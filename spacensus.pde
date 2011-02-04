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

const long ALARM_TONE_HZ = 4000;

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
boolean updateSerial = true;
int people = 0;
int state = DELAY;
int lastIncrement = 0;
boolean alarm = false;
boolean beamInhibited = false;

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

  lcd.begin(16, 2);
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
  processSerialInput();
  updateScreenIfRequired();
  updateSerialStatusIfRequired();
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
      lastIncrement = increment;
      people += increment;
      if (people < 0) {
        people = 0;
      }
      updateDisplay = true;
      updateSerial = true;
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
  if (!beamInhibited) {
    beamInDurationMs = calculateBeamBreakInterval(BEAM_IN, beamInDurationMs);
    beamOutDurationMs = calculateBeamBreakInterval(BEAM_OUT, beamOutDurationMs);
    
    if (beamInDurationMs >= OBSTRUCTION_INTERVAL_MS || beamOutDurationMs >= OBSTRUCTION_INTERVAL_MS) {
      alarmOn();
    } 
    else {
      alarmOff();
    }
  } else {
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
    updateSerial = true;
  }
}

void alarmOff() {
  if (alarm) {
    alarm = false;
    noTone(ALARM);
    updateDisplay = true;
    updateSerial = true;
  }
}

void updateScreenIfRequired() {
  if (updateDisplay) { 
    if (state != DELAY) {
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Occupancy: ");
      lcd.print(people, DEC);   
    }
    if (alarm) {
      lcd.setCursor(0,1);
      lcd.print("Beam obstructed!");
    } else if (beamInhibited) {
      lcd.setCursor(0,1);
      lcd.print("Beams disabled!");
    } else {
      lcd.setCursor(0,1);
      if (lastIncrement > 0) {
        lcd.print("             -->");
      } else if (lastIncrement < 0) {
        lcd.print("<--             ");
      } 
    }

    updateDisplay = false;
  }
}

void updateSerialStatusIfRequired() {
  if (updateSerial) {
    if (alarm) {
      Serial.print("A");
    } 
    else {
      Serial.print("K");
    }

    if (lastIncrement > 0) {
      Serial.print("I");
    } 
    else if (lastIncrement < 0) {
      Serial.print("O");
    } 
    else {
      Serial.print("N");
    }

    if (beamInhibited) {
      Serial.print("X");
    } 
    else {
      Serial.print("L");
    }
    Serial.println(people, DEC);
    updateSerial = false;
  }
}

void beamInhibit() {
  if (!beamInhibited) {
    digitalWrite(BEAM_ENABLE, HIGH);
    beamInhibited = true;
    updateDisplay = true;
  }
  updateSerial = true;
}

void beamEnable() {
  if (beamInhibited) {
    digitalWrite(BEAM_ENABLE, LOW);
    beamInhibited = false;
    updateDisplay = true;
  }
  updateSerial = true;
}

void processSerialInput() {
  if (Serial.available() > 0) { 
    char c = 0;
    char b = -1;
    do {
      b = Serial.read();
      if (b != -1) {
        c = b;
      }
    } 
    while (b != -1);

    switch (c) {
    case 'S':
      updateSerial = true;
      break;
    case 'L':
      beamEnable();
      break;
    case 'X':
      beamInhibit();
      break;
    case 'R':
      people = 0;
      lastIncrement = 0;
      state = DELAY;
      updateSerial = true;
      break;
    }
  }
}

