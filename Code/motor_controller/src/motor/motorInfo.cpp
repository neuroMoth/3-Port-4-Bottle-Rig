#include "motorInfo.h"

motorInfo::motorInfo(uint8_t dig_pin_num, volatile uint8_t *port_number, volatile uint8_t *import_pin_loc, uint8_t pin_num, MotorType type){
    digital_pin = dig_pin_num;
    port = port_number;
    input_port = import_pin_loc;
    pin = pin_num;

    motor_type = type;

    current_state = 0;
    previous_state = 0;
    motor_running = 0;

    init_movement_recieved = 0;
    move_motor = 0;
    in_motion = 0;
}


void motorInfo::add_linear_ports(uint8_t up_port, uint8_t up_pin, uint8_t down_port, uint8_t down_pin){
    linear_up_port = up_port;
    linear_up_pin = up_pin;
    linear_down_port = down_port;
    linear_down_pin = down_pin;
}

bool motorInfo::check_state(){
    bool pin_state = (*this->input_port & (1 << this->pin)) != 0;

    if(pin_state && (!this->previous_state) && (!this->current_state)){
        if(!(this->init_movement_recieved)){
            this->init_movement_recieved = 1;
            this->motor_signal_start = millis();
        }

        if(this->init_movement_recieved && ((millis() - this->motor_signal_start) > 1)){
            this->current_state = 1;

            this->move_motor = 1;
            
            this->init_movement_recieved = 0;
         
        }
    }
    else if((!pin_state) && (this->previous_state) && (this->current_state)){
        if(!(this->init_movement_recieved)){
            this->init_movement_recieved = 1;
            this->motor_signal_start = millis();
        }

        if(this->init_movement_recieved && ((millis() - this->motor_signal_start) > 1)){
            this->current_state = 0;

            this->move_motor = 1;

            this->init_movement_recieved = 0;

        }
    }

    return pin_state;
}
