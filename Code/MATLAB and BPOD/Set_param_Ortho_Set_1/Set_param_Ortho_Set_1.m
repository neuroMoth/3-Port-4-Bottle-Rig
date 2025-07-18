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


%% Session Setup
% Assert Analog Input module is present + USB-paired (via USB button on console GUI)
BpodSystem.assertModule('AnalogIn', 1); % The second argument (1) indicates that AnalogIn must be paired with its USB serial port


%% Setup analog input module
%A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1); % Create an instance of the Analog Input module
%A.nActiveChannels = 1; % Record from up to 2 channels
%
%A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
%A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
%%A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
%
%A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
%A.startReportingEvents; % Enable threshold event signaling
%
%%behaviorDataFile = BpodSystem.Path.CurrentDataFile;
%%A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
%start_scope(A);
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
    
    % if S.GUI.calibration_or_clean popup has the first option selected (use calibration values) then go find those 
    % for each valve 
    if S.GUI.calibration_or_clean == 1
        for i = 1:8
            valve = i;
            
            open_time = sprintf("op_%d", valve);
            S.GUI.(open_time) = GetValveTimes(S.GUI.select_amount_liquid_ul,i) * 1000; 
        end

    else
    % otherwise use a default of 30 and allow user to change to whatever value they want
        for i = 1:8
            valve = i;
            
            open_time = sprintf("op_%d", valve);
            S.GUI.(open_time) = 30;
        end
    end

    S.GUIPanels.OpenTimes_Taste_Valves_milliseconds = {'op_1', 'op_2', 'op_3','op_4','op_5','op_6','op_7','op_8'};

    S.GUI.Valve_1 = 'Manual_Open_Valve(1,1,BpodSystem.ProtocolSettings.GUI.op_1)';
    S.GUIMeta.Valve_1.Style = 'pushbutton';

    S.GUI.Valve_2 = 'Manual_Open_Valve(1,2,S.GUI.op_2)';
    S.GUIMeta.Valve_2.Style = 'pushbutton';
    S.GUI.Valve_3 = 'Manual_Open_Valve(1,3,S.GUI.op_3)';
    S.GUIMeta.Valve_3.Style = 'pushbutton';
    S.GUI.Valve_4 = 'Manual_Open_Valve(1,4,S.GUI.op_4)';
    S.GUIMeta.Valve_4.Style = 'pushbutton';
    S.GUI.Valve_5 = 'Manual_Open_Valve(1,5,S.GUI.op_5)';
    S.GUIMeta.Valve_5.Style = 'pushbutton';
    S.GUI.Valve_6 = 'Manual_Open_Valve(1,6,S.GUI.op_6)';
    S.GUIMeta.Valve_6.Style = 'pushbutton';
    S.GUI.Valve_7 = 'Manual_Open_Valve(1,7,S.GUI.op_7)';
    S.GUIMeta.Valve_7.Style = 'pushbutton';
    S.GUI.Valve_8 = 'Manual_Open_Valve(1,8,S.GUI.op_8)';
    S.GUIMeta.Valve_8.Style = 'pushbutton';
    S.GUIPanels.Manual_Taste_Valves = {'Valve_1', 'Valve_2', 'Valve_3','Valve_4','Valve_5', 'Valve_6', 'Valve_7', 'Valve_8'};

    %% Manual control odor solenoid valves
    S.GUI.Ortho_ON = 'Manual_OdGen_Valve(2,1,1)';
    S.GUIMeta.Ortho_ON.Style = 'pushbutton';
    S.GUI.Ortho_OFF = 'Manual_OdGen_Valve(2,1,0)';
    S.GUIMeta.Ortho_OFF.Style = 'pushbutton';
    S.GUI.Retro_ON = 'Manual_OdGen_Valve(2,2,1)';
    S.GUIMeta.Retro_ON.Style = 'pushbutton';
    S.GUI.Retro_OFF = 'Manual_OdGen_Valve(2,2,0)';
    S.GUIMeta.Retro_OFF.Style = 'pushbutton';
    S.GUI.Gen_ON = 'Manual_OdGen_Valve(2,3,1)';
    S.GUIMeta.Gen_ON.Style = 'pushbutton';
    S.GUI.Gen_OFF = 'Manual_OdGen_Valve(2,3,0)';
    S.GUIMeta.Gen_OFF.Style = 'pushbutton';
    S.GUIPanels.Manual_Odor_Solenoids = {'Ortho_ON', 'Ortho_OFF', 'Retro_ON','Retro_OFF','Gen_ON','Gen_OFF'};

    %% Control Lick Stick
    %S.GUIMeta.LickStick.Style = 'pushbutton';
    %.GUI.LickStick = 'launch_lick_stick(1)';

    %% Control the 7 odor lines - Line 12 must be empty

    S.GUI.odor_line_5 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
    S.GUIMeta.odor_line_5.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.odor_line_5.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
        'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
        'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
        'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
