/*
 * Disclaimer:
 *
 * This is both a hack and my first Arduino project. The quality of this
 * Code is not up to my Java programming standards so please don't judge
 * me by it!
 */
#include <Dogm.h>
#include <MsTimer2.h>
#include "DisplayPeopleSprites.h"
#include "DisplayArrowSprites.h"

const unsigned long MAX_LONG = (2^32) - 1;

const int BEAM_IN = 2; // interrupt
const int BEAM_OUT = 3; // interrupt
const int BEAM_ENABLE = 4;

const int ALARM = 5; // PWM

const int BUTTON_INCREMENT = A0;
const int BUTTON_DECREMENT = A1;

const int LCD_PIN = 9;

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

//const long BEAM_SEPERATION_MM = 240;
//const long MIN_WALKING_SPEED_MM_PER_S = 1300;
//const long MAX_WALKING_SPEED_MM_PER_S = 2500;

const long MIN_PERSON_INTERVAL_MS = 7; //( ( MIN_WALKING_SPEED_MM_PER_S / 1000 ) * BEAM_SEPERATION_MM);
const long MAX_PERSON_INTERVAL_MS = 70; //( ( MAX_WALKING_SPEED_MM_PER_S / 1000 ) * BEAM_SEPERATION_MM);
const long DELAY_BEFORE_RESET_MS = 750;
const long OBSTRUCTION_INTERVAL_MS = 10000;

const long ONE_MINUTE_IN_MS = 60000;

volatile boolean updateDisplay = true;
volatile boolean updateSerial = true;
volatile int people = 0;
volatile int state = DELAY;
volatile int lastIncrement = 0;
volatile boolean wrongBeam = false;
volatile boolean wrongState = false;
boolean alarm = false;
boolean beamInhibited = false;

long beamInDurationMs = 0;
long beamOutDurationMs = 0;
volatile unsigned long breakStartMs = 0;

int incrButtonState;
int lastIncrButtonState = HIGH;
int decrButtonState;
int destIncrButtonState = HIGH;

long bothButtonPressMs = 0;
boolean beamToggled = false;

int history[128];
int lastTenMinutes[10];
int maximums[128];
int maximum = 0;
int walkCycle = 0;
int warningCycle = 0;
long screenTimeout = 0;
long minuteCounter = 0;
int minutesRolled = 0;
float scaleFactor = 1.0;

Dogm dogm(LCD_PIN);

void setup()
{
  Serial.begin(SERIAL_BAUD);

  pinMode(BEAM_ENABLE, OUTPUT);
  pinMode(BEAM_IN, OUTPUT);
  pinMode(BEAM_OUT, OUTPUT);
  pinMode(ALARM, OUTPUT);
  pinMode(BUTTON_INCREMENT, OUTPUT);
  pinMode(BUTTON_DECREMENT, OUTPUT);
  digitalWrite(BEAM_ENABLE, LOW);
  digitalWrite(BEAM_IN, LOW);
  digitalWrite(BEAM_OUT, LOW);
  digitalWrite(BUTTON_INCREMENT, HIGH);
  digitalWrite(BUTTON_DECREMENT, HIGH);
  pinMode(BEAM_IN, INPUT);
  pinMode(BEAM_OUT, INPUT);
  pinMode(BUTTON_INCREMENT, INPUT);
  pinMode(BUTTON_DECREMENT, INPUT);

  for (int x = 0; x < 128; x++) {
    history[x] = 0;
    maximums[x] = 0;
  }
  for (int x = 0; x < 10; x++) {
    lastTenMinutes[x] = 0;
  }
  ready();
  updateSerial = true;
}

void loop()
{
  checkBeamsForObstructions();
  processSerialInput();
  updateButtons();
  updateHistory();
  updateScreenIfRequired();
  updateSerialStatusIfRequired();
  delay(LOOP_WAIT_MS);
}

void ready() {
  MsTimer2::stop();
  updateDisplay = true;
  state = READY;
  wrongBeam = false;
  wrongState = false;
  attachInterrupt(INTERRUPT_IN, breakIn, BREAK_MODE);
  attachInterrupt(INTERRUPT_OUT, breakOut, BREAK_MODE);
}

void breakIn() {
  handleBeamBreak(INTERRUPT_IN, WAIT_IN, WAIT_OUT, -1, BEAM_OUT);
}

