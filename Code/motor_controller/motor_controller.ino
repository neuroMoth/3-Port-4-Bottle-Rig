#include "./src/reporting/reporting.h"
#include "./src/motor/motorInfo.h"
#include <AccelStepper.h>
#include <stdint.h>


// door stepper motor constants
const int STEPPER_LEFT_POSITION = 0;
const int STEPPER_RIGHT_POSITION = 6000;
const int MAX_SPEED = 5500; 
const int ACCELERATION = 5500;

const uint8_t DIR_PIN = 53;
const uint8_t STEP_PIN = 51;

AccelStepper stepper = AccelStepper(1, STEP_PIN, DIR_PIN);

uint8_t convert_bool_to_binary(bool bit_1, bool bit_2, bool bit_3, bool bit_4){
  /*
   * method to convert four booleans to four bit binary number to quickly check which numbers have changed. 
   * bit_1 is the least significant (rightmost) bit, while bit 4 is the most significant (leftmost) bit. 
   */

    uint8_t value = 0;

    value |= (bit_1? 1 : 0) << 0; 
    value |= (bit_2? 1 : 0) << 1; 
    value |= (bit_3? 1 : 0) << 2; 
    value |= (bit_4? 1 : 0) << 3; 

    return value;
}

void move_stepper(bool state, AccelStepper &stepper){
  switch(state){
  case 0:
    // move left
    stepper.moveTo(STEPPER_LEFT_POSITION);
    break;
  case 1:
    // move right
    stepper.moveTo(STEPPER_RIGHT_POSITION);
    break;
  }
}

void move_linear(bool state, AccelStepper &stepper){
  switch(state){
  case 0:
    // move left
    stepper.moveTo(STEPPER_LEFT_POSITION);
    break;
  case 1:
    // move right
    stepper.moveTo(STEPPER_RIGHT_POSITION);
    break;
  }
}



void setup() {
  stepper.setMaxSpeed(MAX_SPEED);
  stepper.setAcceleration(ACCELERATION);
}

void loop() {
  static unsigned long last_poll = 0;
  
  // define motorInfo objects that track current and previous states of the various motors controlled by the arduino.
  // also pass in pin number that state is sent to by the Bpod.
    
  static motorInfo door_1 = motorInfo(43, PORTL, PINL, PL6, MotorType::LINEAR);
  static motorInfo door_2 = motorInfo(45, PORTL, PINL, PL4, MotorType::LINEAR);
  static motorInfo door_3 = motorInfo(47, PORTL, PINL, PL2, MotorType::LINEAR);
  static motorInfo center_port = motorInfo(49, PORTL, PINL, PL0, MotorType::STEPPER);

  static motorInfo* motors[] = {&door_1, &door_2, &door_3, &center_port};
  static int num_motors = sizeof(motors) / sizeof(motorInfo[0]);

  static uint8_t current_val = 0;
  static uint8_t last_val = 0;
  
  if(millis() - last_poll > 1){
    last_val = convert_bool_to_binary(center_port.current_state, door_3.current_state, door_2.current_state, door_1.current_state);

    update_motor_state(door_1);  
    update_motor_state(door_2);  
    update_motor_state(door_3);  
    update_motor_state(center_port);  

    
    current_val = convert_bool_to_binary(center_port.current_state, door_3.current_state, door_2.current_state, door_1.current_state);

    last_poll = millis();
  }

  //static doorMotorTimeDetails motor_time = {};
  // not needed at this time, may add in later.
 
  for(int i = 0; i < num_motors; i++){
    motorInfo* motor = motors[i]; 

    if(!motor->motor_running){
      if(motor->current_state != motor->previous_state){
        switch(motor->motor_type){
          case MotorType::LINEAR:
            break;
          case MotorType::STEPPER{
            break;
          }

        }
      }
    }
  }

  // check if center_port_motor_running first to avoid unneccessary calls to stepper.distanceToGo()
  if (center_port.motor_running && stepper.distanceToGo() == 0) {
    // at this stage we have filled movement_start, movement_type, and now movement_end
    //motor_time.movement_end = millis();

    //report_motor_movement(previous_command, motor_time, program_start_time, trial_start_time);

    center_port.motor_running = false;
  }


  stepper.run();
}


