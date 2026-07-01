function settings_struct = update_valve_open_times(settings_struct, valve_labels, target_amount)
% set_open_valve_values sets open times for valves based on duration type.
%
% Inputs:
%   settings_struct - The settings structure containing GUI fields
%   valve_labels - array of valve numbers being updated
%
% Output:
%   settings_struct - Updated structure with open_time fields set

arguments
    settings_struct struct
    valve_labels double
    target_amount double = 0
end

for i = 1:length(valve_labels)
    valve = valve_labels(i);

    variable_name =  sprintf('select_amount_valve%d', valve);
    open_time = sprintf('open_time_%d', valve);

    if target_amount == 0
        targetAmounts = str2double(settings_struct.GUIMeta.(variable_name).String);
        settings_struct.GUI.(open_time) = (GetValveTimes(targetAmounts(settings_struct.GUI.(variable_name)),valve)) * 1000;
    else; settings_struct.GUI.(open_time) = (GetValveTimes(target_amount,valve)) * 1000;
    end
    
end

end
