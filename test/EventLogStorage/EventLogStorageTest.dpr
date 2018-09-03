program EventLogStorageTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  u_EventLogStorage in '..\..\src\EventLog\u_EventLogStorage.pas',
  i_EventLogStorage in '..\..\src\EventLog\i_EventLogStorage.pas',
  t_EventLog in '..\..\src\EventLog\t_EventLog.pas';

procedure DoTest;
var
  I: Integer;
  VFound: Boolean;
  VItem: TEventLogItem;
  VItems: TArray<TEventLogItem>;
  VStorage: IEventLogStorage;
begin
  VStorage := TEventLogStorageBySQLite.Create('test.db3');

  //for I := 0 to 10000 do begin

  VItem.TimeStamp := Now;
  VItem.GUID := StringToGUID('{C710CD02-86A9-4615-897E-069FE88B0F47}');  //TGuid.NewGuid;
  VItem.Version := ''; //'test' + IntToStr(Random(10000));
  VItem.LastModified := Now;

  //VStorage.AddItem(VItem);
  //end;

  VFound := VStorage.FindLast(VItem.GUID, VItem);

  VItems := VStorage.FetchAll;
end;

begin
  try
    Randomize;
    DoTest;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
