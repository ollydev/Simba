unit script_thread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  lpparser, lpcompiler, lptypes, lpvartypes, lpffiwrappers, lpmessages, lpinterpreter, lpffi, LPDump,
  Client, Settings, SettingsSandbox, Files;

type
  PErrorData = ^TErrorData;
  TErrorData = record
    Line, Col: Int32;
    Error: String;
    FilePath: String;
  end;

  EMMLScriptOptions = set of (soCompileOnly, soWriteTimeStamp);
  EMMLScriptState = (ssRun, ssPause, ssStop);

  PMMLScriptThread = ^TMMLScriptThread;
  TMMLScriptThread = class(TThread)
  protected
    FCompiler: TLPCompiler;
    FOutputBuffer: String;
    FOutput: TStrings;
    FRunning: TInitBool;
    FStartTime: UInt64;
    FClient: TClient;
    FOptions: EMMLScriptOptions;
    FSettings: TMMLSettingsSandbox;

    procedure SetState(Value: EMMLScriptState);

    procedure Flush;

    procedure HandleException(e: Exception);

    function OnFindFile(Sender: TLapeCompiler; var FileName: lpString): TLapeTokenizerBase;
    function OnHandleDirective(Sender: TLapeCompiler; Directive, Argument: lpString; InPeek, InIgnore: Boolean): Boolean;

    function Import: Boolean;
    function Compile: Boolean;

    procedure Execute; override;
  public
    Error: record Data: PErrorData; Callback: procedure of object; end; // set by framescript
    AppPath, DocPath, ScriptPath, ScriptFile, IncludePath, PluginPath, FontPath: String; // set by TSimbaForm.InitializeTMThread

    procedure Write(constref S: String);
    procedure WriteLn; overload;
    procedure WriteLn(constref S: String); overload;

    property Options: EMMLScriptOptions read FOptions write FOptions;
    property Output: TStrings read FOutput write FOutput;
    property State: EMMLScriptState write SetState;
    property Client: TClient read FClient;
    property Settings: TMMLSettingsSandbox read FSettings;
    property StartTime: UInt64 read FStartTime;

    constructor Create(constref Script: String; ASettings: TMMLSettings);
    destructor Destroy; override;
  end;

implementation

uses
  script_imports;

procedure TMMLScriptThread.SetState(Value: EMMLScriptState);
begin
  case Value of
    ssRun: FRunning := bTrue;
    ssStop: FRunning := bFalse;
    ssPause: FRunning := bUnknown;
  end;
end;

procedure TMMLScriptThread.Flush;
begin
  if (FOutput <> nil) then
    FOutput.Add(FOutputBuffer);

  FOutputBuffer := '';
end;

procedure TMMLScriptThread.HandleException(e: Exception);
begin
  if (Error.Callback <> nil) and (Error.Data <> nil) then
  begin
    Self.Error.Data^ := Default(TErrorData);

    if (e is lpException) then
    begin
      with (e as lpException) do
      begin
        Self.Error.Data^.Line := DocPos.Line;
        Self.Error.Data^.Col := DocPos.Col;
        Self.Error.Data^.FilePath := DocPos.FileName;
        Self.Error.Data^.Error := Message;
      end;
    end else
      Self.Error.Data^.Error := e.ClassName + ' :: ' + e.Message;

    Synchronize(Error.Callback);
  end;
end;

function TMMLScriptThread.OnFindFile(Sender: TLapeCompiler; var FileName: lpString): TLapeTokenizerBase;
begin
  Result := nil;
  if (not FindFile(FileName, [IncludeTrailingPathDelimiter(ExtractFileDir(Sender.Tokenizer.FileName)), IncludePath, ScriptPath])) then
    FileName := '';
end;

function TMMLScriptThread.OnHandleDirective(Sender: TLapeCompiler; Directive, Argument: lpString; InPeek, InIgnore: Boolean): Boolean;
begin
  case LowerCase(Directive) of
    'loadlib':
      begin
        if InPeek or InIgnore then
          Exit(True);
      end;

    'findlib':
      begin
        if InPeek or InIgnore then
          Exit(True);
      end;
  end;

  Exit(False);
end;

function TMMLScriptThread.Import: Boolean;
var
  i: Int32;
begin
  Result := False;

  FCompiler.StartImporting();

  try
    for i := 0 to ScriptImports.Count - 1 do
      ScriptImports.Import(ScriptImports.Keys[i], FCompiler, Self);

    Result := True;
  except
    on e: Exception do
      HandleException(e);
  end;

  FCompiler.EndImporting();
end;

function TMMLScriptThread.Compile: Boolean;
var
  T: UInt64;
begin
  Result := False;

  try
    T := GetTickCount64();

    if FCompiler.Compile() then
    begin
      Self.Write('Compiled succesfully in ' + IntToStr(GetTickCount64() - T) + ' ms.');
      Self.WriteLn();

      Result := True;
    end;
  except
    on e: Exception do
      HandleException(e);
  end;
end;

procedure TMMLScriptThread.Execute;
begin
  FRunning := bTrue;

  try
    if Self.Import() and Self.Compile() then
    begin
      if (soCompileOnly in FOptions) then
        Exit;

      FStartTime := GetTickCount64();

      try
        RunCode(FCompiler.Emitter.Code, FRunning);
        RunCode(FCompiler.Emitter.Code, nil, TCodePos(FCompiler.getGlobalVar('__OnTerminate').Ptr^));
      except
        on e: Exception do
          HandleException(e);
      end;

      if (GetTickCount64() - FStartTime <= 60000) then
        WriteLn('Succesfully executed in ' + IntToStr(GetTickCount64() - FStartTime) + ' ms.')
      else
        WriteLn('Succesfully executed in ' + TimeToStr(TimeStampToDateTime(MSecsToTimeStamp(GetTickCount64() - FStartTime))) + '.');
    end;
  finally
    Terminate();
  end;
end;

constructor TMMLScriptThread.Create(constref Script: String; ASettings: TMMLSettings);
begin
  inherited Create(True);

  FreeOnTerminate := True;

  FCompiler := TLPCompiler.Create(TLapeTokenizerString.Create(Script));
  FCompiler.OnFindFile := @OnFindFile;
  FCompiler.OnHandleDirective := @OnHandleDirective;
  FCompiler['Move'].Name := 'MemMove';

  FClient := TClient.Create();
  FClient.WriteLnProc := @Self.WriteLn;

  FSettings := TMMLSettingsSandbox.Create(ASettings);
  FSettings.Prefix := 'Scripts/';

  FOutput := nil;
  FOutputBuffer := '';
end;

destructor TMMLScriptThread.Destroy;
begin
  inherited Destroy();

  FSettings.Free();
  FClient.Free();
  FCompiler.Free();
end;

procedure TMMLScriptThread.Write(constref S: String);
begin
  FOutputBuffer := FOutputBuffer + S;
end;

procedure TMMLScriptThread.WriteLn;
begin
  if (soWriteTimeStamp in FOptions) then
    FOutputBuffer := '[' + TimeToStr(TimeStampToDateTime(MSecsToTimeStamp(GetTickCount64() - FStartTime))) + ']: ' + FOutputBuffer;

  Synchronize(@Flush);
end;

procedure TMMLScriptThread.WriteLn(constref S: String);
begin
  Write(S);
  WriteLn();
end;

end.
