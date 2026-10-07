
%% TESTING PROTOCOL V3.6 | TWO OPERANT RESPONSE TASK
% Main protocol function for behavioral testing using the two-operant response task for retronasal/oral odor detection.
%
% Description:
%   The two operant response task requires a 3-port behavioral rig. The main task is broken into (1) a sampling period
%   at the center port, (2) a brief delay after the center door closes, (3) opening of the 2 lateral doors for the
%   animal to make a choice by licking one side. This protocol also includes a sequence of states during the intertrial
%   interval (ITI) which allow for the center spout to be cleared, rinsed, and loaded with the stimulus for the upcoming
%   trial.
%
%   This requires a center spout connected to a multi-channel manifold with a rinse and a gas line. The inside of
%   the spout contains a single shared channel for all stimuli. Stimuli are loaded from the manifold and rinsed out
%   with gas and water. Rinse and waste stimuli are cleared by a waste vacuum positioned in front of the spout.
%
%   Lateral and center driver valves should be calibrated for 5 uL pulses in ~70 ms for delivering stimuli.
%   Stimulus and rinse valves should be calibrated for 100-600 uL pulses in ~1000-3000 ms for stimulus loading
%   and rinse.
%
% V3.6 Update:
%   All stimuli at the center port are delivered using a single "Driver" valve. Cleaning up code layout.

% This protocol calls the following custom functions (all others are from Bpod or MATLAB):
%   Located in the current protocol folder (...\Bpod Local\Protocols\testing_v3):
%      ExperimentVariables     % Holds parameters for the current session (e.g. state timing and valve assignments).
%      GenerateTrialOrder      % Generates the order of trials for each stimulus type and stimulus valve.
%      Port                    % Holds properties for each of the 3 ports. These are static throughout the session.
%      PortTrialManager        % Assigns properties from the lateral ports to the correct and incorrect ports for each
%                                trial.
%      SoftCodeHandler         % Prints trial information to the MATLAB command window.
%   Located in the general protocol functions folder (...\Bpod Local\General Functions): 
%      currentDayConditions    % Called by ExperimentVariables. Gets updated valve/stimulus assignments (rotated daily).
%      elapsedTime             % Allows MATLAB check the duration of the session.
%      updateValveTimes        % Updates valve times according to the current calibration values (for driver valves).
%      sessionSummary          % Called at the end of the session to provide basic results.
%   Nested functions (located inside the main function towards the end of this script): 
%      addToBpodData           % Organizes and adds info to BpodSystem.Data to be saved at the end of the session.  
%      ConfigureBpodModules    % Sets up the ValveDriver, AnalogIn, and WavePlayer Modules. 

% Original code written by Blake Hourigan for Samuelsen Lab, University of Louisville.
% V2 code and beyond edited/written by Timothy Vladimir Dong for Samuelsen Lab, University of Louisville.

