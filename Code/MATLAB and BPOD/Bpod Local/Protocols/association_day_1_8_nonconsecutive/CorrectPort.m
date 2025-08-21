classdef CorrectPort
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
        function [obj, center_port_inst] = setCorrect(obj, port_1_inst, center_port_inst, port_3_inst, center_valve)
            global BpodSystem

            switch center_valve
                case {2, 3, 4}
                    obj.port = 1;
                    obj.lick_event = port_1_inst.LICK_INPUT;
                    obj.lick_counter_id = port_1_inst.COUNTER_ID;
                    obj.lick_counter_event= port_1_inst.COUNTER_EVENT;

                    obj.valve = port_1_inst.VALVE;
                    time_variable_name = sprintf('open_time_%d', obj.valve);
                    obj.valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
                case {5, 6, 7}
                    obj.port = 3;
                    obj.lick_event = port_3_inst.LICK_INPUT;
                    obj.lick_counter_id = port_3_inst.COUNTER_ID;
                    obj.lick_counter_event= port_3_inst.COUNTER_EVENT;

                    obj.valve = port_3_inst.VALVE;
                    time_variable_name = sprintf('open_time_%d', obj.valve);
                    obj.valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
            end
        end
        function [obj, center_port_inst] = switchCorrect(obj, port_1_inst, center_port_inst, port_3_inst) 
            global BpodSystem
            if (obj.port == 1)
                % switch correct to 3 (ODOR center)
                obj.port = 3;
                obj.lick_event = port_3_inst.LICK_INPUT;
                obj.lick_counter_id = port_3_inst.COUNTER_ID;
                obj.lick_counter_event= port_3_inst.COUNTER_EVENT;

                obj.valve = port_3_inst.VALVE;
                time_variable_name = sprintf('open_time_%d', obj.valve);
                obj.valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;

                % odor is associated with the reward on the right (port 3)
                center_port_inst = center_port_inst.setValve(1, center_port_inst.ODOR_VALVE);
            elseif (obj.port == 3)
                obj.port = 1;
                % switch correct to 1 (WATER center)
                obj.lick_event = port_1_inst.LICK_INPUT;
                obj.lick_counter_id = port_1_inst.COUNTER_ID;
                obj.lick_counter_event= port_1_inst.COUNTER_EVENT;

                obj.valve = port_1_inst.VALVE;
                time_variable_name = sprintf('open_time_%d', obj.valve);
                obj.valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;

                % water is associated with the reward on the left (port 1)
                center_port_inst = center_port_inst.setValve(1, center_port_inst.WATER_VALVE);
            end
        end
    end
end
