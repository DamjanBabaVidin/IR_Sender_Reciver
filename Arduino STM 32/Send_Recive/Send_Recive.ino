
/*  IR_Sender_Reciver
 *  Copyright (C) 2021 Damian 
 *  https://github.com/DamjanBabaVidin/IR_Sender_Reciver
 *
/*  irmpSelectMain15Protocols EW=11111101111100011100110010011000000000000000000000000000100
 *  irmpSelectAllProtocols    EW=11111111111111111111111011111011101000011111000101110101100
 *  без протоколи             EW=10000000000000000000000000000000000000000000000000000000000   винаги е включен IRMP_UNKNOWN_PROTOCOL 0    
 *  VOLUME DOWN      P=SIRCS  A=0x0 C=0x813
 *  Ползвано е 
 *  SimpleReceiver.cpp
 *  Accepts 40 protocols concurrently
 *  If you specify F_INTERRUPTS to 20000 at line 86 (default is 15000) it supports LEGO + RCMM protocols, but disables PENTAX and GREE protocols.
 *  if you see performance issues, you can disable MERLIN Protocol at line 88.
 *  Receives IR protocol data of 15 main protocols.
 *
 *  The following IR protocols are enabled by default:
 *      Sony SIRCS
 *      NEC + APPLE
 *      Samsung + Samsg32
 *      Kaseikyo
 *
 *      Plus 11 other main protocols by including irmpMain15.h instead of irmp.h
 *      JVC, NEC16, NEC42, Matsushita, DENON, Sharp, RC5, RC6 & RC6A, IR60 (SDA2008) Grundig, Siemens Gigaset, Nokia
 *
 *  To disable one of them or to enable other protocols, specify this before the "#include <irmp.h>" line.
 *  If you get warnings of redefining symbols, just ignore them or undefine them first (see Interrupt example).
 *  The exact names can be found in the library file irmpSelectAllProtocols.h (see Callback example).
 *
 *  Using this library IRMP https://github.com/ukw100/IRMP.
 *  with author  Armin Joachimsmeyer
 *  armin.joachimsmeyer@gmail.com
 *
 *  IR_Sender_Reciver is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/gpl.html>.
 *
 */
#include <EEPROM.h>
//#include <USBComposite.h>

//USBMultiSerial<1> ms; // Създаваме един Сериен порт на USB буксата на платката

#include <Arduino.h>
#include "MyFunctionConvert.h"
#include "MyFunctionEEprom.h"


#define LED_RED_PIN    5  // Power ON
#define LED_GREEN_PIN  3  // When the linux program connects
#define LED_BLUE_PIN   4  // Send_Recive
#define EEPROM_DATA_ADRSESS  0x10

typedef  enum ReciveCoommandType
{
  none,
  identify,
  info,
  overflow,
  IR_code,
  Protokols_Set,
  Protokols_Get,
  Application_Close,
  IR_decode_error,
  Command_decode_error,
  unknown
}ReciveCoommandType_t;

/*
 * Set input pin and output pin definitions etc.
 */
#include "PinDefinitionsAndMore.h"

#define IRMP_PROTOCOL_NAMES 1 // Enable protocol number mapping to protocol strings - requires some FLASH. Must before #include <irmp*>

#include <irmpSelectAllProtocols.h>        // This enables all possible protocols
//#include <irmpSelectMain15Protocols.h>    // This enables 15 main protocols
//#include <irmpSelectAllRFProtocols.h>     // This enables all RF main protocols
//#define IRMP_SUPPORT_SIRCS_PROTOCOL     1 // First for test  Sony this enables only one protocol
//#define IRMP_SUPPORT_NEC_PROTOCOL       1 // this enables only one protocol
//#define IRMP_SUPPORT_PANASONIC_PROTOCOL 1 // Panasonic (Beamer), start bits similar to KASEIKY

