// Ползва ардуино проект IRMP_master
// TButton BSendCommandClick->Properties->Default=true, тогава ентер в EditSendCommand е също като буттон клик
// Това е добавено в някой функции {%H-} да не вади warning: Parameter "някакъв" not used
unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, LazSerial,
  StdCtrls, ExtCtrls, ComCtrls, CheckLst, inifiles, lazsynaser, IRMP_master,
  lazutf8, FileUtil, LazFileUtils, LCLProc, Types, LCLType, Menus, AboutDialog, LCL, MyUtils;// za test dobaveni

type
     ReciveCoommandType =
    (
       none,
       identify,
       info,
       overflow,
       IR_code,
       Protokols_Set,
       Protokols_Get,
       IR_decode_error,
       Command_decode_error,
       unknown
     );

    { TBaseThread }
    TBaseThread = class(TThread)
    public
      procedure Log(const Msg: string); //AppendLineEnd: boolean = true);
      procedure ThreadUpdateButtons();
    end;

    { TThreadConect }

    TThreadConect = class(TBaseThread)
    public
      EventConect: PRtlEvent;
      procedure Execute; override;
    end;


  { TFMain }
  TFMain = class(TForm)

    BConnect  : TButton;
    BClose    : TButton;
    BClearMemo: TButton;
    BSendCommand: TButton;

    CheckListBox1: TCheckListBox;
    Memo: TMemo;
    EditSendCommand: TEdit;
    ImageList1: TImageList;

    MainMenu1: TMainMenu;
    MenuItemAbout: TMenuItem;
    Serial: TLazSerial;
    StatusBar1: TStatusBar;
    Timer1: TTimer;

    procedure BClearMemoClick(Sender: TObject);
    procedure BCloseClick(Sender: TObject);
    procedure BConnectClick(Sender: TObject);
    procedure BSendCommandClick(Sender: TObject);// Изпраща данните от EditSendCommand по Серийния Порт

    procedure EditSendCommandKeyDown(Sender: TObject; var Key: Word;{%H-}Shift: TShiftState);   // Същото при натискане Ентер в TEdit,  {%H-} да не вадят warning not used
    procedure EditSendCommandKeyUp(Sender: TObject; var {%H-}Key: Word;{%H-}Shift: TShiftState);// Двете работят заедно

    procedure CheckListBox1DrawItem({%H-}Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure CheckListBox1ShowHint(Sender: TObject; HintInfo: PHintInfo);

    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);

    procedure MenuItemAboutClick(Sender: TObject);

    procedure SerialRxData(Sender: TObject);
    procedure SerialStatus(Sender: TObject; Reason: THookSerialReason; const Value: string);

    procedure IniWrite;
    procedure IniRead;
  private
    { private declarations }
    ACriticalSection: TRTLCriticalSection;
    ThreadMsgArr: TStringList;
 //   flagLockDevice: boolean;
    procedure AddMessage;
    procedure UpdateButtons;
    procedure ListBoxAddProtokols();
    procedure WindowsRectCheck(var frameRect : TRect);
    procedure SerialSendString(const sData : String;const bMemoAdd: boolean);
  public
    { public declarations }
     procedure UpdateProtokolsList(const sIn: string);
     procedure ProcessNewRow(const sRow: string);
     function  DecodeCommand(const sIn: string): ReciveCoommandType;
     procedure MemoAddNewRow(const sRow: string);
     procedure SendCommand();

  public
     ThreadConect: TThreadConect;

  end;

var
  FMain: TFMain;
  RxRowBuffer: String;
  flagIdentifed: Boolean = false;
  flagScaning  : Boolean = false;
  Ini_LastUsedPort: string;
  flagKeyUp   : Boolean = true;   // Флаг за TEditSendCommand, когато е отпуснат клавиша

  INI_WindowsMaximized : boolean;
  INI_WindowsWidth     : Longint;
  INI_WindowsHeight    : Longint;
  INI_WindowsPoint     : TPoint;


