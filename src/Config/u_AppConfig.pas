unit u_AppConfig;

interface

uses
  i_AppConfig,
  i_UserAgentConfig,
  i_EventLogViewConfig;

type
  TAppConfig = class(TInterfacedObject, IAppConfig)
  private
    FIniFileName: string;

    FShowPrevInfoOnly: Boolean;
    FForceUpdateCheck: Boolean;
    FUserAgentConfig: IUserAgentConfig;
    FEventLogViewConfig: IEventLogViewConfig;
  private
    { IAppConfig }
    procedure DoReadConfig;
    procedure DoWriteConfig;

    function GetShowPrevInfoOnly: Boolean;
    procedure SetShowPrevInfoOnly(const AValue: Boolean);

    function GetForceUpdateCheck: Boolean;

    function GetUserAgentConfig: IUserAgentConfig;
    function GetEventLogViewConfig: IEventLogViewConfig;
  public
    class function GetIniFileName: string;
    class function GetForceUpdateCmdLineFlag: Boolean;
  public
    constructor Create;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  Winapi.Windows,
  u_UserAgentConfig,
  u_EventLogViewConfig;

{ TAppConfig }

constructor TAppConfig.Create;
begin
  inherited Create;

  FIniFileName := Self.GetIniFileName;

  FShowPrevInfoOnly := False;
  FForceUpdateCheck := Self.GetForceUpdateCmdLineFlag;

  FUserAgentConfig := TUserAgentConfig.Create;
  FEventLogViewConfig := TEventLogViewConfig.Create;
end;

class function TAppConfig.GetIniFileName: string;
begin
  Result :=
    ExtractFilePath(ParamStr(0)) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
end;

class function TAppConfig.GetForceUpdateCmdLineFlag: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do begin
    if SameText(ParamStr(I), '--force-update') then begin
      Result := True;
      Exit;
    end;
  end;
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

    FUserAgentConfig.DoReadConfig(VIni);
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

    FUserAgentConfig.DoWriteConfig(VIni);
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

function TAppConfig.GetUserAgentConfig: IUserAgentConfig;
begin
  Result := FUserAgentConfig;
end;

procedure TAppConfig.SetShowPrevInfoOnly(const AValue: Boolean);
begin
  FShowPrevInfoOnly := AValue;
end;

end.
