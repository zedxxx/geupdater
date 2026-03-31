unit libzstd;

interface

uses
  Windows,
  Classes,
  SysUtils;

const
  libzstd_dll = 'libzstd.dll';

type
  ELibZstdError = class(Exception);

const
  ZSTD_MIN_CLEVEL = 1;
  ZSTD_MAX_CLEVEL = 22;
  ZSTD_DEFAULT_CLEVEL = 3;
  ZSTD_FAST_MIN = -5; // ultra-fast

function CompressZstd(const AData: RawByteString; ACompressionLevel: Integer = ZSTD_DEFAULT_CLEVEL): RawByteString;
procedure DecompressZstd(const AData: Pointer; const ASize: NativeUInt; const ADest: TStream);

function LoadLibZstd(const ADllName: string = libzstd_dll; const ARaiseException: Boolean = True): Boolean;
procedure UnLoadLibZstd;

function IsLibZstdLoaded: Boolean;

implementation

uses
  SyncObjs;

type
  size_t = NativeUInt;
  
  PZSTD_DStream = Pointer;

  ZSTD_inBuffer = record
    src: Pointer;
    size: size_t;
    pos: size_t;
  end;
  PZSTD_inBuffer = ^ZSTD_inBuffer;

  ZSTD_outBuffer = record
    dst: Pointer;
    size: size_t;
    pos: size_t;
  end;
  PZSTD_outBuffer = ^ZSTD_outBuffer;

var
  ZSTD_compress: function(dst: Pointer; dstCapacity: size_t; src: Pointer; srcSize: size_t; compressionLevel: Integer): size_t; cdecl;
  ZSTD_decompress: function(dst: Pointer; dstCapacity: size_t; src: Pointer; compressedSize: size_t): size_t; cdecl;

  ZSTD_compressBound: function(srcSize: size_t): size_t; cdecl;
  ZSTD_getFrameContentSize: function(src: Pointer; srcSize: size_t): UInt64; cdecl;

  ZSTD_isError: function(code: size_t): Cardinal; cdecl;
  ZSTD_getErrorName: function(code: size_t): PAnsiChar; cdecl;

  ZSTD_createDStream: function: PZSTD_DStream; cdecl;
  ZSTD_freeDStream: function(zds: PZSTD_DStream): size_t; cdecl;
  ZSTD_initDStream: function(zds: PZSTD_DStream): size_t; cdecl;
  ZSTD_decompressStream: function(zds: PZSTD_DStream; output: PZSTD_outBuffer; input: PZSTD_inBuffer): size_t; cdecl;

const
  ZSTD_CONTENTSIZE_UNKNOWN = UInt64(-1);
  ZSTD_CONTENTSIZE_ERROR = UInt64(-2);

type
  TLibState = record
    FState: Integer;
    function GetValue: Integer; inline;
    procedure SetValue(const AValue: Integer); inline;
    property Value: Integer read GetValue write SetValue;
  end;

{ TLibState }

const
  LIBZSTD_STATE_NONE = 0;
  LIBZSTD_STATE_LOADED = 1;
  LIBZSTD_STATE_LOAD_ERROR = 2;

function TLibState.GetValue: Integer;
begin
  Result := InterlockedCompareExchange(FState, 0, 0);
end;

procedure TLibState.SetValue(const AValue: Integer);
begin
  InterlockedExchange(FState, AValue);
end;

var
  GState: TLibState;
  GHandle: THandle = 0;
  GLock: TCriticalSection;

function IsLibZstdLoaded: Boolean;
begin
  Result := GState.Value = LIBZSTD_STATE_LOADED;
end;

function LoadLibZstd(const ADllName: string; const ARaiseException: Boolean): Boolean;

  function GetProcAddr(const AProcName: string): Pointer;
  begin
    Result := GetProcAddress(GHandle, PChar(AProcName));
    if Result = nil then begin
      raise ELibZstdError.Create('Cannot load function "' + AProcName + '" from ' + ADllName);
    end;
  end;

