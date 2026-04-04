unit u_BaseForm;

interface

uses
  System.Classes,
  VCL.Forms;

type
  TBaseForm = class(TForm)
  protected
    procedure ReadState(Reader: TReader); override;
  end;

implementation

procedure TBaseForm.ReadState(Reader: TReader);
begin
  inherited;
  {$IF CompilerVersion <= 34} // Delphi 10.4 and older
  OldCreateOrder := False;
  {$IFEND}
end;

end.
