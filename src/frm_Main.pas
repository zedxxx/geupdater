unit frm_Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Threading,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  i_AppConfig,
  i_UpdateCheckerTask,
  i_EventLogStorage,
  i_TaskInfoListener,
  frm_About,
  frm_EventLogView;

type
  TfrmMain = class(TForm)
    grpGEClassic: TGroupBox;
    grpGEWeb: TGroupBox;
    grpGM: TGroupBox;
    grpGMClassic: TGroupBox;
    btnExit: TButton;
    btnAbout: TButton;
    btnTimeLine: TButton;
    pnlGEEarth: TPanel;
    pnlGEHistory: TPanel;
    pnlGESky: TPanel;
    pnlGEMoon: TPanel;
    pnlGEMars: TPanel;
    pnlGEClient: TPanel;
    pnlGEWebEarth: TPanel;
    pnlGEWebClient: TPanel;
    pnlGMClassicEarth: TPanel;
    pnlGMClassicJSAPI: TPanel;
    pnlGMEarth: TPanel;
    pnlGMMars: TPanel;
    pnlGMMoon: TPanel;
    pnlBottom: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnTimeLineClick(Sender: TObject);
  private
    FAppConfig: IAppConfig;
    FEventLog: IEventLogStorage;
    FListeners: TList<ITaskInfoListener>;
    FCheckerTasks: TList<ITask>;
    FfrmAbout: TfrmAbout;
    FfrmTimeLineForm: TfrmEventLogViewer;
    procedure BuildTasks(const AShowPrevInfoOnly: Boolean);
    procedure StartTasks;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  t_TaskInfo,
  i_Downloader,
  i_DownloaderFactory,
  u_AppConfig,
  u_TaskInfoListener,
  u_DownloaderFactory,
  u_GoogleMaps,
  u_GoogleEarthWeb,
  u_GoogleEarthDesktop,
  u_EventLogStorage;

{$R *.dfm}

function MakeTask(const ACheckerTask: IUpdateCheckerTask; const AShowPrevInfoOnly: Boolean): ITask;
begin
  Result := TTask.Create(procedure ()
    begin
      ACheckerTask.Execute(AShowPrevInfoOnly);
    end
  );
end;

procedure TfrmMain.BuildTasks(const AShowPrevInfoOnly: Boolean);

  function _GetGEPanel(const AType: TGoogleEarthDesktopCheckType): TPanel;
  begin
    case AType of
      gecctEarth:   Result := pnlGEEarth;
      gecctHistory: Result := pnlGEHistory;
      gecctSky:     Result := pnlGESky;
      gecctMars:    Result := pnlGEMars;
      gecctMoon:    Result := pnlGEMoon;
      gecctClient:  Result := pnlGEClient;
    else
      raise Exception.CreateFmt('GE Desktop - Unexpected type: %d', [Integer(AType)]);
    end;
  end;

  function _GetGEWebPanel(const AType: TGoogleEarthWebCheckType): TPanel;
  begin
    case AType of
      gewctEarth:  Result := pnlGEWebEarth;
      gewctClient: Result := pnlGEWebClient;
    else
      raise Exception.CreateFmt('GE Web - Unexpected type: %d', [Integer(AType)]);
    end;
  end;

  function _GetGMClassicPanel(const AType: TGoogleMapsCheckType): TPanel;
  begin
    case AType of
      gmctSat: Result := pnlGMClassicEarth;
      gmctApi: Result := pnlGMClassicJSAPI;
    else
      raise Exception.CreateFmt('GM Classic - Unexpected type: %d', [Integer(AType)]);
    end;
  end;

  function _GetGMPanel(const AType: TGoogleMapsCheckType): TPanel;
  begin
    case AType of
      gmctEarth: Result := pnlGMEarth;
      gmctMars:  Result := pnlGMMars;
      gmctMoon:  Result := pnlGMMoon;
    else
      raise Exception.CreateFmt('GM - Unexpected type: %d', [Integer(AType)]);
    end;
  end;

var
  VGEDesktopCheckType: TGoogleEarthDesktopCheckType;
  VGEWebCheckType: TGoogleEarthWebCheckType;
  VGMCheckType: TGoogleMapsCheckType;
  VDownloader: IDownloader;
  VDownloaderFactory: IDownloaderFactory;
  VTask: IUpdateCheckerTask;
  VListener: ITaskInfoListener;
