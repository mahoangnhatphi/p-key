unit main_form;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Menus, Graphics, Windows,
  vni_engine;

type
  TInputMode = (imVNI, imTelex);

  TVNIKeyboardHookData = record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;
  PVNIKeyboardHookData = ^TVNIKeyboardHookData;

  TVNIKeyboardInput = record
    wVk: Word;
    wScan: Word;
    dwFlags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;
  TVNIMouseInput = record
    dx: LongInt;
    dy: LongInt;
    mouseData: DWORD;
    dwFlags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;
  TVNIInput = record
    IType: DWORD;
    case Integer of
      0: (mi: TVNIMouseInput);
      1: (ki: TVNIKeyboardInput);
  end;

  TVNIForm = class(TForm)
  private
    FEngine: TVNIEngine;
    FInputMode: TInputMode;
    FHook: HHOOK;
    FEnabled: Boolean;
    FInjecting: Boolean;
    FUpdatingUI: Boolean;
    FClosing: Boolean;
    FLastWindow: HWND;
    FStatus: TLabel;
    FModeMark: TLabel;
    FDetail: TLabel;
    FToggle: TCheckBox;
    FModeSelect: TComboBox;
    FShortcutTitle: TLabel;
    FShortcutText: TLabel;
    FTray: TTrayIcon;
    FTrayMenu: TPopupMenu;
    FTrayToggle: TMenuItem;
    procedure SetInputEnabled(Value: Boolean);
    procedure ToggleClick(Sender: TObject);
    procedure InputModeChange(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure HideClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ReplaceSuffix(const BeforeText, AfterText: UnicodeString);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function HandleKey(const Data: TVNIKeyboardHookData): Boolean;
  end;

var
  VNIForm: TVNIForm;

implementation

const
  INPUT_TAG: ULONG_PTR = $564E49;
  WH_KEYBOARD_LL = 13;

var
  ActiveForm: TVNIForm;

function SendInput(cInputs: UINT; pInputs: Pointer; cbSize: Integer): UINT; stdcall;
  external 'user32.dll' name 'SendInput';

function IsModifierDown(Key: Integer): Boolean;
begin
  Result := GetAsyncKeyState(Key) < 0;
end;

function KeyToChar(VK: DWORD; out C: WideChar): Boolean;
var
  Upper: Boolean;
begin
  Result := True;
  if (VK >= Ord('A')) and (VK <= Ord('Z')) then
  begin
    Upper := IsModifierDown(VK_SHIFT) xor (GetKeyState(VK_CAPITAL) and 1 <> 0);
    if Upper then
      C := WideChar(VK)
    else
      C := WideChar(VK + 32);
  end
  else if (VK >= Ord('0')) and (VK <= Ord('9')) and not IsModifierDown(VK_SHIFT) then
    C := WideChar(VK)
  else if (VK >= VK_NUMPAD0) and (VK <= VK_NUMPAD9) and
    (GetKeyState(VK_NUMLOCK) and 1 <> 0) then
    C := WideChar(Ord('0') + VK - VK_NUMPAD0)
  else if VK = VK_SPACE then
    C := ' '
  else
    Result := False;
end;

procedure SendBackspace;
var
  Inputs: array[0..1] of TVNIInput;
begin
  FillChar(Inputs, SizeOf(Inputs), 0);
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_BACK;
  Inputs[0].ki.dwExtraInfo := INPUT_TAG;
  Inputs[1] := Inputs[0];
  Inputs[1].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(Length(Inputs), @Inputs[0], SizeOf(TVNIInput));
end;

procedure SendUnicode(const Text: UnicodeString);
var
  Inputs: array[0..1] of TVNIInput;
  i: Integer;
begin
  for i := 1 to Length(Text) do
  begin
    FillChar(Inputs, SizeOf(Inputs), 0);
    Inputs[0].Itype := INPUT_KEYBOARD;
    Inputs[0].ki.wScan := Ord(Text[i]);
    Inputs[0].ki.dwFlags := KEYEVENTF_UNICODE;
    Inputs[0].ki.dwExtraInfo := INPUT_TAG;
    Inputs[1] := Inputs[0];
    Inputs[1].ki.dwFlags := KEYEVENTF_UNICODE or KEYEVENTF_KEYUP;
    SendInput(Length(Inputs), @Inputs[0], SizeOf(TVNIInput));
  end;
end;

function KeyboardProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  Data: PVNIKeyboardHookData;
begin
  if nCode = HC_ACTION then
  begin
    Data := PVNIKeyboardHookData(lParam);
    if (Data^.dwExtraInfo <> INPUT_TAG) and (wParam = WM_KEYDOWN) and
      Assigned(ActiveForm) and ActiveForm.HandleKey(Data^) then
      Exit(1);
  end;
  if Assigned(ActiveForm) then
    Result := CallNextHookEx(ActiveForm.FHook, nCode, wParam, lParam)
  else
    Result := CallNextHookEx(0, nCode, wParam, lParam);
end;

constructor TVNIForm.Create(AOwner: TComponent);
var
  Header, StatusCard, ShortcutCard: TPanel;
  Title, Subtitle, ModeLabel: TLabel;
  Help: TLabel;
  HideButton, ExitButton: TButton;
  ExitItem: TMenuItem;
begin
  inherited Create(AOwner);
  Caption := 'P-Key';
  Position := poScreenCenter;
  ClientWidth := 500;
  ClientHeight := 380;
  BorderStyle := bsSingle;
  Color := $00F8F7F5;
  Font.Name := 'Segoe UI';
  OnCloseQuery := @FormCloseQuery;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 88;
  Header.BevelOuter := bvNone;
  Header.ParentColor := False;
  Header.Color := $00733A18;

  Title := TLabel.Create(Self);
  Title.Parent := Header;
  Title.Caption := 'P-Key';
  Title.Font.Name := 'Segoe UI Semibold';
  Title.Font.Size := 16;
  Title.Font.Color := clWhite;
  Title.SetBounds(26, 15, 280, 28);

  Subtitle := TLabel.Create(Self);
  Subtitle.Parent := Header;
  Subtitle.Caption := 'VNI typing, always ready in the system tray';
  Subtitle.Font.Name := 'Segoe UI';
  Subtitle.Font.Color := $00E6D8CB;
  Subtitle.SetBounds(28, 48, 380, 22);

  StatusCard := TPanel.Create(Self);
  StatusCard.Parent := Self;
  StatusCard.BevelOuter := bvNone;
  StatusCard.ParentColor := False;
  StatusCard.Color := clWhite;
  StatusCard.SetBounds(24, 112, 452, 78);

  FModeMark := TLabel.Create(Self);
  FModeMark.Parent := StatusCard;
  FModeMark.Caption := 'V';
  FModeMark.Font.Name := 'Segoe UI Semibold';
  FModeMark.Font.Size := 22;
  FModeMark.Font.Color := clRed;
  FModeMark.Alignment := taCenter;
  FModeMark.Layout := tlCenter;
  FModeMark.SetBounds(18, 17, 30, 42);

  FStatus := TLabel.Create(Self);
  FStatus.Parent := StatusCard;
  FStatus.Font.Name := 'Segoe UI Semibold';
  FStatus.Font.Size := 10;
  FStatus.SetBounds(60, 17, 340, 24);

  FDetail := TLabel.Create(Self);
  FDetail.Parent := StatusCard;
  FDetail.Font.Name := 'Segoe UI';
  FDetail.Font.Color := clGray;
  FDetail.SetBounds(60, 42, 350, 20);

  ModeLabel := TLabel.Create(Self);
  ModeLabel.Parent := Self;
  ModeLabel.Caption := 'Kieu go';
  ModeLabel.Font.Name := 'Segoe UI Semibold';
  ModeLabel.SetBounds(26, 207, 88, 24);

  FModeSelect := TComboBox.Create(Self);
  FModeSelect.Parent := Self;
  FModeSelect.Style := csDropDownList;
  FModeSelect.Items.Add('VNI  (1-9)');
  FModeSelect.Items.Add('Telex  (s f r x j)');
  FModeSelect.ItemIndex := Ord(imVNI);
  FModeSelect.SetBounds(116, 203, 180, 30);
  FModeSelect.OnChange := @InputModeChange;

  FToggle := TCheckBox.Create(Self);
  FToggle.Parent := Self;
  FToggle.Caption := 'Bat bo go tieng Viet toan he thong';
  FToggle.Font.Name := 'Segoe UI Semibold';
  FToggle.SetBounds(26, 238, 320, 28);
  FToggle.OnClick := @ToggleClick;

  ShortcutCard := TPanel.Create(Self);
  ShortcutCard.Parent := Self;
  ShortcutCard.BevelOuter := bvNone;
  ShortcutCard.ParentColor := False;
  ShortcutCard.Color := $00EEEAE5;
  ShortcutCard.SetBounds(24, 274, 452, 54);

  FShortcutTitle := TLabel.Create(Self);
  FShortcutTitle.Parent := ShortcutCard;
  FShortcutTitle.Caption := 'VNI';
  FShortcutTitle.Font.Name := 'Segoe UI Semibold';
  FShortcutTitle.Font.Color := $00733A18;
  FShortcutTitle.SetBounds(18, 17, 48, 20);

  FShortcutText := TLabel.Create(Self);
  FShortcutText.Parent := ShortcutCard;
  FShortcutText.Caption := '1-5 tone   6 circumflex   7 horn   8 breve   9 d   0 remove tone';
  FShortcutText.Font.Name := 'Segoe UI';
  FShortcutText.Font.Color := clGray;
  FShortcutText.SetBounds(70, 17, 360, 20);

  Help := TLabel.Create(Self);
  Help.Parent := Self;
  Help.AutoSize := False;
  Help.WordWrap := True;
  Help.Caption := 'Dong cua so nay de tiep tuc chay nen. Bam bieu tuong khay he thong de mo lai.';
  Help.Font.Name := 'Segoe UI';
  Help.Font.Color := clGray;
  Help.SetBounds(26, 340, 250, 30);

  HideButton := TButton.Create(Self);
  HideButton.Parent := Self;
  HideButton.Caption := 'An xuong khay';
  HideButton.Font.Name := 'Segoe UI';
  HideButton.SetBounds(278, 338, 112, 30);
  HideButton.OnClick := @HideClick;

  ExitButton := TButton.Create(Self);
  ExitButton.Parent := Self;
  ExitButton.Caption := 'Thoat';
  ExitButton.Font.Name := 'Segoe UI';
  ExitButton.SetBounds(396, 338, 80, 30);
  ExitButton.OnClick := @ExitClick;

  FTrayMenu := TPopupMenu.Create(Self);
  FTrayToggle := TMenuItem.Create(FTrayMenu);
  FTrayToggle.OnClick := @ToggleClick;
  FTrayMenu.Items.Add(FTrayToggle);
  ExitItem := TMenuItem.Create(FTrayMenu);
  ExitItem.Caption := 'Thoat';
  ExitItem.OnClick := @ExitClick;
  FTrayMenu.Items.Add(ExitItem);
  FTray := TTrayIcon.Create(Self);
  FTray.Hint := 'P-Key';
  FTray.Icon.Handle := LoadIcon(HInstance, MakeIntResource(1));
  Icon.Assign(FTray.Icon);
  FTray.PopUpMenu := FTrayMenu;
  FTray.OnClick := @TrayClick;
  FTray.Visible := True;

  FEngine := TVNIEngine.Create;
  ActiveForm := Self;
  SetInputEnabled(True);
end;

destructor TVNIForm.Destroy;
begin
  SetInputEnabled(False);
  if ActiveForm = Self then
    ActiveForm := nil;
  FEngine.Free;
  inherited Destroy;
end;

procedure TVNIForm.SetInputEnabled(Value: Boolean);
begin
  if Value = FEnabled then
    Exit;
  if Value then
  begin
    FHook := SetWindowsHookEx(WH_KEYBOARD_LL, @KeyboardProc, HInstance, 0);
    FEnabled := FHook <> 0;
  end
  else
  begin
    if FHook <> 0 then
      UnhookWindowsHookEx(FHook);
    FHook := 0;
    FEnabled := False;
  end;
  FEngine.Reset;
  FLastWindow := 0;
  FUpdatingUI := True;
  try
    FToggle.Checked := FEnabled;
    FTrayToggle.Checked := FEnabled;
    if FEnabled then
    begin
      FStatus.Caption := 'Trang thai: Dang bat';
      FModeMark.Caption := 'V';
      FModeMark.Font.Color := clRed;
      FDetail.Caption := 'San sang go tieng Viet trong ung dung thuong dung.';
      FTrayToggle.Caption := 'Tat bo go';
      FTray.Hint := 'P-Key - Dang bat';
    end
    else
    begin
      FStatus.Caption := 'Trang thai: Da tat (khong tao duoc hook)';
      FModeMark.Caption := 'E';
      FModeMark.Font.Color := clGray;
      FDetail.Caption := 'Bam de thu bat bo go lai.';
      FTrayToggle.Caption := 'Bat bo go';
      FTray.Hint := 'P-Key - Da tat';
    end;
  finally
    FUpdatingUI := False;
  end;
end;

procedure TVNIForm.ToggleClick(Sender: TObject);
begin
  if FUpdatingUI then
    Exit;
  SetInputEnabled(not FEnabled);
end;

procedure TVNIForm.InputModeChange(Sender: TObject);
begin
  FInputMode := TInputMode(FModeSelect.ItemIndex);
  FEngine.Reset;
  if FInputMode = imVNI then
  begin
    FShortcutTitle.Caption := 'VNI';
    FShortcutText.Caption := '1-5 tone   6 circumflex   7 horn   8 breve   9 d   0 remove tone';
  end
  else
  begin
    FShortcutTitle.Caption := 'TELEX';
    FShortcutText.Caption := 's f r x j tone   aa aw ee oo ow uw dd   z remove mark';
  end;
end;

procedure TVNIForm.TrayClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  BringToFront;
end;

procedure TVNIForm.ExitClick(Sender: TObject);
begin
  FClosing := True;
  Close;
end;

procedure TVNIForm.HideClick(Sender: TObject);
begin
  Hide;
end;

procedure TVNIForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FClosing;
  if not CanClose then
    Hide;
end;

procedure TVNIForm.ReplaceSuffix(const BeforeText, AfterText: UnicodeString);
var
  i, FirstChanged: Integer;
begin
  if FInjecting then
    Exit;
  FInjecting := True;
  try
  FirstChanged := 1;
  while (FirstChanged <= Length(BeforeText)) and
    (FirstChanged <= Length(AfterText)) and
    (BeforeText[FirstChanged] = AfterText[FirstChanged]) do
    Inc(FirstChanged);
  for i := FirstChanged to Length(BeforeText) do
    SendBackspace;
  SendUnicode(Copy(AfterText, FirstChanged, Length(AfterText)));
  finally
    FInjecting := False;
  end;
end;

function TVNIForm.HandleKey(const Data: TVNIKeyboardHookData): Boolean;
var
  C: WideChar;
  BeforeText, AfterText: UnicodeString;
  Target: HWND;
begin
  Result := False;
  if not FEnabled or FInjecting then
    Exit;

  Target := GetForegroundWindow;
  if Target <> FLastWindow then
  begin
    FEngine.Reset;
    FLastWindow := Target;
  end;

  if IsModifierDown(VK_CONTROL) or IsModifierDown(VK_MENU) then
  begin
    FEngine.Reset;
    Exit;
  end;

  if Data.vkCode = VK_BACK then
  begin
    FEngine.Backspace;
    Exit;
  end;
  if (Data.vkCode = VK_DELETE) or (Data.vkCode = VK_LEFT) or
    (Data.vkCode = VK_RIGHT) or (Data.vkCode = VK_UP) or
    (Data.vkCode = VK_DOWN) or (Data.vkCode = VK_HOME) or
    (Data.vkCode = VK_END) or (Data.vkCode = VK_PRIOR) or
    (Data.vkCode = VK_NEXT) then
  begin
    FEngine.Reset;
    Exit;
  end;

  if not KeyToChar(Data.vkCode, C) then
  begin
    if (Data.vkCode = VK_RETURN) or (Data.vkCode = VK_TAB) or
      (Data.vkCode >= VK_OEM_1) then
      FEngine.Reset;
    Exit;
  end;

  if C = ' ' then
  begin
    FEngine.Reset;
    Exit;
  end;

  BeforeText := FEngine.Word;
  if FInputMode = imVNI then
    FEngine.TypeChar(C)
  else
    FEngine.TypeTelexChar(C);
  AfterText := FEngine.Word;
  if (AfterText <> BeforeText + C) and
    ((FInputMode = imTelex) or ((C >= '0') and (C <= '9'))) then
  begin
    { ponytail: suffix replacement assumes an ordinary text caret; reset on navigation, add selection tracking only if needed. }
    ReplaceSuffix(BeforeText, AfterText);
    Result := True;
  end;
end;

end.
