unit i_AppConfig;

interface

uses
  i_UserAgentConfig,
  i_EventLogViewConfig;

type
  IAppConfig = interface
    ['{757D7F93-7700-427A-830D-BBA18FD20556}']
    procedure DoReadConfig;
    procedure DoWriteConfig;

    function GetShowPrevInfoOnly: Boolean;
    procedure SetShowPrevInfoOnly(const AValue: Boolean);
    property ShowPrevInfoOnly: Boolean read GetShowPrevInfoOnly write SetShowPrevInfoOnly;

    function GetForceUpdateCheck: Boolean;
    property ForceUpdateCheck: Boolean read GetForceUpdateCheck;

    function GetUserAgentConfig: IUserAgentConfig;
    property UserAgentConfig: IUserAgentConfig read GetUserAgentConfig;

    function GetEventLogViewConfig: IEventLogViewConfig;
    property EventLogViewConfig: IEventLogViewConfig read GetEventLogViewConfig;
  end;

implementation

end.
