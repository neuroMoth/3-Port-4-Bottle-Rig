% Original code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% V2 code edited/written by Timothy Vladimir Dong for Samuelsen Lab, Univeristy of Louisville----

%% SIDE TRAINING 1 PROTOCOL V2 | WATER STIMULUS
function day04_sideTraining1_WATER_v2
    
    global BpodSystem % Imports the BpodSystem object to the function workspace

    %% SET UP SESSION
    expV = ExperimentVariables(); %expV is used to access experiment constants

    % Setup for wave player
    Fs = 44100;    % Sampling rate in Hz (e.g., CD quality)
    T = .5;         % Duration in seconds
    f = 800;       % Frequency of the tone in Hz
    t = 0:1/Fs:T; % Generate the time vector
    y = sin(2*pi*f*t); % Generate the sinusoidal waveform

    BpodSystem.Status.trial = 1;
    BpodSystem.Status.consecutiveRatSkips = 0;
    BpodSystem.Status.ExitTrialLoop = false; % session end 
    
    % FOR ALTERNATION: 
    BpodSystem.Status.switchStimulusFlag = false; % used to indicate when middle stimulus should switch
    BpodSystem.Status.currentTrialType = nan; % tracking current trial type (0 = water, 1 = odor)
    BpodSystem.Status.numberNonconsecutiveCorrect = 0; 
    BpodSystem.Status.iOdorTrial = 1; % for iterating odor trial variables
    BpodSystem.Status.iWaterTrial = 1; % for iterating water trial variables

    % Organizing what to save to data structure
    BpodSystem.Data.condition = ''; 
    BpodSystem.Data.correctTrials = nan(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.correctPort = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.centerValve = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.rewardLick = zeros(expV.MAXIMUM_TRIALS, 1);
    BpodSystem.Data.trialsEngaged = zeros(expV.MAXIMUM_TRIALS, 1);

    % Saving ExperimentVariables
    propNames = properties(expV); propValues = cell(size(propNames));
    for i = 1:numel(propNames); propValues{i} = expV.(propNames{i}); end
    expVarTable = cell2table(propValues,'RowNames', propNames, 'VariableNames', {'Value'}); % Convert to table
    BpodSystem.Data.experimentVariables = expVarTable; % Save table to structure

    % Generating lineup for valve openings
    % FOR SIDE TRAINING valve orders assigned separately for odor and water trials, but only use one
    [waterValveLineup, odorValveLineup] = GenerateCenterLineup_SideTraining(); 
    
    % These values do not change for side training
    BpodSystem.Status.currentTrialType = expV.SIDE_TRAINING_STIMULUS; % track current trial type (0 = water, 1 = odor)
    trialType = []; 
    num_dryLicks = expV.REWARD_LICKS-1;
    center_valveDelay = expV.REWARD_VALVE_DELAY; 

    % configure the analog in. performed in configure_analog_in.m
    A = configure_analog_in();

    % Set up wave player
    W = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1);
    W.SamplingRate = Fs;
    W.loadWaveform(1, y); % Loads a sound as waveform 1

    %% LOAD ProtocolSettings
    S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
    subj = BpodSystem.GUIData.SubjectName;
    if isempty(fieldnames(S)) % If running this protocol for the first time with this subject
        dir = ['C:\Users\Chad Samuelsen\Documents\Github\Bpod Local\Data\',subj,'\Set_exp_parameters\Session Settings\DefaultSettings.mat'];
        temp = load(dir);
        S = temp.ProtocolSettings; clear temp;
        
        BpodSystem.ProtocolSettings = S;
    end

    % UPDATE valve open times 
    S = update_valve_open_times(S, [1, expV.VALVE_SET1, expV.VALVE_SET2, 8]);
    
    % Save protocol settings (after updating valve timings)
    BpodSystem.ProtocolSettings = S;
    SaveProtocolSettings(BpodSystem.ProtocolSettings)
    
    BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

    % GET CONDITION FOR CURRENT SUBJECT
    conditions = S.GUIMeta.CONDITION_CODE.String;
    if ~any(contains(conditions, "null")); error('Error: no condition selected for this subject. '); end
    SUBJECT_CONDITION_CODE = conditions(~contains(conditions, "null")); 
    BpodSystem.Data.condition = SUBJECT_CONDITION_CODE;
    
    port_1 = LateralPort(1); % port_1 is the instance of the class Port1
    port_3 = LateralPort(3); % port_3 is the instance of the class Port3
    center_port = CenterPort; % center_port the instance of the class center_port
    correct_port = PortHandler; % PortHandler takes properties of whichever port is correct for that trial
    incorrect_port = PortHandler;

    % Save valve open times
    valveID = ["Valve1"; "Valve2"; "Valve3"; "Valve4"; "Valve5"; "Valve6"; "Valve7";  "Valve8"];
    valveOpenTimes = [BpodSystem.ProtocolSettings.GUI.open_time_1; BpodSystem.ProtocolSettings.GUI.open_time_2; ...
        BpodSystem.ProtocolSettings.GUI.open_time_3; BpodSystem.ProtocolSettings.GUI.open_time_4; ...
        BpodSystem.ProtocolSettings.GUI.open_time_5; BpodSystem.ProtocolSettings.GUI.open_time_6; 
        BpodSystem.ProtocolSettings.GUI.open_time_7; BpodSystem.ProtocolSettings.GUI.open_time_8];
    BpodSystem.Data.valveOpenTimes = table(valveID,valveOpenTimes); % This time is in ms
    
    totalValveWindow = ceil(mean(valveOpenTimes)/100)*100; % round up to nearest 100 ms to set stim window
    fullStimWindow = (totalValveWindow/1000) + expV.STIMULUS_WINDOW; % convert totalValve window to seconds
    BpodSystem.Data.fullStimulusWindow = fullStimWindow; 

    % Print to command window the start of the Session
    disp(['Subject Name: ' subj]);
    disp(['Condition: ' char(SUBJECT_CONDITION_CODE)]);
    fprintf('Date and time: %s\n',datetime("now"))
    fprintf('Valve Durations: '); 
    for iValves=1:length(valveID); fprintf('%s=%.1fms. ',num2str(iValves),valveOpenTimes(iValves)); end
    fprintf('\nSTIMULUS: ')

    %% MAIN TRIAL LOOP
    % do MAXIMUM_TRIALS as defined in ExperimentVariables file if 60 minutes has not elapsed.
    for trial = 1:expV.MAXIMUM_TRIALS
        
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        %% Get parameters for the current trial and save

        % Get trial parameters according to trial type
        if BpodSystem.Status.currentTrialType == 0 % WATER trial
            waterTrial = BpodSystem.Status.iWaterTrial; trialType = 'WATER';
            % Get center valve for this trial
            center_stimulus_valve = waterValveLineup(waterTrial);
            BpodSystem.Status.iWaterTrial = waterTrial + 1; % iterate
        elseif BpodSystem.Status.currentTrialType == 1 % ODOR trial
            odorTrial = BpodSystem.Status.iOdorTrial; trialType = 'ODOR';
            % Get center valve for this trial
            center_stimulus_valve = odorValveLineup(odorTrial);
            BpodSystem.Status.iOdorTrial = odorTrial + 1; % Iterate 
        end
        
        % Set center valve and correct port -> WHERE CORRECT CHOICE IS DEFINED
        center_port = center_port.setValve(1, center_stimulus_valve);
        correct_port = correct_port.setCorrect(port_1, port_3, center_stimulus_valve, expV.VALVE_SET1, expV.VALVE_SET2, ...
            SUBJECT_CONDITION_CODE);
        incorrect_port = incorrect_port.setIncorrect(port_1, port_3, center_stimulus_valve, expV.VALVE_SET1, expV.VALVE_SET2, ...
            SUBJECT_CONDITION_CODE);

        % If stimuli switched (or first trial), print new lateral ports and reset flag
        if trial == 1
            fprintf('%s. Correct=port%d. Incorrect=port%d. \n',trialType,correct_port.port, incorrect_port.port);
        end

        % new trial *block*, reset consecutiveRatSkips - not relevant for alternation 
        if (mod(trial, (expV.TRIALS_PER_BLOCK + 1)) == 0)
            BpodSystem.Status.consecutiveRatSkips = 0;
        end
        
        BpodSystem.Status.trial  = trial;
        BpodSystem.Data.centerValve(trial) = center_port.left_valve;
        BpodSystem.Data.correctPort(trial) = correct_port.port;
        BpodSystem.Data.rewardLick(trial) = num_dryLicks+1;

        fprintf('Trial %d: ', trial)
        fprintf('Center=valve%d. %d dry licks. %dms valve delay. ',center_stimulus_valve, num_dryLicks, center_valveDelay*1000);

        %% Assemble the State Machine for this Trial
        sma = NewStateMachine();

        % set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
        sma = SetGlobalTimer(sma, 'TimerID', expV.EXPERIMENT_TIMER_ID, 'Duration', expV.TOTAL_ALLOWED_TIME);
        sma = SetGlobalTimer(sma, 'TimerID', expV.LICK_WINDOW_TIMER_ID, 'Duration', expV.LICK_WINDOW); % time to do all dry licks
        sma = SetGlobalTimer(sma, 'TimerID', expV.STIM_WINDOW_TIMER_ID, 'Duration', fullStimWindow); % time after valve opens before door goes up

        % NOTE: global counters cannot be used for 1 dry lick. Changed structure for first 4 days of side training. 
        % set global counters for each of the possible input ports (AnalogIn1 ports 1-4). 
        % Arguments: (sma, CounterNumber, TargetEvent, Threshold)
        %sma = SetGlobalCounter(sma, center_port.LEFT_COUNTER_ID, center_port.LEFT_LICK_INPUT, num_dryLicks); 
        %sma = SetGlobalCounter(sma, center_port.RIGHT_COUNTER_ID, center_port.RIGHT_LICK_INPUT, num_dryLicks);
        %sma = SetGlobalCounter(sma, port_1.COUNTER_ID, port_1.LICK_INPUT, num_dryLicks); % Left Port licks
        %sma = SetGlobalCounter(sma, port_3.COUNTER_ID, port_3.LICK_INPUT, num_dryLicks); % Right Port licks

        %% Adding States
        % First trial only: add experiment global timer
        if (trial == 1)
            sma = AddState(sma, 'Name', 'triggerExperimentTimer', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'ITI_start'},...
                'OutputActions',{'GlobalTimerTrig', expV.EXPERIMENT_TIMER_ID});
        end

        %%%%% TRIAL START %%%%%
        sma = AddState(sma, 'Name', 'ITI_start', ...
            'Timer', (expV.ITI_TIME-3),...
            'StateChangeConditions', {'Tup', 'TTC_Center', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.UP});
        sma = AddState(sma, 'Name', 'TTC_Center', ...
            'Timer', expV.TTC_CENTER_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', center_port.LEFT_LICK_INPUT, 'firstCenterLick', ...
            expV.experimentTimeExpired, 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'WavePlayer1', ['P' 8 0]});
        sma = AddState(sma, 'Name', 'firstCenterLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitCenterRewardLick', expV.experimentTimeExpired, 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});
        sma = AddState(sma, 'Name', 'waitCenterRewardLick', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LEFT_LICK_INPUT, 'delayCenterValve', expV.experimentTimeExpired, ...
            'cleanup', expV.lickTimeExpired , 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'delayCenterValve', ...
            'Timer', center_valveDelay,...
            'StateChangeConditions', {'Tup', 'openCenterValve'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve', ...
            'Timer', center_port.left_valve_time,...
            'StateChangeConditions', {'Tup', 'closeCenterValve'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.left_valve], ...
            'GlobalTimerTrig', expV.STIM_WINDOW_TIMER_ID});
        sma = AddState(sma, 'Name', 'closeCenterValve', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitRemainingCenterTime'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.left_valve]});
        sma = AddState(sma, 'Name', 'waitRemainingCenterTime', ...
            'Timer', 0,...
            'StateChangeConditions', {expV.stimTimeExpired, 'ttcLateralTimeout', expV.lickTimeExpired, 'ttcLateralTimeout'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});

        %%%%% BEGIN TTC ON THE LATERAL PORTS %%%%%
        sma = AddState(sma, 'Name', 'ttcLateralTimeout', ...
            'Timer', expV.DELAY_TIME,...
            'StateChangeConditions', {'Tup', 'ttcLateral', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{center_port.DOOR, expV.UP});
        sma = AddState(sma, 'Name', 'ttcLateral', ...
            'Timer', expV.TTC_LATERAL_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', correct_port.lick_input, 'firstLateralLick', incorrect_port.lick_input,...
            'waitFinalIncorrectLick', expV.experimentTimeExpired , 'cleanup'},...
            'OutputActions',{correct_port.door, expV.DOWN});
        sma = AddState(sma, 'Name', 'firstLateralLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick'},...
            'OutputActions',{correct_port.door, expV.DOWN, 'SoftCode', 3, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});
        sma = AddState(sma, 'Name', 'waitLateralRewardLick', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.lick_input, 'openLateralReward', expV.experimentTimeExpired , 'cleanup'...
            expV.lickTimeExpired, 'reportSkip'},...
            'OutputActions',{correct_port.door, expV.DOWN});
        sma = AddState(sma, 'Name', 'openLateralReward', ...
            'Timer', correct_port.valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralReward'},...
            'OutputActions',{correct_port.door, expV.DOWN, 'ValveModule1', ['O', correct_port.valve], ...
            'GlobalTimerTrig', expV.STIM_WINDOW_TIMER_ID});
        sma = AddState(sma, 'Name', 'closeLateralReward', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitRemainingLateralTime'},...
            'OutputActions',{correct_port.door, expV.DOWN, 'ValveModule1', ['C', correct_port.valve]});
        sma = AddState(sma, 'Name', 'waitRemainingLateralTime', ...
            'Timer', 0,...
            'StateChangeConditions', {expV.stimTimeExpired, 'ITI_end', expV.lickTimeExpired, 'ITI_end'},...
            'OutputActions',{correct_port.door, expV.DOWN});
        sma = AddState(sma, 'Name', 'waitFinalIncorrectLick', ...
            'Timer', 0,...
            'StateChangeConditions', {incorrect_port.lick_input, 'reportIncorrect', ...
            expV.experimentTimeExpired , 'cleanup', expV.lickTimeExpired, 'reportSkip'},...
            'OutputActions',{correct_port.door, expV.DOWN});
        sma = AddState(sma, 'Name', 'reportIncorrect', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_punish'},...
            'OutputActions',{'SoftCode', 14});
        sma = AddState(sma, 'Name', 'reportSkip', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_punish'},...
            'OutputActions',{'SoftCode', 2});
        sma = AddState(sma, 'Name', 'ITI_end', ...
            'Timer', 3,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{correct_port.door, expV.UP, 'SoftCode', 15});
        sma = AddState(sma, 'Name', 'ITI_punish', ...
            'Timer', (expV.PUNISHMENT_TIME+3),...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{correct_port.door, expV.UP});
        
        %%%%% TRIAL END - reset counters %%%%%
        % sma = AddState(sma, 'Name', 'resetCorrectCounter', ...
        %     'Timer', 0,...
        %     'StateChangeConditions', {'Tup', 'resetIncorrectCounter'},...
        %     'OutputActions',{'GlobalCounterReset', correct_port.lick_counter_id});
        % sma = AddState(sma, 'Name', 'resetIncorrectCounter', ...
        %     'Timer', 0,...
        %     'StateChangeConditions', {'Tup', 'resetCenterCounter'},...
        %     'OutputActions',{'GlobalCounterReset', incorrect_port.lick_counter_id});
        % sma = AddState(sma, 'Name', 'resetCenterCounter', ...
        %     'Timer', 0,...
        %     'StateChangeConditions', {'Tup', 'exit'},...
        %     'OutputActions',{'GlobalCounterReset', center_port.LEFT_COUNTER_ID});
        
        %%%%% SESSION END %%%%%
        sma = AddState(sma, 'Name', 'cleanup', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{port_1.DOOR, expV.UP, port_3.DOOR, expV.UP, 'ValveModule1', ['B' 00000000], 'SoftCode', 1});

        % function will check if softcode '1' has been sent by the state machine in cleanup state. 
        % if it has, it is time to exit the trial loop (end of session).

        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

        %% Send description to the Bpod State Machine device
        SendStateMachine(sma);

        % Run the trial
        events = RunStateMachine();
        if ~isempty(fieldnames(events)) % If you didn't stop the session manually mid-trial
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, events); % Adds raw events to a human-readable data struct
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

        fprintf('\n')

        if (BpodSystem.Status.ExitTrialLoop || BpodSystem.Status.BeingUsed == 0 || trial == expV.MAXIMUM_TRIALS)
            stop_experiment(A, W);
            sessionSummary();
            return
        end
    end
end
