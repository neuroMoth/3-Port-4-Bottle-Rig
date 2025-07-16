#include "./src/reporting/reporting.h"
#include "./src/motor/motorInfo.h"
#include <AccelStepper.h>
#include <stdint.h>


// door stepper motor constants
const int STEPPER_LEFT_POSITION = 0;
const int STEPPER_RIGHT_POSITION = 6000;
const int MAX_SPEED = 5500; 
const int ACCELERATION = 5500;

// time linear actuator is allowed to move in ms
const unsigned long LINEAR_ACTUATOR_TIME = 2000;

const uint8_t DIR_PIN = 53;
const uint8_t STEP_PIN = 51;

AccelStepper stepper = AccelStepper(1, STEP_PIN, DIR_PIN);

uint8_t convert_bool_to_binary(bool bit_1, bool bit_2, bool bit_3, bool bit_4){
  /*
   * funtion to convert four booleans to four bit binary number to quickly check which numbers have changed. 
   * bit_1 is the least significant (rightmost) bit, while bit 4 is the most significant (leftmost) bit. 
   */

    uint8_t value = 0;

    value |= (bit_1? 1 : 0) << 0; 
    value |= (bit_2? 1 : 0) << 1; 
    value |= (bit_3? 1 : 0) << 2; 
    value |= (bit_4? 1 : 0) << 3; 

    return value;
}

void move_stepper(motorInfo* motor){
  /*
   * function to move a stepper motor from current position to new target.
   * essentially just sets new target based on desired new state.
   */
  switch(motor->current_state){
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

void move_linear(motorInfo* motor){
  /*
   * funtion to move linear actuator to new desired position based on desired position as indicated in motor.current_state.
   */
  switch(motor->current_state){
  case 0:
    // move up 
    *(motor->linear_down_port) &= ~(1 << motor->linear_down_pin);
    *(motor->linear_up_port) |= (1 << motor->linear_up_pin);
    
    motor->motor_move_start = millis();

    break;
  case 1:
    // move down 
    *(motor->linear_up_port) &= ~(1 << motor->linear_up_pin);
    *(motor->linear_down_port) |= (1 << motor->linear_down_pin);
    
    motor->motor_move_start = millis();
    break;
  }
}



void setup() {
  Serial.begin(115200);
  stepper.setMaxSpeed(MAX_SPEED);
  stepper.setAcceleration(ACCELERATION);

  // set PL6, PL4, PL2, PL0 to input pins
  DDRL &= ~(1 << PL6); 
  DDRL &= ~(1 << PL4); 
  DDRL &= ~(1 << PL2); 
  DDRL &= ~(1 << PL0); 

  // set PA0, PA1, PA2, PA3, PA4, PA5 to input pins
  DDRA |= (1 << PA0);
  DDRA |= (1 << PA1);
  DDRA |= (1 << PA2);
  DDRA |= (1 << PA3);
  DDRA |= (1 << PA4);
  DDRA |= (1 << PA5);


  PORTA |= (1 << PA0);
  PORTA |= (1 << PA2);
  PORTA |= (1 << PA4);
  delay(4000);

  PORTA &= ~(1 << PA0);
  PORTA &= ~(1 << PA2);
  PORTA &= ~(1 << PA4);


  PORTA |= (1 << PA1);
  PORTA |= (1 << PA3);
  PORTA |= (1 << PA5);
  delay(500);
  PORTA &= ~(1 << PA1);
  PORTA &= ~(1 << PA3);
  PORTA &= ~(1 << PA5);


}

void loop() {
  static unsigned long last_poll = 0;
  
  // define motorInfo objects that track current and previous states of the various motors controlled by the arduino.
  // also pass in pin number that state is sent to by the Bpod.
    
  static motorInfo door_1 = motorInfo(43, PORTL, &PINL, PL6, MotorType::LINEAR);
  // the below line is used to specify that PORTs and PINs that will be written to to move a 
  // linear actuator in a given direction. the first two are the UP pin, the second two are DOWN pin.
  door_1.add_linear_ports(&PORTA, PA0, &PORTA, PA1);

  static motorInfo door_2 = motorInfo(45, PORTL, &PINL, PL4, MotorType::LINEAR);
  door_2.add_linear_ports(&PORTA, PA2, &PORTA, PA3);

  static motorInfo door_3 = motorInfo(47, PORTL, &PINL, PL2, MotorType::LINEAR);
  door_3.add_linear_ports(&PORTA, PA4, &PORTA, PA5);

  static motorInfo center_port = motorInfo(49, PORTL, &PINL, PL0, MotorType::STEPPER);

  static motorInfo* motors[] = {&door_1, &door_2, &door_3, &center_port};
  static int num_motors = sizeof(motors) / sizeof(motors[0]);

  static uint8_t current_val = 0;
  static uint8_t last_val = 0;
  
  if(millis() - last_poll > 1){
    last_val = convert_bool_to_binary(center_port.current_state, door_3.current_state, door_2.current_state, door_1.current_state);

    bool state_1 = door_1.check_state();  
    door_2.check_state();  
    door_3.check_state();  
    center_port.check_state();  


    current_val = convert_bool_to_binary(center_port.current_state, door_3.current_state, door_2.current_state, door_1.current_state);

    last_poll = millis();
  }

  //static doorMotorTimeDetails motor_time = {};
  // not needed at this time, may add in later.
  for(int i = 0; i < num_motors; i++){
    motorInfo* motor = motors[i]; 

    if(motor->move_motor){
        switch(motor->motor_type){
          case MotorType::LINEAR:
            move_linear(motor);

            motor->move_motor = 0;
            motor->in_motion = 1;
            break;
          case MotorType::STEPPER:
            move_stepper(motor);
            
            motor->move_motor = 0;
            motor->in_motion = 1;
            break;
        }
    }else if(motor->in_motion){
      switch(motor->motor_type){
        case MotorType::LINEAR:
          if ((millis() - motor->motor_move_start) > LINEAR_ACTUATOR_TIME){
            switch(motor->current_state){
              case 0:
                // move up 
                *(motor->linear_up_port) &= ~(1 << motor->linear_up_pin);
                motor->previous_state = 0;
                
                motor->in_motion = 0;



                break;
              case 1:
                // move down
                *(motor->linear_down_port) &= ~(1 << motor->linear_down_pin);

                motor->previous_state = motor->current_state;
                motor->previous_state = 1;
                
                motor->in_motion = 0;
                break;
            }
          }
          break;
        default:
          break;
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


