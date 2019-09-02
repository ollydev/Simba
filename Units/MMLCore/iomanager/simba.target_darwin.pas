{$mode objfpc}{$H+}
{$modeswitch objectivec2}

unit simba.target_darwin;

interface

uses
  classes, sysutils,
  cocoaall, macosall, lcltype, simba.target, simba.oswindow, mufasatypes;

type
  TWindowTarget = class(TTarget)
  protected
    FWindow: TOSWindow;
    FAutoFocus: Boolean;
    FData: Pointer;

    function GetHandle: PtrUInt; override;
    procedure SetHandle(Value: PtrUInt); override;

    function GetAutoFocus: Boolean; override;
    procedure SetAutoFocus(Value: Boolean); override;

    procedure GetTargetBounds(out Bounds: TBox); override;
  public
    function CopyData(X, Y, Width, Height: Int32): PRGB32; override;
    function ReturnData(X, Y, Width, Height: Int32): TRetData; override;
    procedure FreeReturnData; override;

    function TargetValid: Boolean; override;

    procedure ActivateClient; override;
    procedure GetMousePosition(out X, Y: Int32); override;
    procedure ScrollMouse(X, Y: Int32; Lines: Int32); override;
    procedure MoveMouse(X, Y: Int32); override;
    procedure HoldMouse(X, Y: Int32; Button: TClickType); override;
    procedure ReleaseMouse(X, Y: Int32; Button: TClickType); override;
    function IsMouseButtonHeld(Button: TClickType): Boolean;override;

    procedure SendString(Text: String; KeyWait, KeyModWait: Int32); override;
    procedure HoldKey(Key: Int32); override;
    procedure ReleaseKey(Key: Int32); override;
    function IsKeyHeld(Key: Int32): Boolean; override;
    function GetKeyCode(Character: Char): Int32; override;

    constructor Create(Target: TOSWindow);
    destructor Destroy; override;
  end;

implementation

uses
  simba.darwin_inputhelpers;

procedure SendKeyInput(Key: Word; Down: Boolean);
var
  Char: Word;
begin
  Char := 0;
  if Key in [VK_A .. VK_Z] then
  begin
    Char := Ord('A') + Key - VK_A;
  end;

  if Key in [VK_0 .. VK_9] then
  begin
    Char := Ord('0') + Key - VK_0;
  end;

  CGPostKeyboardEvent(Char, VirtualKeyCodeToMac(Key), boolean_t(Down));
end;

function TWindowTarget.GetHandle: PtrUInt;
begin
  Result := FWindow;
end;

procedure TWindowTarget.SetHandle(Value: PtrUInt);
begin
  FWindow := Value;
end;

function TWindowTarget.GetAutoFocus: Boolean;
begin
  Result := FAutoFocus;
end;

procedure TWindowTarget.SetAutoFocus(Value: Boolean);
begin
  FAutoFocus := Value;
end;

procedure TWindowTarget.GetTargetBounds(out Bounds: TBox);
var
  Attempts: Int32;
begin
  for Attempts := 1 to 5 do
  begin
    if FWindow.GetBounds(Bounds) then
      Exit;

    Self.InvalidTarget();
  end;

  raise Exception.CreateFmt('Invalid window handle: %d', [FWindow]);
end;

constructor TWindowTarget.Create(Target: TOSWindow);
begin
  inherited Create();

  Handle := Target;
end;

destructor TWindowTarget.Destroy;
begin
  inherited Destroy();
end;

function TWindowTarget.TargetValid: Boolean;
var
  windowIds, windows: CFArrayRef;
begin
  windowIds := CFArrayCreateMutable(nil, 1, nil);
  CFArrayAppendValue(windowIds, UnivPtr(FWindow));
  windows := CGWindowListCreateDescriptionFromArray(windowIds);
  CFRelease(windowIds);
  Result := CFArrayGetCount(windows) <> 0;
  CFRelease(windows);
end;

procedure TWindowTarget.ActivateClient;
begin
  FWindow.Activate();
end;

function TWindowTarget.CopyData(X, Y, Width, Height: Int32): PRGB32;
var
  Bounds: TBox;
  Image: CGImageRef;
  Rect: CGRect;
  ColorSpace: CGColorSpaceRef;
  Context: CGContextRef;
