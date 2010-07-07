#include "buttons.h"
#define DEFAULT_DELTA 200
ButtonsClass::ButtonsClass(unsigned int s) 
{
  count = s;
  buttons = (char *) malloc(s * sizeof(char));
  states = (bool *) malloc(s * sizeof(bool));
  last = millis();
  delta = DEFAULT_DELTA;
}

ButtonsClass::~ButtonsClass()
{
  free(buttons);
  free(states);
}

void ButtonsClass::read()
{
  int i;
  if(millis()-last < delta) {
    for(i=0; i<count; i++) {
      states[i] = digitalRead(buttons[i]);
    }
  }
  last = millis();
}



