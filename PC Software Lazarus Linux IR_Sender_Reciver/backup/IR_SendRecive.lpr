program IR_SendRecive;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, runtimetypeinfocontrols,
  { you can add units after this } Main, LazSerialPort, AboutDialog;

{$R *.res}

begin
  Application.Title:='IR Sender Reciver';
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TFAboutDialog, FAboutDialog);
  Application.Run;
end.

