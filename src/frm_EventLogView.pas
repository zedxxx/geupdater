unit frm_EventLogView;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  VirtualTrees,
  t_EventLog,
  i_EventLogStorage,
  u_EventLogViewConfig;

type
  TGuidInfo = record
    DisplayName: string;
    ItemsCount: Integer;
  end;

  TGuidInfoDictionary = TDictionary<TGUID, TGuidInfo>;

  TfrmEventLogViewer = class(TForm)
    btnClose: TButton;
    pnlTreeView: TPanel;
    lblInfo: TLabel;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FConfig: TEventLogViewConfig;
    FVirtualTree: TVirtualStringTree;
    FStorage: IEventLogStorage;
    FEvents: TEventLogItemArray;
    FGuidInfo: TGuidInfoDictionary;
    procedure PrepareGuidInfo;
    function GetItemIndex(const ANode: PVirtualNode): Int64; inline;
    procedure UpdateFormCaption(const ANode: PVirtualNode);
    procedure OnVTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure OnVTBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
    procedure OnVTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: UnicodeString);
    procedure OnVTHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure OnVTKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UpdateTree;
  public
    constructor Create(
      const AOwner: TComponent;
      const AStorage: IEventLogStorage
    ); reintroduce;
  end;

implementation

uses
  System.Diagnostics,
  System.DateUtils,
  c_UpdateCheckerTask,
  u_DateTimeUtils;

{$R *.dfm}

constructor TfrmEventLogViewer.Create(
  const AOwner: TComponent;
  const AStorage: IEventLogStorage
);
begin
  inherited Create(AOwner);
  FStorage := AStorage;

  FGuidInfo := TGuidInfoDictionary.Create(32);
  PrepareGuidInfo;
end;

procedure TfrmEventLogViewer.PrepareGuidInfo;
var
  VGroupName: string;

  procedure _Add(const AGuid: string; const AName: string);
  var
    VInfo: TGuidInfo;
  begin
    VInfo.DisplayName := Format('%s (%s)', [AName, VGroupName]);
    VInfo.ItemsCount := 0;
    FGuidInfo.Add(StringToGUID(AGuid), VInfo);
  end;

begin
  // Google Earth Desktop
  VGroupName := 'Desktop';
  _Add(cGoogleEarthDesktopEathGUID, 'Earth');
  _Add(cGoogleEarthDesktopHistoryGUID, 'History');
  _Add(cGoogleEarthDesktopSkyGUID, 'Sky');
  _Add(cGoogleEarthDesktopMarsGUID, 'Mars');
  _Add(cGoogleEarthDesktopMoonGUID, 'Moon');
  _Add(cGoogleEarthDesktopClientGUID, 'Client');

  // Google Earth Web
  VGroupName := 'Web';
  _Add(cGoogleEarthWebEarthGUID, 'Earth');
  _Add(cGoogleEarthWebClientGUID, 'Client');

  // Google Maps Classic
  VGroupName := 'Maps Classic';
  _Add(cGoogleMapsClassicEarthGUID, 'Earth');
  _Add(cGoogleMapsClassicJSAPIGUID, 'JS API');

  // Google Maps
  VGroupName := 'Maps';
  _Add(cGoogleMapsEarthGUID, 'Earth');
  _Add(cGoogleMapsMarsGUID, 'Mars');
  _Add(cGoogleMapsMoonGUID, 'Moon');
end;

procedure TfrmEventLogViewer.FormCreate(Sender: TObject);
var
  I: Integer;
  VTreeColumnsState: TTreeColumnsState;
  VTreeShowOpt: TTreeShowOptRec;
