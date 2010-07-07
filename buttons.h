#ifndef buttons_h
#define buttons_h

#include "WProgram.h"

class ButtonsClass {
public:
  ButtonsClass(unsigned int );
  ~ButtonsClass();
  void read();
  char * buttons;
  bool * states;
  unsigned long int last;
private:
  unsigned int count;
  unsigned int delta;
};

#endif