%% Main Protocol Function
function testing_v3

    %% SESSION SETUP
    % Getting experiment constant variables and generating the trial order. 

    global BpodSystem % Imports the BpodSystem object to the function workspace
    
    expV = ExperimentVariables(); %expV is used to access experiment constants from the ExperimentVariables function

    BpodSystem.Status.trial = 1;
    BpodSystem.Status.ExitTrialLoop = false; % set to true for session to end
    BpodSystem.Status.switchStimulusFlag = false; % used to trigger center stimulus switch (for alternation training).

    % Generating trial order (determines the stimulus and vale for each trial)
    [trial_order, center_stim_valve_order] = GenerateTrialOrder(); % Protocol function. Returns trial order.

    %% LOAD and UPDATE ProtocolSettings and Get Valve Timings
    S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
    subject = BpodSystem.GUIData.SubjectName;
    if isempty(S) || isempty(fieldnames(S)) % If running this protocol for the first time with this subject, or if settings cannot be found
        dir = ['C:\Users\Chad Samuelsen\Documents\Github\Bpod Local\Data\',subject,'\Set_exp_parameters\Session Settings\DefaultSettings.mat'];
        temp = load(dir);
        S = temp.ProtocolSettings; clear temp;
        BpodSystem.ProtocolSettings = S;
    end

    % UPDATE valve open times
    deliveryValves = sort([expV.LEFT_VALVE, expV.CENTER_DRIVER_VALVE, expV.RIGHT_VALVE]); % Valves for delivering stimuli
    centerStimValves = [expV.CENTER_VALVE_SET1, expV.CENTER_VALVE_SET2]; % Valves for loading center port stimuli
    S = updateValveTimes(S, deliveryValves, expV.STIM_VOLUME);

    % save delivery valve open times to session data
    valveID = strings(size(deliveryValves))';
    valveStimTimes = zeros(size(deliveryValves))';
    for iValve = 1:length(deliveryValves)
        valveID(iValve) = ['Valve', num2str(deliveryValves(iValve))];
        time_variable_name = sprintf('open_time_%d', deliveryValves(iValve));
        valveStimTimes(iValve) = round(BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000, 4);
    end

    % Get valve times for priming, loading, and rinse
    % Make sure the values allow for full ITI
    valvePrimingTime = round(mean(GetValveTimes(expV.PRIMING_VOLUME, centerStimValves)), 3);
    valveLoadingTime = round(mean(GetValveTimes(expV.LOAD_VOLUME, centerStimValves)), 3);
    valveRinseTime = round(GetValveTimes(expV.RINSE_VOLUME, expV.RINSE_VALVE), 3);
    if (expV.ITI_TIME - expV.ITI_ENDTIME) < (valvePrimingTime + valveLoadingTime + (2*valveRinseTime) + (4*expV.GAS_TIME) + 1)
        error('Error: calibration values for rinse and preloading are incompatible with this protocol. ');
    end

    % Save protocol settings (after updating valve timings)
    BpodSystem.ProtocolSettings = S;
    SaveProtocolSettings(BpodSystem.ProtocolSettings)
    BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

    % GET CONDITION FOR CURRENT SUBJECT
    condition = S.GUIMeta.CONDITION_CODE.String;
    if ~any(contains(condition, "null")); error('Error: no condition selected for this subject. '); end
    SUBJECT_CONDITION_CODE = condition(~contains(condition, "null"));

    %% Generate port instances
    % port 1 = LEFT, port 2 = CENTER, port 3 = RIGHT

    % Instances of each port class are constant throughout the session.
    left_port = Port(1, expV.LEFT_VALVE, valveStimTimes(deliveryValves == expV.LEFT_VALVE));
    center_port = Port(2, expV.CENTER_DRIVER_VALVE, valveStimTimes(deliveryValves == expV.CENTER_DRIVER_VALVE));
    right_port = Port(3, expV.RIGHT_VALVE, valveStimTimes(deliveryValves == expV.RIGHT_VALVE));

    % Instances of the PortTrialManager class receive the properties of the left or right ports according to the trial.
    % This determines which port is correct or incorrect for each trial.
    correct_port = PortTrialManager; % Recieves properties of the "correct" port for the current trial. 
    incorrect_port = PortTrialManager; % Receives properties of the "incorrect" port for the current trial. 
    
    addToBpodData(); % Adds session information to BpodSystem.Data to be saved (starts at the end of the first trial). 

    %% Configure valve, analog in, and waveplayer modules
    % The ValveModule manages the valve open/closed states. 
    % AnalogInModule records licking and generates events. 
    % WavePlayerModule produces tones. 
    [ValveModule, AnalogInModule, WavePlayerModule] = ConfigureBpodModules(); % configure Bpod modules
    
    % Start the oscilliscope gui to view capacitance sensor inputs.
    AnalogInModule.scope();
    AnalogInModule.scope_StartStop();

    %% PRINT SESSION START INFO TO COMMAND WINDOW
    disp(['Subject Name: ' subject]);
    disp(['Condition: ' char(SUBJECT_CONDITION_CODE)]);
    fprintf('Date and time: %s\n', datetime("now"));
    disp(['Water valves: [', num2str(expV.CENTER_VALVE_SET1), ...
          ']. Odor valves: [', num2str(expV.CENTER_VALVE_SET2), '].']);
    fprintf(['Valve Durations (' num2str(expV.STIM_VOLUME) 'ul): ']);
    for iValves = 1:length(valveID)
        fprintf('%s=%.1fms. ', valveID(iValves), valveStimTimes(iValves)*1000);
    end
    fprintf(['\nPriming: ' num2str(expV.PRIMING_VOLUME) 'ul, ' num2str(valvePrimingTime) 's. ']);
    fprintf(['Load: ' num2str(expV.LOAD_VOLUME) 'ul, ' num2str(valveLoadingTime) 's. ']);
    fprintf(['Rinse: ' num2str(expV.RINSE_VOLUME) 'ul, ' num2str(valveRinseTime) 's per pulse (x2 pulses). \n']);

    % Reset and start session timer (persistent function)
    clear elapsedTime; % Make sure session timer starts at 0. 
    elapsedTime; % First call to start timer. 

    %% MAIN TRIAL LOOP
    % Loops until one end conditions are met (trial number, session time, or manually stopped). 
    for trial = 1:expV.MAXIMUM_TRIALS

        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

        %% Get parameters for the current trial and save to variables
        BpodSystem.Status.trial  = trial;
        fprintf('Trial %d: ', trial)

        if trial_order(trial) == 0
            fprintf('Water trial. ');
        else
            fprintf('Odor trial.  ');
        end

        % Get center valve and set correct/incorrect ports based on the trial type and condition
        center_stimulus_valve = center_stim_valve_order(trial); % Get center valve for this trial
        correct_port = correct_port.setCorrect(left_port, right_port, ...
            center_stimulus_valve, expV.CENTER_VALVE_SET1, expV.CENTER_VALVE_SET2, ...
            SUBJECT_CONDITION_CODE);
        incorrect_port = incorrect_port.setIncorrect(left_port, right_port, ...
            center_stimulus_valve, expV.CENTER_VALVE_SET1, expV.CENTER_VALVE_SET2, ...
            SUBJECT_CONDITION_CODE);

        BpodSystem.Data.summary.correctPort(trial) = correct_port.PORT;
        fprintf(['Center=valve', num2str(center_stimulus_valve), '. Correct=port', num2str(correct_port.PORT),'. ']);

        %% Assemble the State Machine for this Trial
        sma = NewStateMachine();

        % Global timers: ITI timer and lick window timer
        sma = SetGlobalTimer(sma, 'TimerID', expV.ITI_TIMER_ID, 'Duration', ...
            (expV.ITI_TIME - expV.ITI_ENDTIME)); % The ITI timer does not include ITI_ENDTIME
        sma = SetGlobalTimer(sma, 'TimerID', expV.LICK_WINDOW_TIMER_ID, 'Duration', ...
            expV.LICK_WINDOW); % 2 seconds to get all licks

        % Global counters for each of port (AnalogIn1 ports 1-3)
        sma = SetGlobalCounter(sma, left_port.COUNTER_ID, left_port.LICK_ONSET, 3);
        sma = SetGlobalCounter(sma, center_port.COUNTER_ID, center_port.LICK_ONSET, 3);
        sma = SetGlobalCounter(sma, right_port.COUNTER_ID, right_port.LICK_ONSET, 3);

        %% Adding States

        %%%% MAIN ITI: GAS CLEARING, WATER RINSE, AND STIMULUS LOADING %%%%%
        % trialStart: make sure all doors are up and all valves are closed.
        sma = AddState(sma, 'Name', 'trialStart', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_gasClear1'},...
            'OutputActions', {left_port.DOOR, expV.UP, center_port.DOOR, expV.UP, right_port.DOOR, expV.UP, ...
            'ValveModule1', ['B' 0], expV.GAS_VALVE, 0});
        % ITI_gasClear1: clear center port with gas and start ITI timer
        sma = AddState(sma, 'Name', 'ITI_gasClear1', ...
            'Timer', expV.GAS_TIME,...
            'StateChangeConditions', {'Tup', 'ITI_gasDelay1'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 1,'GlobalTimerTrig', expV.ITI_TIMER_ID});
         % ITI_gasDelay1: pause after gas to allow pressure to rebalance
        sma = AddState(sma, 'Name', 'ITI_gasDelay1', ...
            'Timer', expV.GAS_DELAY,...
            'StateChangeConditions', {'Tup', 'ITI_rinse1'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0});
        % ITI_rinse1: first water rinse
        sma = AddState(sma, 'Name', 'ITI_rinse1', ...
            'Timer', valveRinseTime,...
            'StateChangeConditions', {'Tup', 'ITI_gasClear2'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0, 'ValveModule1', ['O' expV.RINSE_VALVE]});
        % ITI_gasClear2: clear first rinse with gas
        sma = AddState(sma, 'Name', 'ITI_gasClear2', ...
            'Timer', expV.GAS_TIME,...
            'StateChangeConditions', {'Tup', 'ITI_gasDelay2'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 1, 'ValveModule1', ['C' expV.RINSE_VALVE]});
        % ITI_gasDelay2: pause after gas
        sma = AddState(sma, 'Name', 'ITI_gasDelay2', ...
            'Timer', expV.GAS_DELAY,...
            'StateChangeConditions', {'Tup', 'ITI_rinse2'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0});
        % ITI_rinse2: second water rinse
        sma = AddState(sma, 'Name', 'ITI_rinse2', ...
            'Timer', valveRinseTime,...
            'StateChangeConditions', {'Tup', 'ITI_gasClear3'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0, 'ValveModule1', ['O' expV.RINSE_VALVE]});
        % ITI_gasClear3: clear second rinse with gas
        sma = AddState(sma, 'Name', 'ITI_gasClear3', ...
            'Timer', expV.GAS_TIME,...
            'StateChangeConditions', {'Tup', 'ITI_gasDelay3'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 1, 'ValveModule1', ['C' expV.RINSE_VALVE]});
        % ITI_gasDelay3: pause after gas
        sma = AddState(sma, 'Name', 'ITI_gasDelay3', ...
            'Timer', expV.GAS_DELAY,...
            'StateChangeConditions', {'Tup', 'ITI_stimPriming'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0});
        % ITI_stimPriming: prime center spout with the next stimulus
        sma = AddState(sma, 'Name', 'ITI_stimPriming', ...
            'Timer', valvePrimingTime,...
            'StateChangeConditions', {'Tup', 'ITI_stimPrimingDelay'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0, 'ValveModule1', ['O' center_stimulus_valve]});
        % ITI_stimPrimingDelay: close priming valve, allow stimulus to settle
        sma = AddState(sma, 'Name', 'ITI_stimPrimingDelay', ...
            'Timer', expV.PRIMING_DELAY,...
            'StateChangeConditions', {'Tup', 'ITI_gasClear4'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0, 'ValveModule1', ['C' center_stimulus_valve]});
        % ITI_gasClear4: clear priming slug with gas
        sma = AddState(sma, 'Name', 'ITI_gasClear4', ...
            'Timer', expV.GAS_TIME,...
            'StateChangeConditions', {'Tup', 'ITI_gasDelay4'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 1});
        % ITI_gasDelay4: pause after gas
        sma = AddState(sma, 'Name', 'ITI_gasDelay4', ...
            'Timer', expV.GAS_DELAY,...
            'StateChangeConditions', {'Tup', 'ITI_stimLoad'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0});
        % ITI_stimLoad: final stimulus loading in the center spout
        sma = AddState(sma, 'Name', 'ITI_stimLoad', ...
            'Timer', valveLoadingTime,...
            'StateChangeConditions', {'Tup', 'ITI_waitForRemaining'},...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0, 'ValveModule1', ['O' center_stimulus_valve]});
        % ITI_waitForRemaining: wait for ITI timer to finish and start the trial 
        sma = AddState(sma, 'Name', 'ITI_waitForRemaining', ...
            'Timer', 0,...
            'StateChangeConditions', {expV.ITI_TIMER_END, 'TTC_Center'},...
            'OutputActions',{center_port.DOOR, expV.UP, 'ValveModule1', ['C' center_stimulus_valve], ...
            'GlobalCounterReset', center_port.COUNTER_ID});

        %%%%% CENTER PORT: SAMPLING PHASE %%%%%
        % Center port door opens, wait for lick or timeout
        sma = AddState(sma, 'Name', 'TTC_Center', ...
            'Timer', expV.TTC_CENTER_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', center_port.LICK_ONSET, 'waitCenterDryLicks'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'AnalogIn1', ['#' 0], 'WavePlayer1', ['P' 8 0]});
        % Wait for 3 dry licks at the center port
        sma = AddState(sma, 'Name', 'waitCenterDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.COUNTER_EVENT, 'waitCenterSampleLick1', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});
        
        % SAMPLING: deliver 3 pulses of the center stimulus, each triggered by lick offset at the center port. 
        sma = AddState(sma, 'Name', 'waitCenterSampleLick1', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LICK_OFFSET, 'openCenterValve1', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve1', ...
            'Timer', center_port.VALVE_TIME,...
            'StateChangeConditions', {'Tup', 'closeCenterValve1'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCenterValve1', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitCenterSampleLick2'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitCenterSampleLick2', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LICK_OFFSET, 'openCenterValve2', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve2', ...
            'Timer', center_port.VALVE_TIME,...
            'StateChangeConditions', {'Tup', 'closeCenterValve2'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCenterValve2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitCenterSampleLick3'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitCenterSampleLick3', ...
            'Timer', 0,...
            'StateChangeConditions', {center_port.LICK_OFFSET, 'openCenterValve3', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve3', ...
            'Timer', center_port.VALVE_TIME,...
            'StateChangeConditions', {'Tup', 'closeCenterValve3'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCenterValve3', ...
            'Timer', expV.STIMULUS_WINDOW,...
            'StateChangeConditions', {'Tup', 'Delay', expV.LICK_WINDOW_TIMER_END, 'Delay'},...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.VALVE]});

        %%%%% LATERAL PORT: RESPONSE PHASE %%%%%
        % Delay: waiting before lateral ports open
        sma = AddState(sma, 'Name', 'Delay', ...
            'Timer', expV.DELAY_TIME,...
            'StateChangeConditions', {'Tup', 'TTC_Lateral'},...
            'OutputActions',{center_port.DOOR, expV.UP, 'GlobalCounterReset', incorrect_port.COUNTER_ID});
        % Open both lateral doors, wait for first lick on either lateral port
        sma = AddState(sma, 'Name', 'TTC_Lateral', ...
            'Timer', expV.TTC_LATERAL_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', correct_port.LICK_ONSET, 'waitLateralDryLicks', ...
            incorrect_port.LICK_ONSET, 'waitLateralDryLicks'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'GlobalCounterReset', correct_port.COUNTER_ID});
        % Wait for 3 dry licks on chosen port
        sma = AddState(sma, 'Name', 'waitLateralDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.COUNTER_EVENT, 'waitLateralRewardLick1', incorrect_port.COUNTER_EVENT, ...
            'waitFinalIncorrectLick', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});
        
        % If correct choice: deliver 3 reward pulses, each triggered by lick offset
        sma = AddState(sma, 'Name', 'waitLateralRewardLick1', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.LICK_OFFSET, 'openCorrectValve1', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCorrectValve1', ...
            'Timer', correct_port.VALVE_TIME,...
            'StateChangeConditions', {'Tup', 'closeCorrectValve1'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'ValveModule1', ['O', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCorrectValve1', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick2'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitLateralRewardLick2', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.LICK_OFFSET, 'openCorrectValve2', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCorrectValve2', ...
            'Timer', correct_port.VALVE_TIME,...
            'StateChangeConditions', {'Tup', 'closeCorrectValve2'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'ValveModule1', ['O', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCorrectValve2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick3'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitLateralRewardLick3', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.LICK_OFFSET, 'openCorrectValve3', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCorrectValve3', ...
            'Timer', correct_port.VALVE_TIME,...
            'StateChangeConditions', {'Tup', 'closeCorrectValve3'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'ValveModule1', ['O', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCorrectValve3', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_correctTrialEnd', expV.LICK_WINDOW_TIMER_END, 'ITI_correctTrialEnd'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN, 'ValveModule1', ['C', correct_port.VALVE]});
        % Correct trial end: raise doors, send SoftCode 15
        sma = AddState(sma, 'Name', 'ITI_correctTrialEnd', ...
            'Timer', expV.ITI_ENDTIME,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{left_port.DOOR, expV.UP, right_port.DOOR, expV.UP, 'SoftCode', 15});
        
        % If incorrect choice: wait for final lick, then report incorrect and go to punish
        sma = AddState(sma, 'Name', 'waitFinalIncorrectLick', ...
            'Timer', 0,...
            'StateChangeConditions', {incorrect_port.LICK_ONSET, 'reportIncorrect', expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{left_port.DOOR, expV.DOWN, right_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'reportIncorrect', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_punishTrialEnd'},...
            'OutputActions',{'SoftCode', 14});
        
        % If trial is skipped, report skipped trial and go to punish
        sma = AddState(sma, 'Name', 'reportSkip', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI_punishTrialEnd'},...
            'OutputActions',{'SoftCode', 2});
        
        % Punishment for incorrect/skipped trial end: raise doors, extra gas clear, extra ITI
        sma = AddState(sma, 'Name', 'ITI_punishTrialEnd', ...
            'Timer', expV.ITI_ENDTIME,...
            'StateChangeConditions', {'Tup', 'ITI_punishExtraGasClear'},...
            'OutputActions',{left_port.DOOR, expV.UP, right_port.DOOR, expV.UP});
        sma = AddState(sma, 'Name', 'ITI_punishExtraGasClear', ...
            'Timer', expV.GAS_TIME,...
            'StateChangeConditions', {'Tup', 'ITI_punish'},...
            'OutputActions',{left_port.DOOR, expV.UP, right_port.DOOR, expV.UP, expV.GAS_VALVE, 1});
        sma = AddState(sma, 'Name', 'ITI_punish', ...
            'Timer', (expV.PUNISHMENT_TIME - expV.GAS_TIME),...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{left_port.DOOR, expV.UP, right_port.DOOR, expV.UP, 'ValveModule1', ['B' 0], expV.GAS_VALVE, 0});

        %%%%% TRIAL END %%%%%

        % Assign the softcode function to print output to MATLAB during each trial
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

        %% Send state machine description for this trial to the Bpod State Machine device and run 
        SendStateMachine(sma); % Sends the constructed state machine program to the Bpod machine
        events = RunStateMachine(); % Tells the Bpod machine to run the currently loaded state machine program
        
        %% Save raw events once Bpod completes running the trial
        if ~isempty(fieldnames(events)) % If you didn't stop the session manually mid-trial
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, events); % Adds raw events to a human-readable data struct
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file path
            fprintf('\n'); 
        end

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

        % Check if experiment ends (checks duration, trial number, and other stop conditions)
        t = elapsedTime;
        if (BpodSystem.Status.ExitTrialLoop || BpodSystem.Status.BeingUsed == 0 || ...
                trial == expV.MAXIMUM_TRIALS || t > expV.TOTAL_ALLOWED_TIME)

            disp(['Experiment duration: ' num2str(t) 'sec.' ])
            clear elapsedTime; % Stop counting time from session start.

            AnalogInModule.scope_StartStop; % Close oscilloscope GUI
            AnalogInModule.endAcq; % Stop recording events (threshold crossings)
            AnalogInModule.stopReportingEvents; % Stop sending events to state machine
            ValveModule.isOpen = zeros(1,8); % Make sure all valves are closed
            clear AnalogInModule
            clear WavePlayerModule
            clear ValveModule

            sessionSummary(); % Prints basic session results to the MATLAB command window.
            return
        end
    end

    %% Nested Functions
    % These are divided into subfunctions just for organization and readability.

    % Function to add session info to BpodSystem.Data (helps with organization)
    function addToBpodData
        % Organizing what to save to BpodSystem data structure
        BpodSystem.Data.condition = SUBJECT_CONDITION_CODE;
        BpodSystem.Data.trialOrder.trialTypeOrder = trial_order;
        BpodSystem.Data.trialOrder.centerValveOrder = center_stim_valve_order;
        
        % save port properties
        BpodSystem.Data.portInfo.port1 = left_port;
        BpodSystem.Data.portInfo.port2 = center_port;
        BpodSystem.Data.portInfo.port3 = right_port;

        % Preallocating summary arrays
        BpodSystem.Data.summary.correctTrials = nan(expV.MAXIMUM_TRIALS, 1);
        BpodSystem.Data.summary.engagedTrials = nan(expV.MAXIMUM_TRIALS, 1);
        BpodSystem.Data.summary.correctPort = nan(expV.MAXIMUM_TRIALS, 1);

        % Saving ExperimentVariables
        propNames = properties(expV); propValues = cell(size(propNames));
        for i = 1:numel(propNames); propValues{i} = expV.(propNames{i}); end
        expVarTable = cell2table(propValues,'RowNames', propNames, 'VariableNames', {'Value'}); % Convert to table
        BpodSystem.Data.experimentVariables = expVarTable; % Save table to structure
        
        % Save calibrated valve times for stimulus drivers
        BpodSystem.Data.valveTimings.valveStimTimes = table(valveID, valveStimTimes); % time in seconds
        BpodSystem.Data.valveTimings.valvePrimingTime = valvePrimingTime;
        BpodSystem.Data.valveTimings.valveLoadingTime = valveLoadingTime;
        BpodSystem.Data.valveTimings.valveRinseTime = valveRinseTime;
    end

    function [V, A, W] = ConfigureBpodModules
        % Assert that each module is present + USB-paired (not necessary for ValveDriver)
        BpodSystem.assertModule({'ValveModule','AnalogIn','WavePlayer'}, [0 1 1]);

        %%% Configure Valve Driver Module for valve control
        V = ValveDriverModule(BpodSystem.ModuleUSB.ValveModule1); 
        
        %%% Configure Analog In Module to record and generate events from sensor input
        A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
        A.SamplingRate = 5000; % Set the sampling rate to 5kHz
        A.nActiveChannels = 3;
        % Enable event reporting on AnalogInput1. This sends lick 'events' to the state machine to be processed/counted.
        [A.InputRange{1:3}] = deal('0V:5V'); % Set input range
        A.SMeventsEnabled(1:3) = 1;
        % This sets threshold voltages that we want to cross to generate events.
        % Here we have 2 thresholds per channel, the first one for lick onset (5v) and the second for lick offset (1v)
        A.Thresholds = [5 5 5 5 0 0 0 0; 1 1 1 1 0 0 0 0];
        % ResetVoltages sets the voltage bound that must be crossed before a new event can be generated
        A.ResetVoltages = [1 1 1 1 0 0 0 0; 5 5 5 5 0 0 0 0];
        A.startReportingEvents(); % Tell the AnalogInput1 module to start reporting events to the state machine
        A.Stream2USB(1:3) = 1; % View all channels by default
        %behaviorDataFile = BpodSystem.Path.CurrentDataFile;
        %A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
        
        %%% Configure Wave Player to allow the AnalogOut Module to generate the trial starting tone. 
        % Variables for wave player
        Fs = 44100;    % Sampling rate in Hz (e.g., CD quality)
        T = .5;         % Duration in seconds
        f = 800;       % Frequency of the tone in Hz
        t = 0:1/Fs:T; % Generate the time vector
        y = sin(2*pi*f*t); % Generate the sinusoidal waveform
        W = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1);
        W.SamplingRate = Fs;
        W.loadWaveform(1, y); % Loads a sound as waveform 1
    end
end