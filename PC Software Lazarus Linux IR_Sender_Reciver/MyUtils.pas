unit MyUtils;
// this unit does something

// public  - - - - - - - - - - - - - - - - - - - - - - - - -
interface

uses
      Classes, math;

//type
// const     // of course the const- and var-blocks are possible, too

// a list of procedure/function signatures makes
// them useable from outside of the unit
function  GetOverlapedSize(const x1, size1,  x2, size2: Longint) :Longint;
procedure PutInRect(var InOutRec: TRect ; const rect: TRect) ;
// an implementation of a function/procedure
// must not be in the interface-part

// private - - - - - - - - - - - - - - - - - - - - - - - - -
implementation

//var   // var in private-part
	// => only modifiable inside from this unit
	//chosenRandomNumber: TRandomNumber;

// Сигурно има и подобра формула, да се сметне две отсечки който лежат на една права, колко се застъпват, но и това работи
// върща колко се засъпват, ако е негативна, значи не се застъпват
function GetOverlapedSize(const x1, size1,  x2, size2: Longint) :Longint;
var X21 :Longint;
    s   :Longint ;
begin
       X21:=x2-x1;

      if ( x21>0) then                    // |.X1                |X2
      begin
            s:= size1 - x21;
            if s>0  then s:=min(s,size2)  // |X1----------------------X1+S1|              OR   |X1----------------------------------X1+S1|
                                          //                     |X2-------------X2+S2|                       |X2-------------X2+S2|
                                          // |X1-------X1+S1|    |X2-------------X2+S2|
      end
      else                                // |.X2                |X1
      begin
             s:= size2 + x21;             // |X2----------------------X2+S2|              OR   |X2----------------------------------X2+S2|
            if s>0  then s:=min(s,size1)  //                     |X1-------------X1+S1|                       |X1-------------X1+S1|
                                          // |X2-------X2+S2|    |X1-------------X1+S1|
      end;
       result := s;
end;
// Ako InOutRec е поголяма от rect, намалявая я
// Ако частично излиза от размера слага я в rect
procedure PutInRect(var InOutRec: TRect ; const rect: TRect) ;
var
L,T,W,H: Longint;
begin
        InOutRec.NormalizeRect;
        L:= InOutRec.Left;
        T:= InOutRec.Top;
        W:= InOutRec.Width;
        H:= InOutRec.Height;

        if  W > rect.Width  then W:= rect.Width;      // Нормализираме Максимума
        if  H > rect.Height then H:= rect.Height;

        if L < rect.Left then L := rect.Left              // Align from Left
        else if L+W > rect.Right then L:= rect.Right - W; // Align from Right

        if T < rect.Top then T := rect.Top                 // Align from Top
        else if T+H > rect.Bottom then T:= rect.Bottom - H;// Align from Bottom


        InOutRec:=Bounds(L,T,W,H);                         //

end;

// initialization is the part executed
// when the unit is loaded/included
initialization
begin
	//chosenRandomNumber := 3;
end;

// finalization is worked off at program end
finalization
begin
	// this unit says 'bye' at program halt
	writeln('bye');
end;
end.