void breakOut() {
  handleBeamBreak(INTERRUPT_OUT, WAIT_OUT, WAIT_IN, 1, BEAM_IN);
}

String getDirection(int beam) {
  String dir;
  if (beam == BEAM_IN) {
    dir = "Outer";
  } else {
    dir = "Inner"; 
  }
  return dir;
}

String getDirectionInv(int beam) {
  String dir;
  if (beam == BEAM_IN) {
    dir = "Inner";
  } else {
    dir = "Outer"; 
  }
  return dir;
}

void handleBeamBreak(int interrupt, int gotoState, int waitingForState, int increment, int otherBeam) {
  unsigned long now = millis();
  if (state == READY) {
    if (digitalRead(otherBeam) != BREAK_VAL) {
      detachInterrupt(interrupt);
      Serial.print("Ready -> WaitForBreak");
      Serial.println(getDirection(otherBeam));
      state = gotoState;
      MsTimer2::set(MAX_PERSON_INTERVAL_MS, timerTransitionToReady);
      breakStartMs = now;
      MsTimer2::start();
    } else {
      wrongBeam = true; 
    }
  } 
  else if (state == waitingForState) {
    MsTimer2::stop();
    state = DELAY;
    boolean tooLong = true;
    if (isBreakIntervalWithinLimits(now)) {
      modifyPeopleCount(increment);
      tooLong = false;
    }
    detachInterrupt(interrupt);
    Serial.print("GotBreak");
    Serial.print(getDirectionInv(otherBeam));
    Serial.print(" -> Delay");
    if (tooLong) {
      Serial.print(" (too long)");  
    }
    Serial.println("");
    MsTimer2::set(DELAY_BEFORE_RESET_MS, timerTransitionToReady);
    MsTimer2::start();
  } else {
    wrongState = true; 
  }
}

void timerTransitionToReady() {
  if (wrongBeam) {
     Serial.println("Earlier: same beam broken");
  }
  if (wrongState) {
     Serial.println("Earlier: beam broken in wrong state");
  }
  Serial.println("Delay -> Ready");
  ready();
}

void modifyPeopleCount(int increment) {
  lastIncrement = increment;
  people += increment;
  if (people < 0) {
    people = 0;
  }
  maximum = max(maximum,people);
  updateDisplay = true;
  updateSerial = true;
}

boolean isBreakIntervalWithinLimits(unsigned long breakStopMs) {
  unsigned long breakIntervalMs = absTimeDifference(breakStartMs, breakStopMs);
  return breakIntervalMs >= MIN_PERSON_INTERVAL_MS;
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
    updateSerial = true;
  }
}

void beamEnable() {
  if (beamInhibited) {
    digitalWrite(BEAM_ENABLE, LOW);
    beamInhibited = false;
    updateDisplay = true;
    updateSerial = true;
  }
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

    updateSerial = true;
    switch (c) {
    case 'S':
      break;
    case 'L':
      beamEnable();
      break;
    case 'X':
      beamInhibit();
      break;
    case 'M':
      noTone(ALARM);
      break;
    case 'R':
      people = 0;
      lastIncrement = 0;
      updateDisplay = true;
      state = DELAY;
      break;
    case 'I':
      modifyPeopleCount(1);
      break;
    case 'D':
      modifyPeopleCount(-1);
      break;
    default:
      updateSerial = false;
      break;
    }
  }
}

void updateButtons() {
  int incrReading = digitalRead(BUTTON_INCREMENT);
  int decrReading = digitalRead(BUTTON_DECREMENT);

  if (incrButtonState == HIGH && incrReading == LOW && decrReading == HIGH) {
    modifyPeopleCount(1);
  } 
  else if (decrButtonState == HIGH && decrReading == LOW && incrReading == HIGH) {
    modifyPeopleCount(-1);
  }

  incrButtonState = incrReading; 
  decrButtonState = decrReading;

  if (decrButtonState == LOW && incrButtonState == LOW) {
    if (!beamToggled) {
      bothButtonPressMs += LOOP_WAIT_MS;
    }
  } 
  else {
    beamToggled = false;
    bothButtonPressMs = 0;
  }

  if (bothButtonPressMs >= 5000 && !beamToggled) {
    toggleBeam();
  }
}

