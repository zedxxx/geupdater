unit u_EventLogStorage;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  ZConnection,
  ZDataset,
  ZDbcIntfs,
  t_EventLog,
  i_EventLogStorage;

type
  TEventLogStorageBySQLite = class(TInterfacedObject, IEventLogStorage)
  private
    FLock: TCriticalSection;
    FConnection: TZConnection;
    FGuidID: TDictionary<TGUID, Int64>;
    function GetGuidID(const AGuid: TGUID): Int64;
    class function DateTimeToInt64(const AValue: TDateTime): Int64; inline;
    class function Int64ToDateTime(const AValue: Int64): TDateTime; inline;
    class procedure ItemFromQuery(
      const AGuid: TGUID;
      const AQuery: TZQuery;
      out AItem: TEventLogItem
    ); inline;
  private
    { IEventLogStorage }
    procedure AddItem(const AItem: TEventLogItem);
    procedure DeleteItem(const AItemID: Int64);
    function FindLast(const AGuid: TGUID; out AItem: TEventLogItem): Boolean;
    function FetchAll: TArray<TEventLogItem>;
  public
    constructor Create(const ADbFileName: string = '');
    destructor Destroy; override;
  end;

implementation

uses
  Winapi.Windows,
  System.StrUtils,
  System.SysUtils,
  System.DateUtils,
  System.NetEncoding;

const
  cProtocolName = 'sqlite-3';
  cLibraryName = 'sqlite3.dll';
  cStorageFileName = 'data.db3';

const
  cGuidsTableName = 'guids';
  cEventsTableName = 'events';

{ TEventLogStorageBySQLite }

constructor TEventLogStorageBySQLite.Create(const ADbFileName: string);
var
  VQuery: TZQuery;
  VAppPath: string;
  VDbFileName: string;
  VIsDbFileExists: Boolean;
begin
  inherited Create;

  VAppPath := ExtractFilePath(ParamStr(0));

  VDbFileName := ADbFileName;
  if VDbFileName = '' then begin
    VDbFileName := VAppPath + cStorageFileName;
  end;
  VIsDbFileExists := FileExists(VDbFileName);

  FConnection := TZConnection.Create(nil);

  FConnection.Protocol := cProtocolName;
  FConnection.LibraryLocation := VAppPath + cLibraryName;
  FConnection.Database := VDbFileName;

  FConnection.Properties.Add('encoding="UTF-8"');
  FConnection.Properties.Add('foreing_key=on');
  FConnection.Properties.Add('cache_size=-2000');
  FConnection.Properties.Add('synchronous=NORMAL');
  FConnection.Properties.Add('main.journal_mode=WAL');
  FConnection.Properties.Add('main.locking_mode=NORMAL');

  FConnection.TransactIsolationLevel := tiReadCommitted;

  FConnection.Connect;

  if not VIsDbFileExists then begin
    FConnection.ExecuteDirect(
      'CREATE TABLE ' + cGuidsTableName + ' (' +
      'ID    INTEGER PRIMARY KEY AUTOINCREMENT,' +
      'Guid  TEXT UNIQUE NOT NULL)'
    );
    FConnection.ExecuteDirect(
      'CREATE TABLE ' + cEventsTableName + ' (' +
      'ID            INTEGER PRIMARY KEY AUTOINCREMENT,' +
      'GuidID        INTEGER NOT NULL,' +
      'TimeStamp     INTEGER,' +
      'LastModified  INTEDER,' +
      'Version       TEXT,' +
      'FOREIGN KEY (GuidID) REFERENCES ' + cGuidsTableName + '(Guid)'+
      ')'
    );
  end;

  FGuidID := TDictionary<TGUID, Int64>.Create(64);

  // prepare guid cache
  VQuery := TZQuery.Create(nil);
  try
    VQuery.Connection := FConnection;
    VQuery.SQL.Add('SELECT ID, Guid FROM ' + cGuidsTableName);
    VQuery.Open;
    if VQuery.FindFirst then begin
      repeat
        FGuidID.Add(
          StringToGUID(VQuery.FieldByName('Guid').AsString),
          VQuery.FieldByName('ID').AsLargeInt
        );
      until not VQuery.FindNext;
    end;
  finally
    VQuery.Free;
  end;

  FLock := TCriticalSection.Create;
