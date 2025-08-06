%% Code written by Roberto Vincis, FSU ----
% This code is called back from the BPod Console to run orthonasal odor
% experiments using. 
% Add more details here....

global BpodSystem

%% --- Session Setup
% Assert Analog Input module is present + USB-paired (via USB button on console GUI)
BpodSystem.assertModule('AnalogIn', 1); % 
BpodSystem.assertModule('WavePlayer', 1); % 

%% Setup analog input module - This should read and record licking, breathing, and many other inputs sent by the analog outputs
A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1); % Create an instance of the Analog Input module
A.nActiveChannels = 4; % Record from up to 2 channels
A.Stream2USB(1:4) = 1; % Configure only channels 1 and 2 for USB streaming
A.InputRange(1) = {'-5V:5V'}; A.InputRange(2) = {'-5V:5V'}; A.InputRange(3) = {'-5V:5V'}; A.InputRange(4) = {'-10V:10V'};
%A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
%A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
%A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
A.startReportingEvents; % Enable threshold event signaling
behaviorDataFile = BpodSystem.Path.CurrentDataFile;
A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
A.scope; % Launch Scope GUI
A.scope_StartStop % Start USB streaming + data logging

%% --- Define parameters and trial structure
%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        
        subj = BpodSystem.GUIData.SubjectName;
        dir = ['C:\Users\VincisLab Photometry\Documents\MATLAB\Bpod Local\Data\' subj '\Set_param_Ortho_Set_1\Session Settings\DefaultSettings.mat'];
        temp = load(dir);
        S = temp.ProtocolSettings; clear temp;
        
        S.GUIMeta = rmfield(S.GUIMeta, {'odor_line_5', 'odor_line_6','odor_line_7', 'odor_line_8',...   
                                        'odor_line_9', 'odor_line_10','odor_line_11', 'odor_line_12',...
                                        'Valve_1','Valve_2','Valve_3','Valve_4','Valve_5',...
                                        'Ortho_ON','Ortho_OFF','Retro_ON','Retro_OFF','Gen_ON','Gen_OFF'}); % Using a cell array
    
        S.GUI = rmfield(S.GUI, {'odor_line_5', 'odor_line_6','odor_line_7', 'odor_line_8',...
                                'odor_line_9', 'odor_line_10','odor_line_11', 'odor_line_12',...
                                 'Valve_1','Valve_2','Valve_3','Valve_4','Valve_5',...
                                 'Ortho_ON','Ortho_OFF','Retro_ON','Retro_OFF','Gen_ON','Gen_OFF'});
                                    
        S.GUIPanels = rmfield(S.GUIPanels, {'Current_Odor_List','Manual_Odor_Solenoids','Manual_Taste_Valves'});
    end
%% --- Initialize the control for generation of sounds and 5 Volts analog events
% Decimal:8 -> binary:1000 -> analog output 4 (WavePlayer1)
% Decimal:4 -> binary:0100 -> analog output 3 (WavePlayer1)
W = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1); % Create an instance of the WavePlayer 4 channels
J = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer2); % Create an instance of the WavePlayer 8 channels

W.SamplingRate = 10000; %10KHz sampilng rate
J.SamplingRate = 10000; %10KHz sampilng rate

Sound  = GenerateSineWave(30000, 55000, 1);
Sound  = Sound(1:500*1); % 500ms

Five_volts = 5 * ones(1, W.SamplingRate/1000); % 1ms 5Volt signal
W.loadWaveform(1, Sound);         % Loads a sound as waveform 1
W.loadWaveform(2, -1*Five_volts); % Loads a single -5V sample as waveform 2
W.loadWaveform(3, Five_volts);    % Loads a single 5V sample as waveform 3

%%
% add the settings to the Bpodsystem object
BpodSystem.ProtocolSettings = S;

% Initialize Bpod notebook (for manual data annotation)
BpodNotebook('init'); 

% Initialize parameter GUI plugin
BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

