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
  i_EventLogStorage,
  u_GuidDictionary;

type
  TEventLogStorageBySQLite = class(TInterfacedObject, IEventLogStorage)
  private
    FLock: TCriticalSection;
    FConnection: TZConnection;
    FGuidDict: TGuidDictionary;
    class function DateTimeToInt64(const AValue: TDateTime): Int64; inline;
    class function Int64ToDateTime(const AValue: Int64): TDateTime; inline;
    class procedure ItemFromQuery(const AGuid: TGUID; const AQuery: TZQuery; out AItem: TEventLogItem); inline;
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
  cProtocolName = 'sqlite';
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
  FConnection.LibraryLocation := cLibraryName;
  FConnection.Database := VDbFileName;

  FConnection.Properties.Add('encoding = "UTF-8"');
  FConnection.Properties.Add('foreing_keys = ON');
  FConnection.Properties.Add('cache_size = -2000');
  FConnection.Properties.Add('synchronous = NORMAL');
  FConnection.Properties.Add('main.journal_mode = WAL');
  FConnection.Properties.Add('main.locking_mode = NORMAL');

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
      'LastModified  INTEGER,' +
      'Version       TEXT,' +
      'FOREIGN KEY (GuidID) REFERENCES ' + cGuidsTableName + '(ID)'+
      ')'
    );
  end;

  FGuidDict := TGuidDictionary.Create(64);

  // prepare guid cache
  VQuery := TZQuery.Create(nil);
  try
    VQuery.Connection := FConnection;
    VQuery.SQL.Add('SELECT ID, Guid FROM ' + cGuidsTableName);
    VQuery.Open;
    if VQuery.FindFirst then begin
      repeat
        FGuidDict.Add(
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
  FreeAndNil(FGuidDict);
  FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TEventLogStorageBySQLite.AddItem(const AItem: TEventLogItem);

  function GetGuidId(const AGuid: TGUID): Int64;
  var
    VQuery: TZQuery;
    VGuidStr: string;
  begin
    // search in cache first
    if FGuidDict.TryGetIdByGuid(AGuid, Result) then begin
      Exit;
    end;

    VGuidStr := GUIDToString(AGuid);

    VQuery := TZQuery.Create(nil);
    try
      VQuery.Connection := FConnection;

      // insert guid into db
      VQuery.SQL.Text := 'INSERT INTO ' + cGuidsTableName + ' (Guid) VALUES (:g)';
      VQuery.ParamByName('g').AsString := VGuidStr;

      VQuery.ExecSQL;
      if VQuery.RowsAffected <> 1 then begin
        raise Exception.CreateFmt('Failed insert GUID %s into %s', [VGuidStr, cGuidsTableName]);
      end;

      // fetch guid id from db
      VQuery.SQL.Text := 'SELECT ID FROM ' + cGuidsTableName + ' WHERE Guid = :g';
      VQuery.ParamByName('g').AsString := VGuidStr;

      VQuery.Open;
      if not VQuery.FindFirst then begin
        raise Exception.CreateFmt('Failed to get ID for last inserted GUID %s from %s', [VGuidStr, cGuidsTableName]);
      end;

      Result := VQuery.FieldByName('ID').AsLargeInt;

      // add id to cache
      FGuidDict.Add(AGuid, Result);
    finally
      VQuery.Free;
    end;
  end;

var
  VGuidId: Int64;
  VQuery: TZQuery;
begin
  FLock.Acquire;
  try
    FConnection.StartTransaction;
    try
      VGuidId := GetGuidId(AItem.GUID);

      VQuery := TZQuery.Create(nil);
      try
        VQuery.Connection := FConnection;

        VQuery.SQL.Text :=
          'INSERT INTO ' + cEventsTableName +
          '(GuidID,TimeStamp,LastModified,Version) VALUES (:gid,:ts,:lm,:v)';

        VQuery.ParamByName('gid').AsLargeInt := VGuidId;
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
          'WHERE ID = :id';

        VQuery.ParamByName('id').AsLargeInt := AItemID;
        VQuery.ExecSQL;

        if VQuery.RowsAffected <> 1 then begin
          raise Exception.CreateFmt('Failed delete item with ID = %d from %s', [AItemID, cEventsTableName]);
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
  VGuidId: Int64;
  VQuery: TZQuery;
begin
  FLock.Acquire;
  try
    Result := FGuidDict.TryGetIdByGuid(AGuid, VGuidId);
    if not Result then begin
      Exit;
    end;

    // fetch data from db
    VQuery := TZQuery.Create(nil);
    try
      VQuery.Connection := FConnection;

      VQuery.SQL.Text :=
        'SELECT ID,TimeStamp,LastModified,Version FROM ' + cEventsTableName + ' ' +
        'WHERE GuidID = :gid ' +
        'ORDER BY ID DESC LIMIT 1';
      VQuery.ParamByName('gid').AsLargeInt := VGuidId;

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

  procedure GrowResultArray(const ANewCount: Integer);
  var
    VCapacity: Integer;
  begin
    VCapacity := Length(Result);
    if ANewCount > VCapacity then begin
      VCapacity := System.SysUtils.GrowCollection(VCapacity, ANewCount);
      SetLength(Result, VCapacity); // grow
    end;
  end;

var
  I: Integer;
  VGuid: TGUID;
  VGuidId: Int64;
  VQuery: TZQuery;
begin
  Result := nil;

  FLock.Acquire;
  try
    VQuery := TZQuery.Create(nil);
    try
      VQuery.Connection := FConnection;
      VQuery.SQL.Text := 'SELECT ID,GuidID,TimeStamp,LastModified,Version FROM ' + cEventsTableName;
      VQuery.Open;

      if VQuery.FindFirst then begin
        I := 0;
        SetLength(Result, 1024);

        repeat
          GrowResultArray(I+1);

          VGuidId := VQuery.FieldByName('GuidID').AsLargeInt;
          if FGuidDict.TryGetGuidById(VGuidId, VGuid) then begin
            ItemFromQuery(VGuid, VQuery, Result[I]);
            Inc(I);
          end else begin
            raise Exception.CreateFmt('Can''t find GUID for GuidID = %d', [VGuidId])
          end;
        until not VQuery.FindNext;

        SetLength(Result, I);
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
