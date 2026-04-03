unit u_AppConfig;

interface

uses
  i_AppConfig,
  i_EventLogViewConfig;

type
  TAppConfig = class(TInterfacedObject, IAppConfig)
  private
    FIniFileName: string;

    FShowPrevInfoOnly: Boolean;
    FForceUpdateCheck: Boolean;
    FEventLogViewConfig: IEventLogViewConfig;
  public
    procedure DoReadConfig;
    procedure DoWriteConfig;

    function GetShowPrevInfoOnly: Boolean;
    procedure SetShowPrevInfoOnly(const AValue: Boolean);

    function GetForceUpdateCheck: Boolean;

    function GetEventLogViewConfig: IEventLogViewConfig;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  u_UserAgentInfo,
  u_EventLogViewConfig;

{ TAppConfig }

constructor TAppConfig.Create;
begin
  inherited Create;

  FShowPrevInfoOnly := False;
  FForceUpdateCheck := False; // todo

  FIniFileName :=
    ExtractFilePath(ParamStr(0)) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');

  FEventLogViewConfig := TEventLogViewConfig.Create;
end;

destructor TAppConfig.Destroy;
begin

  inherited;
end;

procedure TAppConfig.DoReadConfig;
var
  VIni: TMemIniFile;
begin
  if not FileExists(FIniFileName) then begin
    Exit;
  end;

  VIni := TMemIniFile.Create(FIniFileName, TEncoding.UTF8);
  try
    FShowPrevInfoOnly := VIni.ReadBool('Main', 'ShowPrevInfoOnly', FShowPrevInfoOnly);

    GUserAgentInfo.DoReadConfig; // todo
    FEventLogViewConfig.DoReadConfig(VIni);
  finally
    VIni.Free;
  end;
end;

procedure TAppConfig.DoWriteConfig;
var
  VIni: TMemIniFile;
  VHandle: THandle;
begin
  if not FileExists(FIniFileName) then begin
    VHandle := FileCreate(FIniFileName);
    if VHandle = INVALID_HANDLE_VALUE then begin
      RaiseLastOSError;
    end;
    FileClose(VHandle);
  end;

  VIni := TMemIniFile.Create(FIniFileName, TEncoding.UTF8);
  try
    VIni.WriteBool('Main', 'ShowPrevInfoOnly', FShowPrevInfoOnly);

    FEventLogViewConfig.DoWriteConfig(VIni);

    VIni.UpdateFile;
  finally
    VIni.Free;
  end;
end;

function TAppConfig.GetEventLogViewConfig: IEventLogViewConfig;
begin
  Result := FEventLogViewConfig;
end;

function TAppConfig.GetForceUpdateCheck: Boolean;
begin
  Result := FForceUpdateCheck;
end;

function TAppConfig.GetShowPrevInfoOnly: Boolean;
begin
  Result := FShowPrevInfoOnly;
end;

procedure TAppConfig.SetShowPrevInfoOnly(const AValue: Boolean);
begin
  FShowPrevInfoOnly := AValue;
end;

end.
