unit u_UserAgentInfo;

interface

// https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome

type
  TUserAgentInfo = record
  private
    FChromeVersion: string;
    FClientVersion: string;
  public
    procedure DoReadConfig;
  public
    function GetChromeUserAgent: string;

    function GetDesktopClientVersion: string;
    function GetDesktopClientUserAgent: string;
  end;

var
  GUserAgentInfo: TUserAgentInfo;

implementation

uses
  System.SysUtils,
  System.IniFiles;

const
  cChromeVersionDefault = '146.0.0.0';
  cDesktopClientVersionDefault = '7.3.7.1094';

{ TUserAgentInfo }

procedure TUserAgentInfo.DoReadConfig;
var
  VIni: TMemIniFile;
  VIniFileName: string;
begin
  VIniFileName :=
    ExtractFilePath(ParamStr(0)) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');

  if not FileExists(VIniFileName) then begin
    Exit;
  end;

  VIni := TMemIniFile.Create(VIniFileName, TEncoding.UTF8);
  try
    FChromeVersion := VIni.ReadString('Main', 'ChromeVersion', FChromeVersion);
    FClientVersion := VIni.ReadString('Main', 'DesktopClientVersion', FClientVersion);
  finally
    VIni.Free;
  end;
end;

function TUserAgentInfo.GetChromeUserAgent: string;
begin
  Result :=
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/' + FChromeVersion + ' Safari/537.36';
end;

function TUserAgentInfo.GetDesktopClientVersion: string;
begin
  Result := FClientVersion;
end;

function TUserAgentInfo.GetDesktopClientUserAgent: string;
begin
  Result :=
    'GoogleEarth/' + FClientVersion +
    '(Windows;Microsoft Windows (6.2.9200.0);en;kml:2.2;client:Pro;type:default)';
end;

initialization
  GUserAgentInfo.FChromeVersion := cChromeVersionDefault;
  GUserAgentInfo.FClientVersion := cDesktopClientVersionDefault;

end.
