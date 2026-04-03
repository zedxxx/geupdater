unit u_UpdateCheckerTaskBase;

interface

uses
  t_TaskInfo,
  t_EventLog,
  i_AppConfig,
  i_Downloader,
  i_DownloadRequest,
  i_TaskInfoListener,
  i_EventLogStorage,
  i_UpdateCheckerTask;

type
  TUpdateCheckerTaskBase = class(TInterfacedObject, IUpdateCheckerTask)
  protected
    FInfo: TTaskInfo;
    FListener: TArray<ITaskInfoListener>;
    FConfig: IAppConfig;
    FDownloader: IDownloader;
    FEventLog: IEventLogStorage;
    FPrevInfo: TEventLogItem;
    FPrevInfoExists: Boolean;
    procedure ClearInfo(var AInfo: TTaskInfo);
    procedure UpdateListener;
    function BuildRequest: IDownloadRequest;
  protected
    function GetConf: TTaskConf; virtual; abstract;
    function GetHeaders: string; virtual; abstract;
    procedure DoExecute; virtual; abstract;
  private
    { IUpdateCheckerTask }
    procedure Execute(const AShowPrevInfoOnly: Boolean);
  public
    constructor Create(
      const AConfig: IAppConfig;
      const ADownloader: IDownloader;
      const AEventLog: IEventLogStorage;
      const AListener: TArray<ITaskInfoListener>
    );
    procedure AfterConstruction; override;
  end;

implementation

uses
  SysUtils,
  u_DownloadRequest,
  u_DateTimeUtils;

{ TUpdateCheckerTaskBase }

constructor TUpdateCheckerTaskBase.Create(
  const AConfig: IAppConfig;
  const ADownloader: IDownloader;
  const AEventLog: IEventLogStorage;
  const AListener: TArray<ITaskInfoListener>
);
begin
  Assert(AConfig <> nil);
  Assert(ADownloader <> nil);
  Assert(AEventLog <> nil);

  inherited Create;

  FConfig := AConfig;
  FDownloader := ADownloader;
  FEventLog := AEventLog;
  FListener := AListener;

  ClearInfo(FInfo);
end;

procedure TUpdateCheckerTaskBase.AfterConstruction;
begin
  inherited;
  FInfo.Conf := GetConf;
  FPrevInfoExists := FEventLog.FindLast(StringToGUID(FInfo.Conf.GUID), FPrevInfo);
  UpdateListener;
end;

function TUpdateCheckerTaskBase.BuildRequest: IDownloadRequest;
begin
  Result := TDownloadRequest.Create(FInfo.Conf.RequestUrl, GetHeaders);
end;

procedure TUpdateCheckerTaskBase.Execute(const AShowPrevInfoOnly: Boolean);
var
  VItem: TEventLogItem;
  VTimeStamp: TDateTime;
begin
  if AShowPrevInfoOnly then begin
    FInfo.State := tsFinished;
    if FPrevInfoExists then begin
      FInfo.Version := FPrevInfo.Version;
      FInfo.TimeStamp := FPrevInfo.TimeStamp;
    end;
    UpdateListener;
    Exit;
  end;

  FInfo.State := tsInProgress;
  UpdateListener;
  try
    try
      DoExecute;
      case FInfo.State of
        tsFinished: begin
          VTimeStamp := LocalTimeToUTC(Now);
          if FInfo.IsUpdatesFound or not FPrevInfoExists then begin
            VItem.TimeStamp := VTimeStamp;
            VItem.GUID := StringToGUID(FInfo.Conf.GUID);
            VItem.Version := FInfo.Version;
            VItem.LastModified := FInfo.LastModified;
            FEventLog.AddItem(VItem);
          end;
          if FInfo.IsUpdatesFound then begin
            FInfo.TimeStamp := VTimeStamp;
          end else
          if FPrevInfoExists then begin
            FInfo.TimeStamp := FPrevInfo.TimeStamp;
          end;
        end;

        tsHttpError: begin
          // ToDo: Log http response
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
  AInfo.Conf.GUID := GUIDToString(TGUID.Empty);
  AInfo.Conf.DisplayName :=  '';
  AInfo.Conf.RequestUrl :=  '';
  AInfo.LastModified := 0;
  AInfo.Version := '';
  AInfo.IsUpdatesFound := False;
  AInfo.TimeStamp := 0;
  AInfo.HttpRequest := nil;
  AInfo.HttpResponse := nil;
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
