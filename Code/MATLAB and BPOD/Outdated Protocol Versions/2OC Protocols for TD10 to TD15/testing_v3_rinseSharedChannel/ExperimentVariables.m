classdef ExperimentVariables 
    properties (Constant)
        TOTAL_ALLOWED_TIME = 4500; %seconds
        ITI_TIME = 15; %seconds 
        ITI_ENDTIME = 2; %portion of ITI for the end of the trial (taken from the whole ITI duration)
        PUNISHMENT_TIME = 10; %seconds
        TTC_CENTER_TIME = 5; %seconds
        TTC_LATERAL_TIME = 5; %seconds
        LICK_WINDOW = 2; %seconds | Defines amount of seconds rat has to complete required amount of licks.
        DELAY_TIME = 3; %seconds | delay from closing the center door to opening the lateral door
        STIMULUS_WINDOW = 50/1000; %ms after final valve closes before door goes up (if still within LICK_WINDOW)

        VALVE_SET1 = [3]; % Water valves
        VALVE_SET2 = [5]; % Odor valves
        RINSE_VALVE = 7; 
        VAC_VALVE = 'BNC1'; 
        
        REWARD_LICKS = [4 5 6]; %range of possible rewarded lick to be pseudorandomized per valve (+1 from # of dry licks)
        REWARD_VALVE_DELAY = 0; %delay from lick detection to valve opening
        
        STIM_VOLUME = 10; 
        LOAD_VOLUME = 250; % Should be approximately 5x the dead space of the manifold (current estimate about 70ul)
        RINSE_VOLUME = 1250; % Currently 1250ul or 1.25ml. 
 
        MAXIMUM_TRIALS = 160; 
        MINIMUM_TRIALS = 160; 
        TRIALS_PER_BLOCK = 20; 
        MAX_REPEATS = 4; 

        %CONDITION_CODE = 'WROL'; % WROL = Water Right, Odor Left  
        %SKIPPED_TRIALS_THRESHOLD = 20; % threshold of consecutive trials skipped in a 20 trial block to end early
        %CORRECT_REQUIRED_TO_SWITCH = 2; % only for use with alternation training days 

        % these varaibles are used to make door commands more intuitive and easy to understand & read.
        UP = 0;
        DOWN = 1;
        LEFT_SPOUT = 0;
        RIGHT_SPOUT = 1;

        ITI_TIMER_ID = 1; 
        LICK_WINDOW_TIMER_ID = 2;
        STIM_WINDOW_TIMER_ID = 3; 
        
        itiTimeExpired = 'GlobalTimer1_End';
        lickTimeExpired = 'GlobalTimer2_End';
        stimTimeExpired = 'GlobalTimer3_End';
    end
end
