#include "WProgram.h"
#include <string.h>

#define SER        Serial1
#define LCD_CLEAR  (char)0x01
#define LCD_CTRL   (char)0xFE
#define LCD_CURON  (char)0x0E
#define LCD_CUROFF (char)0x0C
#define LCD_CUR    (char)0x80


class LCDClass {
public:
  LCDClass(unsigned int c);
  ~LCDClass();
  
  void clear();
  void write(const char *s, unsigned int line, unsigned int col);
  void write(const char *s, unsigned int line);
  void cursor_at(unsigned int line, unsigned int col);
  void cursor(bool onoff);
  
  unsigned int cols;
private:
  unsigned int heads[4];

};

