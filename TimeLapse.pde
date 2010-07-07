#include <MsTimer2.h>
#include <EEPROM.h>
#include "eeprom.h"
#include "buttons.h"

// Code version:
#define CODEID "TimeLapse 0.1"

// Constants
#define READY       Serial.println(">")
#define BAUD        9600
#define LOOP_DELAY  100
#define SHOOT_DELAY 500
#define RUNNING_LED 8
#define SHOOT_LED   9
#define TRIGGER_PIN 10
#define SEL_B       2
#define INC_B       3
#define DEC_B       4
#define CYC_B       5


// Globals
unsigned int g_period = 0;
bool g_running = false;
char g_pins[3] = {RUNNING_LED, SHOOT_LED, TRIGGER_PIN};
ButtonsClass g_buttons(4);



void isr() {
  digitalWrite(SHOOT_LED, HIGH);
  digitalWrite(TRIGGER_PIN, HIGH);
  delay(SHOOT_DELAY);
  digitalWrite(SHOOT_LED, LOW);  
  digitalWrite(TRIGGER_PIN, LOW);
  return;
}

void toggle() {
  if (g_running)
  {
    Serial1.write(0xFE);
    Serial1.write(0x01);
    Serial1.write(0xFE);
    Serial1.write(64+128);
    Serial1.print("Idle");
    MsTimer2::stop();
    g_running = false;
    digitalWrite(RUNNING_LED, LOW);
    READY;
  }
  else
  {
    Serial1.write(0xFE);
    Serial1.write(0x01);
    Serial1.write(0xFE);
    Serial1.write(64+128);
    Serial1.print("Acquiring");
    MsTimer2::start();
    g_running = true;
    digitalWrite(RUNNING_LED, HIGH);
  }
}



//  ____       _               
// / ___|  ___| |_ _   _ _ __  
// \___ \ / _ \ __| | | | '_ \ 
//  ___) |  __/ |_| |_| | |_) |
// |____/ \___|\__|\__,_| .__/ 
//                      |_|    

void setup() {
  Serial.begin(BAUD);
  Serial.println(CODEID);
  Serial1.begin(9600);
  Serial1.write(0xFE);
  Serial1.write(0x01);
  Serial1.write(0xFE);
  Serial1.write(64+128);
  Serial1.print(CODEID);

  g_buttons.buttons[0] = SEL_B;
  g_buttons.buttons[1] = INC_B;
  g_buttons.buttons[2] = DEC_B;
  g_buttons.buttons[3] = CYC_B;

  // LED Output
  int p;
  for(p=0; p<4; p++) {
    pinMode(g_pins[p], OUTPUT);
    digitalWrite(g_pins[p], LOW);
  }

  // Button pins (also set the pullup resistors)
  for(p=0; p<4; p++) {
    pinMode(g_buttons.buttons[p], INPUT);
    digitalWrite(g_buttons.buttons[p], HIGH);
  }

  MsTimer2::set(g_period, isr);
  READY;
}


//  _                      
// | |    ___   ___  _ __  
// | |   / _ \ / _ \| '_ \ 
// | |__| (_) | (_) | |_) |
// |_____\___/ \___/| .__/ 
//                  |_|    

void loop() {
  static unsigned int v = 0;
  char ch;
  if (Serial.available()) {
    ch = Serial.read();
    // Serial command parsing:
    switch(ch) {
    case '/':
      toggle();
      break;
    case '0'...'9': // Accumulates values
      v = v * 10 + ch - '0';
      break;
    case 'p':
      v = 0;
      break;
    }
  }

  g_buttons.read();
  int i;
  for(i=0; i<4; i++)
    Serial.print(g_buttons.states[i]);
   Serial.println();

  delay(LOOP_DELAY);
}


