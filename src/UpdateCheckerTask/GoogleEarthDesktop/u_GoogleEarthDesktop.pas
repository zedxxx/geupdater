unit u_GoogleEarthDesktop;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_EventLogStorage,
  u_UpdateCheckerTaskBase;

type
  TGoogleEarthDesktopCheckType = (
    gecctEarth,
    gecctHistory,
    gecctSky,
    gecctMars,
    gecctMoon,
    gecctClient
  );

  TGoogleEarthDesktop = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleEarthDesktopCheckType;
    function GetHeaders: string;
    function IsClientCheck: Boolean; inline;
  protected
    function GetConf: TTaskConf; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleEarthDesktopCheckType;
      const ADownloader: IDownloader;
      const AEventLog: IEventLogStorage;
      const AListener: TArray<ITaskInfoListener>
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  c_UserAget,
  c_UpdateCheckerTask,
  i_DownloadResponse,
  u_DateTimeUtils;

const
  cLang = 'hl=en-GB&gl=us';

  cTaskConf: array [TGoogleEarthDesktopCheckType] of TTaskConf = (
    (GUID:        cGoogleEarthDesktopEathGUID;
     RequestUrl:  'http://kh.google.com/dbRoot.v5?' + cLang;
     DisplayName: 'Earth'),

    (GUID:        cGoogleEarthDesktopHistoryGUID;
     RequestUrl:  'http://khmdb.google.com/dbRoot.v5?db=tm&' + cLang;
     DisplayName: 'History'),

    (GUID:        cGoogleEarthDesktopSkyGUID;
     RequestUrl:  'http://khmdb.google.com/dbRoot.v5?db=sky&' + cLang;
     DisplayName: 'Sky'),

    (GUID:        cGoogleEarthDesktopMarsGUID;
     RequestUrl:  'http://khmdb.google.com/dbRoot.v5?db=mars&' + cLang;
     DisplayName: 'Mars'),

    (GUID:        cGoogleEarthDesktopMoonGUID;
     RequestUrl:  'http://khmdb.google.com/dbRoot.v5?db=moon&' + cLang;
     DisplayName: 'Moon'),

    (GUID:        cGoogleEarthDesktopClientGUID;
     RequestUrl:  'http://dl.google.com/earth/client/advanced/current/GoogleEarthProWin.exe';
     DisplayName: 'Client')
  );

{ TGoogleEarthDesktop }

constructor TGoogleEarthDesktop.Create(
  const ACheckType: TGoogleEarthDesktopCheckType;
  const ADownloader: IDownloader;
  const AEventLog: IEventLogStorage;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AEventLog, AListener);
  FCheckType := ACheckType;
end;

function TGoogleEarthDesktop.GetConf: TTaskConf;
begin
  Result := cTaskConf[FCheckType];
end;

function TGoogleEarthDesktop.IsClientCheck: Boolean;
begin
  Result := FCheckType = gecctClient;
end;

function TGoogleEarthDesktop.GetHeaders: string;
var
  VIfModifiedSince: string;
begin
  if IsClientCheck then begin
    Result :=
      'User-Agent: ' + cBrowserUserAgent + #13#10 +
      'Accept: */*' + #13#10 +
      'Accept-Encoding: gzip,deflate' + #13#10 +
      'Accept-Language: en-us,en,*';
  end else begin
    if FPrevInfoExists and (FPrevInfo.LastModified <> 0) then begin
      VIfModifiedSince :=
        'If-Modified-Since: ' + DateTimeToRFC1123(FPrevInfo.LastModified) + #13#10;
    end else begin
      VIfModifiedSince := '';
    end;
    Result :=
      'User-Agent: ' + cDesktopClientUserAgent + #13#10 +
      VIfModifiedSince +
      'Accept: application/vnd.google-earth.kml+xml, application/vnd.google-earth.kmz, image/*, */*' + #13#10 +
      'Accept-Encoding: gzip,deflate' + #13#10 +
      'Accept-Language: en-us,en,*' + #13#10 +
      'Accept-Charset: iso-8859-1,*,utf-8';
  end;
end;

function GetDbRootVersion(const AData: Pointer; const ASize: Int64): string;
var
  VPtr: PByte;
  VVersion: PWord;
begin
  Result := '';
  VPtr := AData;
  Assert(VPtr <> nil);
  if ASize > 8 then begin
    Inc(VPtr, 6);
    VVersion := PWord(VPtr);
    Result := IntToStr(VVersion^ xor $4200);
  end;
end;

procedure TGoogleEarthDesktop.DoExecute;
var
  VUrl: string;
  VRawHeaders: string;
  VResponse: IDownloadResponse;
begin
  VUrl := FInfo.Conf.RequestUrl;
  VRawHeaders := GetHeaders;

  if IsClientCheck then begin
    VResponse := FDownloader.DoHeadRequest(VUrl, VRawHeaders);
  end else begin
    VResponse := FDownloader.DoGetRequest(VUrl, VRawHeaders);
  end;

  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;

    if IsClientCheck then begin
      FInfo.Version := '-';
      FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.LastModified <> FInfo.LastModified);
    end else begin
      FInfo.Version := GetDbRootVersion(VResponse.Body, VResponse.BodySize);
      FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.Version <> FInfo.Version);
    end;
  end else if VResponse.Code = 304 then begin // Not Modified
    Assert(FPrevInfoExists);
    FInfo.State := tsFinished;
    FInfo.LastModified := FPrevInfo.LastModified;
    FInfo.Version := FPrevInfo.Version;
  end else begin
    FInfo.State := tsFailed;
  end;
end;

end.
