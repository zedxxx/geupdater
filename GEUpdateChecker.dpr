program GEUpdateChecker;

uses
  Vcl.Forms,
  c_UserAget in 'src\c_UserAget.pas',
  frm_About in 'src\frm_About.pas' {frmAbout},
  frm_Main in 'src\frm_Main.pas' {frmMain},
  u_DateTimeUtils in 'src\u_DateTimeUtils.pas',
  i_Downloader in 'src\Downloader\i_Downloader.pas',
  i_DownloadResponse in 'src\Downloader\i_DownloadResponse.pas',
  u_DownloaderByIndy in 'src\Downloader\u_DownloaderByIndy.pas',
  u_DownloaderWithRamCache in 'src\Downloader\u_DownloaderWithRamCache.pas',
  u_DownloadResponse in 'src\Downloader\u_DownloadResponse.pas',
  i_UpdateCheckerTask in 'src\UpdateCheckerTask\i_UpdateCheckerTask.pas',
  u_UpdateCheckerTaskBase in 'src\UpdateCheckerTask\u_UpdateCheckerTaskBase.pas',
  dbroot_lite in 'src\UpdateCheckerTask\GoogleEarthDesktop\dbroot_lite.pas',
  u_GoogleEarthDesktop in 'src\UpdateCheckerTask\GoogleEarthDesktop\u_GoogleEarthDesktop.pas',
  planetoid_metadata in 'src\UpdateCheckerTask\GoogleEarthWeb\planetoid_metadata.pas',
  u_GoogleEarthWeb in 'src\UpdateCheckerTask\GoogleEarthWeb\u_GoogleEarthWeb.pas',
  u_PlanetoidMetadata in 'src\UpdateCheckerTask\GoogleEarthWeb\u_PlanetoidMetadata.pas',
  u_GoogleMaps in 'src\UpdateCheckerTask\GoogleMaps\u_GoogleMaps.pas',
  i_TaskInfoListener in 'src\UpdateCheckerTaskListener\i_TaskInfoListener.pas',
  t_TaskInfo in 'src\UpdateCheckerTaskListener\t_TaskInfo.pas',
  u_TaskInfoListener in 'src\UpdateCheckerTaskListener\u_TaskInfoListener.pas',
  u_Scheduler in 'src\u_Scheduler.pas',
  u_DownloaderByHttpClient in 'src\Downloader\u_DownloaderByHttpClient.pas',
  u_DownloaderFactory in 'src\Downloader\u_DownloaderFactory.pas',
  i_DownloaderFactory in 'src\Downloader\i_DownloaderFactory.pas',
  i_EventLogStorage in 'src\EventLog\i_EventLogStorage.pas',
  t_EventLog in 'src\EventLog\t_EventLog.pas',
  u_EventLogStorage in 'src\EventLog\u_EventLogStorage.pas',
  frm_EventLogView in 'src\frm_EventLogView.pas' {frmEventLogViewer},
  u_EventLogViewConfig in 'src\u_EventLogViewConfig.pas',
  c_UpdateCheckerTask in 'src\UpdateCheckerTask\c_UpdateCheckerTask.pas',
  fr_TaskInfo in 'src\fr_TaskInfo.pas' {frTaskInfo: TFrame};

{$R *.res}

begin
  if not TScheduler.AppCanStart then begin
    Exit;
  end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
