%% Code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
%% Code edited by Timothy Vladimir Dong for Samuelsen Lab, Univeristy of Louisville----
% ASSOCIATION | WATER LEFT (Port 1)| ODOR RIGHT (Port 3)

function testing_WATER_left_ODOR_right_EDIT_singleValveOpening
    
    global BpodSystem

    W = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1);
    W.SamplingRate = 44100;

    Fs = 44100;    % Sampling rate in Hz (e.g., CD quality)
    T = .5;         % Duration in seconds
    f = 800;       % Frequency of the tone in Hz

    % Generate the time vector
    t = 0:1/Fs:T;

    % Generate the sinusoidal waveform
    y = sin(2*pi*f*t);
    %Five_volts = 5 * ones(1, W.SamplingRate/1000); % 1ms 5Volt signal
    W.loadWaveform(1, y);         % Loads a sound as waveform 1

    %expV is used to access experiment constants
    expV = ExperimentVariables();

    % this variable is created to indicate when the protocol should halt (after 60 minutes). This is set
    % in the softcode handler function 'BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_exit'
    BpodSystem.Status.ExitTrialLoop = false;

    % Organizing what to save to data structure
    BpodSystem.Data.correctTrials = nan(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.correctPort = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.centerValve = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.firstRewardLick = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.trialsEngaged = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Status.trial = 1;

    % Saving ExperimentVariables
    propNames = properties(expV); propValues = cell(size(propNames));
    for i = 1:numel(propNames) % Loop through and get each property value
        propValues{i} = expV.(propNames{i});
    end
    expVarTable = cell2table(propValues,'RowNames', propNames, 'VariableNames', {'Value'}); % Convert to table
    BpodSystem.Data.experimentVariables = expVarTable; % Save table to structure

    % Generating lineup and jitter for valve openings
    [center_port_valve_lineup, reward_lick_lineup, center_delay_lineup] = GenerateCenterLineup(); 
    BpodSystem.Data.centerValveDelay = center_delay_lineup;
    blankJitter = generateBlankValveJitter(); % generates jitter for every trial and valve opening at the start
    BpodSystem.Data.blankOpenTimes = expV.BLANK_OPEN_TIME + blankJitter; 

    %BpodSystem.Data.center_valve_lineup = center_port_valve_lineup;

    % used to indicate when middle stimulus should switch. this behavior is defined in  SoftCodeHandler.m
    BpodSystem.Status.switchStimulusFlag = false;

    % used to indicate when middle stimulus should switch. this behavior is defined in  SoftCodeHandler.m
    BpodSystem.Status.consecutiveRatSkips = 0;

    % configure the analog in. performed in configure_analog_in.m
    A = configure_analog_in();

    S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
    if isempty(fieldnames(S)) % If /

        subj = BpodSystem.GUIData.SubjectName;
        dir = ['C:\Users\Chad Samuelsen\Documents\Github\Bpod Local\Data\FakeSubject\Set_param_Ortho_Set_1\Session Settings\DefaultSettings.mat'];
        temp = load(dir);
        S = temp.ProtocolSettings; clear temp;

        % init an empty cell array to hold names of gui fields to remove
        fields = {};
        % remove ability to rename valve stimuli
        for i = 1:8
            fieldname = sprintf('valve_line_%d', i);
            fields{end+1} = fieldname;
            fieldname = sprintf('Valve_%d', i);
            fields{end+1} = fieldname;
        end

        S.GUIMeta = rmfield(S.GUIMeta, fields); % Using a cell array
        S.GUI = rmfield(S.GUI, fields);
        S.GUIPanels = rmfield(S.GUIPanels, {'Current_valve_assignments','Manual_Taste_Valves'});
        BpodSystem.ProtocolSettings = S;
    end

    valveID = ["Valve1"; "Valve2"; "Valve3"; "Valve4"; "Valve5"; "Valve6"; "Valve7";  "Valve8"];
    valveOpenTimes = [BpodSystem.ProtocolSettings.GUI.open_time_1; BpodSystem.ProtocolSettings.GUI.open_time_2; ...
        BpodSystem.ProtocolSettings.GUI.open_time_3; BpodSystem.ProtocolSettings.GUI.open_time_4; ...
        BpodSystem.ProtocolSettings.GUI.open_time_5; BpodSystem.ProtocolSettings.GUI.open_time_6; 
        BpodSystem.ProtocolSettings.GUI.open_time_7; BpodSystem.ProtocolSettings.GUI.open_time_8];
    BpodSystem.Data.valveOpenTimes = table(valveID,valveOpenTimes);

    % port_1 is the instance of the class Port1
    port_1 = LateralPort(1);
    % port_3 is the instance of the class Port3
    port_3 = LateralPort(3);
    % center_port the instance of the class center_port
    center_port = CenterPort;

    correct_port = PortHandler;
    incorrect_port = PortHandler;

    BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

    %% Print to document the start of the Session
    fprintf('Date and time: %s\n',datetime("now"))
    fprintf('Valve Durations: '); 
    for iValves=1:length(valveID); fprintf('%s=%.1fms. ',num2str(iValves),valveOpenTimes(iValves)); end
    fprintf('\n')

    %% Looping through trials
    % do MAXIMUM_TRIALS as defined in ExperimentVariables file if 60 minutes has not elapsed.
    for trial= 1:expV.MAXIMUM_TRIALS
        
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        BpodSystem.Status.trial  = trial;
        fprintf('Trial %d: ', trial)

        % Get center valve and number of dry licks for this trial
        center_stimulus_valve = center_port_valve_lineup(trial); 
        num_dryLicks = reward_lick_lineup(trial)-1;
        center_valveDelay = center_delay_lineup(trial);

        % Set center valve and correct port 
        center_port = center_port.setValve(1, center_stimulus_valve);
        correct_port = correct_port.setCorrect(port_1, port_3, center_stimulus_valve);
        incorrect_port = incorrect_port.setIncorrect(port_1, port_3, center_stimulus_valve);

        fprintf('Center=valve%d. %d dry licks. ',center_stimulus_valve,num_dryLicks);
        fprintf('Correct=port%d. ',correct_port.port); fprintf('Incorrect=port%d. ',incorrect_port.port);

        % Get blank jitter and offset between blank and true valve closing times
        center_timeOffset = expV.BLANK_OPEN_TIME + blankJitter(trial,1);
        center_blankTime = center_port.left_valve_time - center_timeOffset; 
        lateral_timeOffset = expV.BLANK_OPEN_TIME + blankJitter(trial,2); 
        lateral_blankTime = correct_port.valve_time - lateral_timeOffset; 

        %% Start State Machine for this Trial
        sma = NewStateMachine();

        % set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
        sma = SetGlobalTimer(sma, 'TimerID', expV.experimentTimerID, 'Duration', expV.TOTAL_ALLOWED_TIME);
        sma = SetGlobalTimer(sma, 'TimerID', expV.lickWindowTimerID, 'Duration', expV.LICK_WINDOW);

        % set global counters for each of the possible input ports (AnalogIn1 ports 1-4) to 6.
        sma = SetGlobalCounter(sma, center_port.LEFT_COUNTER_ID, center_port.LEFT_LICK_INPUT, num_dryLicks); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?
        sma = SetGlobalCounter(sma, center_port.RIGHT_COUNTER_ID, center_port.RIGHT_LICK_INPUT, num_dryLicks);
        sma = SetGlobalCounter(sma, port_1.COUNTER_ID, port_1.LICK_INPUT, 3);
        sma = SetGlobalCounter(sma, port_3.COUNTER_ID, port_3.LICK_INPUT, 3);

        % if this is the first trial
        if (trial == 1)
            % add max time allowed timer

            sma = AddState(sma, 'Name', 'triggerExperimentTimer', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'ITI_start'},...
                'OutputActions',{'GlobalTimerTrig', expV.EXPERIMENT_TIMER_ID});
        end

        if (mod(trial, (expV.TRIALS_PER_BLOCK + 1)) == 0)
            % new trial *block*, reset consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = 0;
        end

        if (expV.MINIMUM_TRIALS) % evaluate if minimum trial number is reached, and if 10 consecutive traials have been skipped
            if(BpodSystem.Status.consecutiveRatSkips >= expV.SKIPPED_TRIALS_THRESHOLD)
                stop_experiment(A, W);
                return
            end
        end

        BpodSystem.Data.centerValve(trial) = center_port.left_valve;
        BpodSystem.Data.correctPort(trial) = correct_port.port;
        BpodSystem.Data.firstRewardLick(trial) = num_dryLicks;

        %% Adding States

        sma = AddState(sma, 'Name', 'ITI_start', ...
            'Timer', (expV.ITI_TIME-5),...
            'StateChangeConditions', {'Tup', 'TTC_Center', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.UP});

        sma = AddState(sma, 'Name', 'TTC_Center', ...
            'Timer', expV.TTC_CENTER_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', center_port.LEFT_LICK_INPUT, 'firstCenterLick', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalCounterReset', center_port.LEFT_COUNTER_ID, 'WavePlayer1', ['P' 8 0]});

        sma = AddState(sma, 'Name', 'firstCenterLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitForRemainingCenterDryLicks'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});

        sma = AddState(sma, 'Name', 'waitForRemainingCenterDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_COUNTER_EVENT, 'waitCenterRewardLick', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'waitCenterRewardLick', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_LICK_INPUT, 'delayCenterValve', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'delayCenterValve', ...
            'Timer', center_valveDelay,...
            'StateChangeConditions', {'Tup', 'openCenterValve', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openCenterValve', ...
            'Timer', center_blankTime,...
            'StateChangeConditions', {'Tup', 'closeCenterBlank'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.left_valve], 'BNC1', 1});

         sma = AddState(sma, 'Name', 'closeCenterBlank', ...
            'Timer', center_timeOffset,...
            'StateChangeConditions', {'Tup', 'closeCenterValve'},...
            'OutputActions',{center_port.DOOR, expV.DOWN,'BNC1', 0});

        sma = AddState(sma, 'Name', 'closeCenterValve', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ttcLateralTimeout'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.left_valve]});

        %%%%% BEGIN TTC ON THE LATERAL PORTS %%%%%
        sma = AddState(sma, 'Name', 'ttcLateralTimeout', ...
            'Timer', expV.DELAY_TIME,...
            'StateChangeConditions', {'Tup', 'ttcLateral', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.UP, 'GlobalCounterReset', port_3.COUNTER_ID,'SoftCode', 3});

        sma = AddState(sma, 'Name', 'ttcLateral', ...
            'Timer', expV.TTC_LATERAL_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', correct_port.lick_event, 'waitLateralDryLicks', incorrect_port.lick_event,...
            'waitLateralDryLicks' expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, port_3.DOOR, expV.DOWN, 'GlobalCounterReset', port_1.COUNTER_ID});

        sma = AddState(sma, 'Name', 'waitLateralDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_counter_event, 'waitLateralRewardLick', incorrect_port.lick_counter_event, ...
            'reportIncorrect', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired, 'reportSkip'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, port_3.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});

        sma = AddState(sma, 'Name', 'waitLateralRewardLick', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_event, 'openLateralReward', expV.experimentTimeExpired , 'cleanup'...
            expV.lickTimeExpired, 'reportSkip'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, port_3.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openLateralReward', ...
            'Timer', lateral_blankTime,...
            'StateChangeConditions', {'Tup', 'closeLateralBlank'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, port_3.DOOR, expV.DOWN, 'ValveModule1', ['O', correct_port.valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralBlank', ...
            'Timer', lateral_timeOffset,...
            'StateChangeConditions', {'Tup', 'closeLateralReward'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, port_3.DOOR, expV.DOWN, 'BNC1', 0});

        sma = AddState(sma, 'Name', 'closeLateralReward', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_end'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, port_3.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.valve]});

        sma = AddState(sma, 'Name', 'reportIncorrect', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_punish'},...
            'OutputActions',{'SoftCode', 14});

        sma = AddState(sma, 'Name', 'reportSkip', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_punish'},...
            'OutputActions',{'SoftCode', 2});

        sma = AddState(sma, 'Name', 'ITI_end', ...
            'Timer', 5,...
            'StateChangeConditions', {'Tup', 'resetCorrectCounter'},...
            'OutputActions',{port_1.DOOR, expV.UP, port_3.DOOR, expV.UP, 'SoftCode', 15});
        
        sma = AddState(sma, 'Name', 'ITI_punish', ...
            'Timer', (expV.PUNISHMENT_TIME+5),...
            'StateChangeConditions', {'Tup', 'resetCorrectCounter'},...
            'OutputActions',{port_1.DOOR, expV.UP, port_3.DOOR, expV.UP});

        sma = AddState(sma, 'Name', 'resetCorrectCounter', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'resetIncorrectCounter'},...
            'OutputActions',{'GlobalCounterReset', correct_port.lick_counter_id});

        sma = AddState(sma, 'Name', 'resetIncorrectCounter', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'resetCenterCounter'},...
            'OutputActions',{'GlobalCounterReset', incorrect_port.lick_counter_id});

        sma = AddState(sma, 'Name', 'resetCenterCounter', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{'GlobalCounterReset', center_port.LEFT_COUNTER_ID});

        sma = AddState(sma, 'Name', 'cleanup', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{port_1.DOOR, expV.UP, port_3.DOOR, expV.UP, 'ValveModule1', ['B' 00000000], 'BNC1', 0, 'SoftCode', 1});

        % function will check if softcode '3' has been sent by the state machine in cleanup state. if it has, it is time to exit the
        % trial loop.
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

        SendStateMachine(sma);
        events = RunStateMachine();

        if ~isempty(fieldnames(events)) % If you didn't stop the session manually mid-trial
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,events); % Adds raw events to a human-readable data struct
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

        if (BpodSystem.Status.ExitTrialLoop == 1 || BpodSystem.Status.BeingUsed == 0)
            stop_experiment(A, W);
            return
        end

        fprintf('\n')
    end
end
