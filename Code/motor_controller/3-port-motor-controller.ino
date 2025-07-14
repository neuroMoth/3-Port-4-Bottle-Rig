#include "./src/reporting/reporting.h"
#include <AccelStepper.h>
#include <avr/wdt.h>

const unsigned long BAUD_RATE = 115200;

// door stepper motor constants
const int STEPPER_LEFT_POSITION = 0;
const int STEPPER_RIGHT_POSITION = 6000;
const int MAX_SPEED = 5500; 
const int ACCELERATION = 5500;

const uint8_t DIR_PIN = 53;
const uint8_t STEP_PIN = 51;

AccelStepper stepper = AccelStepper(1, STEP_PIN, DIR_PIN);

void setup() {
  Serial.begin(BAUD_RATE);

  stepper.setMaxSpeed(MAX_SPEED);
  stepper.setAcceleration(ACCELERATION);
}

void loop() {
  String command = "\0";
  // define all variables used in experiment runtime scope  
  static String previous_command = "\0";

  static bool center_port_motor_running = false; 

  static unsigned long last poll = 0;

  if(millis() - last_poll > 5){

    // 0 == Down, 1 == Up 
    static bool door_1_state = PINL & (1 << PL6); // Digital 43
    static bool door_2_state = PINL & (1 << PL4); // Digital 45
    static bool door_3_state = PINL & (1 << PL2); // Digital 47

    // 0 == Left from the perspective of the rat. 1 == Right from perspective of the rat
    static bool center_port_state = PINL & (1 << PL0); // Digital 49

    last_poll = millis();
  }

  static doorMotorTimeDetails motor_time = {};

  if (Serial.available() > 0) {
    // read until the newline char 
    command = Serial.readStringUntil('\n');
  }
  // only process command cases if one has been recieved from the controller
  if (!command.equals("\0")){
  }


  // check if center_port_motor_running first to avoid unneccessary calls to stepper.distanceToGo()
  if (center_port_motor_running && stepper.distanceToGo() == 0) {
    // at this stage we have filled movement_start, movement_type, and now movement_end
    motor_time.movement_end = millis();

    //report_motor_movement(previous_command, motor_time, program_start_time, trial_start_time);

    center_port_motor_running = false;
  }


  stepper.run();
}
