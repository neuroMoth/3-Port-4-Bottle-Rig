classdef PortHandler
    properties 
        port;
        lick_event;
        lick_counter_id;
        lick_counter_event;
        
        valve;
        valve_time;
    end
    properties (Constant)

    end
    methods
        function obj = setCorrect(obj, port_1_inst, port_3_inst, center_valve)
            switch center_valve
                case {2, 3, 4}
                    obj = obj.setProperties(3, port_3_inst);
                case {5, 6, 7}
                    obj = obj.setProperties(1, port_1_inst); % correct is port 1
            end
        end
        function obj = setIncorrect(obj, port_1_inst, port_3_inst, center_valve)
            switch center_valve
                % if correct is 1, incorrect is the opposite
                case {2, 3, 4} % water valves incorrect port 
                    obj = obj.setProperties(1, port_1_inst);
                case {5, 6, 7} % odor valves incorrect port 
                    obj = obj.setProperties(3, port_3_inst);
            end
        end
        function obj = switchPort(obj, port_1_inst, port_3_inst) 
            % function that takes in the current port on an incorrect_port OR correct_port instance
            % and fills the information with the opposite port
            if (obj.port == 1)
                obj = obj.setProperties(3, port_3_inst); % switch to port 3 attributes
            elseif (obj.port == 3)
                obj = obj.setProperties(1, port_1_inst); % switch to port 1 attributes
            end
        end
    end

    methods (Access = private) 
        function obj = setProperties(obj, port_number, port_instance)
            global BpodSystem
                obj.port = port_number;
                % switch correct to 1 (WATER center)
                obj.lick_event = port_instance.LICK_INPUT;
                obj.lick_counter_id = port_instance.COUNTER_ID;
                obj.lick_counter_event= port_instance.COUNTER_EVENT;

                obj.valve = port_instance.VALVE;
                time_variable_name = sprintf('open_time_%d', obj.valve);
                obj.valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
        end
    end
end
