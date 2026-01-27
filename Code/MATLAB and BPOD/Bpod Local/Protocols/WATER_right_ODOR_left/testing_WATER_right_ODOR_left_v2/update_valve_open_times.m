function settings_struct = update_valve_open_times(settings_struct, valve_labels)
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
    valve_labels int
end

for i = 1:length(valve_labels)
    valve = valve_labels(i);

    variable_name =  sprintf('select_amount_valve%d', valve);
    targetAmounts = str2double(settings_struct.GUIMeta.(variable_name).String);

    open_time = sprintf('open_time_%d', valve);
    settings_struct.GUI.(open_time) = (GetValveTimes(targetAmounts(settings_struct.GUI.(variable_name)),valve)) * 1000;
end

end
