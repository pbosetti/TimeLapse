#include "lcd.h"


LCDClass::LCDClass(unsigned int c)
{
  SER.begin(9600);
  cols = c;
  switch(cols) {
  case 16:
    heads[0] = 0;
    heads[1] = 64;
    heads[2] = 16;
    heads[3] = 80;
    break;    
  case 20:
    heads[0] = 0;
    heads[1] = 64;
    heads[2] = 20;
    heads[3] = 84;
    break;    
  }
}

LCDClass::~LCDClass()
{
}

void LCDClass::clear()
{
  SER.write(LCD_CTRL);
  SER.write(LCD_CLEAR);
}

void LCDClass::write(const char *s, unsigned int line, unsigned int col)
{
  SER.write(LCD_CTRL);
  SER.write(heads[line] + col + 128);
  SER.write(s);
}

void LCDClass::write(const char *s, unsigned int line)
{
  write(s, line, 0);
}

void LCDClass::cursor_at(unsigned int line, unsigned int col)
{
  SER.write(LCD_CTRL);
  SER.write(heads[line] + col + 0x80);
}

void LCDClass::cursor(bool onoff)
{
  SER.write(LCD_CTRL);
  SER.write(onoff ? LCD_CURON : LCD_CUROFF);
}



