% TVD - This class assigns the information from each of the lateral ports to the correct or incorrect port instances

classdef PortHandler
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
            valveSet1 = num2cell(stim1Valves); 
            valveSet2 = num2cell(stim2Valves);
            
            % conditionCode is either WLOR or WROL (Water Left Odor Right or Water Right Odor Left)
            if strcmp(conditionCode, 'WLOR')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(1, port_1_inst); % correct is port 1 (left)
                    case valveSet2
                        obj = obj.setProperties(3, port_3_inst);
                end
            elseif strcmp(conditionCode, 'WROL')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(3, port_3_inst); % correct is port 3 (right)
                    case valveSet2
                        obj = obj.setProperties(1, port_1_inst);
                end
            end
        end
        
        function obj = setIncorrect(obj, port_1_inst, port_3_inst, center_valve, stim1Valves, stim2Valves, conditionCode)
            valveSet1 = num2cell(stim1Valves); 
            valveSet2 = num2cell(stim2Valves);
            
            % conditionCode is either WLOR or WROL
            if strcmp(conditionCode, 'WROL')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(1, port_1_inst); % incorrect is port 1 (left)
                    case valveSet2
                        obj = obj.setProperties(3, port_3_inst);
                end
            elseif strcmp(conditionCode, 'WLOR')
                switch center_valve
                    case valveSet1
                        obj = obj.setProperties(3, port_3_inst); % incorrect is port 3 (right)
                    case valveSet2
                        obj = obj.setProperties(1, port_1_inst);
                end
            end
        end
        
        function obj = switchPort(obj, port_1_inst, port_3_inst)
            % function that takes in the current port on an incorrect_port OR correct_port instance
            % and fills the information with the opposite port
            if (obj.PORT == 1)
                obj = obj.setProperties(3, port_3_inst); % switch to port 3 attributes
            elseif (obj.PORT == 3)
                obj = obj.setProperties(1, port_1_inst); % switch to port 1 attributes
            end
        end
    end

    methods (Access = private)
        function obj = setProperties(obj, port_number, port_instance)
            global BpodSystem
            obj.PORT = port_number;
            
            obj.LICK_ONSET = port_instance.LICK_ONSET;
            obj.LICK_OFFSET = port_instance.LICK_OFFSET;
            obj.COUNTER_ID = port_instance.COUNTER_ID;
            obj.COUNTER_EVENT= port_instance.COUNTER_EVENT;
            obj.DOOR= port_instance.DOOR;

            obj.VALVE = port_instance.VALVE;
            time_variable_name = sprintf('open_time_%d', obj.VALVE);
            obj.VALVE_TIME = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
        end
    end
end
