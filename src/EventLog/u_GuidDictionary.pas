unit u_GuidDictionary;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TDictionaryById = TDictionary<Int64, TGUID>;
  TDictionaryByGuid = TDictionary<TGUID, Int64>;

  TGuidDictionary = class
  private
    FById: TDictionaryById;
    FByGuid: TDictionaryByGuid;
  public
    procedure Add(const AGuid: TGUID; const AId: Int64);
    function TryGetIdByGuid(const AGuid: TGUID; out AId: Int64): Boolean; inline;
    function TryGetGuidById(const AId: Int64; out AGuid: TGUID): Boolean; inline;
  public
    constructor Create(ACapacity: Integer);
    destructor Destroy; override;
  end;

  EGuidDictionary = class(Exception);

implementation

{ TGuidDictionary }

constructor TGuidDictionary.Create(ACapacity: Integer);
begin
  inherited Create;
  FById := TDictionaryById.Create(ACapacity);
  FByGuid := TDictionaryByGuid.Create(ACapacity);
end;

destructor TGuidDictionary.Destroy;
begin
  FreeAndNil(FById);
  FreeAndNil(FByGuid);
  inherited Destroy;
end;

procedure TGuidDictionary.Add(const AGuid: TGUID; const AId: Int64);
begin
  if FById.ContainsKey(AId) then
    raise EGuidDictionary.CreateFmt('ID %d already exists!', [AId]);

  if FByGuid.ContainsKey(AGuid) then
    raise EGuidDictionary.CreateFmt('GUID %s already exists!', [GuidToString(AGuid)]);

  FById.Add(AId, AGuid);
  FByGuid.Add(AGuid, AId);
end;

function TGuidDictionary.TryGetGuidById(const AId: Int64; out AGuid: TGUID): Boolean;
begin
  Result := FById.TryGetValue(AId, AGuid);
end;

function TGuidDictionary.TryGetIdByGuid(const AGuid: TGUID; out AId: Int64): Boolean;
begin
  Result := FByGuid.TryGetValue(AGuid, AId);
end;

end.
