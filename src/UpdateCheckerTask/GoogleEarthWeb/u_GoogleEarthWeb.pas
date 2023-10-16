unit u_GoogleEarthWeb;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_EventLogStorage,
  u_UpdateCheckerTaskBase;

type
  TGoogleEarthWebCheckType = (gewctEarth, gewctClient);

  TGoogleEarthWeb = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleEarthWebCheckType;
  private
    class function GetVersion(const AData: Pointer; const ASize: Int64): string;
    class function GetClientVersion(const AText: string): string;
  protected
    function GetConf: TTaskConf; override;
    function GetHeaders: string; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleEarthWebCheckType;
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
  c_UserAgent,
  c_UpdateCheckerTask,
  i_DownloadRequest,
  i_DownloadResponse,
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
  const ADownloader: IDownloader;
  const AEventLog: IEventLogStorage;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AEventLog, AListener);
  FCheckType := ACheckType;
end;

function TGoogleEarthWeb.GetConf: TTaskConf;
begin
  Result := cTaskConf[FCheckType];
end;

function TGoogleEarthWeb.GetHeaders: string;
begin
  Result :=
    'User-Agent: ' + cBrowserUserAgent + #13#10 +
    'Accept: */*' + #13#10 +
    'Accept-Language: en-us,en,*';
end;

procedure TGoogleEarthWeb.DoExecute;
var
  VRequest: IDownloadRequest;
  VResponse: IDownloadResponse;
begin
  VRequest := BuildRequest;
  VResponse := FDownloader.DoGetRequest(VRequest);

  FInfo.HttpRequest := VRequest;
  FInfo.HttpResponse := VResponse;

  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;
    case FCheckType of
      gewctEarth:  FInfo.Version := GetVersion(VResponse.Body, VResponse.BodySize);
      gewctClient: FInfo.Version := GetClientVersion(VResponse.GetBodyAsText);
    else
      Assert(False);
    end;
    FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.Version <> FInfo.Version);
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

class function TGoogleEarthWeb.GetClientVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := '"app_min\.html":"(.*?)/app_min\.html"';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;

    if Result <> '' then begin
      Exit;
    end;

    VPattern := 'data-version="(.*?)"';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;
  end;
end;

end.
