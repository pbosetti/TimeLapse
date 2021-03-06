#include "buttons.h"
#define DEFAULT_DELTA 250
#define B_NUM 5
#define S_NUM 8

ButtonsClass::ButtonsClass(byte sel, byte dsel, byte inc, byte dec, byte cyc) 
{
  buttons[0] = sel;
  buttons[1] = dsel;
  buttons[2] = inc;
  buttons[3] = dec;
  buttons[4] = cyc;
  negated_buttons = true;
  last = 0;
  delta = DEFAULT_DELTA;
  selection = 0;
  shooting = false;
  en_saving = true;
  d_hour = 0;
  d_min = 0;
  min = 0;
  sec = 30;
  count = 200;
}

ButtonsClass::~ButtonsClass()
{
}

// Setup for buttons DI pins; note that if pullup == true, buttons are normally closed!
void ButtonsClass::pin_setup(bool pullup)
{
  negated_buttons = pullup;
  for(int p=0; p<B_NUM; p++) {
    pinMode(buttons[p], INPUT);
    digitalWrite(buttons[p], pullup);
  }
}

bool ButtonsClass::read(unsigned long int time)
{
  bool updated = false;
  if(time-last > delta) {
    int i;
    bool v[B_NUM];
    updated = true;
    for(i=0; i<B_NUM; i++) {
      v[i] = digitalRead(buttons[i]);
      bitWrite(bits, i, (negated_buttons ? !v[i] : v[i]));
    }
    switch(bits) {
    case 1: // Select button
      selection = (selection + 1) % S_NUM;
      break;
    case 2: // Select button
      if (--selection > S_NUM)
        selection = S_NUM - 1;
      break;
    case 3: // Select up and down together
      en_saving = !en_saving;
      break;
    case 4: // Up button
      change(+1);
      break;
    case 8: // Down button
      change(-1);
      break;
    case 16: // Shoot button
      shooting = ! shooting;
      break;
    default:
      updated = false;
    }
    last = time;
  }
  return updated;
}

/* Global duration of sequence */
hms_t ButtonsClass::duration()
{
  hms_t d;
  unsigned int s = lapse() / 1000 * count;
  d.h = s / 3600;
  d.m = (s % 3600) / 60;
  d.s = (s % 3600) % 60;
  return d;
}

/* Interval between shots, in milliseconds */
unsigned long int ButtonsClass::lapse()
{
  return (unsigned long int)(min * 60 + sec) * 1000;
}

/* Delay to start shooting, in milliseconds */
unsigned long int ButtonsClass::delay()
{
  return (d_hour * 60 + d_min) * 60000;
}

void ButtonsClass::set_delay(unsigned long int millisec)
{
  d_min = (millisec/60000) % 60;
  d_hour = (millisec/60000) / 60;
}

/* Description */
void ButtonsClass::describe_in(const unsigned int row, char * desc)
{
  switch(row) {
  case 1:
    sprintf(desc, "Start delay: %02dh:%02dm", d_hour, d_min);
    break;
  case 2:
    if (count > 0)
      sprintf(desc, "Lap:%02d:%02d Count:%04d\0", min, sec, count);
    else
      sprintf(desc, "Lap:%02d:%02d Count:unl.\0", min, sec);
    break;
  case 3:
    sprintf(desc, "Time left:  %02d:%02d:%02d\0", duration().h, duration().m, duration().s);
    break;
  default:
    desc = "                \0";
  }
}

void ButtonsClass::change(int val)
{
  switch(selection) {
  case 0:
    d_hour = constrain(d_hour + val, 0, 24);
    break;
  case 1:
    if (d_min == 0 and val == -1)
      d_min = 59;
    else
      d_min = (d_min + val) % 60;
    break;
  case 2:
    if (min == 0 and val == -1)
      min = 59;
    else
      min = (min + val) % 60;
    break;
  case 3:
    if (sec == 0 and val == -1)
      sec = 59;
    else
      sec = (sec + val) % 60;
    break;
  case 4:
    count_atomic_increment(1000, val);
    break;
  case 5:
    count_atomic_increment(100, val);
    break;
  case 6:
    count_atomic_increment(10, val);
    break;
  case 7:
    count_atomic_increment(1, val);
    break;
  }
}

void ButtonsClass::count_atomic_increment(int radix, int increment)
{
  if (count < radix and increment < 0)
    count = count + 9 * radix;
  else if (count / radix == 9 and increment > 0)
    count = count - 9 * radix;
  else
    count = (count + increment * radix);
  count = constrain(count, 0, 9999);
}
















