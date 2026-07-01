%% Code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% center port open for 30 minutes. even licks are rewarded with stimulus.

function lick_training_familiarization_CENTER 
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

        center_port = center_port.setValve(2, center_port.WATER_VALVE);

        S = BpodParameterGUI('sync', S);

        sma = NewStateMachine();

        % set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
        sma = SetGlobalTimer(sma, 'TimerID', expV.experimentTimerID, 'Duration', expV.TOTAL_ALLOWED_TIME);

        sma = AddState(sma, 'Name', 'start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'centerPortDown', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{'GlobalTimerTrig', 1, 'WavePlayer1', ['P' 8 0]});

        sma = AddState(sma, 'Name', 'centerPortDown', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.RIGHT_LICK_INPUT, 'noRewardLick', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'noRewardLick', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.RIGHT_LICK_INPUT, 'RewardLick', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        sma = AddState(sma, 'Name', 'RewardLick', ...
            'Timer', center_port.right_valve_time,...
            'StateChangeConditions', {'Tup', 'flipValveOff', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O', center_port.left_valve], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'flipValveOff', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'centerPortDown', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C', center_port.left_valve], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'cleanup', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{center_port.DOOR, expV.UP, 'ValveModule1', 2});

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