const
  DEBUG                           = true;
  MEMO_MAX_LINE_COUNT             = 1000;
  TERMINAL_TEXT_SEND              = '-> Send Command: ';
  TERMINAL_TEXT_SCAN_SERIAL_PORTS = 'Scan Serial Ports';
  TERMINAL_TEXT_ERROR_SEND        = '-> ERROR Send Command Port is CLOSD :';
  COMMAND_SEND_PROTOCOLS_GET      = 'Protocols Get';
  COMMAND_SEND_IDETIFY            = 'identify';
  COMMAND_RECIVE_PROTOCOLS_DATA   = 'Protocols :';
  COMMAND_RECIVE_IDETIFY          = 'IR Send Recive USB-Serial Daemon';
  COMMAND_APPLICATION_CLOSE       = 'Application Close';

implementation
{$R *.lfm}


{ TFMain }

procedure TFMain.FormCreate(Sender: TObject);
begin
 // Add App minimum size = 80% of Originall TFMain size from resource
 Constraints.MinWidth := Width - ( Width  div 100  )*20;
 Constraints.MinHeight:= Height- ( Height div 100 )*20;

 IniRead;

 Memo.DoubleBuffered := true;
 BSendCommand.Caption :=  StringReplace(BSendCommand.Caption, '\n', SLineBreak, [rfReplaceAll]); // Неможе в едитора да се сложи дворедов текст,тук мениме '\n' в SLineBreak

 CheckListBox1.Color:=clInactiveBorder ;//clLtGray;//clGrayText;// clInactiveBorder;//clInactiveCaption;
 ListBoxAddProtokols();

 ThreadMsgArr := TStringList.Create();
 InitCriticalSection(ACriticalSection);

 if ThreadConect=nil then                      // Тук я пускаме и си чака EventConect за да сканира за IR устройство
    ThreadConect:=TThreadConect.Create(false);
end;
// Тя е след FormCreate
procedure TFMain.FormActivate(Sender: TObject);
begin
     Serial.BaudRate   := br115200;
     Serial.DataBits   := db8bits;
     Serial.StopBits   := sbOne;
     Serial.Parity     := pNone;
     Serial.FlowControl:= fcNone;
end;
procedure TFMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
      if ( Serial.Active ) then
        begin
          Serial.WriteData(COMMAND_APPLICATION_CLOSE );
          MemoAddNewRow(TERMINAL_TEXT_SEND +COMMAND_APPLICATION_CLOSE);
         end;
      if Serial.Active then
        Serial.Active := false ;

      IniWrite;

      Application.Terminate;
end;
procedure TFMain.FormDestroy(Sender: TObject);
begin
     DoneCriticalsection(ACriticalSection);
     ThreadMsgArr.Free;
end;

// Само Тук Можем да Вземем точно Width и Height, при WindowState == wsNormal
procedure TFMain.FormResize(Sender: TObject);
begin
      if ( WindowState <> wsNormal ) OR (RestoredWidth =0 ) OR ( RestoredHeight =0 )  then // Първия път  RestoredWidth, Height ==0 това обърква FormShow, пропускаме този вариант
        exit;

      Ini_WindowsWidth  := RestoredWidth;
      Ini_WindowsHeight := RestoredHeight;
end;
// Тук може да се Мени Размера на виндовса и  wsMaximized
procedure TFMain.FormShow(Sender: TObject);
var INI_WindowsRect: TRect;
begin
      WindowState := wsNormal;      // Правиме виндовса в началото да е да е wsNormal

      INI_WindowsRect:=Bounds(INI_WindowsPoint.x, INI_WindowsPoint.y, INI_WindowsWidth, INI_WindowsHeight );

      WindowsRectCheck( INI_WindowsRect ); // Ако  Rect не е в прозореца или е поголям, нормализира размерите и позицията

     // Може и така място BoundsRect
     //Left  := INI_WindowsPoint.x;  Top   := INI_WindowsPoint.y ;  Width := INI_WindowsWidth ;  Height:=INI_WindowsHeight ;
     BoundsRect := INI_WindowsRect;// Това е Размер и координатати на wsNormal Виндовс

     if INI_WindowsMaximized then WindowState:= wsMaximized ;  // Трябва да се Смени Тук и е след BoundsRec, Ако е във FormCreate, губят се размерите