//#define IRMP_SUPPORT_ONKYO_PROTOCOL     1 // Last not RF, for test
//#define IRMP_MELINERA_PROTOCOL          1 // Last RF, for test 
//#define IR_OUTPUT_IS_ACTIVE_LOW

#define IRSND_IR_FREQUENCY                 38000
#define IRSND_PROTOCOL_NAMES               1 // Enable protocol number mapping to protocol strings - requires some FLASH.
#include <irsndSelectAllProtocols.h>         // This is for IRSN, if its gone it cant send a command 

/*
 * After setting the definitions we can include the code and compile it.
 */
//#define ALTERNATIVE_IRMP_FEEDBACK_LED_PIN LED_BLUE_PIN  // This led is blue , works invers , atached to the plus
//#define FEEDBACK_LED_IS_ACTIVE_LOW =false               // !!!FOR SOME REASON THAT DOSENT WORK!!!
 
#ifdef ALTERNATIVE_IRMP_FEEDBACK_LED_PIN
#define IRMP_FEEDBACK_LED_PIN  ALTERNATIVE_IRMP_FEEDBACK_LED_PIN
#endif
/*
 * After setting the definitions we can include the code and compile it.
 */
#define USE_ONE_TIMER_FOR_IRMP_AND_IRSND // otherwise we get an error on AVR platform: redefinition of 'void __vector_8() 
#include <irmp.c.h>
#include <irsnd.c.h>

IRMP_DATA irmp_data;
IRMP_DATA irsnd_data;
Print *pSerial;
        
char *COMMAND_IDENTIFY          = "identify";
char *COMMAND_INFO              = "info"    ;
char *COMMAND_SEND_IR           = "P=";
char *COMMAND_PROTOCOLS_SET     = "EW=";
char *COMMAND_PROTOCOLS_GET     = "Protocols Get";
char *COMMAND_APPLICATION_CLOSE = "Application Close";


ReciveCoommandType m_ReciveCoommandType;

static bool arrProtocols[IRMP_N_PROTOCOLS ];


void setup() 
{
#if defined(MCUSR)
    MCUSR = 0; // To reset old boot flags for next boot
#endif
    pSerial=&Serial;


    Serial.begin(115200);
#if defined(__AVR_ATmega32U4__) || defined(SERIAL_USB) || defined(SERIAL_PORT_USBVIRTUAL)
    delay(2000); // To be able to connect Serial monitor after reset and before first printout
#endif
#if defined(ESP8266)
    pSerial->println(); // to separate it from the internal boot output
#endif
    
    // IR Recive
    irmp_init();//void irmp_init(uint_fast8_t aIrmpInputPin, uint_fast8_t aIrmpFeedbackLedPin, bool aIrmpLedFeedbackPinIsActiveLow);

#ifdef ALTERNATIVE_IRMP_FEEDBACK_LED_PIN
    irmp_irsnd_LEDFeedback(true); // Enable receive signal feedback at ALTERNATIVE_IRMP_FEEDBACK_LED_PIN
#endif

    //IR Send
    irsnd_init();
    irmp_irsnd_LEDFeedback(true); // Enable send signal feedback at LED_BUILTIN


    pinMode(LED_RED_PIN  , OUTPUT);
    pinMode(LED_GREEN_PIN, OUTPUT);
    UpdateConnectionLed(false);// Linux App is conected. Actualize Reed-Green LED / in start, not USB connected, Red Led lighting
}

String sRead;
#define MAX_READ_SIZE  1024  // It can be some other port, there must be megabytes of data, String sRead must be overflowed, we set the maximum.
bool bReadOverflow,bEoln;
char inChar;


