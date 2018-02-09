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
  i_TaskInfoListener;

type
  TfrmMain = class(TForm)
    grpGEClassic: TGroupBox;
    grpGEWeb: TGroupBox;
    grpGM: TGroupBox;
    grpGMClassic: TGroupBox;
    btnExit: TButton;
    btnAbout: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
  private
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
  t_TaskInfo,
  i_Downloader,
  i_UpdateCheckerStoredInfo,
  u_TaskInfoListener,
  u_Downloader,
  u_DownloaderWithRamCache,
  u_GoogleMaps,
  u_GoogleEarthWeb,
  u_GoogleEarthClassic,
  u_UpdateCheckerStoredInfo;

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
  VGEClassicCheckType: TGoogleEarthClassicCheckType;
  VGEWebCheckType: TGoogleEarthWebCheckType;
  VGMCheckType: TGoogleMapsCheckType;
  VProxyParams: TProxyParams;
  VDownloader: IDownloader;
  VTask: IUpdateCheckerTask;
  VListener: ITaskInfoListener;
  VStoredInfo: IUpdateCheckerStoredInfo;
begin
  VProxyParams.UseProxy := False;
  VStoredInfo := TUpdateCheckerStoredInfo.Create('StoredInfo.ini');

  // GoogleEarth Classic
  for VGEClassicCheckType := Low(TGoogleEarthClassicCheckType) to High(TGoogleEarthClassicCheckType) do begin
    VDownloader := TDownloaderByIndy.Create(VProxyParams);

    VListener := TTaskInfoListener.Create(grpGEClassic);
    FListeners.Add(VListener);

    VTask := TGoogleEarthClassic.Create(
      VGEClassicCheckType,
      VDownloader,
      VStoredInfo,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask) );
  end;

  VDownloader :=
    TDownloaderWithRamCache.Create(
      TDownloaderByIndy.Create(VProxyParams)
    );

  // GoogleEarth Web
  for VGEWebCheckType := Low(TGoogleEarthWebCheckType) to High(TGoogleEarthWebCheckType) do begin
    VListener := TTaskInfoListener.Create(grpGEWeb);
    FListeners.Add(VListener);

    VTask := TGoogleEarthWeb.Create(
      VGEWebCheckType,
      VDownloader,
      VStoredInfo,
      TArray<ITaskInfoListener>.Create(VListener)
    );
    FCheckerTasks.Add( MakeTask(VTask) );
  end;

  // GoogleMaps Classic
  for VGMCheckType in cGoogleMapsClassicSet do begin
    VListener := TTaskInfoListener.Create(grpGMClassic);
    FListeners.Add(VListener);

    VTask := TGoogleMaps.Create(
      VGMCheckType,
      VDownloader,
      VStoredInfo,
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
      VStoredInfo,
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

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

end.