end;

procedure TFMain.MenuItemAboutClick(Sender: TObject);
begin
      FAboutDialog.ShowModal;       // FAboutDialog.Show;
end;

// Испраща командата од EditSendCommand по Serial Порта
// извиква я BSendCommandClick или EditSendCommandKeyDown
procedure TFMain.SendCommand();
var
 Str: String;
begin
      Str := EditSendCommand.text;  // Str := Str + inttohex(checksum(Str),2)+ Char(13)+ Char(10);
      if Str.length>0 then Serial.WriteData(Str);
end;

// При BSendCommandClick Испраща командата од EditSendCommand по Serial Порта
procedure TFMain.BSendCommandClick(Sender: TObject);
begin
     SendCommand();
end;

// При Ентер в TEditSendCommand Испраща командата по Serial Порта
// да не се дублира многократно, ползваме и Флаг flagKeyUp, вдига се в EditSendCommandKeyUp
procedure TFMain.EditSendCommandKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    if ( Key=13 ) AND ( flagKeyUp )then      //VK_RETURN
    begin
         SendCommand();   // Това изпраща командата
         // Key := 0;
         flagKeyUp:=false; // За да не се повтаря, натиска при задържане на бутона, движим и този флаг
    end;
end;

// За да не се повтаря, натиска при задърюане на бутона, движим и този флаг, тук вдига флага
procedure TFMain.EditSendCommandKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
      flagKeyUp:=true;
end;

procedure TFMain.BCloseClick(Sender: TObject);
begin
      if ( Serial.Active ) then
      begin
           Serial.WriteData(COMMAND_APPLICATION_CLOSE );
           MemoAddNewRow(TERMINAL_TEXT_SEND +COMMAND_APPLICATION_CLOSE);
      end;

      Serial.Close;
end;
// Тук праща EventConect, до нишката ThreadConect
// Отделно Enable-Disable контроли
procedure TFMain.BConnectClick(Sender: TObject);
begin
     RtlEventSetEvent(FMain.ThreadConect.EventConect);
end;

procedure TFMain.BClearMemoClick(Sender: TObject);
begin
      Memo.Clear;
end;
procedure TFMain.SerialSendString(const sData : String;const bMemoAdd: boolean);
begin
     if ( Serial.Active ) then
      begin
           Serial.WriteData(sData);
           if  bMemoAdd then MemoAddNewRow(TERMINAL_TEXT_SEND +sData)
      end
     else MemoAddNewRow( TERMINAL_TEXT_ERROR_SEND  + sData);
end;

// Получен е някакъв ред од серийния порт, данните са чисти без EOLN знака
// Добавя ред в Memo
// Интерпретира данните, ако са команд изпълнява
procedure TFMain.ProcessNewRow(const sRow: string);
begin
      MemoAddNewRow(sRow);

      sRow.Trim;
      case  DecodeCommand(sRow) of
            Protokols_Get: UpdateProtokolsList(sRow);
            identify     : begin
                                flagIdentifed:=true;
                                Serial.WriteData(COMMAND_SEND_PROTOCOLS_GET);
                                MemoAddNewRow(TERMINAL_TEXT_SEND +COMMAND_SEND_PROTOCOLS_GET);
                           end
            else       ;//Other, Unknown
      end;
end;

