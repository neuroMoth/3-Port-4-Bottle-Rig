#ifndef DOOR_INFO_H

#define DOOR_INFO_H

#include <Arduino.h>
#include <stdint.h>

struct doorInfo{
    int pin;
    static bool current_state; 
    static bool previous_state;
};

doorInfo(int pin);


#endif // !DOOR_INFO_H
