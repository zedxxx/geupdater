unit t_EventLog;

interface

type
  TEventLogItem = record
    ID: Int64;
    TimeStamp: TDateTime;
    GUID: TGUID;
    Version: string;
    LastModified: TDateTime;
  end;
  PEventLogItem = ^TEventLogItem;

  TEventLogItemArray = TArray<TEventLogItem>;

implementation

end.