// Получен е някакъв ред од серийния порт, данните са чисти без EOLN знака
// Тук декодира каква команда е и Върща ReciveCoommandType
function TFMain.DecodeCommand(const sIn: string): ReciveCoommandType;
 var i: Integer;
  begin
   // 'Protocols :1111111111111111111111011111011101000011111000101110101100'

   if ( sIn.StartsWith(COMMAND_RECIVE_PROTOCOLS_DATA) ) then
   begin
         if ( sIn.Length <> ( IRMP_N_PROTOCOLS+length(COMMAND_RECIVE_PROTOCOLS_DATA) ) ) then
           exit ( Command_decode_error );

         for i := length(COMMAND_RECIVE_PROTOCOLS_DATA)+1  to High(sIn) do  //for i := Low(sIn) to High(sIn) do
         begin
                if ( sIn[i]<>'0' ) AND ( sIn[i]<>'1' ) then
                 exit ( Command_decode_error );
         end;
     exit( Protokols_Get );
   end
   //'IR Send Recive USB-Serial Daemon'
   else if ( sIn = COMMAND_RECIVE_IDETIFY ) then exit( identify );

   result := none;      // towa da se vidi
 end;

// Синтакса е вред 'Protocols :1111111111111111111111011111011101000011111000101110101100'
// Update чавките в CheckListBox1
procedure TFMain.UpdateProtokolsList(const sIn: string);
  var i,sIndex: Integer;
begin
      for i := 0 to CheckListBox1.Count-1 do //   for i := length(COMMAND_RECIVE_PROTOCOLS_DATA)+1  to High(sIn) do  //for i := Low(sIn) to High(sIn) do
      begin
         sIndex:= i+ length(COMMAND_RECIVE_PROTOCOLS_DATA)+1;
         if (sIndex in [ Low(sIn) .. High(sIn)]) then
                  CheckListBox1.Checked[i]:= sIn[ i+ length(COMMAND_RECIVE_PROTOCOLS_DATA)+1]='1'
         else
              begin
                  ShowMessage('Error UpdateProtokolsList(const sIn: string);  if (sIndex in [ Low(sIn) .. High(sIn)]) then  ');
                  break;
              end;
      end;
end;
// Малко упражнение за CheckListBox1, като е дисабле, не работи Скрола, затова я правим lbOwnerDrawFixed
// ние определяме цветовете, там също има проблем odFocused не работи
// Решили сме го по този начин
procedure TFMain.CheckListBox1DrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
    with CheckListBox1.Canvas do
    begin
         // if odFocused in State then // Това не работи
         // DrawFocusRect(ARect);      // това също
        if ( CheckListBox1.Focused )AND ( odSelected in State ) then  // Когато фокуса е върхо CheckListBox1 и реда е селектиран
        begin
             Brush.Color := clHighlight;
             Font.Color  := clHighlightText;
        end
        else                                                         // Всички други варианти
        begin
             Brush.Color := CheckListBox1.Color;
             Font.Color  := clGrayText ;
        end;
        FillRect(ARect);                                            // Тук боядисва, този правоъгълник под текста, за всеки итем
        TextOut(ARect.Left, ARect.Top, CheckListBox1.Items[Index]); // Тук пише текста, за съответния итем
  end;
end;

// Чете данните от серийния порт
// Може да идват на порции, трупа ги в FTempStr /самата процедура може да се извиква повече пъти/
// Когато намери Char(10)- края на реда прехвърля данните в Memo.Lines и изпълнява коммандата
// EOLN_L= #10;    //Line feed (LF, #10 ): Linux, macOS, BSDs, Unix,
// EOLN_M= #13;    //Carriage return (CR, #13): Mac OS Classic
// EOLN  = #13#10; //Carriage return + Line feed (CRLF, #13#10): Microsoft Windows
// Обхванати са повечето варианти за края на реда, Ползва ардуино проект IRMP_master, ардуиното някога изпраща #10, някога #13#10
// Целта е да не се мени твърде много основния проект, затова тук съм обхванал трите варианта за EOLN
// има един недостатък, не знам дали е възможен ако Rx сплитне даните пр. ABC#13  #10D ще ги отчита като два реда
// Също ако има стари счупени  данни без EOLN, новите ще ги трупа въхо тях и синтакса няма да е верен.
// !!! евентуално да се добави tajmer i след известно време да празни този FTempStr буфер
procedure TFMain.SerialRxData(Sender: TObject);
var
    RxData: string;
    i:integer;
    bEOLN_M:boolean;
