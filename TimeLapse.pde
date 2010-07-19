#include <MsTimer2.h>
#include <EEPROM.h>
#include "eeprom.h"
#include "buttons.h"
#include "lcd.h"

// Code version:
#define CODEID "TimeLapse 0.3b"

// Constants
#define READY       Serial.println(">")
#define BAUD        9600
#define LOOP_DELAY  100
#define SHOOT_DELAY 500
#define RUNNING_LED 13
#define SHOOT_LED   8
#define TRIGGER_PIN 10
#define EEPROM_RESET 12
#define LCD_PWR     11
#define SEL_B       2
#define DSL_B       3
#define INC_B       4
#define DEC_B       5
#define CYC_B       6

// EEPROM mem locations
#define EE_MIN   100
#define EE_SEC   108
#define EE_COUNT 116

// Globals
unsigned int g_period = 0;
bool g_running = false;
bool g_logging = false;
char g_pins[3] = {
  RUNNING_LED, SHOOT_LED, TRIGGER_PIN};
ButtonsClass g_buttons(SEL_B, DSL_B, INC_B, DEC_B, CYC_B);
LCDClass g_lcd(20);


void isr_shoot() {
  digitalWrite(SHOOT_LED, HIGH);
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

void toggle() {
  if (g_running)
  {
    MsTimer2::stop();
    g_running = false;
    digitalWrite(RUNNING_LED, LOW);
    READY;
  }
  else
  {
    EEPROM_write(EE_MIN, g_buttons.min);
    EEPROM_write(EE_SEC, g_buttons.sec);
    EEPROM_write(EE_COUNT, g_buttons.count);
    MsTimer2::set(g_period, isr_shoot);
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
  g_lcd.cursor(false);
  g_lcd.clear();
  g_lcd.write(CODEID, 0);

  // LED Output
  int p;
  for(p=0; p<4; p++) {
    pinMode(g_pins[p], OUTPUT);
    digitalWrite(g_pins[p], LOW);
  }

  pinMode(LCD_PWR, OUTPUT);
  digitalWrite(LCD_PWR, HIGH);

  pinMode(EEPROM_RESET, INPUT);
  digitalWrite(EEPROM_RESET, HIGH);
  if (digitalRead(EEPROM_RESET) == LOW) {
    EEPROM_read(EE_MIN, g_buttons.min);
    EEPROM_read(EE_SEC, g_buttons.sec);
    EEPROM_read(EE_COUNT, g_buttons.count);
    Serial.println("Loaded last settings form EEPROM");
    g_lcd.write("Reloading defaults", 1);
  }
  else {
    Serial.println("Resetting default settings");
    g_lcd.write("Resetting defaults", 1);
  }

  // Button pins (also set the pullup resistors)
  g_buttons.pin_setup(HIGH);

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
  static bool first_time = true;
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
    1, 1, 1, 1, 1, 1        };
  static const unsigned int cur_c[] = {
    5, 8, 16, 17, 18, 19        };
  bool updated = g_buttons.read();
  if (g_running != g_buttons.shooting)
    toggle();
  g_period = g_buttons.lapse() * 1000;
  char s[20];
  if (updated || first_time) {
    g_buttons.describe_in(0, s);
    g_lcd.write(s, 1);
    g_buttons.describe_in(1, s);
    g_lcd.write(s, 2);
    g_lcd.write(g_running ? " RUN" : "IDLE", 0, 16);
    g_lcd.power(g_buttons.en_saving);
    g_lcd.cursor_at(cur_l[g_buttons.selection], cur_c[g_buttons.selection]);
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
  first_time = false;
  delay(LOOP_DELAY);
}
















