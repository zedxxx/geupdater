unit u_ContentDecoder;

interface

uses
  System.Classes,
  System.SysUtils;

type
  TContentDecoder = record
    class function GetDecodersStr: string; static;

    class procedure DoDecodeGZip(var AContent: TMemoryStream); static;
    class procedure DoDecodeDeflate(var AContent: TMemoryStream); static;
    class procedure DoDecodeBrotli(var AContent: TMemoryStream); static;
    class procedure DoDecodeZstd(var AContent: TMemoryStream); static;

    class procedure Decode(const AContentEncoding: string; var AContent: TMemoryStream); static;
  end;

  EContentDecoderError = class(Exception);

implementation

uses
  SynZip,
  libbrotli,
  libzstd;

type
  TContentEncodingType = (
    etGZip,
    etDeflate,
    etBrotli,
    etZstd,
    etIdentity,
    etUnknown
  );

function GetEncodingType(const AContentEncoding: string): TContentEncodingType;
begin
  if AContentEncoding = 'gzip' then begin
    Result := etGZip;
  end else
  if AContentEncoding = 'deflate' then begin
    Result := etDeflate;
  end else
  if AContentEncoding = 'br' then begin
    Result := etBrotli;
  end else
  if AContentEncoding = 'zstd' then begin
    Result := etZstd;
  end else
  if AContentEncoding = 'identity' then begin
    Result := etIdentity;
  end else begin
    Result := etUnknown;
  end;
end;

{ TContentDecoder }

class function TContentDecoder.GetDecodersStr: string;
begin
  Result := 'gzip, deflate';

  if LoadLibBrotliDec(libbrotlidec_dll, False) then begin
    Result := Result + ', br';
  end;

  if LoadLibZstd(libzstd_dll, False) then begin
    Result := Result + ', zstd';
  end;
end;

class procedure TContentDecoder.DoDecodeGZip(var AContent: TMemoryStream);
var
  VGZRead: TGZRead;
  VStream: TMemoryStream;
begin
  VStream := TMemoryStream.Create;
  try
    if VGZRead.Init(AContent.Memory, AContent.Size) and VGZRead.ToStream(VStream) then begin
      FreeAndNil(AContent);
      AContent := VStream;
      AContent.Position := 0;
      VStream := nil;
    end else begin
      raise EContentDecoderError.Create('Gzip decompression failed!');
    end;
  finally
    VStream.Free;
  end;
end;

class procedure TContentDecoder.DoDecodeDeflate(var AContent: TMemoryStream);
var
  VStream: TMemoryStream;
begin
  VStream := TMemoryStream.Create;
  try
    try
      UnCompressStream(AContent.Memory, AContent.Size, VStream, nil, True {as zlib format});
    except
      on E1: ESynZipException do begin
        VStream.Clear;
        try
          UnCompressStream(AContent.Memory, AContent.Size, VStream, nil, False {as raw deflate});
        except
          on E2: ESynZipException do begin
            raise EContentDecoderError.CreateFmt(
              'Deflate decompression failed (zlib and raw formats): %s | %s', [E1.Message, E2.Message]
            );
          end;
        end;
      end;
    end;
    FreeAndNil(AContent);
    AContent := VStream;
    AContent.Position := 0;
    VStream := nil;
  finally
    VStream.Free;
  end;
end;

class procedure TContentDecoder.DoDecodeBrotli(var AContent: TMemoryStream);
var
  VStream: TMemoryStream;
begin
  if not LoadLibBrotliDec(libbrotlidec_dll, True) then begin
    raise EContentDecoderError.Create('Cannot load Brotli decoder library!');
  end;
  VStream := TMemoryStream.Create;
  try
    DecompressBrotli(AContent.Memory, AContent.Size, VStream);
    FreeAndNil(AContent);
    AContent := VStream;
    AContent.Position := 0;
    VStream := nil;
  finally
    VStream.Free;
  end;
end;

class procedure TContentDecoder.DoDecodeZstd(var AContent: TMemoryStream);
var
  VStream: TMemoryStream;
begin
  if not LoadLibZstd(libzstd_dll, True) then begin
    raise EContentDecoderError.Create('Cannot load zstd library!');
  end;
  VStream := TMemoryStream.Create;
  try
    DecompressZstd(AContent.Memory, AContent.Size, VStream);
    FreeAndNil(AContent);
    AContent := VStream;
    AContent.Position := 0;
    VStream := nil;
  finally
    VStream.Free;
  end;
end;

class procedure TContentDecoder.Decode(const AContentEncoding: string; var AContent: TMemoryStream);
var
  VEncoding: TContentEncodingType;
begin
  if (AContent.Size = 0) or (AContentEncoding = '') then begin
    Exit;
  end;

  AContent.Position := 0;

  VEncoding := GetEncodingType(AContentEncoding);

  case VEncoding of
    etGZip     : DoDecodeGZip(AContent);
    etDeflate  : DoDecodeDeflate(AContent);
    etBrotli   : DoDecodeBrotli(AContent);
    etZstd     : DoDecodeZstd(AContent);
    etIdentity : { nothing to do } ;
    etUnknown  : raise EContentDecoderError.CreateFmt('Unknown Content-Encoding: "%s"', [AContentEncoding]);
  else
    raise EContentDecoderError.CreateFmt('Unexpected encoding type value: %d', [Integer(VEncoding)]);
  end;
end;

end.
