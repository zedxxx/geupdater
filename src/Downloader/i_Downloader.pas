unit i_Downloader;

interface

uses
  i_DownloadRequest,
  i_DownloadResponse;

type
  IDownloader = interface
    ['{5F32B1AB-F7AA-4E82-821D-358644054062}']
    function DoHeadRequest(const ARequest: IDownloadRequest): IDownloadResponse;
    function DoGetRequest(const ARequest: IDownloadRequest): IDownloadResponse;
  end;

implementation

end.
