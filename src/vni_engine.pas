unit vni_engine;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  SysUtils, vietnamese_chars, syllable_parser;

type
  { Bo go VNI: giu word buffer, bien doi khi nhan cac phim so 0-9 }
  TVNIEngine = class
  private
    FWord: UnicodeString;
    procedure SetChar(pos: Integer; c: WideChar);
    function ApplyDigit(c: WideChar): Boolean;   { true = da consume }
    function LastBaseIs(base: WideChar): Boolean;
    function RemoveTelexMark: Boolean;
  public
    constructor Create;
    procedure Reset;
    procedure TypeChar(c: WideChar);             { phep MOT ky tu (khong phai separator) }
    procedure TypeTelexChar(c: WideChar);
    procedure Backspace;
    function CurrentWord: UnicodeString;
    property Word: UnicodeString read FWord;
  end;

implementation

constructor TVNIEngine.Create;
begin
  inherited Create;
  FWord := '';
end;

procedure TVNIEngine.Reset;
begin
  FWord := '';
end;

function TVNIEngine.CurrentWord: UnicodeString;
begin
  Result := FWord;
end;

procedure TVNIEngine.SetChar(pos: Integer; c: WideChar);
var
  tmp: UnicodeString;
begin
  if (pos < 1) or (pos > Length(FWord)) then
    Exit;
  tmp := FWord;
  tmp[pos] := c;
  FWord := tmp;
end;

function TVNIEngine.ApplyDigit(c: WideChar): Boolean;
var
  v: TVietChar;
  tgt, p, i: Integer;
  nt: TTone;
  sh: TShape;
  base: WideChar;
  newKind: Integer;
  rpos: array[0..15] of Integer;
  rkind: array[0..15] of TVowelKind;
  rn: Integer;
begin
  Result := False;

  if FWord = '' then
    Exit(False);

  if c = '9' then
  begin
    p := FindD(FWord);
    if (p = 0) or ((Length(FWord) <> 1) and not IsLikelyVietnameseWord(FWord)) then
      Exit(False);
    case FWord[p] of
      'd': SetChar(p, 'đ');
      'D': SetChar(p, 'Đ');
      'đ': SetChar(p, 'd');
      'Đ': SetChar(p, 'D');
    end;
    Exit(True);
  end;

  if not IsLikelyVietnameseWord(FWord) then
    Exit(False);

  case c of
    '0':
      begin
        tgt := FindToneTarget(FWord);
        if tgt = 0 then Exit(False);
        if not DecomposeChar(FWord[tgt], v) then Exit(False);
        if v.Tone = 0 then Exit(False);
        v.Tone := 0;
        SetChar(tgt, ComposeChar(v.Kind, v.Tone, v.Upper));
        Exit(True);
      end;

    '1'..'5':
      begin
        tgt := FindToneTarget(FWord);
        if tgt = 0 then Exit(False);
        if not DecomposeChar(FWord[tgt], v) then Exit(False);
        nt := ToneFromKey(c);
        if v.Tone = nt then
          v.Tone := 0            { go 2 lan -> xoa dau }
        else
          v.Tone := nt;          { doi dau / dat dau }
        SetChar(tgt, ComposeChar(v.Kind, v.Tone, v.Upper));
        Exit(True);
      end;

    '6', '7', '8':
      begin
        sh := ShapeFromKey(c);
        RealVowels(FWord, rpos, rkind, rn);
        { chon nguyen am sau cung co the mang shape nay }
        p := -1;
        for i := rn-1 downto 0 do
        begin
          base := BaseOf(rkind[i]);
          if ShapeApplies(base, sh) then
          begin
            p := rpos[i];
            Break;
          end;
        end;
        if p = -1 then Exit(False);
        if not DecomposeChar(FWord[p], v) then Exit(False);
        if ShapeOf(v.Kind) = sh then
          newKind := BaseKind(BaseOf(v.Kind))   { toggle: xoa shape }
        else
          newKind := KindForShape(BaseOf(v.Kind), sh);
        if newKind < 0 then Exit(False);
        SetChar(p, ComposeChar(TVowelKind(newKind), v.Tone, v.Upper));
        Exit(True);
      end;

  end;
end;

procedure TVNIEngine.TypeChar(c: WideChar);
begin
  if (c >= '0') and (c <= '9') then
  begin
    if not ApplyDigit(c) then
      FWord := FWord + c;   { khong ap dung -> ky tu so thuc su }
  end
  else
    FWord := FWord + c;
end;

function TVNIEngine.LastBaseIs(base: WideChar): Boolean;
var
  v: TVietChar;
  c: WideChar;
begin
  if FWord = '' then
    Exit(False);
  c := FWord[Length(FWord)];
  if (c = base) or (c = WideChar(Ord(base) - 32)) then
    Exit(True);
  Result := DecomposeChar(c, v) and (BaseOf(v.Kind) = base);
end;

function TVNIEngine.RemoveTelexMark: Boolean;
var
  tgt, p, newKind: Integer;
  v: TVietChar;
begin
  Result := False;
  tgt := FindToneTarget(FWord);
  if (tgt <> 0) and DecomposeChar(FWord[tgt], v) then
  begin
    if v.Tone <> 0 then
    begin
      v.Tone := 0;
      SetChar(tgt, ComposeChar(v.Kind, v.Tone, v.Upper));
      Exit(True);
    end;
    if ShapeOf(v.Kind) <> shNone then
    begin
      newKind := BaseKind(BaseOf(v.Kind));
      SetChar(tgt, ComposeChar(TVowelKind(newKind), 0, v.Upper));
      Exit(True);
    end;
  end;

  p := FindD(FWord);
  if (p <> 0) and ((FWord[p] = 'đ') or (FWord[p] = 'Đ')) then
  begin
    if FWord[p] = 'đ' then
      SetChar(p, 'd')
    else
      SetChar(p, 'D');
    Exit(True);
  end;
end;

procedure TVNIEngine.TypeTelexChar(c: WideChar);
var
  key: WideChar;
  handled: Boolean;
begin
  key := c;
  if (key >= 'A') and (key <= 'Z') then
    key := WideChar(Ord(key) + 32);
  handled := False;
  case key of
    's': handled := ApplyDigit('1');
    'f': handled := ApplyDigit('2');
    'r': handled := ApplyDigit('3');
    'x': handled := ApplyDigit('4');
    'j': handled := ApplyDigit('5');
    'z': handled := RemoveTelexMark;
    'a': if LastBaseIs('a') then handled := ApplyDigit('6');
    'e': if LastBaseIs('e') then handled := ApplyDigit('6');
    'o': if LastBaseIs('o') then handled := ApplyDigit('6');
    'w':
      if LastBaseIs('a') then
        handled := ApplyDigit('8')
      else if LastBaseIs('o') or LastBaseIs('u') then
        handled := ApplyDigit('7');
    'd': if LastBaseIs('d') then handled := ApplyDigit('9');
  end;
  if not handled then
    FWord := FWord + c;
end;

procedure TVNIEngine.Backspace;
begin
  if FWord <> '' then
    Delete(FWord, Length(FWord), 1);
end;

end.
