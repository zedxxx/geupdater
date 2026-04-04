unit u_GoogleEarthWeb;

interface

uses
  t_TaskInfo,
  i_AppConfig,
  i_Downloader,
  i_TaskInfoListener,
  i_EventLogStorage,
  u_UpdateCheckerTaskBase;

type
  TGoogleEarthWebCheckType = (gewctEarth, gewctClient);

  TGoogleEarthWeb = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleEarthWebCheckType;
    function IsClientCheck: Boolean; inline;
  private
    class function GetVersion(const AData: Pointer; const ASize: Int64): string;
    class function GetClientDataVersion(const AText: string): string;
    class function GetClientVersion(const AText: string): string;
  protected
    function GetConf: TTaskConf; override;
    function GetHeaders: string; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleEarthWebCheckType;
      const AConfig: IAppConfig;
      const ADownloader: IDownloader;
      const AEventLog: IEventLogStorage;
      const AListener: TArray<ITaskInfoListener>
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  RegularExpressions,
  c_UpdateCheckerTask,
  i_DownloadRequest,
  i_DownloadResponse,
  u_DateTimeUtils,
  u_DownloadRequest,
  u_PlanetoidMetadata;

const
  cTaskConf: array [TGoogleEarthWebCheckType] of TTaskConf = (
    (GUID:        cGoogleEarthWebEarthGUID;
     RequestUrl:  'https://kh.google.com/rt/earth/PlanetoidMetadata';
     DisplayName: 'Earth'),

    (GUID:        cGoogleEarthWebClientGUID;
     RequestUrl:  'https://earth.google.com/web';
     DisplayName: 'Client')
  );

{ TGoogleEarthWeb }

constructor TGoogleEarthWeb.Create(
  const ACheckType: TGoogleEarthWebCheckType;
  const AConfig: IAppConfig;
  const ADownloader: IDownloader;
  const AEventLog: IEventLogStorage;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(AConfig, ADownloader, AEventLog, AListener);
  FCheckType := ACheckType;
end;

function TGoogleEarthWeb.IsClientCheck: Boolean;
begin
  Result := FCheckType = gewctClient;
end;

function TGoogleEarthWeb.GetConf: TTaskConf;
begin
  Result := cTaskConf[FCheckType];
end;

function TGoogleEarthWeb.GetHeaders: string;
var
  VIfModifiedSince: string;
begin
  VIfModifiedSince := '';

  if IsClientCheck and FPrevInfoExists and (FPrevInfo.LastModified <> 0) then begin
    VIfModifiedSince :=  'If-Modified-Since: ' + DateTimeToHttpDate(FPrevInfo.LastModified) + #13#10;
  end;

  Result :=
    'User-Agent: ' + FConfig.UserAgentConfig.ChromeUserAgent + #13#10 +
    VIfModifiedSince +
    'Accept: */*' + #13#10 +
    'Accept-Language: en-us,en,*';
end;

procedure TGoogleEarthWeb.DoExecute;
var
  VRequest: IDownloadRequest;
  VResponse: IDownloadResponse;

  procedure _FetchClientVersion;
  var
    VRequestUrl: string;
  begin
    // Step 1: fetch "data-version"
    FInfo.Version := GetClientDataVersion(VResponse.GetBodyAsText);

    if FInfo.Version = '' then begin
      Exit;
    end;

    // Step 2: fetch actual value of client version
    VRequestUrl := Format('https://earth.google.com/static/multi-threaded/versions/%s/main.dart.js', [FInfo.Version]);

    VRequest := TDownloadRequest.Create(VRequestUrl, GetHeaders);;
    VResponse := FDownloader.DoGetRequest(VRequest);

    FInfo.HttpRequest := VRequest;
    FInfo.HttpResponse := VResponse;

    if VResponse.Code = 200 then begin
      FInfo.LastModified := VResponse.LastModified;
      FInfo.Version := GetClientVersion(VResponse.GetBodyAsText);
    end else
    if VResponse.Code = 304 then begin
      Assert(FPrevInfoExists);
      FInfo.LastModified := FPrevInfo.LastModified;
      FInfo.Version := FPrevInfo.Version;
    end else begin
      // Use "data-version" as client version on error
    end;
  end;

begin
  VRequest := BuildRequest;
  VResponse := FDownloader.DoGetRequest(VRequest);

  FInfo.HttpRequest := VRequest;
  FInfo.HttpResponse := VResponse;

  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;
    if IsClientCheck then begin
      _FetchClientVersion;
    end else begin
      FInfo.Version := GetVersion(VResponse.Body, VResponse.BodySize);
    end;
    FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.Version <> FInfo.Version);
  end else
  if VResponse.Code = 304 then begin
    Assert(FPrevInfoExists);
    FInfo.State := tsFinished;
    FInfo.LastModified := FPrevInfo.LastModified;
    FInfo.Version := FPrevInfo.Version;
  end else begin
    FInfo.State := tsHttpError;
  end;
end;

class function TGoogleEarthWeb.GetVersion(const AData: Pointer; const ASize: Int64): string;
var
  VMetadata: TPlanetoidMetadataRec;
begin
  Result := '';
  if ASize > 0 then begin
    if ParseMetadata(AData, ASize, VMetadata) then begin
      if VMetadata.Epoch_02 = VMetadata.Epoch_05 then begin
        Result := IntToStr(VMetadata.Epoch_02);
      end else begin
        Result := Format('%d,%d', [VMetadata.Epoch_02, VMetadata.Epoch_05]);
      end;
    end;
  end;
end;

class function TGoogleEarthWeb.GetClientDataVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := 'data-version="(.*?)"';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;
  end;
end;

class function TGoogleEarthWeb.GetClientVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := '"(\d+\.\d+\.\d+\.\d+)"\.split\("\."\)';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;
  end;
end;

end.