void toggleBeam() {
  beamToggled = true;
  if (beamInhibited) {
    beamEnable();
  } 
  else {
    beamInhibit();
  }
}

void updateScreenIfRequired() {
  screenTimeout += LOOP_WAIT_MS;
  if (screenTimeout > 250) {
    screenTimeout = 0;
    updateDisplay = true;
  }
  if (updateDisplay) {
    dogm.start();
    do {
      drawHeader();
      drawIndicator();
      drawGraph();
      drawFooter();
    } 
    while( dogm.next() );
    walkCycle++;
    if (walkCycle == 7 ) {
      walkCycle = 0;
    }
    warningCycle++;
    if (warningCycle == 9 ) {
      warningCycle = 0;
    }
    updateDisplay = false;
  }
}

void drawGraph() {
  dogm.drawLine(0, 13, 0, 46);
  for (int x = 0; x < 128; x++) {
    int level = (int) ((float) history[x] * scaleFactor);
    dogm.drawLine(x, 13, x, 13 + level);
  }
}

void drawFooter() {
  dogm.setFont(font_6x9);
  dogm.setXY(0,1);
  dogm.setRot(0);

  if (warningCycle > 4 && (alarm || beamInhibited)) {
    if (alarm) {
      dogm.drawStr("Beam obstructed!");
    } 
    else if (beamInhibited) { 
      dogm.drawStr("Beams disabled!");
    } 
  } 
  else {
    drawTextAndNumber("24hr maximum: ", maximum);
  }
}

void drawHeader() {
  dogm.setFont(font_7x13);
  dogm.setXY(0,54);
  dogm.setRot(0);
  drawTextAndNumber("Occupancy: ", people);
}

void drawIndicator() {
  if (lastIncrement < 0) {
    dogm.setBitmap(101, 62, ARROW_BITMAPS, ARROW_WIDTH, ARROW_HEIGHT);
    dogm.setBitmap(120, 63, OUT_PEOPLE_BITMAPS + walkCycle * PEOPLE_CHARS, PEOPLE_WIDTH, PEOPLE_HEIGHT);

  } 
  else if (lastIncrement > 0) {
    dogm.setBitmap(116, 62, ARROW_BITMAPS + ARROW_CHARS, ARROW_WIDTH, ARROW_HEIGHT);
    dogm.setBitmap(101, 63, IN_PEOPLE_BITMAPS + walkCycle * PEOPLE_CHARS, PEOPLE_WIDTH, PEOPLE_HEIGHT);
  } 
}

void drawTextAndNumber(String message, int number) {
  message += String(number, DEC);
  char charBuffer[20];
  message.toCharArray(charBuffer, 20);
  dogm.drawStr(charBuffer);
}

void updateHistory() {
  if (minuteCounter >= ONE_MINUTE_IN_MS) {
    int sum = 0;
    int localMaximum = 0;
    int localMaximumAvg = 0;
    for (int x = 0; x < 9; x++) {
      lastTenMinutes[x] = lastTenMinutes[x + 1];
      sum += lastTenMinutes[x];
      localMaximum = max(localMaximum, lastTenMinutes[x]);
    }
    lastTenMinutes[9] = people;
    sum += lastTenMinutes[9];
    localMaximum = max(localMaximum, lastTenMinutes[9]);
    minutesRolled++;
    minuteCounter = 0;
    if (minutesRolled >= 10) {
      maximum = 0;
      int average = sum / 10;
      for (int x = 0; x < 127; x++) {
        history[x] = history[x + 1];
        localMaximumAvg = max(localMaximumAvg, history[x]);
        maximums[x] = maximums[x + 1];
        maximum = max(maximum, maximums[x]);
      }
      history[127] = average;
      localMaximumAvg = max(localMaximumAvg, history[127]);
      maximums[127] = localMaximum;
      maximum = max(maximum, history[127]);
      minutesRolled = 0;
      if (localMaximumAvg < 1) {
        scaleFactor = 1.0;
      } 
      else {
        scaleFactor = 33.0 / (float) localMaximumAvg;
      }
      updateDisplay = true;
    }
  } 
  else {
    minuteCounter += LOOP_WAIT_MS;
  }
}

long absTimeDifference(long past, long present) {
  if (past < present) {
    return present - past;
  } 
  else if (past > present) {
    return (MAX_LONG - past) + present;
  } 
  else {
    return 0;
  }
}