var
  VState: Integer;
begin
  VState := GState.Value;

  if VState = LIBZSTD_STATE_LOADED then begin
    Result := True;
    Exit;
  end;

  if VState = LIBZSTD_STATE_LOAD_ERROR then begin
    Result := False;
    Exit;
  end;

  GLock.Acquire;
  try
    VState := GState.Value;

    if VState = LIBZSTD_STATE_LOADED then begin
      Result := True;
      Exit;
    end;

    if VState = LIBZSTD_STATE_LOAD_ERROR then begin
      Result := False;
      Exit;
    end;

    GHandle := LoadLibrary(PChar(ADllName));
    try
      if GHandle = 0 then begin
        raise ELibZstdError.Create('Cannot load ' + ADllName);
      end;

      ZSTD_compress := GetProcAddr('ZSTD_compress');
      ZSTD_decompress := GetProcAddr('ZSTD_decompress');
      ZSTD_compressBound := GetProcAddr('ZSTD_compressBound');
      ZSTD_getFrameContentSize := GetProcAddr('ZSTD_getFrameContentSize');
      ZSTD_isError := GetProcAddr('ZSTD_isError');
      ZSTD_getErrorName := GetProcAddr('ZSTD_getErrorName');
      ZSTD_createDStream := GetProcAddr('ZSTD_createDStream');
      ZSTD_freeDStream := GetProcAddr('ZSTD_freeDStream');
      ZSTD_initDStream := GetProcAddr('ZSTD_initDStream');
      ZSTD_decompressStream := GetProcAddr('ZSTD_decompressStream');

      GState.Value := LIBZSTD_STATE_LOADED;
      Result := True;
    except
      on E: Exception do begin
        GState.Value := LIBZSTD_STATE_LOAD_ERROR;

        if GHandle <> 0 then begin
          FreeLibrary(GHandle);
          GHandle := 0;
        end;

        if ARaiseException then begin
          raise;
        end else begin
          Result := False;
        end;
      end;
    end;
  finally
    GLock.Release;
  end;
end;

procedure UnLoadLibZstd;
begin
  GLock.Acquire;
  try
    GState.Value := LIBZSTD_STATE_NONE;

    ZSTD_compress := nil;
    ZSTD_decompress := nil;
    ZSTD_compressBound := nil;
    ZSTD_getFrameContentSize := nil;
    ZSTD_isError := nil;
    ZSTD_getErrorName := nil;
    ZSTD_createDStream := nil;
    ZSTD_freeDStream := nil;
    ZSTD_initDStream := nil;
    ZSTD_decompressStream := nil;

    if GHandle <> 0 then begin
      FreeLibrary(GHandle);
      GHandle := 0;
    end;
  finally
    GLock.Release;
  end;
end;

function CompressZstd(const AData: RawByteString; ACompressionLevel: Integer): RawByteString;
var
  VInputSize: NativeUInt;
  VMaxOutputSize: NativeUInt;
  VResult: NativeUInt;
begin
  Result := '';

  VInputSize := Length(AData);

  if VInputSize = 0 then begin
    Exit;
  end;

  if (ACompressionLevel < ZSTD_FAST_MIN) or (ACompressionLevel > ZSTD_MAX_CLEVEL) then begin
    raise ELibZstdError.CreateFmt(
      'CompressionLevel value %d is out of range [%d..%d]!', [ACompressionLevel, ZSTD_FAST_MIN, ZSTD_MAX_CLEVEL]
    );
  end;

  VMaxOutputSize := ZSTD_compressBound(VInputSize);

  // Allocate output buffer
  SetLength(Result, VMaxOutputSize);

  // Compress
  VResult := ZSTD_compress(Pointer(Result), VMaxOutputSize, Pointer(AData), VInputSize, ACompressionLevel);

  // Check for error
  if ZSTD_isError(VResult) <> 0 then begin
    raise ELibZstdError.CreateFmt('Zstd compression failed: %s', [string(ZSTD_getErrorName(VResult))]);
  end;

  // Resize to actual compressed size
  SetLength(Result, VResult);
