%% Code written by Roberto Vincis, FSU ---- Edited for Samuelsen Lab by Blake Hourigan 7/17/25
% This code is called from the BPod Console to setup the parameters for 3 port ... experiment


% get the filename of the default settings so we can delete it and avoid
% using cached file instead of the one we are making now 
f = fullfile('C:\','Users','Chad Samuelsen','Documents','Github','Bpod Local','Data','FakeSubject','Set_param_Ortho_Set_1','Session Settings', 'DefaultSettings.mat');

if exist(f, 'file')
    delete(f);
end

global BpodSystem

function start_scope(analog_object)
% function to start the oscilliscope
    analog_object.scope; % Launch Scope GUI
    analog_object.scope_StartStop % Start USB streaming + data logging
end

function shutdown_protocol(analog_input)
% function used to shutdown open processes before terminating the protocol after the user hits the stop button.
% this is important to avoid closing the software without releasing the ports in use to be used again.
    analog_input.scope_StartStop; % Stop Oscope GUI
    analog_input.endAcq; % Close Oscope GUI
    analog_input.stopReportingEvents; % Stop sending events to state machine
    clear analog_input;
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

        open_time = sprintf("op_%d", valve);

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


%% Session Setup
% Assert Analog Input module is present + USB-paired (via USB button on console GUI)
BpodSystem.assertModule('AnalogIn', 1); % The second argument (1) indicates that AnalogIn must be paired with its USB serial port


% Setup analog input module
A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1); % Create an instance of the Analog Input module
A.nActiveChannels = 1; % Record from up to 2 channels

A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
%A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V

A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
A.startReportingEvents; % Enable threshold event signaling

%behaviorDataFile = BpodSystem.Path.CurrentDataFile;
%A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
start_scope(A);
%--- Define parameters and trial structure


S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'

if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    taste_valves = {'1','2','3','4','5', '6', '7', '8'};
    S = create_popup_menu(S, "select_taste_valve", 1, taste_valves);

    liquid_amount_options = {'1','1.5','2','2.5','3','3.5','4','4.5','5','5.5','6','6.5','7','7.5','8','8.5'};
    S = create_popup_menu(S, "select_amount_liquid_ul", 9, liquid_amount_options);

    calibration_or_manual_values = {'Use Calibration Values', 'Manually Set Opening Times'};
    S = create_popup_menu(S, "calibration_or_clean", 1, calibration_or_manual_values);

    % create variables threshold_licks and num_trials and make them user editable fields
    S.GUI.threshold_licks = 7;
    S.GUIMeta.threshold_licks.Style = 'edit'; 

    S.GUI.num_trials = 210;
    S.GUIMeta.num_trials.Style = 'edit'; 

    if S.GUI.calibration_or_clean == 1
        % if S.GUI.calibration_or_clean popup has the first option selected (use calibration values) then go find those 
        % for each valve 
        S = set_valve_open_values(S, 'calibrated');   
    else
        % otherwise use a default of 30 and allow user to change to whatever value they want
        S = set_valve_open_values(S, 'default');   
    end

    S.GUIPanels.OpenTimes_Taste_Valves_milliseconds = {'op_1', 'op_2', 'op_3','op_4','op_5','op_6','op_7','op_8'};

    %%% BEGIN CREATE MANUAL TEST VALVES BUTTON PANEL %%% 
    for i = 1:8
        valve_number = i;

        valve_name = sprintf("Valve_%d", valve_number);

        opening_time_field = sprintf("op_%d", valve_number);

        S.GUI.(valve_name) = sprintf('Manual_Open_Valve(1,%d,BpodSystem.ProtocolSettings.(%s))', valve_number, opening_time_field);
        S.GUIMeta.(valve_name).Style = 'pushbutton';

    end

    S.GUIPanels.Manual_Taste_Valves = {'Valve_1', 'Valve_2', 'Valve_3','Valve_4','Valve_5', 'Valve_6', 'Valve_7', 'Valve_8'};

    %%% END CREATE MANUAL TEST VALVES BUTTON PANEL %%% 

    %% Control the 7 odor lines - Line 12 must be empty


    %%% BEGIN PANEL %%% 
    odor_options = {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
        'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
        'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
        'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};

for i = 5:12
    line = i;

    variable_name =  sprintf("odor_line_%d", line);
    S = create_popup_menu(S, variable_name, 21, odor_options);
end
S.GUIPanels.Current_Odor_List = {'odor_line_5','odor_line_6','odor_line_7','odor_line_8','odor_line_9',...
    'odor_line_10','odor_line_11','odor_line_12',};
    %%% END PANEL %%% 

    %% unsure of what this does at this time
    odor_set_options = {'first set of 7 odors','second set of 7 odors','third set of 7 odors'};
    S = create_popup_menu(S, 'odor_set', 3, odor_set_options);
    %% unsure of what this does at this time


    %% Setup for text panel displaying odor selections 

    for i = 5:12 
        odor_id = i;

        variable_name = sprintf("odor_ID_%d", odor_id);
        odor_line_value = sprintf("odor_line_%d", odor_id);

        S.GUIMeta.(variable_name).Style = 'text';
        S.GUI.(variable_name) = S.GUIMeta.(odor_line_value).String{S.GUI.(odor_line_value)};


    end

    S.GUIPanels.Current_Odor_ID = {'odor_ID_5','odor_ID_6','odor_ID_7','odor_ID_8','odor_ID_9',...
        'odor_ID_10','odor_ID_11','odor_ID_12'};

BpodSystem.ProtocolSettings = S;
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S); % initialize GUI to keep track of parameters


%% this is just a state machine that will last 10 minutes to allow for checking parameter of the experiments
for i = 1:Set_param_constants.NUM_SECONDS

    S = BpodParameterGUI('sync', S); 

    sma = NewStateMachine();

    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer',1,...
        'StateChangeConditions', {'Tup', '>exit'},...
        'OutputActions', {}); 

    % Send description to the Bpod State Machine device
    SendStateMachine(sma);

    % Run the trial
    RawEvents = RunStateMachine;

    if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial

        for i =  5:12
            % dynamically gets the number of the odor based on i.
            id = i;
            odor_line_number = sprintf('odor_line_%d', id);

            odor_id_field = sprintf('odor_ID_%d', id);

            % fill in dynamically generated variable name to get the value
            S.GUI.(odor_id_field) = S.GUIMeta.(odor_line_number).String{S.GUI.(odor_line_number)};
        end

        if S.GUI.calibration_or_clean == 1
            S = set_valve_open_values(S, 'calibrated');   
        else
            S = set_valve_open_values(S, 'user');   
        end


        % sync parameters to gui inputs
        S = BpodParameterGUI('sync', S);

        S.OdorSequence = gen_odor_sequence(BpodSystem);

        BpodSystem.ProtocolSettings = S;

        SaveProtocolSettings(BpodSystem.ProtocolSettings)
        disp(['Setting data are continously saved! You still have ' num2str((Set_param_constants.NUM_SECONDS-i)/Set_param_constants.MINUTES_PER_HOUR) 'minutes to finish setting the parameters']);
    end
    % Exit the session if the user has pressed the end button
    if BpodSystem.Status.BeingUsed == 0
        if exist('A', 'var')
            shutdown_protocol(A);
        end
        return

    end

end
