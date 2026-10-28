
%% ExperimentVariables (Class)
% This script defines the ExperimentVariables class to hold variables which are constant for the duration of the 
% experimental session. It should only be called once in the main testing_v3 protocol script.  

classdef ExperimentVariables
    properties (Constant)
        %% Side training session stimulus
        SIDE_TRAINING_STIMULUS = 1; % 1 for water, 2 for odor. 
        
        %% Session time variables (in seconds)
        TOTAL_ALLOWED_TIME = 3600;
        ITI_TIME = 12;
        ITI_ENDTIME = 2; % portion of ITI for the end of the trial (subtracted from total ITI_TIME duration)
        PUNISHMENT_TIME = 0; % added to the ITI_TIME after incorrect or skipped trials
        TTC_CENTER_TIME = 30;
        TTC_LATERAL_TIME = 30;
        LICK_WINDOW = 2; % time rat has to complete required amount of licks.
        DELAY_TIME = 3; % delay from closing the center door to opening the lateral door
        GAS_TIME = 0.3; % valve open time for gas clearing
        GAS_DELAY = 0.2; % wait for pressure to stabilize before next valve opening
        
        %% Dry Licks
        DRY_LICKS_PRESTIM = 3; % number of licks to be completed before stimulus delivery (for 3 licks)
        DRY_LICKS_POSTSTIM = 7; % number of licks to be completed after the 3 stimulus deliveries

        %% Volumes
        STIM_VOLUME = 5; % stimulus in ul delivered per lick (3 licks for center, 4 licks for lateral)
        LOAD_VOLUME = 200; % at least 1x dead space of the manifold. Fills the manifold and pushes the first amount to waste.

        %% Valves
        LEFT_VALVE = 1; % left port valve
        RIGHT_VALVE = 8; % right port valve
        CENTER_DRIVER_VALVE = 2; % center port valve for delivering each stimulus
        RINSE_VALVE = 7;
        GAS_VALVE = 'BNC1';

        % Center valves for each stimulus are no longer constants, they are rotated each day. 
        % The valve assignments below are left in case an override is required. 
        % CENTER_VALVE_SET1 = [2, 3]; % Water valves
        % CENTER_VALVE_SET2 = [5, 6]; % Odor valves

        %% Trial structure
        MAXIMUM_TRIALS = 500; % Side training sessions have shorter ITI. Higher possible max trials.  
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
            % get current valve assignments from valve_config.mat
            configFile = fullfile(fileparts(which('valve_config.mat')), 'valve_config.mat');
            if ~isfile(configFile)
                error(['Error: stimulus valve assignments not found (valve_config.mat). ' ...
                    'Check general function setValveStimuli. ']); 
            end
            
            % get valve assignments for stimulus valves
            stimValves = [3, 4, 5, 6]; 
            % convert to logical
            stimValves_logical = false(1,8); 
            stimValves_logical(stimValves) = true; 
            
            % get stim assignments (1 = water, 2 = odor)
            valveConfigStruct = load(configFile);
            stimAssignments = valveConfigStruct.config.valve_slots(stimValves_logical); 
            
            obj.CENTER_VALVE_SET1 = stimValves(stimAssignments == 1);
            obj.CENTER_VALVE_SET2 = stimValves(stimAssignments == 2);
        end
    end
end
