    classdef CenterPort
        properties 
            left_valve; % the valve in the center is not a constant. 
            left_valve_time; % the delay time for this valve 

            right_valve; % the valve in the center is not a constant. 
            right_valve_time; % the delay time for this valve 
        end
        properties (Constant)
            LEFT_COUNTER_ID = 1;
            RIGHT_COUNTER_ID = 2;

            LEFT_LICK_INPUT = 'AnalogIn1_1';
            RIGHT_LICK_INPUT = 'AnalogIn1_2'; % input for the second spout in the center port.
            DOOR = 'Flex2DO';
            ACTIVE_SPOUT = 'Flex4DO';

            LEFT_COUNTER_EVENT = 'GlobalCounter1_End';
            RIGHT_COUNTER_EVENT = 'GlobalCounter2_End';

            WATER_VALVE = 2;
            ODOR_VALVE = 5;
        end 
        methods
            function obj = setValve(obj, port, valve_number)
                global BpodSystem

                time_variable_name = sprintf('open_time_%d', valve_number);
                switch port
                    case 1
                        obj.left_valve = valve_number; 

                        obj.left_valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
                    case 2
                        obj.right_valve = valve_number;

                        obj.right_valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
                end
            end
            function obj = switchLeftValve(obj)
                switch (obj.left_valve)
                    case 2
                        obj.left_valve = 5;
                    case 5 
                        obj.left_valve = 2;
                end
            end
        end
    end