void loop()
{

    // Check if new data available and get them, format and send to USB Serial
    //
    if (irmp_get_data(&irmp_data))
    {
        //
        // Skip repetitions of command
        //
        if (!(irmp_data.flags & IRMP_FLAG_REPETITION))
        {
            // Here data is available and is no repetition -> evaluate IR command
           /* switch (irmp_data.command)
            {
              case 0x48: digitalWrite(LED_BUILTIN, LOW);
                   delay(4000);
                break;
              default:  digitalWrite(LED_BUILTIN,HIGH );
                break;
            }*/
        }

      //pSerial->println( irmp_data.protocol, HEX);            // Just for the test to know it exists
      //irmp_print_protocol_name( pSerial, irmp_data.protocol);// This prits the name of the protocol or code
      irmp_result_print(pSerial,&irmp_data);
    }

  sRead="";
  bReadOverflow=false;
  bEoln=false;
  // Read from USB port
  // If thers alot of data  overflow error
  // If ther are more commands separated by EOL reads the first, others ignored

  //while(pSerial->available()) 
  while(Serial.available()>0) 
  {   
      delay(2);  //delay to allow byte to arrive in input buffer
       char inChar=Serial.read();
       sRead+=inChar;  
      // sRead = Serial.readString();
     // EOL detected Тук има уловка
  //   if ((inChar =='\r') || (inChar== '\n')) 
 //    bEoln=true;
   
//     if (!bEoln) 
   /*  {
       if ( sRead.length()<MAX_READ_SIZE ) sRead+=inChar;  // 
       else bReadOverflow=true;                            // Даните са дълги, Overloff грешка, не пълниме в String sRead. Но си довършваме цикъла за да се изпразни порта.
     }*/
  }
  sRead.trim();// Here we remove , empty space from left and rigth 
  
  switch ( DecodeCommand() )
  {
      case   identify        : pSerial->println("IR Send Recive USB-Serial Daemon");
                                 
                               UpdateConnectionLed(true);// Linux App is conected. Update Reed-Green LED - Green lighting
      break; 
      case   info            : PrintInfoScreen();
      break;
      case   overflow        : pSerial->println("Overflow Error!!! Command too long : " + sRead + " ...");
      break;
      case   Protokols_Set   : IRMPSupportProtokolsWrite(); //!!! Dont implant it!!! It writes in the eprom what protocols to decode
      break;
      case   Protokols_Get   : IRMPSupportProtokolsRead();  //!!! Dont implant it!!! 
      break;
      case  Application_Close: UpdateConnectionLed(false);  // Linux App is closed. Update Reed-Green LED - Reed lighting
      break;
      case   IR_code         : SendIR();
      break;
      case   IR_decode_error : pSerial->println("Error decode IR code command : " + sRead ); 
      break;
      case   Command_decode_error :pSerial->println("Error decode Command : " + sRead ); 
      break;
      case   unknown         : pSerial->println("Unknown Command: " + sRead );
      break;
      default:
      break;
  }

  delay(100);
}

// See if a command has been received from the USB serial port
// COMMAND_SEND_IR is used more often, be it abovе
ReciveCoommandType_t  DecodeCommand()
{  
   if ( bReadOverflow )
    return overflow;
    
   if ( !sRead.length() )
    return none;
    
   if ( sRead.startsWith(COMMAND_SEND_IR) ) // Command starts with  "P="
    return  ParseIrCode(sRead);             // If code is ОК return IR_code, IR_decode_error, unknown ;
    
    if ( sRead == COMMAND_IDENTIFY )
    return identify;   
    
   if ( sRead == COMMAND_INFO) 
    return  info;  

   if ( sRead.startsWith(COMMAND_PROTOCOLS_SET) ) // Command starts with "EEPROM_WRITE_PROTOCOLS="
    return ParseEepromProtokols( sRead);
    
   if ( sRead == COMMAND_PROTOCOLS_GET )
    return Protokols_Get;  
    
   if ( sRead == COMMAND_APPLICATION_CLOSE )
    return Application_Close;  


   return unknown;
}