begin
   RxData:=  Serial.ReadData;   //Вземаме каквото е прочел порта
   bEOLN_M:=false;
   // Обработва получените данни
   for i := Low(RxData) to High(RxData) do
    begin
         case  RxData[i] of
                 #13: // EOLN_M= #13;    //Carriage return (CR, #13): Mac OS Classic
                      // два пъти под ред се дават #13#13, или #13 е последен приет знак, предаваме предишните данни и bEOLN_M остава true
                     if ( bEOLN_M=true ) OR ( i =High(RxData) ) then
                     begin
                           ProcessNewRow(RxRowBuffer);
                           RxRowBuffer:='';
                      end
                     else  bEOLN_M:=true;  // намерено е първи път

                 #10:   // Line feed (LF, #10 ): Linux, macOS, BSDs, Unix, Когато е #10, без начение дали е   #10 или #13#10
                        // EOLN  = #13#10; //Carriage return + Line feed (CRLF, #13#10): Microsoft Windows
                     begin
                           ProcessNewRow(RxRowBuffer);
                           RxRowBuffer:='';
                           bEOLN_M:=false;
                      end;
                 else // не е крй на реда
                     if bEOLN_M=true then      //abcd#13A предава abcd, започва новите A
                     begin
                           ProcessNewRow(RxRowBuffer);
                           RxRowBuffer:= RxData[i];
                           bEOLN_M:=false;
                      end  else RxRowBuffer:= RxRowBuffer + RxData[i]; // Няма никакъв EOLN и трупа всички дани в FTempStr
              end;//case
    end;//for
end;

// Add new Row in Memo, include empty rows
// Process Memo max row limit
procedure TFMain.MemoAddNewRow(const sRow: string);
begin
      Memo.Lines.BeginUpdate;

      while Memo.Lines.Count > MEMO_MAX_LINE_COUNT do  // Когато надвишат MEMO_MAX_LINE_COUNT, трие старите редове
         Memo.Lines.Delete(0);

      Memo.Lines.Add(sRow);
      Memo.Lines.EndUpdate;

      Memo.SelStart := Length(Memo.Lines.Text); // оригинал Memo.SelStart := Length(Memo.Lines.Text)-1;
      Memo.SelLength:=0;
end;

// Има проблем, HR_SerialClose не винаги се испраща
// ако затворим serial.close работи, но ако прекъснем конекцията тогава не го регистрира
procedure TFMain.SerialStatus(Sender: TObject; Reason: THookSerialReason;
  const Value: string);
begin
  case Reason of
    HR_SerialClose :
                    begin
                          StatusBar1.SimpleText := 'Port ' + Value + ' closed';
                          flagIdentifed:=false;  // От някаква причина се прекъсне конекцията/това не работи/
                          UpdateButtons;   // Enable, disable buttons
                    end;
    HR_Connect :
                  begin
                         StatusBar1.SimpleText := 'Port ' + Value + ' connected';
                         UpdateButtons;   // Enable, disable buttons
                  end;
//    HR_CanRead :   StatusBar1.SimpleText := 'CanRead : ' + Value ;
//    HR_CanWrite :  StatusBar1.SimpleText := 'CanWrite : ' + Value ;
//    HR_ReadCount : StatusBar1.SimpleText := 'ReadCount : ' + Value ;
//    HR_WriteCount : StatusBar1.SimpleText := 'WriteCount : ' + Value ;
    HR_Wait :  StatusBar1.SimpleText := 'Wait : ' + Value ;
  end ;

