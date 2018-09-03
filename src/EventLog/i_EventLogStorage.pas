unit i_EventLogStorage;

interface

uses
  t_EventLog;

type
  IEventLogStorage = interface
    ['{7E3712C5-D54D-40E4-964C-CB055B54A752}']
    procedure AddItem(const AItem: TEventLogItem);
    function FindLast(const AGuid: TGUID; out AItem: TEventLogItem): Boolean;
    function FetchAll: TArray<TEventLogItem>;
  end;

implementation

end.
