#ifndef MOTOR_INFO_H

#define MOTOR_INFO_H

#include <Arduino.h>
#include <stdint.h>


enum MotorType{
    LINEAR,
    STEPPER,
};



struct motorInfo{
    uint8_t digital_pin; // digital pin number, ex. 43 for PORTL's PL6. 
    uint8_t port; // PORT address, ex. PORTL for PORTL's PL6. 
    uint8_t input_port; // PIN address, ex. PINL for PORTL's PL6. 
    uint8_t pin; // pin number, ex. 6 for PORTL's PL6. 

    MotorType motor_type;

    bool current_state; // holds current state -> up / down or left / right
    bool previous_state; // holds previous state -> up / down or left / right
    bool motor_running; // true if motor is currently moving to avoid enacting commands recieved too close together, confusing position. 

    
    motorInfo(uint8_t dig_pin_num, uint8_t port_number, uint8_t import_pin_loc, uint8_t pin_num, MotorType type);
};

void update_motor_state(motorInfo &motor);



#endif // !MOTOR_INFO_H
