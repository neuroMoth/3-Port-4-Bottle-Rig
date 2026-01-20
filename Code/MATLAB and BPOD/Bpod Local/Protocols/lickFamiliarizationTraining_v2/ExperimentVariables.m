classdef ExperimentVariables 
    properties (Constant)
        PORT_FAMILIARIZATION = 1; % FAMILIARIZATION ONLY: 1=Left, 2=Center, 3=Right
        
        TOTAL_ALLOWED_TIME = 1800; %seconds - 30min for familiarization

        VALVE_SET1 = [2]; %Water valves
        %VALVE_SET2 = [5, 6, 7]; %Odor valves
        
        REWARD_LICKS = [5]; %range of possible rewarded lick to be pseudorandomized per valve (+1 from # of dry licks)
        REWARD_VALVE_DELAY = [0/1000]; %delay from lick detection to valve opening
 
        %% Most of these aren't used for familiarization
        
        ITI_TIME = 0; %seconds 
        PUNISHMENT_TIME = 0; %seconds
        TTC_CENTER_TIME = 30; %seconds
        TTC_LATERAL_TIME = 60; %seconds
        LICK_WINDOW = 2; %seconds | Defines amount of seconds rat has to complete required amount of licks.
        DELAY_TIME = 0; %seconds | delay from closing the center door to opening the lateral door
        STIMULUS_WINDOW = 300/1000; %ms after valve closes before door goes up (if still within LICK_WINDOW)
        
        MAXIMUM_TRIALS = 200; 
        MINIMUM_TRIALS = 160; 
        TRIALS_PER_BLOCK = 20; 
        MAX_REPEATS = 4; 

        %SKIPPED_TRIALS_THRESHOLD = 20; % threshold of consecutive trials skipped in a 20 trial block to end early
        %CORRECT_REQUIRED_TO_SWITCH = 9999; % only for use with alternation training days 

        %% these varaibles are used to make door commands more intuitive and easy to understand & read.
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
