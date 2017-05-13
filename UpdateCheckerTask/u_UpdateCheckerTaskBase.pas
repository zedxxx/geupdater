unit u_UpdateCheckerTaskBase;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_UpdateCheckerTask,
  i_UpdateCheckerStoredInfo;

type
  TUpdateCheckerTaskBase = class(TInterfacedObject, IUpdateCheckerTask)
  protected
    FInfo: TTaskInfo;
    FListener: TArray<ITaskInfoListener>;
    FDownloader: IDownloader;
    FStoredInfo: IUpdateCheckerStoredInfo;
    FStoredInfoRec: TStoredInfoRec;
    FHasStoredInfo: Boolean;
    procedure ClearInfo(var AInfo: TTaskInfo);
    procedure UpdateListener;
  protected
    function GetGUID: TGUID; virtual; abstract;
    function GetName: string; virtual; abstract;
    procedure DoExecute; virtual; abstract;
  private
    { IUpdateCheckerTask }
    procedure Execute;
  public
    constructor Create(
      const ADownloader: IDownloader;
      const AStoredInfo: IUpdateCheckerStoredInfo;
      const AListener: TArray<ITaskInfoListener>
    );
    procedure AfterConstruction; override;
  end;

implementation

uses
  SysUtils;

{ TUpdateCheckerTaskBase }

constructor TUpdateCheckerTaskBase.Create(
  const ADownloader: IDownloader;
  const AStoredInfo: IUpdateCheckerStoredInfo;
  const AListener: TArray<ITaskInfoListener>
);
begin
  Assert(ADownloader <> nil);
  Assert(AStoredInfo <> nil);

  inherited Create;

  FDownloader := ADownloader;
  FStoredInfo := AStoredInfo;
  FListener := AListener;

  ClearInfo(FInfo);
end;

procedure TUpdateCheckerTaskBase.AfterConstruction;
begin
  inherited;
  FInfo.Name := GetName;
  FHasStoredInfo := FStoredInfo.Read(GetGUID, FStoredInfoRec);
  UpdateListener;
end;

procedure TUpdateCheckerTaskBase.Execute;
begin
  FInfo.State := tsInProgress;
  UpdateListener;
  try
    try
      DoExecute;
      if FInfo.State = tsFinished then begin
        if FInfo.IsUpdatesFound or not FHasStoredInfo then begin
          FStoredInfoRec.Version := FInfo.Version;
          FStoredInfoRec.LastModified := FInfo.LastModified;
          FStoredInfoRec.LastCheck := Now;
          FStoredInfo.Write(GetGUID, FStoredInfoRec);
        end;
      end;
    except
      // ToDo: Log error
      FInfo.State := tsFailed;
    end;
  finally
    UpdateListener;
  end;
end;

procedure TUpdateCheckerTaskBase.ClearInfo(var AInfo: TTaskInfo);
begin
  AInfo.State := tsNone;
  AInfo.Name :=  '';
  AInfo.LastModified := 0;
  AInfo.Version := '';
  AInfo.IsUpdatesFound := False;
end;

procedure TUpdateCheckerTaskBase.UpdateListener;
var
  I: Integer;
begin
  for I := 0 to Length(FListener) - 1 do begin
    if Assigned(FListener[I]) then begin
      FListener[I].Update(FInfo);
    end;
  end;
end;

end.
