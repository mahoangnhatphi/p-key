unit vietnamese_chars;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

type
  { kind maps 1:1 to row index in Rows }
  TVowelKind = (vkA=0, vkABreve, vkACirc,
                vkE,   vkECirc,
                vkI,
                vkO,   vkOCirc, vkOHorn,
                vkU,   vkUHorn,
                vkY,
                vkD);

  TShape = (shNone=0, shCirc, shBreve, shHorn, shBar);
  TTone  = 0..5;  { 0=ko,1=sac,2=huyen,3=hoi,4=nga,5=nang }

  TVietChar = record
    Kind: TVowelKind;
    Tone: TTone;
    Upper: Boolean;
  end;

function ComposeChar(k: TVowelKind; tone: TTone; upper: Boolean): WideChar;
function DecomposeChar(c: WideChar; out v: TVietChar): Boolean;
function BaseOf(k: TVowelKind): WideChar;     { lowercase base letter }
function ShapeOf(k: TVowelKind): TShape;
function IsVowelKind(k: TVowelKind): Boolean; { khong tinh d/d }
function ShapeApplies(base: WideChar; sh: TShape): Boolean;
function KindForShape(base: WideChar; sh: TShape): Integer; { -1 neu vo nghia }
function BaseKind(base: WideChar): Integer;                  { base khong dau hinh, -1 neu ko phai nguyen am }
function ToneFromKey(key: WideChar): TTone;    { '1'..'5', else 0 }
function ShapeFromKey(key: WideChar): TShape;  { '6'->circ ... '9'->bar; ko thi shNone }

implementation

type
  TRow = record
    L, U: array[0..5] of WideChar;
  end;

const
  Rows: array[0..12] of TRow = (
    (L:('a','á','à','ả','ã','ạ'); U:('A','Á','À','Ả','Ã','Ạ')),
    (L:('ă','ắ','ằ','ẳ','ẵ','ặ'); U:('Ă','Ắ','Ằ','Ẳ','Ẵ','Ặ')),
    (L:('â','ấ','ầ','ẩ','ẫ','ậ'); U:('Â','Ấ','Ầ','Ẩ','Ẫ','Ậ')),
    (L:('e','é','è','ẻ','ẽ','ẹ'); U:('E','É','È','Ẻ','Ẽ','Ẹ')),
    (L:('ê','ế','ề','ể','ễ','ệ'); U:('Ê','Ế','Ề','Ể','Ễ','Ệ')),
    (L:('i','í','ì','ỉ','ĩ','ị'); U:('I','Í','Ì','Ỉ','Ĩ','Ị')),
    (L:('o','ó','ò','ỏ','õ','ọ'); U:('O','Ó','Ò','Ỏ','Õ','Ọ')),
    (L:('ô','ố','ồ','ổ','ỗ','ộ'); U:('Ô','Ố','Ồ','Ổ','Ỗ','Ộ')),
    (L:('ơ','ớ','ờ','ở','ỡ','ợ'); U:('Ơ','Ớ','Ờ','Ở','Ỡ','Ợ')),
    (L:('u','ú','ù','ủ','ũ','ụ'); U:('U','Ú','Ù','Ủ','Ũ','Ụ')),
    (L:('ư','ứ','ừ','ử','ữ','ự'); U:('Ư','Ứ','Ừ','Ử','Ữ','Ự')),
    (L:('y','ý','ỳ','ỷ','ỹ','ỵ'); U:('Y','Ý','Ỳ','Ỷ','Ỹ','Ỵ')),
    (L:('đ',#0,#0,#0,#0,#0);       U:('Đ',#0,#0,#0,#0,#0))
  );

function ComposeChar(k: TVowelKind; tone: TTone; upper: Boolean): WideChar;
var
  r: TRow;
begin
  r := Rows[ord(k)];
  if upper then
    Result := r.U[tone]
  else
    Result := r.L[tone];
end;

function DecomposeChar(c: WideChar; out v: TVietChar): Boolean;
var
  i, t: Integer;
  r: TRow;
begin
  Result := False;
  for i := 0 to 12 do
  begin
    r := Rows[i];
    for t := 0 to 5 do
    begin
      if r.U[t] = c then
      begin
        v.Kind := TVowelKind(i);
        v.Tone := t;
        v.Upper := True;
        Exit(True);
      end;
      if r.L[t] = c then
      begin
        v.Kind := TVowelKind(i);
        v.Tone := t;
        v.Upper := False;
        Exit(True);
      end;
    end;
  end;
end;

function BaseOf(k: TVowelKind): WideChar;
begin
  case k of
    vkA, vkABreve, vkACirc: Result := 'a';
    vkE, vkECirc:       Result := 'e';
    vkI:                Result := 'i';
    vkO, vkOCirc, vkOHorn: Result := 'o';
    vkU, vkUHorn:       Result := 'u';
    vkY:                Result := 'y';
    vkD:                Result := 'd';
    else                Result := #0;
  end;
end;

function ShapeOf(k: TVowelKind): TShape;
begin
  case k of
    vkABreve: Result := shBreve;
    vkACirc:  Result := shCirc;
    vkECirc:  Result := shCirc;
    vkOCirc:  Result := shCirc;
    vkOHorn:  Result := shHorn;
    vkUHorn:  Result := shHorn;
    vkD:      Result := shBar;
    else      Result := shNone;
  end;
end;

function IsVowelKind(k: TVowelKind): Boolean;
begin
  Result := (ord(k) >= ord(vkA)) and (ord(k) <= ord(vkY)); { bo vkD }
end;

function ShapeApplies(base: WideChar; sh: TShape): Boolean;
begin
  case sh of
    shCirc:  Result := (base = 'a') or (base = 'e') or (base = 'o');
    shBreve: Result := (base = 'a');
    shHorn:  Result := (base = 'o') or (base = 'u');
    shBar:   Result := (base = 'd');
    else     Result := False;
  end;
end;

function KindForShape(base: WideChar; sh: TShape): Integer;
begin
  if not ShapeApplies(base, sh) then
    Exit(-1);
  case sh of
    shCirc:  case base of 'a': Exit(ord(vkACirc)); 'e': Exit(ord(vkECirc)); 'o': Exit(ord(vkOCirc)); end;
    shBreve: Exit(ord(vkABreve));
    shHorn:  case base of 'o': Exit(ord(vkOHorn)); 'u': Exit(ord(vkUHorn)); end;
    shBar:   Exit(ord(vkD));
  end;
  Result := -1;
end;

function ToneFromKey(key: WideChar): TTone;
begin
  case key of
    '1': Result := 1;
    '2': Result := 2;
    '3': Result := 3;
    '4': Result := 4;
    '5': Result := 5;
    else Result := 0;
  end;
end;

{ kind ung voi base letter khong co dau hinh; -1 neu khong phai nguyen am }
function BaseKind(base: WideChar): Integer;
begin
  case base of
    'a': Result := ord(vkA);
    'e': Result := ord(vkE);
    'i': Result := ord(vkI);
    'o': Result := ord(vkO);
    'u': Result := ord(vkU);
    'y': Result := ord(vkY);
    else Result := -1;
  end;
end;

function ShapeFromKey(key: WideChar): TShape;
begin
  case key of
    '6': Result := shCirc;
    '7': Result := shHorn;
    '8': Result := shBreve;
    '9': Result := shBar;
    else Result := shNone;
  end;
end;

end.
