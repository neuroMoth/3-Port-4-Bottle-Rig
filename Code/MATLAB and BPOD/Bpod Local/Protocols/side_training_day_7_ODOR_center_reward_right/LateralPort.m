classdef LateralPort
        properties
            % int variables
            COUNTER_ID;
            VALVE;
            VALVE_TIME;
            DOOR;
            
            % string variables 
            LICK_INPUT;
            COUNTER_EVENT;
        end
        methods 
            function obj = LateralPort(side)
                global BpodSystem

                if (side == 1)
                    obj.COUNTER_ID = 3;
                    obj.VALVE = 1;

                    obj.LICK_INPUT = 'AnalogIn1_3';
                    obj.DOOR = 'Flex1DO';
                    obj.COUNTER_EVENT = 'GlobalCounter3_End';

                    obj.VALVE_TIME = BpodSystem.ProtocolSettings.GUI.open_time_1/1000;

                elseif (side == 3)
                    obj.COUNTER_ID = 4;
                    obj.VALVE = 8;

                    obj.LICK_INPUT = 'AnalogIn1_4';
                    obj.COUNTER_EVENT = 'GlobalCounter4_End';
                    obj.DOOR = 'Flex3DO';

                    obj.VALVE_TIME = BpodSystem.ProtocolSettings.GUI.open_time_8/1000;

                else
                end
            end
        end 
end
