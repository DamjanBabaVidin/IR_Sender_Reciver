# IR_Sender_Reciver

This software is licensed under the GPL license, and is an IR-remote Ingest and Repeater. 
It consists of 2 modules:
 - IR_SendRecive PC software for Linux written in Lazarus
 - Send_Recive.ino Arduino module STM32F103C8T6 and a few details for them. 
uses 2 projects from github:
- LazSerial v0.3: https://github.com/JurassicPork/TLazSerial 
- IRMP-Infrared Multi Protocol Decoder + Encoder https://github.com/ukw100/IRMP

This 2 project is needed for commissioning, you will pick up from these addresses yourself

I automated the maximum I could do. The GUI of the IR_SendRecive application scans all serial ports and then tries to find the device.
Detects which protocols are installed, after which you can conveniently receive IR codes from the remote control and request IR codes from the device.
My goal is to be able to back up each remote in a text file and then be able to generate these codes directly from the computer.

 Keep in mind that this is my first project uploaded to gitub, and I apologize in advance if something goes wrong.