begin
  // Init with default values
  VTreeShowOpt.SortColumn := 0;
  VTreeShowOpt.SortDirection := 1;

  SetLength(VTreeColumnsState, 5);

  VTreeColumnsState[0].Name := 'Num';
  VTreeColumnsState[1].Name := 'Time';
  VTreeColumnsState[2].Name := 'Name';
  VTreeColumnsState[3].Name := 'Version';
  VTreeColumnsState[4].Name := 'Last-Modified';

  VTreeColumnsState[0].Size := 50;
  VTreeColumnsState[0].Position := 0;

  VTreeColumnsState[1].Size := 150;
  VTreeColumnsState[1].Position := 1;

  VTreeColumnsState[2].Size := 250;
  VTreeColumnsState[2].Position := 2;

  VTreeColumnsState[3].Size := 80;
  VTreeColumnsState[3].Position := 3;

  VTreeColumnsState[4].Size := 150;
  VTreeColumnsState[4].Position := 4;

  // create and load config
  FConfig :=
    TEventLogViewConfig.Create(
      Self.BoundsRect,
      VTreeColumnsState,
      VTreeShowOpt
    );

  Self.BoundsRect := FConfig.GetBoundsRect;

  // create and init tree view
  FVirtualTree := TVirtualStringTree.Create(nil);
  with FVirtualTree do begin
    Parent := Self.pnlTreeView;

    OnGetText := Self.OnVTGetText;
    OnHeaderClick := Self.OnVTHeaderClick;
    OnBeforeCellPaint := Self.OnVTBeforeCellPaint;
    OnFocusChanged := Self.OnVTFocusChanged;
    OnKeyDown := Self.OnVTKeyDown;

    TreeOptions.MiscOptions := [toReadOnly];
    NodeDataSize := 0;
    Left := 0;
    Top := 0;
    Align := alClient;
    Visible := True;

    ScrollBarOptions.ScrollBars := ssBoth;

    TreeOptions.MiscOptions := [
      toFullRepaintOnResize,
      toInitOnSave,
      toGridExtensions,
      toToggleOnDblClick,
      toWheelPanning
    ];

    TreeOptions.PaintOptions := [
      toShowButtons,
      toShowDropmark,
      toShowHorzGridLines,
      //toShowVertGridLines,
      toThemeAware,
      toUseBlendedImages
    ];

    TreeOptions.SelectionOptions := [
      toFullRowSelect
    ];

    Header.Options := [
      hoColumnResize,
      hoDblClickResize,
      hoDrag,
      hoHotTrack,
      hoRestrictDrag,
      hoVisible
    ];

    VTreeColumnsState := FConfig.TreeColumnsState;

    for I := 0 to Length(VTreeColumnsState) - 1 do begin
      with Header.Columns.Add do begin
        Text := VTreeColumnsState[I].Name;
        Position := VTreeColumnsState[I].Position;
        Width := VTreeColumnsState[I].Size;
        if I = 0 then begin // column "Num"
          Options := [
            coAllowClick,
            coEnabled,
            coParentBidiMode,
            coParentColor,
            coResizable,
            coVisible,
            coAutoSpring
          ];
        end else begin
          Options := [
            coAllowClick,
            coDraggable,
            coEnabled,
            coParentBidiMode,
            coParentColor,
            coResizable,
            coShowDropMark,
            coVisible,
            coAutoSpring
          ];
        end;
      end;
    end;
    Header.AutoSizeIndex := 0;

    VTreeShowOpt := FConfig.TreeShowOpt;
    Header.SortColumn := VTreeShowOpt.SortColumn;
    Header.SortDirection := TSortDirection(VTreeShowOpt.SortDirection);
  end;
end;

procedure TfrmEventLogViewer.FormDestroy(Sender: TObject);
var
  I: Integer;
  VColumn: TVirtualTreeColumn;
  VTreeColumnsState: TTreeColumnsState;
  VTreeShowOptRec: TTreeShowOptRec;
begin
  FConfig.SetWindowPosition(Self.BoundsRect);

  VTreeColumnsState := FConfig.TreeColumnsState;
  if Length(VTreeColumnsState) = FVirtualTree.Header.Columns.Count then begin
    for I := 0 to FVirtualTree.Header.Columns.Count - 1 do begin
      VColumn := FVirtualTree.Header.Columns.Items[I];
      VTreeColumnsState[I].Size := VColumn.Width;
      VTreeColumnsState[I].Position := VColumn.Position;
    end;
    FConfig.TreeColumnsState := VTreeColumnsState;
  end;

  VTreeShowOptRec.SortColumn := FVirtualTree.Header.SortColumn;
  VTreeShowOptRec.SortDirection := Integer(FVirtualTree.Header.SortDirection);
  FConfig.TreeShowOpt := VTreeShowOptRec;

  FreeAndNil(FConfig);
  FreeAndNil(FGuidInfo);
end;

procedure TfrmEventLogViewer.UpdateTree;
var
  I: Integer;
  VInfo: TGuidInfo;
  VTimer: TStopwatch;
  VNode: PVirtualNode;
begin
  FVirtualTree.Clear;

  VTimer := TStopwatch.StartNew;

  if FStorage <> nil then begin
    FEvents := FStorage.FetchAll;
    for I := 0 to Length(FEvents) - 1 do begin
      if FGuidInfo.TryGetValue(FEvents[I].GUID, VInfo) then begin
        Inc(VInfo.ItemsCount);
        FGuidInfo.Items[FEvents[I].GUID] := VInfo;
      end;
    end;
    FVirtualTree.RootNodeCount := Length(FEvents);
    if FVirtualTree.RootNodeCount > 0 then begin
      VNode := FVirtualTree.RootNode.FirstChild;
      FVirtualTree.Selected[VNode] := True;
      FVirtualTree.FocusedNode := VNode;
      UpdateFormCaption(VNode);
    end;
  end else begin
    FEvents := nil;
  end;

  VTimer.Stop;

  lblInfo.Caption :=
    Format(
      '%d events, loaded at %.4f seconds',
      [Length(FEvents), VTimer.Elapsed.TotalSeconds]
    );