end;


// Вначалото зарежда в CheckListBox1 протоколите ARR_protocols
// В момента не може да се програмира IR устройството от тук, затова всички чавки са disabled
// Може и генерално да се сложи CheckListBox1 -> enable фалсе, но тогава скрола не работи, затова всека чавка отделно слагаме ItemEnabled[i-1]:=false;
// Плюс има цял модул около цветовете - CheckListBox1DrawItem
procedure TFMain.ListBoxAddProtokols();
var
      i: integer;
begin
      // създаваме items в CheckListBox1
      for i := Low(ARR_protocols) to High(ARR_protocols) do
      begin
           CheckListBox1.items.add( format('%2d - ',[ARR_protocols[i].index])+ ARR_protocols[i].name );
           CheckListBox1.ItemEnabled[i-1]:=false;   // тук го меним да е disabled
      end;
end;

// когато мишката е върхо Item показва детайли за протокола tooltip
procedure TFMain.CheckListBox1ShowHint(Sender: TObject; HintInfo: PHintInfo);
var hintItem : Integer;
begin
 // if (HintInfo^.HintControl = CheckListBox1) and (CheckListBox1.ItemAtPos(HintInfo^.CursorPos, True) > -1) then
 //     HintInfo^.HintStr := CheckListBox1.Items[CheckListBox1.ItemAtPos(HintInfo^.CursorPos, True)];
    if (HintInfo^.HintControl <> CheckListBox1) then
     exit;

     hintItem:=  CheckListBox1.ItemAtPos(HintInfo^.CursorPos, True);
     if  ( hintItem =  -1) then
      exit;
     hintItem:=hintItem+1;
     if (hintItem in[Low(ARR_protocols)..High(ARR_protocols)] ) then
     HintInfo^.HintStr :=  ARR_protocols[hintItem ].tooltip ;

end;
// Увисва ако тук има CriticalSection
// Предполагам че Synchronize(@FMain.AddMessage);  се испълнява веднага, може би няма нуюда от арр, а само стринг
procedure TFMain.AddMessage;
begin
     while ThreadMsgArr.Count > 0 do  // Когато надвишат MEMO_MAX_LINE_COUNT, трие старите редове
      begin
            MemoAddNewRow(ThreadMsgArr[0]);
            ThreadMsgArr.Delete(0);
      end;
end;
procedure TFMain.UpdateButtons;
begin
      if flagIdentifed then Ini_LastUsedPort := Serial.Device
                       else Ini_LastUsedPort := '';

      EditSendCommand.Enabled:=flagIdentifed;
      BSendCommand.Enabled   :=flagIdentifed;
      BClose.Enabled         :=flagIdentifed;

     if flagScaning then         BConnect.Caption:= 'Scanning...'
      else if flagIdentifed then BConnect.Caption:= 'Reconnect'
                            else BConnect.Caption:= 'Connect';

     BConnect.Enabled:=NOT flagScaning;  // Този буттон винаги е пуснат, освен когато скенира
end;

{ TThreadConect }

// Стартира се в FormCreate и чака EventConect
// Когато получи евента, на ново сканира за Серийни портове и търси търси нащето устройство
procedure TThreadConect.Execute;
Var sl: TStringList;
     iFind: integer;
     PortName: string;
