#include <MsTimer2.h>
#include <EEPROM.h>
#include "eeprom.h"
#include "buttons.h"
#include "lcd.h"

// Code version:
#define CODEID "TimeLapse 0.4 "

// Constants
#define READY       Serial.println(">")
#define BAUD        9600
#define LOOP_DELAY  100
#define SHOOT_DELAY 500
#define FOCUS_DELAY 500
#define RUNNING_LED 13
#define SHOOT_LED   10
#define DELAY_LED   11
#define TRIGGER_PIN 8
#define FOCUS_PIN   9
#define EEPROM_RESET 3
#define SEL_B       3
#define DSL_B       2
#define INC_B       4
#define DEC_B       5
#define CYC_B       6

// EEPROM mem locations
#define EE_MIN   100
#define EE_SEC   108
#define EE_COUNT 116
#define EE_D_H   124
#define EE_D_M   132

// Globals
unsigned long int g_start, g_delay = 0;
unsigned int g_period = 0;
bool g_running = false;
bool g_logging = false;
bool g_force_update = true;
char g_status[6] = " IDLE";
char g_pins[5] = {
  RUNNING_LED, SHOOT_LED, DELAY_LED, TRIGGER_PIN, FOCUS_PIN};
ButtonsClass g_buttons(SEL_B, DSL_B, INC_B, DEC_B, CYC_B);
LCDClass g_lcd(20);


void isr_shoot() {
  unsigned long int to_go = g_delay - (millis() - g_start);
  if (to_go == 0 || to_go > g_delay) {
    g_buttons.d_min = 0;
    g_buttons.d_hour = 0;
    strcpy(g_status, "  RUN");
    digitalWrite(DELAY_LED, LOW);
    digitalWrite(SHOOT_LED, HIGH);
    digitalWrite(FOCUS_PIN, HIGH);
    delayMicroseconds(FOCUS_DELAY * 1000);
    digitalWrite(TRIGGER_PIN, HIGH);
    delayMicroseconds(SHOOT_DELAY * 1000);
    digitalWrite(SHOOT_LED, LOW);  
    digitalWrite(TRIGGER_PIN, LOW);
    if (g_buttons.count > 0) {
      g_buttons.count--;
      if (g_buttons.count == 0)
        g_buttons.shooting = false;
    }
  }
  else {
    strcpy(g_status, "DELAY");
    digitalWrite(DELAY_LED, HIGH);
    g_buttons.d_min = (to_go/60000) % 60;
    g_buttons.d_hour = (to_go/60000) / 60;
    Serial.print(g_buttons.d_hour);
    Serial.print(" ");
    Serial.println(g_buttons.d_min);
  }
  g_force_update = true;
}

void toggle() {
  if (g_running)
  {
    MsTimer2::stop();
    g_running = false;
    digitalWrite(RUNNING_LED, LOW);
    digitalWrite(DELAY_LED, LOW);
    strcpy(g_status, " IDLE");
    READY;
  }
  else
  {
    EEPROM_write(EE_MIN, g_buttons.min);
    EEPROM_write(EE_SEC, g_buttons.sec);
    EEPROM_write(EE_COUNT, g_buttons.count);
    EEPROM_write(EE_D_H, g_buttons.d_hour);
    EEPROM_write(EE_D_M, g_buttons.d_min);
    MsTimer2::set(g_period, isr_shoot);
    MsTimer2::start();
    g_running = true;
    g_start = millis();
    g_delay = (g_buttons.d_hour * 60 + g_buttons.d_min) * 60000;
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
  g_lcd.cursor(false);
  g_lcd.clear();
  g_lcd.write(CODEID, 0);

  // LED Output
  int p;
  for(p=0; p<5; p++) {
    pinMode(g_pins[p], OUTPUT);
    digitalWrite(g_pins[p], LOW);
  }

  // Button pins (also set the pullup resistors)
  g_buttons.pin_setup(HIGH);

//  pinMode(EEPROM_RESET, INPUT);
//  digitalWrite(EEPROM_RESET, HIGH);
  if (digitalRead(EEPROM_RESET) == HIGH) {
    EEPROM_read(EE_MIN, g_buttons.min);
    EEPROM_read(EE_SEC, g_buttons.sec);
    EEPROM_read(EE_COUNT, g_buttons.count);
    EEPROM_read(EE_D_H, g_buttons.d_hour);
    EEPROM_read(EE_D_M, g_buttons.d_min);
    Serial.println("Loaded last settings form EEPROM");
    g_lcd.write("Reloading settings", 1);
  }
  else {
    Serial.println("Resetting default settings");
    g_lcd.write("Resetting defaults", 1);
  }

  MsTimer2::set(g_period, isr_shoot);
  delay(1000);
  READY;
  g_lcd.cursor(true);
  g_lcd.clear();
  g_lcd.write(CODEID, 0);
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
      g_logging = ! g_logging;
      break;
    case '0'...'9': // Accumulates values
      v = v * 10 + ch - '0';
      break;
    case 'm':
      g_buttons.min = constrain(v,0,59);
      v = 0;
      break;
    case 's':
      g_buttons.sec = constrain(v,0,59);
      v = 0;
      break;
    case 'c':
      g_buttons.count = constrain(v,0,9999);
      v = 0;
      break;
    case 't':
      g_buttons.shooting = !g_buttons.shooting;
      break;
    }
  }

  static const unsigned int cur_l[] = {
    1, 1, 2, 2, 2, 2, 2, 2                };
  static const unsigned int cur_c[] = {
    14, 18, 5, 8, 16, 17, 18, 19                };
  bool updated = g_buttons.read();
  if (g_running != g_buttons.shooting)
    toggle();
  g_period = g_buttons.lapse() * 1000;
  char s[20];
  if (updated || g_force_update) {
    g_buttons.describe_in(1, s);
    g_lcd.write(s, 1);
    g_buttons.describe_in(2, s);
    g_lcd.write(s, 2);
    g_buttons.describe_in(3, s);
    g_lcd.write(s, 3);
    g_lcd.write(g_status, 0, 15);
    g_lcd.power(g_buttons.en_saving);
    g_lcd.cursor_at(cur_l[g_buttons.selection], cur_c[g_buttons.selection]);
    g_force_update = false;
  }
  if (updated && g_logging) {
    Serial.print(g_buttons.selection);
    Serial.print(" ");
    char s[20];
    g_buttons.describe_in(0, s);
    Serial.print(s);
    g_buttons.describe_in(1, s);
    Serial.print(s);
    Serial.println();
  }
  delay(LOOP_DELAY);
}




















