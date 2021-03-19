void TrimLeft(String  &str)
{
  int iFind =0;
  for(int i =0; i < str.length(); i++ )
  {
     if ( str[i]==' ')iFind ++;
      else break;
  }
  
  if (iFind>0 )str.remove(0, iFind); 
}

void TrimRight(String  &str)
{
  int iFind =0;
  for (int i = str.length() - 1; i >= 0; i--)
  {
     if ( str[i]==' ') iFind++;
      else break;
  }
  
  if (iFind>0 )str.remove(str.length() -iFind, iFind); 
}
