unit i_DownloadResponse;

interface

uses
  System.Classes;

type
  IDownloadResponse = interface
    ['{8CAB564B-0CFB-4377-A1BC-0ECEB075154C}']
    function GetCode: Integer;
    property Code: Integer read GetCode;

    function GetRawHeaders: string;
    property RawHeaders: string read GetRawHeaders;

    function GetLastModified: TDateTime;
    property LastModified: TDateTime read GetLastModified;

    function GetBody: Pointer;
    property Body: Pointer read GetBody;

    function GetBodySize: Int64;
    property BodySize: Int64 read GetBodySize;

    function GetBodyAsText: string;
  end;

implementation

end.
