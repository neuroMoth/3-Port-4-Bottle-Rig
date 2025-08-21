classdef IncorrectPort
    properties
        port;
        lick_event;
        lick_counter_id;
        lick_counter_event;
    end
    properties (Constant)

    end
    methods
        function [obj, center_port_inst] = setIncorrect(obj, port_1_inst, center_port_inst, port_3_inst, center_valve)
            switch center_valve
                % if correct is 1, incorrect is the opposite
                case {2, 3, 4} % water valves correct port -> LEFT (PORT 1) | incorrect -> RIGHT (PORT 3)
                    obj.port = 3;
                    obj.lick_event = port_3_inst.LICK_INPUT;
                    obj.lick_counter_id = port_3_inst.COUNTER_ID;
                    obj.lick_counter_event= port_3_inst.COUNTER_EVENT;
                case {5, 6, 7} % odor valves correct port -> RIGHT (PORT 3) | incorrect -> LEFT (PORT 1)
                    obj.port = 3;
                    obj.lick_event = port_1_inst.LICK_INPUT;
                    obj.lick_counter_id = port_1_inst.COUNTER_ID;
                    obj.lick_counter_event= port_1_inst.COUNTER_EVENT;
            end
        end
        function obj = switchIncorrect(obj, port_1_inst, port_3_inst) 
            if (obj.port == 1)
                % switch incorrect to 3 (WATER center)
                obj.port = 3;
                obj.lick_event = port_3_inst.LICK_INPUT;
                obj.lick_counter_id = port_3_inst.COUNTER_ID;
                obj.lick_counter_event= port_3_inst.COUNTER_EVENT;
            elseif (obj.port == 3)
                % switch incorrect to 1 (ODOR center)
                obj.lick_event = port_1_inst.LICK_INPUT;
                obj.lick_counter_id = port_1_inst.COUNTER_ID;
                obj.lick_counter_event= port_1_inst.COUNTER_EVENT;
            end
        end
    end
end