begin
  // create event
  EventConect:=RTLEventCreate;

  sl := TStringList.Create;
  try

    while not Application.Terminated do
    begin
         dbgout( 'ThreadConect wait for EventConect'+ LineEnding );
         flagScaning:=false;

         ThreadUpdateButtons();
         RtlEventWaitFor(EventConect);  // wait infinitely (until EventConect)
         flagIdentifed:=false;
         flagScaning:=true;

         FMain.Serial.Close;


         sl.AddCommaText(GetSerialPortNamesNEW() ); // вземаме стринг лист със всички намерени серийни портове

         Log(TERMINAL_TEXT_SCAN_SERIAL_PORTS);
         case sl.Count of
              0: Log('Not Found Serial Ports' );
              1: Log('Found 1 Serial Port' );
              else Log(format('Found %d Serial Ports',[sl.Count]) );
         end;

         sl.Sort;

         // За да търси побързо, ако съществува първо опитваме да отворим последният успешно ползван порт,
         if Ini_LastUsedPort.Length>0 then  iFind:= sl.IndexOf(Ini_LastUsedPort )
          else iFind:=-1;

         // Опитва да намери IR устройството, по sl листа
         // контактува с серийния порт и чака отговор
         // Ако намери прекъсва търсенето
         while ( sl.Count>0 ) do
         begin
              if ( iFind <>-1 ) then      // Първо опитваме да отворим,  последният успешно ползван порт,
              begin
                   PortName:= sl[iFind];
                   sl.Delete(iFind);
                   iFind :=-1;
              end
              else                        //
                  begin
                   PortName:= sl[0];
                   sl.Delete(0);
              end;
              Log(PortName);

              FMain.Serial.Close;
              Log('Try to Open Serial Port : ' + PortName );

              FMain.Serial.Device := PortName;//'/dev/ttyUSB1';

              try   // това е за всеки случай, не се активирало за сега
                    FMain.Serial.Open;
              except
                    On E :Exception do begin
                           Log('Serial Port : ' + PortName+' Open Error - Exception : '+E.ToString );  ;
                    end;
              end;

              flagIdentifed:=false;                            // Спускаме флага
              if ( FMain.Serial.Active ) then
              begin
                    Log('Open port: '+ PortName );
                    Log(TERMINAL_TEXT_SEND +COMMAND_SEND_IDETIFY );

                    FMain.Serial.WriteData( COMMAND_SEND_IDETIFY );  // Пуска команда до устройството

                    sleep(3000);                                     // Дава време устройството да отгоовори

                    if ( flagIdentifed = true ) then                 // в FMain->ProcessNewRow, ако идентифицира команда Identify вдига флага
                    begin
                             Log('IR Device Open for Send && Recive');
                             break;
                    end
                    else
                    begin
                            FMain.Serial.Close;
                            Log('IR Device not conected to port: '+PortName);
                            Log('Close port: '+PortName);
                    end;
             end
             else Log('Error Open port: '+ PortName );  ;

         end;//while ( sl.Count>0 ) do

        sl.Clear;
    end;//  while

  finally
     sl.Free;
  end;
end;

{ TBaseThread }
 // Тя е важна, нишката испраща Msg, тук ги трупа в гобално array ThreadMsgArr
 // Тази операция е с ACriticalSection
procedure TBaseThread.Log(const Msg: string );
begin

EnterCriticalsection(FMain.ACriticalSection);
     dbgout( Msg + LineEnding );
     FMain.ThreadMsgArr.Add( Msg );
     Synchronize(@FMain.AddMessage);
LeaveCriticalsection(FMain.ACriticalSection);

end;

procedure TBaseThread.ThreadUpdateButtons();
begin
  //   EnterCriticalsection(FMain.ACriticalSection);

     Synchronize(@FMain.UpdateButtons);

  //   LeaveCriticalsection(FMain.ACriticalSection);
end;

procedure TFMain.IniWrite;
var   IniFile: TiniFile;
begin
  {$IFDEF LINUX}                              // False - store in profile, True - create app subfolder: home/a/.config/IR_Sender_Reciver/IR_Sender_Reciver.cfg
    IniFile := TIniFile.Create( GetAppConfigFile(False, True) );
   {$ELSE}
    IniFile := TIniFile.Create(
    ExtractFilePath(Application.EXEName) + '.ini');
   {$ENDIF}
    try
         IniFile.WriteString ('seting' , 'Port'     , Ini_LastUsedPort          );
         IniFile.WriteBool   ('Windows', 'Maximized', WindowState = wsMaximized );
         IniFile.WriteInteger('Windows', 'Left'     , RestoredLeft              );
         IniFile.WriteInteger('Windows', 'Top'      , RestoredTop               );
         IniFile.WriteInteger('Windows', 'Width'    , INI_WindowsWidth          );
         IniFile.WriteInteger('Windows', 'Height'   , INI_WindowsHeight         );
    finally
         IniFile.Free;  // After the ini file was used it must be freed to prevent memory leaks.
    end;
