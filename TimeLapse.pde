#include <EEPROM.h>
#include <avr/power.h>
#include "eeprom.h"
#include "buttons.h"
#include "lcd.h"

// Code version:
#define CODEID "TimeLapse 0.5 "

// Constants
#define READY       Serial.println(">")
#define BAUD        9600
#define LOOP_DELAY  200
#define SHOOT_DELAY 500
#define FOCUS_DELAY 0
#define PAUSE_DELAY 0
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
unsigned long int g_start, g_delay, g_last_shot = 0;
unsigned int g_period = 0;

bool g_running = false;
bool g_logging = false;
bool g_force_update = true;

char g_status[6] = " IDLE";
char g_pins[5] = {
  RUNNING_LED, SHOOT_LED, DELAY_LED, TRIGGER_PIN, FOCUS_PIN};
  
ButtonsClass g_buttons(SEL_B, DSL_B, INC_B, DEC_B, CYC_B);
LCDClass g_lcd(20);


void shoot(unsigned long int now) {
  unsigned long int to_go = g_delay - (now - g_start);
  if (to_go == 0 || to_go > g_delay) {
    g_buttons.set_delay(0);
    strcpy(g_status, "  RUN");
    digitalWrite(DELAY_LED, LOW);
    digitalWrite(SHOOT_LED, HIGH);
    digitalWrite(FOCUS_PIN, HIGH);
    delay(FOCUS_DELAY);
    delay(PAUSE_DELAY);
    digitalWrite(TRIGGER_PIN, HIGH);
    delay(SHOOT_DELAY);
    digitalWrite(SHOOT_LED, LOW);  
    digitalWrite(TRIGGER_PIN, LOW);
    if (g_buttons.count > 0) {
      g_buttons.count--;
      if (g_buttons.count == 0)
        g_buttons.shooting = false;
    }
  }
  else {
    g_buttons.set_delay(to_go);
    strcpy(g_status, "DELAY");
    digitalWrite(DELAY_LED, HIGH);
  }
  g_force_update = true;
}

void toggle(unsigned long int now) {
  if (g_running)
  {
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
    g_running = true;
    g_start = now;
    g_delay = g_buttons.delay();
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
  
  // Disables unneeded modules so to save energy
  power_spi_disable();
  power_twi_disable();
  power_usart2_disable();
  power_usart3_disable();
  power_adc_disable();
  
  // LED Output
  int p;
  for(p=0; p<5; p++) {
    pinMode(g_pins[p], OUTPUT);
    digitalWrite(g_pins[p], LOW);
  }

  // Button pins (also set the pullup resistors)
  g_buttons.pin_setup(HIGH);

  // Saving settings or reloading defaults
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
  unsigned long int now = millis();
  // Read serial commands
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
    1, 1, 2, 2, 2, 2, 2, 2};
  static const unsigned int cur_c[] = {
    14, 18, 5, 8, 16, 17, 18, 19};
  bool updated = g_buttons.read(now);
  if (g_running != g_buttons.shooting)
    toggle(now);
    
  g_period = g_buttons.lapse();
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
  if (g_running and (now / g_period) > g_last_shot) {
    g_last_shot = now / g_period;
    shoot(now);
  }
  if (updated && g_logging) {
    Serial.print(g_buttons.selection);
    Serial.print(" ");
    g_buttons.describe_in(0, s);
    Serial.print(s);
    g_buttons.describe_in(1, s);
    Serial.print(s);
    Serial.println();
  }
  delay(LOOP_DELAY);
}




