// Called with a command "info", print pins and program settings
void PrintInfoScreen()
{
   pSerial->println(F("START " __FILE__ " from " __DATE__ "\r\nUsing IRMP-master library version " VERSION_IRMP));
   pSerial->print(F("Ready to receive IR signals of protocols: "));
   //irmp_print_active_protocols(&Serial);
   irmp_print_active_protocols_Details(&Serial);
   pSerial->println("");
   IRMPSupportProtokolsRead();
   pSerial->println("");
   
#if defined(ARDUINO_ARCH_STM32)
    pSerial->println(F("IR receive pin " IRMP_INPUT_PIN_STRING));
#else
    pSerial->println(F("IR receive pin " STR(IRMP_INPUT_PIN)));
#endif

#if defined(ARDUINO_ARCH_STM32)
    pSerial->println(F("IR send pin " IRSND_OUTPUT_PIN_STRING)); // the internal pin numbers are crazy for the STM32 Boards library
#else
    pSerial->println(F("IR send pin " STR(IRSND_OUTPUT_PIN)));
#endif  


#ifdef ALTERNATIVE_IRMP_FEEDBACK_LED_PIN
    {
      #if defined(ARDUINO_ARCH_STM32)
            pSerial->println(F("IR feedback pin " ALTERNATIVE_IRMP_FEEDBACK_LED_PIN)); // the internal pin numbers are crazy for the STM32 Boards library
      #else
            pSerial->println(F("IR feedback pin " STR(ALTERNATIVE_IRMP_FEEDBACK_LED_PIN)));
      #endif  
    }
#else
     pSerial->println(F("No IR feedback pin "));
#endif
 
}
// String is this format 
// EEPROM_WRITE_PROTOCOLS=11111101111100011100110010011000000000000000000000000000100
ReciveCoommandType_t  ParseEepromProtokols(String sIn)
{
    sIn.remove(0, strlen(COMMAND_PROTOCOLS_SET)); // Remove from begin "EEPROM_WRITE_PROTOCOLS=", left: 11111101111100011100110010011000000000000000000000000000100
    sIn.trim();
    if ( sIn.length() !=IRMP_N_PROTOCOLS)
    { 
      pSerial->print(F("( sIn.length() !=IRMP_N_PROTOCOLS+1)" ));
      int t=sIn.length();
    //  pSerial->print(t,DEC );
//       pSerial->println(COMMAND_PROTOCOLS_SET,DEC));
      return Command_decode_error;
    }
   for(int i =0; i < sIn.length()-1; i++ )
   {
     if      ( sIn[i]!='0')arrProtocols[i]=false;
     else if ( sIn[i]!='1')arrProtocols[i]=true;
      else
       return Command_decode_error;
   }
  
  return Protokols_Set;
}


// This must be the last of the codes decoded by the IR code code of the last Medion protocol
// Exsample P=SIRCS  A=0x0 C=0x813
// If dosent start with  "P=" return unknown;
// If IR code but with wrong syntax returns IR_decode_error
// If its valid , filled  irsnd_data.->, .protocol,.address,.command , return IR_code;
// starts  P= is tested
ReciveCoommandType_t ParseIrCode(String sIn)
{
  bool bError;

   sIn.remove(0, strlen(COMMAND_SEND_IR)); // remove from start "P=", leaves: SIRCS  A=0x0 C=0x813
   
   int iFindA= sIn.indexOf("A=");
   
   if ( iFindA==-1 )
    return IR_decode_error;

   int iIR_Protocol=DecodeIR_Protocol(sIn.substring(0,iFindA  )); // Checking to see if there is such a protocol


   
   if ( iIR_Protocol==-1 )
     return IR_decode_error;
     
   irsnd_data.protocol =  iIR_Protocol; // Decoded successfully, we save the index
   
   sIn.remove(0, iFindA+2); // remove from start  'SIRCS  '+'А=', leaves 0x0 C=0x813
   
   int iFindC= sIn.indexOf("C=");
   
   if ( iFindC==-1 )
    return IR_decode_error;
    
   irsnd_data.address=DecodeHEX( sIn.substring(0,iFindC  ) ,  &bError   ); // goes in'0x0 '
   if ( bError )
    return IR_decode_error;

   sIn.remove(0, iFindC+2); // remove from begin  '0x0 '+'C=', leaves 0x813

   irsnd_data.command=DecodeHEX(sIn, & bError   ); // goes in '0x813'
   if ( bError  )
    return IR_decode_error;
              
  return IR_code;
}

