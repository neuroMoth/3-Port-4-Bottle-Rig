%% Code written by Roberto Vincis, FSU ---- Edited for Samuelsen Lab by Blake Hourigan 7/17/25
% This code is called from the BPod Console to setup the parameters for 3 port ... experiment


% get the filename of the default settings so we can delete it and avoid
% using cached file instead of the one we are making now 
f = fullfile('C:\','Users','Chad Samuelsen','Documents','Github','Bpod Local','Data','FakeSubject','Set_param_Ortho_Set_1','Session Settings', 'DefaultSettings.mat');

if exist(f, 'file')
    delete(f);
end

global BpodSystem

function start_oscilliscope(analog_object)
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


%% Session Setup
% Assert Analog Input module is present + USB-paired (via USB button on console GUI)
%BpodSystem.assertModule('AnalogIn', 1); % The second argument (1) indicates that AnalogIn must be paired with its USB serial port
%
%
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
%start_oscilliscope(A);
%%--- Define parameters and trial structure


S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'

if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S = default_protocol_settings(S);

    BpodSystem.ProtocolSettings = S;
end

% Initialize parameter GUI plugin with gui returned from default_protocol_settings
BpodParameterGUI('init', S); 


%% BEGIN REPEATING STATE MACHINE -- LAST 10 MINUTES -- CONTINUOUSLY SAVES SETTINGS
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

        for v =  1:Set_param_constants.NUM_VALVES
            % dynamically gets the number of the odor based on i.
            id = v;
            valve_line_number = sprintf('valve_line_%d', id);

            odor_id_field = sprintf('odor_ID_%d', id);

            % fill in dynamically generated variable name to get the value
            S.GUI.(odor_id_field) = S.GUIMeta.(valve_line_number).String{S.GUI.(valve_line_number)};
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
%% END STATE MACHINE