%%
for current_trial = 1:size(BpodSystem.ProtocolSettings.OdorSequence,2)
    
    S = BpodParameterGUI('sync', S); 
    % Ok add here which line to deliver the reward should be open
    LoadSerialMessages('ValveModule1', {['O' BpodSystem.ProtocolSettings.GUI.select_taste_valve], ['C' BpodSystem.ProtocolSettings.GUI.select_taste_valve]});  % Just play with Valve 1 for the moment
    time = BpodSystem.ProtocolSettings.GUI.op_1/1000;

    sma = NewStateMachine();
    
    sma = SetGlobalCounter(sma, 1, 'BNC1High', BpodSystem.ProtocolSettings.GUI.noflick); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?

    sma = AddState(sma, 'Name', 'start', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup' , 'sound'},...    
        'OutputActions', {'AnalogIn1', ['#' 0], 'WavePlayer1',['P' 4 2]});
    
    sma = AddState(sma, 'Name', 'sound', ...
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup' , 'WaitForLick1_IN'},...    
        'OutputActions', {'AnalogIn1', ['#' 1], 'WavePlayer1',['P' 3 0]});
    
    sma = AddState(sma, 'Name', 'WaitForLick1_IN', ...
        'Timer', 5,...
        'StateChangeConditions', {'Tup' , 'ITI', 'GlobalCounter1_End', 'OpenValve'},...    
        'OutputActions', {'GlobalCounterReset', 1}); 
      
    sma = AddState(sma, 'Name', 'OpenValve', ...
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'DelayValve'},...
        'OutputActions', {'PWM1', 255, 'ValveModule1',  1, 'AnalogIn1', ['#' 2],'WavePlayer1',['P' 8 1]});
    
    sma = AddState(sma, 'Name', 'DelayValve', ...
        'Timer', time,...
        'StateChangeConditions', {'Tup', 'CloseValve'},...
        'OutputActions', {}); 

    sma = AddState(sma, 'Name', 'CloseValve', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'PWM1', 255,'ValveModule1', 2});
    
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer',2,...
        'StateChangeConditions', {'Tup', '>exit'},...
        'OutputActions', {'AnalogIn1', ['#' 5]}); 
    
     % Send description to the Bpod State Machine device
    SendStateMachine(sma);
    
    % Run the trial
    RawEvents = RunStateMachine;
    
     if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Adds raw events to a human-readable data struct
        BpodSystem.Data.TrialSettings(current_trial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        %BpodSystem.Data.RawEvents.Trial{1,T}.TasteID = currentTrial(1,1);
        BpodSystem.Data.RawEvents.Trial{1,current_trial}.OdorVial  = BpodSystem.ProtocolSettings.OdorSequence(current_trial);
        temp = {'';'';'';'';BpodSystem.ProtocolSettings.GUI.odor_ID_5; BpodSystem.ProtocolSettings.GUI.odor_ID_6;...
                BpodSystem.ProtocolSettings.GUI.odor_ID_7;BpodSystem.ProtocolSettings.GUI.odor_ID_8;...
                BpodSystem.ProtocolSettings.GUI.odor_ID_9;BpodSystem.ProtocolSettings.GUI.odor_ID_10;...
                BpodSystem.ProtocolSettings.GUI.odor_ID_11};     
        BpodSystem.Data.RawEvents.Trial{1,current_trial}.OdorID = temp{BpodSystem.Data.RawEvents.Trial{1,current_trial}.OdorVial};
        %BpodSystem.Data.RawEvents.Trial{1,T}.MFC(1,2) = S.MFC(1,2);     
        %BpodSystem.Data.RawEvents.Trial{1,T}.OdorID = S.setting.OdorID(currentTrial(1,3)).valve;
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        disp(['Saved data for trial #' num2str(current_trial)]);
        %--- Typically a block of code here will update online plots using the newly updated BpodSystem.Data
        StateTiming();
        if current_trial == size(BpodSystem.ProtocolSettings.OdorSequence,2)
            A.scope_StartStop; % Stop Oscope GUI
            A.endAcq; % Close Oscope GUI
            A.stopReportingEvents; % Stop sending events to state machine
        else
        end
      end
    % Exit the session if the user has pressed the end button
    if BpodSystem.Status.BeingUsed == 0
        A.scope_StartStop; % Stop Oscope GUI
        A.endAcq; % Close Oscope GUI
        A.stopReportingEvents; % Stop sending events to state machine
        return
    end

end
