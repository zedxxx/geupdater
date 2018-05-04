unit i_Downloader;

interface

uses
  i_DownloadResponse;

type
  IDownloader = interface
    ['{5F32B1AB-F7AA-4E82-821D-358644054062}']
    function DoHeadRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;

    function DoGetRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;
  end;

implementation

end.
