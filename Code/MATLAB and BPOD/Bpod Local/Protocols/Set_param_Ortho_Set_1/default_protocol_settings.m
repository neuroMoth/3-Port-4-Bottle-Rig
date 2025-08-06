function protocol_settings = default_protocol_settings(protocol_settings, valves)
    % Function that intakes a BpodSystem ProtocolSettings object and returns 
    % the object with default settings for the protocol.
    

    valve_labels = {'1','2','3','4','5', '6', '7', '8'};
    liquid_amount_options = {'1','1.5','2','2.5','3','3.5','4','4.5','5','5.5','6','6.5','7','7.5','8','8.5'};

    default_liquid_index = find(cellfun(@(x) strcmp(x,'5'), liquid_amount_options));

    protocol_settings = create_popup_menu(protocol_settings, "select_taste_valve", 1, valve_labels);

    protocol_settings = create_popup_menu(protocol_settings, "select_amount_liquid_ul", 9, liquid_amount_options);

    calibration_or_manual_values = {'Use Calibration Values', 'Manually Set Opening Times'};
    protocol_settings = create_popup_menu(protocol_settings, "calibration_or_clean", 1, calibration_or_manual_values);

    % create variables threshold_licks and num_trials and make them user editable fields
    protocol_settings.GUI.threshold_licks = 7;
    protocol_settings.GUIMeta.threshold_licks.Style = 'edit'; 

    protocol_settings.GUI.num_trials = 210;
    protocol_settings.GUIMeta.num_trials.Style = 'edit'; 

    if protocol_settings.GUI.calibration_or_clean == 1
        % if S.GUI.calibration_or_clean popup has the first option selected (use calibration values) then go find those 
        % for each valve 
        protocol_settings = set_valve_open_values(protocol_settings, valves, 'calibrated');   
    else
        % otherwise use a default of 30 and allow user to change to whatever value they want
        protocol_settings = set_valve_open_values(protocol_settings, valves, 'default');   
    end

    % clear residual panel information, then create the panel again by giving variable names of gui entities to 
    % S.GUIPanels.valve_open_times_ms
    protocol_settings.GUIPanels.valve_open_times_ms={};
    for i = 1:Set_param_constants.NUM_VALVES
        open_time_string = sprintf('open_time_%d', i);
        protocol_settings.GUIPanels.valve_open_times_ms{end + 1} = open_time_string;
    end

    %%% BEGIN CREATE MANUAL TEST VALVES BUTTON PANEL %%% 
    protocol_settings.GUIPanels.Manual_Taste_Valves = {};
    for i = 1:Set_param_constants.NUM_VALVES
        valve_number = i;

        valve_name = sprintf('Valve_%d', valve_number);

        opening_time_field = sprintf('open_time_%d', valve_number);

        protocol_settings.GUI.(valve_name) = sprintf('Manual_Open_Valve(1,%d,BpodSystem.ProtocolSettings.GUI.%s)', valve_number, opening_time_field);
        protocol_settings.GUIMeta.(valve_name).Style = 'pushbutton';

        protocol_settings.GUIPanels.Manual_Taste_Valves{end + 1} = valve_name;

    end


    %%% END CREATE MANUAL TEST VALVES BUTTON PANEL %%% 

    %% Control the 7 odor lines - Line 12 must be empty


    %%% BEGIN PANEL %%% 
    stimulus_options = {'empty', 'stimulus_1', 'stimulus_2', 'stimulus_3', 'stimulus_4', 'stimulus_5',...
        'stimulus_6', 'stimulus_7', 'stimulus_8', 'stimulus_9', 'stimulus_10', 'stimulus_11', 'stimulus_12',...
        'stimulus_13', 'stimulus_14', 'stimulus_15', 'stimulus_16', 'stimulus_17', 'stimulus_18', 'stimulus_19',...
        'stimulus_20', 'stimulus_21'};


protocol_settings.GUIPanels.Current_valve_assignments = {};
for i = 1:Set_param_constants.NUM_VALVES
    line = i;

    variable_name =  sprintf('valve_line_%d', line);
    protocol_settings = create_popup_menu(protocol_settings, variable_name, 21, stimulus_options);

    protocol_settings.GUIPanels.Current_valve_assignments{end + 1} = variable_name;
end
%%% END PANEL %%% 

%% unsure of what this does at this time
odor_set_options = {'first set of 7 odors','second set of 7 odors','third set of 7 odors'};
protocol_settings = create_popup_menu(protocol_settings, 'odor_set', 3, odor_set_options);
%% unsure of what this does at this time


%% Setup for text panel displaying odor selections 
protocol_settings.GUIPanels.stimuli_ID = {};
for i = 1:Set_param_constants.NUM_VALVES
    stimulus_id= i;

    variable_name = sprintf('stimulus_ID_%d', stimulus_id);
    valve_line_value = sprintf("valve_line_%d", stimulus_id);

    stimulus_name = protocol_settings.GUI.(valve_line_value);

    protocol_settings.GUIMeta.(variable_name).Style = 'text';
    protocol_settings.GUI.(variable_name) = protocol_settings.GUIMeta.(valve_line_value).String{stimulus_name};

    protocol_settings.GUIPanels.stimuli_ID{end + 1} = variable_name;
end

end

function settings_struct = create_popup_menu(settings_struct, fieldname, default_value, options)
    %function used to create a popup menu in the GUI. Takes current Bpod ProtocolSettings object and 
    % returns a new one with a new popup menu with the user supplied fieldname (new field variable name),
    % default value, and options (available items to select from).
    arguments
    settings_struct struct
    fieldname string
    default_value (1,1) double {mustBeInteger, mustBePositive}
    options cell % accept any type, but must be cell array of char vectors
end
settings_struct.GUI.(fieldname)= default_value; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
settings_struct.GUIMeta.(fieldname).Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
settings_struct.GUIMeta.(fieldname).String = options;
end
