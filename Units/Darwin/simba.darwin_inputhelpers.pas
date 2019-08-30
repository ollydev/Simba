unit simba.darwin_inputhelpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function VirtualKeyCodeToMac(AKey: Word): Word;
function VirtualKeyCodeToCharCode(AKey: Word): Word;

implementation

uses
  LCLType;

function VirtualKeyCodeToMac(AKey: Word): Word;
begin
  case AKey of
  VK_BACK      : Result := $33;
  VK_TAB       : Result := $30;
  VK_RETURN    : Result := $24;
  VK_PAUSE     : Result := $71;
  VK_CAPITAL   : Result := $39;
  VK_ESCAPE    : Result := $35;
  VK_SPACE     : Result := $31;
  VK_PRIOR     : Result := $74;
  VK_NEXT      : Result := $79;
  VK_END       : Result := $77;
  VK_HOME      : Result := $73;
  VK_LEFT      : Result := $7B;
  VK_UP        : Result := $7E;
  VK_RIGHT     : Result := $7C;
  VK_DOWN      : Result := $7D;
  VK_SNAPSHOT  : Result := $69;
  VK_INSERT    : Result := $72;
  VK_DELETE    : Result := $75;
  VK_HELP      : Result := $72;
  VK_SLEEP     : Result := $7F7F;
  VK_NUMPAD0   : Result := $52;
  VK_NUMPAD1   : Result := $53;
  VK_NUMPAD2   : Result := $54;
  VK_NUMPAD3   : Result := $55;
  VK_NUMPAD4   : Result := $56;
  VK_NUMPAD5   : Result := $57;
  VK_NUMPAD6   : Result := $58;
  VK_NUMPAD7   : Result := $59;
  VK_NUMPAD8   : Result := $5b;
  VK_NUMPAD9   : Result := $5c;
  //VK_MULTIPLY  : Result := $43;
  //VK_ADD       : Result := $45;
  VK_SEPARATOR : Result := $41;
  VK_SUBTRACT  : Result := $4E;
  VK_DECIMAL   : Result := $41;
  VK_DIVIDE    : Result := $4B;
  VK_F1        : Result := $7A;
  VK_F2        : Result := $78;
  VK_F3        : Result := $63;
  VK_F4        : Result := $76;
  VK_F5        : Result := $60;
  VK_F6        : Result := $61;
  VK_F7        : Result := $62;
  VK_F8        : Result := $64;
  VK_F9        : Result := $65;
  VK_F10       : Result := $6D;
  VK_F11       : Result := $67;
  VK_F12       : Result := $6F;
  VK_F13       : Result := $69;
  VK_F14       : Result := $6B;
  VK_F15       : Result := $71;
  VK_F16       : Result := $6A;
  VK_F17       : Result := $40;
  VK_F18       : Result := $4F;
  VK_F19       : Result := $50;
  VK_NUMLOCK   : Result := $47;
  VK_CLEAR     : Result := $47;
  VK_SCROLL    : Result := $6B;
  VK_SHIFT     : Result := $38;
  VK_CONTROL   : Result := $37;
  VK_MENU      : Result := $3A;
  VK_OEM_3     : Result := 50;
  //VK_OEM_MINUS : Result := 27;
  VK_OEM_PLUS  : Result := 24;
  VK_OEM_5     : Result := 42;
  VK_OEM_4     : Result := 33;
  VK_OEM_6     : Result := 30;
  VK_OEM_1     : Result := 41;
  VK_OEM_7     : Result := 39;
  VK_OEM_COMMA : Result := 43;
  //VK_OEM_PERIOD: Result := 47;
  //VK_OEM_2     : Result := 44;
  else
    Result := 0;
  end;
end;

function VirtualKeyCodeToCharCode(AKey: Word): Word;
begin
  case AKey of
  VK_MULTIPLY  : Result := Ord('*');
  VK_ADD       : Result := Ord('+');
  VK_OEM_MINUS : Result := Ord('-');
  VK_OEM_PERIOD: Result := Ord('.');
  VK_OEM_2     : Result := Ord('/');
  else
    Result := AKey;
  end;
end;

end.

