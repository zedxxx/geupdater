unit i_UserAgentConfig;

interface

uses
  i_ConfigBase;

type
  IUserAgentConfig = interface(IConfigBase)
    ['{84D930E8-AD2E-43C4-93A4-524EA9BEA356}']

    function GetChromeUserAgent: string;
    property ChromeUserAgent: string read GetChromeUserAgent;

    function GetChromeVersion: string;
    procedure SetChromeVersion(const AValue: string);
    property ChromeVersion: string read GetChromeVersion write SetChromeVersion;

    function GetDesktopClientUserAgent: string;
    property DesktopClientUserAgent: string read GetDesktopClientUserAgent;

    function GetDesktopClientVersion: string;
    procedure SetDesktopClientVersion(const AValue: string);
    property DesktopClientVersion: string read GetDesktopClientVersion write SetDesktopClientVersion;
  end;

implementation

end.
