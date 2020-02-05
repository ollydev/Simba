unit simba.script_simbamethod;

{$mode objfpc}{$H+}

interface

uses
  classes, sysutils,
  simba.script_common;

type
  TSimbaMethod = object
    Script: TObject;

    Method: ESimbaMethod;
    Params: TMemoryStream;
    Result: TMemoryStream;

    procedure _DebugImage;
    procedure _DebugImageDraw;
    procedure _DebugImageDisplay;
    procedure _DebugImageClear;
    procedure _DebugImageGetImage;
    procedure _ScriptError;
    procedure _ClearDebug;
    procedure _GetPID;
    procedure _ShowBalloonHint;
    procedure _Disguise;
    procedure _Status;
  end;

implementation

uses
  graphtype, extctrls,
  simba.debugimage, simba.debugform, simba.scripttabsform, simba.mufasatypes, simba.main, simba.scripttab;

procedure TSimbaMethod._GetPID;
begin
  Result.Write(GetProcessID(), SizeOf(SizeInt));
end;

procedure TSimbaMethod._ShowBalloonHint;
var
  Title, Hint: ShortString;
  Timeout: Int32;
  Flags: TBalloonFlags;
begin
  Params.Read(Title, SizeOf(ShortString));
  Params.Read(Hint, SizeOf(ShortString));
  Params.Read(Timeout, SizeOf(Int32));
  Params.Read(Flags, SizeOf(Int32));

  SimbaForm.TrayIcon.BalloonTitle := Title;
  SimbaForm.TrayIcon.BalloonHint := Hint;
  SimbaForm.TrayIcon.BalloonTimeout := Timeout;
  SimbaForm.TrayIcon.BalloonFlags := Flags;
  SimbaForm.TrayIcon.ShowBalloonHint();
end;

procedure TSimbaMethod._Disguise;
var
  Title: ShortString;
begin
  Params.Read(Title, SizeOf(ShortString));

  SimbaForm.Caption := Title;
end;

procedure TSimbaMethod._Status;
var
  Status: ShortString;
begin
  Params.Read(Status, SizeOf(ShortString));

  SimbaScriptTabsForm.StatusPanelFileName.Caption := Status;
end;

procedure TSimbaMethod._DebugImage;
var
  Width, Height: Int32;
begin
  Params.Read(Width, SizeOf(Int32));
  Params.Read(Height, SizeOf(Int32));

  SimbaDebugImageForm.SetDimensions(Width, Height);
  SimbaDebugImageForm.ImageBox.Draw(PRGB32(Params.Memory + Params.Position), Width, Height);

  SimbaForm.ShowForm(SimbaDebugImageForm);
end;

procedure TSimbaMethod._DebugImageDraw;
var
  Width, Height: Int32;
begin
  Params.Read(Width, SizeOf(Int32));
  Params.Read(Height, SizeOf(Int32));

  SimbaDebugImageForm.ImageBox.Draw(PRGB32(Params.Memory + Params.Position), Width, Height);
end;

procedure TSimbaMethod._DebugImageDisplay;
var
  Width, Height: Int32;
begin
  Params.Read(Width, SizeOf(Int32));
  Params.Read(Height, SizeOf(Int32));

  SimbaDebugImageForm.SetDimensions(Width, Height);

  SimbaForm.ShowForm(SimbaDebugImageForm);
end;

procedure TSimbaMethod._DebugImageClear;
begin
  SimbaDebugImageForm.ImageBox.Clear();
end;

procedure TSimbaMethod._DebugImageGetImage;
begin
  SimbaDebugImageForm.ImageBox.Write(Result);
end;

procedure TSimbaMethod._ScriptError;
var
  Param: TSimbaMethod_ScriptError;
  i: Int32;
begin
  Params.Read(Param, SizeOf(TSimbaMethod_ScriptError));

  for i := 0 to SimbaScriptTabsForm.TabCount - 1 do
    if SimbaScriptTabsForm.Tabs[i].ScriptInstance = Self.Script then
    begin
      if (SimbaScriptTabsForm.Tabs[i].ScriptName = Param.FileName) or FileExists(Param.FileName) then
      begin
        if FileExists(Param.FileName) then
          SimbaScriptTabsForm.Open(Param.FileName)
        else
          SimbaScriptTabsForm.Tabs[i].MakeVisible();

        SimbaScriptTabsForm.CurrentTab.ScriptErrorLine := Param.Line;
        SimbaScriptTabsForm.CurrentEditor.CaretX := Param.Column;
        SimbaScriptTabsForm.CurrentEditor.CaretY := Param.Line;

        if SimbaScriptTabsForm.Focused and SimbaScriptTabsForm.CurrentEditor.CanSetFocus() then
          SimbaScriptTabsForm.CurrentEditor.SetFocus();
      end;
    end;
end;

procedure TSimbaMethod._ClearDebug;
begin
  SimbaDebugForm.Clear();
end;

end.
