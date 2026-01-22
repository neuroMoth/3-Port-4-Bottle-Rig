classdef PortHandler
    properties
        port;
        lick_input;
        lick_counter_id;
        lick_counter_event;

        valve;
        valve_time;
    end
    properties (Constant)

    end
    methods
        function obj = setCorrect(obj, port_1_inst, port_3_inst, center_valve, waterValves, odorValves, conditionCode)
            % conditionCode is either WLOR or WROL
            if strcmp(conditionCode, 'WLOR')
                switch center_valve
                    case {waterValves}
                        obj = obj.setProperties(1, port_1_inst); % correct is port 1 (left)
                    case {odorValves}
                        obj = obj.setProperties(3, port_3_inst);
                end
            elseif strcmp(conditionCode, 'WROL')
                switch center_valve
                    case {waterValves}
                        obj = obj.setProperties(3, port_3_inst); % correct is port 3 (right)
                    case {odorValves}
                        obj = obj.setProperties(1, port_1_inst);
                end
            end
        end
        function obj = setIncorrect(obj, port_1_inst, port_3_inst, center_valve, waterValves, odorValves, conditionCode)
            % conditionCode is either WLOR or WROL
            if strcmp(conditionCode, 'WROL')
                switch center_valve
                    case {waterValves}
                        obj = obj.setProperties(1, port_1_inst); % incorrect is port 1 (left)
                    case {odorValves}
                        obj = obj.setProperties(3, port_3_inst);
                end
            elseif strcmp(conditionCode, 'WLOR')
                switch center_valve
                    case {waterValves}
                        obj = obj.setProperties(3, port_3_inst); % incorrect is port 3 (right)
                    case {odorValves}
                        obj = obj.setProperties(1, port_1_inst);
                end
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
            obj.lick_input = port_instance.LICK_INPUT;
            obj.lick_counter_id = port_instance.COUNTER_ID;
            obj.lick_counter_event= port_instance.COUNTER_EVENT;

            obj.valve = port_instance.VALVE;
            time_variable_name = sprintf('open_time_%d', obj.valve);
            obj.valve_time = BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000;
        end
    end
end
