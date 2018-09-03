unit u_UpdateCheckerTaskBase;

interface

uses
  t_TaskInfo,
  t_EventLog,
  i_Downloader,
  i_TaskInfoListener,
  i_EventLogStorage,
  i_UpdateCheckerTask;

type
  TUpdateCheckerTaskBase = class(TInterfacedObject, IUpdateCheckerTask)
  protected
    FInfo: TTaskInfo;
    FListener: TArray<ITaskInfoListener>;
    FDownloader: IDownloader;
    FEventLog: IEventLogStorage;
    FPrevInfo: TEventLogItem;
    FPrevInfoExists: Boolean;
    procedure ClearInfo(var AInfo: TTaskInfo);
    procedure UpdateListener;
  protected
    function GetConf: TTaskConf; virtual; abstract;
    procedure DoExecute; virtual; abstract;
  private
    { IUpdateCheckerTask }
    procedure Execute;
  public
    constructor Create(
      const ADownloader: IDownloader;
      const AEventLog: IEventLogStorage;
      const AListener: TArray<ITaskInfoListener>
    );
    procedure AfterConstruction; override;
  end;

implementation

uses
  SysUtils,
  u_DateTimeUtils;

{ TUpdateCheckerTaskBase }

constructor TUpdateCheckerTaskBase.Create(
  const ADownloader: IDownloader;
  const AEventLog: IEventLogStorage;
  const AListener: TArray<ITaskInfoListener>
);
begin
  Assert(ADownloader <> nil);
  Assert(AEventLog <> nil);

  inherited Create;

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

procedure TUpdateCheckerTaskBase.Execute;
var
  VItem: TEventLogItem;
begin
  FInfo.State := tsInProgress;
  UpdateListener;
  try
    try
      DoExecute;
      if FInfo.State = tsFinished then begin
        if FInfo.IsUpdatesFound or not FPrevInfoExists then begin
          VItem.TimeStamp := LocalTimeToUTC(Now);
          VItem.GUID := StringToGUID(FInfo.Conf.GUID);
          VItem.Version := FInfo.Version;
          VItem.LastModified := FInfo.LastModified;
          FEventLog.AddItem(VItem);
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
