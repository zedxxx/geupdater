program GEDesktopVersionReadTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Classes,
  ZLib,
  System.SysUtils,
  dbroot_lite in 'dbroot_lite.pas';

const
  cTestFileName: array [0..2] of string = (
    '.\dbroot\earth\hl=ru&gl=ru&output=proto&cv=7.3.2.5481&ct=pro',
    '.\dbroot\tm\hl=ru&gl=ru&output=proto&cv=7.3.2.5481&ct=pro',
    '.\dbroot\sky\hl=ru&gl=ru&output=proto&cv=7.3.2.5481&ct=pro'
  );

procedure GeXorDecrypt(const AKey: TBytes; var AData: TBytes);
var
  I, J: Integer;
  VKeySize: Integer;
  VDataSize: Integer;
begin
  // https://github.com/google/earthenterprise/blob/master/earth_enterprise/src/common/etencoder.cc

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

function GetGeRootVersion(const AStream: TMemoryStream): Integer;
const
  cMagic = $7468DEAD;
var
  VRaw: Pointer;
  VData: TBytes;
  VProto: TDbRootProto;
  VEncrypted: TEncryptedDbRootProto;
  VMagic: Cardinal;
  VSize, VEstimateSize: Integer;
begin
  Result := -1;
  VEncrypted := TEncryptedDbRootProto.Create;
  try
    VEncrypted.LoadFromStream(AStream);
    if VEncrypted.encryption_type = ENCRYPTION_XOR then begin
      VData := VEncrypted.dbroot_data;

      GeXorDecrypt(VEncrypted.encryption_data, VData);

      VMagic := PCardinal(@VData[0])^;
      if VMagic <> cMagic then begin
        Exit;
      end;
      VEstimateSize := PInteger(@VData[4])^;
      ZDecompress(@VData[8], Length(VData) - 8, VRaw, VSize, VEstimateSize);

      VProto := TDbRootProto.Create;
      try
        VProto.LoadFromMem(VRaw, VSize, True);
        Result := VProto.database_version.quadtree_version;
      finally
        VProto.Free;
      end;
    end;
  finally
    VEncrypted.Free;
  end;
end;

procedure DoTest;
var
  I: Integer;
  VStream: TMemoryStream;
begin
  VStream := TMemoryStream.Create;
  try
    for I := Low(cTestFileName) to High(cTestFileName) do begin
      VStream.LoadFromFile(cTestFileName[I]);
      Writeln(GetGeRootVersion(VStream));
      VStream.Clear;
    end;
  finally
    VStream.Free;
  end;
end;

begin
  try
    DoTest;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
