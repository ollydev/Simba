{
	This file is part of the Mufasa Macro Library (MML)
	Copyright (c) 2009-2012 by Raymond van Venetië and Merlijn Wajer

    MML is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    MML is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with MML.  If not, see <http://www.gnu.org/licenses/>.

	See the file COPYING, included in this distribution,
	for details about the copyright.

    about form for the Mufasa Macro Library
}

unit about;

{$mode objfpc}{$H+}
{$MACRO ON}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    AboutMemo: TMemo;
    ButtonClose: TButton;
    ImageSimba: TImage;
    LabelTitle: TLabel;
    LabelRevision: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  AboutForm: TAboutForm;

implementation
uses
  mufasabase,
  SimbaUnit,
  resource, versiontypes, versionresource;
{ TAboutForm }

function getVersion(out Major, Minor, Revision, Build: Integer): Boolean;
var
  Stream: TResourceStream;
  Version: TVersionResource;
begin
  Result := False;
  try
    Stream := TResourceStream.CreateFromID(HINSTANCE, 1, PChar(RT_VERSION));
    try
      Version := TVersionResource.Create();
      try
        Version.SetCustomRawDataStream(Stream);
        with Version.FixedInfo do
        begin
          Major := FileVersion[0];
          Minor := FileVersion[1];
          Revision := FileVersion[2];
          Build := FileVersion[3];
        end;

        Result := True;
      finally
        Version.SetCustomRawDataStream(nil);
        Version.Free;
      end;
    finally
      Stream.Free;
    end;
  except end;
end;

procedure TAboutForm.FormCreate(Sender: TObject);
var
  Major, Minor, Revision, Build: Integer;
begin
  Self.Caption := format('About Simba r%d', [SimbaVersion]);
  Self.LabelRevision.Caption := format('Revision %d', [SimbaVersion]);
  AboutMemo.Lines.Add('Simba is released under the GPL license.');
  if (getVersion(Major, Minor, Revision, Build)) then
    AboutMemo.Lines.Add(Format('You are using Simba version %d.%d.%d (Build %d).', [Major, Minor, Revision, Build]))
  else
    AboutMemo.Lines.Add('You are using an unknown version of Simba.');
  AboutMemo.Lines.Add(format('Compiled with FPC version %d.%d.%d', [FPC_VERSION,
      FPC_RELEASE, FPC_PATCH]));
  AboutMemo.Lines.Add('');
  AboutMemo.Lines.Add('Please report bugs at: http://bugs.villavu.com/');
  AboutMemo.ReadOnly:= True;
end;

procedure TAboutForm.OkButtonClick(Sender: TObject);
begin
  Self.ModalResult:=mrOK;
  Self.Hide;
end;

initialization
  {$R *.lfm}

end.

