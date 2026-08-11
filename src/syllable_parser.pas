unit syllable_parser;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  vietnamese_chars, SysUtils;

{ vi tri (1-based) cua nguyen am nhan tone; 0 neu ko co }
function FindToneTarget(const w: UnicodeString): Integer;
{ vi tri cuoi cung cua chu d/D neu co, else 0 }
function FindD(const w: UnicodeString): Integer;
{ cac nguyen am that (bo u trong 'qu', i quasi trong 'gi') }
procedure RealVowels(const w: UnicodeString; out pos: array of Integer;
  out kinds: array of TVowelKind; out n: Integer);
{ nguyen am cua word: mang positions va kinds }
procedure CollectVowels(const w: UnicodeString; out pos: array of Integer;
  out kinds: array of TVowelKind; out n: Integer);
{ A small guard against rewriting ordinary non-Vietnamese words. }
function IsLikelyVietnameseWord(const w: UnicodeString): Boolean;

implementation

function LowerBase(c: WideChar): WideChar;
var
  v: TVietChar;
begin
  if DecomposeChar(c, v) then
    Exit(BaseOf(v.Kind));
  if (c >= 'A') and (c <= 'Z') then
    Exit(WideChar(Ord(c) + 32));
  Result := c;
end;

function IsValidOnset(const s: UnicodeString): Boolean;
begin
  Result := (s = '') or (s = 'b') or (s = 'c') or (s = 'ch') or
    (s = 'd') or (s = 'g') or (s = 'gh') or (s = 'gi') or (s = 'h') or
    (s = 'k') or (s = 'kh') or (s = 'l') or (s = 'm') or (s = 'n') or
    (s = 'ng') or (s = 'ngh') or (s = 'nh') or (s = 'p') or (s = 'ph') or
    (s = 'q') or (s = 'qu') or (s = 'r') or (s = 's') or (s = 't') or
    (s = 'th') or (s = 'tr') or (s = 'v') or (s = 'x');
end;

function IsValidCoda(const s: UnicodeString): Boolean;
begin
  Result := (s = '') or (s = 'c') or (s = 'ch') or (s = 'm') or
    (s = 'n') or (s = 'ng') or (s = 'nh') or (s = 'p') or (s = 't');
end;

function IsLikelyVietnameseWord(const w: UnicodeString): Boolean;
var
  pos: array[0..15] of Integer;
  kinds: array[0..15] of TVowelKind;
  n, i: Integer;
  onset, coda: UnicodeString;
begin
  RealVowels(w, pos, kinds, n);
  if n = 0 then
    Exit(False);

  { A Vietnamese syllable has one contiguous vowel cluster. }
  for i := 1 to n - 1 do
    if pos[i] <> pos[i - 1] + 1 then
      Exit(False);

  onset := '';
  for i := 1 to pos[0] - 1 do
    onset := onset + LowerBase(w[i]);
  coda := '';
  for i := pos[n - 1] + 1 to Length(w) do
    coda := coda + LowerBase(w[i]);
  Result := IsValidOnset(onset) and IsValidCoda(coda);
end;

procedure CollectVowels(const w: UnicodeString; out pos: array of Integer;
  out kinds: array of TVowelKind; out n: Integer);
var
  i: Integer;
  v: TVietChar;
begin
  n := 0;
  for i := 1 to Length(w) do
  begin
    if not DecomposeChar(w[i], v) then
      Continue;
    if not IsVowelKind(v.Kind) then
      Continue;
    if n < Length(pos) then
    begin
      pos[n] := i;
      kinds[n] := v.Kind;
    end;
    Inc(n);
  end;
end;

function FindToneTarget(const w: UnicodeString): Integer;
var
  pos: array[0..15] of Integer;
  kinds: array[0..15] of TVowelKind;
  n, i, j, firstMarked: Integer;
  seq: string;
  firstList: Boolean;
  v: TVietChar;
  kk: TVowelKind;
  nfoll: Boolean;
begin
  Result := 0;
  if Length(w) = 0 then
    Exit;

  n := 0;
  for i := 1 to Length(w) do
  begin
    if not DecomposeChar(w[i], v) then Continue;
    if not IsVowelKind(v.Kind) then Continue;
    kk := v.Kind;   { giu kind truoc khi loop ben trong lam thay doi v }

    { qu/gi quasi }
    if (BaseOf(kk) = 'u') and (i > 1) and (LowerBase(w[i-1]) = 'q') then Continue;
    if BaseOf(kk) = 'i' then
    begin
      nfoll := False;
      for j := i+1 to Length(w) do
        if DecomposeChar(w[j], v) and IsVowelKind(v.Kind) then
        begin
          nfoll := True;
          Break;
        end;
      if (i > 1) and (LowerBase(w[i-1]) = 'g') and nfoll then Continue;
    end;

    if n < Length(pos) then
    begin
      pos[n] := i;
      kinds[n] := kk;
    end;
    Inc(n);
  end;

  if n = 0 then
    Exit(0);
  if n = 1 then
    Exit(pos[0]);

  { uu tien nguyen am co dau hinh }
  firstMarked := -1;
  for i := 0 to n-1 do
    if ShapeOf(kinds[i]) <> shNone then
    begin
      firstMarked := i;
      Break;
    end;
  if firstMarked >= 0 then
    Exit(pos[firstMarked]);

  { cum nguyen am: luat dat dau }
  seq := '';
  for i := 0 to n-1 do
    seq := seq + string(BaseOf(kinds[i]));

  firstList  := (seq = 'ai') or (seq = 'ao') or (seq = 'au') or
                (seq = 'ay') or (seq = 'ia') or (seq = 'ie') or
                (seq = 'ua') or (seq = 'uo') or (seq = 'uy');
  { 'oa'/'oe' dang mo (khong co phu am cuoi) -> dau o nguyen am dau
    (hoa->hoa, khong -> hoang nay dau o 'a') }
  firstList := firstList or
    (((seq = 'oa') or (seq = 'oe')) and (pos[n-1] = Length(w)));

  if firstList then
    Result := pos[0]
  else
    Result := pos[n-1];
end;

function FindD(const w: UnicodeString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(w) do
    if (w[i] = 'd') or (w[i] = 'D') or (w[i] = 'đ') or (w[i] = 'Đ') then
      Result := i;
end;

{ cac nguyen am that (bo u trong 'qu', i quasi trong 'gi') }
procedure RealVowels(const w: UnicodeString; out pos: array of Integer;
  out kinds: array of TVowelKind; out n: Integer);
var
  i, j: Integer;
  v: TVietChar;
  kk: TVowelKind;
  later: Boolean;
begin
  n := 0;
  for i := 1 to Length(w) do
  begin
    if not DecomposeChar(w[i], v) then Continue;
    if not IsVowelKind(v.Kind) then Continue;
    kk := v.Kind;

    if (BaseOf(kk) = 'u') and (i > 1) and (LowerBase(w[i-1]) = 'q') then Continue;

    if BaseOf(kk) = 'i' then
    begin
      later := False;
      for j := i+1 to Length(w) do
        if DecomposeChar(w[j], v) and IsVowelKind(v.Kind) then
        begin
          later := True;
          Break;
        end;
      if (i > 1) and (LowerBase(w[i-1]) = 'g') and later then Continue;
    end;

    if n < Length(pos) then
    begin
      pos[n] := i;
      kinds[n] := kk;
    end;
    Inc(n);
  end;
end;

end.
