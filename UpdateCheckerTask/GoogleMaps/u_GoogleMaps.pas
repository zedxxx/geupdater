unit u_GoogleMaps;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_UpdateCheckerStoredInfo,
  u_UpdateCheckerTaskBase;

type
  TGoogleMapsCheckType = (gmctSat, gmctApi);

  TGoogleMaps = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleMapsCheckType;
    function GetUrl: string;
    function GetHeaders: string;
  protected
    function GetGUID: TGUID; override;
    function GetName: string; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleMapsCheckType;
      const ADownloader: IDownloader;
      const AStoredInfo: IUpdateCheckerStoredInfo;
      const AListener: TArray<ITaskInfoListener>
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  RegularExpressions,
  c_UserAget,
  i_DownloadResponse;

const
  cName: array [TGoogleMapsCheckType] of string = (
    'Satellite',
    'JS API'
  );

  cGUID: array [TGoogleMapsCheckType] of string = (
    '{D732DF07-37C4-4773-9C88-AA95C1A7AAFF}',
    '{45B30A7C-F81D-4E85-9E7D-52DE35E25173}'
  );

{ TGoogleMaps }

constructor TGoogleMaps.Create(
  const ACheckType: TGoogleMapsCheckType;
  const ADownloader: IDownloader;
  const AStoredInfo: IUpdateCheckerStoredInfo;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AStoredInfo, AListener);
  FCheckType := ACheckType;
end;

function TGoogleMaps.GetName: string;
begin
  Result := cName[FCheckType];
end;

function TGoogleMaps.GetGUID: TGUID;
begin
  Result := StringToGUID(cGUID[FCheckType]);
end;

function TGoogleMaps.GetUrl: string;
begin
  Result := 'https://maps.googleapis.com/maps/api/js';
end;

function TGoogleMaps.GetHeaders: string;
begin
  Result :=
    'User-Agent: ' + cBrowserUserAgent + #13#10 +
    'Accept: text/html, */*' + #13#10 +
    'Accept-Encoding: gzip,deflate' + #13#10 +
    'Accept-Language: en-us,en,*';
end;

function GetVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := 'https://khms\d+.googleapis\.com/kh\?v=(\d+)';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;
  end;
end;

function GetApiVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := '\[\"https://maps\.googleapis\.com/maps-api-(.*?)/api/js/\d+/\d+\",\"(.*?)\"\]';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[2].Value;
    end;
  end;
end;

procedure TGoogleMaps.DoExecute;
var
  VUrl: string;
  VRawHeaders: string;
  VResponse: IDownloadResponse;
begin
  VUrl := GetUrl;
  VRawHeaders := GetHeaders;
  VResponse := FDownloader.DoGetRequest(VUrl, VRawHeaders);
  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;
    case FCheckType of
      gmctSat: FInfo.Version := GetVersion(VResponse.GetBodyAsText);
      gmctApi: FInfo.Version := GetApiVersion(VResponse.GetBodyAsText);
    else
      Assert(False);
    end;
    FInfo.IsUpdatesFound :=
      not FHasStoredInfo or
      (FStoredInfoRec.Version <> FInfo.Version);
  end else begin
    FInfo.State := tsFailed;
  end;
end;

end.
