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
  i_UpdateCheckerTask,
  i_EventLogStorage,
  i_TaskInfoListener;

type
  TfrmMain = class(TForm)
    grpGEClassic: TGroupBox;
    grpGEWeb: TGroupBox;
    grpGM: TGroupBox;
    grpGMClassic: TGroupBox;
    btnExit: TButton;
    btnAbout: TButton;
    btnTimeLine: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnTimeLineClick(Sender: TObject);
  private
    FEventLog: IEventLogStorage;
    FListeners: TList<ITaskInfoListener>;
    FCheckerTasks: TList<ITask>;
    procedure BuildTasks;
    procedure StartTasks;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  frm_About,
  frm_EventLogView,
  t_TaskInfo,
  i_Downloader,
  i_DownloaderFactory,
  u_TaskInfoListener,
  u_DownloaderFactory,
  u_GoogleMaps,
  u_GoogleEarthWeb,
  u_GoogleEarthDesktop,
  u_EventLogStorage;

{$R *.dfm}

function MakeTask(const ACheckerTask: IUpdateCheckerTask): ITask;
begin
  Result := TTask.Create(procedure ()
    begin
      ACheckerTask.Execute;
    end
  );
end;

procedure TfrmMain.BuildTasks;
var
  VGEDesktopCheckType: TGoogleEarthDesktopCheckType;
  VGEWebCheckType: TGoogleEarthWebCheckType;
  VGMCheckType: TGoogleMapsCheckType;
  VDownloader: IDownloader;
  VDownloaderFactory: IDownloaderFactory;
  VTask: IUpdateCheckerTask;
  VListener: ITaskInfoListener;
begin
  VDownloaderFactory := TDownloaderFactory.Create(dftHttpClient);

  // GoogleEarth Desktop
  for VGEDesktopCheckType := Low(TGoogleEarthDesktopCheckType) to High(TGoogleEarthDesktopCheckType) do begin
    VListener := TTaskInfoListener.Create(grpGEClassic);
    FListeners.Add(VListener);

    VTask := TGoogleEarthDesktop.Create(
      VGEDesktopCheckType,
      VDownloaderFactory.BuildDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask) );
  end;

  VDownloader := VDownloaderFactory.BuildDownloaderWithCache;

  // GoogleEarth Web
  for VGEWebCheckType := Low(TGoogleEarthWebCheckType) to High(TGoogleEarthWebCheckType) do begin
    VListener := TTaskInfoListener.Create(grpGEWeb);
    FListeners.Add(VListener);

    VTask := TGoogleEarthWeb.Create(
      VGEWebCheckType,
      VDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask) );
  end;

  // GoogleMaps
  for VGMCheckType := Low(TGoogleMapsCheckType) to High(TGoogleMapsCheckType) do begin

    if VGMCheckType in cGoogleMapsClassicSet then begin
      Continue;
    end;

    VListener := TTaskInfoListener.Create(grpGM);
    FListeners.Add(VListener);

    VTask := TGoogleMaps.Create(
      VGMCheckType,
      VDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask) );
  end;

  // GoogleMaps Classic
  VDownloader := VDownloaderFactory.BuildDownloaderWithCache;

  for VGMCheckType in cGoogleMapsClassicSet do begin
    VListener := TTaskInfoListener.Create(grpGMClassic);
    FListeners.Add(VListener);

    VTask := TGoogleMaps.Create(
      VGMCheckType,
      VDownloader,
      FEventLog,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask) );
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
  FEventLog := TEventLogStorageBySQLite.Create;
  FListeners := TList<ITaskInfoListener>.Create;
  FCheckerTasks := TList<ITask>.Create;
  BuildTasks;
  StartTasks;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
var
  I: Integer;
  VTaskArr: array of ITask;
begin
  if FCheckerTasks.Count > 0 then begin
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

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnTimeLineClick(Sender: TObject);
var
  VTimeLineForm: TfrmEventLogViewer;
begin
  VTimeLineForm := TfrmEventLogViewer.Create(Self, FEventLog);
  try
    VTimeLineForm.ShowModal;
  finally
    VTimeLineForm.Free;
  end;
end;

end.
