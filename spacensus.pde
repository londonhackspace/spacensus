#include <LiquidCrystal.h>

const int BEAM_IN = 2; // interrupt
const int BEAM_OUT = 3; // interrupt
const int BEAM_ENABLE = 4;

const int ALARM = 5; // PWM

const int LCD_RS = 12;
const int LCD_RW = 11;
const int LCD_ENABLE = 10;
const int LCD_D4 = 9;
const int LCD_D5 = 8;
const int LCD_D6 = 7;
const int LCD_D7 = 6;

const int INTERRUPT_IN = 0;
const int INTERRUPT_OUT = 1;
const int BREAK_MODE = FALLING;
const int BREAK_VAL = LOW;

const int SERIAL_BAUD = 9600;

const long ALARM_TONE_HZ = 9000;

const int READY = 0;
const int WAIT_IN = 1;
const int WAIT_OUT = 2;
const int DELAY = 3;

const long LOOP_WAIT_MS = 50;

const long MIN_PERSON_INTERVAL_MS = 200;
const long MAX_PERSON_INTERVAL_MS = 800;
const long DELAY_BEFORE_RESET_MS = 1000;
const long OBSTRUCTION_INTERVAL_MS = 5000;

boolean updateDisplay = true;
int people = 0;
int state = DELAY;
boolean alarm = false;

long beamInDurationMs = 0;
long beamOutDurationMs = 0;
long breakIntervalMs = 0;
long resetIntervalMs = 0;

LiquidCrystal lcd(LCD_RS, LCD_RW, LCD_ENABLE, LCD_D4, LCD_D5, LCD_D6, LCD_D7);


void setup()
{
  Serial.begin(SERIAL_BAUD);

  pinMode(BEAM_ENABLE, OUTPUT);
  pinMode(BEAM_IN, OUTPUT);
  pinMode(BEAM_OUT, OUTPUT);
  digitalWrite(BEAM_ENABLE, LOW);
  digitalWrite(BEAM_IN, LOW);
  digitalWrite(BEAM_OUT, LOW);
  pinMode(BEAM_IN, INPUT);
  pinMode(BEAM_OUT, INPUT);

  lcd.print("spacensus v0.1");
}

void loop()
{
  switch (state) {
  case DELAY:
    handleResetDelay();
    break;
  case WAIT_OUT:
      handleBreakInterval();
    break;
  case WAIT_IN:
     handleBreakInterval();
    break;
  }
  checkBeamsForObstructions();
  updateScreenIfRequired();
  delay(LOOP_WAIT_MS);
}

void handleBreakInterval() {
    breakIntervalMs += LOOP_WAIT_MS;
    if (breakIntervalMs > DELAY_BEFORE_RESET_MS) {
      ready();
    }
}

void ready() {
  updateDisplay = true;
  state = READY;
  breakIntervalMs = 0;
  attachInterrupt(INTERRUPT_IN, breakIn, BREAK_MODE);
  attachInterrupt(INTERRUPT_OUT, breakOut, BREAK_MODE);
}

void breakIn() {
  handleBeamBreak(INTERRUPT_IN, WAIT_IN, WAIT_OUT, -1);
}

void breakOut() {
  handleBeamBreak(INTERRUPT_OUT, WAIT_OUT, WAIT_IN, 1);
}

void handleBeamBreak(int interrupt, int gotoState, int waitingForState, int increment) {
  if (state == READY) {
    detachInterrupt(interrupt);    
    state = gotoState;
  } 
  else if (state == waitingForState) {
    detachInterrupt(interrupt);    
    if (isBreakIntervalWithinLimits()) {
      people += increment;
      if (people < 0) {
        people = 0;
      }
      updateDisplay = true;
    }
    state = DELAY;

  }
}

boolean isBreakIntervalWithinLimits() {
  return breakIntervalMs >= MIN_PERSON_INTERVAL_MS && breakIntervalMs <= MAX_PERSON_INTERVAL_MS;
}

void handleResetDelay() {
  resetIntervalMs += LOOP_WAIT_MS;
  if (resetIntervalMs >= DELAY_BEFORE_RESET_MS) {
    resetIntervalMs = 0;
    ready();
  }
}

void checkBeamsForObstructions() {
  beamInDurationMs = calculateBeamBreakInterval(BEAM_IN, beamInDurationMs);
  beamOutDurationMs = calculateBeamBreakInterval(BEAM_OUT, beamOutDurationMs);

  if (beamInDurationMs >= OBSTRUCTION_INTERVAL_MS || beamOutDurationMs >= OBSTRUCTION_INTERVAL_MS) {
    alarmOn();
  } 
  else {
    alarmOff();
  }
}

long calculateBeamBreakInterval(int beam, long currentInterval) {
  if (isBeamBroken(beam)) {
    return currentInterval + LOOP_WAIT_MS;
  } 
  else {
    return 0;
  }
}

boolean isBeamBroken(int beam) {
  return (digitalRead(beam) == BREAK_VAL);
}

void alarmOn () {
  if (!alarm) {
    alarm = true;
    tone(ALARM, ALARM_TONE_HZ);
    updateDisplay = true;
  }
}

void alarmOff() {
  if (alarm) {
    alarm = false;
    noTone(ALARM);
    updateDisplay = true;
  }
}

void updateScreenIfRequired() {
  if (updateDisplay) {
    if (alarm) {
      lcd.clear();
      lcd.print("Beam obstructed!");
    } 
    else if (state != DELAY) {
      lcd.clear();
      lcd.print("Occupancy: ");
      lcd.print(people, DEC);   
    } 
    updateDisplay = false;
  }
}





