end;

destructor TEventLogStorageBySQLite.Destroy;
begin
  FreeAndNil(FConnection);
  FreeAndNil(FGuidID);
  FreeAndNil(FLock);
  inherited Destroy;
end;

function TEventLogStorageBySQLite.GetGuidID(const AGuid: TGUID): Int64;
var
  VQuery: TZQuery;
begin
  // search in cache first
  if FGuidID.TryGetValue(AGuid, Result) then begin
    // found in cache - this already in db
    Exit;
  end;

  // seems that is a brand new guid
  VQuery := TZQuery.Create(nil);
  try
    VQuery.Connection := FConnection;
    // insert guid into db
    VQuery.SQL.Add('INSERT INTO ' + cGuidsTableName + ' (Guid) VALUES (:g)');
    VQuery.ParamByName('g').AsString := GUIDToString(AGuid);

    VQuery.ExecSQL;
    if VQuery.RowsAffected <> 1 then begin
      raise Exception.Create('Failed insert GUID into ' + cGuidsTableName);
    end;
    // fetch guid id from db
    VQuery.SQL.Text := 'SELECT MAX(ID) AS RowID FROM ' + cGuidsTableName;
    VQuery.Open;
    if not VQuery.FindFirst then begin
      raise Exception.Create('Failed to get last inserted row ID');
    end;
    Result := VQuery.FieldByName('RowID').AsLargeInt;
    // add id to cache
    FGuidID.Add(AGuid, Result);
  finally
    VQuery.Free;
  end;
end;

procedure TEventLogStorageBySQLite.AddItem(const AItem: TEventLogItem);
var
  VGuidID: Int64;
  VQuery: TZQuery;
begin
  FLock.Acquire;
  try
    FConnection.StartTransaction;
    try
      VGuidID := GetGuidID(AItem.GUID);

      VQuery := TZQuery.Create(nil);
      try
        VQuery.Connection := FConnection;

        VQuery.SQL.Text :=
          'INSERT INTO ' + cEventsTableName +
          '(GuidID,TimeStamp,LastModified,Version) VALUES (:gid,:ts,:lm,:v)';

        VQuery.ParamByName('gid').AsLargeInt := VGuidID;
        VQuery.ParamByName('ts').AsLargeInt := DateTimeToInt64(AItem.TimeStamp);
        VQuery.ParamByName('lm').AsLargeInt := DateTimeToInt64(AItem.LastModified);
        VQuery.ParamByName('v').AsAnsiString := UTF8Encode(AItem.Version);

        VQuery.ExecSQL;

        if VQuery.RowsAffected <> 1 then begin
          raise Exception.Create('Failed insert into ' + cEventsTableName);
        end;
      finally
        VQuery.Free;
      end;

      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TEventLogStorageBySQLite.DeleteItem(const AItemID: Int64);
var
  VQuery: TZQuery;
begin
  FLock.Acquire;
  try
    FConnection.StartTransaction;
    try
      VQuery := TZQuery.Create(nil);
      try
        VQuery.Connection := FConnection;

        VQuery.SQL.Text :=
          'DELETE FROM ' + cEventsTableName + ' ' +
          'WHERE ID = :RowID';

        VQuery.ParamByName('RowID').AsLargeInt := AItemID;
        VQuery.ExecSQL;

        if VQuery.RowsAffected <> 1 then begin
          raise Exception.CreateFmt('Failed delete item with ID=%d', [AItemID]);
        end;
      finally
        VQuery.Free;
      end;

      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    FLock.Release;
  end;
end;

