program GEUpdateChecker;

uses
  Vcl.Forms,
  frm_Main in 'frm_Main.pas' {frmMain},
  u_UpdateCheckerTaskBase in 'UpdateCheckerTask\u_UpdateCheckerTaskBase.pas',
  i_Downloader in 'Downloader\i_Downloader.pas',
  i_DownloadResponse in 'Downloader\i_DownloadResponse.pas',
  u_Downloader in 'Downloader\u_Downloader.pas',
  u_DownloadResponse in 'Downloader\u_DownloadResponse.pas',
  i_UpdateCheckerTask in 'UpdateCheckerTask\i_UpdateCheckerTask.pas',
  u_GoogleEarthClassic in 'UpdateCheckerTask\GoogleEarthClassic\u_GoogleEarthClassic.pas',
  i_TaskInfoListener in 'UpdateCheckerTaskListener\i_TaskInfoListener.pas',
  t_TaskInfo in 'UpdateCheckerTaskListener\t_TaskInfo.pas',
  u_TaskInfoListener in 'UpdateCheckerTaskListener\u_TaskInfoListener.pas',
  u_GoogleMaps in 'UpdateCheckerTask\GoogleMaps\u_GoogleMaps.pas',
  u_GoogleEarthWeb in 'UpdateCheckerTask\GoogleEarthWeb\u_GoogleEarthWeb.pas',
  planetoid_metadata in 'UpdateCheckerTask\GoogleEarthWeb\planetoid_metadata.pas',
  pbInput in 'Include\ProtoBufGenerator\pbInput.pas',
  pbOutput in 'Include\ProtoBufGenerator\pbOutput.pas',
  pbPublic in 'Include\ProtoBufGenerator\pbPublic.pas',
  StrBuffer in 'Include\ProtoBufGenerator\StrBuffer.pas',
  uAbstractProtoBufClasses in 'Include\ProtoBufGenerator\uAbstractProtoBufClasses.pas',
  c_UserAget in 'c_UserAget.pas',
  i_UpdateCheckerStoredInfo in 'UpdateCheckerTask\i_UpdateCheckerStoredInfo.pas',
  u_UpdateCheckerStoredInfo in 'UpdateCheckerTask\u_UpdateCheckerStoredInfo.pas',
  u_DownloaderWithRamCache in 'Downloader\u_DownloaderWithRamCache.pas',
  frm_About in 'frm_About.pas' {frmAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.
