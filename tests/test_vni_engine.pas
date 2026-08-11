program test_vni_engine;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  SysUtils, vietnamese_chars, syllable_parser, vni_engine;

var
  Passed, Failed: Integer;

function Feed(keys: string; out word: UnicodeString): TVNIEngine;
var
  i: Integer;
  e: TVNIEngine;
begin
  e := TVNIEngine.Create;
  for i := 1 to Length(keys) do
    e.TypeChar(WideChar(keys[i]));
  word := e.CurrentWord;
  Result := e;
end;

procedure Check(keys: string; expected: UnicodeString);
var
  word: UnicodeString;
  e: TVNIEngine;
begin
  e := Feed(keys, word);
  if word = expected then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    WriteLn('FAIL [', keys, '] got=[', word, '] want=[', expected, ']');
  end;
end;

procedure CheckTelex(keys: string; expected: UnicodeString);
var
  i: Integer;
  e: TVNIEngine;
begin
  e := TVNIEngine.Create;
  for i := 1 to Length(keys) do
    e.TypeTelexChar(WideChar(keys[i]));
  if e.Word = expected then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    WriteLn('FAIL Telex [', keys, '] got=[', e.Word, '] want=[', expected, ']');
  end;
  e.Free;
end;

procedure CheckBackspace;
var
  e: TVNIEngine;
  word: UnicodeString;
begin
  e := Feed('Vie65t', word);  { Việt }
  e.Backspace;
  if e.CurrentWord <> 'Việ' then
  begin
    Inc(Failed);
    WriteLn('FAIL backspace1 got=[', e.CurrentWord, '] want=[Việ]');
  end
  else
    Inc(Passed);

  e.Backspace;
  if e.CurrentWord <> 'Vi' then
  begin
    Inc(Failed);
    WriteLn('FAIL backspace2 got=[', e.CurrentWord, '] want=[Vi]');
  end
  else
    Inc(Passed);

  e.Backspace;
  if e.CurrentWord <> 'V' then
  begin
    Inc(Failed);
    WriteLn('FAIL backspace3 got=[', e.CurrentWord, '] want=[V]');
  end
  else
    Inc(Passed);
end;

begin
  Passed := 0;
  Failed := 0;

  { thanh co ban }
  Check('a1', 'á');
  Check('a2', 'à');
  Check('a3', 'ả');
  Check('a4', 'ã');
  Check('a5', 'ạ');
  Check('e1', 'é');
  Check('i1', 'í');
  Check('o2', 'ò');
  Check('u3', 'ủ');
  Check('y1', 'ý');

  { dau hinh }
  Check('a6', 'â');
  Check('o6', 'ô');
  Check('e6', 'ê');
  Check('a8', 'ă');
  Check('o7', 'ơ');
  Check('u7', 'ư');
  Check('d9', 'đ');
  Check('D9', 'Đ');
  Check('d99', 'd');

  { hinh + thanh }
  Check('a61', 'ấ');
  Check('o61', 'ố');
  Check('e62', 'ề');

  { word co ban }
  Check('to6i', 'tôi');
  Check('VIE65T', 'VIỆT');
  Check('hoa1', 'hóa');
  Check('chao2', 'chào');
  Check('hoang2', 'hoàng');
  Check('nguye64n', 'nguyễn');
  Check('tie61ng', 'tiếng');
  Check('thuye63n', 'thuyển');
  Check('quye61t', 'quyết');
  Check('gie61ng', 'giếng');
  Check('gi2', 'gì');
  Check('quy1', 'quý');
  Check('quang2', 'quàng');
  Check('uo7', 'uơ');
  Check('mua7', 'mưa');

  { doi dau }
  Check('a12', 'à');
  Check('a13', 'ả');
  Check('a51', 'á');

  { go dau 2 lan -> xoa }
  Check('a11', 'a');
  Check('a22', 'a');
  Check('a61', 'ấ');
  Check('a611', 'â');        { 6->a,1->ấ,1->xoa thanh -> â }

  { go hinh 2 lan -> xoa hinh }
  Check('a66', 'a');
  Check('o66', 'o');

  { phim 0: uu tien xoa thanh, giu hinh }
  Check('a10', 'a');
  Check('a20', 'a');
  Check('a610', 'â');
  Check('o610', 'ô');
  Check('u710', 'ư');

  { so thuong }
  Check('2026', '2026');
  Check('1984', '1984');
  Check('hello6', 'hello6');
  Check('test6', 'test6');

  { Telex }
  CheckTelex('aS', 'á');
  CheckTelex('aaf', 'ầ');
  CheckTelex('aw', 'ă');
  CheckTelex('ee', 'ê');
  CheckTelex('oo', 'ô');
  CheckTelex('ow', 'ơ');
  CheckTelex('uw', 'ư');
  CheckTelex('dd', 'đ');
  CheckTelex('tieengs', 'tiếng');
  CheckTelex('chao2', 'chao2');
  CheckTelex('aaz', 'a');
  CheckTelex('ddz', 'd');

  { ghi chu: hello6 -> hellô (engine bien doi nguyen am, khong check am tiet)
    plan mong 'hello6 -> hello6' nhung do bo qua validation on-set }

  { backspace }
  CheckBackspace;

  WriteLn('Passed: ', Passed);
  WriteLn('Failed: ', Failed);
  if Failed = 0 then
    WriteLn('ALL TESTS PASSED')
  else
    WriteLn('SOME TESTS FAILED');

  Halt(Failed);
end.
