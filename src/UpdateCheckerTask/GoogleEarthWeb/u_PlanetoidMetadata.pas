unit u_PlanetoidMetadata;

interface

type
  TPlanetoidMetadataRec = record
    Epoch_02: Integer;
    Epoch_05: Integer;
    ModelRadius: Double;
  end;

function ParseMetadata(
  const AData: Pointer;
  const ASize: Integer;
  out AMetadata: TPlanetoidMetadataRec
): Boolean;

implementation

uses
  Classes,
  planetoid_metadata;

procedure SaveDump(const AData: Pointer; const ASize: Int64);
var
  VStream: TFileStream;
begin
  try
    VStream := TFileStream.Create('PlanetoidMetadata.bin', fmCreate);
    try
      if (AData <> nil) and (ASize > 0) then begin
        VStream.WriteBuffer(AData^, ASize);
      end;
    finally
      VStream.Free;
    end;
  except
    //
  end;
end;

function ParseMetadata(
  const AData: Pointer;
  const ASize: Integer;
  out AMetadata: TPlanetoidMetadataRec
): Boolean;
var
  VPlanetoidMetadata: TPlanetoidMetadata;
begin
  Result := False;
  if ASize > 0 then begin
    try
      VPlanetoidMetadata := TPlanetoidMetadata.Create;
      try
        VPlanetoidMetadata.LoadFromMem(AData, ASize);
        AMetadata.Epoch_02 := VPlanetoidMetadata.epoch.f02;
        AMetadata.Epoch_05 := VPlanetoidMetadata.epoch.f05;
        AMetadata.ModelRadius := VPlanetoidMetadata.model_radius;
        Result := True;
      finally
        VPlanetoidMetadata.Free;
      end;
    except
      SaveDump(AData, ASize);
      raise;
    end;
  end;
end;

end.
