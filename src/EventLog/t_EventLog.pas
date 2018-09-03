unit t_EventLog;

interface

type
  TEventLogItem = record
    TimeStamp: TDateTime;
    GUID: TGUID;
    Version: string;
    LastModified: TDateTime;
  end;
  PEventLogItem = ^TEventLogItem;

implementation

end.
