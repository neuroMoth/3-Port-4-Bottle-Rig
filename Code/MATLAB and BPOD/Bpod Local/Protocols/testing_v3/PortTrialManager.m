
%% PortTrialManager (Class)
% This script defines the PortTrialManager class to assign and hold the properties (e.g. event and command names) of the
% correct and incorrect ports for each trial. This is determined using the valves assigned to each stimulus and the
% condition code for the current animal subject (WLOR or WROL). 

classdef PortTrialManager
    properties
        PORT; % port number (1 = LEFT, 3 = RIGHT)
        
        VALVE; % valve assigned to the port (for the center port (port 2) this is changed every trial
        VALVE_TIME; % changed to match the current assigned valve

        LICK_ONSET; % event for lick onset detection
        LICK_OFFSET; % event for lick offset detection
        DOOR; % output command for controlling door motors
        
        COUNTER_ID; % id for global counter which counts the number of dry licks
        COUNTER_EVENT; % event that triggers when the counter threshold is reached
    end

    methods
        function obj = setCorrect(obj, port_1_inst, port_3_inst, center_valve, stim1Valves, stim2Valves, conditionCode)
            if port_1_inst.PORT ~= 1 || port_3_inst.PORT ~= 3; error('Port instances are incompatible. '); end
            
            valveSet1 = num2cell(stim1Valves); 
            valveSet2 = num2cell(stim2Valves);
            
            % conditionCode is either WLOR or WROL (Water Left Odor Right or Water Right Odor Left)
            if strcmp(conditionCode, 'WLOR')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(port_1_inst); % correct is port 1 (left)
                    case valveSet2
                        obj = obj.setProperties(port_3_inst);
                end
            elseif strcmp(conditionCode, 'WROL')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(port_3_inst); % correct is port 3 (right)
                    case valveSet2
                        obj = obj.setProperties(port_1_inst);
                end
            end
        end
        
        function obj = setIncorrect(obj, port_1_inst, port_3_inst, center_valve, stim1Valves, stim2Valves, conditionCode)
            if port_1_inst.PORT ~= 1 || port_3_inst.PORT ~= 3; error('Port instances are incompatible. '); end
            
            valveSet1 = num2cell(stim1Valves); 
            valveSet2 = num2cell(stim2Valves);
            
            % conditionCode is either WLOR or WROL
            if strcmp(conditionCode, 'WROL')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(port_1_inst); % incorrect is port 1 (left)
                    case valveSet2
                        obj = obj.setProperties(port_3_inst);
                end
            elseif strcmp(conditionCode, 'WLOR')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(port_3_inst); % incorrect is port 3 (right)
                    case valveSet2
                        obj = obj.setProperties(port_1_inst);
                end
            end
        end
        
        function obj = switchPort(obj, port_1_inst, port_3_inst)
            % function that takes in the current port on an incorrect_port OR correct_port instance
            % and fills the information with the opposite port
            
            if port_1_inst.PORT ~= 1 || port_3_inst.PORT ~= 3; error('Port instances are incompatible. '); end
            
            if (obj.PORT == 1)
                obj = obj.setProperties(port_3_inst); % switch to port 3 attributes
            elseif (obj.PORT == 3)
                obj = obj.setProperties(port_1_inst); % switch to port 1 attributes
            end
        end
    end

    methods (Access = private)
        function obj = setProperties(obj, port_instance)
            obj.PORT = port_instance.PORT;
            
            obj.LICK_ONSET = port_instance.LICK_ONSET;
            obj.LICK_OFFSET = port_instance.LICK_OFFSET;
            obj.COUNTER_ID = port_instance.COUNTER_ID;
            obj.COUNTER_EVENT= port_instance.COUNTER_EVENT;
            obj.DOOR= port_instance.DOOR;

            obj.VALVE = port_instance.VALVE;
            obj.VALVE_TIME = port_instance.VALVE_TIME;
        end
    end
end
