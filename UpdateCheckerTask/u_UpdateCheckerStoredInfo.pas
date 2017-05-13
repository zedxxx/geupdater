unit u_UpdateCheckerStoredInfo;

interface

uses
  IniFiles,
  SyncObjs,
  i_UpdateCheckerStoredInfo;

type
  TUpdateCheckerStoredInfo = class(TInterfacedObject, IUpdateCheckerStoredInfo)
  private
    FIni: TCustomIniFile;
    FLock: TCriticalSection;
    function OpenIniFile(const AFileName: string): TCustomIniFile;
    function GUIDToSectionName(const AGUID: TGUID): string;
  private
    { IUpdateCheckerStoredInfo }
    function Read(const AGUID: TGUID; out AInfo: TStoredInfoRec): Boolean;
    procedure Write(const AGUID: TGUID; const AInfo: TStoredInfoRec);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
  end;

implementation

uses
  Classes,
  SysUtils;

{ TUpdateCheckerStoredInfo }

constructor TUpdateCheckerStoredInfo.Create(const AFileName: string);
begin
  Assert(AFileName <> '');
  inherited Create;
  FLock := TCriticalSection.Create;
  FIni := OpenIniFile(AFileName);
end;

destructor TUpdateCheckerStoredInfo.Destroy;
begin
  if Assigned(FIni) then begin
    try
      FIni.UpdateFile;
    except
      //
    end;
  end;
  FreeAndNil(FIni);
  FreeAndNil(FLock);
  inherited;
end;

function TUpdateCheckerStoredInfo.GUIDToSectionName(const AGUID: TGUID): string;
begin
  Result := AGUID.ToString;
  Result := StringReplace(Result, '{', '', []);
  Result := StringReplace(Result, '}', '', []);
  Result := StringReplace(Result, '-', '_', [rfReplaceAll]);
end;

function TUpdateCheckerStoredInfo.OpenIniFile(const AFileName: string): TCustomIniFile;
var
  VFileStream: TFileStream;
begin
  if not FileExists(AFileName) then begin
    VFileStream := TFileStream.Create(AFileName, fmCreate);
    FreeAndNil(VFileStream);
    Assert(FileExists(AFileName));
  end;
  Result := TMemIniFile.Create(AFileName);
end;

function TUpdateCheckerStoredInfo.Read(
  const AGUID: TGUID;
  out AInfo: TStoredInfoRec
): Boolean;
var
  VSection: string;
begin
  FLock.Acquire;
  try
    VSection := GUIDToSectionName(AGUID);
    Result := FIni.SectionExists(VSection);
    if Result then begin
      AInfo.Version := FIni.ReadString(VSection, 'Version', '');
      AInfo.LastModified := FIni.ReadDateTime(VSection, 'LastModified', 0);
      AInfo.LastCheck := FIni.ReadDateTime(VSection, 'LastCheck', 0);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TUpdateCheckerStoredInfo.Write(
  const AGUID: TGUID;
  const AInfo: TStoredInfoRec
);
var
  VSection: string;
begin
  FLock.Acquire;
  try
    VSection := GUIDToSectionName(AGUID);
    FIni.WriteString(VSection, 'Version', AInfo.Version);
    FIni.WriteDateTime(VSection, 'LastModified', AInfo.LastModified);
    FIni.WriteDateTime(VSection, 'LastCheck', AInfo.LastCheck);
  finally
    FLock.Release;
  end;
end;

end.
