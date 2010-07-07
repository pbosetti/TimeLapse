#include "WProgram.h"

class ButtonsClass {
public:
  ButtonsClass(unsigned int s);
  ~ButtonsClass();
  void read();
  char * buttons;
  bool * states;
  unsigned long int last;
private:
  unsigned int count;
  unsigned int delta;
};


