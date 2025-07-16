global BpodSystem

%% Session Setup
% Assert Analog Input module is present + USB-paired (via USB button on console GUI)
BpodSystem.assertModule('AnalogIn', 1); % The second argument (1) indicates that AnalogIn must be paired with its USB serial port

%% Setup analog input module
A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1); % Create an instance of the Analog Input module
A.nActiveChannels = 2; % Record from up to 2 channels
A.Stream2USB(1:2) = 1; % Configure only channels 1 and 2 for USB streaming
A.SMeventsEnabled(1) = 1; % Return threshold crossing events from Ch1
A.Thresholds(1) = 2.5; % Set voltage threshold of Ch1 to 2.5V
A.ResetVoltages(1) = 1; % Voltage must return below 1V before another threshold crossing event can be triggered
A.startReportingEvents; % Enable threshold event signaling
%behaviorDataFile = BpodSystem.Path.CurrentDataFile;
%A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
A.scope; % Launch Scope GUI
A.scope_StartStop % Start USB streaming + data logging

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

    S.GUI.select_taste_valve = 1; % Configurable reward condition schemes. 'BothCorrect' rewards either side.
    S.GUIMeta.select_taste_valve.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.select_taste_valve.String =  {'1','2','3','4','5'};
    
    S.GUI.select_amount_liquid_ul = 16; % set how many microliters of fluid to receive
    S.GUIMeta.select_amount_liquid_ul.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.select_amount_liquid_ul.String =  {'1','1.5','2','2.5','3','3.5','4','4.5','5','5.5','6','6.5','7','7.5','8','8.5'};
    
    S.GUI.Calibr_or_clean = 0; % if 1, it allow to set the oprning time of the valves to fixed time otherise it use the calibration 
    S.GUIMeta.Calibr_or_clean.Style = 'checkbox';
    
    S.GUIMeta.noflick.Style = 'edit'; 
    S.GUI.noflick = 7;
    S.GUIMeta.notrials.Style = 'edit'; 
    S.GUI.notrials = 210;

    if S.GUI.Calibr_or_clean == 1
        S.GUI.op_1 = GetValveTimes(BpodSystem.ProtocolSettings.GUI.select_amount_liquid_ul,1)*1000; 
        S.GUI.op_2 = 30;
        S.GUI.op_3 = 30;
        S.GUI.op_4 = 30;
        S.GUI.op_5 = 30;
    else
        S.GUI.op_1 = 30; 
        S.GUI.op_2 = 30;
        S.GUI.op_3 = 30;
        S.GUI.op_4 = 30;
        S.GUI.op_5 = 30;
    end
         
    S.GUIPanels.OpenTimes_Taste_Valves_milliseconds = {'op_1', 'op_2', 'op_3','op_4','op_5'};

    S.GUI.Valve_1 = 'Manual_Open_Valve(1,1,BpodSystem.ProtocolSettings.GUI.op_1)';
    S.GUIMeta.Valve_1.Style = 'pushbutton';
    S.GUI.Valve_2 = 'Manual_Open_Valve(1,2,BpodSystem.ProtocolSettings.GUI.op_2)';
    S.GUIMeta.Valve_2.Style = 'pushbutton';
    S.GUI.Valve_3 = 'Manual_Open_Valve(1,3,BpodSystem.ProtocolSettings.GUI.op_3)';
    S.GUIMeta.Valve_3.Style = 'pushbutton';
    S.GUI.Valve_4 = 'Manual_Open_Valve(1,4,BpodSystem.ProtocolSettings.GUI.op_4)';
    S.GUIMeta.Valve_4.Style = 'pushbutton';
    S.GUI.Valve_5 = 'Manual_Open_Valve(1,5,BpodSystem.ProtocolSettings.GUI.op_5)';
    S.GUIMeta.Valve_5.Style = 'pushbutton';
    S.GUIPanels.Manual_Taste_Valves = {'Valve_1', 'Valve_2', 'Valve_3','Valve_4','Valve_5'};

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
    S.GUIMeta.LickStick.Style = 'pushbutton';
    S.GUI.LickStick = 'launch_lick_stick(1)';

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
% Initialize Bpod notebook (for manual data annotation)
BpodNotebook('init'); 

% Initialize parameter GUI plugin
BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

%% this is just a state machine that will last 10 minutes to allow for checking parameter of the experiments
for i = 1:6000
    
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
        S.GUI.odor_ID_5 = S.GUIMeta.odor_line_5.String{S.GUI.odor_line_5};
        S.GUI.odor_ID_6 =  S.GUIMeta.odor_line_6.String{S.GUI.odor_line_6};
        S.GUI.odor_ID_7 =  S.GUIMeta.odor_line_7.String{S.GUI.odor_line_7};
        S.GUI.odor_ID_8 =  S.GUIMeta.odor_line_8.String{S.GUI.odor_line_8};       
        S.GUI.odor_ID_9 =  S.GUIMeta.odor_line_9.String{S.GUI.odor_line_9};
        S.GUI.odor_ID_10 =  S.GUIMeta.odor_line_10.String{S.GUI.odor_line_10};
        S.GUI.odor_ID_11 =  S.GUIMeta.odor_line_11.String{S.GUI.odor_line_11};
        S.GUI.odor_ID_12 =  S.GUIMeta.odor_line_12.String{S.GUI.odor_line_12}; 
                
        if S.GUI.Calibr_or_clean == 1
            S.GUI.op_1 = GetValveTimes(BpodSystem.ProtocolSettings.GUI.select_amount_liquid_ul,1)*1000;
            S.GUI.op_2 = 30;
            S.GUI.op_3 = 30;
            S.GUI.op_4 = 30;
            S.GUI.op_5 = 30;
        else
            S.GUI.op_1 = BpodSystem.ProtocolSettings.GUI.op_1;
            S.GUI.op_2 = BpodSystem.ProtocolSettings.GUI.op_2;
            S.GUI.op_3 = BpodSystem.ProtocolSettings.GUI.op_3;
            S.GUI.op_4 = BpodSystem.ProtocolSettings.GUI.op_4;
            S.GUI.op_5 = BpodSystem.ProtocolSettings.GUI.op_5;
        end
        S = BpodParameterGUI('sync', S);
        S.OdorSequence = gen_odor_sequence(BpodSystem);
        BpodSystem.ProtocolSettings = S;
        SaveProtocolSettings(BpodSystem.ProtocolSettings);
        disp(['Setting data are continously saved! You still have ' num2str((6000-i)/60) 'minutes to finish setting the parameters']);
      end
    % Exit the session if the user has pressed the end button
    if BpodSystem.Status.BeingUsed == 0
        A.scope_StartStop; % Stop Oscope GUI
        A.endAcq; % Close Oscope GUI
        A.stopReportingEvents; % Stop sending events to state machine
        clear A;
        return
        
    end

end