end;


procedure TFMain.IniRead;
var   IniFile: TiniFile;
begin

   {$IFDEF LINUX}                             // False - store in profile, True - create app subfolder: home/a/.config/IR_Sender_Reciver/IR_Sender_Reciver.cfg
    IniFile := TIniFile.Create( GetAppConfigFile(False, True) );
   {$ELSE}
    IniFile := TIniFile.Create(
    ExtractFilePath(Application.EXEName) + '.ini');
   {$ENDIF}

   try
       Ini_LastUsedPort:=IniFile.ReadString('seting', 'Port', '');

       INI_WindowsMaximized:= IniFile.ReadBool('Windows', 'Maximized', false );
       INI_WindowsPoint.x  := IniFile.ReadInteger('Windows', 'Left'  , -10   );
       INI_WindowsPoint.y  := IniFile.ReadInteger('Windows', 'Top'   , -10   );
       INI_WindowsWidth    := IniFile.ReadInteger('Windows', 'Width' , -1    );
       INI_WindowsHeight   := IniFile.ReadInteger('Windows', 'Height', -1    );
   finally
       IniFile.Free;  // After the ini file was used it must be freed to prevent memory leaks.
     end;

end;



////////////////////////////////////////////////////////////////////////////////
// GUI-то само размества прозореца да е видим при старта, има ситуация при много лоши данни от INI file
// Увисва, тук проверяваме размера и позицията frameRect слрямо Screen.Monitors[indexMax].WorkareaRect
// ако не е видим системата го мести
// !!! Ако е между два монитора, преместваме го там дето е повече
procedure TFMain.WindowsRectCheck(var frameRect : TRect);
var
   i: integer;
   lwidth , lHeight: longint;
   lOwerlapedArea: longint;
   maxOwerlapedArea : longint =0;
   indexMax :integer=-1;
   recMonitor:TRect;
begin

      if frameRect.Width < Constraints.MinWidth then frameRect.Width:= Constraints.MinWidth;
      if frameRect.Height< Constraints.MinHeight then frameRect.Height:= Constraints.MinHeight;

       // Търсим каде се намира прозореца, може да е вънка ор всички монитори
       // Може да е между, 2-3 монитора
      for i := 0 to Screen.MonitorCount - 1 do
      begin

         recMonitor:=Screen.Monitors[i].WorkareaRect;                // Това  е областта за каде може да се намира Windows без таскбар...

         lwidth := GetOverlapedSize( frameRect.Left, frameRect.Width, recMonitor.Left, recMonitor.Width );
         lHeight:= GetOverlapedSize( frameRect.Top, frameRect.Height, recMonitor.Top, recMonitor.Height );

         if ( lwidth>0 ) AND ( lHeight>0 ) then lOwerlapedArea:= lwidth* lHeight
         else lOwerlapedArea:=0;

         if lOwerlapedArea > maxOwerlapedArea then
         begin
              maxOwerlapedArea:= lOwerlapedArea;
              indexMax:=i;
         end;

    end;

       if ( indexMax = -1 ) then PutInRect( frameRect, Screen.WorkareaRect                    ) // Ako frameRect.Width e pogolqmo, namalqwago
                            else PutInRect( frameRect, Screen.Monitors[indexMax].WorkareaRect );// Ako frameRect.Width e pogolqmo, namalqwago

end;


end.