begin
  VDownloaderFactory := TDownloaderFactory.Create;

  // GoogleEarth Desktop
  for VGEDesktopCheckType := Low(TGoogleEarthDesktopCheckType) to High(TGoogleEarthDesktopCheckType) do begin
    VListener := TTaskInfoListener.Create(_GetGEPanel(VGEDesktopCheckType));
    FListeners.Add(VListener);

    VTask := TGoogleEarthDesktop.Create(
      VGEDesktopCheckType,
      FAppConfig,
      VDownloaderFactory.BuildDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask, AShowPrevInfoOnly) );
  end;

  VDownloader := VDownloaderFactory.BuildDownloaderWithCache;

  // GoogleEarth Web
  for VGEWebCheckType := Low(TGoogleEarthWebCheckType) to High(TGoogleEarthWebCheckType) do begin
    VListener := TTaskInfoListener.Create(_GetGEWebPanel(VGEWebCheckType));
    FListeners.Add(VListener);

    VTask := TGoogleEarthWeb.Create(
      VGEWebCheckType,
      FAppConfig,
      VDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask, AShowPrevInfoOnly) );
  end;

  // GoogleMaps
  for VGMCheckType := Low(TGoogleMapsCheckType) to High(TGoogleMapsCheckType) do begin

    if VGMCheckType in cGoogleMapsClassicSet then begin
      Continue;
    end;

    VListener := TTaskInfoListener.Create(_GetGMPanel(VGMCheckType));
    FListeners.Add(VListener);

    VTask := TGoogleMaps.Create(
      VGMCheckType,
      FAppConfig,
      VDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask, AShowPrevInfoOnly) );
  end;

  // GoogleMaps Classic
  VDownloader := VDownloaderFactory.BuildDownloaderWithCache;

  for VGMCheckType in cGoogleMapsClassicSet do begin
    VListener := TTaskInfoListener.Create(_GetGMClassicPanel(VGMCheckType));
    FListeners.Add(VListener);

    VTask := TGoogleMaps.Create(
      VGMCheckType,
      FAppConfig,
      VDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask, AShowPrevInfoOnly) );
  end;
end;

procedure TfrmMain.StartTasks;
var
  I: Integer;
  VTaskArr: array of ITask;
begin
  if FCheckerTasks.Count > 0 then begin
    SetLength(VTaskArr, FCheckerTasks.Count);
    for I := 0 to FCheckerTasks.Count - 1 do begin
      VTaskArr[I] := FCheckerTasks.Items[I].Start;
    end;

    TTask.Run(procedure ()
      begin
        TTask.WaitForAll(VTaskArr);
        TThread.Synchronize(nil, procedure ()
          begin
            FCheckerTasks.Clear;
          end
        );
      end
    );
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAppConfig := TAppConfig.Create;
  FAppConfig.DoReadConfig;

  FEventLog := TEventLogStorageBySQLite.Create;
  FListeners := TList<ITaskInfoListener>.Create;
  FCheckerTasks := TList<ITask>.Create;

  BuildTasks(FAppConfig.ShowPrevInfoOnly and not FAppConfig.ForceUpdateCheck);
  StartTasks;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
var
  I: Integer;
  VTaskArr: array of ITask;
begin
  if FAppConfig <> nil then begin
    FAppConfig.DoWriteConfig;
  end;

  if Assigned(FCheckerTasks) and (FCheckerTasks.Count > 0) then begin
    SetLength(VTaskArr, FCheckerTasks.Count);
    for I := 0 to FCheckerTasks.Count - 1 do begin
      VTaskArr[I] := FCheckerTasks.Items[I];
      VTaskArr[I].Cancel;
    end;
    TTask.WaitForAll(VTaskArr, 1000);
  end;

  FreeAndNil(FCheckerTasks);
  FreeAndNil(FListeners);
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  btnExit.SetFocus;
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  if not Assigned(FfrmAbout) then begin
    FfrmAbout := TfrmAbout.Create(Self);
  end;

  FfrmAbout.ShowModal;
end;

procedure TfrmMain.btnTimeLineClick(Sender: TObject);
begin
  if not Assigned(FfrmTimeLineForm) then begin
    FfrmTimeLineForm := TfrmEventLogViewer.Create(Self,  FAppConfig.EventLogViewConfig, FEventLog);
  end;

  FfrmTimeLineForm.ShowModal;
end;

end.
