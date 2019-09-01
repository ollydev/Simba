{%MainUnit simba.oswindow}

uses
  baseunix,
  macosall, simba.darwin_inputhelpers;

function TOSWindow_Helper.IsValid: Boolean;
var
  windowIds, windows: CFArrayRef;
begin
  windowIds := CFArrayCreateMutable(nil, 1, nil);
  CFArrayAppendValue(windowIds, UnivPtr(Self));
  windows := CGWindowListCreateDescriptionFromArray(windowIds);
  CFRelease(windowIds);
  Result := CFArrayGetCount(windows) <> 0;
  CFRelease(windows);
end;

function TOSWindow_Helper.IsActive: Boolean;
begin
  Result := isWindowActive(Self);
end;

function TOSWindow_Helper.IsActive(Time: Int32): Boolean;
var
  T: UInt64;
begin
  T := GetTickCount64() + Time;
  while (T > GetTickCount64()) do
  begin
    if Self.IsActive() then
      Exit(True);

    Sleep(25);
  end;

  Exit(False);
end;

function TOSWindow_Helper.IsVisible: Boolean;
begin
  Result := True; //TODO: Implement
end;

function TOSWindow_Helper.GetPID: UInt32;
begin
  Result := GetWindowInfo(Self).ownerPid;
end;

function TOSWindow_Helper.GetRootWindow: TOSWindow;
begin
  Result := Self;
end;

function TOSWindow_Helper.GetClassName: WideString;
begin
  Result := ''; //TODO: Implement
end;

function TOSWindow_Helper.GetTitle: WideString;
begin
  Result := GetWindowInfo(Self).title;
end;

function TOSWindow_Helper.GetBounds(out Bounds: TBox): Boolean;
var
  info: TWindowInfo;
begin
  info := GetWindowInfo(Self);
  if info.id <> high(CGWindowID) then
  begin
    Bounds.X1 := info.x;
    Bounds.Y1 := info.y;
    Bounds.X2 := info.x + info.width;
    Bounds.Y2 := info.y + info.height;
    Exit(True);
  end;

  Bounds.X1 := -1;
  Bounds.Y1 := -1;
  Bounds.X2 := -1;
  Bounds.Y2 := -1;
  Exit(False);
end;

function TOSWindow_Helper.GetBounds: TBox;
begin
  if (not GetBounds(Result)) then
  begin
    Result.X1 := -1;
    Result.Y1 := -1;
    Result.X2 := -1;
    Result.Y2 := -1;
  end;
end;

function TOSWindow_Helper.GetChildren(Recursive: Boolean): TOSWindowArray;
begin
  //Result := []; //XGetChildren(DefaultDisplay, Self, Recursive); //TODO: FIX
end;

procedure TOSWindow_Helper.SetBounds(Bounds: TBox);
begin
  //XMoveResizeWindow(DefaultDisplay, Self, Bounds.X1, Bounds.Y1, Bounds.X2 - Bounds.X1, Bounds.Y2 - Bounds.Y1);
  //XSync(DefaultDisplay, 0);
  //TODO: FIX
end;

function TOSWindow_Helper.Activate: Boolean;
begin
  //XSetActiveWindow(DefaultDisplay, Self.GetRootWindow());
  //Result := Self.IsActive(1000);
  //TODO: Fix
end;

procedure TOSWindow_Helper.Kill;
begin
  fpkill(Self.GetPID(), SIGTERM);
end;

function GetWindows: TOSWindowArray;
var
  Window: TOSWindow;
begin
  //Window := XDefaultRootWindow(DefaultDisplay);
  //Result := Window.GetChildren();
end;

function GetVisibleWindows: TOSWindowArray;
var
  Window: TOSWindow;
begin
  SetLength(Result, 0);

  for Window in GetWindows() do
    if Window.IsVisible() then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Window;
    end;
end;

function GetActiveWindow: TOSWindow;
begin
  //Result := //XGetActiveWindow(DefaultDisplay);
end;

function GetDesktopWindow: TOSWindow;
begin
  Result := kCGNullWindowID;
end;

function GetTopWindows: TOSWindowArray;

  {function IsVisible(var Window: TOSWindow): Boolean;
  var
    Windows: TOSWindowArray;
    i: Int32;
  begin
    Result := Window.IsVisible();
    if (not Result) then
    begin
      Windows := XGetChildren(DefaultDisplay, Window, False);
      for i := High(Windows) downto 0 do
      begin
        Window := Windows[i];
        if Window.IsVisible() then
          Exit(True);
      end;
    end;
  end;}
var
  Windows: TOSWindowArray;
  windowInfos: CFArrayRef;
  i: Int32;
begin
  SetLength(Result, 0);
  windowInfos := CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);



  Windows := CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);
  for i := High(Windows) downto 0 do
    if IsVisible(Windows[i]) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Windows[i];
    end;
end;
