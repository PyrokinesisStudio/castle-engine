{
  Copyright 2008-2011 Michalis Kamburelis.

  This file is part of "Kambi VRML game engine".

  "Kambi VRML game engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Kambi VRML game engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Convert Collada to VRML. }
unit ColladaToVRML;

{$I kambiconf.inc}

interface

uses VRMLNodes;

{ Load Collada file as X3D.

  Written based on Collada 1.3.1 and 1.4.1 specifications.
  Should handle any Collada 1.3.x or 1.4.x version.
  This basically means that any existing Collada version should
  be supported. From
  http://www.gamasutra.com/view/feature/1580/introduction_to_collada.php?page=6,
  "The specification stayed quite stable between 1.1 and 1.3.1" --- which
  means that support for 1.3.1 actually includes support for anything existing
  with version <= 1.3.1. And  1.4.1 is currently the newest release.
  To sum it up, everything existing should be handled...

  Although don't expect to handle all Collada features --- many things
  are missing currently, what should work currently is geometry and
  standard (without shaders) materials.

  Only if AllowKambiExtensions, it may use some of our engine specific
  extensions (for example, Material.mirror may be <> 0,
  see [http://vrmlengine.sourceforge.net/kambi_vrml_extensions.php#section_ext_material_mirror]. }
function LoadCollada(const FileName: string;
  const AllowKambiExtensions: boolean = false): TVRMLRootNode;

implementation

uses SysUtils, KambiUtils, KambiStringUtils, VectorMath,
  DOM, KambiXMLRead, KambiXMLUtils, KambiWarnings, Classes, KambiClassUtils,
  FGL {$ifdef VER2_2}, FGLObjectList22 {$endif};

{$define read_interface}
{$define read_implementation}

{ TCollada* helper containers ------------------------------------------------ }

type
  TColladaController = class
    Name: string;
    Source: string;
    BoundShapeMatrix: TMatrix4Single;
    BoundShapeMatrixIdentity: boolean;
  end;

  TObjectsListItem_1 = TColladaController;
  {$I objectslist_1.inc}

type
  TColladaControllersList = class(TObjectsList_1)
    function FindName(const Name: string): Integer;
  end;

function TColladaControllersList.FindName(const Name: string): Integer;
begin
  for Result := 0 to Count - 1 do
    if Items[Result].Name = Name then
      Exit;
  Result := -1;
end;

type
  { Represents Collada <polylist> or <polygons> (item read by ReadPolyCommon),
    which are X3D IndexedFaceSet with a material name. }
  TColladaPoly = class
    { Collada material name (from <polylist> "material" attribute).
      For Collada 1.3.x, this is just a name of material in material library.
      For Collada 1.4.x, when instantiating geometry you specify which material
      name (inside geometry) corresponds to which material name on Materials
      list. }
    Material: string;
    X3DGeometry: TNodeIndexedFaceSet;
    destructor Destroy; override;
  end;

  TColladaPolysList = specialize TFPGObjectList<TColladaPoly>;

destructor TColladaPoly.Destroy;
begin
  X3DGeometry.FreeIfUnused;
  X3DGeometry := nil;
  inherited;
end;

type
  TColladaGeometry = class
    { Collada geometry id. }
    Name: string;
    Polys: TColladaPolysList;
    constructor Create;
    destructor Destroy; override;
  end;

constructor TColladaGeometry.Create;
begin
  Polys := TColladaPolysList.Create;
end;

destructor TColladaGeometry.Destroy;
begin
  FreeAndNil(Polys);
  inherited;
end;

type
  TColladaGeometriesList = class (specialize TFPGObjectList<TColladaGeometry>)
  public
    { Find item with given Name, @nil if not found. }
    function Find(const Name: string): TColladaGeometry;
  end;

function TColladaGeometriesList.Find(const Name: string): TColladaGeometry;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Name = Name then
      Exit(Items[I]);

  Result := nil;
end;

{ LoadCollada ---------------------------------------------------------- }

function LoadCollada(const FileName: string;
  const AllowKambiExtensions: boolean): TVRMLRootNode;
var
  WWWBasePath: string;

  { List of Collada effects. Each contains an X3D Appearance node,
    with a name equal to Collada effect name. }
  Effects: TVRMLNodesList;

  { List of Collada materials. Nodes here are created by copying from Effects
    list, and changing NodeName to Collada material name (forgetting effect name).
    This way we handle instance_effect in <material> node.
    Many materials may refer to a single effect, so we make DeepCopy
    of the effect (not just copy a reference). }
  Materials: TVRMLNodesList;

  { List of Collada geometries. }
  Geometries: TColladaGeometriesList;

  { List of Collada visual scenes, for <visual_scene> Collada elements.
    Every visual scene is X3D TNodeX3DGroupingNode instance.
    This is for Collada >= 1.4.x (for Collada < 1.4.x,
    the <scene> element is directly placed as a rendered scene). }
  VisualScenes: TVRMLNodesList;

  ResultModel: TNodeGroup absolute Result;

  Version14: boolean; //< Collada version >= 1.4.x

  { List of all controllers, read from library_controllers, used by
    instance_controller. }
  Controllers: TColladaControllersList;

  { Read elements of type "common_color_or_texture_type" in Collada >= 1.4.x. }
  function ReadColorOrTexture(Element: TDOMElement): TVector3Single;
  var
    ColorElement: TDOMElement;
  begin
    ColorElement := DOMGetChildElement(Element, 'color', false);

    if ColorElement <> nil then
    begin
      { I simply drop 4th color component, I don't know what's the use of this
        (alpha is exposed by effect/materials parameter transparency, so color
        alpha is supposed to mean something else ?). }
      Result := Vector3SingleCut(
        Vector4SingleFromStr(DOMGetTextData(ColorElement)));
    end else
      { We don't support anything else than <color> here, just use
        default white color eventually. }
      Result := Vector3Single(1, 1, 1);
  end;

  { Read elements of type "common_float_or_param_type" in Collada >= 1.4.x. }
  function ReadFloatOrParam(Element: TDOMElement): Float;
  var
    FloatElement: TDOMElement;
  begin
    FloatElement := DOMGetChildElement(Element, 'float', false);
    if FloatElement <> nil then
    begin
      Result := StrToFloat(DOMGetTextData(FloatElement));
    end else
      { We don't support anything else than <float> here, just use
        default 1 eventually. }
      Result := 1.0;
  end;

  { Read <effect>. Only for Collada >= 1.4.x.
    Adds effect to the Effects list. }
  procedure ReadEffect(EffectElement: TDOMElement);
  var
    Appearance: TNodeAppearance;
    Mat: TNodeMaterial;
    Id: string;
    ProfileElement, TechniqueElement, PhongElement: TDOMElement;
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    TransparencyColor: TVector3Single;
  begin
    if not DOMGetAttribute(EffectElement, 'id', Id) then
      Id := '';

    Appearance := TNodeAppearance.Create(Id, WWWBasePath);
    Effects.Add(Appearance);

    Mat := TNodeMaterial.Create('', WWWBasePath);
    Appearance.FdMaterial.Value := Mat;

    ProfileElement := DOMGetChildElement(EffectElement, 'profile_COMMON', false);
    if ProfileElement <> nil then
    begin
       TechniqueElement := DOMGetChildElement(ProfileElement, 'technique', false);
       if TechniqueElement <> nil then
       begin
         PhongElement := DOMGetChildElement(TechniqueElement, 'phong', false);

         { We actually treat <phong> and <blinn> elements the same.

           X3D lighting equations specify that always Blinn
           (half-vector) technique is used. What's much more practically
           important, OpenGL uses Blinn method. So actually I always do
           blinn method (at least for real-time rendering). }
         if PhongElement = nil then
           PhongElement := DOMGetChildElement(TechniqueElement, 'blinn', false);

         if PhongElement <> nil then
         begin
           { Initialize, in case no <transparent> child. }
           TransparencyColor := ZeroVector3Single;

           Children := PhongElement.ChildNodes;
           try
             for I := 0 to Children.Count - 1 do
             begin
               ChildNode := Children.Item[I];
               if ChildNode.NodeType = ELEMENT_NODE then
               begin
                 ChildElement := ChildNode as TDOMElement;

                 if ChildElement.TagName = 'emission' then
                   Mat.FdEmissiveColor.Value :=
                     ReadColorOrTexture(ChildElement) else

                 if ChildElement.TagName = 'ambient' then
                   Mat.FdAmbientIntensity.Value := VectorAverage(
                     ReadColorOrTexture(ChildElement)) else

                 if ChildElement.TagName = 'diffuse' then
                   Mat.FdDiffuseColor.Value :=
                     ReadColorOrTexture(ChildElement) else

                 if ChildElement.TagName = 'specular' then
                   Mat.FdSpecularColor.Value :=
                     ReadColorOrTexture(ChildElement) else

                 if ChildElement.TagName = 'shininess' then
                   Mat.FdShininess.Value :=
                     ReadFloatOrParam(ChildElement) / 128.0 else

                 if ChildElement.TagName = 'reflective' then
                   {Mat.FdMirrorColor.Value := }
                     ReadColorOrTexture(ChildElement) else

                 if ChildElement.TagName = 'reflectivity' then
                 begin
                   if AllowKambiExtensions then
                     Mat.FdMirror.Value := ReadFloatOrParam(ChildElement) else
                     ReadFloatOrParam(ChildElement);
                 end else

                 if ChildElement.TagName = 'transparent' then
                   TransparencyColor :=
                     ReadColorOrTexture(ChildElement) else

                 if ChildElement.TagName = 'transparency' then
                   Mat.FdTransparency.Value :=
                     ReadFloatOrParam(ChildElement) else

                 if ChildElement.TagName = 'index_of_refraction' then
                   {Mat.FdIndexOfRefraction.Value := }
                     ReadFloatOrParam(ChildElement);
               end;
             end;
           finally FreeChildNodes(Children); end;

           { Collada says (e.g.
             https://collada.org/public_forum/viewtopic.php?t=386)
             to multiply TransparencyColor by Transparency.
             Although I do not handle TransparencyColor, I still have to do
             this, as there are many models with Transparency = 1 and
             TransparencyColor = (0, 0, 0). }
           Mat.FdTransparency.Value :=
             Mat.FdTransparency.Value * VectorAverage(TransparencyColor);

           { make sure to not mistakenly use blending on model that should
             be opaque, but has Effect.FdTransparency.Value = some small
             epsilon, due to numeric errors in above multiply. }
           if Zero(Mat.FdTransparency.Value) then
             Mat.FdTransparency.Value := 0.0;
         end;
       end;
    end;
  end;

  { Read <library_effects>. Only for Collada >= 1.4.x.
    All effects are added to the Effects list. }
  procedure ReadLibraryEffects(LibraryElement: TDOMElement);
  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    LibraryId: string;
  begin
    if not DOMGetAttribute(LibraryElement, 'id', LibraryId) then
      LibraryId := '';

    Children := LibraryElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'effect' then
            ReadEffect(ChildElement);
            { other ChildElement.TagName not supported for now }
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

  { Read <material>. It is added to the Materials list. }
  procedure ReadMaterial(MatElement: TDOMElement);

    function ReadParamAsVector3(Element: TDOMElement): TVector3Single;
    var
      AType: string;
    begin
      if not DOMGetAttribute(Element, 'type', AType) then
      begin
        OnWarning(wtMinor, 'Collada', '<param> has no type attribute');
        Result := ZeroVector3Single;
      end else
      if AType <> 'float3' then
      begin
        OnWarning(wtMinor, 'Collada', 'Expected <param> with type "float3"');
        Result := ZeroVector3Single;
      end else
        Result := Vector3SingleFromStr(DOMGetTextData(Element));
    end;

    function ReadParamAsFloat(Element: TDOMElement): Float;
    var
      AType: string;
    begin
      if not DOMGetAttribute(Element, 'type', AType) then
      begin
        OnWarning(wtMinor, 'Collada', '<param> has no type attribute');
        Result := 0;
      end else
      if AType <> 'float' then
      begin
        OnWarning(wtMinor, 'Collada', 'Expected <param> with type "float"');
        Result := 0;
      end else
        Result := StrToFloat(DOMGetTextData(Element));
    end;

  var
    MatId: string;

    { For Collada < 1.4.x }
    procedure TryCollada13;
    var
      ShaderElement, TechniqueElement, PassElement, ProgramElement: TDOMElement;
      Children: TDOMNodeList;
      ChildNode: TDOMNode;
      ChildElement: TDOMElement;
      ParamName: string;
      I: Integer;
      Appearance: TNodeAppearance;
      Mat: TNodeMaterial;
    begin
      Appearance := TNodeAppearance.Create(MatId, WWWBasePath);
      Materials.Add(Appearance);

      Mat := TNodeMaterial.Create('', WWWBasePath);
      Appearance.FdMaterial.Value := Mat;

      ShaderElement := DOMGetChildElement(MatElement, 'shader', false);
      if ShaderElement <> nil then
      begin
         TechniqueElement := DOMGetChildElement(ShaderElement, 'technique', false);
         if TechniqueElement <> nil then
         begin
           PassElement := DOMGetChildElement(TechniqueElement, 'pass', false);
           if PassElement <> nil then
           begin
             ProgramElement := DOMGetChildElement(PassElement, 'program', false);
             if ProgramElement <> nil then
             begin
               Children := ProgramElement.ChildNodes;
               try
                 for I := 0 to Children.Count - 1 do
                 begin
                   ChildNode := Children.Item[I];
                   if ChildNode.NodeType = ELEMENT_NODE then
                   begin
                     ChildElement := ChildNode as TDOMElement;
                     if ChildElement.TagName = 'param' then
                     begin
                       if DOMGetAttribute(ChildElement, 'name', ParamName) then
                       begin
                         if ParamName = 'EMISSION' then
                           Mat.FdEmissiveColor.Value :=
                             ReadParamAsVector3(ChildElement) else

                         if ParamName = 'AMBIENT' then
                           Mat.FdAmbientIntensity.Value := VectorAverage(
                             ReadParamAsVector3(ChildElement)) else

                         if ParamName = 'DIFFUSE' then
                           Mat.FdDiffuseColor.Value :=
                             ReadParamAsVector3(ChildElement) else

                         if ParamName = 'SPECULAR' then
                           Mat.FdSpecularColor.Value :=
                             ReadParamAsVector3(ChildElement) else

                         if ParamName = 'SHININESS' then
                           Mat.FdShininess.Value :=
                             ReadParamAsFloat(ChildElement) / 128.0 else

                         if ParamName = 'REFLECTIVE' then
                           {Mat.FdMirrorColor.Value := }
                             ReadParamAsVector3(ChildElement) else

                         if ParamName = 'REFLECTIVITY' then
                         begin
                           if AllowKambiExtensions then
                             Mat.FdMirror.Value := ReadParamAsFloat(ChildElement) else
                             ReadParamAsFloat(ChildElement);
                         end else

                         (*
                         Blender Collada 1.3.1 exporter bug: it sets
                         type of TRANSPARENT param as "float".
                         Although content inicates "float3",
                         like Collada 1.3.1 spec requires (page 129),
                         and consistently with what is in Collada 1.4.1 spec.

                         I don't handle this anyway, so I just ignore it for now.
                         Should be reported to Blender.

                         if ParamName = 'TRANSPARENT' then
                           {Mat.FdTransparencyColor.Value := }
                             ReadParamAsVector3(ChildElement) else
                         *)

                         if ParamName = 'TRANSPARENCY' then
                           Mat.FdTransparency.Value :=
                             ReadParamAsFloat(ChildElement);

                         { other ParamName not handled }
                       end;
                     end;
                   end;
                 end;
               finally FreeChildNodes(Children); end
             end;
           end;
         end;
      end;
    end;

    { For Collada >= 1.4.x }
    procedure TryCollada14;
    var
      InstanceEffect: TDOMElement;
      EffectId: string;
      Appearance: TNodeAppearance;
      EffectIndex: Integer;
    begin
      if MatId = '' then Exit;

      InstanceEffect := DOMGetChildElement(MatElement, 'instance_effect', false);
      if InstanceEffect <> nil then
      begin
        if DOMGetAttribute(InstanceEffect, 'url', EffectId) and
           SCharIs(EffectId, 1, '#') then
        begin
          Delete(EffectId, 1, 1); { delete initial '#' char }
          { tests: Writeln('instantiating effect ', EffectId, ' as material ', MatId); }

          EffectIndex := Effects.FindNodeName(EffectId);
          if EffectIndex <> -1 then
          begin
            Appearance := Effects[EffectIndex].DeepCopy as TNodeAppearance;
            Appearance.NodeName := MatId;
            Materials.Add(Appearance);
          end else
            OnWarning(wtMinor, 'Collada', Format('Material "%s" references ' +
              'non-existing effect "%s"', [MatId, EffectId]));
        end;
      end;
    end;

  begin
    if not DOMGetAttribute(MatElement, 'id', MatId) then
      MatId := '';

    if Version14 then
      TryCollada14 else
      TryCollada13;
  end;

  { Read <library_materials> (Collada >= 1.4.x) or
    <library type="MATERIAL"> (Collada < 1.4.x). }
  procedure ReadLibraryMaterials(LibraryElement: TDOMElement);
  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    LibraryId: string;
  begin
    if not DOMGetAttribute(LibraryElement, 'id', LibraryId) then
      LibraryId := '';

    Children := LibraryElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'material' then
            ReadMaterial(ChildElement);
            { other ChildElement.TagName not supported for now }
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

  { Read <geometry>. It is added to the Geometries list. }
  procedure ReadGeometry(GeometryElement: TDOMElement);
  var
    { Collada Geometry constructed, available to all ReadPoly* local procedures. }
    Geometry: TColladaGeometry;

    { Text is the name of the source, Object is the TDynVector3SingleArray
      instance containing this source's data. }
    SourcesList: TStringList;

    { Read <source> within <mesh>.

      This is quite limited compared to what Collada offers, actually
      we understand only float_array data accessed by accessor with
      three parameters (although any accessor.stride >= 3).

      In other words, <source> simply defines a named array of TVector3Single
      for us. }
    procedure ReadSource(SourceElement: TDOMElement);
    var
      FloatArray, Technique, Accessor: TDOMElement;
      SeekPos, FloatArrayCount, I, AccessorCount, AccessorStride,
        AccessorOffset, MinCount: Integer;
      Floats: TDynFloatArray;
      SourceId, FloatArrayContents, Token, AccessorSource: string;
      Source: TDynVector3SingleArray;
    begin
      if not DOMGetAttribute(SourceElement, 'id', SourceId) then
        SourceId := '';

      FloatArray := DOMGetChildElement(SourceElement, 'float_array', false);
      if FloatArray <> nil then
      begin
        if not DOMGetIntegerAttribute(FloatArray, 'count', FloatArrayCount) then
        begin
          FloatArrayCount := 0;
          OnWarning(wtMinor, 'Collada', '<float_array> without a count attribute');
        end;

        Floats := TDynFloatArray.Create(FloatArrayCount);
        try
          FloatArrayContents := DOMGetTextData(FloatArray);

          SeekPos := 1;
          for I := 0 to FloatArrayCount - 1 do
          begin
            Token := NextToken(FloatArrayContents, SeekPos, WhiteSpaces);
            if Token = '' then
            begin
              OnWarning(wtMinor, 'Collada', 'Actual number of tokens in <float_array>' +
                ' less than declated in the count attribute');
              Break;
            end;
            Floats.Items[I] := StrToFloat(Token);
          end;

          Technique := DOMGetChildElement(SourceElement, 'technique_common', false);
          if Technique = nil then
          begin
            Technique := DOMGetChildElement(SourceElement, 'technique', false);
            { TODO: actually, I should search for technique with profile="COMMON"
              in this case, right ? }
          end;

          if Technique <> nil then
          begin
            Accessor := DOMGetChildElement(Technique, 'accessor', false);

            { read <accessor> attributes }

            if not DOMGetIntegerAttribute(Accessor, 'count', AccessorCount) then
            begin
              OnWarning(wtMinor, 'Collada', '<accessor> has no count attribute');
              AccessorCount := 0;
            end;

            if not DOMGetIntegerAttribute(Accessor, 'stride', AccessorStride) then
              { default, according to Collada spec }
              AccessorStride := 1;

            if not DOMGetIntegerAttribute(Accessor, 'offset', AccessorOffset) then
              { default, according to Collada spec }
              AccessorOffset := 0;

            if not DOMGetAttribute(Accessor, 'source', AccessorSource) then
            begin
              OnWarning(wtMinor, 'Collada', '<accessor> has no source attribute');
              AccessorSource := '';
            end;
            { TODO: we ignore AccessorSource, just assume that it refers to
              float_array within this <source> }

            if AccessorStride >= 3 then
            begin
              { Max index accessed is
                  AccessorOffset + AccessorStride * (AccessorCount - 1) + 2.
                Minimum count is +1 to this.
                Check do we have enough floats. }
              MinCount := AccessorOffset + AccessorStride * (AccessorCount - 1) + 3;
              if Floats.Count < MinCount then
              begin
                OnWarning(wtMinor, 'Collada', Format('<accessor> count requires at least %d float ' +
                  'values (offset %d + stride %d * (count %d - 1) + 3) in <float_array>, ' +
                  'but only %d are avilable', [MinCount,
                    AccessorOffset, AccessorStride, AccessorCount, Floats.Count]));
                { force AccessorCount smaller }
                AccessorCount := (Floats.Count - AccessorOffset) div AccessorStride;
              end;

              Source := TDynVector3SingleArray.Create(AccessorCount);
              for I := 0 to AccessorCount - 1 do
              begin
                Source.Items[I][0] := Floats.Items[AccessorOffset + AccessorStride * I    ];
                Source.Items[I][1] := Floats.Items[AccessorOffset + AccessorStride * I + 1];
                Source.Items[I][2] := Floats.Items[AccessorOffset + AccessorStride * I + 2];
              end;
              { tests: Writeln('added source ', SourceId, ' with ', AccessorCount, ' items'); }
              SourcesList.AddObject(SourceId, Source);
            end;
          end;
        finally FreeAndNil(Floats); end;
      end;
    end;

  var
    { This is just a reference to one of the objects on SourcesList --- the one
      referenced by <vertices> element. }
    Vertices: TDynVector3SingleArray;
    VerticesId: string;

    { Read <vertices> within <mesh> }
    procedure ReadVertices(VerticesElement: TDOMElement);
    var
      Children: TDOMNodeList;
      ChildNode: TDOMNode;
      ChildElement: TDOMElement;
      I: Integer;
      InputSemantic, InputSource: string;
      InputSourceIndex: Integer;
    begin
      if not DOMGetAttribute(VerticesElement, 'id', VerticesId) then
        VerticesId := '';

      Children := VerticesElement.ChildNodes;
      try
        for I := 0 to Children.Count - 1 do
        begin
          ChildNode := Children.Item[I];
          if ChildNode.NodeType = ELEMENT_NODE then
          begin
            ChildElement := ChildNode as TDOMElement;
            if (ChildElement.TagName = 'input') and
               DOMGetAttribute(ChildElement, 'semantic', InputSemantic) and
               (InputSemantic = 'POSITION') and
               DOMGetAttribute(ChildElement, 'source', InputSource) and
               SCharIs(InputSource, 1, '#') then
            begin
              Delete(InputSource, 1, 1); { delete leading '#' char }
              InputSourceIndex := SourcesList.IndexOf(InputSource);
              if InputSourceIndex <> -1 then
              begin
                Vertices := SourcesList.Objects[InputSourceIndex] as
                  TDynVector3SingleArray;
                Exit;
              end else
              begin
                OnWarning(wtMinor, 'Collada', Format('Source attribute ' +
                  '(of <input> element within <vertices>) ' +
                  'references non-existing source "%s"', [InputSource]));
              end;
            end;
          end;
        end;
      finally FreeChildNodes(Children); end;

      OnWarning(wtMinor, 'Collada', '<vertices> element has no <input> child' +
        ' with semantic="POSITION" and some source attribute');
    end;

    { Read common things of <polygons> and <polylist> and similar within <mesh>.
      - Creates IndexedFaceSet, initializes it's coord and some other
        fiels (but leaves coordIndex empty).
      - Adds to Geometry.Polys
      - Reads <input> children, to calculate InputsCount and VerticesOffset. }
    procedure ReadPolyCommon(PolygonsElement: TDOMElement;
      out IndexedFaceSet: TNodeIndexedFaceSet;
      out InputsCount, VerticesOffset: Integer);
    var
      Children: TDOMNodeList;
      ChildNode: TDOMNode;
      ChildElement: TDOMElement;
      I: Integer;
      Coord: TNodeCoordinate;
      PolygonsCount: Integer;
      InputSemantic, InputSource: string;
      Poly: TColladaPoly;
    begin
      if not DOMGetIntegerAttribute(PolygonsElement, 'count', PolygonsCount) then
        PolygonsCount := 0;

      VerticesOffset := 0;

      IndexedFaceSet := TNodeIndexedFaceSet.Create(Format('%s_collada_poly_%d',
        { There may be multiple <polylist> inside a single Collada <geometry> node,
          so use Geometry.Polys.Count to name them uniquely for X3D. }
        [Geometry.Name, Geometry.Polys.Count]), WWWBasePath);
      IndexedFaceSet.FdCoordIndex.Items.Count := 0;
      IndexedFaceSet.FdSolid.Value := false;
      { For VRML >= 2.0, creaseAngle is 0 by default.
        But, since I currently ignore normals in Collada file, it's better
        to have some non-zero creaseAngle by default. }
      IndexedFaceSet.FdCreaseAngle.Value := DefaultVRML1CreaseAngle;

      Poly := TColladaPoly.Create;
      Poly.X3DGeometry := IndexedFaceSet;
      Geometry.Polys.Add(Poly);

      Coord := TNodeCoordinate.Create(VerticesId, WWWBasePath);
      IndexedFaceSet.FdCoord.Value := Coord;
      Coord.FdPoint.Items.Assign(Vertices);

      if DOMGetAttribute(PolygonsElement, 'material', Poly.Material) then
      begin
        { Collada 1.4.1 spec says that this is just material name.
          Collada 1.3.1 spec says that this is URL. }
        if (not Version14) and SCharIs(Poly.Material, 1, '#') then
          Delete(Poly.Material, 1, 1);
      end; { else leave Poly.Material as '' }

      InputsCount := 0;

      Children := PolygonsElement.ChildNodes;
      try
        for I := 0 to Children.Count - 1 do
        begin
          ChildNode := Children.Item[I];
          if ChildNode.NodeType = ELEMENT_NODE then
          begin
            ChildElement := ChildNode as TDOMElement;
            if ChildElement.TagName = 'input' then
            begin
              { we must count all inputs, since parsing <p> elements depends
                on InputsCount }
              Inc(InputsCount);
              if DOMGetAttribute(ChildElement, 'semantic', InputSemantic) and
                 (InputSemantic = 'VERTEX') then
              begin
                if not (DOMGetAttribute(ChildElement, 'source', InputSource) and
                        (InputSource = '#' + VerticesId))  then
                  OnWarning(wtMinor, 'Collada', '<input> with semantic="VERTEX" ' +
                    '(of <polygons> element within <mesh>) does not reference ' +
                    '<vertices> element within the same <mesh>');

                { Collada requires offset in this case.
                  For us, if there's no offset, just leave VerticesOffset as it was. }
                DOMGetIntegerAttribute(ChildElement, 'offset', VerticesOffset);
              end;
            end;
          end;
        end;
      finally FreeChildNodes(Children); end;
    end;

    { Read <polygons> within <mesh> }
    procedure ReadPolygons(PolygonsElement: TDOMElement);
    var
      IndexedFaceSet: TNodeIndexedFaceSet;
      InputsCount: Integer;
      VerticesOffset: Integer;

      procedure AddPolygon(const Indexes: string);
      var
        SeekPos, Index, CurrentInput: Integer;
        Token: string;
      begin
        CurrentInput := 0;
        SeekPos := 1;

        repeat
          Token := NextToken(Indexes, SeekPos, WhiteSpaces);
          if Token = '' then Break;
          Index := StrToInt(Token);

          { for now, we just ignore indexes to other inputs }
          if CurrentInput = VerticesOffset then
            IndexedFaceSet.FdCoordIndex.Items.Add(Index);

          Inc(CurrentInput);
          if CurrentInput = InputsCount then CurrentInput := 0;
        until false;

        IndexedFaceSet.FdCoordIndex.Items.Add(-1);
      end;

    var
      Children: TDOMNodeList;
      ChildNode: TDOMNode;
      ChildElement: TDOMElement;
      I: Integer;
    begin
      ReadPolyCommon(PolygonsElement, IndexedFaceSet, InputsCount, VerticesOffset);

      Children := PolygonsElement.ChildNodes;
      try
        for I := 0 to Children.Count - 1 do
        begin
          ChildNode := Children.Item[I];
          if ChildNode.NodeType = ELEMENT_NODE then
          begin
            ChildElement := ChildNode as TDOMElement;
            if ChildElement.TagName = 'p' then
              AddPolygon(DOMGetTextData(ChildElement));
          end;
        end;
      finally FreeChildNodes(Children); end;
    end;

    { Read <polylist> within <mesh> }
    procedure ReadPolylist(PolygonsElement: TDOMElement);
    var
      IndexedFaceSet: TNodeIndexedFaceSet;
      InputsCount: Integer;
      VerticesOffset: Integer;
      VCount, P: TDOMElement;
      VCountContent, PContent, Token: string;
      SeekPosVCount, SeekPosP, ThisPolygonCount, CurrentInput, I, Index: Integer;
    begin
      ReadPolyCommon(PolygonsElement, IndexedFaceSet, InputsCount, VerticesOffset);

      VCount := DOMGetChildElement(PolygonsElement, 'vcount', false);
      P := DOMGetChildElement(PolygonsElement, 'p', false);

      if (VCount <> nil) and (P <> nil) then
      begin
        VCountContent := DOMGetTextData(VCount);
        PContent := DOMGetTextData(P);

        { we will parse both VCountContent and PContent now, at the same time }

        SeekPosVCount := 1;
        SeekPosP := 1;

        repeat
          Token := NextToken(VCountContent, SeekPosVCount, WhiteSpaces);
          if Token = '' then Break; { end of polygons }

          ThisPolygonCount := StrToInt(Token);

          CurrentInput := 0;

          for I := 0 to ThisPolygonCount * InputsCount - 1 do
          begin
            Token := NextToken(PContent, SeekPosP, WhiteSpaces);
            if Token = '' then
            begin
              OnWarning(wtMinor, 'Collada', 'Unexpected end of <p> data in <polylist>');
              Exit;
            end;
            Index := StrToInt(Token);

            { for now, we just ignore indexes to other inputs }
            if CurrentInput = VerticesOffset then
              IndexedFaceSet.FdCoordIndex.Items.Add(Index);

            Inc(CurrentInput);
            if CurrentInput = InputsCount then CurrentInput := 0;
          end;

          IndexedFaceSet.FdCoordIndex.Items.Add(-1);
        until false;
      end;
    end;

    { Read <triangles> within <mesh> }
    procedure ReadTriangles(PolygonsElement: TDOMElement);
    var
      IndexedFaceSet: TNodeIndexedFaceSet;
      InputsCount: Integer;
      VerticesOffset: Integer;
      P: TDOMElement;
      PContent, Token: string;
      SeekPosP, CurrentInput, Index, VertexNumber: Integer;
    begin
      ReadPolyCommon(PolygonsElement, IndexedFaceSet, InputsCount, VerticesOffset);

      P := DOMGetChildElement(PolygonsElement, 'p', false);
      if P <> nil then
      begin
        PContent := DOMGetTextData(P);

        SeekPosP := 1;
        CurrentInput := 0;
        VertexNumber := 0;

        repeat
          Token := NextToken(PContent, SeekPosP, WhiteSpaces);
          if Token = '' then Break; { end of triangles }
          Index := StrToInt(Token);

          { for now, we just ignore indexes to other inputs }
          if CurrentInput = VerticesOffset then
            IndexedFaceSet.FdCoordIndex.Items.Add(Index);

          Inc(CurrentInput);
          if CurrentInput = InputsCount then
          begin
            CurrentInput := 0;
            Inc(VertexNumber);
            if VertexNumber = 3 then
            begin
              VertexNumber := 0;
              IndexedFaceSet.FdCoordIndex.Items.Add(-1);
            end;
          end;
        until false;
      end;
    end;

  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement, Mesh: TDOMElement;
    I: Integer;
    GeometryId: string;
  begin
    if not DOMGetAttribute(GeometryElement, 'id', GeometryId) then
      GeometryId := '';

    Geometry := TColladaGeometry.Create;
    Geometry.Name := GeometryId;
    Geometries.Add(Geometry);

    Mesh := DOMGetChildElement(GeometryElement, 'mesh', false);
    if Mesh <> nil then
    begin
      SourcesList := TStringList.Create;
      try
        Children := Mesh.ChildNodes;
        try
          for I := 0 to Children.Count - 1 do
          begin
            ChildNode := Children.Item[I];
            if ChildNode.NodeType = ELEMENT_NODE then
            begin
              ChildElement := ChildNode as TDOMElement;
              if ChildElement.TagName = 'source' then
                ReadSource(ChildElement) else
              if ChildElement.TagName = 'vertices' then
                ReadVertices(ChildElement) else
              if ChildElement.TagName = 'polygons' then
                ReadPolygons(ChildElement) else
              if ChildElement.TagName = 'polylist' then
                ReadPolylist(ChildElement) else
              if ChildElement.TagName = 'triangles' then
                ReadTriangles(ChildElement);
                { other ChildElement.TagName not supported for now }
            end;
          end;
        finally FreeChildNodes(Children); end
      finally StringList_FreeWithContentsAndNil(SourcesList); end;
    end;
  end;

  { Read <library_geometries> (Collada >= 1.4.x) or
    <library type="GEOMETRY"> (Collada < 1.4.x). }
  procedure ReadLibraryGeometries(LibraryElement: TDOMElement);
  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    LibraryId: string;
  begin
    if not DOMGetAttribute(LibraryElement, 'id', LibraryId) then
      LibraryId := '';

    Children := LibraryElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'geometry' then
            ReadGeometry(ChildElement);
            { other ChildElement.TagName not supported for now }
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

  { Read <library> element.
    Only for Collada < 1.4.x (Collada >= 1.4.x has  <library_xxx> elements). }
  procedure ReadLibrary(LibraryElement: TDOMElement);
  var
    LibraryType: string;
  begin
    if DOMGetAttribute(LibraryElement, 'type', LibraryType) then
    begin
      if LibraryType = 'MATERIAL' then
        ReadLibraryMaterials(LibraryElement) else
      if LibraryType = 'GEOMETRY' then
        ReadLibraryGeometries(LibraryElement);
        { other LibraryType not supported for now }
    end;
  end;

  { Read <matrix> or <bind_shape_matrix> element to given Matrix. }
  function  ReadMatrix(MatrixElement: TDOMElement): TMatrix4Single; overload;
  var
    SeekPos: Integer;
    Row, Col: Integer;
    Token, Content: string;
  begin
    Content := DOMGetTextData(MatrixElement);

    SeekPos := 1;

    for Row := 0 to 3 do
      for Col := 0 to 3 do
      begin
        Token := NextToken(Content, SeekPos, WhiteSpaces);
        if Token = '' then
        begin
          OnWarning(wtMinor, 'Collada', 'Matrix (<matrix> or <bind_shape_matrix> ' +
            'element) has not enough items');
          Break;
        end;
        Result[Col, Row] := StrToFloat(Token);
      end;
  end;

  { Read <lookat> element, return appropriate matrix. }
  function ReadLookAt(MatrixElement: TDOMElement): TMatrix4Single;
  var
    SeekPos: Integer;
    Content: string;

    function ReadVector(var Vector: TVector3Single): boolean;
    var
      Token: string;
      I: Integer;
    begin
      Result := true;

      for I := 0 to 2 do
      begin
        Token := NextToken(Content, SeekPos, WhiteSpaces);
        if Token = '' then
        begin
          OnWarning(wtMinor, 'Collada', 'Unexpected end of data of <lookat>');
          Exit(false);
        end;
        Vector[I] := StrToFloat(Token);
      end;
    end;

  var
    Eye, Center, Up: TVector3Single;
  begin
    Content := DOMGetTextData(MatrixElement);

    SeekPos := 1;

    if ReadVector(Eye) and
       ReadVector(Center) and
       ReadVector(Up) then
      Result := LookAtMatrix(Eye, Center, Up);
  end;

  { Read <node> element, add it to ParentGroup. }
  procedure ReadNodeElement(ParentGroup: TNodeX3DGroupingNode;
    NodeElement: TDOMElement);

    { For Collada material id, return the X3D Material (or @nil if not found). }
    function MaterialToX3D(MaterialId: string;
      InstantiatingElement: TDOMElement): TNodeAppearance;
    var
      MaterialIndex: Integer;
      BindMaterial, Technique: TDOMElement;
      InstanceMaterialSymbol, InstanceMaterialTarget: string;
      Children: TDOMNodeList;
      ChildNode: TDOMNode;
      ChildElement: TDOMElement;
      I: Integer;
    begin
      if MaterialId = '' then Exit(nil);

      { For InstantiatingElement = instance_geometry (Collada 1.4.x), this
        must be present.
        For InstantiatingElement = instance (Collada 1.3.x), this must not
        be present.
        (But we actually don't check these conditions, just handle any case.) }
      BindMaterial := DOMGetChildElement(InstantiatingElement, 'bind_material', false);
      if BindMaterial <> nil then
      begin
        Technique := DOMGetChildElement(BindMaterial, 'technique_common', false);
        if Technique <> nil then
        begin
          { read <instance_material list inside.
            This may contain multiple materials, but actually we're only
            interested in a single material, so we look for material with
            symbol = MaterialId. }
          Children := Technique.ChildNodes;
          try
            for I := 0 to Children.Count - 1 do
            begin
              ChildNode := Children.Item[I];
              if ChildNode.NodeType = ELEMENT_NODE then
              begin
                ChildElement := ChildNode as TDOMElement;
                if (ChildElement.TagName = 'instance_material') and
                   DOMGetAttribute(ChildElement, 'symbol', InstanceMaterialSymbol) and
                   (InstanceMaterialSymbol = MaterialId) and
                   DOMGetAttribute(ChildElement, 'target', InstanceMaterialTarget) then
                begin
                  { this should be true, target is URL }
                  if SCharIs(InstanceMaterialTarget, 1, '#') then
                    Delete(InstanceMaterialTarget, 1, 1);

                  { replace MaterialId with what is indicated by
                      <instance_material target="..."> }
                  MaterialId := InstanceMaterialTarget;
                end;
              end;
            end;
          finally FreeChildNodes(Children); end;
        end;
      end;

      MaterialIndex := Materials.FindNodeName(MaterialId);
      if MaterialIndex = -1 then
      begin
        OnWarning(wtMinor, 'Collada', Format('Referencing non-existing material name "%s"',
          [MaterialId]));
        Result := nil;
      end else
      begin
        Result := Materials[MaterialIndex] as TNodeAppearance;
      end;
    end;

    { Add Collada geometry instance (many X3D Shape nodes) to given X3D Group. }
    procedure AddGeometryInstance(Group: TNodeX3DGroupingNode;
      Geometry: TColladaGeometry; InstantiatingElement: TDOMElement);
    var
      Shape: TNodeShape;
      I: Integer;
      Poly: TColladaPoly;
    begin
      for I := 0 to Geometry.Polys.Count - 1 do
      begin
        Poly := Geometry.Polys[I];
        Shape := TNodeShape.Create('', WWWBasePath);
        Group.FdChildren.Add(Shape);
        Shape.FdGeometry.Value := Poly.X3DGeometry;
        Shape.Appearance := MaterialToX3D(Poly.Material, InstantiatingElement);
      end;
    end;

    { Read <instance_geometry>, adding resulting X3D nodes into
      ParentGroup. Actually, this is also for reading <instance> in Collada 1.3.1. }
    procedure ReadInstanceGeometry(ParentGroup: TNodeX3DGroupingNode;
      InstantiatingElement: TDOMElement);
    var
      GeometryId: string;
      Geometry: TColladaGeometry;
    begin
      if DOMGetAttribute(InstantiatingElement, 'url', GeometryId) and
         SCharIs(GeometryId, 1, '#') then
      begin
        Delete(GeometryId, 1, 1);
        Geometry := Geometries.Find(GeometryId);
        if Geometry = nil then
        begin
          OnWarning(wtMinor, 'Collada', Format('<node> instantiates non-existing ' +
            '<geometry> element "%s"', [GeometryId]));
        end else
          AddGeometryInstance(ParentGroup, Geometry, InstantiatingElement);
      end;
    end;

    { Read <instance_controller>, adding resulting X3D node into
      ParentGroup. }
    procedure ReadInstanceController(ParentGroup: TNodeX3DGroupingNode;
      InstantiatingElement: TDOMElement);
    var
      ControllerId: string;
      ControllerIndex: Integer;
      Controller: TColladaController;
      Group: TNodeX3DGroupingNode;
      Geometry: TColladaGeometry;
    begin
      if DOMGetAttribute(InstantiatingElement, 'url', ControllerId) and
         SCharIs(ControllerId, 1, '#') then
      begin
        Delete(ControllerId, 1, 1);
        ControllerIndex := Controllers.FindName(ControllerId);
        if ControllerIndex = -1 then
        begin
          OnWarning(wtMinor, 'Collada', Format('<node> instantiates non-existing ' +
            '<controller> element "%s"', [ControllerId]));
        end else
        begin
          Controller := Controllers[ControllerIndex];

          Geometry := Geometries.Find(Controller.Source);
          if Geometry = nil then
          begin
            OnWarning(wtMinor, 'Collada', Format('<controller> references non-existing ' +
              '<geometry> element "%s"', [Controller.Source]));
          end else
          begin
            if Controller.BoundShapeMatrixIdentity then
            begin
              Group := TNodeGroup.Create('', WWWBasePath);
            end else
            begin
              Group := TNodeMatrixTransform.Create('', WWWBasePath);
              TNodeMatrixTransform(Group).FdMatrix.Value := Controller.BoundShapeMatrix;
            end;
            ParentGroup.FdChildren.Add(Group);
            AddGeometryInstance(Group, Geometry, InstantiatingElement);
          end;
        end;
      end;
    end;

  var
    { This is either TNodeTransform or TNodeMatrixTransform. }
    NodeTransform: TNodeX3DGroupingNode;

    { Create new Transform node, place it as a child of current Transform node
      and switch current Transform node to the new one.

      The idea is that each
      Collada transformation creates new nested VRML Transform node
      (since Collada transformations may represent any transformation,
      not necessarily representable by a single VRML Transform node).

      Returns NodeTransform, typecasted to TNodeTransform, for your comfort. }
    function NestedTransform: TNodeTransform;
    var
      NewNodeTransform: TNodeTransform;
    begin
      NewNodeTransform := TNodeTransform.Create('', WWWBasePath);
      NodeTransform.FdChildren.Add(NewNodeTransform);

      NodeTransform := NewNodeTransform;
      Result := NewNodeTransform;
    end;

    function NestedMatrixTransform: TNodeMatrixTransform;
    var
      NewNodeTransform: TNodeMatrixTransform;
    begin
      NewNodeTransform := TNodeMatrixTransform.Create('', WWWBasePath);
      NodeTransform.FdChildren.Add(NewNodeTransform);

      NodeTransform := NewNodeTransform;
      Result := NewNodeTransform;
    end;

  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    NodeId: string;
    V3: TVector3Single;
    V4: TVector4Single;
  begin
    if not DOMGetAttribute(NodeElement, 'id', NodeId) then
      NodeId := '';

    NodeTransform := TNodeTransform.Create(NodeId, WWWBasePath);
    ParentGroup.FdChildren.Add(NodeTransform);

    { First iterate to gather all transformations.

      For Collada 1.4, this shouldn't be needed (spec says that
      transforms must be before all instantiations).

      But Collada 1.3.1 specification doesn't say anything about the order.
      And e.g. Blender Collada 1.3 exporter in fact generates files
      with <instantiate> first, then <matrix>, and yes: it expects matrix
      should affect instantiated object. So the bottom line is that for
      Collada 1.3, I must first gather all transforms, then do instantiations. }

    Children := NodeElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'matrix' then
          begin
            NestedMatrixTransform.FdMatrix.Value := ReadMatrix(ChildElement);
          end else
          if ChildElement.TagName = 'rotate' then
          begin
            V4 := Vector4SingleFromStr(DOMGetTextData(ChildElement));
            if V4[3] <> 0.0 then
            begin
              NestedTransform.FdRotation.ValueDeg := V4;
            end;
          end else
          if ChildElement.TagName = 'scale' then
          begin
            V3 := Vector3SingleFromStr(DOMGetTextData(ChildElement));
            if not VectorsPerfectlyEqual(V3, Vector3Single(1, 1, 1)) then
            begin
              NestedTransform.FdScale.Value := V3;
            end;
          end else
          if ChildElement.TagName = 'lookat' then
          begin
            NestedMatrixTransform.FdMatrix.Value := ReadLookAt(ChildElement);
          end else
          if ChildElement.TagName = 'skew' then
          begin
            { TODO }
          end else
          if ChildElement.TagName = 'translate' then
          begin
            V3 := Vector3SingleFromStr(DOMGetTextData(ChildElement));
            if not VectorsPerfectlyEqual(V3, ZeroVector3Single) then
            begin
              NestedTransform.FdTranslation.Value := V3;
            end;
          end;
        end;
      end;
    finally FreeChildNodes(Children); end;

    { Now iterate to read instantiations and recursive nodes. }

    Children := NodeElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if (ChildElement.TagName = 'instance') or
             (ChildElement.TagName = 'instance_geometry') then
            ReadInstanceGeometry(NodeTransform, ChildElement) else
          if ChildElement.TagName = 'instance_controller' then
            ReadInstanceController(NodeTransform, ChildElement) else
          if ChildElement.TagName = 'node' then
            ReadNodeElement(NodeTransform, ChildElement);
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

  { Read <node> sequence within given SceneElement, adding nodes to Group.
    This is used to handle <visual_scene> for Collada 1.4.x
    and <scene> for Collada 1.3.x. }
  procedure ReadNodesSequence(Group: TNodeX3DGroupingNode;
    SceneElement: TDOMElement);
  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
  begin
    Children := SceneElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'node' then
            ReadNodeElement(Group, ChildElement);
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

  { Read <scene> element. }
  procedure ReadSceneElement(SceneElement: TDOMElement);
  var
    SceneId: string;

    procedure Collada14;
    var
      InstanceVisualScene: TDOMElement;
      VisualSceneId: string;
      VisualSceneIndex: Integer;
    begin
      InstanceVisualScene := DOMGetChildElement(SceneElement,
        'instance_visual_scene', false);
      if InstanceVisualScene <> nil then
      begin
        if DOMGetAttribute(InstanceVisualScene, 'url', VisualSceneId) and
           SCharIs(VisualSceneId, 1, '#') then
        begin
          Delete(VisualSceneId, 1, 1);
          VisualSceneIndex := VisualScenes.FindNodeName(VisualSceneId);
          if VisualSceneIndex = -1 then
          begin
            OnWarning(wtMinor, 'Collada', Format('<instance_visual_scene> instantiates non-existing ' +
              '<visual_scene> element "%s"', [VisualSceneId]));
          end else
          begin
            ResultModel.FdChildren.Add(VisualScenes[VisualSceneIndex]);
          end;
        end;
      end;
    end;

    procedure Collada13;
    var
      Group: TNodeGroup;
    begin
      Group := TNodeGroup.Create(SceneId, WWWBasePath);
      ResultModel.FdChildren.Add(Group);

      ReadNodesSequence(Group, SceneElement);
    end;

  begin
    if not DOMGetAttribute(SceneElement, 'id', SceneId) then
      SceneId := '';

    { <scene> element is different in two Collada versions, it's most clear
      to just branch and do different procedure depending on Collada version. }

    if Version14 then
      Collada14 else
      Collada13;
  end;

  { Read <visual_scene>. Obtained scene X3D node is added both
    to VisualScenes list and VisualScenesSwitch.choice. }
  procedure ReadVisualScene(VisualScenesSwitch: TNodeSwitch;
    VisualSceneElement: TDOMElement);
  var
    VisualSceneId: string;
    Group: TNodeGroup;
  begin
    if not DOMGetAttribute(VisualSceneElement, 'id', VisualSceneId) then
      VisualSceneId := '';

    Group := TNodeGroup.Create(VisualSceneId, WWWBasePath);
    VisualScenes.Add(Group);
    VisualScenesSwitch.FdChildren.Add(Group);

    ReadNodesSequence(Group, VisualSceneElement);
  end;

  { Read <library_visual_scenes> from Collada 1.4.x }
  procedure ReadLibraryVisualScenes(LibraryElement: TDOMElement);
  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    LibraryId: string;
    VisualScenesSwitch: TNodeSwitch;
  begin
    if not DOMGetAttribute(LibraryElement, 'id', LibraryId) then
      LibraryId := '';

    { Library of visual scenes is simply a VRML Switch, with each
      scene inside as one choice. This way we export to VRML all
      scenes from Collada, even those not chosen as current scene.
      That's good --- it's always nice to keep some data when
      converting. }

    VisualScenesSwitch := TNodeSwitch.Create(LibraryId, WWWBasePath);
    ResultModel.FdChildren.Add(VisualScenesSwitch);

    Children := LibraryElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'visual_scene' then
            ReadVisualScene(VisualScenesSwitch, ChildElement);
            { other ChildElement.TagName not supported for now }
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

  { Read <controller> from Collada 1.4.x }
  procedure ReadController(ControllerElement: TDOMElement);
  var
    Controller: TColladaController;
    Skin, BindShapeMatrix: TDOMElement;
  begin
    Controller := TColladaController.Create;
    Controllers.Add(Controller);
    Controller.BoundShapeMatrixIdentity := true;

    if not DOMGetAttribute(ControllerElement, 'id', Controller.Name) then
      Controller.Name := '';

    Skin := DOMGetChildElement(ControllerElement, 'skin', false);
    if Skin <> nil then
    begin
      if DOMGetAttribute(Skin, 'source', Controller.Source) then
      begin
        { this should be true, controller.source is URL }
        if SCharIs(Controller.Source, 1, '#') then
          Delete(Controller.Source, 1, 1);
      end;

      BindShapeMatrix := DOMGetChildElement(Skin, 'bind_shape_matrix', false);
      if BindShapeMatrix <> nil then
      begin
        Controller.BoundShapeMatrixIdentity := false;
        Controller.BoundShapeMatrix := ReadMatrix(BindShapeMatrix);
      end;
    end;
  end;

  { Read <library_controllers> from Collada 1.4.x }
  procedure ReadLibraryControllers(LibraryElement: TDOMElement);
  var
    Children: TDOMNodeList;
    ChildNode: TDOMNode;
    ChildElement: TDOMElement;
    I: Integer;
    LibraryId: string;
  begin
    if not DOMGetAttribute(LibraryElement, 'id', LibraryId) then
      LibraryId := '';

    Children := LibraryElement.ChildNodes;
    try
      for I := 0 to Children.Count - 1 do
      begin
        ChildNode := Children.Item[I];
        if ChildNode.NodeType = ELEMENT_NODE then
        begin
          ChildElement := ChildNode as TDOMElement;
          if ChildElement.TagName = 'controller' then
            ReadController(ChildElement);
            { other ChildElement.TagName not supported for now }
        end;
      end;
    finally FreeChildNodes(Children); end
  end;

var
  Doc: TXMLDocument;
  Version: string;
  I: Integer;
  DocChildren: TDOMNodeList;
  ChildNode: TDOMNode;
  ChildElement: TDOMElement;
begin
  Effects := nil;
  Materials := nil;
  Geometries := nil;
  VisualScenes := nil;
  Controllers := nil;

  try
    { ReadXMLFile always sets TXMLDocument param (possibly to nil),
      even in case of exception. So place it inside try..finally. }
    ReadXMLFile(Doc, FileName);

    Check(Doc.DocumentElement.TagName = 'COLLADA',
      'Root node of Collada file must be <COLLADA>');

    if not DOMGetAttribute(Doc.DocumentElement, 'version', Version) then
    begin
      Version := '';
      Version14 := false;
      OnWarning(wtMinor, 'Collada', '<COLLADA> element misses "version" attribute');
    end else
    begin
      { TODO: uhm, terrible hack... I should move my lazy ass and tokenize
        Version properly. }
      Version14 := IsPrefix('1.4.', Version);
    end;

    if DOMGetAttribute(Doc.DocumentElement, 'base', WWWBasePath) then
    begin
      { COLLADA.base is exactly for the same purpose as WWWBasePath.
        Use it (making sure it's absolute path). }
      WWWBasePath := ExpandFileName(WWWBasePath);
    end else
      WWWBasePath := ExtractFilePath(ExpandFilename(FileName));

    Effects := TVRMLNodesList.Create;
    Materials := TVRMLNodesList.Create;
    Geometries := TColladaGeometriesList.Create;
    VisualScenes := TVRMLNodesList.Create;
    Controllers := TColladaControllersList.Create;

    Result := TVRMLRootNode.Create('', WWWBasePath);
    try
      Result.HasForceVersion := true;
      Result.ForceVersion := X3DVersion;

      { First read library_effects.

        Effects may be referenced by materials,
        and there's no guarantee that library_effects will occur before
        library_materials. Testcase: COLLLADA 1.4.1 Basic Samples/Cube/cube.dae.

        library_effects is only for Collada >= 1.4.x. }
      ChildElement := DOMGetChildElement(Doc.DocumentElement, 'library_effects', false);
      if ChildElement <> nil then
        ReadLibraryEffects(ChildElement);

      DocChildren := Doc.DocumentElement.ChildNodes;
      try
        for I := 0 to DocChildren.Count - 1 do
        begin
          ChildNode := DocChildren.Item[I];
          if ChildNode.NodeType = ELEMENT_NODE then
          begin
            ChildElement := ChildNode as TDOMElement;
            if ChildElement.TagName = 'library' then { only Collada < 1.4.x }
              ReadLibrary(ChildElement) else
            if ChildElement.TagName = 'library_materials' then { only Collada >= 1.4.x }
              ReadLibraryMaterials(ChildElement) else
            if ChildElement.TagName = 'library_geometries' then { only Collada >= 1.4.x }
              ReadLibraryGeometries(ChildElement) else
            if ChildElement.TagName = 'library_visual_scenes' then { only Collada >= 1.4.x }
              ReadLibraryVisualScenes(ChildElement) else
            if ChildElement.TagName = 'library_controllers' then { only Collada >= 1.4.x }
              ReadLibraryControllers(ChildElement) else
            if ChildElement.TagName = 'scene' then
              ReadSceneElement(ChildElement);
              { other ChildElement.TagName not supported for now }
          end;
        end;
      finally FreeChildNodes(DocChildren); end;

      Result.Meta.PutPreserve('source', ExtractFileName(FileName));
      Result.Meta.KeyData['source-collada-version'] := Version;
    except FreeAndNil(Result); raise; end;
  finally
    FreeAndNil(Doc);
    FreeWithContentsAndNil(Effects);

    { Note: if some material will be used by some geometry, but the
      geometry will not be used, everything will be still Ok
      (no memory leak). First freeing over Materials will not free this
      material (since it's used), but then freeing over Geometries will
      free the geometry together with material (since material usage will
      drop to zero).

      This means that also other complicated case, when one material is
      used twice, once by unused geometry node, second time by used geometry
      node, is also Ok. }

    VRMLNodesList_FreeUnusedAndNil(Materials);
    FreeAndNil(Geometries);

    VRMLNodesList_FreeUnusedAndNil(VisualScenes);

    FreeWithContentsAndNil(Controllers);
  end;
end;

end.