begin
  Result := nil;

  if FAutoFocus then
    ActivateClient();

  GetTargetBounds(Bounds);

  ImageClientAreaOffset(X, Y);

  if Bounds.Contains(Bounds.X1 + X, Bounds.Y1 + Y, Width, Height) then
  begin
    Rect := CGRectMake(x, y, width, height);
    Image := CGWindowListCreateImage(rect, kCGWindowListOptionIncludingWindow, FWindow, kCGWindowImageBoundsIgnoreFraming);

    Result := GetMem(Width * Height * SizeOf(TRGB32));
    FillByte(Result^, Width * Height * SizeOf(TRGB32), $0);
    ColorSpace := CGColorSpaceCreateDeviceRGB();
    Context := CGBitmapContextCreate(Result, width, height, 8, Width * SizeOf(TRGB32), ColorSpace, kCGImageAlphaPremultipliedFirst or kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(ColorSpace);
    CGContextDrawImage(Context, rect, Image);
    CGImageRelease(Image);
    CGContextRelease(Context);
  end;
end;

function TWindowTarget.ReturnData(X, Y, Width, Height: Int32): TRetData;
var
  Bounds: TBox;
  Image: CGImageRef;
  Rect: CGRect;
  ColorSpace: CGColorSpaceRef;
  Context: CGContextRef;
begin
  Result := NullReturnData;

  if FAutoFocus then
    ActivateClient();

  GetTargetBounds(Bounds);

  ImageClientAreaOffset(X, Y);

  if Bounds.Contains(Bounds.X1 + X, Bounds.Y1 + Y, Width, Height) then
  begin
    if (FData <> nil) then
      raise Exception.Create('FreeReturnData has not been called');

    Rect := CGRectMake(x, y, width, height);
    Image := CGWindowListCreateImage(rect, kCGWindowListOptionIncludingWindow, FWindow, kCGWindowImageBoundsIgnoreFraming);

    FData := GetMem(width * height * SizeOf(TRGB32));
    FillByte(FData^, Width * Height * SizeOf(TRGB32), $0);
    ColorSpace := CGColorSpaceCreateDeviceRGB();
    Context := CGBitmapContextCreate(FData, width, height, 8, Width * SizeOf(TRGB32), ColorSpace, kCGImageAlphaPremultipliedFirst or kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(ColorSpace);
    CGContextDrawImage(Context, rect, Image);
    CGImageRelease(Image);
    CGContextRelease(Context);

    Result.Ptr := PRGB32(FData);
    Result.IncPtrWith := 0;
    Result.RowLen := Width;
  end;
end;

procedure TWindowTarget.FreeReturnData;
begin
  if (FData <> nil) then
  begin
    FreeMem(Self.FData);
    FData := nil;
  end;
end;

procedure TWindowTarget.GetMousePosition(out X, Y: Int32);
var
  event: CGEventRef;
  point: CGPoint;
begin
  event := CGEventCreate(nil);
  point := CGEventGetLocation(event);
  CFRelease(event);

  X := round(point.x);
  Y := round(point.y);
  MouseClientAreaOffset(X, Y);
end;

procedure TWindowTarget.ScrollMouse(X, Y: Int32; Lines: Int32);
var
   ScrollEvent: CGEventRef;
begin
  if FAutoFocus then
    ActivateClient();

  MouseClientAreaOffset(X, Y);

  ScrollEvent := CGEventCreateScrollWheelEvent(nil, kCGScrollEventUnitPixel, 1, lines * 10);
  CGEventPost(kCGHIDEventTap, scrollEvent);
  CFRelease(scrollEvent);
end;

procedure TWindowTarget.MoveMouse(X, Y: Int32);
var
  event: CGEventRef;
begin
  if FAutoFocus then
    ActivateClient();

  MouseClientAreaOffset(X, Y);

  event := CGEventCreateMouseEvent(nil, {kCGEventMouseMoved} 5, CGPointMake(x, y), 0); //CGWarpCursorPos
  CGEventPost(kCGSessionEventTap, event);
  CFRelease(event);
end;

procedure TWindowTarget.HoldMouse(X, Y: Int32; Button: TClickType);
var
  event: CGEventRef;
  eventType, mouseButton: LongInt;
begin
  if FAutoFocus then
    ActivateClient();

  case button of
    mouse_Left:
      begin
        eventType := 1 {kCGEventLeftMouseDown};
        mouseButton := kCGMouseButtonLeft;
      end;
    mouse_Middle:
      begin
        eventType := 25 {kCGEventOtherMouseDown};
        mouseButton := kCGMouseButtonCenter;
      end;
    mouse_Right:
      begin
        eventType := 3 {kCGEventRightMouseDown};
        mouseButton := kCGMouseButtonRight;
      end;
  end;

  event := CGEventCreateMouseEvent(nil, eventType, CGPointMake(x, y), mouseButton);
  CGEventPost(kCGSessionEventTap, event);
  CFRelease(event);
end;

procedure TWindowTarget.ReleaseMouse(X, Y: Int32; Button: TClickType);
var
  event: CGEventRef;
  eventType, mouseButton: LongInt;
begin
  if FAutoFocus then
    ActivateClient();

  case button of
    mouse_Left:
      begin
        eventType := 2 {kCGEventLeftMouseUp};
        mouseButton := kCGMouseButtonLeft;
      end;
    mouse_Middle:
      begin
        eventType := 26 {kCGEventOtherMouseUp};
        mouseButton := kCGMouseButtonCenter;
      end;
    mouse_Right:
      begin
        eventType := 4 {kCGEventRightMouseUp};
        mouseButton := kCGMouseButtonRight;
      end;
  end;

  event := CGEventCreateMouseEvent(nil, eventType, CGPointMake(x, y), mouseButton);
  CGEventPost(kCGSessionEventTap, event);
  CFRelease(event);
end;

function TWindowTarget.IsMouseButtonHeld(Button: TClickType): Boolean;
var
  mouseButton: UInt32;
  buttonStateResult: CBool;
begin
  case button of
    mouse_Left:   mouseButton := kCGMouseButtonLeft;
    mouse_Middle: mouseButton := kCGMouseButtonCenter;
    mouse_Right:  mouseButton := kCGMouseButtonRight;
  else
    Result := False;
  end;

  buttonStateResult := CGEventSourceButtonState(kCGEventSourceStateCombinedSessionState, mouseButton);
  Result := buttonStateResult > 0;
end;

procedure TWindowTarget.SendString(Text: String; KeyWait, KeyModWait: Int32);
var
   I, L: Integer;
   K: Byte;
   HoldShift: Boolean;
begin
  if FAutoFocus then
    ActivateClient();

  HoldShift := False;
  L := Length(Text);
  for I := 1 to L do
  begin
    if (((Text[I] >= 'A') and (Text[I] <= 'Z')) or
        ((Text[I] >= '!') and (Text[I] <= '&')) or
        ((Text[I] >= '(') and (Text[I] <= '+')) or
        (Text[I] = ':') or
        ((Text[I] >= '<') and (Text[I] <= '@')) or
        ((Text[I] >= '^') and (Text[I] <= '_')) or
        ((Text[I] >= '{') and (Text[I] <= '~'))) then
    begin
      HoldKey(VK_SHIFT);
      HoldShift := True;
      sleep(keymodwait shr 1);
    end;

    K := GetKeyCode(Text[I]);
    HoldKey(K);

    if keywait <> 0 then
      Sleep(keywait);

    ReleaseKey(K);

    if (HoldShift) then
    begin
      HoldShift := False;
      sleep(keymodwait shr 1);
      ReleaseKey(VK_SHIFT);
    end;
  end;
end;

procedure TWindowTarget.HoldKey(Key: Int32);
begin
  if FAutoFocus then
    ActivateClient();

  SendKeyInput(key, True);
end;

procedure TWindowTarget.ReleaseKey(Key: Int32);
begin
  if FAutoFocus then
    ActivateClient();

  SendKeyInput(key, False);
end;

function TWindowTarget.IsKeyHeld(Key: Int32): Boolean;
begin
  Result := Boolean(CGEventSourceKeyState(kCGEventSourceStateCombinedSessionState, VirtualKeyCodeToMac(key)));
end;

function TWindowTarget.GetKeyCode(Character: Char): Int32;
begin
  case Character of
    '0'..'9': Result := VK_0 + Ord(Character) - Ord('0');
    'a'..'z': Result := VK_A + Ord(Character) - Ord('a');
    'A'..'Z': Result := VK_A + Ord(Character) - Ord('A');
    ' ': Result := VK_SPACE;
  else
    Raise Exception.CreateFMT('GetKeyCode - char (%s) is not in A..z',[Character]);
  end
end;

end.
