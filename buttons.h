#ifndef buttons_h
#define buttons_h
#include "WProgram.h"

struct minsec {
  unsigned int min;
  unsigned int sec;
};

class ButtonsClass {
public:
  ButtonsClass(byte sel, byte inc, byte dec, byte cyc);
  ~ButtonsClass();
  void read();
  void pin_setup(bool pullup);
  minsec duration();
  unsigned int lapse();
  byte buttons[4];
  bool states[4];
  unsigned long int last;
  unsigned int selection;
  bool shooting;
  unsigned int min, sec, count;
private:
  void change(int val);
  void count_atomic_increment(int radix, int increment);
  unsigned int delta;
};

#endif
