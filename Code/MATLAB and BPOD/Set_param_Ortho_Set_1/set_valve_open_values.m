function settings_struct = set_valve_open_values(settings_struct, type_durations)
    % set_open_valve_values sets open times for valves based on duration type.
    % 
    % Inputs:
    %   settings_struct - The settings structure containing GUI fields
    %   type_durations  - One of:
    %                       'calibrated' - uses GetValveTimes()
    %                       'default'    - sets all to 30
    %                       'user'       - uses previously manually saved values
    %                       numeric string (e.g., "45") - manual set
    %
    % Output:
    %   settings_struct - Updated structure with open_time fields set
    arguments
    settings_struct struct
    type_durations string
    end

    for i = 1:Set_param_constants.NUM_VALVES
        valve = i;

        open_time = sprintf('open_time_%d', valve);

        switch(type_durations)
            case 'calibrated'
                settings_struct.GUI.(open_time) = GetValveTimes(settings_struct.GUI.select_amount_liquid_ul,i); 
            case 'default'
                settings_struct.GUI.(open_time) = 30; 
            case 'user'
                settings_struct.GUI.(open_time) = BpodSystem.ProtocolSettings.GUI.(open_time);
            otherwise
                val = str2double(type_durations)
                if ~isnan(val)
                    settings_struct.GUI.(open_time) = val; 
                else
                    disp('invalid value, enter a number for manual entry')
                end
        end
    end
end