class procedure TEventLogStorageBySQLite.ItemFromQuery(
  const AGuid: TGUID;
  const AQuery: TZQuery;
  out AItem: TEventLogItem
);
begin
  AItem.GUID := AGuid;
  AItem.ID := AQuery.FieldByName('ID').AsLargeInt;
  AItem.TimeStamp := Int64ToDateTime(AQuery.FieldByName('TimeStamp').AsLargeInt);
  AItem.LastModified := Int64ToDateTime(AQuery.FieldByName('LastModified').AsLargeInt);
  AItem.Version := UTF8ToString(AQuery.FieldByName('Version').AsAnsiString);
end;

function TEventLogStorageBySQLite.FindLast(
  const AGuid: TGUID;
  out AItem: TEventLogItem
): Boolean;
var
  VGuidID: Int64;
  VQuery: TZQuery;
begin
  FLock.Acquire;
  try
    Result := FGuidID.TryGetValue(AGuid, VGuidID);
    if not Result then begin
      Exit;
    end;

    // fetch data from db
    VQuery := TZQuery.Create(nil);
    try
      VQuery.Connection := FConnection;

      VQuery.SQL.Text :=
        'SELECT ID,TimeStamp,LastModified,Version FROM ' + cEventsTableName + ' ' +
        'WHERE GuidID=' + IntToStr(VGuidID) + ' ' +
        'ORDER BY ID DESC LIMIT 1';
      VQuery.Open;

      Result := VQuery.FindFirst;
      if not Result then begin
        Exit;
      end;

      ItemFromQuery(AGuid, VQuery, AItem);
    finally
      VQuery.Free;
    end;
  finally
    FLock.Release;
  end;
end;

function TEventLogStorageBySQLite.FetchAll: TArray<TEventLogItem>;

  function GetGuidDictByID: TDictionary<Int64,TGUID>;
  var
    I: Integer;
    VArray: TArray<TPair<TGUID,Int64>>;
  begin
    VArray := FGuidID.ToArray;
    Result := TDictionary<Int64,TGUID>.Create(Length(VArray)*2);
    for I := Low(VArray) to High(VArray) do begin
      Result.Add(VArray[I].Value, VArray[I].Key);
    end;
  end;

  function GetItemsCount(const AQuery: TZQuery): Integer;
  begin
    AQuery.Last;
    Result := AQuery.RecordCount;
    AQuery.First;
  end;

var
  I: Integer;
  VCount: Integer;
  VGuidID: Int64;
  VQuery: TZQuery;
  VDict: TDictionary<Int64,TGUID>;
begin
  Result := nil;

  FLock.Acquire;
  try
    VQuery := TZQuery.Create(nil);
    try
      VDict := GetGuidDictByID;

      VQuery.Connection := FConnection;
      VQuery.SQL.Text := 'SELECT ID,GuidID,TimeStamp,LastModified,Version FROM ' + cEventsTableName;
      VQuery.Open;

      VCount := GetItemsCount(VQuery);

      if (VCount > 0) and VQuery.FindFirst then begin
        I := 0;
        SetLength(Result, VCount);
        repeat
          if I >= VCount then begin
            raise Exception.Create('Array length less then Items count!');
          end;
          VGuidID := VQuery.FieldByName('GuidID').AsLargeInt;
          ItemFromQuery(VDict.Items[VGuidID], VQuery, Result[I]);
          Inc(I);
        until not VQuery.FindNext;
      end;
    finally
      VQuery.Free;
    end;
  finally
    FLock.Release;
  end;
end;

class function TEventLogStorageBySQLite.DateTimeToInt64(const AValue: TDateTime): Int64;
begin
  if AValue = 0 then begin
    Result := 0;
  end else begin
    Result := DateTimeToUnix(AValue);
  end;
end;

class function TEventLogStorageBySQLite.Int64ToDateTime(const AValue: Int64): TDateTime;
begin
  if AValue = 0 then begin
    Result := 0.0;
  end else begin
    Result := UnixToDateTime(AValue);
  end;
end;

end.
