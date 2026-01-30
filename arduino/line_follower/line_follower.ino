/*
 * Medical Delivery Robot - Arduino Line Follower
 * 
 * Hardware:
 * - 5 IR Sensors (L2, L1, C, R1, R2)
 * - 2 DC Motors (Left, Right)
 * - Motor Driver (L298N)
 * - Serial Communication with Raspberry Pi
 * 
 * Logic:
 * - PID line following
 * - When all sensors detect black -> STOP and send "STOP" to RPi
 * - Wait for "RESUME" command from RPi
 */

// IR Sensor Pins
#define IR_L2 A0
#define IR_L1 A1
#define IR_C  A2
#define IR_R1 A3
#define IR_R2 A4

// Motor Driver Pins (L298N)
#define MOTOR_L_EN 5   // Left motor enable (PWM)
#define MOTOR_L_IN1 6
#define MOTOR_L_IN2 7

#define MOTOR_R_EN 10  // Right motor enable (PWM)
#define MOTOR_R_IN1 8
#define MOTOR_R_IN2 9

// PID Constants
#define KP 20
#define KI 0
#define KD 10

// Motor Speed
#define BASE_SPEED 150
#define MAX_SPEED 255

// Sensor Threshold (adjust based on your sensors)
#define BLACK_THRESHOLD 500  // Values above = black line

// State
bool isWaiting = false;
int lastError = 0;
float integral = 0;

void setup() {
  // Initialize serial
  Serial.begin(9600);
  
  // Initialize motor pins
  pinMode(MOTOR_L_EN, OUTPUT);
  pinMode(MOTOR_L_IN1, OUTPUT);
  pinMode(MOTOR_L_IN2, OUTPUT);
  pinMode(MOTOR_R_EN, OUTPUT);
  pinMode(MOTOR_R_IN1, OUTPUT);
  pinMode(MOTOR_R_IN2, OUTPUT);
  
  // Initialize IR sensor pins
  pinMode(IR_L2, INPUT);
  pinMode(IR_L1, INPUT);
  pinMode(IR_C, INPUT);
  pinMode(IR_R1, INPUT);
  pinMode(IR_R2, INPUT);
  
  delay(1000);
  Serial.println("🤖 Medical Delivery Robot - Arduino Online");
}

void loop() {
  // Read sensors
  int l2 = analogRead(IR_L2);
  int l1 = analogRead(IR_L1);
  int c  = analogRead(IR_C);
  int r1 = analogRead(IR_R1);
  int r2 = analogRead(IR_R2);
  
  // Convert to binary (1 = black, 0 = white)
  bool s_l2 = (l2 > BLACK_THRESHOLD);
  bool s_l1 = (l1 > BLACK_THRESHOLD);
  bool s_c  = (c > BLACK_THRESHOLD);
  bool s_r1 = (r1 > BLACK_THRESHOLD);
  bool s_r2 = (r2 > BLACK_THRESHOLD);
  
  // Check if all sensors detect black (STOP condition)
  if (s_l2 && s_l1 && s_c && s_r1 && s_r2) {
    stopMotors();
    
    if (!isWaiting) {
      Serial.println("STOP");
      isWaiting = true;
    }
    
    // Wait for RESUME command
    waitForResume();
    return;
  }
  
  // Normal line following with PID
  if (!isWaiting) {
    int error = calculateError(s_l2, s_l1, s_c, s_r1, s_r2);
    int correction = calculatePID(error);
    
    int leftSpeed = constrain(BASE_SPEED + correction, 0, MAX_SPEED);
    int rightSpeed = constrain(BASE_SPEED - correction, 0, MAX_SPEED);
    
    setMotorSpeed(leftSpeed, rightSpeed);
  }
}

int calculateError(bool l2, bool l1, bool c, bool r1, bool r2) {
  /*
   * Error calculation based on sensor positions
   * Negative = line is left, Positive = line is right
   * 
   * Sensor positions: L2(-2) L1(-1) C(0) R1(1) R2(2)
   */
  
  if (c) return 0;           // Centered - perfect!
  if (l1) return -1;         // Slightly left
  if (r1) return 1;          // Slightly right
  if (l2) return -2;         // Far left
  if (r2) return 2;          // Far right
  
  // No line detected (use last error)
  return lastError;
}

int calculatePID(int error) {
  integral += error;
  int derivative = error - lastError;
  lastError = error;
  
  // Prevent integral windup
  integral = constrain(integral, -100, 100);
  
  int correction = (KP * error) + (KI * integral) + (KD * derivative);
  return correction;
}

void setMotorSpeed(int leftSpeed, int rightSpeed) {
  // Left motor
  if (leftSpeed >= 0) {
    digitalWrite(MOTOR_L_IN1, HIGH);
    digitalWrite(MOTOR_L_IN2, LOW);
    analogWrite(MOTOR_L_EN, leftSpeed);
  } else {
    digitalWrite(MOTOR_L_IN1, LOW);
    digitalWrite(MOTOR_L_IN2, HIGH);
    analogWrite(MOTOR_L_EN, abs(leftSpeed));
  }
  
  // Right motor
  if (rightSpeed >= 0) {
    digitalWrite(MOTOR_R_IN1, HIGH);
    digitalWrite(MOTOR_R_IN2, LOW);
    analogWrite(MOTOR_R_EN, rightSpeed);
  } else {
    digitalWrite(MOTOR_R_IN1, LOW);
    digitalWrite(MOTOR_R_IN2, HIGH);
    analogWrite(MOTOR_R_EN, abs(rightSpeed));
  }
}

void stopMotors() {
  digitalWrite(MOTOR_L_IN1, LOW);
  digitalWrite(MOTOR_L_IN2, LOW);
  analogWrite(MOTOR_L_EN, 0);
  
  digitalWrite(MOTOR_R_IN1, LOW);
  digitalWrite(MOTOR_R_IN2, LOW);
  analogWrite(MOTOR_R_EN, 0);
}

void waitForResume() {
  while (isWaiting) {
    if (Serial.available() > 0) {
      String command = Serial.readStringUntil('\n');
      command.trim();
      
      if (command == "RESUME") {
        isWaiting = false;
        integral = 0;  // Reset PID
        lastError = 0;
        Serial.println("✅ Resumed line following");
        break;
      }
    }
    delay(10);
  }
}
