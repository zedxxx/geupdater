unit frm_About;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  StdCtrls,
  ShellAPI,
  ExtCtrls,
  u_BaseForm;

type
  TfrmAbout = class(TBaseForm)
    txtVersion: TStaticText;
    txtBuild: TStaticText;
    txtCopyright: TStaticText;
    txtHomePage: TStaticText;
    btnOk: TButton;
    procedure FormShow(Sender: TObject);
    procedure txtHomePageClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TfrmAbout.FormShow(Sender: TObject);

  function _LinkerTimeStamp: TDateTime;
  var
    VHeaders: PImageNtHeaders;
  begin
    VHeaders := PImageNtHeaders(HInstance + UIntPtr(PImageDosHeader(HInstance)._lfanew));
    Result := VHeaders.FileHeader.TimeDateStamp / SecsPerDay + UnixDateDelta;
  end;

var
  VBuildTime: TDateTime;
resourcestring
  rsBuildCaptionFmt = 'Build: %s UTC';
begin
  VBuildTime := _LinkerTimeStamp;
  txtBuild.Caption := Format(rsBuildCaptionFmt, [FormatDateTime('yyyy-mm-dd hh:nn:ss', VBuildTime)]);
  txtCopyright.Caption := 'Copyright ' + #169 + ' 2009-' + FormatDateTime('yyyy', VBuildTime) + ', zed';
end;

procedure TfrmAbout.txtHomePageClick(Sender: TObject);
begin
  ShellExecute(Application.Handle, PChar('open'), PChar(txtHomePage.Caption), nil, nil, SW_SHOW);
end;

procedure TfrmAbout.btnOkClick(Sender: TObject);
begin
  Close;
end;

end.
