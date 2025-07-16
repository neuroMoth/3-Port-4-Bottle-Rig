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
    volatile uint8_t *port; // PORT address, ex. PORTL for PORTL's PL6. 
    volatile uint8_t* input_port; // PIN address, ex. PINL for PORTL's PL6. 
    uint8_t pin; // pin number, ex. 6 for PORTL's PL6. 

    MotorType motor_type;
    
    // the below are used only for motors of LINEAR TYPE. they instruct arduino which
    // pins to set high for either direction of the linear actuator.
    volatile uint8_t* linear_up_port;
    uint8_t linear_up_pin;
    volatile uint8_t* linear_down_port;
    uint8_t linear_down_pin;

    unsigned long motor_move_start; // holds the starting time for the last motor movement
    unsigned long motor_signal_start; // holds the starting time for the last motor movement
                              
    bool init_movement_recieved;                            

    bool current_state; // holds current state -> up / down or left / right
    bool previous_state; // holds previous state -> up / down or left / right
    bool motor_running; // true if motor is currently moving to avoid enacting commands recieved too close together, confusing position. 

    bool move_motor;
    bool in_motion;

    
    // function declaration for the contructor of the struct.
    motorInfo(uint8_t dig_pin_num, volatile uint8_t *port_number, volatile uint8_t *import_pin_loc, uint8_t pin_num, MotorType type);

    // function declaration for method that updates the motor current state based on state of pin associated with the 
    // Bpod's desired motor state.
    bool check_state();

    void add_linear_ports(uint8_t up_port, uint8_t up_pin, uint8_t down_port, uint8_t down_pin);
};




#endif // !MOTOR_INFO_H
