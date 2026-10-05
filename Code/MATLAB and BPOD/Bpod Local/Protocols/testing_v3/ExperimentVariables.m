
%% ExperimentVariables (Class)
% This script defines the ExperimentVariables class to hold variables which are constant for the duration of the 
% experimental session. It should only be called once in the main testing_v3 protocol script.  

classdef ExperimentVariables
    properties (Constant)
        %% Session time variables (in seconds)
        TOTAL_ALLOWED_TIME = 3600;
        ITI_TIME = 15;
        ITI_ENDTIME = 2; % portion of ITI for the end of the trial (subtracted from total ITI_TIME duration)
        PUNISHMENT_TIME = 15; % added to the ITI_TIME after incorrect or skipped trials
        TTC_CENTER_TIME = 5;
        TTC_LATERAL_TIME = 5;
        LICK_WINDOW = 2; % time rat has to complete required amount of licks.
        DELAY_TIME = 3; % delay from closing the center door to opening the lateral door
        STIMULUS_WINDOW = 0.1; % pause after final valve closes before door goes up (if still within LICK_WINDOW)
        GAS_TIME = 0.3; % valve open time for gas clearing
        GAS_DELAY = 0.2; % wait for pressure to stabilize before next valve opening
        PRIMING_DELAY = 0.5; % priming slug sits stagnant before final gas clearing and stimulus loading

        %% Volumes
        STIM_VOLUME = 5; % stimulus in ul delivered per lick (3 licks for center, 4 licks for lateral)
        PRIMING_VOLUME = 100; % 1x dead space of the manifold (current estimate about 100ul). For "seasoning" step.
        LOAD_VOLUME = 200; % 2x dead space of the manifold. Fills the manifold and pushes the first amount to waste.
        RINSE_VOLUME = 600; % 600ul (0.6ml) for each rinse round (2 rounds with gas clearing in between).

        %% Valves
        LEFT_VALVE = 1; % left port valve
        RIGHT_VALVE = 8; % right port valve
        CENTER_DRIVER_VALVE = 4; % center port valve for delivering each stimulus
        RINSE_VALVE = 7;
        GAS_VALVE = 'BNC1';

        % Center valves for each stimulus are no longer constants, they are rotated each day. 
        % The valve assignments below are left in case an override is required. 
        % CENTER_VALVE_SET1 = [2, 3]; % Water valves
        % CENTER_VALVE_SET2 = [5, 6]; % Odor valves

        %% Trial structure
        MAXIMUM_TRIALS = 200;
        MAX_REPEATS = 4; % This only applies to repeats across blocks. Within blocks, the max is 3 repeats.

        %CORRECT_REQUIRED_TO_SWITCH = 2; % only for use with alternation training days

        %% Variables just to make door commands more intuitive and easy to understand & read.
        UP = 0;
        DOWN = 1;

        ITI_TIMER_ID = 1;
        LICK_WINDOW_TIMER_ID = 2;

        ITI_TIMER_END = 'GlobalTimer1_End';
        LICK_WINDOW_TIMER_END = 'GlobalTimer2_End';
    end

    properties
        CENTER_VALVE_SET1; % Water valves
        CENTER_VALVE_SET2; % Odor valves
    end

    methods 
        function obj = ExperimentVariables
            % Calls general function currentDayConditions to get the current valve assignments
            [waterValves, odorValves] = currentDayConditions; 
            
            obj.CENTER_VALVE_SET1 = waterValves;
            obj.CENTER_VALVE_SET2 = odorValves;
        end
    end
end
