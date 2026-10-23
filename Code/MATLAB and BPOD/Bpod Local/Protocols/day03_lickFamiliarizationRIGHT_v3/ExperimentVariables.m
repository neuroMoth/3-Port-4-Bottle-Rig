
%% ExperimentVariables (Class)
% This script defines the ExperimentVariables class to hold variables which are constant for the duration of the 
% experimental session. It should only be called once in the main protocol script.  

classdef ExperimentVariables
    properties (Constant)
        %% Lick familiarization port
        CURRENT_PORT = 3; % port 3 is the right port
        
        %% Session time variables (in seconds)
        TOTAL_ALLOWED_TIME = 1800;

        %% Volumes
        STIM_VOLUME = 5; % stimulus in ul delivered per lick (3 licks for center, 4 licks for lateral)

        %% Valves
        LEFT_VALVE = 1; % left port valve
        RIGHT_VALVE = 8; % right port valve
        CENTER_DRIVER_VALVE = 2; % center port valve for delivering each stimulus

        %% Variables just to make door commands more intuitive and easy to understand & read.
        UP = 0;
        DOWN = 1;

        SESSION_TIMER_ID = 1;

        SESSION_TIME_END = 'GlobalTimer1_End';
    end
end