// Check if there is such a protocol eg 'SIRCS' or 0x39
// Put both syntaxes to work
// returns the index if found or -1 if not found
int DecodeIR_Protocol(String sIn)
{ 
  bool bError;
  sIn.trim();
  
  if ( !sIn.length() )
  return -1;

  // There are no names only codes of type 0x0 to 0x59, here 0x does not mean HEX values ​​but are decimal from 0-59
  if ( ( sIn.startsWith("0x") || sIn.startsWith("0X") ) )
  {
    sIn.remove(0, 2); // The command starts with 0x or 0X, we remove 0X from the beginning

    uint8_t protocol =DecodeDEC_to_uint8_t( sIn,  &bError   ); // goes in  '0x0 '
  
   if ( bError )
    return -1;
 
    if ( protocol>=0 && protocol <= IRMP_N_PROTOCOLS ) return protocol;
     else return -1;
  }

  #  if defined(__AVR__)
       for (uint8_t i = 0; i <= IRMP_N_PROTOCOLS); ++i)
       {
            const char* tProtocolStringPtr = (char*) pgm_read_word(&irmp_protocol_names[i]);
            if( sIn == (__FlashStringHelper *) (tProtocolStringPtr));
             return i;
         }
       }
  #  else
       for (uint8_t i = 0; i <= IRMP_N_PROTOCOLS; ++i)
       { 
         if( sIn == irmp_protocol_names[i] )
          return i;
       }
  #  endif
   

 return -1;
}

void SendIR()
{
    irsnd_data.flags = 0; // repeat frame 0 time

    irsnd_send_data(&irsnd_data, true);

//    bool bErr;
//    String sMsg="Send IR : P="+GetProtocolName(irsnd_data.protocol, & bErr)+"  A=0x"+String(irsnd_data.address, HEX)+" B=0x"+String(irsnd_data.command, HEX);
//    pSerial->println(sMsg);
    pSerial->print("Send IR : ");
   // pSerial->print(irsnd_data.protocol);
    irmp_result_print(pSerial,&irsnd_data);
}
// Checks the status of USB, only when changed updates the Dual-red-green diode
// Green - USB connected
// Red   - USB not connected
void UpdateConnectionLed(const bool bAppConnected )
{
     digitalWrite(LED_RED_PIN  , !bAppConnected ); // sets the digital pin 13 on
     digitalWrite(LED_GREEN_PIN,  bAppConnected ); // sets the digital pin 13 on
}

void IRMPSupportProtokolsWrite()
{
  EEPROM_writeAnything(EEPROM_DATA_ADRSESS, arrProtocols);
  EEPROM_writeAnything(EEPROM_DATA_ADRSESS + sizeof(arrProtocols), arrProtocols); // We write twice, this is for verification, the data must always be equal


  bool bError=false;
  bool arrCheckEEprom1[IRMP_N_PROTOCOLS ];
  bool arrCheckEEprom2[IRMP_N_PROTOCOLS ];
  
  EEPROM_readAnything(EEPROM_DATA_ADRSESS, arrCheckEEprom1);
  EEPROM_readAnything(EEPROM_DATA_ADRSESS + sizeof(arrProtocols), arrCheckEEprom2);

  String str="";
  String strr1="";
  String strr2="";
   for (uint8_t i = 0; i < IRMP_N_PROTOCOLS ; i++)
   {
    /*  if( !( arrProtocols[i]==arrCheckEEprom1[i]==arrCheckEEprom2[i]) )
      {
        bError=true;
        break;
      }*/
       str+=arrProtocols[i];
       strr1+=arrCheckEEprom1[i];
       strr2+=arrCheckEEprom2[i];
   }

   if ( bError)
   {
      pSerial->print(F("ERROR! Write Protokols to EEprom :" ));
      pSerial->println( str );  
   }
   else {
           pSerial->print(F("Write Protokols to EEprom Sucseful : " ));  
           pSerial->println(F("please Restart Reciver" )); // 
        }
        pSerial->println( str );  
        pSerial->println( strr1 );  
        pSerial->println( strr2 ); 
}

