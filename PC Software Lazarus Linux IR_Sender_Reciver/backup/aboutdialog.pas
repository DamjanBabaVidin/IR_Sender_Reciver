// BorderStyle bsDialog
// ShowInTaskBar stNewer


unit AboutDialog;

{$mode objfpc}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls,fileinfo,lclintf, Buttons;

type

  { TFAboutDialog }

  TFAboutDialog = class(TForm)
    ButtonClose: TButton;
    ImageAppIcon: TImage;
    ImageAuthor: TImage;

    LabelAppName: TLabel;
    LabelVersion: TLabel;

    LabelAppDetails: TLabel;
    LabelWebLinkProject: TLabel;
    LabelWebLinkAuthor: TLabel;
    LabelCopyright2: TLabel;
    LabelCopyright1: TLabel;
    LabelGPL: TLabel;

    Memo1: TMemo;
    SpeedButtonCredits: TSpeedButton;     // Не намерих Код за оцветяване на бутон, освен това с TSpeedButton
    SpeedButtonLicense: TSpeedButton;

    procedure FormCreate(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure LabelWebLinkAuthorClick(Sender: TObject);
    procedure LabelWebLinkProjectClick(Sender: TObject);
    procedure LabelWebLinkMouseEnter(Sender: TObject);
    procedure LabelWebLinkMouseLeave(Sender: TObject);
    procedure SpeedButtonCreditsClick(Sender: TObject);
    procedure SpeedButtonCreditsPaint(Sender: TObject);
    procedure SpeedButtonLicenseClick(Sender: TObject);
    procedure SpeedButtonLicensePaint(Sender: TObject);
  private
    procedure ShowHideControls(const b1,b2: boolean);
  public

  end;

var
  FAboutDialog: TFAboutDialog;
  bButtonLicense : boolean = false;
  bButtonCredits : boolean = false;
  ButtonCreditsTextWidth : integer = 0;
  ButtonCreditsTextHeight: integer = 0;
  ButtonLicenseTextWidth : integer = 0;
  ButtonLicenseTextHeight: integer = 0;

const
     clBlueButtonFace = $81871f ;{//$ff8124;//$f4ff48;//;//$ff2525;//$AACC02;  $BBGGRR  }
     GPL_ROW1 = 'IR Sender Reciver is free software; you can redistribute it and/or modify it under the terms'+
                ' of the GNU General Public License as published by the Free Software Foundation;'+
                ' either version 2 of the License, or (at your option) any later version. ';
     GPL_ROW2 ='IR Sender Reciver is distributed in the hope that it will be useful,'+
                ' but WITHOUT ANY WARRANTY; without even the implied warranty of'+
                ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.'+ LineEnding +
                '  See the GNU General Public License for more details. ;';

     Author_ROW1 = 'Написано от: Дамян БабаВидин '+ LineEnding+'Created by: Damjan BabaVidin'+ LineEnding +
                   'https://www.youtube.com/channel/UCC3VEIywd4jmNeerrD_8sPw'+ LineEnding;
     Author_ROW2 = 'Use Serial Port Component for Lazarus : LazSerial v0.3 by Jurassic Pork'+ LineEnding +
                   ' Based on  :'+ LineEnding +
                   '- SdpoSerial v0.1.4'+ LineEnding +
                   '  CopyRight (C) 2006-2010 Paulo Costa'+ LineEnding +
                   '    paco@fe.up.pt'+ LineEnding +

                   '- Synaser library  by Lukas Gebauer ' + LineEnding +
                   '- TcomPort component '+ LineEnding ;
     Author_ROW3 = 'Use IRMP-master Arduino Libarty for STM32F1 microcontrolers :'+ LineEnding +
                   ' IRMP](https://github.com/ukw100/IRMP) - Infrared Multi Protocol Decoder + Encoder';

implementation

{ TFAboutDialog }

procedure TFAboutDialog.ButtonCloseClick(Sender: TObject);
begin
      Close;
end;


// Някоя част от данните се вземат от Project Option
// Целта е да е Унифицирано и од едно място са данните
procedure TFAboutDialog.FormCreate(Sender: TObject);
var
  FileVerInfo: TFileVersionInfo;
begin
      FileVerInfo:=TFileVersionInfo.Create(nil);

      try
         FileVerInfo.ReadFileInfo;

         FAboutDialog.Caption:='About ' + FileVerInfo.VersionStrings.Values['ProductName'];
         LabelAppName.Caption:=FileVerInfo.VersionStrings.Values['ProductName'];

         LabelVersion.Caption:=FileVerInfo.VersionStrings.Values['FileDescription'];
         LabelVersion.Caption:=FileVerInfo.VersionStrings.Values['FileVersion'];

         LabelAppDetails.Caption:= FileVerInfo.VersionStrings.Values['Comments'];

         LabelCopyright1.Caption:=FileVerInfo.VersionStrings.Values['CompanyName'];
         LabelCopyright2.Caption:=FileVerInfo.VersionStrings.Values['LegalCopyright'];

      finally
        FileVerInfo.Free;
      end;

      LabelWebLinkProject.Font.Color := clBlue ;
      LabelWebLinkAuthor.Font.Color  := clBlue ;
      Memo1.Visible:=false;

      // Трябва ни Width,Height na teksta ba tezi buttoni за да го центрираме posle. Wzemamae go edin pyt
      SpeedButtonCredits.Canvas.GetTextSize(SpeedButtonCredits.Caption,ButtonCreditsTextWidth,ButtonCreditsTextHeight);
      SpeedButtonLicense.Canvas.GetTextSize(SpeedButtonLicense.Caption,ButtonLicenseTextWidth,ButtonLicenseTextHeight);
end;
// Тя се извиква всеки път преди .ShowModal;
// ресетваме тези неща
procedure TFAboutDialog.FormShow(Sender: TObject);
begin
      bButtonCredits:= false;
      bButtonLicense:= false;

      ShowHideControls(bButtonCredits,bButtonLicense);
end;
procedure TFAboutDialog.ShowHideControls(const b1,b2: boolean);
var bShowMemo: boolean;
begin
      bShowMemo:=   b1 OR b2 ;  // Място If
      Memo1.Visible:=bShowMemo;

      LabelAppDetails.Visible    := NOT bShowMemo;
      LabelWebLinkProject.Visible:= NOT bShowMemo;
      LabelWebLinkAuthor.Visible := NOT bShowMemo;
      LabelCopyright2.Visible    := NOT bShowMemo;
      LabelCopyright1.Visible    := NOT bShowMemo;
      LabelGPL.Visible           := NOT bShowMemo;
end;
procedure TFAboutDialog.LabelWebLinkProjectClick(Sender: TObject);
begin
      OpenURL('https://github.com/');
end;

procedure TFAboutDialog.LabelWebLinkAuthorClick(Sender: TObject);
begin
     OpenURL('https://www.youtube.com/channel/UCC3VEIywd4jmNeerrD_8sPw');
end;

procedure TFAboutDialog.LabelWebLinkMouseEnter(Sender: TObject);
begin
           TLabel(Sender).Cursor := crHandPoint;   //cursor changes into handshape when it is on StaticText
           TLabel(Sender).Font.Color := clRed ;// clAqua ;    //StaticText changes color into blue when cursor is on StaticText
end;

procedure TFAboutDialog.LabelWebLinkMouseLeave(Sender: TObject);
begin
      TLabel(Sender).Font.Color := clBlue ;   //when cursor is not on StaticText then color of text changes into default color
end;

procedure TFAboutDialog.SpeedButtonCreditsClick(Sender: TObject);
var  textColor : TColor;
begin
      bButtonCredits:=NOT bButtonCredits;

      if ( bButtonCredits ) then
       begin
             textColor:= clBtnFace;
           // Ако е натиснат този буттон, да се прерисува
           if bButtonLicense then
            begin
                bButtonLicense:=false;
                SpeedButtonLicense.Invalidate;
            end;
           Memo1.Text:=Author_ROW1+ LineEnding+ Author_ROW2+ LineEnding+Author_ROW3;
       end
      else textColor:= clBtnText;

      TLabel(Sender).Font.Color := textColor ;

      ShowHideControls(bButtonCredits,bButtonLicense);
end;



procedure TFAboutDialog.SpeedButtonLicenseClick(Sender: TObject);
var  textColor : TColor;
begin
      bButtonLicense:=NOT bButtonLicense;

      if ( bButtonLicense ) then
      begin
           textColor:= clBtnFace;

           // Ако е натиснат този буттон, да се прерисува
           if bButtonCredits then
            begin
                bButtonCredits:=false;
                SpeedButtonCredits.Invalidate;
            end;
           Memo1.Text:=GPL_ROW1+ LineEnding+ LineEnding+ GPL_ROW2;
      end
      else textColor:= clInfoText;

      TLabel(Sender).Font.Color := textColor ;

      ShowHideControls(bButtonCredits,bButtonLicense);
end;
procedure TFAboutDialog.SpeedButtonCreditsPaint(Sender: TObject);
var ARect: TRect;
begin
       ARect:=TSpeedButton(Sender).ClientRect;

       if bButtonCredits then
        begin
             TSpeedButton(Sender).Canvas.Brush.Color := clBlueButtonFace; // change background
             TSpeedButton(Sender).Font.Color:= clBtnFace;                 // change text color
        end
        else
        begin
              TSpeedButton(Sender).Canvas.Brush.Color := clBtnFace;      // change background
              TSpeedButton(Sender).Font.Color:= clInfoText;              // change text color
        end;

        TSpeedButton(Sender).Canvas.Rectangle(ARect);// Пълни ARect с Brush.Color

        TSpeedButton(Sender).Canvas.TextOut( ARect.Left + 2 + ( ARect.Width -4 -ButtonCreditsTextWidth )div 2, // Центрираме Хоризонтално
                                             ARect.Top  + 2 + ( ARect.Height-4 -ButtonCreditsTextHeight )div 2, // Центрираме Вертикалално
                                             TSpeedButton(Sender).Caption);               // write caption/text
end;
procedure TFAboutDialog.SpeedButtonLicensePaint(Sender: TObject);
var ARect: TRect;
begin
       ARect:=TSpeedButton(Sender).ClientRect;
       if bButtonLicense then
        begin
             TSpeedButton(Sender).Canvas.Brush.Color := clBlueButtonFace; // change background
             TSpeedButton(Sender).Font.Color:= clBtnFace;                 // change text color
        end
        else
        begin
              TSpeedButton(Sender).Canvas.Brush.Color := clBtnFace;      // change background
              TSpeedButton(Sender).Font.Color:= clInfoText;              // change text color
        end;

       TSpeedButton(Sender).Canvas.Rectangle(ARect);                     // Пълни ARect с Brush.Color

       TSpeedButton(Sender).Canvas.TextOut( ARect.Left + 2 + ( ARect.Width -4 -ButtonLicenseTextWidth  )div 2, // Центрираме Хоризонтално
                                            ARect.Top  + 2 + ( ARect.Height-4 -ButtonLicenseTextHeight )div 2, // Центрираме Вертикалално
                                            TSpeedButton(Sender).Caption);                                     // write caption/text

end;



initialization
  {$I aboutdialog.lrs}

end.

