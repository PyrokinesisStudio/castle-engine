{
  Copyright 2001-2008 Michalis Kamburelis.

  This file is part of "Kambi VRML game engine".

  "Kambi VRML game engine" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "Kambi VRML game engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "Kambi VRML game engine"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  ----------------------------------------------------------------------------
}

{ @abstract(TGLWindow is a window with associated OpenGL context.)

  @link(Glwm) object (instance of class @link(TGLWindowsManager))
  is a manager of all active (that is, visible) @link(TGLWindow) windows.

  Using this unit:

  @orderedList(
    @item(Declare and create @link(TGLWindow) instance.
      Or simply use unit @link(GLW_Win) (or @link(GLW_Demo) or
      @link(GLW_Navigated)), these units give you already initialized
      instance of TGLWindow class in global variable Glw.)

    @item(Assign Glw properties and callbacks like
      @link(TGLWindow.OnDraw OnDraw),
      @link(TGLWindow.OnResize OnResize),
      @link(TGLWindow.Width Width),
      @link(TGLWindow.Height Height),
      @link(TGLWindow.Caption Caption).)

    @item(Call @link(TGLWindow.Init Glw.Init),
      this will actually show the window and it's
      associated OpenGL context. It also calls
      @link(TGLWindow.EventInit EventInit)
      (@link(TGLWindow.OnInit OnInit) callback)
      and @link(TGLWindow.EventResize EventResize)
      (@link(TGLWindow.OnResize OnResize) callback).)

    @item(Call @link(TGLWindowsManager.Loop Glwm.Loop).
      This will enter message loop that will call
      appropriate windows' callbacks at appropriate times
      (OnDraw, OnKeyDown, OnResize, OnIdle and many more).
      There are also some Glwm callbacks, like
      @link(TGLWindowsManager.OnIdle Glwm.OnIdle).

      For more advanced needs you can use something like
        @longCode(#  while Glwm.ProcessMessage do <something>;#)
      instead of Glwm.Loop.

      You can also call @link(TGLWindow.InitLoop Glw.InitLoop),
      this is just a shortcut for Glw.Init + Glwm.Loop.)

    @item(Glwm.Loop ends when you call @link(TGLWindowsManager.Quit Glwm.Quit)
      or when you close last visible window using @link(TGLWindow.Close Close(true)).

      User is also allowed to close a window using WindowManager facilities
      (clicking on "X" button in the frame corner, pressing Alt+F4 or something
      like that). By default, such user action will make window close
      (but you can freely customize what your program does when user
      tries to close the window using callback
      @link(TGLWindow.OnCloseQuery OnCloseQuery)).)
  )

  So the simplest example of using this unit can look like this:

@longcode(#
  uses GLWindow, GLW_Win;

  procedure Draw(Glwin: TGLWindow);
  begin  ...  end;

  procedure Resize(Glwin: TGLWindow);
  begin  ...  end;

  begin
   Glw.OnResize := @Resize;
   Glw.InitLoop('Simplest GLWindow example', @Draw);
  end.
#)

  @italic(More object-oriented approach):
  Instead of assigning callbacks (OnDraw, OnResize etc.) you can
  also derive a new class from TGLWindow and override some of virtual
  methods, like EventDraw, EventResize etc. Every callback OnXxx
  has a corresponding EventXxx method. In TGLWindow class,
  all EventXxx methods simply call appropriate OnXxx callbacks
  (this way you can use whatever approach you like -- OOP or not-OOP).

  This is a second version of the "simplest example" program above,
  this time using OOP approach:

@longcode(#
  uses GLWindow;

  type
    TMyWindow = class(TGLWindow)
      procedure EventDraw; override;
      procedure EventResize; override;
    end;

  procedure TMyWindow.EventDraw;
  begin  ...  end;

  procedure TMyWindow.EventResize;
  begin  ...  end;

  var
    Glw: TMyWindow;
  begin
    Glw := TMyWindow.Create;
    try
      Glw.Caption := 'Simplest GLWindow example using more OOP';
      Glw.InitLoop;
    finally Glw.Free end;
  end.
#)

  The non-OOP approach has one advantage: you can easily switch all callbacks
  to some other set of callbacks using TGLWindowCallbacks,
  TGLWindow.GetCallbacksState, TGLWindow.SetCallbacksState.
  Using these functions I implemented unit
  @link(GLWinModes) and then, on top of this, I implemented some very
  handy things like modal message boxes (unit @link(GLWinMessages))
  and progress bar (unit @link(ProgressGL)). These units give you some typical
  GUI capabilities, and they are in pure OpenGL.

  Using OOP approach (overriding EventXxx methods instead of registering OnXxx
  callbacks) you can not do such things so easily -- in general, you have
  to define something to turn off special EventXxx functionality
  (like SetDemoOptions in TGLWindowDemo and UseNavigator in TGLWindowNavigator)
  and you have to turn them off/on when using GLWinModes
  (mentioned TGLWindowDemo and TGLWindowNavigator are already handled in
  GLWinModes). TODO: I shall do some virtual methods in TGLWindow
  to make this easy.

  Random features list:

  @unorderedList(

    @item(TGLWindowsManager.ProcessMessage method.
      This allows you to reimplement
      event loop handling, which is crucial for implementing things
      like @link(MessageInputQuery) function that does modal GUI dialog box.)

    @item(TGLWindow.KeysDown to easily and reliably check which keys
      are pressed. Also TGLWindow.CharactersDown.)

    @item(Frames per second measuring, see
      @link(TGLWindow.FpsActive FpsActive),
      @link(TGLWindow.FpsFrameTime FpsFrameTime),
      @link(TGLWindow.FpsRealTime FpsRealTime) and
      other FpsXxx properties and methods in TGLWindow class.)

    @item(A menu bar under WinAPI and GTK backends.

      You can attach a menu to a window. Menu structure is constructed using
      various descendants of TMenuEntry class.
      Then you have to assign such menu structure
      to TGLWindow.MainMenu property. When GLWindow is implemented on top
      of GTK_1 or GTK_2 or WINAPI or GLUT we will show this menu and call
      TGLWindow.EventMenuCommand (TGLWindow.OnMenuCommand) when user clicks some menu item.
      Other implementations (XLIB for now) ignore MainMenu.

      See @code(kambi_vrml_game_engine/opengl/examples/menu_test.pasprogram)
      for an example how to use menu.)

    @item(Changing screen resolution and bit depth,
      see TGLWindowsManager.VideoChange.

      Also you can request various OpenGL buffers: color buffer with alpha
      channel (@link(TGLWindow.AlphaBits AlphaBits)),
      stencil buffer (@link(TGLWindow.StencilBufferBits StencilBufferBits)),
      double buffer (@link(TGLWindow.DoubleBuffer DoubleBuffer)), accumulation buffer
      (@link(TGLWindow.AccumBufferBits AccumBufferBits)),
      multisampling (full-screen antialiasing) buffers (@link(TGLWindow.MultiSampling MultiSampling))?
      )

    @item(You can use native modal dialogs for things such as file selection.
      GTK implementation will use GTK dialogs, WinAPI implementation
      will use Windows dialog boxes, XLib implementation will fall back
      on GLWinMessages text input.

      See TGLWindow.FileDialog (for opening and saving files) and
      TGLWindow.ColorDialog (for choosing RGB colors).)

    @item(TGLWindow.ParseParameters method allows you to easily initialize TGLWindow
      properties like initial size and position using command-line
      parameters like @code(@--geometry WIDTHxHEIGHT), @code(@--display) etc.)
  )
}

unit GLWindow;

{$I kambiconf.inc}
{$I openglmac.inc}

{ Choose GLWindow implementation ------------------------------------------ }

{ You must define one of the symbols GLWINDOW_GTK_1, GLWINDOW_GTK_2,
  GLWINDOW_WINAPI (only under Windows),  GLWINDOW_XLIB (only where X11
  and Xlib are available, which usually means "only under UNIX"),
  GLWINDOW_GLUT.

  Of course the list of available implementations may be extended
  with time (although I do not plan it for now, since I'm happy with
  available implementations).

  Here are short descriptions for each implementation:

  GLWINDOW_GTK_1 and GLWINDOW_GTK_2
    GLWINDOW_GTK_1 is based on GTK 1.x (>= 1.2) using GtkGLArea widget.
    Made around beginning of march 2004.

    GLWINDOW_GTK_2 is based on GTK 2.x, using GtkGLExt extension.
    Made 2005-02.

    MainMenu is implemented as a nice-looking GTK menu bar.
    Dialog windows implemented using GTK dialog windows.

    Implementations on top of GTK should work under any OS where GTK works.
    Currently both GTK_1 and GTK_2 are tested under Linux, FreeBSD and Windows.
    GTK_2 is also tested on Mac OS X.

    GLWINDOW_GTK_1:
    Known problems of only GLWINDOW_GTK_1 (fixed in GTK_2):
    - Some key shortcuts for menu items will not work,
      so don't use them. It seems that this is an issue with GTK 1,
      that simply can't be fixed in GLWindow.
      These keys are: Delete, BackSpace, '?' key, Tab.
      All of them work in GLWINDOW_GTK_2 version, with the exception
      of Tab key.
    - When FullScreen = true and MainMenu <> nil, result is not perfect
      because things like gnome-panel may cover your fullscreen window.
      Solved in GLWINDOW_GTK_2, can't be cleanly solved with GTK_1.
    - Under Windows be warned that GTK 1.3 has somewhat buggy
      key events handling - sometimes I don't get keyup events for
      appropriate keys, sometimes keydown events for some keys
      are temporarily blocked. A little code in glwindow_gtk.inc
      was added to workaround some problems, but definitely
      this still does not work as smoothly as it should.
    - Menu mnemonics are not implemented (I don't know how to *easily*
      do them in GTK_1, and I don't really care since GTK_2 version
      is completely stable now). They are simply removed when Caption
      is displayed.
    - File filters are not implemented. This is fixed in GTK_2 by
      using newer GtkFileChooser.

    GLWINDOW_GTK_2:
    This is now stable and tested and is much better than GTK_1.
    At some point, this may be renamed to simply GLWINDOW_GTK
    and compatilibity with GTK 1.x may be dropped.

    Also FullScreen is cleanly implemented in GTK_2,
    never using override_redirect,
    so Alt+Tab always works (even when your window is fullscreen),
    and things like gnome-panel will never cover your fullscreen window.

    Known problems:
    - TryVideoChange is not implemented, i.e. always returns false.
      I don't know how to cleanly implement it using GTK.
    - Under Windows, window will be always resizeable by user, even if
      you set ResizeAllowed <> raAllowed.
      This is masked in our unit (so your OnResize callback will not get
      to know such thing), so it's harmless for correctness of your programs,
      but, anyway, user can do it.

  GLWINDOW_WINAPI
    Based on Windows API.
    MainMenu is implemented as WinAPI menu bar. So it looks nice.
    Dialog windows are implemented as common Windows dialog boxes.

  GLWINDOW_XLIB
    Based on XLib units. No X toolkit is used.

    MainMenu is not implemented (it's ignored).
    That's not easy to implement when you don't want to use any X toolkit.
    And it's not a good idea to implement it yourself (without any standard
    GUI toolkit) --- this makes many Xlib programs ugly, because every single one
    uses his own GUI. In other words:
    if you want to have MainMenu then just use GLWINDOW_GTK_1/2.

    Dialog boxes are implemented using GLWinMessages.MessageXxx.
    So they are not very comfortable to user, but they work.

  GLWINDOW_GLUT
    Based on glut library. There's little use of implementing
    GLWindow on top of glut library since the initial idea of GLWindow
    was to overcome many glut shortcomings. The only advantage of this is that
    such implementation of GLWindow may be used for various testing purposes.

    MainMenu is implemented as glut pop-up menu. Activated by right mouse button.
    Looks ugly and has a lot of usability problems, but works.

    TryVideoChange is simply not implemented, always returns false.

    Known problems:
    (they are specific to GLWINDOW_GLUT and will not be fixed.
    Just use other GLWINDOW_xxx backend if you don't want these problems):
    - Lack of Glwm.ProcessMesssages (although freeglut allows me to fix it,
      maybe I'll do it someday)
    - Glwm.Loop does never return (because it must be implemented as a
      single call to glutMainLoop)
    - Key up / down (with K_xxx constants) are rather poorly simulated.
    - FlushRedisplay always redraws the window
      (it can't know whether window really needs redraw or not,
      so it redraws it always).
    - Even when ResizeAllowed <> raNotAllowed user will be able
      to change size of our window (using window manager-specific
      things, like dragging our window's border)
      but we will simply "pretend" that nothing happened
      (TGLWindow instance will not change it's Width/Height,
      will not do OnResize event etc.).
      Similar with (Min|Max)(Width|Height) constraints:
      they can't be forced using glut, we will simply ignore
      the fact if they will be broken by user.
    - I can't pass to glut value of StencilBufferBits so
      I'm simply saying to glut that I want stencil buffer
      when StencilBufferBits > 0, and then I'm checking
      using glutGet(GLUT_WINDOW_STENCIL_SIZE) how many stencil bits I have.
      Analogous for DepthBufferBits, AlphaBits, AccumBufferBits.
    - Menu mnemonics are not implemented.
      They are simply removed when Caption is displayed.
    - CustomCursor is not implemented. Cursor = gcCursor is treated like gcDefault.

  GLWINDOW_TEMPLATE
    This is a special dummy implementation, useful only as an example for programmers
    that want to implement another GLWindow backend (e.g. based on Mac OS X Carbon).
    It compiles, but actually nothing works --- file glwindow_implementation_template.inc
    is just a dummy implementation with TO-DO marks that you should fill.
}

{ If GLWindow implementation is not choosen at this point, choose
  default (best, most functional and stable) implementation
  for a given OS.

  This way you can override configuration below by compiling GLWindow
  with some GLWINDOW_xxx symbol already defined. }
{$ifndef GLWINDOW_WINAPI}
 {$ifndef GLWINDOW_XLIB}
  {$ifndef GLWINDOW_GLUT}
   {$ifndef GLWINDOW_GTK_1}
    {$ifndef GLWINDOW_GTK_2}
     {$ifdef MSWINDOWS}
       {$define GLWINDOW_WINAPI}
       { $define GLWINDOW_GTK_2}
       { $define GLWINDOW_GTK_1}
       { $define GLWINDOW_GLUT}
       { $define GLWINDOW_TEMPLATE}
     {$endif}
     {$ifdef UNIX}
       {$define GLWINDOW_GTK_2}
       { $define GLWINDOW_GTK_1}
       { $define GLWINDOW_XLIB}
       { $define GLWINDOW_GLUT}
       { $define GLWINDOW_TEMPLATE}
     {$endif}
    {$endif}
   {$endif}
  {$endif}
 {$endif}
{$endif}

{ To make new GL Window implementation -------------------------------------

  - Define a symbol like GLWINDOW_FOO for a new implementation,
    document it in the "available implementations list" above.
  - Create a file glwindow_foo.inc with contents from
    glwindow_implementation_template.inc
    and conditionally include it from glwindow_implementation_specific.inc.
  - Adjust defining GLWINDOW_HAS_PROCESS_MESSAGE,
    GLWINDOW_HAS_VIDEO_CHANGE and GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN
    for your implementation.
  - Implement all methods in glwindow_foo.inc. You wil find the specification
    what each method should do in the specification of the interface of this
    module.
  - Call all TGLWindow.DoXxx functions at appropriate places from your
    implementation.
    You can call all DoIdle and DoTimer for all Glwm.Active[] windows
    using Glwm.DoActiveWindowsIdle/Timer (this will give usually inefficient
    but working implementation)
  - Call TGLWindowsManager.DoSelfIdle and DoSelfTimer when appropriate.
    Remember that you can always assume that the ONLY existing instance of
    TGLWindowsManager is Glwm.
  Some important things that can be easily forgotten:
  - Remember that probably you will have to call ReleaseAllKeysAndMouse
    when user switches to another window or activates MainMenu.
}

{ Configure some debugging options of GLWindow ---------------------------- }

{ Ponizsze opcje nie moga byc ustawiane gdzies globalnie -
  idea jest taka ze zeby zmienic te ustawienia bedziesz
  modyfikowal kod ponizej. Innymi slowy, wszystkie ponizsze ustawienia
  maja charakter jakichs pomocy do debuggowania programow ktore uzywaja
  GLWindow i nie ma sensu jakos automatyzowac tego (tzn. zebys mogl
  modyfikowac te opcje nie modyfikujac zrodel GLWindow.pas). }

{ Zdefiniuj GLWINDOW_LOGFILE aby w tym module bylo generowanych troche wywolan
  do LogWrite. W tej chwili oznacza to otoczenie wszystkich TGLWindow.EventXxx
  klauzulami LogWrite('event xxx begin') LogWrite('event xxx end').
  Jest to wygodne gdy chcesz sie dowiedziec w ktorym z callbackow okna OnXxx program
  sie wywala.

  Jezeli bedzie zdefiniowane GLWINDOW_LOGFILE_IDLELIKE i GLWINDOW_LOGFILE
  to dodatkowo do logfile beda szly zdarzenia OnIdle i OnTimer, ktore normalnie
  sa wylaczone z logowania (bo zabieraja bardzo duzo miejsca w logu bo
  sa wywolywane bardzo czesto).
}
{ $define GLWINDOW_LOGFILE}
{ $define GLWINDOW_LOGFILE_IDLELIKE}
{$ifndef GLWINDOW_LOGFILE}
  {$undef GLWINDOW_LOGFILE_IDLELIKE}
{$endif}

{ zdefiniuj symbol GLWINDOW_CHECK_GL_ERRORS_AFTER_DRAW aby w DoDraw,
  a wiec po zwyczajnym wywolaniu EventDraw a wiec i OnDraw,
  wywolywal CheckGLErrors z KambiGLUtils ktore sprawdzi czy zaszly jakies
  bledy OpenGLa (przez glGetError) i jesli tak - rzuci wyjatek.
}
{$ifdef DEBUG}
  {$define GLWINDOW_CHECK_GL_ERRORS_AFTER_DRAW}
{$endif}

{ Configure internal things ---------------------------------------- }

{$ifdef GLWINDOW_GTK_1} {$define GLWINDOW_GTK_ANY} {$endif}
{$ifdef GLWINDOW_GTK_2} {$define GLWINDOW_GTK_ANY} {$endif}

{ Two reasons why sometimes GTK backend call some X-specific things:

  1. Grrrr. Implementing TGLWindow.SetMousePosition is a real hack for GTK.

     First of all, there is no GDK or GTK function for this.
     (confirmed by google, e.g. see here
     [http://mail.gnome.org/archives/gtk-list/2001-January/msg00035.html]).
     You have to bypass GTK and use things like Xlib's XWarpPointer or
     Windows' SetCursorPos. So this is getting very dirty already ---
     suddenly GLWindow's GTK backend stops to be portable.

     Moreover, to use XWarpPointer, you have to get Xlib parameters
     (X window id and display pointer) from GTK window. And here comes
     another surprise, this time caused by FPC bindings: GTK 1 bindings
     don't include macro GDK_WINDOW_XID. They include macro
     GDK_WINDOW_XDISPLAY but it seems incorrectly defined
     (should take GdkWindow not PGdkWindowPrivate ?).
     GTK 2 bindings don't include these macros too, but GTK 2 library contains
     functions gdk_x11_drawable_get_xid/xdisplay and I can get to them.

     All in all, right now I implemented TGLWindow.SetMousePosition
     only for GTK 2 under Unix. It's possible to do this for GTK 1 under Unix,
     but more hacking is needed (hint: fix GTK 1 bindings in this regard).
     It's possible to do this for Windows, you have to use SetCursorPos
     (see the real Windows backend TGLWindow.SetMousePosition implementation).

  2. Screen resizing.

     I have to use there XF86VidMode extension, just like for GLWINDOW_XLIB
     backend. And, just like for TGLWindow.SetMousePosition, I'll need
     for this some functions available only in GTK 2 library that
     "uncover" X11 internals related to GTK for me. }
{$ifdef GLWINDOW_GTK_2}
  {$ifdef UNIX}
    {$define GLWINDOW_GTK_WITH_XLIB}
  {$endif}
{$endif}

{ An important property of a GLWindow implementation is whether such
  implementation can provide TGLWindowManager.ProcessMessage method.
  E.g. glut implementation cannot provide this. Xlib and WinAPI can.
  We're defining symbol GLWINDOW_HAS_PROCESS_MESSAGE for such implementations.
  A special include file GLWindow_has_process_message.inc is provided
  to help such implementations.
  Implementations without TGLWindowManager.ProcessMessage usually use some
  higher-level interface. They are slightly easier to implement, but they
  lack functionality -- I need TGLWindowManager.ProcessMessage to do such
  things as GLWinMessages. }
{$undef GLWINDOW_HAS_PROCESS_MESSAGE}
{$ifdef GLWINDOW_WINAPI}  {$define GLWINDOW_HAS_PROCESS_MESSAGE} {$endif}
{$ifdef GLWINDOW_XLIB}    {$define GLWINDOW_HAS_PROCESS_MESSAGE} {$endif}
{$ifdef GLWINDOW_GTK_ANY} {$define GLWINDOW_HAS_PROCESS_MESSAGE} {$endif}
{$ifdef GLWINDOW_TEMPLATE}{$define GLWINDOW_HAS_PROCESS_MESSAGE} {$endif}

{ Does implementation implement TryVideoChange and VideoReset methods ?
  (if this will not be defined, we will use TryVideoChange that always
  returns false and VideoReset that is NOOP). }
{$undef GLWINDOW_HAS_VIDEO_CHANGE}
{$ifdef GLWINDOW_WINAPI}
  {$define GLWINDOW_HAS_VIDEO_CHANGE}
{$endif}
{$ifdef GLWINDOW_XLIB}
  {$define GLWINDOW_HAS_VIDEO_CHANGE}
  {$define GLWINDOW_USE_XF86VMODE}
{$endif}
{$ifdef GLWINDOW_GTK_ANY}
  {$ifdef UNIX}
    { Hmm. This compiles and basically works, but the new screen is still
      virtual. For now this is disabled. TODO. }
    { $define GLWINDOW_HAS_VIDEO_CHANGE}
    { $define GLWINDOW_USE_XF86VMODE}
  {$endif}
{$endif}

{ See glwindow_private_modifiers_down.inc for description in what
  situations you want to define GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN. }
{$ifdef GLWINDOW_GTK_ANY} {$define GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN} {$endif}
{$ifdef GLWINDOW_XLIB}    {$define GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN} {$endif}

{ TODO list ------------------------------------------------------------------

  (? means "I'm not sure whether to implement it")

  only winapi :
  - windowActive / appActive - byc moze zrobic nieco inaczej i wszedzie ?
    czy decyzja w ProcessMessage o znaczeniu window/appActive jest dobra ?
    byc moze przeniesc z private do public na odczyt ?
  - k_alt zrobic - trzeba przechwytywac sys_keydown ale wtedy
    albo przechwytujemy wszystkie (w rezultacie
    blokujac standardowe klawisze Alt+F4 lub Alt+spacja Windowsowi)
    albo mamy problem gdy user wejdzie w system menu : wtedy dostaniemy
    zdarzenie alt+down ale nikt nie raczy nam przeslac alt+up.
    !@#& Windows. W glutcie po prostu przechwytuja zawsze, blokujac
    Alt+F4 i Alt+spacja. Czy to w ogole mozna zrobic lepiej ?

  only glut :
  - zrobic przechwytywanie klikania na przyciki "Zamknij" pod glutem
    (glut wysyla wtedy PostQuitMessage i konczy program ! nie chce tego !)
  - ReleaseAllKeysAndMouse - call this when user switches to another window
    or activates a menu

  only Xlib :
  - ColorDialog test

  only GLWINDOW_GTK_1/2:
  - in InitImplDepend implement
    MaxWidth/Height (Maybe these properties should be removed ?
      They are made for symmetry with MinWidth/Height. Are they really useful ?)
  - with GTK 2:
    - Implement better fullscreen toggle now (that doesn't need
      recreating window).
      Update docs about capabilities of GTK_2 implementation.
    - Value of propery FullScreen should change at runtime,
      and parts of things that I'm doing now in InitImplDepend
      should be done on such changes.
      This way I should be able to react to fullscreen changes
      forced by user (using window manager, not F11) really cleanly.

  general:
  - napisac jakies programy ktore sprawdzilyby ze
    DepthBufferBits, AlphaBits
    dzialaja, i sprawdzic je pod wszystkimi implementacjami
  - Width, Height, Left, Top zaimplementowac tak zeby przeniesc je
    do sekcji "mozesz nimi pozniej manipulowac" ?
  - zrobic implementacje przez SDL ?
  - use EnumDisplaySettings instead of such variables as
    VideoColorBits / VideoScreenWidth / VideoFrequency,
    do some proc DisplayExists and EnumDisplays
  - do parametru --fullscreen-custom dodac mozliwosc podania
    VideoColorBits, VideoFrequency
  - zrobic zdarzenia mousewheel
  - dodac mozliwosc zrobienia FullScreen w stylu SDLa : program moze zmienic
    okienko na fullscreen ale wewnetrzne Width i Height nie ulegna zmianie
    i program bedzie dzialac w okienku na srodku ekranu, a po bokach
    bedzie czern
  - OnTimer interface sucks -- it doesn't allow you to register many timeout
    functions for different timeouts.
  - add to multi_glwindow testing call to FileDialog and ColorDialog
    to test
  - virtual TGLWindow.TurnOffEventsSpecials ?

  menu things:
  - The method of updating menu (always rebuild menu in MainMenuChanged)
    is awfully simple. Well, it works prefectly, because menus are small
    and it's not a problem to update them whole. But it should be improved.
    Probably the only visible problem is that if you use "tearoffs" with
    GTK menu, they disappear on menu change.
  - For WinAPI, glut: impl Enabled
}

interface

uses
  SysUtils, Math, VectorMath, GL, GLU, GLExt,
  {$ifdef GLWINDOW_GLUT} KambiGlut, {$endif}
  {$ifdef GLWINDOW_WINAPI} Windows, Rects,
    { In FPC < 2.2.2, CommDlg stuff was inside Windows unit. }
    {$ifndef VER2_2_0} {$ifndef VER2_0_0} CommDlg, {$endif} {$endif}
  {$endif}
  {$ifdef GLWINDOW_XLIB} Xlib, XlibUtils, XUtil, X, KeySym, CursorFont, Glx, KambiGlx, {$endif}
  {$ifdef GLWINDOW_USE_XF86VMODE} KambiXF86VMode, {$endif}
  {$ifdef GLWINDOW_GTK_WITH_XLIB} X, Xlib, {$endif}
  {$ifdef GLWINDOW_GTK_1} Glib, Gdk, Gtk, GtkGLArea, {$endif}
  {$ifdef GLWINDOW_GTK_2} Glib2, Gdk2, Gtk2, GdkGLExt, GtkGLExt, KambiDynLib, {$endif}
  {$ifdef GLWINDOW_LOGFILE} LogFile, {$endif}
  KambiUtils, KambiClassUtils, KambiGLUtils, Images, Keys, Navigation,
  RaysWindow, KambiStringUtils, KambiFilesUtils, KambiTimeUtils,
  FileFilters;

{$define read_interface}

{ ---------------------------------------------------------------------

  I'm aliasing here TKey type and key constants from Keys unit,
  this way code that uses GLWindow unit has automcatically
  available TKey type and key constants (because a lot of code
  using GLWindow unit uses also these type/constant, so I want
  to avoid adding "Keys" unit to uses clauses).

  Once the "reuse" keyword will be implemented in FPC,
  this can be done using something like "reuse Keys".
}

type
  TKey = Keys.TKey;
const
  K_None = Keys.K_None;

  K_BackSpace = Keys.K_BackSpace;
  K_Tab = Keys.K_Tab;
  K_Enter = Keys.K_Enter;

  K_Minus = Keys.K_Minus;
  K_Shift = Keys.K_Shift;
  K_Ctrl = Keys.K_Ctrl;
  K_Alt = Keys.K_Alt;
  K_Plus = Keys.K_Plus;

  K_Escape = Keys.K_Escape;
  K_Space = Keys.K_Space;
  K_PageUp = Keys.K_PageUp;
  K_PageDown = Keys.K_PageDown;
  K_End = Keys.K_End;
  K_Home = Keys.K_Home;
  K_Left = Keys.K_Left;
  K_Up = Keys.K_Up;
  K_Right = Keys.K_Right;
  K_Down = Keys.K_Down;
  K_Insert = Keys.K_Insert;
  K_Delete = Keys.K_Delete;

  K_Numpad_Plus = Keys.K_Numpad_Plus;
  K_Numpad_Minus = Keys.K_Numpad_Minus;

  K_0 = Keys.K_0;  K_1 = Keys.K_1;  K_2 = Keys.K_2;  K_3 = Keys.K_3;
  K_4 = Keys.K_4;  K_5 = Keys.K_5;  K_6 = Keys.K_6;  K_7 = Keys.K_7;
  K_8 = Keys.K_8;  K_9 = Keys.K_9;

  K_A = Keys.K_A;  K_B = Keys.K_B;  K_C = Keys.K_C;  K_D = Keys.K_D;
  K_E = Keys.K_E;  K_F = Keys.K_F;  K_G = Keys.K_G;  K_H = Keys.K_H;
  K_I = Keys.K_I;  K_J = Keys.K_J;  K_K = Keys.K_K;  K_L = Keys.K_L;
  K_M = Keys.K_M;  K_N = Keys.K_N;  K_O = Keys.K_O;  K_P = Keys.K_P;
  K_Q = Keys.K_Q;  K_R = Keys.K_R;  K_S = Keys.K_S;  K_T = Keys.K_T;
  K_U = Keys.K_U;  K_V = Keys.K_V;  K_W = Keys.K_W;  K_X = Keys.K_X;
  K_Y = Keys.K_Y;  K_Z = Keys.K_Z;

  K_F1 = Keys.K_F1;  K_F2 = Keys.K_F2;  K_F3 = Keys.K_F3;  K_F4 = Keys.K_F4;
  K_F5 = Keys.K_F5;  K_F6 = Keys.K_F6;  K_F7 = Keys.K_F7;  K_F8 = Keys.K_F8;
  K_F9 = Keys.K_F9;  K_F10 = Keys.K_F10;  K_F11 = Keys.K_F11;  K_F12 = Keys.K_F12;

  K_Comma = Keys.K_Comma;
  K_Period = Keys.K_Period;

{ --------------------------------------------------------------------- }

{ @section(Export types and consts related to TMouseButton from
  Navigation unit) }

type
  { }
  TMouseButton = Navigation.TMouseButton;
  TMouseButtons = Navigation.TMouseButtons;

const
  mbLeft = Navigation.mbLeft;
  mbMiddle = Navigation.mbMiddle;
  mbRight = Navigation.mbRight;

const
  GLWindowPositionCenter = -1000000;
  GLWindowDefaultSize = -1000000;

type
  TGLWindowParseOption = (poGeometry, poScreenGeometry, poDisplay);
  TGLWindowParseOptions = set of TGLWindowParseOption;
  PGLWindowParseOptions = ^TGLWindowParseOptions;

const
  { Constant below contains all "normal" command-line options,
    that most programs using GLWindow should be able to handle
    without any problems.

    In other words, most programs calling @link(TGLWindow.ParseParameters)
    method can safely pass as the 1st parameter this constant,
    StandardParseOptions.
    Or they can simply call overloaded version of TGLWindow.ParseParameters
    that doesn't take any parameters, it is always equivalent to
    calling TGLWindow.ParseParameters(StandardParseOptions).

    In case you are not sure what precisely >> "normal" command-line options <<
    mean: well, I'm unsure too. If that bothers you, just don't
    use this constant and always specify list of parameters
    for TGLWindow.ParseParameters explicitly. }
  StandardParseOptions: TGLWindowParseOptions = [poGeometry, poScreenGeometry,
    poDisplay];

  DefaultDepthBufferBits = 16;

type
  TGLWindow = class;

  {$I glwindowmenu.inc}

  TIdleFunc = procedure;
  TGLWindowFunc = procedure(Glwin: TGLWindow);
  TDrawFunc = TGLWindowFunc;
  TKeyCharFunc = procedure(Glwin: TGLWindow; Key: TKey; C: char);
  TMouseMoveFunc = procedure(Glwin: TGLWindow; NewX, NewY: Integer);
  TMouseUpDownFunc = procedure(Glwin: TGLWindow; Button: TMouseButton);
  TMenuCommandFunc = procedure(Glwin: TGLWindow; Item: TMenuItem);

  TDynArrayItem_2 = TGLWindowFunc;
  PDynArrayItem_2 = ^TGLWindowFunc;
  {$define DYNARRAY_2_IS_FUNCTION}
  {$I dynarray_2.inc}
  { This is a list of @link(TGLWindowFunc) procedures. }
  TDynGLWindowFuncArray = class(TDynArray_2)
  public
    { This calls all Items that are not nil.
      It passes them glwin parameter. }
    procedure ExecuteAll(Glwin: TGLWindow);
  end;

  { This record is useful to save the state of all callbacks
    of @link(TGLWindow), with the exception of OnInit and OnClose callbacks.
    This is used in @link(TGLWindow.GetCallbacksState)
    and @link(TGLWindow.SetCallbacksState).
    See unit GLWinModes for example when such thing is useful. }
  TGLWindowCallbacks = record
    MouseMove: TMouseMoveFunc;
    MouseDown, MouseUp: TMouseUpDownFunc;
    KeyDown, KeyUp: TKeyCharFunc;
    BeforeDraw, Draw, CloseQuery, Idle, Timer: TGLWindowFunc;
    Resize: TGLWindowFunc;
    MenuCommand: TMenuCommandFunc;
    { When expanding this type: remember to also expand
      implementation of TGLWindow.GetCallbacksState and
      TGLWindow.SetCallbacksState.

      @seealso DefaultCallbacksState }
  end;

  { }
  TResizeAllowed = (raNotAllowed, raOnlyAtInit, raAllowed);

  EGLContextNotPossible = class(Exception);

  { Values for TGLWindow.Cursor.

    gcDefault, gcNone, gcCustom have somewhat special meanings.
    The rest are some cursor images will well-defined meanings for the user,
    their exact look may depend on current window manager theme etc.  }
  TGLWindowCursor = (
    { Leave cursor as default, decided by a window manager. }
    gcDefault,
    { Make cursor invisible. }
    gcNone,
    { Use custom cursor image in TGLWindow.CustomCursor. }
    gcCustom,
    { Standard arrow, indicates, well, that user can point / click something. }
    gcStandard,
    { Indicates the program is busy and user should wait. }
    gcWait,
    { Text cursor, indicates that there's text under the cursor, which commonly means
      that it can be selectec, or that user can click to gain focus to text box. }
    gcText,
    { Indicates something active is under cursor, usually for links. }
    gcHand);

  {$define read_interface_types}
  {$I glwindow_implementation_specific.inc}
  {$undef read_interface_types}

  TGLWindow = class

  { Include GLWindow-implementation-specific parts of TGLWindow class.
    Note that in every included file I should specify the scope
    (usually "private") of things that are added to TGLWindow class.

    (I used to specify in this file "private" scope as the starting
    scope, but this was useless since "glwindow_implementation_specific.inc"
    may include more than 1 file for some implementations.
    E.g. GLWINDOW_XLIB causes "glwindow_implementation_specific.inc"
    to include 3 different files. So it's consequent to just request
    that in each of these files I specify scope explicitly).

    This way some implementations may expose some protected or even public
    things that are specific for them. }

  {$define read_tglwindow_interface}
  {$I glwindow_implementation_specific.inc}
  {$undef read_tglwindow_interface}

  private
    FWidth, FHeight, FLeft, FTop: Integer;
    FOnInit: TGLWindowFunc;
    FOnBeforeDraw, FOnDraw: TDrawFunc;
    FOnResize: TGLWindowFunc;
    FOnClose: TGLWindowFunc;
    FOnCloseQuery: TGLWindowFunc;
    FOnKeyDown, FOnKeyUp: TKeyCharFunc;
    FMouseMove: TMouseMoveFunc;
    FMouseDown, FMouseUp: TMouseUpDownFunc;
    FOnIdle, FOnTimer: TGLWindowFunc;
    FFullScreen, FDoubleBuffer: boolean;
    FResizeAllowed: TResizeAllowed;
    FMousePressed: TMouseButtons;
    FMouseX, FMouseY: integer;
    FColorBits: integer;

    FCursor: TGLWindowCursor;
    procedure SetCursor(const Value: TGLWindowCursor);

    FCustomCursor: TRGBAlphaImage;
    procedure SetCustomCursor(const Value: TRGBAlphaImage);

    FAutoRedisplay: boolean;
    procedure SetAutoRedisplay(value: boolean);

    FCaption: string;
    procedure SetCaption(const Value: string);

    { FClosed = are we outside of Init..Close }
    FClosed: boolean;

    { EventInitCalled = has OnInit been called from Init ? }
    EventInitCalled: boolean;
    closeerrors: string; { Used by Close. }

    { Konkretne implementacje nie robia wlasnej wersji TGLWindow.Init,
      robia InitImplDepend -- tam sie inicjuja + musza wywolac
      Glwm.ActiveAdd(Self) w dogodnej chwili.

      Here's a list of properties that should be made "visible" to the user
      in InitImplDepend:
        Width, Height, Left, Top, FullScreen
        Cursor, CustomCursor (remember that changes to this after InitImplDepend
          should also be allowed)
        ResizeAllowed (DoResize already implements appropriate
          checks, but implementation should provide user with visual clues that
          the window may / may not be resized)
        MainMenu (display MainMenu and provide way to call DoMenuCommand)

      OpenGL context must be initialized honouring these properties:
        DoubleBuffer, StencilBufferBits, DepthBufferBits, AlphaBits,
        AccumBufferBits, MultiSampling }
    procedure InitImplDepend;

    { Podobnie jak z Init i InitImplDepend jest tez z Close, wystarczy napisac
      CloseImplDepend (w CloseImplDepend juz nie trzeba wywolywac
      ActiveRemove, to jest wywolane w Close niezaleznym od implementacji).
      W czasie CloseImplDepend wyjatkowo wszelkie bledy nie powinny powodowac wyjatku
      (chociaz ew. przezyjemy jesli wyleci jakis wyjatek z CloseImplDepend) -
      zamiast tego powinny wywolywac CloseError. Powod : Close powinno, bez wzgledu
      na bledy, probowac mozliwie duzo sfinalizowac. }
    procedure CloseImplDepend;

    procedure CloseError(const error: string);

    { Call this method only when DoubleBuffered and if you already did
      MakeCurrent. This will swap OpenGL buffers. (implicit glFlush is
      guaranteed) }
    procedure SwapBuffers;

    { Processing recursively from MainMenu, set ParentWindow of all TMenuEntry
      to AParentWindow. This is valid NOP if MainMenu = nil.
      This is called from Init, MainMenuChanged (with AParentWindow = Self)
      and from Close (with AParentWindow = nil). }
    procedure MainMenuSetParent(AParentWindow: TGLWindow);

    { This is called by MainMenuChanged. This can assume that (not Closed) and
      (MainMenu <> nil). This should update whole user interface
      (implementation-specific) to show new contents of MainMenu.
      This does not update ParentWindow fields of TMenuEntry, this will be
      already done in MainMenuChanged. }
    procedure MainMenuChangedImplDepend;

    { This is something internal for communicating between GLWindowMenu and
      TGLWindow.

      This is called from GLWindowMenu after every change in MainMenu that
      should be reflected in user interface. It's called only when
      MainMenu <> nil.
      Note: state of MainMenu <> nil must not change, i.e. you can't use this
      to remove or add main menu to window. You can call this method
      only if MainMenu <> nil when you did Init on this object and
      then you changed something in MainMenu.Items.

      This is also called from SetMainMenu when (not Closed).

      Calling this on a closed window is a valid NOP. }
    procedure MainMenuChanged;

    procedure CreateImplDepend;

    { For all keys that are down (KeysDown[k]) call DoKeyUp(k).
      For all mouse buttons that are down (mb in MousePressed) call DoMouseUp(mb).
      If GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN is defined,
      this calls at the beginning SetPrivateModifiersDown(..., ..., false)
      to say that all keys are up.

      Useful when user somehow switches to another window / control
      (e.g. when he opens our MainMenu), such that we are then unable to catch
      following KeyUps and MouseUps. So user simply STOPS controlling outr
      program with mouse and keyboard, so we have to assume that he releases
      all keys and mouse buttons.

      Nie widze chwilowo zastosowania dla MousePressed[*] := false,
      ale jest to konsekwentne. Z punktu widzenia programu w momencie wejscia
      usera do menu user przestaje kontrolowac program (tzn. okienko OpenGLa)
      przy pomocy myszy i klawiatury. }
    procedure ReleaseAllKeysAndMouse;

    { This should be implemented in backend-specific GLWindow parts.
      When in DoKeyDown we get some key event that specifies that
      some menu item should be called -- if RedirectKeyDownToMenuCommand,
      DoKeyDown will do DoMenuCommand. Else DoKeyDown will do nothing.

      This should be implemened as "Result := true" if we have to process
      keypresses in GLWindow to pass them as menu commands, e.g. when GLWindow
      works on top of glut or Xlib.
      When GLWindow works on top of GTK or WinAPI that allow us to do a "real"
      menu, this should be implemented as "Result := false". }
    function RedirectKeyDownToMenuCommand: boolean;

    { DoXxx methods ------------------------------------------------------------

      The general idea of DoXxx methods: "Call me on Xxx event.
      I'll do everything that needs to be done and that is not specific to
      GLWindow-implementation.".
      GLWindow-implementation specific methods should not ever call EventXxx
      directly (and nothing should ever call OnXxx directly besides EventXxx),
      they should use DoXxx methods.

      Remember that no DoXxx may be called from CloseImplDepend.

      Below is the detailed specification, but summing some things up
      you don't have to worry about these things when you use DoXxx methods
      (these things are fully handled by DoXxx methods):
      - updating state of MousePressed
      - updating state of KeysDown
      - updating state of CharactersDown
      - updating state of MouseX, MouseY
      - calling MakeCurrent before every EventXxx
      - flushing gl commands (and swapping gl buffers when DoubleBuffer'ing)
      - taking care of AutoRedisplay
      - updating Width, Height (and updating it with accordance to
        Min/MaxWidth/Height and ResizeAllowed)
      - checking MainMenu.Enabled
    }

    { DoResize with FromIndependentInit = true is called only once
      (and exactly once) from TGLWindow.Init implementation.
      So all GLWindow-implementation code should always
      pass FromIndependentInit = false (EVEN if it may be called from
      InitImplDepend (that is called before DoResize in Init) !).

      Some more notes about calling DoResize from InitImplDepend:
      in this case DoResize will NOT call EventResize (since the first callback
      that should be called for a window is EventInit). We will always after
      EventInit call DoResize(..., true), so this should not be a problem
      anywhere. You can simply call DoResize from InitImplDepend to tell us what
      real Width/Height we have, and the real EventResize will be called
      just at a later time.

      You can pass here ANY AWidth, AHeight. It will be automatically clipped
      here to fit in Min/MaxWidth/Height and to satisfy ResizeAllowed.

      Also MakeCurrent + EventResize will be called (probably; sometimes
      DoResize may decide to not call EventResize - e.g. when ResizeAllowed
      =raNotAllowed and FirstTime = false then it's useless to call here
      EventResize).

      Remember : this function does not automatically call PostRedisplay.
      You must make sure that soon after changing size of the window
      you will call DoDraw (e.g. you can call PostRedisplay after
      calling DoResize; but usually (under WinAPI, Xlib, glut, gtk)
      it's not needed, i.e. WinAPI, Xlib, glut and gtk all take care of this
      automatically). }
    procedure DoResize(AWidth, AHeight: integer; FromIndependentInit: boolean);
    { Wywoluj kiedy user kliknie na przycisku "Zamknij" itp.
      Wywola EventCloseQuery i ew. Close (and Close will execute EventClose,
      CloseImplDepend etc.). Note that there is no DoClose method and there
      should not be such method : always use DoCloseQuery. }
    procedure DoCloseQuery;

    { Do MakeCurrent,
         EventBeforeDraw,
         EventDraw (inside Fps_RenderStart/End)
         flush gl command pipeline (and swap gl buffers if DoubleBuffer)

         take care of AutoRedisplay -
           if AutoRedisplay then
           begin
            if Glwm.AutoRedisplayAddToList > 0 then

              make sure that Glwm.AutoRedisplayList contains Self
              (i.e. add Self to Glwm.AutoRedisplayList, unless
              Glwm.AutoRedisplayList already contains Self)

            else
              PostRedisplay;

           So specific GLWindow implementations need not to worry about
           AutoRedisplay. They only have to implement PostRedisplay.

           Also, some implementations (currently this concerns gtk
           implementations) should disallow doing PostRedisplay caused
           by AutoRedisplay = true when they are inside ProcessAllMessages
           (since it can, in some situations, as with GTK bindings,
           mean that ProcessAllMessages would hang forever, since
           there would be always pending message to redisplay the window).
           Such implementations want to do

             if AutoRedisplayAddToList = 0 then AutoRedisplayList.Clear;
             Inc(AutoRedisplayAddToList);

           at the beginning and then

             Dec(AutoRedisplayAddToList);
             if AutoRedisplayAddToList = 0 then AutoRedisplayList.PostRedisplay;

           at the end, see glwindow_gtk.inc ProcessAllMessages implementation
           for example (with proper try...finally clause around).
           Also such backends should do
             AutoRedisplayList := TGLWindowsList.Create;
           and
             FreeAndNil(AutoRedisplayList);
           at appropriate places (e.g. in
           TGLWindowManager.Create/DestroyImplDependent)
           and
             Glwm.AutoRedisplayList.Delete(Self);
           in TGLWindow.CloseImplDepend (to make sure that destroyed windows
           are not a memebers of AutoRedisplayList).

           Note that AutoRedisplayAddToList is an integer (not a simple boolean)
           to be safe in case someone calls ProcessAllMessages recursively
           (e.g. call ProcessAllMessages that calls OnMouseDown that calls
           ProcessAllMessages inside). }
    procedure DoDraw;

    PressedKeyToCharacter: array [TKey] of Char;
    PressedCharacterToKey: array [Char] of TKey;

    { DoKeyDown/Up: pass here key that is pressed down or released up.

      Only DoKeyDown: pass also CharKey. Pass Key = K_None if this is not
      representable as TKey, pass CharKey =#0 if this is not representable
      as char. But never pass both Key = K_None and CharKey =#0
      (this would have no meaning).

      Only DoKeyUp: never pass Key = K_None.

      If you call DoKeyUp while (not KeysDown[Key]) it will be ignored
      (will not do any EventKeyUp etc. - just NOOP).

      This will
         update KeysDown accordingly,
         update ChatactersDown accordingly,
         DoKeyDown: may here call DoMenuCommand
           (and then it will NOT call MakeCurrent and EventKeyDown)
         MakeCurrent,
         EventKeyDown/Up.

       Note that CharactersDown are updated on the basis that given
       TKey corresponds to character. PressedKeyToCharacter and
       PressedCharacterToKey arrays
       store 1-1 mapping between pressed keys and pressed characters.
       So at any given point, we consider that given character corresponds
       to only one key. So CharactersDown may get fooled by user in some
       complicated cases, that's acceptable (since unavoidable,
       see CharactersDown comments). If a new key corresponding to already
       pressed character is pressed, this new key replaces previous key
       in the mapping.

       PressedKeyToCharacter reverse each other, that is
         PressedCharacterToKey[PressedKeyToCharacter[Key]] = Key and
         PressedKeyToCharacter[PressedCharacterToKey[C]] = C
       for all keys and characters, assuming that
       PressedCharacterToKey[C] <> K_None and
       PressedKeyToCharacter[Key] <> #0 (which indicate that no character
       is pressed / no character is pressed corresponding to this key).

       Storing correspondence means that if each KeyDown is paired by
       KeyUp, then each pressed Character will also be released.
       (Since each pressed Character *always* has a corresponding key
       that activated it.)

       PressedXxx arrays may seem complicated, but their programming
       is trivial and they allow me to update CharactersDown array
       quickly and reliably.
    }
    procedure DoKeyDown(key: TKey; CharKey: char);
    procedure DoKeyUp(key: TKey);
    { Do MakeCurrent,
         EventMouseMove,
         update MouseX, Y }
    procedure DoMouseMove(x, y: integer);
    { DoMouseDown/Up:
        update FMouseX, FMouseY (so that before EventMouseDown/Up position
          of the mouse is set to the current, precise, position)
        update MousePressed
        MakeCurrent
        EventMouseDown/Up }
    procedure DoMouseDown(x, y: integer; btn: TMouseButton);
    procedure DoMouseUp(x, y: integer; btn: TMouseButton);
    procedure DoIdle;
    procedure DoTimer;
    { Just call it when user presses some MenuItem.
      This takes care of MainMenu.Enabled,
        MakeCurent,
        Item.DoCommand,
        optional EventMenuCommand or EventKeyDown }
    procedure DoMenuCommand(Item: TMenuItem);

  private
    { Things named "Fps_" are internal things.
      Things named "Fps" (without "_") are public. }

    { Fps_FramesRendered = 0 means "no frame was rendered yet" }
    Fps_FramesRendered: Int64;
    { if Fps_FramesRendered > 0 then Fps_FirstTimeTick is the time of first
      Fps_RenderEnd call. }
    Fps_FirstTimeTick: LongWord;
    { set in Fps_RenderStart }
    Fps_RenderStartTime: TKamTimerResult;
    { how much time passed inside frame rendering }
    Fps_FrameTimePassed: TKamTimerResult;

    FFpsActive: boolean;
    procedure SetFPSActive(value: boolean);

    FDrawSpeed: Single;
    FIdleSpeed: Single;

    DoIgnoreNextIdleSpeed: boolean;

    LastIdleStartTime: TKamTimerResult;

    FFpsSecondsToAutoReset: Cardinal;
    FFpsHoldsAfterReset: TMilisecTime;
    procedure Fps_RenderStart;
    procedure Fps_RenderEnd;
  private
    { zwraca opis aktualnych zadanych wlasciwosci od buforow OpenGLa
      (czy single/double (na podstawie DoubleBuffer), czy indexed,
      ile bitow na red/green/blue/alpha channel (m.in. AlphaBits),
      ile bitow zadasz od innych buforow (Depth/Stencil/AccumBufferBits) itp.
      Uzywa zmiennych tego okienka, tzn. opisuje "czego zadasz",
      NIE "co masz", w ogole okienko nie musi byc (not Closed)
      i moze nie byc zadnego aktualnego gl contextu zeby ta funkcja dzialala.
      Jej wynik jest przydatny np. do konstruowania komunikatow dla wyjatku
      EGLContextNotPossible. }
    function RequestedBufferAttributes: string;
    { sprawdza czy wartosci Provided* spelniaja odpowiednie warunki zapisane w zmiennych
      tego obiektu, tzn. czy
        ProvidedStencilBits >= StencilBufferBits and
        ProvidedDepthBits >= DepthBufferBits ...
      itd. Jesli nie to rzuca wyjatek EGLContextNotPossible z komunikatem w rodzaju
      'ProviderName provided depth buffer with ProvidedStencilBits but StencilBufferBits
      required' - i.e. this message states _what_ requirements can not be fullfilled
      and what API (e.g. ProviderName = 'Glut' / 'ChoosePixelFormat') is responsible for
      this.

      Note that ProvidedMultiSampling is not checked if MultiSampling is <= 1.
      In other words, if multisampling was not required, ProvidedMultiSampling
      doesn't matter --- it's Ok even ProvidedMultiSampling = 0 and
      MultiSampling = 1, which happens commonly (since our MultiSampling = 1 means
      "no multisampling" and is default, but most backends returns num_samples
      (or something equivalent) as = 0 when multisampling not supported). }
    procedure CheckRequestedBufferAttributes(const ProviderName: string;
      ProvidedStencilBits, ProvidedDepthBits, ProvidedAlphaBits,
      ProvidedAccumRedBits, ProvidedAccumGreenBits, ProvidedAccumBlueBits,
      ProvidedAccumAlphaBits, ProvidedMultiSampling: Cardinal);

    FDepthBufferBits: Cardinal;
    FStencilBufferBits: Cardinal;
    FAlphaBits: Cardinal;
    FMultiSampling: Cardinal;
    FGtkIconName: string;
    FWindowVisible: boolean;
  public

    { EventXxx virtual methods -------------------------------------------------

      W sekcji private zdefiniowane sa procedury DoXxx ktore wykonuja niezalezna
      od implementacji GLWindow robote z opakowaniem zdarzen OnXxx.
      Oto jak to jest robione : najwazniejsza czescia tych procedur jest wywolanie
      odpowiedniej procedury EventXxx. Procedura EventXxx ma za zadanie
      z kolei wywolac odpowiednie OnXxx (o ile to jest zdefinoiwane, czyli
      Assigned(OnXxx)) i ew. OnXxxList jezeli zdarzenie ma swoja wersje listowa,
      jak OnInit czy OnClose. Wszystkie procedury OnXxx sa wywolywane
      przez
        try OnXxx except on BreakGLWinEvent do ; end
      albo cos rownowaznego. Czyli rzucenie w czasie OnXxx wyjatkiem
      BreakGLWinEvent spowoduje powrot do aktualnego EventXxx a
      sam wyjatek zostanie wyciszony (wylapany i zignorowany).
      W przypadku zdarzen listowych OnXxxList wyjatek zostanie wylapany
      w obrebie wywolania pojedynczego elementu listy, tzn.
      BreakGLWinEvent spowoduje przejscie do wykonywania nastepnej na liscie
      OnXxxList precedury.

      Pytanie : po co nam ten dodatkowy stopien do zejscia, tzn. procedury
      EventXxx ? Mianowicie, procedury EventXxx sa wirtualne. W zwiazku z tym
      pozwalaja one na konstruowanie uzytecznych podklas klasy TGLWindow.

      Przy okazji procedury te sa nie w protected ale w public aby umozliwic
      wygodne wywolywanie ich spoza klasy TGLWindow, np. gdy chcesz recznie
      spowodowac OnResize na jakims window wygodniej jest wywolac
        glwin.EventResize
      niz
        if Assigned(glwin.OnResize) then glwin.OnResize(glwin);
      albo nawet
        if Assigned(glwin.OnResize) then
         try glwin.OnResize(glwin) except on BreakGLWinevent do ; end

      Pamietaj przy tym ze przed kazdym EventXxx musi byc wywolane MakeCurrent !
      (DoXxx robia to automatycznie, podobnie jak pare wewnetrznych rzeczy).  }
    procedure EventResize; virtual;
    procedure EventInit; virtual;
    procedure EventClose; virtual;
    { EventCloseQuery ma zwrocic true aby DoCloseQuery zrobilo Close }
    function EventCloseQuery: boolean; virtual;
    procedure EventDraw; virtual;
    procedure EventBeforeDraw; virtual;
    procedure EventKeyDown(Key: TKey; C: char); virtual;
    procedure EventKeyUp(key: TKey; C: char); virtual;
    procedure EventMouseMove(newX, newY: integer); virtual;
    procedure EventMouseDown(btn: TMouseButton); virtual;
    procedure EventMouseUp(btn: TMouseButton); virtual;
    { UWAGA : jezeli pokrywasz EventIdle/Timer musisz prawdopodobnie takze pokryc
      funkcje AllowsProcessMessageSuspend -- patrz do jej opisu. }
    procedure EventIdle; virtual;
    procedure EventTimer; virtual;
    procedure EventMenuCommand(Item: TMenuItem); virtual;

    { w Glwm.ProcessMessage wykonywana jest bardzo wazna rzecz zaoszczedzajaca
      cykle procesora : program ktory nie ma zadnego idle ani timer zarejestrowanego
      ani nie zostalo wywolane Glwm.Quit ma prawo "zawisnac" na oczekiwanie
      message'a od winsystemu.

      Aby takie cos dzialalo musi byc sposob aby uzyskac od okna informacje
      czy wykonuje ono cos w EventIdle / EventTimer. (no bo jezeli tak to nie wolno
      nam robic takiego zawieszania sie).
      W bazowej klasie TGLWindow EventIdle / EventTimer wywoluja tylko
      OnIdle / OnTimer, w zwiazku z czym ta funkcja zwraca
        not (Assigned(OnIdle) or Assigned(OnTimer))
      ale to sie moze zmienic jesli pokryjesz EventIdle/ Timer i dorobisz tam
      jakas funkcjonalnosc. }
    function AllowsProcessMessageSuspend: boolean; virtual;
  public
    { ----------------------------------------------------------------------------
      rzeczy ktore mozesz inicjowac tylko przed wywolaniem Init. Potem sa juz
      read-only (chociaz moga byc uaktualniane na skutek wewnetrznych wywolan;
      np. Width i Height moga sie zmieniac, co zostanie zaznaczone
      wywolaniem OnResize). Left i Top tez beda uaktualniane. }

    { Left, Top, Width i Height caly czas okreslaja ClientRect - a wiec
      obszar na ktorym bedzie tworzony i uzywany kontekst OpenGLa.
      Nie uwzgledniaja ramek jakie WindowManager dodal do naszego okienka.
      And they don't take space taken by menu (if MainMenu <> nil) into account.
      So these are always dimensions of our 3d window --- nothing more, nothing less.

      min/maxWidth/Height i ResizeAllowed ustawiaja scisle ograniczenia na
      Width i Height ktore sa poprawiane zgodnie z tymi wlasciwosciami podczas
      wywolywania Init. PO wywolaniu Init (tzn. pomiedzy Init a Close) jest
      gwarantowane ze
        - minWidth<= Width<= maxWidth
        - minHeight<= Height<= maxHeight
        - Width i Height nie ulegna zmianie jezeli not ResizeAllowed <> raAllowed

      Poniewaz WindowManager (WindowManager X-ow lub Windows) moze dosc swobodnie
      traktowac nasze wymagania min/maxWidth/Height i ResizeAllowed wiec jest
      niestety mozliwe ze rzeczywiste wymiary okienka beda sie roznic od
      zadanych w width, height - zauwazysz to zwlaszcza jezeli ustawiles
      istotne ograniczenia na min/maxWidth/Height lub jezeli ustawiles
      ResizeAllowed <> raAllowed. Wiec TGLWindow robi tak ze moze nieco przeklamywac
      wlasciwosci Width / Height - tak zeby nasze wlasciwoci Width/Height ZAWSZE
      spelnialy zadane ograniczenia, nawet jezeli w rezultacie moga sie one czasem
      roznic od rzeczywistych rozmiarow okienka.

      Aplikacje polegajace na tym na poczatku (po zainicjowaniu gl contextu)
      glViewport jest ustawiony na wymiary okienka moga byc spokojne : wprawdzie
      rzeczywiste okienko moze nie miec rozmiarow Width/Height, poczatkowe
      glViewport bedzie na pewno zgodne z NASZYMI Width/Height.

      GLWindowDefaultSize will be treated specifically:
      at Init, will be replaced with some comfortable size slightly
      smaller than screen size.
    }
    property Width: integer read FWidth write FWidth default GLWindowDefaultSize;
    property Height: integer read FHeight write FHeight default GLWindowDefaultSize;

    { jezeli Left / Top rowne sa GLWindowPositionCenter w momencie wywolania Init
      to zostana zainicjowane tak zeby okienko bylo na srodku ekranu. }
    property Left: integer read {$ifdef GLWINDOW_GLUT}GetLeft{$else}FLeft{$endif} write FLeft; { = GLWindowPositionCenter }
    property Top :integer read {$ifdef GLWINDOW_GLUT}GetTop{$else}FTop{$endif} write FTop; { = GLWindowPositionCenter }
    property FullScreen: boolean read FFullScreen write FFullScreen; { = false }
    { DoubleBuffer to swapBuffers bedzie robione automatycznie po kazdym repaincie.
      jesli false - bedzie robione glFlush. }
    property DoubleBuffer: boolean read FDoubleBuffer write FDoubleBuffer default true;

    { ColorBits : sprobuje ustawic takie bits per pixel tylko dla danego okna.
      Jesli ColorBits = 0 w czasie Init to uzyje Glwm.VideoColorBits
      (chociaz one tez moga byc = 0; wtedy wezmie defaultowe ColorBits jakie
      da nam Windows). Tak czy siak, po zakonczeniu Init ColorBits powiedza
      nam jakie ColorBits otrzymalismy.
      Aby naprawde zmienic ColorBits z duza szansa uzywaj raczej
      Glwm.VideoColorBits i Glwm.VideoChange.

      TODO: uzywanie tej wlasciwosci jest deprecated. Jest ona non-cross-platform,
      interfejs nie czyni zadnych gwarancji ze rzeczywiscie dostaniemy
      wymagane ColorBits, ponadto nie powinnismy zmieniac ColorBits
      po Init - po wyjasnienie dlaczego patrz komentarze do StencilbufferBits.

      @deprecated }
    property ColorBits: integer
      read FColorBits write FColorBits default 0;

    { Sets mouse cursor appearance over this window.
      See TGLWindowCursor for a list of possible values and their meanings.

      TODO: for now, gcCustom is not handled anywhere. }
    property Cursor: TGLWindowCursor read FCursor write SetCursor default gcDefault;

    { Image for cursor, used only when @link(Cursor) = gcCustom.
      We will try hard to use any cursor image as appropriate, but on some platforms
      cursor size may be limited (16 x 16 seems standard for GTK) and cursor
      may be forced to monochrome.

      Note that you still own the TRGBAlphaImage instance passed here --- you're
      responsible for freeing it etc. If this is @nil, and @link(Cursor) = gcCustom,
      then it will be treated like @link(Cursor) = gcDefault. (I don't raise error
      in such case, as that would make changing both Cursor and CustomCursor values
      unnecessarily tricky for the programmer.)

      TODO: for now, this is not implemented. @link(Cursor) ignores gcCustom value,
      under every GLWindow implementation... sorry, CustomCursor is only a plan. }
    property CustomCursor: TRGBAlphaImage read FCustomCursor
      write SetCustomCursor;

    { This instructs window manager to place mouse at NewMouseX and NewMouseY
      position. NewMouseX and NewMouseY are specified just like
      MouseX and MouseY properties are given, so they are relative
      to OpenGL area, and 0,0 is upper-top corner.
      Note that the resulting position may be different than
      MouseX and MouseY, e.g. if part of the window is offscreen then
      window manager will probably refuse to move cursor offscreen.

      This *may* generate normal OnMouseMove event, just as if the
      user moved the mouse. But it's also allowed to not do this.

      Use this only when window is not closed. }
    procedure SetMousePosition(const NewMouseX, NewMouseY: Integer);

    { Naklada ograniczenia na to kiedy i jak Width i Height moga sie zmienic.
      = raNotAllowed oznacza ze Width i Height nie moga sie zmienic
        CHYBA ze po to zeby dostosowac sie do min/maxWidth/Height.
        Tak ostre ograniczenia moga nawet spowodowac ze przy probie Init
        okienka z atrybutem Fullscreen = true flaga Fullscreen moze zostac
        wylaczone na true. Ale masz PEWNOSC ze Width i Height zawsze beda
        rowne zadanym, o ile tylko beda w granicach min/maxWidth/Height.
      = raOnlyAtInit oznacza ze rozmiary okienka moga zostac zainicjowane
        na inne niz podane jezeli np. WindowManager ma obiekcje co do
        zadanych przez nas rozmiarow okienka albo jezeli chcesz miac
        Fullscreen i ScreenWidth/H sa rozne od Width/Height. W tych przypadkach,
        i byc moze takze w innych podobnych rozmiary Width/Height jakie
        dostanie okienko beda rozne od zadanych Width/Height. Ale masz PEWNOSC
        ze po wywolaniu pierwszego callbacka (czyli EventInit (OnInit),
        tuz przed pierwszym EventResize (OnResize))
        Width/Height juz beda stale, dopoki okienko bedzie not Closed.
      = raAllowed jest domyslne i pozwala na najwieksza swobode WindowManagerowi
        i userowi : okienko moze byc zresizowane w dowolnym momencie.
        Oznacza to ze nie tylko Width/Height jakie dostaniesz w pierwszych
        OnInit i OnResize moga byc inne niz te ktorych zazadales ale takze
        w trakcie dzialania programu rozmiary okienka moga sie zmieniac.
        Powinienes
        byc na to przygotowany obslugujac zdarzenie OnResize (ktore w zasadzie
        jest zupelnie zbedne w pozostalych przypadkach, gdy ResizeAllowed<>
        raAllowed), zapewne ustawiajac w nim odpowiednie glViewport i
        uaktualniajac macierz projection.
      ResizeAllowed <> raAllowed oznacza ze do okna bedzie wyslane tylko
        raz OnResize - na poczatku, pod koniec wykonywania Init (chociaz
        w zasadzie i tak bedziesz mogl je zignorowac i obsluzyc wszystko
        w OnInit; chociaz moze czasem bedziesz jednak chcial zapisac
        ustawianie glViewport i projection w OnResize, dla porzadku).
        Poniewaz pierwsze glViewport (przed wywolaniem pierwszych callbackow
        EventInit (OnInit) i EventResize (OnResize) w Init)
        jest wykonane automatycznie to w rezultacie programy
        majace ResizeAllowed <> raAllowed nie musza sie nigdy martwic
        o robienie kiedykolwiek glViewport. }
    property ResizeAllowed: TResizeAllowed read FResizeAllowed write FResizeAllowed;  { = raAllowed }

    { Jest GWARANTOWANE ze dla kazdego nowootwartego okna NAJPIERW zostanie
      wyslany EventInit (OnInit) and THEN EventResize (OnResize).

      This is a sensible and consequential approach -- EventInit (OnInit)
      is always the first executed callback and EventClose (OnClose)
      is always last. Some examples (like gl_win_events.pasprogram)
      confirm that this is really useful.

      One more thing: in EventInit (OnInit) you already have valid
      Width/Height values, i.e. those values were already adjusted
      if ResizeAllowed <> raNotAllowed. If ResizeAllowed = raNotAllowed
      then Width and Height are constant, so this is obvious. }
    property OnInit: TGLWindowFunc read FOnInit write FOnInit; { = nil }

    (* zawsze po wywolaniu OnInit beda wywolywane wszystkie funkcje
       z listy OnInitList. Ten obiekt jest tylko tworzony i niszczony w
       tej klasie, poza tym mozesz na nim robic co ci sie zywnie podoba -
       dodawac, usuwac, przegladac procedury, co chcesz. Oczywiscie najbardziej
       przewidywalne jest zachowanie programu ktory tylko dodaje do tej listy. *)
    OnInitList: TDynGLWindowFuncArray;
  public
    { minimalne i maksymalne rozmiary okna. Musi byc
        0 < minWidth <= maxWidth, 0 < minHeight <= maxHeight.

      Jesli sprobujesz samemu zainicjowac Width lub Height okienka na cos spoza
      tego zakresu - jesli to bedzie mniejsze od minWidth to zostanie przyjete
      minWidth, jesli wieksze od maxWidth - zostanie przyjete maxWidth (tzn.
      zostanie poprawione dopiero w Init !). Bedzie to wykonane nawet jesli
      ResizeAllowed = raNotAllowed ! Wiec pamietaj ze jesli chcesz zeby ResizeAllowed
      = raNotAllowed bylo honorowane - width i height musza sie zawierac w
      min/max Width/Height.
      Podobnie, jezeli ustawisz Fullscreen := true i okaze sie ze rozmiary ekranu
      sa zle - flaga FullScreen zostanie wylaczona. Innymi slowy, niniejsze
      ograniczenia maja priorytet ponad ResizeAllowed, a wszystkie razem
      (min/maxWidth/Height i ResizeAllowed) maja priorytet nad
      Width, Height, FullScreen.

      Tym sposobem ZAWSZE bedzie zachodzic minWidth <= width <= maxWidth, o ile
      tylko not Closed. I wszystko co napisalem dziala tak samo dla Height. }
    MinWidth, MinHeight, MaxWidth, MaxHeight: integer; { = 100, 100, 4000, 4000 }

    { Zadane parametry buforow OpenGLa. }

    { Po zainicjowaniu okienka StencilBufferBits NIE jest ustawiane na uzyskana
      ilosc bitow (np. chcielismy miec 8, ustawilismy StencilBufferBits := 8,
      dostalismy 16, wiec glGetInteger(GL_STENCIL_BITS) = 16,
      ale ciagle StencilBufferBits = 8. To jest przydatne jesli teraz zrobimy
      okienku Close, potem np. zmienimy AccumBufferBits i sprobujemy zrobic
      Init : nie chcielismy w takiej sytuacji zeby StencilBufferBits
      zmienialo sie automatycznie, prawda ?
      Zawsze kiedy chcesz zbadac ile bitow rzeczywiscie masz mozesz uzyc
      glGetInteger. }

    { Required depth buffer precision. Zero means that we don't need
      depth buffer at all. We may get depth buffer with more precision
      than requested (we may even get depth buffer when we set
      DepthBufferBits = 0), this all depends on graphic card.

      Default value is 16 (DefaultDepthBufferBits),
      which is a reasonable default for 3D programs
      that want to work with depth test enabled.

      @italic(Design notes:) One may ask why default value is not 0 ?

      @orderedList(
        @item(
          Most programs using OpenGL use depth testing, so many programs
          would have to call something like @code(Glw.DepthBufferBits := 16).)

        @item(
          Often graphic cards / window systems / OSes give you an OpenGL
          context with depth buffer @italic(even if you don't need depth buffer).
          I don't say that it's bad. But it makes very easy to forget about
          doing @code(DepthBufferBits := something-non-zero;).
          If you're writing 3d program and sitting on some
          system that always gives you depth buffer (even if DepthBufferBits = 0)
          then it may happen that you forget to write in your program
          @longCode(#  glw.DepthBufferBits := 16;#)

          And while on your system everything will work, you will
          receive errors on other systems because you forgot to request a
          depth buffer.)
      )

      Of course, if you are writing a program that does not need depth buffer
      you should set glw.DepthBufferBits := 0. The only advantage of having
      default DepthBufferBits = 16 is that if you forget to set
      Glw.DepthBufferBits := 0 your programs will still work (most graphic cards
      will give you some depth buffer anyway).
      They will just use more resources than they should.
    }
    property DepthBufferBits: Cardinal
      read FDepthBufferBits write FDepthBufferBits default DefaultDepthBufferBits;

    { Required stencil buffer precision, zero means that stencil buffer is
      not needed.

      Just like with other XxxBufferBits property, we may get more
      bits than we requested. But we will never get less --- if window system
      will not be able to provide GL context with requested number of bits,
      @link(Init) will raise an error. }
    property StencilBufferBits: Cardinal
      read FStencilBufferBits write FStencilBufferBits default 0;

    { How many samples are required for multisampling.
      1 means that no multisampling is required.
      Values larger than 1 means that we require OpenGL context with
      multisampling capabilities (GLX_ARB_multisample for glX on Unix
      or WGL_ARB_multisample for wgl on Windows). MultiSampling says how
      many samples per pixel should be done (try typical 2 or 4 values).

      So the only thing remaining for your program to make anti-aliasing
      working is to use core OpenGL extension GL_ARB_multisample:
      [http://opengl.org/registry/specs/ARB/multisample.txt].
      In the usual case, this means simply to call

      @longCode(#  if GL_ARB_multisample then glEnable(GL_MULTISAMPLE_ARB); #)

      and

      @longCode(#  if GL_ARB_multisample then glDisable(GL_MULTISAMPLE_ARB); #)

      Just like with other XxxBufferBits property, we may get more
      samples than we requested (e.g. if you request 3, you will most probably
      get 4...). But we will never get less --- if window system
      will not be able to provide GL context with requested number of bits,
      @link(Init) will raise an error. }
    property MultiSampling: Cardinal
      read FMultiSampling write FMultiSampling default 1;

    { Required number of bits in alpha channel of color buffer.
      Zero means that alpha channel is not needed.

      Just like with other XxxBufferBits property, we may get more
      bits than we requested. But we will never get less --- if window system
      will not be able to provide GL context with requested number of bits,
      @link(Init) will raise an error.

      It's undefined how I'll treat this variable when indexed color mode
      will be possible in TGLWindow. }
    property AlphaBits: Cardinal
      read FAlphaBits write FAlphaBits default 0;

    { Required number of bits in color channels of accumulation buffer.
      Color channel is 0..3: red, green, blue, alpha.
      Zero means that given channel of accumulation buffer is not needed,
      so when the vector is all zeros (default value) this means that
      accumulation buffer is not needed at all.

      Just like with other XxxBufferBits property, we may get more
      bits than we requested. But we will never get less --- if window system
      will not be able to provide GL context with requested number of bits,
      @link(Init) will raise an error. }
    AccumBufferBits: TVector4Cardinal;

    (* TODO: zrobic od razu
         IndexBufferBits: Cardinal; = ????
         IndexedColorBuffer: boolean; { = false }
    *)

    { Name of the icon for this window used by GTK 2 backend.

      This is simply passed to @code(gtk_window_set_icon_name),
      see [http://library.gnome.org/devel/gtk/stable/GtkWindow.html#gtk-window-set-icon-name].
      This allows you to use an installed icon (in /usr/share/icons/
      or ~/.local/share/icons/) for your program. See
      [http://library.gnome.org/devel/integration-guide/stable/icons.html.en]
      for short information how and where to install your icons.

      It's ignored on non-GTK 2 backends. }
    property GtkIconName: string read FGtkIconName write FGtkIconName;

    { @abstract(Should this window be actually displayed on the desktop?
      Set to @false for special tricks.)

      As you can guess, in 99% you want to leave this as @true, as the
      main purpose of the window is to actually be visible and interactive
      on the desktop, right? But in some very special cases you really
      need some OpenGL context but you don't want to display a visible
      window for the user to see. One example is the @--screenshot
      option of view3dscene, see
      [http://vrmlengine.sourceforge.net/view3dscene.php#section_screenshot].

      A cleaner way to achieve this would be to actually initialize
      content to render to off-screen bitmap. This is possibly faster,
      and gives you more possibilities (e.g. window size doesn't limit
      the screenshot size, liki it @italic(can) with current approach).
      But this is the more reliable, easily implemented way, so for now it's
      very useful. }
    property WindowVisible: boolean read FWindowVisible write FWindowVisible default true;
  public

    { -----------------------------------------------------------------------
      rzeczy ktore mozesz inicjowac przed wywolaniem Init ale mozesz tez nimi
      swobodnie manipulowac pozniej. }

    property Caption: string read FCaption write SetCaption; { = ProgramName }

    { This is probably the most important callback.
      You should redraw your window here.

      It will be called when your window contents must be redrawn,
      e.g. after creating a window, after resizing a window, after uncovering
      the window etc. You can also request that this callback should be
      called in a short time by PostRedisplay.

      Note: calling PostRedisplay while in EventDraw (OnDraw) is NOT ignored.
      It means that in a short time next EventDraw (OnDraw) will be called. }
    property OnDraw: TDrawFunc read FOnDraw write FOnDraw; { = nil }

    { OnBeforeDraw will be always called right before OnDraw
      (more specifically, EventBeforDraw will be always called right before
      EventDraw). So those two functions, EventBeforeDraw and EventDraw,
      will be always called sequentially as a pair. So what is the use of
      BeforeDraw ?

      Only one thing differs OnDraw and OnBeforeDraw: time spent in OnBeforeDraw
      (more specifically, in EventBeforeDraw) is NOT counted as "frame time"
      by FpsFrameTime. This is useful when you have something that needs
      to be done from time to time right before OnDraw and that is very
      time-consuming. It such cases it is not desirable to put such time-consuming
      task inside OnDraw because this would cause a sudden big change in
      FpsFrameTime value (and DrawSpeed). So you can avoid this by putting
      this in OnBeforeDraw. Of course, using OnBeforeDraw also means that the
      program will not always be time-based. By using OnBeforeDraw instead
      of OnDraw you're breaking the rules that are designed to make time-based
      program (a program that adjusts itself to the speed of computer it is on).
      But this is sometimes desirable when you have something that you want
      to do really seldom (e.g. only when user presses some special key)
      (but that is also time-consuming).

      E.g. view3dscene uses Scene.Render. From time to time user presses
      a key like "g" or "m" that force the whole Scene to be regenerated.
      This means that a call to Scene.Render inside OnDraw takes sometimes
      much more time than it usually does. This gives some unpleasant effect
      because when the user views the scene using "Examine" mode
      then after pressing "g" DrawSpeed is (for only one short moment !)
      very big. And this means that after pressing "g" user sees 1. first,
      it takes some time to regenerate the model 2. second, after regenerating
      the model there is a sudden jump in the amount the object is rotated
      (because DrawSpeed is big). And the second thing is bad.
      It can avoided by putting Scene.PrepareRender(true) after OnKeyDown,
      OnMouseDown etc. But the simplest (and more elegant) way
      is to put Scene.PrepareRender(true) only in OnBeforeDraw. }
    property OnBeforeDraw: TDrawFunc read FOnBeforeDraw write FOnBeforeDraw; { = nil }

    { OnResize - wywolywane zawsze gdy okienko bedzie zresizowane,
      tzn. gdy zmienia sie width i/lub height tego obiektu.
      Ponadto, jest gwarantowane ze OnResize bedzie wywolane zawsze w czasie Init
      tuz po EventInit (OnInit).
      Przed wywolaniem OnResize width i height okienka sa juz uaktualnione,
      jest zrobione MakeCurrent. Nie ma problemu jesli OnResize = nil,
      chociaz zazwyczaj jest to dobre  miejsce na ustawienie projection matrix.

      Kiedys bylo automatyczne glViewport przed OnResize - teraz NIE JEST,
      patrz old\GLWindow_why_not_Viewport_in_OnResize.txt po wyjasnienie
      dlaczego, w skrocie - zazwyczaj glViewport powinnno isc w parze ze zmiana
      projection i rozbijanie tego latwo doprowadzi nas do bledow w specjalnych
      przypadkach.

      I jeszcze jest gwarantowane ze zdarzenie OnResize zajdzie pierwszy
      raz nawet gdy ResizeAllowed <> raAllowed.

      2D OpenGL programs may want to register here simple
      @link(Resize2D). }
    property OnResize: TGLWindowFunc read FOnResize write FOnResize; { = nil }

    { jesli assigned, to bedzie wywolywane OnClose w momencie zamykania okna -
      czyli robienia Close. Ta procedura jest ostatnia szansa na zrobienie czegos
      zanim kontekst OpenGL'a zostanie zniszczony i jest lustrzanym odbiciem
      OnInit; dobrym miejscem na niszczenie tego co stworzylo OnInit jest wlasnie
      OnClose (np. tutaj niszcz fonty OpenGL'a ktore potrzebuja kontekstu OpenGL'a
      zeby ladnie wyczyscic po sobie zasosby OSa) }
    property OnClose: TGLWindowFunc read FOnClose write FOnClose;

    { podobnie jak OnInit, OnClose tez ma swoja wersje listowa : OnCloseList.
      Patrz komentarze przy OnInitList. }
    public OnCloseList: TDynGLWindowFuncArray;

    { OnKeyDown(Self, Key, c) occurs when user presses some key that
      we can represent as key: TKey and/or c: char.

      Not all keyboard keys can be represented as TKey value. There are
      some keys that generate sensible char values, but still cannot be
      represented as TKey value, e.g. key '/' does not have any K_Xxx
      constant for now but can be expressed as char '/'.
      So you can get Key = K_None is such situations, e.g. OnKeyDown
      will be called like OnKeyDown(Self, K_None, '/').

      Character c is based on pressed key, current Modifiers state,
      state of keys like "Caps-Lock" , maybe some OS configurarion
      (like locale-specific chars, e.g. polish "ogonki"), etc. In general,
      it is operating-system (and window-system, and GLWindow-backend)
      specific. Not all key presses are representable as
      char, so you may get c = #0 in such situations.
      E.g. "up arrow" key does not have a corresponding char code,
      so OnKeyDown may be called like OnKeyDown(Self, K_Up, #0).

      Never will both Key = K_None and c = #0 (this would be rather useless
      event...). (Unless you will explicitely call EventKeyDown(K_None, #0),
      which you should never do.)

      Note: once I had here separate events, OnKeyPress (with only c: char)
      and OnKeyDown (with only Key: TKey). But this was very error-prone:
      for one user key press you could get two events (e.g.
      OnKeyDown(K_C) and then OnKeyPress('c')). Problems with this were easily
      avoidable in small programs (where you can see all your OnKeyDown and
      OnKeyPress handlers in one file), but in large programs they were producing
      very nasty bugs. E.g. imagine that you handle in OnKeyDown key K_Enter
      by doing GLWinMessages.MessageOK. But then each time user presses
      Enter key you
      1. handle it in OnKeyDown calling GLWinMessages.MessageOK
      2. GLWinMessages.MessageOK changes your GLWindow callbacks
         so that OnKeyPress(#13) makes GLWinMessages.MessageOK exit.
      3. but then you're getting OnKeyPress(#13) event (because K_Enter
         is converted to #13 char). So GLWinMessages.MessageOK ends.
      This looked like a bug in GLWinMessages.MessageOK. But actually
      it was a bug in callbacks design: you were getting two callbacks
      (OnKeyDown amd OnKeyPress) for one event (user presses a key).

      polish:
      KeyDown moze byc pod wplywem key repeata.
      Tzn. ze jesli uzytkownik bedzie trzymal klawisz przycisniety to my
      mozemy dostawac co chwila nowe KeyDown. Pod niektorymi
      systemami moze byc wtedy tak ze przed kazdym KeyDown bedziemy
      dostawali "udawane" KeyUp (udawane, bo user tak naprawde ani na chwile
      nie puscil klawisza) a pod niektorymi nie bedziemy dostawali KeyUp
      (bedziemy po prostu dostawali KeyDown(k) podczas gdy juz wczesniej
      KeysDown[k] = true). Piszac program musisz byc gotow na obie mozliwosci.
      Podsumowujac : nie patrz na KeyDown(k) jako na "zdarzenie ktore zachodzi
      gdy KeysDown[k] zmienia sie z false na true". To tak nie dziala.
      Patrz raczej na to jako na zdarzenie po ktorym KeysDown[k] na pewno
      jest true. }
    property OnKeyDown: TKeyCharFunc read FOnKeyDown write FOnKeyDown;

    { Called when user releases a pressed key. I.e. it's called right after
      KeysDown[Key] changed from true to false.

      Key is never K_None.

      C may be #0 is no representable character is released.
      When C is <> #0, we detected that some character is released.
      This is connected with setting CharactersDown[C] from @true to @false.

      Note that reporting characters for "key release" messages is not
      perfect, as various key combinations (sometimes more than one?) may lead
      to generating given character. We have some intelligent algorithm
      for this, used to make CharactersDown table and to detect
      this C for OnKeyUp callback. The idea is that a character is released
      when the key that initially caused the press of this character is
      also released.

      This solves in a determined way problems like
      "what happens if I press Shift, then X,
      then release Shift, then release X". (will "X" be correctly
      released as pressed and then released? yes.
      will small "x" be reported as released at the end? no, as it was never
      pressed.) }
    property OnKeyUp: TKeyCharFunc read FOnKeyUp write FOnKeyUp;

    { Jesli uzytkownik klilknie na znaczku "X" (zamknij
      aplikacje) lub wybierze polecenie "Zamknij" z SysMenu okna lub przycisnie
      Alt-F4 wtedy : jesli OnCloseQuery = nil to okno zostanie zamkniete (Close).
      Natomiast jesli to zdarzenie bedzie assigned okno sie NIE zamknie
      i zostanie wywolane to zdarzenie. W tym zdarzeniu mozna np. spytac sie
      uzytkownika o potwierdzenie i wtedy ew. wywolac metode Close !

      Jesli okno zostanie zamkniete przez wywolanie Close to zdarzenie nie bedzie
      mialo znaczenia.

      When handling this event, you must remember that user
      may try to close our window at any time.
      E.g. if you're implementing here somehing like showing user
      text "You cannot quit now" or asking user "Do you really want to quit"
      remember that while you display such message to user and you're
      processing events (e.g. looking for keypress "Yes" or "No"),
      user may try to close your window again.

      GLWinMessages unit offers some nice routines that you can safely
      use here, e.g. you can use it inside OnCloseQuery like

        if MessageYesNo(glwin, 'Are you sure you want to quit ?') then
         Close;

      Inside MessageYesNo, when we're processing events,
      and waiting for user's answer (yes or no),
      futher OnCloseQuery events will be ignored, so everything will work OK.

      This event is also useful if you want to call Close(false)
      on closing the window (i.e. QuitWhenLastWindowClosed = false).
      By default, if this event is undefined, we call Close(true)
      when user tries to close the window. }
    property OnCloseQuery: TGLWindowFunc read FOnCloseQuery write FOnCloseQuery; { = nil }

    { OnMouseMove : jasne; gdy mysz sie ruszy, wysyla to zdarzenie.
       Parametry : standardowe glwin. Klawisze myszy wcisniete w tym
       momencie masz w mousePressed. Pozycje myszy PRZED przesunieciem
       masz w mouseX, mouseY, a PO przesunieciu - w parametrach newX, newY.
       Oczywiscie, PO wywolaniu EventMouseMove mouseX, mouseY zostana
       odswiezone na newX, newY. Tymczasem ty w trakcie obslugi EventMouseMove
       bedziesz mogl skorzystac z tego ze newX-mouseX, newY-mouseY to przesuniecie
       wzgledne myszy. }
    property OnMouseMove :TMouseMoveFunc read FMouseMove write FMouseMove; { = nil }

    { OnMouseDown : zachodzi gdy przycisnie jakis klawisz myszy.
       Parametry : standardowe glwin, btn = ktory przycisk zrobil down.
       Pozycje myszy w momecie up / down masz w mouseX, mouseY.
       Podobnie jak w glut'cie jest gwarantowane ze po wywolaniu OnMouseDown
       mysz zostanie zlapana i wszystkie komunikaty myszy (OnMouseMove, OnMouseUp)
       beda przekazywane az do wywolania OnMouseUp ktore zwolni wszystkie przyciski
       myszy. W rezultacie mysz moze przyjmowac pozycje spoza (0, 0, width, height) -
       moze wychodzic dowolnie daleko w dowolna strone (takze na wartosci ujemne !)

       @groupBegin }
    property OnMouseDown :TMouseUpDownFunc
      read FMouseDown write FMouseDown {default nil};
    property OnMouseUp :TMouseUpDownFunc
      read FMouseUp write FMouseUp {default nil};
    { @groupEnd }

    { property OnIdle i OnTimer beda zachodzily dla wszystkich okien
      w Glwm.Active[] w momencie gdy zajdzie zdarzenie obiektu Glwm -
      OnIdle lub OnTimer. Tzn. nie zrozumcie mnie zle - zadna kolejnosc
      zdarzen OnIdli Glwm i roznych okien nie jest gwarantowana i beda
      nawet mogly sie przeplatac - ale poza tym OnIdle i OnTimer beda
      wywolywane wtedy gdy logika powiedzialaby ze moze byc wywolane
      Glwm.OnIdle lub OnTimer, odpowiednio.

      Te zdarzenia sa tu przedstawione bo mimo ze OnIdle / OnTimer
      sa zdarzeniami niezwiazanymi z konkretnym okienkiem to jednak
      sa wykorzystywane najczesciej wlasnie aby iterowac po wszystkich /
      niektorych okiekach wsrod Glwm.Active[] i cos w nich robic,
      chociazby sprawdzac ich KeysDown[]. W tej sytuacji jest dobrym
      pomyslem aby robic te zdarzenia w callbacku specyficznym
      dla danego obiektu a nie dla calego Glwm - w ten sposob ulozenie
      danych w obiektach odpowiada rzeczywistym celom do jakiego sa
      uzywane - OnIdle Glwm powinno sie zajmowac tylko sprawami ogolnymi,
      OnIdle w jakims konkretnym okienku - tylko sprawami tego okienka.

      Zachowanie takiej spojnosci nie jest oczywiscie wymagane ale
      moze znacznie pomoc sensownie zorganizowac swoje programy.
      Takze uzywanie takich modulow jak GLWinMessages jest duzo
      latwiejsze i bezpieczniejsze dopoki ograniczamy kod dotykajacy
      danego okienka tylko do callbackow danego okienka - GLWinMessages
      dziala poprawnie przy tym wlasnie zalozeniu.
    }
    property OnIdle: TGLWindowFunc read FOnIdle write FOnIdle; { = nil }
    property OnTimer: TGLWindowFunc read FOnTimer write FOnTimer; { = nil }

    { If AutoRedisplay then you will not have to ever call
      @link(PostRedisplay) -- window will behave like there was always
      pending redraw. Set this to true only if you're sure that you're
      doing some constant animation in your window and you will want
      to constantly redraw yur window. }
    property AutoRedisplay: boolean read fAutoRedisplay write SetAutoRedisplay; { = false }

    { -------------------------------------------------------------------------
      Menu things (menu may be modified at runtime, everything will be
      automatically properly redisplayed etc.) }

  private
    FMainMenu: TMenu;
    procedure SetMainMenu(Value: TMenu);
  public
    { Menu specified using GLWindowMenu objects.
      Caption of MainMenu will be ignored.
      May be nil -> means "no menu".

      You can change this freely while Closed.

      You can change this almost freely while not Closed: you can use
      various properties of TMenuEntry descendants (adding, deleting items
      from TMenu, changing Caption, Key, CharKey, Checked properties --
      anything) and you can change value of MainMenu BUT you must not
      change MainMenu <> nil state when the window is not Closed.
      I.e. if you called Init with MainMenu = nil, then MainMenu must stay
      nil unit Close. If you called Init with MainMenu <> nil, then you
      can assign other MainMenu values while not Closed, but only values
      <>nil. I.e. you can't set MainMenu to nil if you called Init
      with MainMenu <> nil.
      See @code(kambi_vrml_game_engine/opengl/examples/menu_test_alternative.pasprogram)
      for demo of changing value of MainMenu while window is not Closed.

      Note that MainMenu.Enabled is honoured (as well as Enabled
      for all menu items inside, of course).
      You can use this to disallow user from clicking on the whole
      menu. When MainMenu.Enabled = @false then
      no MenuItem.DoCommand, no EventMenuCommand
      will be called when user presses some menu item.
      When user presses some keyboard shortcut for some menu item,
      no MenuItem.DoCommand and no EventMenuCommand will be called,
      but instead normal EventKeyDown (OnKeyDown) will be called.

      When it is useful to set this to false ?
      For example hen using GLWinModes. When you're changing modes (e.g. at the
      beginning of GLWinMessages.MessageOk) you're temporary setting
      OnMenuCommand to nil, but this doesn't block TMenuItem.DoCommand
      functions. The only way to block menu from triggering ANY event is to
      set this to MainMenu.Enabled to @false. }
    property MainMenu: TMenu read FMainMenu write SetMainMenu;

    { If true then in TGLWindow destructor MainMenu will be destroyed too
      (if not nil, od course). Usually this is something useful. }
    OwnsMainMenu: boolean; { = true }

    { Each time user will choose some menu item (let's name it MenuItem),
      we will call MenuItem.DoCommand. If this will return false then
      we will call EventMenuCommand (that will call OnMenuCommand). }
    OnMenuCommand: TMenuCommandFunc; { = nil }

    { Mouse state ------------------------------------------------------------ }

    { MousePressed to zbior aktualnie wcisnietych przyciskow myszy.
      Jak nietrudno zgadnac, jest automatycznie zarzadzany przed zajmowaniem sie
      OnMouseDown / Up, wiec powinien byc zawsze aktualny i w kazdym miejscu
      programu mozna z niego korzystac (o ile not Closed, oczywiscie).
      No i masz gwarancje ze kazda zmiana mousePressed MUSI byc potwierdzona
      wywolaniem odpowiedniego EventDown / Up. }
    property MousePressed: TMouseButtons read FMousePressed;

    { MouseX, MouseY : pozycja ostatniego zdarzenia myszy we wspolrzednych okna :
      lewy-gorny rog drawing area to (0, 0) a
      prawy-dolny to (glwin.width-1, glwin.height-1) (a wiec y jest odwrotne
       niz typowa perspektywa Ortho2D ustawiana OpenGL'owi).
      Jednak ze wzgledu na mouse-capture (patrz komentarz przy OnMouseDown)
       mouseX, mouseY moga wybiegac poza ten obszar, nawet na wartosci ujemne !
      Poniewaz wsrod zdarzen myszy jest tez EventMouseMove wiec spokojnie
       mozesz to traktowac jako aktualna pozycje myszy. Jedyne miejsce w ktorym
       znaczenie mouseX, mouseY sie zmienia to wnetrze EventMouseMove a wiec
       i OnMouseMove : masz wtedy parametry newX, newY ktore okreslaja aktualna
       pozycje myszy a mouseX, mouseY staja sie POPRZEDNIA zarejestrowana pozycja
       myszy (tzn. nie uwzgledniono jeszcze newX, newY). }
    property MouseX: integer read FMouseX;
    property MouseY: integer read FMouseY;

    { -------------------------------------------------------------------------
      General things to manage this window }

  public
    { UserData is a container for Your data associated with a given TGLWindow
      object. No code in this unit touches the value of this field. }
    UserData: Pointer; { = nil }

    property Closed: boolean read FClosed;

    (*Initialize window (create window with GL context, show window).

      @unorderedList(
        @item(Create window, it's OpenGL area, optionally it's menu.)
        @item(Create OpenGL context associated with it's OpenGL area.)
        @item(Show the window.)
        @item(Call LoadAllExtensions.
          This way every information initialized by this
          is ready, like GLVersion, GLUVersion, extensions are checked
          and initialized.)

        @item(Initial events called:@br
          Call MakeCurrent, EventInit (OnInit)@br
          Call MakeCurrent + EventResize (OnResize)@br
          Call MakeCurrent once again, to be sure that after Init
          active OpenGL context is the one associated with newly created
          window (in case you would change active OpenGL context inside
          EventResize (OnResize), which is allowed).)
      )

      Call to Init is ignored if not Closed., i.e. if window is already inited.

      Raises EGLContextNotPossible if it's not possible to obtain
      OpenGL context with specified attributes.
      For example, maybe you set (Depth|Stencil|Accum)BufferBits properties
      to too high values. It's guaranteed that even when EGLContextNotPossible
      was raised, the window remains in correct (Closed) state, so you
      can try to lower some requirements and call init once again.
      For example:

@longCode(#
  Shadows := true;
  Glw.StencilBufferBits := 8;
  try
    Glw.Init;
  except
    on EGLContextNotPossible do
    begin
      Shadows := false;
      Glw.StencilBufferBits := 0;
      { try to init once again, this time without requesting stencil buffer }
      Glw.Init;
    end;
  end;
#)

      @raises(EGLContextNotPossible If it's not possible to obtain
        OpenGL context with specified attributes.)
    *)
    procedure Init;

    { Close window.

      @unorderedList(
        @item(Calls EventClose (and OnClose).)
        @item(Hides window, destroys it.)
        @item(
          if this was the only open TGLWindow window
          and QuitWhenLastWindowClosed = true then
          this calls Glwm.Quit.)
      )

      Note that often there's no need to call Close explicitly in your program,
      because in destructor of this object we call Close, to be sure
      that window is closed.

      TODO: zrobic param boolean CloseFromDestroyQuitWhenLastWindowClosed ?
      As for now Close from destructor is called always with
      QuitWhenLastWindowClosed = true.

      Call to Close is ignored if window is already Closed. }
    procedure Close(QuitWhenLastWindowClosed: boolean = true);

    { PostRedisplay says that contents of OpenGL area of this window
      must be redrawn. At the nearest free time (e.g. when events queue
      is empty in case of GLWINDOW_XLIB and GLWINDOW_WINAPI)
      we will call EventBeforeDraw, EventDraw (that call OnBeforeDraw, OnDraw)
      (and we will flush gl commands and swap buffers and do other
      things like that; see private method @code(DoDraw)
      for more precise description).

      Note: if window is Closed then PostRedisplay is acceptable NOOP. }
    procedure PostRedisplay;

    { FlushRedisplay mowi : jezeli zawartosc tego okna powinna zostac
      przemalowana (tzn. jest zgloszone i niezrealizowane PostRedisplay
      na tym oknie, przy czym pamietaj ze PostRedisplay moze byc takze
      zglaszane do okienka GLWindow przez WindowManagera) to wywolaj
      OnDraw TERAZ. To znaczy TERAZ - zanim FlushRedisplay powroci
      bedzie juz wykonane przemalowanie (o ile tylko bylo potrzebne).

      Nie powinienes zbyt czesto potrzebowac tej funkcji. Psuje ona
      cala optymalizacje wyswietlania ktora stara sie wykonac wyswietlanie
      jak najpozniej wykonujac najpierw wszystko inne. Generalnie, napisanie
      kodu w rodzaju begin PostRedisplay; FlushRedisplay end powoduje
      natychmiastowe i bezwarunkowe odswiezenie ekranu. Kompletny nonsens,
      nie do takich celow pisalem ten unit.

      Ale jest jeden wazny moment kiedy naprawde powinienes wywolac ta funkcje :
      kiedy zamierzasz zrobic zrzut wlasnego ekranu (np. przez glReadPixels).
      Zalezy ci wtedy zeby ekran przedstawial rzeczywiscie to co powinien -
      - i nie chcesz byc zalezny od tego czy ostatnie PostRedisplay zdazylo
      czy tez nie zdazylo sie wywolac. Przed kazdym glReadPixels i generalnie
      przed innymi operacjami odczytujacymi zawartosc buforow OpenGLa powinienes
      sie upewnic ze sa one odswiezone wywolujac FlushRedisplay;

      Pamietaj ze FlushRedisplay moze wywolac EventDraw (OnDraw).
      Wiec lepiej zebys zadbal zeby wywolywane OnDraw dzialalo dobrze
      w momencie wywolania FlushRedisplay. }
    procedure FlushRedisplay;

    { Each GLWindow has it's own OpenGL context. Before each window callback
      the calling window is guaranteed to be the current one - but sometimes
      you may need to manually set openGL context to a particular window.
      Note : Init of a window sets this window implicitly to be the current one ! }
    procedure MakeCurrent;

    { The intention is to do:
        FlushRedisplay + KambiGLUtils.SaveScreenXxx_noflush(..,GL_FRONT)
      However: see comments at KambiGLUtils.SaveScreenXxx_noflush for some
      warnings about saving from front buffer. In short : you really
      do not want to save contents of front buffer.
      So when DoubleBuffer = true, these functions actually do something
      more reliable:
        EventDraw + KambiGLUtils.SaveScreenXxx_noflush(..,GL_BACK).
      (when DoubleBuffer = false no such workaround is possible so just
      be prepared for some nasty visual effects, as described in comments at
      KambiGLUtils.SaveScreenXxx_noflush).

      If you *intent* to use something other than GL_FRONT,
      or simply have some more advanced needs than just "save current screen",
      use KambiGLUtils.SaveScreenXxx_noflush instead of these. }
    procedure SaveScreen(const fname: string); overload;
    function SaveScreen: TRGBImage; overload;
    function SaveScreen( const xpos, ypos, SavedAreaWidth,
      SavedAreaHeight: integer): TRGBImage; overload;
    function SaveScreenToDisplayList: TGLuint; overload;
    function SaveScreenToDisplayList(const xpos, ypos, SavedAreaWidth,
      SavedAreaHeight: integer): TGLuint; overload;

    {$ifndef GLWINDOW_GLUT}
    { This asks user where to save the file (using @link(FileDialog),
      as default filename taking ProposedFname), if user accepts
      calls glwin.SaveScreen(user-chosen-file-name); }
    procedure SaveScreenDialog(ProposedFileName: string);
    {$endif}

    { @groupbegin

      Methods for simply saving and restoring value of all OnXxx
      callbacks (with the exception of OnInit, OnInitList and
      OnClose, OnCloseList).

      @seealso DefaultCallbacksState }
    function GetCallbacksState: TGLWindowCallbacks;
    procedure SetCallbacksState(const Callbacks: TGLWindowCallbacks);
    { @groupend }

    constructor Create;
    destructor Destroy; override;

  public

    { KeysDown ------------------------------------------------------------ }

    { You can check whether some key is pressed using this array.
      Note that this array is read-only from outside of this class !
      Always KeysDown[K_None] = false. }
    KeysDown: TKeysBooleans;

    { You can check whether some character is pressed using this array.
      Note that this array is read-only from outside of this class !
      Always CharactersDown[#0] = false.

      Note that since a given character may be generated by various
      key combinations, this doesn't work as reliably as KeysDown.
      Although we do our best, and in practice this works Ok.
      But still checking for keys on KeysDown, when possible, it adviced. }
    CharactersDown: TCharactersBooleans;

    { The same thing as Keys.ModifiersDown(KeysDown). }
    function ModifiersDown: TModifierKeys;

    { FPS -------------------------------------------------------------------- }

    { Turn on/off frames per second measuring.
      Before using FpsFrameTime or FpsRealTime you must set FpsActive to @true. }
    property FpsActive: boolean read FFpsActive write SetFpsActive;

    { Rendering speed in frames per second. This tells FPS,
      if we would only call Draw (EventDraw, OnDraw) all the time.
      That is, this doesn't take into account time spent on other activities,
      like OnIdle, and it doesn't take into account that frames are possibly
      not rendered continously (when AutoRedisplay = @false, we may render
      frames seldom, because there's no need to do it more often).

      @seealso FpsRealTime }
    function FpsFrameTime: Double;

    { How many frames per second were rendered. This is a real number
      of EventDraw (OnDraw) calls per second. This means that it's actual
      speed of your program. Anything can slow this down, not only long
      EventDraw (OnDraw), but also slow processing of other events (like OnIdle).
      Also, when AutoRedisplay = @false, this may be very low, since you
      just don't need to render frames continously.

      @seealso FpsFrameTime }
    function FpsRealTime: Double;

    { Set Caption to WindowTitle with description of FpsFrameTime and FpsRealTime. }
    procedure FpsToCaption(const WindowTitle: string);

    { Reset the FPS measuring.
      Alternative to doing @code(FpsActive := false; FpsActive := true). }
    procedure FpsReset;

    { FPS measurements reset after this number of seconds.
      This way FpsRealTime / FpsFrameTime always show the average FPS numbers
      during the last FpsSecondsToAutoReset seconds (well, actually it's
      more complicated, see FpsHoldsAfterReset).

      This way FpsRealTime / FpsFrameTime don't change too rapidly
      (so they are good indicator of current FPS speed, as opposed to
      e.g. DrawSpeed which changes every frame so it very unstable).
      They also change rapidly enough --- you don't want to see measuments
      from too long time ago.

      Change FpsSecondsToAutoReset when not FpsActive = @false.  }
    property FpsSecondsToAutoReset: Cardinal
        read FFpsSecondsToAutoReset
       write FFpsSecondsToAutoReset default 6;

    { How to keep previous FPS measurements, when they reset by
      FpsSecondsToAutoReset?

      When measurements are reset by FpsSecondsToAutoReset, you actually don't
      want to totally forget previous measurements (as this would make
      your FpsRealTime / FpsFrameTime unstable for a short time).
      Instead, you want to assume that current FpsRealTime / FpsFrameTime
      was measured during last FpsHoldsAfterReset miliseconds.

      This way FpsRealTime / FpsFrameTime stay more stable.

      So actually the measurements are reset at each
      FpsSecondsToAutoReset * 1000 - FpsHoldsAfterReset miliseconds. }
    property FpsHoldsAfterReset: TMilisecTime
        read FFpsHoldsAfterReset
       write FFpsHoldsAfterReset default 1000;

    { @abstract(How much time it took to render last frame?)

      This returns the time of last EventDraw (that by default just calls
      OnDraw callback).
      The time is in seconds, 1.0 = 1 second. In other words, if FpsFrameTime
      would be measured only based on the last frame time and
      FpsFrameTime = 1.0 then DrawSpeed is 1.0. (In reality,
      FpsFrameTime is measured a little better, to average the time
      of a couple of last frames).

      So for two times faster computer DrawSpeed is = 0.5,
      for two times slower DrawSpeed = 2.0. This is useful for doing
      time-based rendering, when you want to scale some changes
      by computer speed, to get perceived animation speed the same on every
      computer, regardless of computer's speed. Although remember this measures
      only EventDraw (OnDraw) speed, so if you do anything else
      taking some time (e.g. you perform some calculations during OnIdle)
      you're probably much safer to use IdleSpeed.

      Note that this if you have "unstable" rendering times (for example,
      some OnDraw calls will do something costly like implicitly
      preparing VRML models on first Render) then DrawSpeed value will
      also raise suddenly on such frames. That's why you should do
      any potentially lengthy operations, like preparing VRML scene,
      in OnBeforeDraw, that is not taken into account when calculating
      DrawSpeed. }
    property DrawSpeed: Single read FDrawSpeed;

    { @abstract(How much time passed since last EventIdle (OnIdle) call?)

      The time is in seconds, 1.0 = 1 second.
      For two times faster computer IdleSpeed = 0.5,
      for two times slower IdleSpeed = 2.0. This is useful for doing
      time-based rendering, when you want to scale some changes
      by computer speed, to get perceived animation speed the same on every
      computer, regardless of computer's speed.

      This is like DrawSpeed, but calculated as a time between
      start of previous Idle event and start of current Idle event.
      So this really measures your whole loop time (unlike DrawSpeed
      that measures only EventDraw (OnDraw) speed).

      You can sanely use this only within EventIdle (OnIdle). }
    property IdleSpeed: Single read FIdleSpeed;

    { Forces IdleSpeed within the next EventIdle (onIdle) call to be
      equal to 0.0.

      This is useful if you just came back from some lenghty
      state, like a GUI dialog box (like TGLWindow.FileDialog or modal boxes
      in GLWinMessages --- but actually all our stuff already calls this
      as needed, TGLMode takes care of this). IdleSpeed would be ridicoulously
      long in such case (if our loop is totally stopped) or not relevant
      (if we do our loop, but with totally different callbacks, like
      GLWinMessages). Instead, it's most sensible in such case to fake
      that IdleSpeed is 0.0, so things such as AnimationTime and WorldTime
      should not advance wildly just because we did GUI box.

      This forces the IdleSpeed to zero only once, that is only on the
      next EventIdle (OnIdle). Following EventIdle (OnIdle) will have
      IdleSpeed as usual (unless you call IgnoreNextIdleSpeed again, of course). }
    procedure IgnoreNextIdleSpeed;

    { InitLoop stuff --------------------------------------------------------- }

    { Shortcut for Init (create and show the window with GL contex)
      and Glwm.Loop (run the event loop). }
    procedure InitLoop; overload;

    { Shortcut for setting Caption, OnDraw,
      then calling Init (create and show the window with GL contex)
      and Glwm.Loop (run the event loop). }
    procedure InitLoop(const ACaption: string; AOnDraw: TDrawFunc); overload;

    { Parsing parameters ------------------------------------------------------- }

    { Parse some parameters from Parameters[1]..Parameters[Parameters.High].
      Delete processed parameters from @link(Parameters).
      Arguments to this proc tell which options are allowed:

        poGeometry :
          allowed options are
          --fullscreen (ustawia Fullscreen := true)
          --geometry followed by param WIDTHxHEIGHTsXOFFsYOFF
            gdzie WIDTH, HEIGHT sa liczbami calkowitymi, XOFF, YOFF sa liczbami
            calkowitymi z opcjonalnym znakiem.
            (ustawia Fullscreen := false i Width, Height, Left, Top odpowednio
             - patrz 'man X' po opis co mozna wyrazic parametrem -geometry)

        poScreenGeometry
          --fullscreen-custom WIDTHxHEIGHT (ustawia Fullscreen = true,
             VideoResize := true, VideResizeWidth/Height inicjuje i robi VideoChange)

        poDisplay
          --display (set Glwm.XDisplayName)

      Multiple options of the same kind are allowed, for example two options
      --fullscreen --geometry 100x100+0+0 are allowed. Each of them will
      have appropriate effect - in the above example, --fullscreen param
      will be useless (it will be "overriden" by --geometry param that
      comes later). This is to allow flexible calling my programs from
      shell scripts etc.

      Jezeli parametry sa zle (np. poGeometry in AllowedOptions i zly format
      parametru za --geometry lub brak parametru za --geometry) ->
      -> wyjatek EInvalidParams.

      Wersja 2-argumentowa zwraca jakie grupy parametrow zostaly odczytane
      i zinterpretowane. Np. jezeli poGeometry in SpecifiedOptions to
      wiesz ze user podal window size i position i nie powinnismy juz
      sami tego ustawiac. Chociaz zazwyczaj wystarczy po prostu ustawic
      w programie Width/Height/Left/Top i potem wywolac ParseParameters i wtedy
      juz nie trzeba przejmowac sie czy poGeometry bylo czy nie bylo
      w SpecifiedOptions. }
    procedure ParseParameters({ AllowedOptions = StandardParseOptions }); overload;
    procedure ParseParameters(const AllowedOptions: TGLWindowParseOptions); overload;
    procedure ParseParameters(const AllowedOptions: TGLWindowParseOptions;
      out SpecifiedOptions: TGLWindowParseOptions); overload;

    { Returns help text for options in AllowedOptions.
      The idea is that if you call @code(ParseParameters(AllowedOptions))
      in your program then you should also show your users somwhere
      (e.g. in response to "--help" option) the list of allowed
      options obtained by @code(ParseParametersHelp(AllowedOptions))
      (i.e. with the same value of AllowedOptions).

      Returned string may be multiline, but it does not contain
      the trailing newline (newline char after the last line).

      Returned help text conforms my rules in file
      base/README.kambi_command_line_params

      If AddHeader then it adds text
        'Window options:' +nl
      at the beginning. This is just a small thing that allows you
      to comfortably use the output of this function as a whole
      paragraph (separated from the rest of your "--help" text
      by e.g. empty lines around). }
    class function ParseParametersHelp(
      const AllowedOptions: TGLWindowParseOptions;
      AddHeader: boolean): string;

    { dialog boxes using GUI ------------------------------------------------ }

    {$ifndef GLWINDOW_GLUT}

    { About all dialogs:
      - Behaviour of callbacks:
        callbacks of Glwm and callbacks of other TGLWindow MAY be called while
        the dialog is open. Callbacks of THIS object (EventXxx, OnXxx) will not be
        called. You should treat XxxDialog like
          TGLMode.Create(Self, ...)
          SetStdNoCloseGLWindowState
          ....
          TGLMode.Free
      - How does these dialogs look like ?
        Under GTK and WinAPI implementations we use native dialogs of these.
        Under Xlib implementation we simply fallback on
        GLWinMessages.MessageInputQuery. Under glut this is not implemented.
    }

    { Title is some dialog title.
      FileName specifies default filename (path and/or name, or '' if current dir
      is the default dir and there is no default filename). Note that if you
      have to specify only path in FileName you have to end this paths with
      PathDelim (otherwise '/tmp/blah' would not be clear: whether it's
      filename 'blah' in '/tmp/' dir or whether it's only dir '/tmp/blah/' ?).

      Returns true and sets FileName accordingly if user chooses some filename and
      accepts it. Returns false if user cancels.

      if OpenDialog: may try to force user to only enter existing (and readable)
      FileName. (It may be unable to force this from user, or it may fail,
      so you should watch for some exceptions when opening a file
      (as it always the case with opening files, anyway)).
      The intention is that you should be able to open FileName for reading
      (or reading and writing; anyway, file contents should exist).

      if not OpenDialog: allows user to select a non-existent filename.
      Still, it may try to force ExtractFilePath(FileName) to be valid,
      i.e. user may be forced to choose only filenames with existing paths.
      (of course, here it may fail TOO. So you should not assume for sure
      that ExtractFilePath(FileName) is valid).
      Some warning to user may be shown if FileName already exists, like
      "are you sure you want to overwrite this file ?".
      The intention is that you should be able to open FileName for writing.
      This is the "Save File" dialog.

      Those dialog boxes may allow user for some additional actions,
      e.g. to create some directories, rename some files etc.

      FileFilters is a set of file filters to present to user.
      Pass @nil (default) if you do not want to use file file filters,
      so user will just always see everything. An overloaded version
      allows you to pass file filters encoded in a single string,
      this may be slightly more comfortable for call, see
      TFileFiltersList.AddFiltersFromString
      for explanation how to encode filters in a string. }
    function FileDialog(const Title: string; var FileName: string;
      OpenDialog: boolean; FileFilters: TFileFiltersList = nil): boolean; overload;
    function FileDialog(const Title: string; var FileName: string;
      OpenDialog: boolean; const FileFilters: string): boolean; overload;

    { Shows a dialog window allowing user to choose an RGB color.
      Initial value of Color specifies initial RGB values proposed to the user.
      If user accepts, returns true and sets Color accordingly, else
      returns false (and does not modify Color). }
    function ColorDialog(var Color: TVector3Single): boolean;

    {$endif not GLWINDOW_GLUT}
  end;

  { This is a special exception that is always catched and silenced
    inside every TGLWindow.EventXxx. See comments before
    TGLWindow.EventXxx methods. }
  BreakGLWinEvent = class(TCodeBreaker);

  { This class extends @inherited with some functionality that
    is often useful in some simple demo programs in OpenGL.
    I.e. features implemented here are nice and easy to use,
    but I think that if you're going to do some large program you may
    be better off implementing these things in some other place,
    or not using them at all.
    E.g. using this class, Escape key automatically causes closing
    the window. This is nice if your program is a simple OpenGL toy,
    but this may not be so useful if you're doing a really big game
    and you don't want to allow user to close the window by simply
    pressing one key.

    @orderedList(
      @item(
        Przechwytuje wcisniecia SwapFullScreen_Key
        i wtedy przestawia okno z trybu windowed na fullscreen i z powrotem.
        (robi to wykonujac Close, zmieniajac FFullscreen a potem Init ! wiec pamietaj
        aby napisac dobrze OnInit / OnClose).
        (Zainicjuj wlasciwosc FullScreen i left/top/width/height jesli chcesz,
        FullScreen bedzie okreslal poczatkowy stan a jesli fullScreen = false
        to left/top/width/height beda okreslac rozmiar na jaki okno bedzie
        kazdorazowo ustawiane przy wychodzeniu z FullScreen.)
        (robi to tylko jesli SwapFullScreen_Key <> K_None))

      @item(
        Automatycznie wychodzi (robi Close) gdy user wcisnie Escape
        (o ile close_key <> #0))

      @item(
        Automatycznie wlacza tez FpsActive i co jakies kilkaset milisekund
        uaktualnia tytul okienka poprzez FpsToCaption. (Juz poprawione -
        to jest robione w EventIdle, dziala niezaleznie od OnTimer okienka, od
        Glwm.OnTimer i Glwm.TimerMilisec.)
        (wykonuje to tylko jesli ustawisz FpsShowOnCaption = true).)
    )

    Innymi slowy, robi to co dla wiekszosci demek OpenGLa jest przyjemna
    funkcjonalnoscia. I wystarczy ze bedziesz wykonywal normalne loop
    czy processMessage a wszystko to bedzie aktywne.

    Acha, jeszcze jedno : poniewaz niewykluczone ze ta klasa bedzie
    rozwijana o jeszcze jakies inne sensowne (zazwyczaj) funkcjonalnosci,
    dostepna jest procedura SetDemoOptions ktora zawsze bedzie
    pobierala parametry kontrolujace wszystkie opcje (i w ten sposob
    jesli kiedys dorobie jakas funkcjonalnosc i opcje to stara postac
    nie bedzie sie kompilowala i bedziesz musial zdecydowac czy nowa
    funkcjonalnosc pasuje do danego programu czy nie). Domyslne
    ustawienia zawsze beda akceptowac nowa funkcjonalnosc
    automatycznie, wiec uzywanie SetDemoOptions to jest dobry pomysl !. }
  TGLWindowDemo = class(TGLWindow)
  private
    wLeft, wTop, wWidth, wHeight: integer;
    fSwappingFullscr: boolean;
    lastFPSOutputTick: DWORD;
    FFPSBaseCaption: string;
    FFpsShowOnCaption: boolean;
    FSwapFullScreen_Key: TKey;
    FClose_CharKey: char;
    procedure SetFPSBaseCaption(const Value: string);
  public
    { Whether to show current FPS (frames per second) on window's Caption.
      You can modify this property only @italic(before calling @link(Init).) }
    property FpsShowOnCaption: boolean
      read FFpsShowOnCaption write FFpsShowOnCaption default true;

    { Key to use to switch between FullScreen and not FullScreen.
      Set to K_None to disable this functionality.
      You can freely modify it at any time, even after calling @link(Init). }
    property SwapFullScreen_Key: TKey
      read FSwapFullScreen_Key write FSwapFullScreen_Key default K_F11;

    { Key to use to close the window.
      Set to #0 to disable this functionality.
      You can freely modify it at any time, even after calling @link(Init). }
    property Close_CharKey: char
      read FClose_CharKey write FClose_CharKey default CharEscape;

    { When FpsShowOnCaption, you should not use Caption.
      Instead use FPSBaseCaption.
      It will be inited from Caption at EventInit.
      I know, it's a problem. Well, if in doubt, just turn off FpsShowOnCaption. }
    property FPSBaseCaption: string read FFPSBaseCaption write SetFPSBaseCaption;

    { w czasie OnInit / OnClose mozesz sprawdzic wartosc tej wlasciwosci.
      Jesli true to znaczy ze ten OnInit / OnClose sa wykonywane w czasie
      zmiany okna z fullscreen na windowed albo w druga strone. }
    property SwappingFullscr: boolean read fSwappingFullscr;

    procedure SwapFullScreen;

    procedure EventInit; override;
    procedure EventKeyDown(Key: TKey; c: char); override;
    procedure EventIdle; override;
    function AllowsProcessMessageSuspend: boolean; override;

    procedure SetDemoOptions(ASwapFullScreen_Key: TKey;
      AClose_CharKey: char;
      AFpsShowOnCaption: boolean);

    constructor Create;
  end;

  { This class has a @link(Navigator) property (TNavigator instance)
    and handles some usual things related to using @link(TNavigator)
    instance with TGLWindow window.

    @orderedList(
      @item(
        Po pierwsze, pole Navigator jest swobodne do odczytu i zapisu.
        Mozesz w dowolnym momencie wymieniac uzywany tutaj Navigator.
        Domyslnie Navigator = nil.
        W Destroy klasy jezeli OwnsNavigator (domyslnie true) robimy
        Navigator.Free.)
      @item(
        W metodach Event Idle/KeyPress, w AllowsProcessMessageSuspend
        zajmujemy sie wywolywaniem odpowiednich metod z Navigator, o ile
        tylko Navigator <> nil i UseNavigator = true.
        Oh, and we use IdleSpeed for navigator.)
      @item(
        Metoda PostRedisplayOnMatrixChanged nie jest tu nigdzie uzywana ale mozesz
        ja podac jako TMatrixChangedFunc przy tworzeniu Navigatora. Wywoluje
        ona po prostu PostRediplay. (Jezeli chcesz robic cos innego w reakcji
        na MatrixChanged to naturalnie nie musisz uzywac
        PostRedisplayOnMatrixChanged.))
      @item(
        This will also helps you use MouseLook feature of TWalkNavigator:
        This will call MouseMove of Navigator with a suitable parameters,
        and this gives you UpdateMouseLook method that you should use.
        All that remains to you is to call UpdateMouseLook at appropriate times,
        and mouse look will work.)
    )

    Typical use of this class:
    @orderedList(
      @item(na poczatku programu
@longCode(#
  glw.Navigator := TMatrix<...>.Create(glw.PostRedisplayOnMatrixChanged);
  glw.Navigator.Init(...);
#))
      @item(w OnDraw uzyj gdzies glMultMatrix/glLoadMatrix(glw.Navigator.Matrix))
    )
    And that's all. }
  TGLWindowNavigated = class(TGLWindowDemo)
  private
    FOwnsNavigator: boolean;
    FUseNavigator: boolean;
    FNavigator: TNavigator;
    FCursorNonMouseLook: TGLWindowCursor;
    procedure SetCursorNonMouseLook(const Value: TGLWindowCursor);
    function ReallyUseNavigator: boolean;
    function ReallyUseMouseLook: boolean;
  public
    constructor Create;
    destructor Destroy; override;

    { Navigator instance used. Initially it's nil. }
    property Navigator: TNavigator
      read FNavigator write FNavigator;

    property OwnsNavigator: boolean
      read FOwnsNavigator write FOwnsNavigator default true;

    { jezeli not UseNavigator albo Navigator = nil to to okienko bedzie sie
      zachowywalo jakby wcale nie bylo TGLWindowNavigated. Wszystkie metody Event*
      beda wywolywaly po prostu inherited; i nic wiecej nie beda robic }
    property UseNavigator: boolean
      read FUseNavigator write FUseNavigator default true;

    { These are shortcuts for writing
      TExamineNavigator(Navigator) and TWalkNavigator(Navigator).
      In DEBUG version they use operator "as" but in RELEASE
      version they use direct type-casts for speed.

      @groupBegin }
    function ExamineNav: TExamineNavigator;
    function WalkNav: TWalkNavigator;
    { @groupEnd }

    procedure PostRedisplayOnMatrixChanged(ChangedNavigator: TNavigator);

    procedure EventInit; override;
    procedure EventKeyDown(Key: TKey; C: char); override;
    procedure EventIdle; override;
    procedure EventMouseDown(Button: TMouseButton); override;
    procedure EventMouseMove(NewX, NewY: Integer); override;
    function AllowsProcessMessageSuspend: boolean; override;

    { Calculate a ray picked by WindowX, WindowY position on the window.
      Use this only when Navigator <> nil and Navigator is TWalkNavigator.

      ViewAngleDegX, ViewAngleDegY are your camera view angles.

      WindowX, WindowY are given in the same style as MouseX, MouseY:
      WindowX = 0 is left, WindowY = 0 is top.

      This uses @link(PrimaryRay) call. }
    procedure Ray(const WindowX, WindowY: Integer;
      const ViewAngleDegX, ViewAngleDegY: Single;
      out Ray0, RayVector: TVector3Single);

    { Calculate a ray corresponding to current Navigator
      (must be TWalkNavigator instance) settings and MouseX, MouseY
      position on the screen.

      This is actually just a shortcut for @link(Ray),
      passing MouseX, MouseY as WindowX, WindowY. }
    procedure MousePickedRay(
      const ViewAngleDegX, ViewAngleDegY: Single;
      out Ray0, RayVector: TVector3Single);

    { Calculate a ray picked by WindowX, WindowY position on the window,
      assuming current camera is recorded in Nav.

      ViewAngleDegX, ViewAngleDegY are your camera view angles.

      WindowX, WindowY are given in the same style as MouseX, MouseY:
      WindowX = 0 is left, WindowY = 0 is top.

      This uses @link(PrimaryRay) call. }
    procedure RayFromCustomNavigator(
      Nav: TWalkNavigator;
      const WindowX, WindowY: Integer;
      const ViewAngleDegX, ViewAngleDegY: Single;
      out Ray0, RayVector: TVector3Single);

    { Calculate a ray picked on current mouse position on the window,
      assuming current camera is recorded in Nav.

      ViewAngleDegX, ViewAngleDegY are your camera view angles.

      This uses @link(PrimaryRay) call. }
    procedure MousePickedRayFromCustomNavigator(
      Nav: TWalkNavigator;
      const ViewAngleDegX, ViewAngleDegY: Single;
      out Ray0, RayVector: TVector3Single);

    { If you use Navigator of class TWalkNavigator with this window
      and you want to use it's MouseLook feature then
      you should call this after you changed Navigator.MouseLook value.

      This sets @link(Cursor) (to gcNone or CursorNonMouseLook, based on
      whether mouse look is used now, that is Navigator.MouseLook is @true)
      and, if mouse look is used, repositions mouse cursor at the middle
      of the window.

      You should also call this after you changed Navigator's instance,
      or UseNavigator, as these things also effectively change the
      actual state of "using mouse look". OTOH sometimes you don't
      have to call this --- e.g. if you push/pop mode states using
      TGLMode and in the mode you set temporary UseNavigator = @false,
      then you don't have to call this, because TGLMode will push/pop
      @link(Cursor) state anyway. That's why I explicitly wrote above
      what this function does (sets @link(Cursor) and repositions
      the mouse) --- so that you can figure out where exactly
      you have to use it. }
    procedure UpdateMouseLook;

    { Cursor when not using mouse look.
      Useful if you sometimes use mouse look and you want your cursor
      hidden while mouse look,
      but controlled by this property otherwise.

      When mouse look is not in use, this will be equal to actual
      TGLWindow.Cursor, thus changing cursor.
      When mouse look is in use, TGLWindow.Cursor
      will remain hidden. }
    property CursorNonMouseLook: TGLWindowCursor
      read FCursorNonMouseLook write SetCursorNonMouseLook
      default gcDefault;
  end;

  TObjectsListItem_1 = TGLWindow;
  {$I objectslist_1.inc}
  TGLWindowsList = class(TObjectsList_1)
    { Simply calls PostRedisplay on all items. }
    procedure PostRedisplay;
  end;

  { The only instance of this class should be Glwm.
    Don't create any other objects of class TGLWindowsManager, there's no
    point in doing that.
    This object traces information about all visible instances of TGLWindow
    and implements message loop. It also handles some global tasks
    like managing the screen (changing current screen resolution and/or
    bit depth etc.) }
  TGLWindowsManager = class

  { Include GLWindow-implementation-specific parts of
    TGLWindowsManager class. Rules and comments that apply here are
    the same as in analogous place at TGLWindow class,
    when read_tglwindow_interface is defined. }

  {$define read_tglwindowmanager_interface}
  {$I glwindow_implementation_specific.inc}
  {$undef read_tglwindowmanager_interface}

  private
    { AutoRedisplayAddToList is 0 and
      AutoRedisplayList is nil
      initially and these properties are never changed in generic glwindow
      implementation (i.e. in this file, glwindow.pas).
      They are used by TGLWindow.DoDraw. See there for comments why
      some GLWindow backends may need to modify these properties. }
    AutoRedisplayAddToList: Cardinal;
    AutoRedisplayList: TGLWindowsList;
  private
    FOnIdle :TIdleFunc;
    FOnTimer :TProcedure;
    FTimerMilisec :Cardinal;
    FVideoColorBits: integer;
    FVideoFrequency: Cardinal;

    FActive: TGLWindowsList;
    function GetActive(Index: integer): TGLWindow;

    { ActiveAdd: add new item to Active[].
      glwin MUST NOT be already on Active[] list. }
    procedure ActiveAdd(glwin: TGLWindow);

    { ActiveRemove: delete glwin from Active[].

      glwin don't have to be on the Active[] list. If it is not, this
      method is NOOP. This is useful when this is called from TGLWindow.Close
      because TGLWindow.Close should work even for partially constructed
      Windows.

      If glwin was present on Active[] and after removing glwin
      ActiveCount = 0 and QuitWhenLastWindowClosed then it calls Quit. }
    procedure ActiveRemove(glwin: TGLWindow; QuitWhenLastWindowClosed: boolean);

    { FindWindow : szuka na liscie Active[] glwin. Zwraca indeks
      jesli znajdzie, -1 jesli nie. }
    function FindWindow(glwin: TGLWindow): integer;

    procedure CreateImplDependent;
    procedure DestroyImplDependent;

    { This is GLWindow-implementation specific part of Quit method implementation.
      In non-implementation-specific part of Quit we already closed all windows,
      so this will be called only when ActiveCount = 0.
      So the only things you have to do here is:
      - make ProcessMessage to return false
      - terminate Loop method, if it works (if Loop is implemented using
        "while ProcessMessage do ;" then the first condition is all that is
        really needed)

        Note: it is NOT guaranteed that we are inside Loop method
        when calling this function, i.e. it may be the case that noone ever
        called Glwm.Loop (e.g. in @code(kambi_lines) game, where everything is done
        using while ProcessMessages do ...), but still it must be valid to call
        Quit and QuitWhenNoWindowsActive in such situation.
        Also it must be valid to call Quit and QuitWhenNoWindowsActive more
        then once. }
    procedure QuitWhenNoWindowsActive;

    { This simply checks Assigned(FOnIdle) and only then calls FOnIdle.
      ALWAYS use this method instead of directly calling FOnIdle. }
    procedure DoSelfIdle;

    { Same as DoSelfIdle, but here with FOnTimer. }
    procedure DoSelfTimer;

    { DoActiveWindowsIdle / Timer wywoluja wszystkie OnIdle / OnTimer dla okien w
      Active[]. Implementacje moga zrealizowac OnIdle / OnTimer okien
      inaczej, niekoniecznie w tak prosty sposob, wiec nie musza korzystac
      z tych procedur. Ale moga. }
    procedure DoActiveWindowsIdle;
    procedure DoActiveWindowsTimer;

    { Something useful for some GLWindow implementations. This will implement
      (in a simple way) calling of DoSelfInit and DoActiveWindowsTimer.

      Declare in TGLWindowsManager some variable like
        LastDoTimerTime: TMilisecTime
      initialized to 0. Then just call very often (probably at the same time
      you're calling DoSelfIdle)
        MaybeDoTimer(LastDoTimerTime);
      This will take care of calling DoSelfTimer and DoActiveWindowsTimer
      at the appropriate times. It will use and update LastDoTimerTime,
      you shouldn't read or write LastDoTimerTime yourself. }
    procedure MaybeDoTimer(var ALastDoTimerTime: TMilisecTime);
  public
    { jesli VideoResize to zmieni rozmiar ekranu na VideoResizeWidth /
      VideoResizeHeight wywolaniem VideoChange; wpp. ustawi defaultowy
      rozmiar ekranu (desktopu itp.). }
    VideoResize : boolean;
    VideoResizeWidth,
    VideoResizeheight : integer;

    { Color bits per pixel ktore ma uzyc przy robieniu VideoChange i przy
      robieniu TGLWindow.Init. = 0 oznaczaja ze ma uzyc system default }
    property VideoColorBits: integer read FVideoColorBits write FVideoColorBits default 0;

    { VideoFrequency to set in TryVideoChange and VideoChange.
      Leave as 0 to use system default. }
    property VideoFrequency: Cardinal read FVideoFrequency write FVideoFrequency default 0;

    { Describe the changes recorded in variables VideoXxx, used by VideoChange and
      TryVideoChange. This is a multiline string, each line is indented by 2 spaces,
      always ends with KambiUtils.NL. }
    function VideoSettingsDescribe: string;

    { zmien ekran, zgodnie z VideoColorBits i VideoResizeWidth/Height
      i VideoFrequency.
      Zwraca czy sie udalo.
      Zwracam uwage ze pod niektorymi implementacjami GLWINDOW ta funkcja
      bedzie po prostu zawsze zwracala false. }
    function TryVideoChange: boolean;

    { zrob TryVideoChange, jesli sie nie udalo :
      if OnErrorWarnUserAndContinue to wyswietli warning dla usera i bedzie
        kontynuowal,
      else rzuci Exception. }
    procedure VideoChange(OnErrorWarnUserAndContinue: boolean);

    { VideoReset przywraca domyslne ustawienia ekranu (tzn. nie robi
      nic jesli nigdy nie wywolales TryVideoChange z rezultatem true,
      wpp przywraca domyslne ustawienia). Jest wywolywane automatycznie w
      Glwm.Destroy a wiec w finalization tego unitu (a wiec nie troszcz
      sie o finalizacje wywolania TryVideoChange). }
    procedure VideoReset;

    function ScreenHeight: integer;
    function ScreenWidth: integer;

    { Active[0..ActiveCount-1] : lista aktywnych okien programu, tzn.
      tych dla ktorych wywolano Init a nie wywolano jeszcze Close. }
    function ActiveCount: integer;
    property Active[Index: integer]: TGLWindow read GetActive;

    { OnIdle bedzie wywolywane gdy window system nie przesle nam zadnych
      message'ow i w zwiazku z tym bedziemy wolni. Naczelnym celem
      OnIdle jest aby w aplikacji zmuszonej do czestego odmalowywania sie
      na ekranie OnIdle bylo wykonywane mniej wiecej tak czesto co OnDraw
      (tzn. nie 1 do 1, ale proporcjonalnie tak czesto). W zwiazku z tym
      jezeli nie mamy do siebie zadnych message'ow ale musimy sie
      odmalowac to wtedy OnIdle ZOSTANIE wywolane (nie wiem czy tak
      jest pod glutem; chyba pod glutem OnIdle jest wywolane tylko
      gdy nie musielismy sie odmalowac czyli potencjalnie OnIdle
      moze wtedy zachodzic za rzadko).

      Wiec jesli w kolko mamy posylane do siebie zdarzenia OnDrawGL -
      to pomiedzy nimi zawsze zmieszcza sie z pewna czestotliwoscia
      zdarzenia OnIdleGL. Jednoczesnie, nie odmalowujemy sie w kazdym
      obrocie petli - odmalowujemy sie tylko gdy nie mamy do siebie
      zadnych zdarzen (to tak jak glut; jest faktem ze jezeli
      aplikacja nie nadaza z przetwarzaniem nadchodzacych message'y
      to nalezy cala sile skupic na ich przetwarzaniu a nie
      utrudniac sobie prace zmuszajac sie do przemalowywania okienka
      mimo ze mamy jakies message'y do obsluzenia).

      W szczegolnosci, to jest odpowiednie miejsce aby robic
      badanie KeysDown[] klawiszy (chyba ze nasluch na OnKeyDown wystarcza),
      robic animacje zmieniajac jakies zmienne i wywolywac PostRedisplay.

      Mozesz tez zmieniac wartosc tej  zmiennej w czasie dzialania programu
      (tzn.pomiedzy Init a Close jakiegos okienka). }
    property OnIdle: TIdleFunc read FOnIdle write FOnIdle; { = nil }
    { OnTimer : podobnie jak glutTimerFunc. To zdarzenie jest uruchamiane
      co TimerMilisec milesekund lub wiecej (tzn. nie ma gwarancji ze zdarzenie
      OnTimer rzeczywiscie zajdzie zaraz po tym czasie; moze sie okazac
      ze czas jaki uplynal pomiedzy kolejnymi OnTimer jest duzo wiekszy -
      - w szczegolnosci, OnTimer realizowany jest w ProcessMessage wiec
      musisz zadbac aby ProcessMessage bylo wykonywane dosc czesto w czasie
      i aby pozostale callbacki nie zajmowaly zbyt duzo czasu.
      Jesli ustawisz za male TimerMilisec to OnTimer zacznie dzialac jak OnIdle !
      Mozesz tez zmieniac wartosc OnTimer i TimerMilisec w czasie dzialania engine'u
      (tzn.pomiedzy Init a Close jakiegos okienka). }
    property OnTimer: TProcedure read FOnTimer write FOnTimer; { = nil }
    property TimerMilisec: Cardinal read FTimerMilisec write FTimerMilisec; { = 1000 }

    { Przetwarzaj pewna ilosc messagy WindowSystemu (moze zero, moze kilka ?)
      po drodze wywolujac OnDraw / Idle / Resize itd. w miare potrzeby
      dispatchujac odpowiednie messagy (a wiec i zdarzenia) do odpowiednich
      obiektow TGLWindow.

      Zwraca false jesli wywolano Quit (bezposrednio lub wywolujac
      Close na ostatnim okienku (Close tez mozna wywolac bezposrednio
      lub user moze kliknac na jakis przycisk "Zamknij"))
      Aplikacja chcaca cos robi� w oczekiwaniu na zajscie warunku BB
      powinna robia tak :

      while not BB do Glwm.ProcessMessages;

      W GLWindow, inaczej niz w jakims wiekszym systemie jak np. VCL czy WinAPI,
      programista ma prosta i pelna kontrole nad programem, wi�c mo�na bez problemu
      napisa� program tak, �eby bylo jasne i� w danym stanie programu uzytkownik
      nie mo�e spowodowa� wywolania procedury QuitGL. Przed taka p�tla nale�y
      wi�c wprowadzi� program w taki stan �e pr�dzej czy p�zniej MUSI zajs�
      BB, a potem go z tego stanu wyprowadzi�.

      Gdyby jednak mo�liwos� zako�cenia programu w takiej p�tli byla dopuszczona,
      nale�aloby napisa� p�tl� postaci

      while not BB do
       if not Glwm.ProcessMessage then break;

      Co mozna zakladac lub nie o dzialaniu petli ProcessGLWinMessages ?
       - jezeli windManager zasypuje nam message'ami moze sie okazac
         ze od czasu wywolania PostRedisplay do czasu wywolania
         OnDraw minelo duzo wywolan ProcessMessage. To dlatego ze
         ProcessMessage nie wywoluje zadnego OnDraw jesli ma message
         do przetworzenia. Nie wywoluje tez OnIdle jesli ma message
         do przetworzenia. Natomiast jezeli nie ma message jest
         gwarantowane ze OnDraw i OnIdle beda wywolywane mniej
         wiecej proporcjonalnie tyle samo razy (no chyba ze,
         oczywiscie, PostRedisplay nie bedzie wywolywany co petle).
         Patrz komentarz przy OnIdle.
       - ProcessMessage moze zdecydowac, o ile AllowSuspend i OnIdleGL = nil
         i jeszcze kilka innych warunkow, ze jezeli events queue z WindowSystemu
         jest pusta to zaczekamy az WindowSystem przysle nam jakis event -
         ale nie przez krecenie sie w kolko robiac "puste" wykonania ProcessMessage
         (czyli powodujac zle busy-waiting) tylko przekazujac informacje do
         systemu ze "nasz proces czeka na event". Np. pod Xlib robimy
         XNextEvent, pod Windows GetMessage. W rezultacie piszac petle
         while ProcessMessage(true) do foo(); NIE MOZESZ zakladac
         ze foo() jest wywolywane co chwila. Jezeli OnIdleGL = nil to
         pomiedzy kolejnymi wywolaniami foo() moze uplynac wiele czasu
         bezczynosci naszego programu.
       - robiac normalna petle programu w rodzaju
         "while ProcessMessage(true) do ;" jak w TGLWindowManager.Loop
         bedziesz podawal AllowSuspend = true, bo skoro jedynym sensem
         petli jest wykonywanie ProcessMessage to nie przeszkadza nam fakt
         ze ProcessMessage moze zawisnac.

         Robiac petle w rodzaju tej w ProgressGL czy RaytraceToWindow (w czasie
         wykonywania renderowania) bedziesz chcial miec AllowSuspend = false
         bo bedziesz chcial zeby ProcessMessage uaktualnilo okienko i zakonczylo sie
         najszybciej jak to mozliwe abys mogl kontyuowac obliczenia.

         Robiac petle w rodzaju tej w GLWinMessages albo RaytraceToWindow
         (juz PO zakonczeniu renderowania) postaci
         "repeat ProcessMessage(true) until B;" gdzie B to zmienna/funkcja
         boolowska musisz sie zastonowic : czy zmiana wartosci B MUSI byc
         zwiazana z zajsciem jakiegos callbacka (czyli z zajsciem jakiegos
         zdarzenia dla window managera) ? Jesli tak to mozesz spokojnie
         dac AllowSuspend. Jesli nie, np. stan B zmienia sie w czasie bez
         posrednictwa twojego programu (np. B = function IsUserHungry)
         to musisz dac AllowSuspend = false.

         User is always hungry.

         ProcessAllMessages wywoluje w petli ProcessMessage(false, WasAnyMessage)
         i konczy gdy ProcessMessage zwrocilo false lub WasAnyMessage = false.
         ProcessAllMessages robi wiec jakby flush - synchronizuje nas z window
         managerem, upewniajac sie ze przetworzylismy WSZYSTKIE message'y jakie
         mielismy do wykonania. ProcessAllMessages jest uzyteczne gdy robimy
         cos chcac co jakis czas wywolywac ProcessMessage i chcemy byc pewni
         ze przetwarzamy wszystkie message'y od window managera (ze jestesmy
         na biezaco) - bo byc moze np. jezeli user przycisnie Escape to chcemy
         zrezygnowac z robienia dlugo trwajacej rzeczy. W ten sytuacji robienie
         tylko ProcessMessage co jakis czas nie jest wystarczajaco dobrym pomyslem
         bo np. gdy user przesunie myszke my dostaniemy mnostwo message'y mouseMove
         i jezeli potem user przycisnie Escape to my DLUGO DLUGO tego nie zauwazymy
         bo bedziemy przetwarzali zdarzenia mouseMove. W rezultacie bedziemy
         kontynuowali obliczenia mimo ze user wcisnal Escape. Zle ! Chcemy byc
         na biezaco z message'ami jezeli zamierzamy na nie reagowac.
         Wiec wtedy mozna uzyc ProcessAllMessages - wywoluj to co jakis czas
         i wtedy masz pewnosc ze jestes na biezaco z window managerem.
         Przyklad uzycia : RaytraceToWindow w view3dscene.
         Nigdy nie wywoluj ProcessAllMessages w petli (powinienes wtedy uzywac
         ProcessMessage) - uzywaj tego tylko jesli robisz duzo rzeczy pomiedzy
         kolejnymi wywolaniami ProcessAllMessages.

      Note that if you let some exception to be raised out of
      some event (like OnXxx) then this window may be closed
      while recovering from this exception. I.e. GLWindow implementation
      is free to implement part of ProcessMessage like
      @longCode(#
        if HasKeyDown then
        try
          OnKeyDown(...);
        except
          Close;
          raise;
        end;
      #)
      TODO: this behavior is currently done only by Xlib and WinAPI
      implementation, in glwindow_winsystem.inc.
      Is there really any good reason why we can't remove this behavior ?
    }
    {$ifdef GLWINDOW_HAS_PROCESS_MESSAGE}
    function ProcessMessage(AllowSuspend: boolean): boolean;
    function ProcessAllMessages: boolean;
    {$endif}

    { zamknij wszystkie okna TGLWindow, spraw by ProcessMessage zwracalo false i
      w rezultacie spowoduj zakonczenie procedury Loop jesli dziala.

      Note specific to glut-based implementation (GLWINDOW_GLUT):
      with glut this method (after closing all Windows) calls Halt,
      since this is the only way to exit from Glwm.Loop (that has to be
      implemented as glutMainLoop). }
    procedure Quit;

    { Do the event loop.
      Think of it as just a shortcut for "while ProcessMessage do ;".

      Note that this does nothing if ActiveCount is zero, that is there
      are no open windows. Besides the obvious reason (you didn't call
      TGLWindow.Init on any window...) this may also happen if you called
      Close (or Glwm.Quit) from your window OnInit / OnResize callback.
      In such case no event would probably reach
      our program, and user would have no chance to quit, so Loop just refuses
      to work and exits immediately without any error. }
    procedure Loop;

    function ImplementationName: string;

    constructor Create;
    destructor Destroy; override;
  end;

var
  { One global instance of TGLWindowsManager.

    DON'T change value of this variable, don't Free this object !
    This will be handled in initialization / finalization of this module.
    Many things in this unit, also in TGLWindow class implementation,
    depend on having this variable present all the time. }
  Glwm: TGLWindowsManager;

const
  DefaultCallbacksState: TGLWindowCallbacks =
  ( MouseMove: nil; MouseDown: nil; MouseUp: nil;
    KeyDown: nil; KeyUp: nil;
    BeforeDraw: nil; Draw: nil; CloseQuery: nil; Idle: nil; Timer: nil; Resize: nil;
    MenuCommand: nil);

{ A simple procedure that you can register as OnResize callback,
  like glw.OnResize := Resize2D; You can also call this from your OnResize
  callback.
  It calls
    glViewport(0, 0, glwin.Width, glwin.Height);
    ProjectionGLOrtho(0, glwin.Width, 0, glwin.Height);
  That's the simplest thing to do in OnResize in OpenGL 2D programs. }
procedure Resize2D(glwin: TGLWindow);

{$undef read_interface}

{$define read_interface_2}
{$i glwindowmenu.inc}
{$undef read_interface_2}

implementation

uses ParseParametersUnit, KambiLog, GLImages
  { using here GLWinModes/Messages makes recursive uses,
    but it's needed for FileDialog }
  {$ifdef GLWINDOW_GTK_ANY}, GLWinModes, EnumerateFiles {$endif}
  {$ifdef GLWINDOW_WINAPI}, GLWinModes, GLWindowWinAPIMenu {$endif}
  {$ifdef GLWINDOW_XLIB}, GLWinMessages {$endif};

{$define read_implementation}

{$I objectslist_1.inc}
{$I dynarray_2.inc}
{$I glwindowmenu.inc}
{$I glwindow_implementation_specific.inc}

{ TDynGLWindowFuncArray ------------------------------------------------ }

procedure TDynGLWindowFuncArray.ExecuteAll(glwin: TGLwindow);
var i: integer;
begin
 for i := 0 to Length-1 do
  if {$ifndef FPC_OBJFPC} @ {$endif} Items[i] <> nil then
  begin
   {$I glwindow_eventoncallbegin.inc}
   Items[i](glwin);
   {$I glwindow_eventoncallend.inc}
  end;
end;

{ ----------------------------------------------------------------------------
  niezalezne od GLWINDOW_xxx rzeczy TGLWindow }

constructor TGLWindow.Create;
begin
 inherited;
 OnInitList := TDynGLWindowFuncArray.Create;
 OnCloseList := TDynGLWindowFuncArray.Create;
 FClosed := true;
 FWidth  := GLWindowDefaultSize;
 FHeight := GLWindowDefaultSize;
 FLeft  := GLWindowPositionCenter;
 FTop   := GLWindowPositionCenter;
 FDoubleBuffer := true;
 FCaption := ProgramName;
 FFpsSecondsToAutoReset := 6;
 FpsHoldsAfterReset := 1000;
 FResizeAllowed := raAllowed;
 minWidth := 100;  maxWidth := 4000;
 minHeight := 100; maxHeight := 4000;
 DepthBufferBits := DefaultDepthBufferBits;
 FCursor := gcDefault;
 FMultiSampling := 1;
 FWindowVisible := true;

 OwnsMainMenu := true;

 CreateImplDepend;
end;

destructor TGLWindow.Destroy;
begin
 Close; { <- This will be ignored if already Closed }

 if OwnsMainMenu then FreeAndNil(FMainMenu);

 FreeAndNil(OnInitList);
 FreeAndNil(OnCloseList);
 inherited;
end;

procedure TGLWindow.Init;
begin
 if not FClosed then Exit;

 try
  { Adjust Left/Top/Width/Height/FullScreen as needed.
    Note: calculations below try to correct window geometry but they
    can fail to foresee some things. In particular, they do not take
    into account a potential menu bar that may be visible when MainMenu <> nil.
    E.g., when MainMenu <> nil and implementation supports MainMenu as
    menu bar (GTK and WINAPI implementations) and FullScreen then
    the actual OpenGL window size will NOT match ScreenWidth/Height,
    it will be slightly smaller (menu bar takes some space).
  }
  if FFullscreen and
    ((not between(Glwm.ScreenWidth, minWidth, maxWidth)) or
     (not between(Glwm.ScreenHeight, minHeight, maxHeight)) or
     ((ResizeAllowed = raNotAllowed) and
       ((Glwm.ScreenWidth <> Width) or (Glwm.ScreenHeight <> Height)) )
    ) then
   FFullscreen := false;

  if FFullScreen then
  begin
   fleft := 0;
   ftop := 0;
   fwidth := Glwm.ScreenWidth;
   fheight := Glwm.ScreenHeight;
  end else
  begin
   if Width  = GLWindowDefaultSize then FWidth  := Glwm.ScreenWidth  * 4 div 5;
   if Height = GLWindowDefaultSize then FHeight := Glwm.ScreenHeight * 4 div 5;

   Clamp(fwidth, minWidth, maxWidth);
   Clamp(fheight, minHeight, maxHeight);

   if left = GLWindowPositionCenter then fleft := (Glwm.ScreenWidth-width) div 2;
   if top  = GLWindowPositionCenter then ftop := (Glwm.ScreenHeight-height) div 2;
  end;

  { reset some window state variables }
  FillChar(KeysDown, SizeOf(KeysDown), 0);
  FillChar(CharactersDown, SizeOf(CharactersDown), 0);
  FillChar(PressedKeyToCharacter, SizeOf(PressedKeyToCharacter), 0);
  FillChar(PressedCharacterToKey, SizeOf(PressedCharacterToKey), 0);
  fmousePressed := [];
  EventInitCalled := false;

  MainMenuSetParent(Self);

  FClosed := false; { w tym miejscu, przed InitImplDepend i wywolaniem
    OnInit + OnResize, bo te rzeczy moga rzucic wyjatki a w reakcji na wyjatek
    chcemy wywolac Close ktore do dzialania wymaga aby bylo not FClosed. }

  { Najwazniejsze : zrob to co implementacja zrobic musi.
    Mozesz stad smialo wywolywac DoResize, beda ignorowane dzieki temu
    ze EventInitCalled = false.  }
  InitImplDepend;

  { Do MakeCurrent before glViewport and EventInit. }
  MakeCurrent;

  LoadAllExtensions;

  if Log then
    WritelnLogMultiline('OpenGL context initialization', GLCapsString);

  { zsynchronizuj glViewport z naszymi Width/Height (bo one moga sie roznic od
    rzeczywistych rozmiarow okienka) }
  glViewport(0, 0, Width, Height);

  { call first EventInit and EventResize. Zwroc uwage ze te DoResize i DoInit
    MUSZA byc wykonane na samym koncu procedury Init - jak juz wszystko inne
    zostalo wykonane. Wszystko po to ze juz w pierwszym OnInit lub OnResize
    moze zostac wywolane Glwm.ProcessMessages np. w wyniku wywolania w OnInit
    GLWinMessages.MessageOk. }
  EventInitCalled := true;
  EventInit;

  { Check Closed here, in case OnInit closed the window
    (by calling Glwm.Quit (that calls Close on all windows) or direct Close
    on this window). Note that Close calls
    CloseImplDepend and generally has *immediate* effect --- that's why
    doing anything more with window now (like MakeCurrent) would be wrong. }
  if Closed then Exit;

  DoResize(FWidth, FHeight, true);

  { Check Closed here, in case OnResize closed the window. }
  if Closed then Exit;

  { to be SURE that current window's gl context is active,
    even if someone in EventInit changed current gl context }
  MakeCurrent;
 except
  Close; raise;
 end;
end;

procedure TGLWindow.CloseError(const error: string);
begin
 if closeerrors <> '' then
  closeerrors := closeerrors+nl+error else
  closeerrors := error
end;

procedure TGLWindow.Close(QuitWhenLastWindowClosed: boolean);
begin
 if FClosed then Exit;

 try
  if EventInitCalled then
  begin
   MakeCurrent;
   EventClose;
  end;
 finally
  closeerrors := '';
  CloseImplDepend;

  MainMenuSetParent(nil);

  FClosed := true;

  { Note: it is important here that ActiveRemove will not raise any error
    if Self is not on Active[] list. This is useful if the window was partially
    constructed.

    E.g. when StencilBufferBits was too high and InitImplDepend
    method raised an exception EGLContextNotPossible. Then this method, Close,
    is called, but Self is not on Active[] list. And this fact should not be
    reported as an error -- error is EGLContextNotPossible ! }
  Glwm.ActiveRemove(Self, QuitWhenLastWindowClosed);

  { dopiero tutaj rzucamy wyjatek. Zawsze bedziemy probowac wykonac cala
    powyzsza procedure, w szczegolnosci cale CloseImplDepened,
    bez wzgledu na bledy - a ewentualny wyjatek rzucimy dopiero teraz.}
  if closeerrors <> '' then
   raise Exception.Create('Error(errors?) while trying to close GlWindow : '+nl+closeerrors);
 end;
end;

procedure TGLWindow.MainMenuSetParent(AParentWindow: TGLWindow);

  procedure SetMe(Entry: TMenuEntry);
  var i: Integer;
  begin
   Entry.ParentWindow := AParentWindow;
   if Entry is TMenu then
   for i := 0 to TMenu(Entry).EntriesCount-1 do
    SetMe(TMenu(Entry).Entries[i]);
  end;

begin
 if MainMenu <> nil then SetMe(MainMenu);
end;

procedure TGLWindow.MainMenuChanged;
begin
 if Closed then Exit;
 Check(MainMenu <> nil, 'MainMenu must not be nil when you call MainMenuChanged');
 MainMenuSetParent(Self);
 MainMenuChangedImplDepend;
end;

procedure TGLWindow.SetAutoRedisplay(value: boolean);
begin
 fAutoRedisplay := value;
 if value and (not Closed) then PostRedisplay;
end;

procedure TGLWindow.ReleaseAllKeysAndMouse;
var k: TKey;
    mb: TMouseButton;
    {$ifdef GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN}
    mk: TModifierKey;
    b: boolean;
    {$endif}
begin
 {$ifdef GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN}
 { When GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN, I *HAVE* to use below
   SetPrivateModifiersDown. It would be an error to do DoKeyUp(K_Ctrl)
   directly when GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN, instead we have to
   use SetPrivateModifiersDown(mkCtrl, ...).
   This is the only way to make values in PrivateModifiersDown[]
   and KeysDown[] arrays consistent. }
 for mk := Low(mk) to High(mk) do
  for b := Low(b) to High(b) do
   SetPrivateModifiersDown(mk, b, false);
 {$endif GLWINDOW_USE_PRIVATE_MODIFIERS_DOWN}

 { Since we do DoKeyUp, this should also take care of CharactersDown. }

 for k := Low(k) to High(k) do
  if KeysDown[k] then DoKeyUp(k);

 for mb := Low(mb) to High(mb) do if mb in MousePressed then
  DoMouseUp(MouseX, MouseY, mb);
end;

function TGLWindow.ModifiersDown: TModifierKeys;
begin
 result := Keys.ModifiersDown(KeysDown);
end;

{ wszystkie zdarzenia TGLWindow - opakowujace je procedury DoXxx ktore
  robia wszystkie rzeczy niezalezne od implementacji dla danego zdarzenia
  (m.in. wywoluja EventXxx ktore m.in. wywoluje OnXxx jesli jest assigned).
  Implementacje GLWindow powinny wywolywac te funkcje, NIE wywolywac
  bezposrednio EventXxx ani tym bardziej OnXxx !
  ------------------------------------------------------------------------------------ }

procedure TGLWindow.DoResize(AWidth, AHeight: integer; FromIndependentInit: boolean);
begin
 { zabezpiecz sie przed
   1) glutem, ktoremu nie mamy jak powiedziec ze ResizeAllowed <> raNotAllowed
   2) Windowsem, ktory moze zresizowac nasze okno np. gdy sie nie miescimy na ekranie
   3) XWindow-Managerem ktory zawsze moze nas zresizowac, mimo ze prosimy go
      zeby tego nie robil.
   wiec pod wszystkimi trzema implementacjami musimy sprawdzic warunek ze
     albo ResizeAllowed = raAllowed albo naprawde fwidth = w itd.
   Sprawdzamy tez czy w i h sa w odpowiednim zakresie minXxx .. maxXxx.
     Oczywiscie implementacje powinny starac sie zeby nic spoza tego zakresu do nas
     nie dotarlo, ale nigdy nie ma pewnosci. Zwracam uwage, ze wymagamy aby zawsze
     minWidth > 0 i minHeight > 0 wiec jednoczesnie ponizej gwarantujemy sobie ze nie
     zachodzi sytuacja w = 0 lub h = 0.

   Apropos wywolywania DoResize(.., false) z InitImplDepend:
   zabezpieczamy sie przed tym zawsze. Ale mozna tu odnotowac ze z pewnoscia
   InitImplDepend moze wywolywac DoResize(.., false) w przypadku
   implementacji WINAPI i GTK.
 }

 { update FWidth, FHeight.
   Below we are explicitly forcing assertions about ResizeAllowed:
   when ResizeAllowed
     = raNotAllowed: FWidth and FHeight cannot change
     = raOnlyAtInit: FWidth and FHeight can change only once, at first EventResize
     = raAllowed: FWidth and FHeight can change freely
 }
 if (ResizeAllowed = raAllowed) or
    ((ResizeAllowed = raOnlyAtInit) and FromIndependentInit) then
 begin
  FWidth := Clamped(AWidth,  MinWidth,  MaxWidth);
  FHeight := Clamped(AHeight, MinHeight, MaxHeight);
 end;

 { do not call EventResize before EventInit (this check is needed
   because InitImplDepend is allowed to call DoResize) }
 if not EventInitCalled then Exit;

 { jezeli ResizeAllowed <> raAllowed to nie powinnismy wywolywac EventResize
   poza pierwszym razem (gdy FromIndependentInit).
   Kazdy nastepny raz i tak bylby pozbawiony
   znaczenia, bo przeciez Width i Height i tak nie ulegly zmianie. }
 if (not FromIndependentInit) and (ResizeAllowed <> raAllowed) then Exit;

 MakeCurrent;
 EventResize;
end;

procedure TGLWindow.DoCloseQuery;
begin
 MakeCurrent;
 if EventCloseQuery then Close;
end;

procedure TGLWindow.DoDraw;
begin
 { musimy tu uwzgledniac fakt ze w Event[Before]Draw moglismy zamknac okienko }

 MakeCurrent;

 EventBeforeDraw;
 if Closed then exit;

 Fps_RenderStart;
 try
  EventDraw;
  if Closed then exit;

  if DoubleBuffer then SwapBuffers else glFlush;
  if AutoRedisplay then
  begin
   if Glwm.AutoRedisplayAddToList > 0 then
   begin
    if Glwm.AutoRedisplayList.IndexOf(Self) = -1 then
     Glwm.AutoRedisplayList.Add(Self);
   end else
    PostRedisplay;
  end;
 finally Fps_RenderEnd end;

 {$ifdef GLWINDOW_CHECK_GL_ERRORS_AFTER_DRAW} CheckGLErrors; {$endif}
end;

procedure TGLWindow.DoKeyDown(Key: TKey; CharKey: char);

  function SeekMatchingMenuItem: TMenuItem;

    function SeekMe(Entry: TMenuEntry): TMenuItem;
    var i: Integer;
    begin
     Result := nil;
     if Entry is TMenu then
     begin
      for i := 0 to TMenu(Entry).EntriesCount-1 do
      begin
       Result := SeekMe(TMenu(Entry).Entries[i]);
       if Result <> nil then Break;
      end;
     end else
     if (Entry is TMenuItem) and
        ( ((Key <> K_None) and (TMenuItem(Entry).Key = Key)) or
          ((CharKey <> #0) and (TMenuItem(Entry).CharKey = CharKey)) ) then
      Result := TMenuItem(Entry);
    end;

  begin
   if MainMenu <> nil then
    Result := SeekMe(MainMenu) else
    Result := nil;
  end;

var MatchingMI: TMenuItem;
begin
 if Key <> K_None then KeysDown[Key] := true;

 if (Key <> K_None) and
    (CharKey <> #0) and
    (PressedKeyToCharacter[Key] = #0) then
 begin
   { update CharactersDown and PressedXxx mapping arrays }
   if PressedCharacterToKey[CharKey] = K_None then
   begin
     Assert(not CharactersDown[CharKey]);
     CharactersDown[CharKey] := true;
   end else
   begin
     { some key already recorded as generating this character }
     Assert(CharactersDown[CharKey]);
     Assert(PressedKeyToCharacter[PressedCharacterToKey[CharKey]] = CharKey);

     PressedKeyToCharacter[PressedCharacterToKey[CharKey]] := #0;
     PressedCharacterToKey[CharKey] := K_None;
   end;

   PressedKeyToCharacter[Key] := CharKey;
   PressedCharacterToKey[CharKey] := Key;
 end;

 MatchingMI := SeekMatchingMenuItem;
 if (MainMenu <> nil) and
    MainMenu.Enabled and
    (MatchingMI <> nil) then
 begin
  if RedirectKeyDownToMenuCommand then
   DoMenuCommand(MatchingMI);
 end else
 begin
  MakeCurrent;
  EventKeyDown(Key, CharKey);
 end;
end;

procedure TGLWindow.DoKeyUp(key: TKey);
var
  C: char;
begin
  if KeysDown[Key] then
  begin
    { K_None key is never pressed, DoKeyDown guarentees this }
    Assert(Key <> K_None);

    C := PressedKeyToCharacter[Key];
    if C <> #0 then
    begin
      { update CharactersDown and PressedXxx mapping arrays }
      Assert(CharactersDown[C]);
      CharactersDown[C] := false;
      PressedCharacterToKey[C] := K_None;
      PressedKeyToCharacter[Key] := #0;
    end;

    KeysDown[key] := false;
    MakeCurrent;
    EventKeyUp(key, C);
  end;
end;

procedure TGLWindow.DoMouseMove(x, y: integer);
begin
 MakeCurrent;
 EventMouseMove(x, y);
 FMouseX := x; { odswiezamy FMouseXY dopiero PO wywolaniu EventMouseMove }
 FMouseY := y;
end;

procedure TGLWindow.DoMouseDown(x, y: integer; btn: TMouseButton);
begin
 FMouseX := x;
 FMouseY := y;
 Include(FMousePressed, btn);
 MakeCurrent;
 EventMouseDown(btn);
end;

procedure TGLWindow.DoMouseUp(x, y: integer; btn: TMouseButton);
begin
 FMouseX := x;
 FMouseY := y;
 Exclude(FMousePressed, btn);
 MakeCurrent;
 EventMouseUp(btn);
end;

procedure TGLWindow.DoIdle;
var
  NewLastIdleStartTime: TKamTimerResult;
begin
  { update FIdleSpeed, DoIgnoreNextIdleSpeed, LastIdleStartTime }
  NewLastIdleStartTime := KamTimer;

  if DoIgnoreNextIdleSpeed then
  begin
    FIdleSpeed := 0.0;
    DoIgnoreNextIdleSpeed := false;
  end else
    FIdleSpeed := ((NewLastIdleStartTime - LastIdleStartTime) / KamTimerFrequency);

  LastIdleStartTime := NewLastIdleStartTime;

  MakeCurrent;
  EventIdle;
end;

procedure TGLWindow.DoTimer; begin  MakeCurrent; EventTimer end;

procedure TGLWindow.DoMenuCommand(Item: TMenuItem);
begin
 if (MainMenu <> nil) and (not MainMenu.Enabled) then Exit;

 MakeCurrent;
 if Item.DoCommand then Exit;

 { Maybe Item.DoCommand changed current OpenGL context and returned false ?
   We want to be safe, so we do here MakeCurrent again. }
 MakeCurrent;
 EventMenuCommand(Item);
end;

{ funkcje EventXxx ktore sa wirtualne i sa GWARANTOWANE ze w klasie bazowej
  wywoluja po prostu OnXxx. Te funkcje moga byc pokrywane w podklasach.
  ---------------------------------------------------------------------------- }

function TGLWindow.EventCloseQuery: boolean;
const EventName = 'CloseQuery';
begin
 result := not Assigned(OnCloseQuery);
 {$I glwindow_eventbegin.inc}
 if Assigned(OnCloseQuery) then
 begin
  {$I glwindow_eventoncallbegin.inc}
  OnCloseQuery(Self);
  {$I glwindow_eventoncallend.inc}
 end;
 {$I glwindow_eventend.inc}
end;

procedure TGLWindow.EventInit;                          const EventName = 'Init';      begin {$I glwindow_eventbegin.inc} if Assigned(OnInit)      then begin {$I glwindow_eventoncallbegin.inc} OnInit(Self);                  {$I glwindow_eventoncallend.inc} end;   OnInitList .ExecuteAll(Self); {$I glwindow_eventend.inc} end;
procedure TGLWindow.EventClose;                         const EventName = 'Close';     begin {$I glwindow_eventbegin.inc} if Assigned(OnClose)     then begin {$I glwindow_eventoncallbegin.inc} OnClose(Self);                 {$I glwindow_eventoncallend.inc} end;   OnCloseList.ExecuteAll(Self); {$I glwindow_eventend.inc} end;
procedure TGLWindow.EventBeforeDraw;                    const EventName = 'BeforeDraw';begin { $I glwindow_eventbegin.inc} if Assigned(OnBeforeDraw)then begin {$I glwindow_eventoncallbegin.inc} OnBeforeDraw(Self);            {$I glwindow_eventoncallend.inc} end;   { $I glwindow_eventend.inc} end;
procedure TGLWindow.EventDraw;                          const EventName = 'Draw';      begin { $I glwindow_eventbegin.inc} if Assigned(OnDraw)      then begin {$I glwindow_eventoncallbegin.inc} OnDraw(Self);                  {$I glwindow_eventoncallend.inc} end;   { $I glwindow_eventend.inc} end;
{$define BONUS_LOG_STRING := Format('NewSize : %d,%d', [Width, Height])}
procedure TGLWindow.EventResize;                        const EventName = 'Resize';    begin {$I glwindow_eventbegin.inc} if Assigned(OnResize)    then begin {$I glwindow_eventoncallbegin.inc} OnResize(Self);                {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
{$undef BONUS_LOG_STRING}
{$define BONUS_LOG_STRING := Format('Key %s, character %s (ord: %d)', [KeyToStr(Key), CharToNiceStr(c), Ord(c)])}
procedure TGLWindow.EventKeyDown(Key: TKey; C: char);    const EventName = 'KeyDown';  begin {$I glwindow_eventbegin.inc} if Assigned(OnKeyDown)   then begin {$I glwindow_eventoncallbegin.inc} OnKeyDown(Self, Key, C);          {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
{$undef BONUS_LOG_STRING}
{$define BONUS_LOG_STRING := Format('Key %s, character %s (ord: %d)', [KeyToStr(Key), CharToNiceStr(c), Ord(c)])}
procedure TGLWindow.EventKeyUp(key: TKey; C: char);      const EventName = 'KeyUp';     begin {$I glwindow_eventbegin.inc} if Assigned(OnKeyUp)     then begin {$I glwindow_eventoncallbegin.inc} OnKeyUp(Self, key, C);          {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
{$undef BONUS_LOG_STRING}
{$define BONUS_LOG_STRING := Format('New position: %d %d', [newX, newY])}
procedure TGLWindow.EventMouseMove(newX, newY: integer); const EventName = 'MouseMove'; begin { $I glwindow_eventbegin.inc} if Assigned(OnMouseMove) then begin {$I glwindow_eventoncallbegin.inc} OnMouseMove(Self, newX, newY); {$I glwindow_eventoncallend.inc} end;   { $I glwindow_eventend.inc} end;
{$undef BONUS_LOG_STRING}
{$define BONUS_LOG_STRING := Format('Button: %s', [MouseButtonStr[btn]])}
procedure TGLWindow.EventMouseDown(btn: TMouseButton);   const EventName = 'MouseDown'; begin {$I glwindow_eventbegin.inc} if Assigned(OnMouseDown) then begin {$I glwindow_eventoncallbegin.inc} OnMouseDown(Self, btn);        {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
procedure TGLWindow.EventMouseUp(btn: TMouseButton);     const EventName = 'MouseUp';   begin {$I glwindow_eventbegin.inc} if Assigned(OnMouseUp)   then begin {$I glwindow_eventoncallbegin.inc} OnMouseUp(Self, btn);          {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
{$undef BONUS_LOG_STRING}
procedure TGLWindow.EventMenuCommand(Item: TMenuItem);   const EventName = 'MenuCommand';begin {$I glwindow_eventbegin.inc} if Assigned(OnMenuCommand) then begin {$I glwindow_eventoncallbegin.inc} OnMenuCommand(Self, Item);  {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;

{ ponizej sa zdarzenia idlelike. Jezeli not GLWINDOW_LOGFILE_IDLELIKE
  to tymczasowo robimy tez undefine GLWINDOW_LOGFILE. }
{$ifndef GLWINDOW_LOGFILE_IDLELIKE}
  {$ifdef GLWINDOW_LOGFILE}
    {$define WAS_GLWINDOW_LOGFILE}
    {$undef GLWINDOW_LOGFILE}
  {$endif}
{$endif}
procedure TGLWindow.EventIdle;                          const EventName = 'Idle';      begin {$I glwindow_eventbegin.inc} if Assigned(OnIdle)      then begin {$I glwindow_eventoncallbegin.inc} OnIdle(Self);                  {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
procedure TGLWindow.EventTimer;                         const EventName = 'Timer';     begin {$I glwindow_eventbegin.inc} if Assigned(OnTimer)     then begin {$I glwindow_eventoncallbegin.inc} OnTimer(Self);                 {$I glwindow_eventoncallend.inc} end;   {$I glwindow_eventend.inc} end;
{$ifndef GLWINDOW_LOGFILE_IDLELIKE}
  {$ifdef WAS_GLWINDOW_LOGFILE}
    {$define GLWINDOW_LOGFILE}
  {$endif}
{$endif}

function TGLWindow.AllowsProcessMessageSuspend: boolean;
begin
 result := not (Assigned(OnIdle) or Assigned(OnTimer));
end;

{ Menu things ------------------------------------------------------------ }

procedure TGLWindow.SetMainMenu(Value: TMenu);
begin
 if MainMenu <> Value then
 begin
  if (not Closed) and ((MainMenu <> nil) <> (Value <> nil)) then
   raise EInternalError.Create('While TGLWindow is not Closed, '+
     'you can''t set MainMenu from nil to non-nil or from non-nil to nil');
  FMainMenu := Value;
  if not Closed then
   MainMenuChanged;
 end;
end;

{ SaveScreen wykonane na GLWindow (robimy najpierw FlushRedisplay)
  -------------------------------------------------------------------------- }

procedure TGLWindow.SaveScreen(const fname: string);
begin
 if DoubleBuffer then
 begin
  EventDraw;
  SaveScreen_noflush(fname, GL_BACK);
 end else
 begin
  FlushRedisplay;
  SaveScreen_noflush(fname, GL_FRONT);
 end;
end;

function TGLWindow.SaveScreen: TRGBImage;
begin
 if DoubleBuffer then
 begin
  EventDraw;
  Result := SaveScreen_noflush(GL_BACK);
 end else
 begin
  FlushRedisplay;
  Result := SaveScreen_noflush(GL_FRONT);
 end;
end;

function TGLWindow.SaveScreen(
  const xpos, ypos, SavedAreaWidth, SavedAreaHeight: integer): TRGBImage;
var
  ReadBuffer: TGLenum;
begin
  if DoubleBuffer then
  begin
    EventDraw;
    ReadBuffer := GL_BACK;
  end else
  begin
    FlushRedisplay;
    ReadBuffer := GL_FRONT;
  end;
  Result := SaveScreen_noflush(xpos, ypos,
    SavedAreaWidth, SavedAreaHeight, ReadBuffer);
end;

function TGLWindow.SaveScreenToDisplayList: TGLuint;
begin
 if DoubleBuffer then
 begin
  EventDraw;
  Result := SaveScreenToDisplayList_noflush(GL_BACK);
 end else
 begin
  FlushRedisplay;
  Result := SaveScreenToDisplayList_noflush(GL_FRONT);
 end;
end;

function TGLWindow.SaveScreenToDisplayList(
  const xpos, ypos, SavedAreaWidth, SavedAreaHeight: integer): TGLuint;
var
  ReadBuffer: TGLenum;
begin
  if DoubleBuffer then
  begin
    EventDraw;
    ReadBuffer := GL_BACK;
  end else
  begin
    FlushRedisplay;
    ReadBuffer := GL_FRONT;
  end;
  Result := SaveScreenToDisplayList_noflush(xpos, ypos,
    SavedAreaWidth, SavedAreaHeight, ReadBuffer);
end;

{$ifndef GLWINDOW_GLUT}
procedure TGLWindow.SaveScreenDialog(ProposedFileName: string);
begin
  if FileDialog('Save screen to file', ProposedFileName, false,
    SaveImage_FileFilters) then
   SaveScreen(ProposedFileName);
end;

function TGLWindow.FileDialog(const Title: string; var FileName: string;
  OpenDialog: boolean; const FileFilters: string): boolean;
var
  FFList: TFileFiltersList;
begin
  FFList := TFileFiltersList.Create;
  try
    FFList.AddFiltersFromString(FileFilters);
    Result := FileDialog(Title, FileName, OpenDialog, FFList);
  finally FreeWithContentsAndNil(FFList) end;
end;
{$endif}

{ ----------------------------------------------------------------------------
  Get/Set callbacks State }

function TGLWindow.GetCallbacksState: TGLWindowCallbacks;
begin
 with result do
 begin
  MouseMove := OnMouseMove;
  MouseDown := OnMouseDown;
  MouseUp := OnMouseUp;
  KeyDown := OnKeyDown;
  KeyUp := OnKeyUp;
  BeforeDraw := OnBeforeDraw;
  Draw := OnDraw;
  CloseQuery := OnCloseQuery;
  Resize := OnResize;
  Idle := OnIdle;
  Timer := OnTimer;
  MenuCommand := OnMenuCommand;
 end;
end;

procedure TGLWindow.SetCallbacksState(const Callbacks: TGLWindowCallbacks);
begin
 with Callbacks do
 begin
  OnMouseMove := MouseMove;
  OnMouseDown := MouseDown;
  OnMouseUp := MouseUp;
  OnKeyDown := KeyDown;
  OnKeyUp := KeyUp;
  OnBeforeDraw := BeforeDraw;
  OnDraw := Draw;
  OnCloseQuery := CloseQuery;
  OnResize := Resize;
  OnIdle := Idle;
  OnTimer := Timer;
  OnMenuCommand := MenuCommand;
 end;
end;

{ -----------------------------------------------------------------------------
  Init+Loop at once }

procedure TGLWindow.InitLoop(const ACaption: string; AOnDraw: TDrawFunc);
begin
 FCaption := ACaption;
 OnDraw := AOnDraw;
 InitLoop;
end;

procedure TGLWindow.InitLoop;
begin
 Init;
 Glwm.Loop;
end;

{ TGLWindow ParseParameters -------------------------------------------------- }

type
  TOptionProcData = record
    SpecifiedOptions: TGLWindowParseOptions;
    glwin: TGLWindow;
  end;
  POptionProcData = ^TOptionProcData;

procedure GeometryOptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
var ProcData: POptionProcData absolute Data;

  procedure ApplyGeometryParam(const geom: string);
  var p: integer;
      parWidth, parHeight, parXoff, parYoff: integer;
      xoffPlus, yoffPlus, sizeSpecified, positionSpecified: boolean;
      { p to znak w stringu geom ktory teraz chcemy czytac.
        parWidth i parHeight sa valid tylko o ile sizeSpecified.
        parXoff, parYoff, xoffPlus, yoffPlus sa valid tylko o ile positionSpecified.
      }

    procedure ParseSize;
    { parsuje width i height }
    var startp: integer;
    begin
     sizeSpecified := true;

     {width}
     startp := p;
     while SCharIs(geom, p, ['0'..'9']) do Inc(p);
     parWidth := StrToInt(CopyPos(geom, startp, p-1));

     {height}
     if not SCharIs(geom, p, ['x','X']) then
      raise EInvalidParams.Create(
        'Invalid --geometry parameter : expected "x" between WIDTH and HEIGHT');
     Inc(p);
     startp := p;
     while SCharIs(geom, p, ['0'..'9']) do Inc(p);
     parHeight := StrToInt(CopyPos(geom, startp, p-1));
    end;

    procedure ParsePosition;
    { parsuje xoff, yoff i koniec stringa. }
    var startp: integer;
    begin
     positionSpecified := true;

     {xoff}
     if not SCharIs(geom, p, ['-','+']) then
      raise EInvalidParams.Create(
        'Invalid --geometry parameter : expected "-" or "+" before XOFF');
     xoffPlus := geom[p] = '+';
     Inc(p);
     startp := p;
     if SCharIs(geom, p, ['-','+']) then Inc(p);
     while SCharIs(geom, p, ['0'..'9']) do Inc(p);
     parXoff := StrToInt(CopyPos(geom, startp, p-1));

     {yoff}
     if not SCharIs(geom, p, ['-','+']) then
      raise EInvalidParams.Create(
        'Invalid --geometry parameter : expected "-" or "+" before YOFF');
     yoffPlus := geom[p] = '+';
     Inc(p);
     startp := p;
     if SCharIs(geom, p, ['-','+']) then Inc(p);
     while SCharIs(geom, p, ['0'..'9']) do Inc(p);
     parYoff := StrToInt(CopyPos(geom, startp, p-1));

     {end of string}
     if not (p = Length(geom)+1) then
      raise EInvalidParams.Create(
        'Invalid --geometry parameter : expected end of parameter');
    end;

  begin
   ProcData^.glwin.FullScreen := false;
   try
    sizeSpecified := false;
    positionSpecified := false;
    p := 1;

    if SCharIs(geom, p,['+','-']) then
     ParsePosition else
    begin
     ParseSize;
     if p <= Length(geom) then ParsePosition;
    end;

    {ok, now we can apply what we have}
    if sizeSpecified then
    begin
     ProcData^.glwin.Width := parWidth;
     ProcData^.glwin.Height := parHeight;
    end;
    if positionSpecified then
    begin
     if xoffPlus then
      ProcData^.glwin.Left := parXoff else
      ProcData^.glwin.Left := Glwm.ScreenWidth-parXoff-parWidth;
     if yoffPlus then
      ProcData^.glwin.Top := parYoff else
      ProcData^.glwin.Top := Glwm.ScreenHeight-parYoff-parHeight;
    end;

   except
    on E: EConvertError do
     raise EInvalidParams.Create('Invalid --geometry parameter : '+E.Message);
   end;
  end;

begin
 Include(ProcData^.SpecifiedOptions, poGeometry);
 case OptionNum of
  0: ProcData^.glwin.FullScreen := true;
  1: ApplyGeometryParam(Argument);
 end;
end;

procedure ScreenGeometryOptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
var ProcData: POptionProcData absolute Data;

  procedure ApplyFullScreenCustomParam(const option: string);
  var p: integer;
  begin
   ProcData^.glwin.FullScreen := true;
   try
    p := CharsPos(['x','X'], option);
    if p = 0 then
     raise EInvalidParams.Create(
       'Invalid --fullscreen-custom parameter - format is not WIDTHxHEIGHT');
    Glwm.VideoResizeWidth := StrToInt(Copy(option, 1, p-1));
    Glwm.VideoResizeHeight := StrToInt(SEnding(option, p+1));
    Glwm.VideoResize := true;
    Glwm.VideoChange(true);
   except
    on E: EConvertError do
     raise EInvalidParams.Create('Invalid --fullscreen-custom parameter : '+E.Message);
   end;
  end;

begin
 Include(ProcData^.SpecifiedOptions, poScreenGeometry);
 case OptionNum of
  0: ApplyFullScreenCustomParam(Argument);
 end;
end;

procedure DisplayOptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
var
  ProcData: POptionProcData absolute Data;
begin
  Include(ProcData^.SpecifiedOptions, poDisplay);
  case OptionNum of
    0: {$ifdef GLWINDOW_XLIB}
       if Glwm.FActive.Count <> 0 then
         WarningWrite(ProgramName + ': some windows are already open ' +
           'so --display option is ignored.') else
         Glwm.XDisplayName := Argument;
       {$else}
         {$ifdef GLWINDOW_GTK_2}
         Glwm.XDisplayName := Argument;
         {$else}
         WarningWrite(ProgramName + ': warning: --display option is ignored ' +
           'when we don''t use directly Xlib');
         {$endif}
       {$endif}
  end;
end;

procedure TGLWindow.ParseParameters(const AllowedOptions: TGLWindowParseOptions;
  out SpecifiedOptions: TGLWindowParseOptions);

const
  GeometryOptions: array[0..1]of TOption =
  ( (Short:#0; Long:'fullscreen'; Argument: oaNone),
    (short:#0; Long:'geometry'; Argument: oaRequired) );

  ScreenGeometryOptions: array[0..0]of TOption =
  ( (Short:#0; Long:'fullscreen-custom'; Argument: oaRequired) );

  DisplayOptions: array[0..0]of TOption =
  ( (Short:#0; Long:'display'; Argument: oaRequired) );

  OptionsForParam: array[TGLWindowParseOption] of
    record
      pOptions: POption_Array;
      Count: Integer;
      OptionProc: TOptionProc;
    end =
  ( ( pOptions: @GeometryOptions;
      Count: High(GeometryOptions)+1;
      OptionProc: {$ifdef FPC_OBJFPC} @ {$endif} GeometryOptionProc),
    ( pOptions: @ScreenGeometryOptions;
      Count: High(ScreenGeometryOptions) + 1;
      OptionProc: {$ifdef FPC_OBJFPC} @ {$endif} ScreenGeometryOptionProc),
    ( pOptions: @DisplayOptions;
      Count: High(DisplayOptions) + 1;
      OptionProc: {$ifdef FPC_OBJFPC} @ {$endif} DisplayOptionProc)
  );

var Data: TOptionProcData;
    ParamKind: TGLWindowParseOption;
begin
 Data.SpecifiedOptions := [];
 Data.glwin := Self;

 for ParamKind := Low(ParamKind) to High(ParamKind) do
  if ParamKind in AllowedOptions then
   ParseParametersUnit.ParseParameters(OptionsForParam[ParamKind].pOptions,
     OptionsForParam[ParamKind].Count,
     OptionsForParam[ParamKind].OptionProc, @Data, true);

 SpecifiedOptions := Data.SpecifiedOptions;
end;

procedure TGLWindow.ParseParameters(const AllowedOptions: TGLWindowParseOptions);
var dummy: TGLWindowParseOptions;
begin
 ParseParameters(AllowedOptions, dummy);
end;

procedure TGLWindow.ParseParameters();
begin
 ParseParameters(StandardParseOptions);
end;

class function TGLWindow.ParseParametersHelp(
  const AllowedOptions: TGLWindowParseOptions;
  AddHeader: boolean): string;
const
  HelpForParam: array[TGLWindowParseOption] of string =
  ('  --geometry WIDTHxHEIGHT<sign>XOFF<sign>YOFF' +nl+
   '                        Set initial window size and/or position' +nl+
   '  --fullscreen          Set initial window size to cover whole screen',
   '  --fullscreen-custom WIDTHxHEIGHT' +nl+
   '                        Try to resize the screen to WIDTHxHEIGHT and' +nl+
   '                        then set initial window size to cover whole screen',
   '  --display DISPLAY-NAME' +nl+
   '                        Use given XWindows display name.'
   );
var ParamKind: TGLWindowParseOption;
begin
 if AddHeader then
  result := 'Window options:' else
  result := '';

 for ParamKind := Low(ParamKind) to High(ParamKind) do
  if ParamKind in AllowedOptions then
  begin
   if result <> '' then result += nl;
   result += HelpForParam[ParamKind];
  end;
end;

{ FPS ------------------------------------------------------------------------ }

procedure TGLWindow.FpsReset;
var
  NowTick: TMilisecTime;
  FrameTime, RealTime: Double;
begin
  { We could just set Fps_FramesRendered = 0 and Fps_FrameTimePassed = 0.
    This would basically reset the FPS measurements.

    But it would be very crude solution. Right after FpsReset, our FpsFrameTime/
    FpsRealTime measurements would be completely wrong.
    So we use FpsHoldsAfterReset to counteract this. }

  if FpsHoldsAfterReset = 0 then
  begin
    { reset brutally }
    Fps_FramesRendered := 0;
    Fps_FrameTimePassed := 0;
  end else
  begin
    if Fps_FramesRendered <> 0 then
    begin
      { save measures }
      FrameTime := FpsFrameTime;
      RealTime := FpsRealTime;
    end else
    begin
      { Init some default measures. Otherwise FPS would be wild at the start
        of the program, when Fps_FramesRendered = 0. }
      FrameTime := 80;
      RealTime := 80;
    end;

    { fake that already FpsHoldsAfterReset time passed }
    NowTick := GetTickCount;
    if NowTick > FpsHoldsAfterReset then
      Fps_FirstTimeTick := NowTick - FpsHoldsAfterReset else
      { Once in 49 days Fps_FirstTimeTick has to be wrong... }
      Fps_FirstTimeTick := 0;

    { Adjust Fps_FramesRendered to make new FpsRealTime = old FpsRealTime
      (saved in RealTime).
      RealTime = Fps_FramesRendered * 1000 / FpsHoldsAfterReset sos }
    Fps_FramesRendered := Round(RealTime * FpsHoldsAfterReset / 1000.0);

    { Adjust Fps_FrameTimePassed to make new FpsFrameTime = old FpsFrameTime.

      Remember that Fps_FrameTimePassed is in KamTimerFrequency units.
      So we want to
      Fps_FramesRendered  / (Fps_FrameTimePassed / KamTimerFrequency) = FrameTime so
      Fps_FramesRendered * KamTimerFrequency  / Fps_FrameTimePassed = FrameTime so
      Fps_FramesRendered * KamTimerFrequency / FrameTime = Fps_FrameTimePassed. }
    if FrameTime = 0 then
      Fps_FrameTimePassed := 0 else
      Fps_FrameTimePassed := Round(Fps_FramesRendered * KamTimerFrequency / FrameTime);
  end;
end;

procedure TGLWindow.SetFpsActive(value: boolean);
begin
  if Value = FpsActive then Exit;

  FFpsActive := Value;
  if Value then
  begin
    FpsReset;

    { Just init DrawSpeed, IdleSpeed to some sensible defaults.
      Rendering time 30 frames per second seems sensible default for 3D game
      right?

      For IdleSpeed this is actually not essential, since we call
      IgnoreNextCompSpeed anyway. But in case programmer will (incorrectly!)
      try to use IdleSpeed before EventIdle (OnIdle) call, it's useful to have
      here some predictable value. }
    FDrawSpeed := 1 / 30;
    FIdleSpeed := 1 / 30;

    IgnoreNextIdleSpeed;
  end;
end;

procedure TGLWindow.IgnoreNextIdleSpeed;
begin
  DoIgnoreNextIdleSpeed := true;
end;

procedure TGLWindow.Fps_RenderStart;
begin
  if not FpsActive then Exit;

  Fps_RenderStartTime := KamTimer;
end;

procedure TGLWindow.Fps_RenderEnd;
var
  NowTick: TMilisecTime;
begin
  if not FpsActive then Exit;

  { ((KamTimer-Fps_RenderStartTime) / KamTimerFrequency) = time of last frame
    rendering time. }
  FDrawSpeed := (KamTimer - Fps_RenderStartTime) / KamTimerFrequency;

  NowTick := GetTickCount;
  if ((NowTick - Fps_FirstTimeTick) div 1000) >= FpsSecondsToAutoReset then
    FpsReset;

  if Fps_FramesRendered = 0 then Fps_FirstTimeTick := NowTick;
  Inc(Fps_FramesRendered);
  Fps_FrameTimePassed := Fps_FrameTimePassed + KamTimer - Fps_RenderStartTime;
end;

procedure TGLWindow.FpsToCaption(const WindowTitle: string);
begin
  Caption := WindowTitle +
    Format(' - FPS : %f (real : %f)', [FpsFrameTime, FpsRealTime]);
end;

function TGLWindow.FpsRealTime: Double;
var
  TimePass: TMilisecTime;
begin
  Assert(FpsActive, 'FpsRealTime called by Fps counting not Activated');
  TimePass := GetTickCount - Fps_FirstTimeTick;
  if TimePass > 0 then
    Result := Fps_FramesRendered * 1000 / TimePass else
    Result := 0;
end;

function TGLWindow.FpsFrameTime: Double;
begin
  Assert(FpsActive, 'FpsFrameTime called by Fps counting not Activated');
  if Fps_FrameTimePassed > 0 then
    Result := Fps_FramesRendered * KamTimerFrequency / Fps_FrameTimePassed else
    Result := 0;
end;

{ TGLWindow miscella ---------------------------------------- }

function TGLWindow.RequestedBufferAttributes: string;
begin
 if DoubleBuffer then
  result := 'double buffered' else
  result := 'single buffered';
 if DepthBufferBits > 0 then
  result += Format(', with %d-bits sized depth buffer', [DepthBufferBits]);
 if StencilBufferBits > 0 then
  result += Format(', with %d-bits sized stencil buffer', [StencilBufferBits]);
 if AlphaBits > 0 then
  result += Format(', with %d-bits sized alpha channel', [AlphaBits]);
 if not IsZeroVector(AccumBufferBits) then
  result += Format(', with (%d,%d,%d,%d)-bits sized accumulation buffer',
    [AccumBufferBits[0], AccumBufferBits[1],
     AccumBufferBits[2], AccumBufferBits[3]]);
 if MultiSampling > 1 then
  result += Format(', with multisampling (%d samples)', [MultiSampling]);
end;

procedure TGLWindow.CheckRequestedBufferAttributes(const ProviderName: string;
  ProvidedStencilBits, ProvidedDepthBits, ProvidedAlphaBits,
  ProvidedAccumRedBits, ProvidedAccumGreenBits, ProvidedAccumBlueBits,
  ProvidedAccumAlphaBits, ProvidedMultiSampling: Cardinal);

  procedure CheckRequestedBits(const Name: string; RequestedBits, ProvidedBits: Cardinal);
  begin
   if ProvidedBits < RequestedBits then
    raise EGLContextNotPossible.CreateFmt('%s provided OpenGL context with %s'
      +' %d-bits sized but at least %d-bits sized is required',
      [ ProviderName, Name, ProvidedBits, RequestedBits ]);
  end;

begin
 CheckRequestedBits('stencil buffer', StencilBufferBits, ProvidedStencilBits);
 CheckRequestedBits('depth buffer', DepthBufferBits, ProvidedDepthBits);
 CheckRequestedBits('alpha channel', AlphaBits, ProvidedAlphaBits);
 CheckRequestedBits('accumulation buffer''s red channel'  , AccumBufferBits[0], ProvidedAccumRedBits);
 CheckRequestedBits('accumulation buffer''s green channel', AccumBufferBits[1], ProvidedAccumGreenBits);
 CheckRequestedBits('accumulation buffer''s blue channel' , AccumBufferBits[2], ProvidedAccumBlueBits);
 CheckRequestedBits('accumulation buffer''s alpha channel', AccumBufferBits[3], ProvidedAccumAlphaBits);

 { If MultiSampling <= 1, this means that multisampling not required,
   so don't check it. Even if MultiSampling = 1 and ProvidedMultiSampling = 0
   (as most backends report no multisampling as num samples = 0), it's all Ok. }

 if MultiSampling > 1 then
 begin
   if ProvidedMultiSampling < MultiSampling then
    raise EGLContextNotPossible.CreateFmt('%s provided OpenGL context with %d ' +
      'samples for multisampling (<= 1 means that no multisampling was provided) ' +
      'but at last %d samples for multisampling is required',
      [ ProviderName, ProvidedMultiSampling, MultiSampling ]);
 end;
end;

{ TGLWindowDemo ---------------------------------------------------------------- }

procedure TGLWindowDemo.SwapFullScreen;

  procedure SaveRect;
  begin
   wLeft := Left;
   wTop := Top;
   wWidth := Width;
   wHeight := Height;
  end;

begin
 fSwappingFullscr := true;
 try
  Close(false);
  if not FFullScreen then SaveRect; { save window rect }
  FFullScreen := not FFullScreen;
  if not FFullScreen then
  begin
   Left := wLeft;
   Top := wTop;
   Width := wWidth;
   Height := wHeight;
  end;
  Init;
 finally fSwappingFullscr := false end;
end;

procedure TGLWindowDemo.EventIdle;
const
  { This is the amount of time (in miliseconds) that we must wait
    before updating Caption next time.

    Note that updating Caption of the window too often *may* cause
    a significant FPS dropdown, i.e. : don't do this too often !
    I once used here value 200. It's 5 times per second,
    this didn't seem too often, until once I checked my program
    with this turned off and found that my program runs now
    much faster (you can see that looking at FpsRealTime
    (FpsFrameTime does not change)).

    That's why I use here so big value, and I don't recomment
    anyone trying to set this to something smaller.

    If you really want to show FPS counts updated more constantly,
    you should display them each frame as a text in OpenGL
    (like I do in view3dscene). }
  FpsOutputMilisec = 5000;
begin
 inherited;
 {ponizej udalo mi sie zaimplementowac cos jak timer, a jednak nie uzylem
  zadnego callbacka, w szczegolnosci OnTimer okienka ! A wiec sukces -
  ten timer moze sobie dzialac w sposob zupelnie przezroczysty dla okienka,
  ktore moze swobodnie modyfikowac swoje OnTimer, Glwm.OnTimer,
  Glwm.TimerMilisec. }
 if FpsShowOnCaption and
    ((lastFPSOutputTick = 0) or
     (TimeTickDiff(lastFPSOutputTick, GetTickCount) >= FpsOutputMilisec)) then
 begin
  lastFPSOutputTick := GetTickCount;
  FpsToCaption(FFPSBaseCaption);
 end;
end;

function TGLWindowDemo.AllowsProcessMessageSuspend: boolean;
begin
 result := (inherited AllowsProcessMessageSuspend) and (not FpsShowOnCaption)
end;

procedure TGLWindowDemo.EventInit;
begin
 if not SwappingFullscr then
 begin
  if FpsShowOnCaption then
  begin
   { init frames per second write in timer }
   FpsActive := true;
   FFPSBaseCaption := Caption;
  end;

  { set initial window rect (wLeft/top/width/height) if fullscreen = true }
  if FFullScreen then
  begin
   wWidth  := GLWindowDefaultSize;
   wHeight := GLWindowDefaultSize;
   wLeft   := GLWindowPositionCenter;
   wTop    := GLWindowPositionCenter;
  end;
 end;

 inherited;
end;

procedure TGLWindowDemo.EventKeyDown(Key: TKey; c: char);
begin
 if (c <> #0) and (c = Close_CharKey) then
   Close else
 if (Key <> K_None) and (Key = SwapFullScreen_Key) then
   SwapFullScreen else
   inherited;
   { nie wywoluj inherited jesli to byl klawisz Close_CharKey lub
     SwapFullScreen_Key bo te klawisze zmienily okienko na tyle ze mozna
     podejrzewac ze wcisniecie klawisza mozna juz uznac za nieaktualne. }
end;

procedure TGLWindowDemo.SetDemoOptions(ASwapFullScreen_Key: TKey;
  AClose_CharKey: char;
  AFpsShowOnCaption: boolean);
begin
  SwapFullScreen_Key := ASwapFullScreen_Key;
  Close_CharKey := AClose_CharKey;
  FpsShowOnCaption := AFpsShowOnCaption;
end;

procedure TGLWindowDemo.SetFPSBaseCaption(const Value: string);
begin
  if FFPSBaseCaption <> Value then
  begin
    FFPSBaseCaption := Value;
    { Update Caption now, otherwise Caption would get updated with
      some latency (because only when FpsOutputMilisec is reached). }
    FpsToCaption(FFPSBaseCaption);
  end;
end;

constructor TGLWindowDemo.Create;
begin
  inherited;
  Close_CharKey := CharEscape;
  SwapFullScreen_Key := K_F11;
  FpsShowOnCaption := true;
end;

{ TGLWindowNavigated ------------------------------------------------------------------ }

constructor TGLWindowNavigated.Create;
begin
 inherited;
 UseNavigator := true;
 OwnsNavigator := true;
end;

destructor TGLWindowNavigated.Destroy;
begin
 if OwnsNavigator then Navigator.Free;
 inherited;
end;

function TGLWindowNavigated.ReallyUseNavigator: boolean;
begin
 result := UseNavigator and (Navigator <> nil);
end;

procedure TGLWindowNavigated.PostRedisplayOnMatrixChanged(ChangedNavigator: TNavigator);
begin
 PostRedisplay;
end;

procedure TGLWindowNavigated.EventIdle;
begin
  if ReallyUseNavigator then
    Navigator.Idle(IdleSpeed, @KeysDown, @CharactersDown, MousePressed);
  inherited;
end;

procedure TGLWindowNavigated.EventKeyDown(Key: TKey; C: char);
begin
 if not (ReallyUseNavigator and Navigator.KeyDown(Key, c, @KeysDown)) then
  inherited;
end;

procedure TGLWindowNavigated.EventMouseDown(Button: TMouseButton);
begin
  if not (ReallyUseNavigator and Navigator.MouseDown(Button)) then
    inherited;
end;

procedure TGLWindowNavigated.EventInit;
begin
 inherited;
end;

function TGLWindowNavigated.AllowsProcessMessageSuspend: boolean;
begin
 if ReallyUseNavigator then result := false else result := inherited;
end;

function TGLWindowNavigated.ExamineNav: TExamineNavigator;
begin
  Result :=
    {$ifdef DEBUG} Navigator as TExamineNavigator
    {$else} TExamineNavigator(Navigator)
    {$endif};
end;

function TGLWindowNavigated.WalkNav: TWalkNavigator;
begin
  Result :=
    {$ifdef DEBUG} Navigator as TWalkNavigator
    {$else} TWalkNavigator(Navigator)
    {$endif};
end;

procedure TGLWindowNavigated.RayFromCustomNavigator(
  Nav: TWalkNavigator;
  const WindowX, WindowY: Integer;
  const ViewAngleDegX, ViewAngleDegY: Single;
  out Ray0, RayVector: TVector3Single);
begin
  Ray0 := Nav.CameraPos;
  RayVector := PrimaryRay(WindowX, Height - WindowY,
    Width, Height,
    Nav.CameraPos, Nav.CameraDir, Nav.CameraUp,
    ViewAngleDegX, ViewAngleDegY);
end;

procedure TGLWindowNavigated.MousePickedRayFromCustomNavigator(
  Nav: TWalkNavigator;
  const ViewAngleDegX, ViewAngleDegY: Single;
  out Ray0, RayVector: TVector3Single);
begin
  RayFromCustomNavigator(
    Nav, MouseX, MouseY, ViewAngleDegX, ViewAngleDegY, Ray0, RayVector);
end;

procedure TGLWindowNavigated.Ray(const WindowX, WindowY: Integer;
  const ViewAngleDegX, ViewAngleDegY: Single;
  out Ray0, RayVector: TVector3Single);
begin
  RayFromCustomNavigator(
    Navigator as TWalkNavigator,
    WindowX, WindowY, ViewAngleDegX, ViewAngleDegY, Ray0, RayVector);
end;

procedure TGLWindowNavigated.MousePickedRay(
  const ViewAngleDegX, ViewAngleDegY: Single;
  out Ray0, RayVector: TVector3Single);
begin
  MousePickedRayFromCustomNavigator(
    Navigator as TWalkNavigator,
    ViewAngleDegX, ViewAngleDegY, Ray0, RayVector);
end;

function TGLWindowNavigated.ReallyUseMouseLook: boolean;
begin
  Result := ReallyUseNavigator and
    (Navigator is TWalkNavigator) and
    TWalkNavigator(Navigator).MouseLook;
end;

procedure TGLWindowNavigated.SetCursorNonMouseLook(
  const Value: TGLWindowCursor);
begin
  if Value <> FCursorNonMouseLook then
  begin
    FCursorNonMouseLook := Value;
    if not ReallyUseMouseLook then
      Cursor := CursorNonMouseLook;
  end;
end;

procedure TGLWindowNavigated.UpdateMouseLook;
var
  ML: boolean;
begin
  ML := ReallyUseMouseLook;
  if ML then
    Cursor := gcNone else
    Cursor := CursorNonMouseLook;
  if ML then
    SetMousePosition(Width div 2, Height div 2);
end;

procedure TGLWindowNavigated.EventMouseMove(NewX, NewY: Integer);
var
  MiddleScreenWidth: Integer;
  MiddleScreenHeight: Integer;
begin
  if not (
    ReallyUseNavigator and
    (Navigator is TExamineNavigator) and
    TExamineNavigator(Navigator).MouseMove(
      MouseX, MouseY, NewX, NewY, MousePressed, @KeysDown)) then
    inherited;

  if ReallyUseMouseLook then
  begin
    MiddleScreenWidth := Width div 2;
    MiddleScreenHeight := Height div 2;

    { Note that SetMousePosition may (but doesn't have to)
      generate OnMouseMove to destination position.
      This can cause some problems:

      1. Consider this:

         - player moves mouse to MiddleX-10
         - MouseMove is generated, I rotate camera by "-10" horizontally
         - SetMousePosition sets mouse to the Middle,
           but this time no MouseMove is generated
         - player moved mouse to MiddleX+10. Although mouse was
           positioned on Middle, TGLWindow thinks that the mouse
           is still positioned on Middle-10, and I will get "+20" move
           for player (while I should get only "+10")

         Fine solution for this would be to always subtract
         MiddleScreenWidth and MiddleScreenHeight below
         (instead of previous values, MouseX and MouseY).
         But this causes another problem:

      2. What if player switches to another window, moves the mouse,
         than goes alt+tab back to our window ? Next mouse move will
         be stupid, because it's really *not* from the middle of the screen.

      The solution for both problems: you have to check that previous
      position, MouseX and MouseY, are indeed equal to
      MiddleScreenWidth and MiddleScreenHeight. This way we know that
      this is good move, that qualifies to perform mouse move. }
    if (MouseX = MiddleScreenWidth) and
       (MouseY = MiddleScreenHeight) then
      TWalkNavigator(Navigator).MouseMove(
        NewX - MiddleScreenWidth, NewY - MiddleScreenHeight);

    { I check the condition below to avoid calling SetMousePosition,
      OnMouseMove, SetMousePosition, OnMouseMove... in a loop.
      Not really likely (as messages will be queued, and some
      SetMousePosition will finally just not generate OnMouseMove),
      but I want to safeguard anyway. }
    if (NewX <> MiddleScreenWidth) or (NewY <> MiddleScreenHeight) then
      SetMousePosition(MiddleScreenWidth, MiddleScreenHeight);
  end;
end;

{ TGLWindowsList ------------------------------------------------------------ }

procedure TGLWindowsList.PostRedisplay;
var i: Integer;
begin
 for i := 0 to Count - 1 do Items[i].PostRedisplay;
end;

{ --------------------------------------------------------------------------
  Generic part of implementation of TGLWindowsManager,
  that does not depend what GLWINDOW_xxx backend you want. }

constructor TGLWindowsManager.Create;
begin
 inherited;
 FActive := TGLWindowsList.Create;
 FTimerMilisec := 1000;
 CreateImplDependent;
end;

destructor TGLWindowsManager.Destroy;
begin
 VideoReset;
 DestroyImplDependent;
 FreeAndNil(FActive);
 inherited;
end;

function TGLWindowsManager.GetActive(Index: integer): TGLWindow;
begin result := FActive[Index] end;

function TGLWindowsManager.ActiveCount: integer;
begin result := FActive.Count end;

procedure TGLWindowsManager.ActiveAdd(glwin: TGLWindow);
begin
 FActive.Add(glwin);
end;

procedure TGLWindowsManager.ActiveRemove(glwin: TGLWindow;
  QuitWhenLastWindowClosed: boolean);
begin
 if FActive.Delete(glwin) and
    (ActiveCount = 0) and QuitWhenLastWindowClosed then Quit;
end;

function TGLWindowsManager.FindWindow(glwin: TGLWindow): integer;
begin
 for result := 0 to ActiveCount-1 do
  if Active[result] = glwin then exit;
 result := -1;
end;

procedure TGLWindowsManager.Quit;
var i: integer;
begin
 { We're calling here Close(false) so we will not cause infinite recursive
   Quit calls. }
 for i := 0 to ActiveCount-1 do Active[i].Close(false);

 QuitWhenNoWindowsActive;
end;

procedure TGLWindowsManager.DoSelfIdle;
begin
 if Assigned(FOnIdle) then FOnIdle;
end;

procedure TGLWindowsManager.DoSelfTimer;
begin
 if Assigned(FOnTimer) then FOnTimer;
end;

procedure TGLWindowsManager.DoActiveWindowsIdle;
var i: integer;
begin
 for i := 0 to ActiveCount-1 do Active[i].DoIdle;
end;

procedure TGLWindowsManager.DoActiveWindowsTimer;
var i: integer;
begin
 for i := 0 to ActiveCount-1 do Active[i].DoTimer;
end;

procedure TGLWindowsManager.MaybeDoTimer(var ALastDoTimerTime: TMilisecTime);
var Now: TMilisecTime;
begin
 Now := GetTickCount;
 if ((ALastDoTimerTime = 0) or
     (MilisecTimesSubtract(Now, ALastDoTimerTime) >= FTimerMilisec)) then
 begin
  ALastDoTimerTime := Now;
  DoSelfTimer;
  DoActiveWindowsTimer;
 end;
end;

{ TGLWindowsManager.Video* things ---------------------------------------- }

{$ifndef GLWINDOW_HAS_VIDEO_CHANGE}
function TGLWindowsManager.TryVideoChange: boolean;
begin
 Result := false;
end;

procedure TGLWindowsManager.VideoReset;
begin
end;
{$endif not GLWINDOW_HAS_VIDEO_CHANGE}

function TGLWindowsManager.VideoSettingsDescribe: string;
begin
  Result := '';
  if VideoResize then
    Result += Format('  Screen size :  %dx%d', [VideoResizeWidth, VideoResizeHeight]) + nl;
  if VideoColorBits <> 0 then
    Result += Format('  Color bits per pixel : %d', [VideoColorBits]) + nl;
  if VideoFrequency <> 0 then
    Result += Format('  Display frequency : %d', [VideoFrequency]) + nl;

  if Result = '' then
    Result := '  No display settings change' + nl;
end;

procedure TGLWindowsManager.VideoChange(OnErrorWarnUserAndContinue: boolean);
var s: string;
begin
 if not TryVideoChange then
 begin
  s := 'Can''t change display settings to : ' + nl + VideoSettingsDescribe;

  {$ifndef GLWINDOW_HAS_VIDEO_CHANGE}
    s += ' (changing Video properties not implemented when GLWindow is '+
      'made on top of ' +ImplementationName +')';
  {$endif}

  if OnErrorWarnUserAndContinue then
   WarningWrite(s+'. Trying to continue anyway.') else
   raise Exception.Create(s);
 end;
end;

{ Resize2D ------------------------------------------------------------ }

procedure Resize2D(glwin: TGLWindow);
begin
 glViewport(0, 0, glwin.Width, glwin.Height);
 ProjectionGLOrtho(0, glwin.Width, 0, glwin.Height);
end;

{ init/fini --------------------------------------------------------------- }

initialization
 Glwm := TGLWindowsManager.Create;
 GLWindowMenu_Init;
finalization
 GLWindowMenu_Fini;
 FreeAndNil(Glwm);
end.
