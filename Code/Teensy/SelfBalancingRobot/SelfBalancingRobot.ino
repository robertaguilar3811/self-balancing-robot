#include <Wire.h>
#include <Encoder.h>

#define I2C_ADDRESS 0x58

// Enable pins
const int LEFT_L_EN  = 2;
const int LEFT_R_EN  = 3;
const int RIGHT_L_EN = 6;
const int RIGHT_R_EN = 7;

// PWM pins
const int LEFT_R_PWM  = 4;
const int LEFT_L_PWM  = 5;
const int RIGHT_R_PWM = 8;
const int RIGHT_L_PWM = 9;

// Encoders
Encoder leftEnc(14, 15);
Encoder rightEnc(16, 17);

// Stored PWM values
uint8_t left_r_pwm  = 0;
uint8_t left_l_pwm  = 0;
uint8_t right_r_pwm = 0;
uint8_t right_l_pwm = 0;

// Stored enable values
bool left_r_en  = false;
bool left_l_en  = false;
bool right_r_en = false;
bool right_l_en = false;

// Encoder counts (volatile since accessed in ISR and main loop)
volatile int32_t left_count  = 0;
volatile int32_t right_count = 0;

void setup() {
  Wire.begin(I2C_ADDRESS);
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);

  pinMode(LEFT_R_EN, OUTPUT);
  pinMode(LEFT_L_EN, OUTPUT);
  pinMode(RIGHT_R_EN, OUTPUT);
  pinMode(RIGHT_L_EN, OUTPUT);

  pinMode(LEFT_R_PWM, OUTPUT);
  pinMode(LEFT_L_PWM, OUTPUT);
  pinMode(RIGHT_R_PWM, OUTPUT);
  pinMode(RIGHT_L_PWM, OUTPUT);

  analogWriteFrequency(LEFT_R_PWM,  20000);
  analogWriteFrequency(LEFT_L_PWM,  20000);
  analogWriteFrequency(RIGHT_R_PWM, 20000);
  analogWriteFrequency(RIGHT_L_PWM, 20000);
}

void loop() {
  digitalWrite(LEFT_R_EN,  left_r_en  ? HIGH : LOW);
  digitalWrite(LEFT_L_EN,  left_l_en  ? HIGH : LOW);
  digitalWrite(RIGHT_R_EN, right_r_en ? HIGH : LOW);
  digitalWrite(RIGHT_L_EN, right_l_en ? HIGH : LOW);

  analogWrite(LEFT_R_PWM,  left_r_pwm);
  analogWrite(LEFT_L_PWM,  left_l_pwm);
  analogWrite(RIGHT_R_PWM, right_r_pwm);
  analogWrite(RIGHT_L_PWM, right_l_pwm);

  left_count  = leftEnc.read();
  right_count = rightEnc.read();
}

// Send encoder counts to CODESYS on request (8 bytes: 4 per encoder)
void requestEvent() {
  uint8_t buf[8];
  buf[0] = (left_count >> 24) & 0xFF;
  buf[1] = (left_count >> 16) & 0xFF;
  buf[2] = (left_count >> 8)  & 0xFF;
  buf[3] =  left_count        & 0xFF;
  buf[4] = (right_count >> 24) & 0xFF;
  buf[5] = (right_count >> 16) & 0xFF;
  buf[6] = (right_count >> 8)  & 0xFF;
  buf[7] =  right_count        & 0xFF;
  Wire.write(buf, 8);
}

// Receive I2C data from CODESYS
void receiveEvent(int howMany) {
  while (Wire.available() >= 2) {
    uint8_t reg = Wire.read();
    uint8_t val = Wire.read();

    switch (reg) {
      case 0x00: left_r_en  = val != 0; break;
      case 0x01: left_l_en  = val != 0; break;
      case 0x02: right_r_en = val != 0; break;
      case 0x03: right_l_en = val != 0; break;
      case 0x04: right_r_pwm = val; break;
      case 0x05: right_l_pwm = val; break;
      case 0x06: left_r_pwm  = val; break;
      case 0x07: left_l_pwm  = val; break;
    }
  }
}
