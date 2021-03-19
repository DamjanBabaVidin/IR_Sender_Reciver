
bool GetMin(String sIn,bool bOx)
{
#define MAX_OF(type) \
    (((type)(~0LLU) > (type)((1LLU<<((sizeof(type)<<3)-1))-1LLU)) ? (long long unsigned int)(type)(~0LLU) : (long long unsigned int)(type)((1LLU<<((sizeof(type)<<3)-1))-1LLU))
#define MIN_OF(type) \
    (((type)(1LLU<<((sizeof(type)<<3)-1)) < (type)1) ? (long long int)((~0LLU)-((1LLU<<((sizeof(type)<<3)-1))-1LLU)) : 0LL)
/*

ms.ports[0].print("uint16_t MIN :"); ms.ports[0].print( MIN_OF(uint16_t), DEC );ms.ports[0].print(" decode dec, "); ms.ports[0].print( MIN_OF(uint16_t), HEX );ms.ports[0].println(" decode HEX");

ms.ports[0].print("uint16_t MAH :"); ms.ports[0].print( MAX_OF(uint16_t), DEC );ms.ports[0].print(" decode dec, "); ms.ports[0].print( MAX_OF(uint16_t), HEX );ms.ports[0].println(" decode HEX");
ms.ports[0].print("uint32_t MIN :"); ms.ports[0].print( MIN_OF(uint32_t), DEC );ms.ports[0].print(" decode dec, "); ms.ports[0].print( MIN_OF(uint32_t), HEX );ms.ports[0].println(" decode HEX");

ms.ports[0].print("uint32_t MAH :"); ms.ports[0].print( MAX_OF(uint32_t), DEC );ms.ports[0].print(" decode dec, "); ms.ports[0].print( MAX_OF(uint32_t), HEX );ms.ports[0].println(" decode HEX");

ms.ports[0].print("sizeof uint16_t :"); ms.ports[0].println(sizeof(uint16_t));
ms.ports[0].print("sizeof uint32_t :"); ms.ports[0].println(sizeof(uint32_t));
*/
}

// Получава sIn това е HEX стринга, работи и за двата синтакса, 0XFFfF или FFFa
// Ако е валиден синтакса и дължината конвертира и върща HEX стринга и bError = false
// Ако не е валиден върща 0 и bError = true
// bError е нещо като грешка, върща и нея за да проверим после
uint16_t DecodeHEX(String sIn, bool  *bError  )
{

   sIn.trim();

   if ( ( sIn.startsWith("0x") || sIn.startsWith("0X") ) )sIn.remove(0, 2); // командата започва с 0x или 0X, Махаме од началото 0X

   // Две проверки, да не е празен и да не е подълг от максимума за съответния тип 
   // Ние знаем че размера за uint16_t е 4 HEX знака, тук съм го оставил да се види как трябва, ако правим за друг тип е нещо подобно.
   if ( !sIn.length()|| sIn.length()>sizeof(uint16_t)*2 )
   {
    *bError=true;
    return 0;
   }
   //остава 12Af, проверяваме всеки знак да е 0-9 или A-Z или a-z   
   for (uint8_t i = 0; i < sIn.length(); ++i)
   {
    if ( !( (sIn[i] >= '0' && sIn[i]  <= '9') || (sIn[i]  >= 'A' && sIn[i]  <= 'F') || (sIn[i]  >= 'a' && sIn[i]  <= 'f') ) )
    {
      *bError=true;
       return 0;
    }
   }

   
   *bError=false;
  return strtoul (sIn.c_str(), NULL, 16);//strtol(sIn.c_str(), NULL, 16);
}

// Получава нормален стринг 243, ако абсолютно няма грешка, и по размера също, конвертирта String в uint8_t
uint8_t DecodeDEC_to_uint8_t(String sIn, bool  *bError  )
{

   sIn.trim();

   // Две проверки, да не е празен и да не е подълг от максимума за съответния тип 
   // Ние знаем че размера за uint16_t е 4 HEX знака, тук съм го оставил да се види как трябва, ако правим за друг тип е нещо подобно.
   if ( !sIn.length()|| sIn.length()>sizeof(uint8_t)*2 )
   {
    *bError=true;
    return 0;
   }
   //остава 255, проверяваме всеки знак да е 0-9 
   for (uint8_t i = 0; i < sIn.length(); ++i)
   {
    if ( !( sIn[i] >= '0' && sIn[i]  <= '9') )
    {
      *bError=true;
       return 0;
    }
   }

   
   *bError=false;
  return strtoul (sIn.c_str(), NULL, 10);//strtol(sIn.c_str(), NULL, 10);
}
// Получава нормален стринг 243, ако абсолютно няма грешка, и по размера също, конвертирта String в uint16_t
uint16_t DecodeDEC_to_uint16_t(String sIn, bool  *bError  )
{
   sIn.trim();

   // Две проверки, да не е празен и да не е подълг от максимума за съответния тип 
   // Ние знаем че размера за uint16_t е 4 HEX знака, тук съм го оставил да се види как трябва, ако правим за друг тип е нещо подобно.
   if ( !sIn.length()|| sIn.length()>sizeof(uint16_t)*2 )
   {
    *bError=true;
    return 0;
   }
   //остава 123, проверяваме всеки знак да е 0-9 
   for (uint8_t i = 0; i < sIn.length(); ++i)
   {
    if ( !( sIn[i] >= '0' && sIn[i]  <= '9') )
    {
      *bError=true;
       return 0;
    }
   }

   
   *bError=false;
  return strtoul (sIn.c_str(), NULL, 10);//strtol(sIn.c_str(), NULL, 10);
}
