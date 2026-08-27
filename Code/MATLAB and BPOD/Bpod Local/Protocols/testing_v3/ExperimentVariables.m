classdef ExperimentVariables 
    properties (Constant)
        % All time parameters (in seconds)
        TOTAL_ALLOWED_TIME = 4200;
        ITI_TIME = 15; 
        ITI_ENDTIME = 2; % portion of ITI for the end of the trial (subtracted from whole ITI duration)
        PUNISHMENT_TIME = 10; 
        TTC_CENTER_TIME = 5; 
        TTC_LATERAL_TIME = 5; 
        LICK_WINDOW = 2; % time rat has to complete required amount of licks.
        DELAY_TIME = 3; % delay from closing the center door to opening the lateral door
        STIMULUS_WINDOW = 0.05; % pause after final valve closes before door goes up (if still within LICK_WINDOW)
        GAS_TIME = 0.5; % time for gas purge
        GAS_DELAY = 0.1; % wait for pressure to stabilize before next valve opening
        PRIMING_DELAY = 1; % priming slug sits stagnant before final gas clearing and stimulus loading

        LEFT_VALVE = 1; % left port valve
        RIGHT_VALVE = 8; % right port valve
        CENTER_VALVE_SET1 = [2, 3]; % Water valves
        CENTER_VALVE_SET2 = [5, 6]; % Odor valves
        RINSE_VALVE = 7; 
        GAS_VALVE = 'BNC1'; 
        
        REWARD_LICKS = [4 5 6]; %range of possible rewarded lick to be pseudorandomized per valve (+1 from # of dry licks)
        REWARD_VALVE_DELAY = 0; %delay from lick detection to valve opening
        
        STIM_VOLUME = 10; 
        PRIMING_VOLUME = 50; % 0.5x dead space of the manifold (current estimate about 100ul). For "seasoning" step. 
        LOAD_VOLUME = 250; % 2.5x dead space of the manifold. Fills the manifold and pushes the first amount to waste. 
        RINSE_VOLUME = 500; % 500ul (0.5ml) for each rinse round (2 rounds with gas clearing in between). 
 
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

        ITI_TIMER_ID = 1; 
        LICK_WINDOW_TIMER_ID = 2;
        
        ITI_TIMER_END = 'GlobalTimer1_End';
        LICK_WINDOW_TIMER_END = 'GlobalTimer2_End';
    end
end
