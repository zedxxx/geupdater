unit u_DownloadRequest;

interface

uses
  i_DownloadRequest;

type
  TDownloadRequest = class(TInterfacedObject, IDownloadRequest)
  private
    FUrl: string;
    FRawHeaders: string;
  private
    { IDownloadRequest }
    function GetUrl: string;
    function GetRawHeaders: string;
  public
    constructor Create(
      const AUrl: string;
      const ARawHeaders: string
    );
  end;

implementation

{ TDownloadRequest }

constructor TDownloadRequest.Create(const AUrl, ARawHeaders: string);
begin
  Assert(AUrl <> '');
  Assert(ARawHeaders <> '');

  inherited Create;

  FUrl := AUrl;
  FRawHeaders := ARawHeaders;
end;

function TDownloadRequest.GetUrl: string;
begin
  Result := FUrl;
end;

function TDownloadRequest.GetRawHeaders: string;
begin
  Result := FRawHeaders;
end;

end.
