classdef ExperimentVariables 
    properties (Constant)
        TOTAL_ALLOWED_TIME = 3600; %seconds / 60 minutes.
        ITI_TIME = 5; %seconds 
        PUNISHMENT_TIME = 10; %seconds
        TTC_CENTER_TIME = 15; %seconds
        TTC_LATERAL_TIME = 15; %seconds
        LICK_WINDOW = 2; %seconds | Defines amount of seconds rat has to complete required amount of licks.

        EXPERIMENT_TIMER_ID = 1;
        LICK_WINDOW_TIMER_ID = 2;
        
        MAXIMUM_TRIALS = 200;
        MINIMUM_TRIALS = 100;
        TRIALS_PER_BLOCK = 20;

        SKIPPED_TRIALS_THRESHOLD = 10; % threshold of consecutive trials skipped in a 20 trial block to end early
        CORRECT_REQUIRED_TO_SWITCH = 4;

        % these varaibles are used to make door commands more intuitive and easy to understand & read.
        UP = 0;
        DOWN = 1;
        LEFT_SPOUT = 0;
        RIGHT_SPOUT = 1;
            
        experimentTimerID = 1;
        lickWindowTimerID = 2; 
        
        experimentTimeExpired = 'GlobalTimer1_End';
        lickTimeExpired = 'GlobalTimer2_End';
    end
end