S.GUI.odor_line_6 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
S.GUIMeta.odor_line_6.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
S.GUIMeta.odor_line_6.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
    'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
    'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
    'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
     S.GUI.odor_line_7 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
     S.GUIMeta.odor_line_7.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
     S.GUIMeta.odor_line_7.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
         'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
         'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
         'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
 S.GUI.odor_line_8 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
 S.GUIMeta.odor_line_8.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
 S.GUIMeta.odor_line_8.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
     'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
     'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
     'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
     S.GUI.odor_line_9 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
     S.GUIMeta.odor_line_9.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
     S.GUIMeta.odor_line_9.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
         'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
         'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
         'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
 S.GUI.odor_line_10 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
 S.GUIMeta.odor_line_10.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
 S.GUIMeta.odor_line_10.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
     'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
     'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
     'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
     S.GUI.odor_line_11 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
     S.GUIMeta.odor_line_11.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
     S.GUIMeta.odor_line_11.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
         'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
         'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
         'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
 S.GUI.odor_line_12 = 21; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
 S.GUIMeta.odor_line_12.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
 S.GUIMeta.odor_line_12.String =  {'empty','odor_5', 'odor_6', 'odor_7','odor_8','odor_9',...
     'odor_10', 'odor_11', 'odor_12','odor_13','odor_14',...
     'odor_15', 'odor_16', 'odor_17','odor_18','odor_19',...
     'odor_20', 'odor_21', 'odor_22','odor_23','odor_24'};
%     
S.GUIPanels.Current_Odor_List = {'odor_line_5','odor_line_6','odor_line_7','odor_line_8','odor_line_9',...
    'odor_line_10','odor_line_11','odor_line_12',};
    %%
    S.GUI.odor_set = 3; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
    S.GUIMeta.odor_set.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.odor_set.String =  {'first set of 7 odors','second set of 7 odors','third set of 7 odors'};
    %%
    S.GUIMeta.odor_ID_5.Style = 'text';
    S.GUIMeta.odor_ID_6.Style = 'text';
    S.GUIMeta.odor_ID_7.Style = 'text';
    S.GUIMeta.odor_ID_8.Style = 'text';
    S.GUIMeta.odor_ID_9.Style = 'text';
    S.GUIMeta.odor_ID_10.Style = 'text';
    S.GUIMeta.odor_ID_11.Style = 'text';
    S.GUIMeta.odor_ID_12.Style = 'text';
    %     
    S.GUI.odor_ID_5 = S.GUIMeta.odor_line_5.String{S.GUI.odor_line_5};
    S.GUI.odor_ID_6 =  S.GUIMeta.odor_line_6.String{S.GUI.odor_line_6};
    S.GUI.odor_ID_7 =  S.GUIMeta.odor_line_7.String{S.GUI.odor_line_7};
    S.GUI.odor_ID_8 =  S.GUIMeta.odor_line_8.String{S.GUI.odor_line_8};       
    S.GUI.odor_ID_9 =  S.GUIMeta.odor_line_9.String{S.GUI.odor_line_9};
    S.GUI.odor_ID_10 =  S.GUIMeta.odor_line_10.String{S.GUI.odor_line_10};
    S.GUI.odor_ID_11 =  S.GUIMeta.odor_line_11.String{S.GUI.odor_line_11};
    S.GUI.odor_ID_12 =  S.GUIMeta.odor_line_12.String{S.GUI.odor_line_12};

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
            S.GUI.(odor_id_field) = S.GUIMeta.odor_line_5.String{S.GUI.(odor_line_number)};
        end

        if S.GUI.calibration_or_clean == 1

            for i = 1:8
                % for all eight valves, get valve corresponding valve opening time 
                valve = i;
                valve_name = sprintf("op_%d", valve);
                % the parenthesis allow you to create variables with dynamic names so you don't need to repeat code a bunch
                S.GUI.(valve_name) = GetValveTimes(S.GUI.select_amount_liquid_ul,i)*1000;
            end
        else
            for i = 1:8
                % for all eight valves, get valve corresponding valve opening time 
                valve = i;
                valve_name = sprintf("op_%d", valve);
                % the parenthesis allow you to create variables with dynamic names so you don't need to repeat code a bunch
                S.GUI.(valve_name) = BpodSystem.ProtocolSettings.GUI.(valve_name);
            end


            % sync parameters to gui inputs
            S = BpodParameterGUI('sync', S);

            S.OdorSequence = gen_odor_sequence(BpodSystem);

            BpodSystem.ProtocolSettings = S;

            SaveProtocolSettings(BpodSystem.ProtocolSettings)
            disp(['Setting data are continously saved! You still have ' num2str((Set_param_constants.NUM_SECONDS-i)/60) 'minutes to finish setting the parameters']);
        end
    end
    % Exit the session if the user has pressed the end button
    if BpodSystem.Status.BeingUsed == 0
        shutdown_protocol(A);
        return

    end

end
