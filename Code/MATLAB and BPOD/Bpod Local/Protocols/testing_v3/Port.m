
%% Port (Class)
% This script defines the Port class to hold properties (e.g. event and command names) for each of the three ports 
% in the behavior rig. These properties do not change for the duration of the session. 
% 
% Each port needs an instance declared at the start of the session. This is done using the following format: 
%   portName = Port(port_number, valve_number, valve_timing); 
% Where port_number is either 1 (LEFT), 2 (CENTER), or 3 (RIGHT). 
% 
% TVD Note: This class exists to replace the separate LateralPort and CenterPort classes by combining their functions. 

classdef Port
    properties
        PORT; % port number (1 = LEFT, 2 = CENTER, 3 = RIGHT)
        
        VALVE; % valve assigned to the port (for the center port (port 2) this is changed every trial
        VALVE_TIME; % changed to match the current assigned valve

        LICK_ONSET; % event for lick onset detection
        LICK_OFFSET; % event for lick offset detection
        DOOR; % output command for controlling door motors
        
        COUNTER_ID; % id for global counter which counts the number of dry licks
        COUNTER_EVENT; % event that triggers when the counter threshold is reached
    end
    
    methods 
        function obj = Port(port_number, valve_number, valve_timing) % Declare each port and assign appropriate events and commands

            obj.PORT = port_number;
            obj.VALVE = valve_number;
            obj.VALVE_TIME = valve_timing;

            % Assigning event and command labels
            if (port_number == 1) % LEFT LATERAL PORT
                obj.LICK_ONSET = 'AnalogIn1_1';
                obj.LICK_OFFSET = 'AnalogIn1_9';
                obj.DOOR = 'Flex1DO';
                
                obj.COUNTER_ID = 1;
                obj.COUNTER_EVENT = 'GlobalCounter1_End';
            elseif (port_number == 2) % CENTER PORT
                obj.LICK_ONSET = 'AnalogIn1_2';
                obj.LICK_OFFSET = 'AnalogIn1_10';
                obj.DOOR = 'Flex2DO';

                obj.COUNTER_ID = 2;
                obj.COUNTER_EVENT = 'GlobalCounter2_End';
            elseif (port_number == 3) % RIGHT LATERAL PORT
                obj.LICK_ONSET = 'AnalogIn1_3';
                obj.LICK_OFFSET = 'AnalogIn1_11';
                obj.DOOR = 'Flex3DO';
                
                obj.COUNTER_ID = 3;
                obj.COUNTER_EVENT = 'GlobalCounter3_End';
            else
                error('Error: port number is not compatible with this protocol. '); 
            end
        end
    end
end
