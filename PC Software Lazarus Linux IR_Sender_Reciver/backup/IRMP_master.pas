unit IRMP_master;
// this unit does something

// public  - - - - - - - - - - - - - - - - - - - - - - - - -
interface

type
	// the type TRandomNumber gets globally known
	// since it is included somewhere (uses-statement)
	TRandomNumber = integer;
        protocol= record
                         index  : integer;
                         name   : string;
                         tooltip: string;//details
                   end;
const
      IRMP_N_PROTOCOLS = 60;

      ARR_protocols: array [ 1 .. IRMP_N_PROTOCOLS ] of protocol = (    //  Слагаме array да започва от 1 за да съотвтства индекса
   //   ( index: 0; name:'UNKNOWN'       ; tooltip:'uknown protocol'   Пропускаме 0-'UNKNOWN'                                                                      ),
      ( index: 1; name:'SIRCS'         ; tooltip:'Sony '                                                                                 ),
      ( index: 2; name:'NEC'           ; tooltip:'NEC with 32 bits, 16 address + 8 + 8 command bits, Pioneer, JVC, Toshiba, NoName etc. '),
      ( index: 3; name:'SAMSUNG'       ; tooltip:'Samsung'                                                                               ),
      ( index: 4; name:'MATSUSHITA'    ; tooltip:'Matsushita'                                                                            ),
      ( index: 5; name:'KASEIKYO'      ; tooltip:'Kaseikyo (Panasonic etc)'                                                              ),
      ( index: 6; name:'RECS80'        ; tooltip:'Philips, Thomson, Nordmende, Telefunken, Saba'                                         ),
      ( index: 7; name:'RC5'           ; tooltip:'Philips etc'                                                                           ),
      ( index: 8; name:'DENON'         ; tooltip:'Denon, Sharp'                                                                          ),
      ( index: 9; name:'RC6'           ; tooltip:'Philips etc'                                                                           ),

      ( index:10; name:'SAMSUNG32'     ; tooltip:'Samsung32: no sync pulse at bit 16, length 32 instead of 37'                           ),
      ( index:11; name:'APPLE'         ; tooltip:'Apple, very similar to NEC'                                                            ),
      ( index:12; name:'RECS80EXT'     ; tooltip:'Philips, Technisat, Thomson, Nordmende, Telefunken, Saba'                              ),
      ( index:13; name:'NUBERT'        ; tooltip:'Nubert'                                                                                ),
      ( index:14; name:'BANG_OLUFSEN'  ; tooltip:'Bang & Olufsen'                                                                        ),
      ( index:15; name:'GRUNDIG'       ; tooltip:'Grundig'                                                                               ),
      ( index:16; name:'NOKIA'         ; tooltip:'Nokia'                                                                                 ),
      ( index:17; name:'SIEMENS'       ; tooltip:'Siemens, e.g. Gigaset'                                                                 ),
      ( index:18; name:'FDC'           ; tooltip:'FDC keyboard'                                                                          ),
      ( index:19; name:'RCCAR'         ; tooltip:'RC Car'),
      ( index:20; name:'JVC'           ; tooltip:'JVC (NEC with 16 bits)'                                                                ),
      ( index:21; name:'RC6A'          ; tooltip:'RC6A, e.g. Kathrein, XBOX'                                                             ),
      ( index:22; name:'NIKON'         ; tooltip:'Nikon'                                                                                 ),
      ( index:23; name:'RUWIDO'        ; tooltip:'Ruwido, e.g. T-Home Mediareceiver'                                                     ),
      ( index:24; name:'IR60'          ; tooltip:'IR60 (SDA2008)'                                                                        ),
      ( index:25; name:'KATHREIN'      ; tooltip:'Kathrein'                                                                              ),
      ( index:26; name:'NETBOX'        ; tooltip:'Netbox keyboard (bitserial)'                                                           ),
      ( index:27; name:'NEC16'         ; tooltip:'NEC with 16 bits (incl. sync)'                                                         ),
      ( index:28; name:'NEC42'         ; tooltip:'NEC with 42 bits'                                                                      ),
      ( index:29; name:'LEGO'          ; tooltip:'LEGO Power Functions RC'                                                               ),

      ( index:30; name:'THOMSON'       ; tooltip:'Thomson'                                                                               ),
      ( index:31; name:'BOSE'          ; tooltip:'BOSE'                                                                                  ),
      ( index:32; name:'A1TVBOX'       ; tooltip:'A1 TV Box'                                                                             ),
      ( index:33; name:'ORTEK'         ; tooltip:'ORTEK - Hama'                                                                          ),
      ( index:34; name:'TELEFUNKEN'    ; tooltip:'Telefunken (1560)'                                                                     ),
      ( index:35; name:'ROOMBA'        ; tooltip:'iRobot Roomba vacuum cleaner'                                                          ),
      ( index:36; name:'RCMM32'        ; tooltip:'Fujitsu-Siemens (Activy remote control)'                                               ),
      ( index:37; name:'RCMM24'        ; tooltip:'Fujitsu-Siemens (Activy keyboard)'                                                     ),
      ( index:38; name:'RCMM12'        ; tooltip:'Fujitsu-Siemens (Activy keyboard)'                                                     ),
      ( index:39; name:'SPEAKER'       ; tooltip:'Another loudspeaker protocol, similar to Nubert'                                       ),

      ( index:40; name:'LGAIR'         ; tooltip:'LG air conditioner'                                                                    ),
      ( index:41; name:'SAMSUNG48'     ; tooltip:'air conditioner with SAMSUNG protocol (48 bits)'                                       ),
      ( index:42; name:'MERLIN'        ; tooltip:'Merlin (Pollin 620 185)'                                                               ),
      ( index:43; name:'PENTAX'        ; tooltip:'Pentax camera'                                                                         ),
      ( index:44; name:'FAN'           ; tooltip:'FAN (ventilator), very similar to NUBERT, but last bit is data bit instead of stop bit'),
      ( index:45; name:'S100'          ; tooltip:'very similar to RC5, but 14 instead of 13 data bits'                                   ),
      ( index:46; name:'ACP24'         ; tooltip:'Stiebel Eltron ACP24 air conditioner'                                                  ),
      ( index:47; name:'TECHNICS'      ; tooltip:'Technics, similar to Matsushita, but 22 instead of 24 bits'                            ),
      ( index:48; name:'PANASONIC'     ; tooltip:'Panasonic (Beamer), start bits similar to KASEIKYO'                                    ),
      ( index:49; name:'MITSU_HEAVY'   ; tooltip:'Mitsubishi-Heavy Aircondition, similar timing as Panasonic beamer'                     ),

      ( index:50; name:'VINCENT'       ; tooltip:'Vincent'                                                                               ),
      ( index:51; name:'SAMSUNGAH'     ; tooltip:'SAMSUNG AH'                                                                            ),
      ( index:51; name:'IRMP16'        ; tooltip:'IRMP specific protocol for data transfer, e.g. between two microcontrollers via IR'    ),
      ( index:53; name:'GREE'; tooltip:'Gree climate'),
      ( index:54; name:'RCII'; tooltip:'RC II Infra Red Remote Control Protocol for FM8'),
      ( index:55; name:'METZ'; tooltip:'METZ'),
      ( index:56; name:'ONKYO'; tooltip:'Like NEC but with 16 address + 16 command bits'),

      // тез са RF, Предполагам на изхода мясро IR диода се модулира наякакъв RF генератор
      ( index:57; name:'RF_GEN24'; tooltip:'RF Generic, 24 Bits (Pollin 550666, EAN 4049702006022 and many other similar RF remote controls))'),
      ( index:58; name:'RF_X10'; tooltip:'RF PC X10 Remote Control (Medion, Pollin 721815)'),
      ( index:59; name:'RF_MEDION'; tooltip:'RF PC Medion Remote Control (Medion)')
      ( index:60; name:'MELINERA'; tooltip:'Melinera protocol and single repeat for NEC')
     );



// of course the const- and var-blocks are possible, too

// a list of procedure/function signatures makes
// them useable from outside of the unit
function getRandomNumber(): TRandomNumber;

// an implementation of a function/procedure
// must not be in the interface-part

// private - - - - - - - - - - - - - - - - - - - - - - - - -
implementation

var
	// var in private-part
	// => only modifiable inside from this unit
	chosenRandomNumber: TRandomNumber;

function getRandomNumber(): TRandomNumber;
begin
	// return value
	getRandomNumber := chosenRandomNumber;
end;

// initialization is the part executed
// when the unit is loaded/included
initialization
begin
	// choose our random number
	chosenRandomNumber := 3;
	// chosen by fair-dice-roll
	// guaranteed to be random 
end;

// finalization is worked off at program end
finalization
begin
	// this unit says 'bye' at program halt
	writeln('bye');
end;
end.
