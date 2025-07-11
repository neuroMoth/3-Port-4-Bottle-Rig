#ifndef REPORTING_H

#define REPORTING_H

#include <Arduino.h>
#include <stdint.h>

// amount of microseconds that a valve duration cannot exceed. If it is
// exceeded, the lick will be thrown out.
const uint32_t MAXIMUM_SAMPLE_VALVE_DURATION = 100000;

struct doorMotorTimeDetails {
  unsigned long movement_start;
  unsigned long movement_end;
  unsigned long movement_duration;

  unsigned long end_rel_to_start;
  unsigned long end_rel_to_trial;

  char *movement_type;
};

void report_motor_movement(String previous_command,
                           doorMotorTimeDetails motor_time,
                           unsigned long program_start_time,
                           unsigned long trial_start_time);

#endif // !REPORTING_H