end;

procedure DecompressZstd(const AData: Pointer; const ASize: NativeUInt; const ADest: TStream);
const
  ZSTD_BLOCKSIZE_MAX = 131072; // 128 kB
const
  cMaxTrustedSize = 10 * 1024 * 1024; // 10 MB
var
  VResult: NativeUInt;
  VDecompressedSize: UInt64;
  VDStream: PZSTD_DStream;
  VInBuffer: ZSTD_inBuffer;
  VOutBuffer: ZSTD_outBuffer;
  VTempBuffer: array [0..ZSTD_BLOCKSIZE_MAX-1] of Byte;
begin
  if (AData = nil) or (ASize = 0) then begin
    Exit;
  end;

  VDecompressedSize := ZSTD_getFrameContentSize(AData, ASize);

  if VDecompressedSize = ZSTD_CONTENTSIZE_ERROR then begin
    raise ELibZstdError.Create('Zstd decompression failed: invalid frame header!');
  end;

  if not (ADest is TMemoryStream) or
     (VDecompressedSize = ZSTD_CONTENTSIZE_UNKNOWN) or
     (VDecompressedSize > cMaxTrustedSize)
  then begin
    VDStream := ZSTD_createDStream;
    if VDStream = nil then begin
      raise ELibZstdError.Create('Failed to create Zstd decompression stream!');
    end;

    try
      VResult := ZSTD_initDStream(VDStream);
      if ZSTD_isError(VResult) <> 0 then begin
        raise ELibZstdError.CreateFmt('Failed to initialize Zstd decompression stream: %s', [string(ZSTD_getErrorName(VResult))]);
      end;

      VInBuffer.src := AData;
      VInBuffer.size := ASize;
      VInBuffer.pos := 0;

      repeat
        VOutBuffer.dst := @VTempBuffer[0];
        VOutBuffer.size := Length(VTempBuffer);
        VOutBuffer.pos := 0;

        VResult := ZSTD_decompressStream(VDStream, @VOutBuffer, @VInBuffer);

        if ZSTD_isError(VResult) <> 0 then begin
          raise ELibZstdError.CreateFmt('Zstd decompression failed: %s', [string(ZSTD_getErrorName(VResult))]);
        end;

        if VOutBuffer.pos > 0 then begin
          ADest.WriteBuffer(VTempBuffer[0], VOutBuffer.pos);
        end;

        if VOutBuffer.pos = VOutBuffer.size then begin
          // The output buffer was filled completely, but zstd may still hold decoded
          // bytes in its internal buffers. The spec requires calling ZSTD_decompressStream
          // again with a fresh output buffer (and no new input) to flush the remainder.
          // https://facebook.github.io/zstd/zstd_manual.html#Chapter9
          Continue;
        end;

        if VInBuffer.pos >= VInBuffer.size then begin
          // All input has been consumed
          if VResult = 0 then begin
            // Completed successfully
            Break;
          end else begin
            // The decoder expected more input to complete the frame, so the source data is truncated
            raise ELibZstdError.Create('Zstd decompression failed: truncated frame');
          end;
        end;
      until False;
    finally
      ZSTD_freeDStream(VDStream);
    end;
  end else begin
    Assert(ADest is TMemoryStream);

    ADest.Size := VDecompressedSize; // Allocate output buffer

    VResult := ZSTD_decompress(TMemoryStream(ADest).Memory, VDecompressedSize, AData, ASize);

    if ZSTD_isError(VResult) <> 0 then begin
      raise ELibZstdError.CreateFmt('Zstd decompression failed: %s', [string(ZSTD_getErrorName(VResult))]);
    end;

    if VResult <> VDecompressedSize then begin
      ADest.Size := VResult;
    end;
  end;
end;

initialization
  GLock := TCriticalSection.Create;
  GState.FState := LIBZSTD_STATE_NONE;

finalization
  UnLoadLibZstd;
  FreeAndNil(GLock);

end.
