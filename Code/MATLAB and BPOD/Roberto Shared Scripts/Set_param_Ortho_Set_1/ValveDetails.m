classdef ValveDetails
    properties
        label 
        desired_liquid_amount
        opening_time
    end

    methods 
        function obj = ValveDetails(number, desired_liquid, open_time)
            obj.label = number;
            desired_liquid_amount = desired_liquid;
            opening_time = open_time;
        end
    end
end
