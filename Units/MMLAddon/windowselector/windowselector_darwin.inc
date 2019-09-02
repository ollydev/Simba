{&MainUnit windowselector.pas}

uses
  cocoaall, macosall, simba.darwin_inputhelpers;

function TMWindowSelector.Drag: TOSWindow;
var
  Windows: TOSWindowArray;
  X, Y: Int32;
  WindowInfo: TWindowInfo;
  i: Int32;
begin
  Result := 0;

  //Only way that works for me atm.. not sure how to use the `Tree` search algorithm..
  Windows := GetTopWindows();

  while (IsMouseButtonDown(kCGMouseButtonLeft)) do
  begin
    GetCursorPos(X, Y);
    Result := 0;

    for i := 0 to High(Windows) do
    begin
      WindowInfo := GetWindowInfo(Windows[i]);
      if not WindowInfo.sharingState then //Invalid Windows "Usually"
        continue;

      //Search only NORMAL desktop windows..
      //Does NOT include the dock and other stuff like the start menu, etc..
      //Finder is -25, Dock is 20, Finder is Int.low, etc..
      if WindowInfo.layer <> 0 then
        continue;

      with Windows[i].GetBounds() do
      begin
        if (X > X1) and (Y > Y1) and (X < X2) and (Y < Y2) then
        begin
          Result := Windows[i];
          break;
        end;
      end;
    end;

    if Result = 0 then
      Result := GetDesktopWindow();

    with Result.GetBounds() do
      FForm.SetBounds(X1, Y1, X2-X1-1, Y2-Y1-1);
    FForm.ShowOnTop();

    Sleep(25);
    Application.ProcessMessages();
  end;

  FLastPick := Result;
  FHasPicked := True;

  FForm.Hide();
end;
