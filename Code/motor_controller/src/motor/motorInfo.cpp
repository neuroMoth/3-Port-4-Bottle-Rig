#include "motorInfo.h"

motorInfo::motorInfo(uint8_t dig_pin_num, uint8_t port_number, uint8_t import_pin_loc, uint8_t pin_num, MotorType type){
    digital_pin = dig_pin_num;
    port = port_number;
    input_port = import_pin_loc;
    pin = pin_num;

    motor_type = type;

    current_state = 1;
    previous_state = 1;
    motor_running = 0;
}


void update_motor_state(motorInfo &motor){
    motor.previous_state = motor.current_state;

    motor.current_state = motor.input_port & (1 << motor.pin); // Digital 43
}



