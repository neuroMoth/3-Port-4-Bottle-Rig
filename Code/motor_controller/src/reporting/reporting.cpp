#include "reporting.h"

void report_motor_movement(String previous_command,
                           doorMotorTimeDetails motor_time,
                           unsigned long program_start_time,
                           unsigned long trial_start) {
  /*
  This function is called when the door finishes a movement operation. It takes
  the previous command as a parameter and tells the python controller that a
  movement has completed and which type of movement that was, so that we can
  mark these movements down in the lick dataframe. If the movement was up, that
  means a trial just ended and we can increment to the next trial.
  */

  motor_time.movement_duration =
      motor_time.movement_end - motor_time.movement_start;

  // time of motor movement ending relative to program start
  motor_time.end_rel_to_start = motor_time.movement_end - program_start_time;

  motor_time.end_rel_to_trial = motor_time.movement_end - trial_start;

  Serial.print("MOTOR");
  Serial.print("|");
  Serial.print(motor_time.movement_type);
  Serial.print("|");
  Serial.print(motor_time.movement_duration);
  Serial.print("|");
  Serial.print(motor_time.end_rel_to_start);
  Serial.print("|");
  // printline to force data out
  Serial.println(motor_time.end_rel_to_trial);
}

