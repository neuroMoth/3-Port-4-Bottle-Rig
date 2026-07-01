classdef ExperimentVariables 
    properties (Constant)
        TOTAL_ALLOWED_TIME = 4000; %seconds
        ITI_TIME = 15; %seconds 
        PUNISHMENT_TIME = 10; %seconds
        TTC_CENTER_TIME = 5; %seconds
        TTC_LATERAL_TIME = 5; %seconds
        LICK_WINDOW = 2; %seconds | Defines amount of seconds rat has to complete required amount of licks.
        DELAY_TIME = 3; %seconds | delay from closing the center door to opening the lateral door
        STIMULUS_WINDOW = 200/1000; %ms after valve closes before door goes up (if still within LICK_WINDOW)

        VALVE_SET1 = [2,4];
        VALVE_SET2 = [5,7];
        
        REWARD_LICKS = [4 5 6]; %range of possible rewarded lick to be pseudorandomized per valve
        REWARD_VALVE_DELAY = [10 25 50 75]/1000; % delay from lick detection to valve opening
        BLANK_OPEN_TIME = ([0 5 10])/1000; %seconds divided by 1000 to convert to ms - range to use for jitter

        MAXIMUM_TRIALS = 160;
        MINIMUM_TRIALS = 100;
        TRIALS_PER_BLOCK = 20;

        SKIPPED_TRIALS_THRESHOLD = 20; % threshold of consecutive trials skipped in a 20 trial block to end early
        %CORRECT_REQUIRED_TO_SWITCH = 2;

        % these varaibles are used to make door commands more intuitive and easy to understand & read.
        UP = 0;
        DOWN = 1;
        LEFT_SPOUT = 0;
        RIGHT_SPOUT = 1;

        EXPERIMENT_TIMER_ID = 1;
        LICK_WINDOW_TIMER_ID = 2;
        STIM_WINDOW_TIMER_ID = 3; 
        
        experimentTimeExpired = 'GlobalTimer1_End';
        lickTimeExpired = 'GlobalTimer2_End';
        stimTimeExpired = 'GlobalTimer3_End';
    end
end
