unit t_TaskInfo;

interface

type
  TTaskState = (tsNone, tsInProgress, tsFailed, tsFinished);

  TTaskInfo = record
    State: TTaskState;
    Name: string;
    LastModified: TDateTime;
    Version: string;
    IsUpdatesFound: Boolean;
  end;
  PTaskInfo = ^TTaskInfo;

implementation

end.
