%% Code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% SIDE TRAiNING DAYS 5-6 | ODOR CENTER | VALVE 5 CENTER | LEFT PORT REWARD
function side_training_day_1_odor_right
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
    expV = ExperimentVariables;

    % this variable is created to indicate when the protocol should halt (after 60 minutes). This is set
    % in the softcode handler function 'BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_exit'
    BpodSystem.Status.ExitTrialLoop = false;

    % global variable that will be accessed when SoftCode15 is sent indicating a correct trial selection
    BpodSystem.Data.CorrectTrials = 0;

    BpodSystem.Data.correctPort = zeros(expV.MAXIMUM_TRIALS, 1);

    BpodSystem.Data.centerValve = zeros(expV.MAXIMUM_TRIALS, 1);

    BpodSystem.Data.trialsEngaged = zeros(expV.MAXIMUM_TRIALS, 1);

    BpodSystem.Status.trial = 1;


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

    % port_1 is the instance of the class Port1
    port_1 = LateralPort(1);
    % port_3 is the instance of the class Port3
    port_3 = LateralPort(3);
    % center_port the instance of the class center_port
    center_port = CenterPort;

    correct_port = PortHandler;
    incorrect_port = PortHandler;

    BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

    % do MAXIMUM_TRIALS as defined in ExperimentVariables file if 60 minutes has not elapsed.
    for trial= 1:expV.MAXIMUM_TRIALS
        BpodSystem.Status.trial  = trial;
        trial

        S = BpodParameterGUI('sync', S);

        sma = NewStateMachine();

        % set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
        sma = SetGlobalTimer(sma, 'TimerID', expV.experimentTimerID, 'Duration', expV.TOTAL_ALLOWED_TIME);
        sma = SetGlobalTimer(sma, 'TimerID', expV.lickWindowTimerID, 'Duration', expV.LICK_WINDOW);

        % set global counters for each of the possible input ports (AnalogIn1 ports 1-4) to 6.
        sma = SetGlobalCounter(sma, center_port.LEFT_COUNTER_ID, center_port.LEFT_LICK_INPUT, 3); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?
        sma = SetGlobalCounter(sma, center_port.RIGHT_COUNTER_ID, center_port.RIGHT_LICK_INPUT, 3);
        sma = SetGlobalCounter(sma, port_1.COUNTER_ID, port_1.LICK_INPUT, 3);
        sma = SetGlobalCounter(sma, port_3.COUNTER_ID, port_3.LICK_INPUT, 3);

        % if this is the first trial 
        if (trial == 1)
            first_stimulus_valve = center_port.ODOR_VALVE; % ODOR_VALVE == 5
            first_stimulus_valve

            center_port = center_port.setValve(1, first_stimulus_valve);

            correct_port = correct_port.setCorrect(port_1, port_3, first_stimulus_valve);
            incorrect_port = incorrect_port.setIncorrect(port_1, port_3, first_stimulus_valve);

            correct_port
            incorrect_port

            sma = AddState(sma, 'Name', 'triggerExperimentTimer', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'ITI'},...
                'OutputActions',{'GlobalTimerTrig', 1});
        end

        if (BpodSystem.Status.switchStimulusFlag)
            % switch correct and incorrect
            center_port = center_port.switchLeftValve();

            % select correct and incorrect port based on center_port.left_valve
            correct_port = correct_port.setCorrect(port_1, port_3, center_port.left_valve);
            incorrect_port = incorrect_port.setIncorrect(port_1, port_3, center_port.left_valve);

            % reset the flag
            BpodSystem.Status.switchStimulusFlag = false;

            correct_port
            incorrect_port

        end

        if (mod(trial, (expV.TRIALS_PER_BLOCK + 1)) == 0)
            % new trial *block*, reset consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = 0;
        end

        if (expV.MINIMUM_TRIALS) % evaluate if minimum trial number is reached, and if 10 consecutive traials have been skipped
            if(BpodSystem.Status.consecutiveRatSkips >= 10)
                stop_experiment(A, W);
                return
            end
        end

        BpodSystem.Data.centerValve(trial) = center_port.left_valve;
        BpodSystem.Data.correctPort(trial) = correct_port.port;


        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', expV.ITI_TIME,...
            'StateChangeConditions', {'Tup', 'TTC_Center', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.UP, 'GlobalTimerTrig', expV.EXPERIMENT_TIMER_ID});

        sma = AddState(sma, 'Name', 'TTC_Center', ...
            'Timer', expV.TTC_CENTER_TIME,...
            'StateChangeConditions', {'Tup', 'punish', center_port.LEFT_LICK_INPUT, 'firstCenterLick', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalCounterReset', center_port.LEFT_COUNTER_ID, 'WavePlayer1', ['P' 8 0]});

        sma = AddState(sma, 'Name', 'firstCenterLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitForRemainingCenterDryLicks'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});

        sma = AddState(sma, 'Name', 'waitForRemainingCenterDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_COUNTER_EVENT, 'waitCenterRewardLick1', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'punish'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'waitCenterRewardLick1', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_LICK_INPUT, 'openCenterValve', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'punish' },...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openCenterValve', ...
            'Timer', center_port.left_valve_time,...
            'StateChangeConditions', {'Tup', 'centerValveOff'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.left_valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'centerValveOff', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitCenterRewardLick2'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.left_valve], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'waitCenterRewardLick2', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_LICK_INPUT, 'openCenterValve2', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'punish' },...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openCenterValve2', ...
            'Timer', center_port.left_valve_time,...
            'StateChangeConditions', {'Tup', 'centerValveOff2', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.left_valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'centerValveOff2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitSixthLick', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.left_valve], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'waitSixthLick', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_LICK_INPUT, 'ttcLateralTimeout', expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired , 'punish'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});


        %%%%% BEGIN TTC ON THE LATERAL PORTS %%%%%
        sma = AddState(sma, 'Name', 'ttcLateralTimeout', ...
            'Timer', expV.LATERAL_DELAY,...
            'StateChangeConditions', {'Tup', 'ttcLateral', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.UP, 'GlobalCounterReset', port_3.COUNTER_ID, 'SoftCode', 3});

        sma = AddState(sma, 'Name', 'ttcLateral', ...
            'Timer', expV.TTC_LATERAL_TIME,...
            'StateChangeConditions', {'Tup', 'exit', correct_port.lick_event, 'waitLateralDryLicks', incorrect_port.lick_event,...
                'waitLateralDryLicks' expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'GlobalCounterReset', port_1.COUNTER_ID});

        sma = AddState(sma, 'Name', 'waitLateralDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_counter_event, 'waitLateralRewardLick1', incorrect_port.lick_counter_event, 'punish', expV.experimentTimeExpired , 'cleanup',...
                expV.lickTimeExpired, 'exit'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.lickWindowTimerID});

        sma = AddState(sma, 'Name', 'waitLateralRewardLick1', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_event, 'openLateralReward1', expV.experimentTimeExpired , 'cleanup',...
                expV.lickTimeExpired, 'exit'},...
            'OutputActions',{port_1.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openLateralReward1', ...
            'Timer', correct_port.valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralReward1'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'ValveModule1', ['O', correct_port.valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralReward1', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick2'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.valve], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'waitLateralRewardLick2', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_event, 'openLateralReward2', expV.experimentTimeExpired , 'cleanup',...
                expV.lickTimeExpired, 'exit'},...
            'OutputActions',{port_1.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openLateralReward2', ...
            'Timer', correct_port.valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralReward2'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'ValveModule1', ['O', correct_port.valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralReward2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick3'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.valve], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'waitLateralRewardLick3', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_event, 'openLateralReward3', expV.experimentTimeExpired , 'cleanup',...
                expV.lickTimeExpired, 'exit'},...
            'OutputActions',{port_1.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'openLateralReward3', ...
            'Timer', correct_port.valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralReward3'},...
            'OutputActions',{port_1.DOOR, expV.DOWN,'ValveModule1', ['O', correct_port.valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralReward3', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'reportCorrectSelection'},...
            'OutputActions',{port_1.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.valve], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'punish', ...
            'Timer', expV.PUNISHMENT_TIME,...
            'StateChangeConditions', {'Tup', 'resetCorrectCounter'},...
            'OutputActions',{port_1.DOOR, expV.UP, 'SoftCode', 2});

        sma = AddState(sma, 'Name', 'reportCorrectSelection', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'resetCorrectCounter'},...
            'OutputActions',{});

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
        trial_events = RunStateMachine();

        if ~isempty(fieldnames(trial_events)) % If you didn't stop the session manually mid-trial
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, trial_events); % Adds raw events to a human-readable data struct
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

        if (BpodSystem.Status.ExitTrialLoop == 1 || BpodSystem.Status.BeingUsed == 0)
            stop_experiment(A, W);
            return
        end
    end
end

