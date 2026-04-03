unit u_UserAgentConfig;

interface

uses
  System.SyncObjs,
  System.IniFiles,
  i_UserAgentConfig;

// https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome

type
  TUserAgentConfig = class(TInterfacedObject, IUserAgentConfig)
  public
    const ChromeVersionDefault = '146.0.0.0';
    const DesktopClientVersionDefault = '7.3.7.1094';
  private
    FLock: TCriticalSection;
    FChromeVersion: string;
    FClientVersion: string;
  private
    { IConfigBase }
    procedure DoReadConfig(const AIni: TMemIniFile);
    procedure DoWriteConfig(const AIni: TMemIniFile);
  private
    { IUserAgentConfig }
    function GetChromeUserAgent: string;

    function GetChromeVersion: string;
    procedure SetChromeVersion(const AValue: string);

    function GetDesktopClientUserAgent: string;

    function GetDesktopClientVersion: string;
    procedure SetDesktopClientVersion(const AValue: string);
  public
    class function TrySetVersionValue(var AVersion: string; const AValue: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

const
  cSectionName = 'UserAgent';

{ TUserAgentConfig }

constructor TUserAgentConfig.Create;
begin
  inherited Create;

  FChromeVersion := Self.ChromeVersionDefault;
  FClientVersion := Self.DesktopClientVersionDefault;

  FLock := TCriticalSection.Create;
end;

destructor TUserAgentConfig.Destroy;
begin
  FreeAndNil(FLock);
  inherited;
end;

procedure TUserAgentConfig.DoReadConfig(const AIni: TMemIniFile);

  procedure ReadVersion(const AIdent: string; var ADest: string);
  var
    VStr: string;
  begin
    VStr := AIni.ReadString(cSectionName, AIdent, ADest);
    if VStr <> ADest then begin
      TrySetVersionValue(ADest, VStr);
    end;
  end;

begin
  FLock.Acquire;
  try
    ReadVersion('ChromeVersion', FChromeVersion);
    ReadVersion('DesktopClientVersion', FClientVersion);
  finally
    FLock.Release;
  end;
end;

procedure TUserAgentConfig.DoWriteConfig(const AIni: TMemIniFile);
begin
  FLock.Acquire;
  try
    AIni.WriteString(cSectionName, 'ChromeVersion', FChromeVersion);
    AIni.WriteString(cSectionName, 'DesktopClientVersion', FClientVersion);
  finally
    FLock.Release;
  end;
end;

function TUserAgentConfig.GetChromeUserAgent: string;
begin
  Result :=
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/' + GetChromeVersion + ' Safari/537.36';
end;

function TUserAgentConfig.GetChromeVersion: string;
begin
  FLock.Acquire;
  try
    Result := FChromeVersion;
  finally
    FLock.Release;
  end;
end;

function TUserAgentConfig.GetDesktopClientUserAgent: string;
begin
  Result :=
    'GoogleEarth/' + GetDesktopClientVersion +
    '(Windows;Microsoft Windows (6.2.9200.0);en;kml:2.2;client:Pro;type:default)';
end;

function TUserAgentConfig.GetDesktopClientVersion: string;
begin
  FLock.Acquire;
  try
    Result := FClientVersion;
  finally
    FLock.Release;
  end;
end;

procedure TUserAgentConfig.SetChromeVersion(const AValue: string);
begin
  FLock.Acquire;
  try
    TrySetVersionValue(FChromeVersion, AValue);
  finally
    FLock.Release;
  end;
end;

procedure TUserAgentConfig.SetDesktopClientVersion(const AValue: string);
begin
  FLock.Acquire;
  try
    TrySetVersionValue(FClientVersion, AValue);
  finally
    FLock.Release;
  end;
end;

class function TUserAgentConfig.TrySetVersionValue(var AVersion: string; const AValue: string): Boolean;
var
  I: Integer;
  VNum: Integer;
  VParts: TArray<string>;
begin
  Result := False;

  VParts := AValue.Split(['.']);

  if Length(VParts) <> 4 then begin
    Exit;
  end;

  for I := 0 to High(VParts) do begin
    if not TryStrToInt(VParts[I], VNum) or (VNum < 0) then begin
      Exit;
    end;
  end;

  Result := True;
end;

end.
