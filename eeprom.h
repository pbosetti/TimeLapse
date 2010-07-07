#ifndef eeprom_h
#define eeprom_h

#include "WProgram.h"

// Support functions
template <class T>
int EEPROM_write(int ee, const T& value)
{
  byte const *p = reinterpret_cast<byte const *>(&value);
  int i;
  for (i = 0; i < sizeof(value); i++)
    EEPROM.write(ee++, *p++);
  return i;
}

template <class T> 
int EEPROM_read(int ee, T& value)
{
  byte *p = reinterpret_cast<byte *>(&value);
  int i;
  for (i = 0; i < sizeof(value); i++)
    *p++ = EEPROM.read(ee++);
  return i;
}

#endif
