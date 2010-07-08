#include "buttons.h"
#define DEFAULT_DELTA 250
#define B_NUM 4
#define S_NUM 6

ButtonsClass::ButtonsClass(byte sel, byte inc, byte dec, byte cyc) 
{
  buttons[0] = sel;
  buttons[1] = inc;
  buttons[2] = dec;
  buttons[3] = cyc;
  for(int i=0; i<B_NUM; i++) {
    states[i] = LOW;
  }
  last = millis();
  delta = DEFAULT_DELTA;
  selection = 0;
  shooting = false;
  min = 0;
  sec = 5;
  count = 5;
}

ButtonsClass::~ButtonsClass()
{
}

void ButtonsClass::pin_setup(bool pullup)
{
  for(int p=0; p<B_NUM; p++) {
    pinMode(buttons[p], INPUT);
    digitalWrite(buttons[p], pullup);
  }
}

void ButtonsClass::read()
{
  if(millis()-last > delta) {
    int i;
    for(i=0; i<B_NUM; i++) {
      states[i] = digitalRead(buttons[i]);
    }
    if(states[0] == LOW) {
      selection = (selection + 1) % S_NUM;
    }
    else if(states[1] == LOW) {
      change(+1);
    }
    else if(states[2] == LOW) {
      change(-1);
    }
    else if(states[3] == LOW) {
      shooting = ! shooting;
    }
    last = millis();
  }
}
minsec ButtonsClass::duration()
{
  minsec d;
  unsigned int s = lapse() * count;
  d.min = s / 60;
  d.sec = s % 60;
  return d;
}

unsigned int ButtonsClass::lapse()
{
  return (unsigned int)(min * 60 + sec);
}

void ButtonsClass::change(int val)
{
  switch(selection) {
  case 0:
    if (min == 0 and val == -1)
      min = 59;
    else
      min = (min + val) % 60;
    break;
  case 1:
    if (sec == 0 and val == -1)
      sec = 59;
    else
      sec = (sec + val) % 60;
    break;
  case 2:
    count_atomic_increment(1000, val);
    break;
  case 3:
    count_atomic_increment(100, val);
    break;
  case 4:
    count_atomic_increment(10, val);
    break;
  case 5:
    count_atomic_increment(1, val);
    break;
  }
}

void ButtonsClass::count_atomic_increment(int radix, int increment)
{
  if (count <= radix and increment < 0)
    count = count + 9 * radix;
  else
    count = (count + increment * radix) % 10000;
}