end;

procedure TfrmEventLogViewer.FormShow(Sender: TObject);
begin
  UpdateTree;
end;

function TfrmEventLogViewer.GetItemIndex(const ANode: PVirtualNode): Int64;
begin
  if FVirtualTree.Header.SortDirection = sdAscending then begin
    Result := ANode.Index;
  end else begin
    Result := (Length(FEvents) - 1) - Int64(ANode.Index);
  end;
  if (Result >= Length(FEvents)) or (Result < 0) then begin
    raise Exception.CreateFmt('Node Index is out of bounds [0..%d]: %d', [Length(FEvents)-1, Result]);
  end;
end;

procedure TfrmEventLogViewer.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmEventLogViewer.OnVTBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  I, J: Int64;
  VColor: TColor;
begin
  if FVirtualTree.FocusedNode = nil then begin
    Exit;
  end;

  I := GetItemIndex(Node);
  J := GetItemIndex(FVirtualTree.FocusedNode);

  if FEvents[I].GUID = FEvents[J].GUID then begin
    VColor := $CCFFCC;
  end else begin
    VColor := $FFFFFF;
  end;

  TargetCanvas.Brush.Color := VColor;
  TargetCanvas.FillRect(CellRect);
end;

procedure TfrmEventLogViewer.OnVTGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: UnicodeString
);

  function _FormatName(const AGUID: TGUID): string;
  var
    VInfo: TGuidInfo;
  begin
    if FGuidInfo.TryGetValue(AGUID, VInfo) then begin
      Result := VInfo.DisplayName;
    end else begin
      Result := GUIDToString(AGuid);
    end;
  end;

  function _FormatDateTime(const AValue: TDateTime): string;
  begin
    if AValue <> 0 then begin
      Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', UTCToLocalTime(AValue));
    end else begin
      Result := '';
    end;
  end;

var
  I: Int64;
begin
  I := GetItemIndex(Node);
  case Column of
    0: CellText := Format('%.4d', [I+1]);
    1: CellText := _FormatDateTime(FEvents[I].TimeStamp);
    2: CellText := _FormatName(FEvents[I].GUID);
    3: CellText := FEvents[I].Version;
    4: CellText := _FormatDateTime(FEvents[I].LastModified);
  end;
end;

procedure TfrmEventLogViewer.OnVTHeaderClick(
  Sender: TVTHeader;
  HitInfo: TVTHeaderHitInfo
);
begin
  if Sender.SortDirection = sdAscending then begin
    Sender.SortDirection := sdDescending;
  end else begin
    Sender.SortDirection := sdAscending;
  end;
end;

procedure TfrmEventLogViewer.OnVTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Int64;
  VNode: PVirtualNode;
  VResult: TModalResult;
begin
  if (Key <> VK_DELETE) or (FVirtualTree.SelectedCount <> 1) then begin
    Exit;
  end;

  VNode := FVirtualTree.FocusedNode;
  if VNode = nil then begin
    Exit;
  end;

  I := GetItemIndex(VNode);

  VResult := MessageDlg(
    'Delete record #' + IntToStr(I + 1) + ' from the database?',
    mtConfirmation, [mbYes, mbCancel], 0
  );

  if VResult = mrYes then begin
    try
      FStorage.DeleteItem(FEvents[I].ID);
      UpdateTree;
    except
      on E: Exception do begin
        MessageDlg(
          'Can''t delete record #' + IntToStr(I + 1) + ' from the database.' + #13#10 +
          E.ClassName + ': ' + E.Message,
          mtError, [mbOK], 0
        );
      end;
    end;
  end;
end;

procedure TfrmEventLogViewer.UpdateFormCaption(const ANode: PVirtualNode);
var
  I: Int64;
  VCount: Integer;
  VInfo: TGuidInfo;
begin
  I := GetItemIndex(ANode);
  if FGuidInfo.TryGetValue(FEvents[I].GUID, VInfo) then begin
    VCount := VInfo.ItemsCount;
  end else begin
    VCount := 0;
  end;
  Self.Caption := Format('Time Line [%d/%d]', [VCount, Length(FEvents)]);
end;

procedure TfrmEventLogViewer.OnVTFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  UpdateFormCaption(Node);
  FVirtualTree.Refresh;
end;

end.
