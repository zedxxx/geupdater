unit t_TaskInfo;

interface

type
  TTaskState = (tsNone, tsInProgress, tsFailed, tsFinished);

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
  end;
  PTaskInfo = ^TTaskInfo;

implementation

end.
