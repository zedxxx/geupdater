unit t_TaskInfo;

interface

type
  TTaskState = (tsNone, tsInProgress, tsHttpError, tsFailed, tsFinished);

  TTaskConf = record
    GUID: string;
    RequestUrl: string;
    DisplayName: string;
  end;

  TTaskInfo = record
    State: TTaskState;
    Conf: TTaskConf;
    LastModified: TDateTime;
    Version: string;
    IsUpdatesFound: Boolean;

    TimeStamp: TDateTime;
    HttpRequest: IInterface;
    HttpResponse: IInterface;
  end;
  PTaskInfo = ^TTaskInfo;

implementation

end.
