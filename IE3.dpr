program IE3;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainForm in 'MainForm.pas' {Form1},
  normalizer in 'normalizer.pas';

{$R *.res}

begin
    //ReportMemoryLeaksOnShutdown := DebugHook <> 0;

    Application.Initialize;
    Application.FormFactor.Orientations := [TFormOrientation.Portrait, TFormOrientation.InvertedPortrait, TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
