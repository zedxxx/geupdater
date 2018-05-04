program GEUpdateChecker;

uses
  Vcl.Forms,
  c_UserAget in 'src\c_UserAget.pas',
  frm_About in 'src\frm_About.pas' {frmAbout},
  frm_Main in 'src\frm_Main.pas' {frmMain},
  u_DateTimeUtils in 'src\u_DateTimeUtils.pas',
  i_Downloader in 'src\Downloader\i_Downloader.pas',
  i_DownloadResponse in 'src\Downloader\i_DownloadResponse.pas',
  u_Downloader in 'src\Downloader\u_Downloader.pas',
  u_DownloaderWithRamCache in 'src\Downloader\u_DownloaderWithRamCache.pas',
  u_DownloadResponse in 'src\Downloader\u_DownloadResponse.pas',
  i_UpdateCheckerStoredInfo in 'src\UpdateCheckerTask\i_UpdateCheckerStoredInfo.pas',
  i_UpdateCheckerTask in 'src\UpdateCheckerTask\i_UpdateCheckerTask.pas',
  u_UpdateCheckerStoredInfo in 'src\UpdateCheckerTask\u_UpdateCheckerStoredInfo.pas',
  u_UpdateCheckerTaskBase in 'src\UpdateCheckerTask\u_UpdateCheckerTaskBase.pas',
  dbroot_lite in 'src\UpdateCheckerTask\GoogleEarthClassic\dbroot_lite.pas',
  u_GoogleEarthClassic in 'src\UpdateCheckerTask\GoogleEarthClassic\u_GoogleEarthClassic.pas',
  planetoid_metadata in 'src\UpdateCheckerTask\GoogleEarthWeb\planetoid_metadata.pas',
  u_GoogleEarthWeb in 'src\UpdateCheckerTask\GoogleEarthWeb\u_GoogleEarthWeb.pas',
  u_PlanetoidMetadata in 'src\UpdateCheckerTask\GoogleEarthWeb\u_PlanetoidMetadata.pas',
  u_GoogleMaps in 'src\UpdateCheckerTask\GoogleMaps\u_GoogleMaps.pas',
  i_TaskInfoListener in 'src\UpdateCheckerTaskListener\i_TaskInfoListener.pas',
  t_TaskInfo in 'src\UpdateCheckerTaskListener\t_TaskInfo.pas',
  u_TaskInfoListener in 'src\UpdateCheckerTaskListener\u_TaskInfoListener.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.
