unit u_GoogleEarthDesktop;

{$DEFINE USE_PROTO}

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
    function IsClientCheck: Boolean; inline;
  private
    {$IFDEF USE_PROTO}
    class function GetEpochVersionProto(const AData: Pointer; const ASize: Int64): string;
    {$ELSE}
    class function GetEpochVersion(const AData: Pointer; const ASize: Int64): string;
    {$ENDIF}
  protected
    function GetConf: TTaskConf; override;
    function GetHeaders: string; override;
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
  ZLib,
  dbroot_lite,
  c_UserAgent,
  c_UpdateCheckerTask,
  i_DownloadRequest,
  i_DownloadResponse,
  u_DateTimeUtils;

const
  cParams =
    'hl=en-GB&gl=us' +
    {$IFDEF USE_PROTO}
    '&output=proto'
    {$ELSE}
    ''
    {$ENDIF} +
    '&cv=' + cGoogleEarthClientVersion +
    '&ct=pro';

  cTaskConf: array [TGoogleEarthDesktopCheckType] of TTaskConf = (
    (GUID:        cGoogleEarthDesktopEathGUID;
     RequestUrl:  'https://kh.google.com/dbRoot.v5?' + cParams;
     DisplayName: 'Earth'),

    (GUID:        cGoogleEarthDesktopHistoryGUID;
     RequestUrl:  'https://khmdb.google.com/dbRoot.v5?db=tm&' + cParams;
     DisplayName: 'History'),

    (GUID:        cGoogleEarthDesktopSkyGUID;
     RequestUrl:  'https://khmdb.google.com/dbRoot.v5?db=sky&' + cParams;
     DisplayName: 'Sky'),

    (GUID:        cGoogleEarthDesktopMarsGUID;
     RequestUrl:  'https://khmdb.google.com/dbRoot.v5?db=mars&' + cParams;
     DisplayName: 'Mars'),

    (GUID:        cGoogleEarthDesktopMoonGUID;
     RequestUrl:  'https://khmdb.google.com/dbRoot.v5?db=moon&' + cParams;
     DisplayName: 'Moon'),

    (GUID:        cGoogleEarthDesktopClientGUID;
     RequestUrl:  'https://dl.google.com/earth/client/advanced/current/GoogleEarthProWin.exe';
     DisplayName: 'Client')

     // ToDo: Check for GoogleEarth Enterprise Client (EC)
     // https://dl.google.com/dl/earth/client/advanced/current/GoogleEarthEcWin.exe
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

function TGoogleEarthDesktop.IsClientCheck: Boolean;
begin
  Result := FCheckType = gecctClient;
end;

function TGoogleEarthDesktop.GetConf: TTaskConf;
begin
  Result := cTaskConf[FCheckType];
end;

function TGoogleEarthDesktop.GetHeaders: string;
var
  VIfModifiedSince: string;
begin
  if IsClientCheck then begin
    Result :=
      'User-Agent: ' + cBrowserUserAgent + #13#10 +
      'Accept: */*' + #13#10 +
      'Accept-Language: en-us,en,*';
  end else begin
    if FPrevInfoExists and (FPrevInfo.LastModified <> 0) then begin
      VIfModifiedSince :=
        'If-Modified-Since: ' + DateTimeToRFC1123(FPrevInfo.LastModified) + #13#10;
    end else begin
      VIfModifiedSince := '';
    end;
    Result :=
      'User-Agent: ' + cGoogleEarthClientUserAgent + #13#10 +
      VIfModifiedSince +
      'Accept: application/vnd.google-earth.kml+xml, application/vnd.google-earth.kmz, image/*, */*' + #13#10 +
      'Accept-Language: en-us,en,*' + #13#10 +
      'Accept-Charset: iso-8859-1,*,utf-8';
  end;
end;

procedure TGoogleEarthDesktop.DoExecute;
var
  VRequest: IDownloadRequest;
  VResponse: IDownloadResponse;
begin
  VRequest := BuildRequest;

  if IsClientCheck then begin
    VResponse := FDownloader.DoHeadRequest(VRequest);
  end else begin
    VResponse := FDownloader.DoGetRequest(VRequest);
  end;

  FInfo.HttpRequest := VRequest;
  FInfo.HttpResponse := VResponse;

  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;

    if IsClientCheck then begin
      FInfo.Version := '-';
      FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.LastModified <> FInfo.LastModified);
    end else begin
      FInfo.Version :=
        {$IFDEF USE_PROTO}
        GetEpochVersionProto(VResponse.Body, VResponse.BodySize);
        {$ELSE}
        GetEpochVersion(VResponse.Body, VResponse.BodySize);
        {$ENDIF}

      FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.Version <> FInfo.Version);
    end;
  end else
  if VResponse.Code = 304 then begin // Not Modified
    Assert(FPrevInfoExists);
    FInfo.State := tsFinished;
    FInfo.LastModified := FPrevInfo.LastModified;
    FInfo.Version := FPrevInfo.Version;
  end else begin
    FInfo.State := tsHttpError;
  end;
end;

{$IFDEF USE_PROTO}
class function TGoogleEarthDesktop.GetEpochVersionProto(const AData: Pointer; const ASize: Int64): string;

  procedure _decrypt(const AKey: TBytes; var AData: TBytes);
  var
    I, J: Integer;
    VKeySize: Integer;
    VDataSize: Integer;
  begin
    VKeySize := Length(AKey);
    VDataSize := Length(AData);

    Assert(VKeySize > 0);
    Assert(VDataSize > 0);

    if (VKeySize <= 0) or (VDataSize <= 0) then begin
      Exit;
    end;

    J := 16;
    for I := 0 to VDataSize - 1 do begin
      AData[I] := AData[I] xor AKey[J];
      Inc(J);
      if J mod 8 = 0 then begin
        Inc(J, 16);
      end;
      if J >= VKeySize then begin
        J := (J + 8) mod 24;
      end;
    end;
  end;

var
  VRaw: Pointer;
  VData: TBytes;
  VProto: TDbRootProto;
  VEncrypted: TEncryptedDbRootProto;
  VMagic: Cardinal;
  VSize, VEstimateSize: Integer;
begin
  Result := '';
  VEncrypted := TEncryptedDbRootProto.Create;
  try
    VEncrypted.LoadFromMem(AData, ASize, False);
    if VEncrypted.encryption_type = ENCRYPTION_XOR then begin
      VData := VEncrypted.dbroot_data;

      _decrypt(VEncrypted.encryption_data, VData);

      VMagic := PCardinal(@VData[0])^;
      if VMagic <> $7468DEAD then begin
        Exit;
      end;
      VEstimateSize := PInteger(@VData[4])^;
      ZDecompress(@VData[8], Length(VData) - 8, VRaw, VSize, VEstimateSize);

      VProto := TDbRootProto.Create;
      try
        VProto.LoadFromMem(VRaw, VSize, True);
        Result := IntToStr(VProto.database_version.quadtree_version);
      finally
        VProto.Free;
      end;
    end;
  finally
    VEncrypted.Free;
  end;
end;
{$ELSE}
class function TGoogleEarthDesktop.GetEpochVersion(const AData: Pointer; const ASize: Int64): string;
var
  VPtr: PByte;
  VVersion: PWord;
begin
  Assert(AData <> nil);
  Result := '';
  VPtr := AData;
  if ASize > 8 then begin
    Inc(VPtr, 6);
    VVersion := PWord(VPtr);
    Result := IntToStr(VVersion^ xor $4200);
  end;
end;
{$ENDIF}

end.
