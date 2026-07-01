classdef ExperimentVariables 
    properties (Constant)
        TOTAL_ALLOWED_TIME = 4000; %seconds
        ITI_TIME = 10; %seconds 
        PUNISHMENT_TIME = 10; %seconds
        TTC_CENTER_TIME = 15; %seconds
        TTC_LATERAL_TIME = 15; %seconds
        LICK_WINDOW = 2; %seconds | Defines amount of seconds rat has to complete required amount of licks.
        DELAY_TIME = 3; %seconds | delay from closing the center door to opening the lateral door
        STIMULUS_WINDOW = 300/1000; %ms after valve closes before door goes up (if still within LICK_WINDOW)

        VALVE_SET1 = [2, 3, 4]; %Water valves
        VALVE_SET2 = [5, 6, 7]; %Odor valves
        
        REWARD_LICKS = [4 5 6]; %range of possible rewarded lick to be pseudorandomized per valve (+1 from # of dry licks)
        REWARD_VALVE_DELAY = [10 25 50 75]/1000; %delay from lick detection to valve opening
 
        MAXIMUM_TRIALS = 160; 
        MINIMUM_TRIALS = 160; 
        TRIALS_PER_BLOCK = 20; 
        MAX_REPEATS = 4; 

        %SKIPPED_TRIALS_THRESHOLD = 20; % threshold of consecutive trials skipped in a 20 trial block to end early
        CORRECT_REQUIRED_TO_SWITCH = 8; % only for use with alternation training days 

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
