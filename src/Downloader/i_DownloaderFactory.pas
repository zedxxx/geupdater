unit i_DownloaderFactory;

interface

uses
  i_Downloader;

type
  IDownloaderFactory = interface
    ['{24512E43-C1FC-4D8B-BB96-DBB82B6F51E3}']
    function BuildDownloader: IDownloader;

    function BuildDownloaderWithCache: IDownloader;
  end;

implementation

end.
