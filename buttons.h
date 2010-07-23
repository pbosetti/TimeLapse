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
  bool read(unsigned long int time);
  void pin_setup(bool pullup);
  hms_t duration();
  unsigned long int lapse();
  unsigned long int delay();
  void set_delay(unsigned long int millisec);
  void describe_in(const unsigned int row, char * desc);

  byte buttons[4];
  bool states[4];
  unsigned int bits;
  unsigned long int last;
  unsigned int selection;
  bool shooting, en_saving;
  unsigned int d_hour, d_min, min, sec, count;
  
private:
  void change(int val);
  void count_atomic_increment(int radix, int increment);
  
  unsigned int delta;
  bool negated_buttons;
};

#endif
