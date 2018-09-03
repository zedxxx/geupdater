program EventLogVeiwerTest;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  frm_EventLogView in '..\..\src\frm_EventLogView.pas' {frmEventLogViewer},
  u_EventLogViewConfig in '..\..\src\u_EventLogViewConfig.pas',
  i_EventLogStorage in '..\..\src\EventLog\i_EventLogStorage.pas',
  t_EventLog in '..\..\src\EventLog\t_EventLog.pas',
  u_EventLogStorage in '..\..\src\EventLog\u_EventLogStorage.pas',
  u_DateTimeUtils in '..\..\src\u_DateTimeUtils.pas',
  c_UpdateCheckerTask in '..\..\src\UpdateCheckerTask\c_UpdateCheckerTask.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
