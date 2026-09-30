% TVD 8/27/26 
% This class exists to replace the separate LateralPort and CenterPort classes by combining their functions. 
% It holds and sets the information for each port. Each port needs an instance declared at the start of the session. 

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
        function obj = Port(portNumber, valve_number, valve_timing) % Declare each port and assign appropriate events and commands

            obj.PORT = portNumber;
            obj.VALVE = valve_number;
            obj.VALVE_TIME = valve_timing;

            % Assigning event and command labels
            if (portNumber == 1) % LEFT LATERAL PORT
                obj.LICK_ONSET = 'AnalogIn1_1';
                obj.LICK_OFFSET = 'AnalogIn1_9';
                obj.DOOR = 'Flex1DO';
                
                obj.COUNTER_ID = 1;
                obj.COUNTER_EVENT = 'GlobalCounter1_End';
            elseif (portNumber == 2) % CENTER PORT
                obj.LICK_ONSET = 'AnalogIn1_2';
                obj.LICK_OFFSET = 'AnalogIn1_10';
                obj.DOOR = 'Flex2DO';

                obj.COUNTER_ID = 2;
                obj.COUNTER_EVENT = 'GlobalCounter2_End';
            elseif (portNumber == 3) % RIGHT LATERAL PORT
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
