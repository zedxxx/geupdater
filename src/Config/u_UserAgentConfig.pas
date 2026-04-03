unit u_UserAgentConfig;

interface

uses
  System.IniFiles,
  i_UserAgentConfig;

// https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome

type
  TUserAgentConfig = class(TInterfacedObject, IUserAgentConfig)
  private
    FChromeVersion: string;
    FClientVersion: string;
  public
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
    constructor Create;
  end;

implementation

uses
  System.SysUtils;

const
  cChromeVersionDefault = '146.0.0.0';
  cDesktopClientVersionDefault = '7.3.7.1094';

{ TUserAgentConfig }

constructor TUserAgentConfig.Create;
begin
  inherited Create;

  FChromeVersion := cChromeVersionDefault;
  FClientVersion := cDesktopClientVersionDefault;
end;

procedure TUserAgentConfig.DoReadConfig(const AIni: TMemIniFile);
begin
  FChromeVersion := AIni.ReadString('Main', 'ChromeVersion', FChromeVersion);
  FClientVersion := AIni.ReadString('Main', 'DesktopClientVersion', FClientVersion);
end;

procedure TUserAgentConfig.DoWriteConfig(const AIni: TMemIniFile);
begin
  // todo
end;

function TUserAgentConfig.GetChromeUserAgent: string;
begin
  Result :=
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/' + FChromeVersion + ' Safari/537.36';
end;

function TUserAgentConfig.GetChromeVersion: string;
begin
  Result := FChromeVersion;
end;

function TUserAgentConfig.GetDesktopClientUserAgent: string;
begin
  Result :=
    'GoogleEarth/' + FClientVersion +
    '(Windows;Microsoft Windows (6.2.9200.0);en;kml:2.2;client:Pro;type:default)';
end;

function TUserAgentConfig.GetDesktopClientVersion: string;
begin
  Result := FClientVersion;
end;

procedure TUserAgentConfig.SetChromeVersion(const AValue: string);
begin
  //
end;

procedure TUserAgentConfig.SetDesktopClientVersion(const AValue: string);
begin
  //
end;

end.
