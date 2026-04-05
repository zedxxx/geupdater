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
    FLastUpdateCheck: TDateTime;
    FUserAgentConfig: IUserAgentConfig;
    FEventLogViewConfig: IEventLogViewConfig;
    FLanguage: string;
  private
    { IAppConfig }
    procedure DoReadConfig;
    procedure DoWriteConfig;

    function GetShowPrevInfoOnly: Boolean;
    procedure SetShowPrevInfoOnly(const AValue: Boolean);

    function GetForceUpdateCheck: Boolean;

    function GetLastUpdateCheck: TDateTime;
    procedure SetLastUpdateCheck(const AValue: TDateTime);

    function GetUserAgentConfig: IUserAgentConfig;
    function GetEventLogViewConfig: IEventLogViewConfig;

    function GetLanguage: string;
    procedure SetLanguage(const AValue: string);
  public
    class function GetIniFileName: string;
    class function GetForceCheckCmdLineFlag: Boolean;
    class function GetCheckIntervalCmdLineValue: Cardinal;
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
  FForceUpdateCheck := Self.GetForceCheckCmdLineFlag;
  FLastUpdateCheck := 0;

  FUserAgentConfig := TUserAgentConfig.Create;
  FEventLogViewConfig := TEventLogViewConfig.Create;

  FLanguage := '';
end;

class function TAppConfig.GetIniFileName: string;
begin
  Result :=
    ExtractFilePath(ParamStr(0)) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
end;

class function TAppConfig.GetForceCheckCmdLineFlag: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do begin
    if SameText(ParamStr(I), '--force-check') then begin
      Result := True;
      Exit;
    end;
  end;
end;

class function TAppConfig.GetCheckIntervalCmdLineValue: Cardinal;
var
  I: Integer;
  VInterval: string;
begin
  Result := 0;
  for I := 1 to ParamCount do begin
    if SameText(ParamStr(I), '--check-interval') then begin
      if I + 1 <= ParamCount then begin
        VInterval := StringReplace(ParamStr(I+1), 'h', '', [rfIgnoreCase]);
        if not TryStrToUInt(VInterval, Result) then begin
          Result := 0;
        end;
      end;
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
    FLastUpdateCheck := VIni.ReadDateTime('Main', 'LastUpdateCheck', FLastUpdateCheck);
    FLanguage := VIni.ReadString('Main', 'Language', FLanguage);

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
    VIni.WriteDateTime('Main', 'LastUpdateCheck', FLastUpdateCheck);
    VIni.WriteString('Main', 'Language', FLanguage);

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

function TAppConfig.GetLanguage: string;
begin
  Result := FLanguage;
end;

function TAppConfig.GetLastUpdateCheck: TDateTime;
begin
  Result := FLastUpdateCheck;
end;

procedure TAppConfig.SetLanguage(const AValue: string);
begin
  FLanguage := AValue;
end;

procedure TAppConfig.SetLastUpdateCheck(const AValue: TDateTime);
begin
  FLastUpdateCheck := AValue;
end;

procedure TAppConfig.SetShowPrevInfoOnly(const AValue: Boolean);
begin
  FShowPrevInfoOnly := AValue;
end;

end.
