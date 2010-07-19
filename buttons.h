#ifndef buttons_h
#define buttons_h
#include "WProgram.h"

struct hms_t {
  unsigned int h;
  unsigned int m;
  unsigned int s;
};

class ButtonsClass {
public:
  ButtonsClass(byte sel, byte dsel, byte inc, byte dec, byte cyc);
  ~ButtonsClass();
  bool read();
  void pin_setup(bool pullup);
  hms_t duration();
  unsigned int lapse();
  void describe_in(const unsigned int row, char * desc);

  byte buttons[4];
  bool states[4];
  unsigned int bits;
  unsigned long int last;
  unsigned int selection;
  bool shooting, en_saving;
  unsigned int min, sec, count;
  
private:
  void change(int val);
  void count_atomic_increment(int radix, int increment);
  unsigned int delta;
};

#endif