// After loading the definitions of which protocols are included
// complete the list of active, inactive protocols, something like a reference
void IRMPSupportProtokolsUpdateArr()
{ 
  // puts in the full  arrProtocols false 
  for (uint8_t i = 1; i <= IRMP_N_PROTOCOLS ; ++i)arrProtocols[i]=false; 

// there is some sheet with indexes of active protocols, from there we take which are true
// skip protocol 0 = UNKNOWN
    for (uint8_t i = 1; i < sizeof(irmp_used_protocol_index); ++i)
    {

#  if defined(__AVR__)
        uint8_t tProtocolNumber = (uint8_t) pgm_read_byte(&irmp_used_protocol_index[i]);
        arrProtocols[tProtocolNumber]=true;
#  else
        arrProtocols[irmp_used_protocol_index[i]]=true;
#  endif

    }
}
void IRMPSupportProtokolsRead()
{
   IRMPSupportProtokolsUpdateArr(); 
   pSerial->print("Protocols :");
   for (uint8_t i = 1; i <= IRMP_N_PROTOCOLS; ++i)
   {
     if ( arrProtocols[i] ) pSerial->print( "1"); 
     else pSerial->print( "0");
   }
   pSerial->println("");
}
void IRMPSupportProtokolsReadFromEEprom()
{  bool arrProtocols[IRMP_N_PROTOCOLS ];
   irmp_print_active_protocols( pSerial );

   uint16 EpromAddress = 0x10;
bool ProtocolsArr2[IRMP_N_PROTOCOLS ];
   EEPROM_readAnything(EpromAddress, ProtocolsArr2);

  pSerial->println("");pSerial->print("ByteArr:");
  for (uint8_t i = 0; i < IRMP_N_PROTOCOLS ; i++)   pSerial->print( ProtocolsArr2[i],BIN);


   pSerial->println("");
   pSerial->print("Protocols "); 
   for (uint8_t i = 1; i < sizeof(IRMP_N_PROTOCOLS); ++i)
   {
     pSerial->print( arrProtocols[i],BIN);
   }
   pSerial->println("");
}
  
// It is modified from the original, it also prints the code and the name
void irmp_print_active_protocols_Details(Print *pSerial)
{
    // skip protocol 0 = UNKNOWN
    for (uint8_t i = 1; i < sizeof(irmp_used_protocol_index); ++i)
    {
      if ( i>1 ) pSerial->print(", "); // We do not put a comma on the first one
      
#if IRMP_PROTOCOL_NAMES == 1
        /*
         * Read names of protocol from array and print
         */
#  if defined(__AVR__)

        uint8_t tProtocolNumber = (uint8_t) pgm_read_byte(&irmp_used_protocol_index[i]);  //Index
        pSerial->print(tProtocolNumber); pSerial->print(F(":"));

        const char* tProtocolStringPtr = (char*) pgm_read_word(&irmp_used_protocol_names[i]); //Name
        pSerial->print((__FlashStringHelper *) (tProtocolStringPtr));
#  else
        pSerial->print(irmp_used_protocol_index[i]);pSerial->print(F(":"));// Index
        
        pSerial->print(irmp_used_protocol_names[i]);                         // Name
#  endif
#else
        /*
         * Print just numbers of the protocols not the names
         */
#  if defined(__AVR__)
        uint8_t tProtocolNumber = (uint8_t) pgm_read_byte(&irmp_used_protocol_index[i]);
        pSerial->print(tProtocolNumber);
#  else
        pSerial->print(irmp_used_protocol_index[i]);
#  endif
#endif
        
    }
}
