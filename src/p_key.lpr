program p_key;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
{$APPTYPE GUI}
{$R app.res}
{$ENDIF}

uses
  Interfaces, Forms, Windows, main_form;

const
  InstanceName = 'Local\PKey';

var
  InstanceMutex: THandle;
  ExistingWindow: HWND;

begin
  InstanceMutex := CreateMutex(nil, True, InstanceName);
  if InstanceMutex = 0 then
    Halt(1);
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    ExistingWindow := FindWindow(nil, 'P-Key');
    if ExistingWindow <> 0 then
    begin
      ShowWindow(ExistingWindow, SW_RESTORE);
      SetForegroundWindow(ExistingWindow);
    end;
    CloseHandle(InstanceMutex);
    Halt(0);
  end;

  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.Title := 'P-Key';
  Application.CreateForm(TVNIForm, VNIForm);
  Application.Run;
end.
