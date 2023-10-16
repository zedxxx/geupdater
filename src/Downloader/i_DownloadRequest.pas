unit i_DownloadRequest;

interface

type
  IDownloadRequest = interface
    ['{CE40077A-50F9-4E23-A929-2997F9CC6DCC}']
    function GetUrl: string;
    property Url: string read GetUrl;

    function GetRawHeaders: string;
    property RawHeaders: string read GetRawHeaders;
  end;

implementation

end.
