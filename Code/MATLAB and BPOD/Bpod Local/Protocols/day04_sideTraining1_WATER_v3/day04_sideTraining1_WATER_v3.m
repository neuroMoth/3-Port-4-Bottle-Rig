
%% SIDE TRAINING 1 PROTOCOL V3 | WATER STIMULUS | TWO RESPONSE OPERANT TASK
% Protocol function for 1st side training using the two-response operant task for retronasal/oral odor detection. 
% 
% Center water, then only the correct side opens. 
%  - Order of stimulus columns is randomized. Stimulus is cleared and refilled during the ITI. 
%  - No rinse or priming steps, only stimulus loading. 
%  - Center delivery is always done by the driver valve.  
%  - 30 second TTC for sampling/center and 60 second for response/lateral. 
%
% Calibration: 
%  - Lateral and center driver valves should be calibrated for 5 uL pulses in ~70 ms for delivering stimuli.
%  - Stimulus valves should be calibrated for 100-200 uL pulses in ~1000-2500 ms for stimulus loading.

% This protocol calls the following custom functions (all others are from Bpod or MATLAB):
%   Located in the current protocol folder (...\Bpod Local\Protocols\testing_v3):
%      ExperimentVariables     % Holds parameters for the current session (e.g. state timing and valve assignments).
%      GenerateTrialOrder      % Generates the order of trials for each stimulus type and stimulus valve. Side and
%                                alternation training use a different version of this for valve order. 
%      Port                    % Holds properties for each of the 3 ports. These are static throughout the session.
%      PortTrialManager        % Assigns properties from the lateral ports to the correct and incorrect ports for each
%                                trial.
%      SoftCodeHandler         % Prints trial information to the MATLAB command window.
%   Located in the general protocol functions folder (...\Bpod Local\General Functions): 
%      elapsedTime             % Allows MATLAB check the duration of the session.
%      updateValveTimes        % Updates valve times according to the current calibration values (for driver valves).
%      sessionSummary          % Called at the end of the session to provide basic results.
%      setValveStimuli         % Is not called directly by the protocol, but sets up the valve stimulus assignments. 
%   Nested functions (located inside the main function towards the end of this script): 
%      addToBpodData           % Organizes and adds info to BpodSystem.Data to be saved at the end of the session.  
%      ConfigureBpodModules    % Sets up the ValveDriver, AnalogIn, and WavePlayer Modules. 

% Original code written by Blake Hourigan for Samuelsen Lab, University of Louisville.
% V2 code and beyond edited/written by Timothy Vladimir Dong for Samuelsen Lab, University of Louisville.

%% Main Protocol Function
function day04_sideTraining1_WATER_v3

    %% SESSION SETUP
    % Getting experiment constant variables and generating the trial order. 

    global BpodSystem % Imports the BpodSystem object to the function workspace
    
    expV = ExperimentVariables(); %expV is used to access experiment constants from the ExperimentVariables function

    BpodSystem.Status.trial = 1;
    BpodSystem.Status.ExitTrialLoop = false; % set to true for session to end
    BpodSystem.Status.switchStimulusFlag = false; % used to trigger center stimulus switch (for alternation training).
    
    % Generating trial order (determines the stimulus and vale for each trial)
    % FOR SIDE TRAINING: this is only used to shuffle the order of stimulus loading valves. 
    if expV.SIDE_TRAINING_STIMULUS == 1 % 1 for water
        [center_stim_valve_order, ~] = GenerateTrialOrder_SideAndAlternationTraining();
        sessionStimulus = 'Water'; 
    elseif expV.SIDE_TRAINING_STIMULUS == 2 % 2 for odor
        [~, center_stim_valve_order] = GenerateTrialOrder_SideAndAlternationTraining();
        sessionStimulus = 'Odor'; 
    end

    %% LOAD and UPDATE ProtocolSettings and Get Valve Timings
    ProtocolSettings = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace
    subject = BpodSystem.GUIData.SubjectName; % Saving the subject name from the graphical user interface (GUI)
    % If running this protocol for the first time with this subject, or if settings cannot be found
    if isempty(ProtocolSettings) || isempty(fieldnames(ProtocolSettings)) 
        dir = ['C:\Users\Chad Samuelsen\Documents\Github\Bpod Local\Data\',subject,'\Set_exp_parameters\Session Settings\DefaultSettings.mat'];
        temp = load(dir);
        ProtocolSettings = temp.ProtocolSettings; clear temp;
        BpodSystem.ProtocolSettings = ProtocolSettings;
    end

    % UPDATE valve open times
    deliveryValves = sort([expV.LEFT_VALVE, expV.CENTER_DRIVER_VALVE, expV.RIGHT_VALVE]); % Valves for delivering stimuli
    centerStimValves = [expV.CENTER_VALVE_SET1, expV.CENTER_VALVE_SET2]; % Valves for loading center port stimuli
    ProtocolSettings = updateValveTimes(ProtocolSettings, deliveryValves, expV.STIM_VOLUME);

    % save stimulus delivery valve open times to session data (saved from the protocol settings GUI)
    valveID = strings(size(deliveryValves))';
    valveStimTimes = zeros(size(deliveryValves))';
    for iValve = 1:length(deliveryValves)
        valveID(iValve) = ['Valve', num2str(deliveryValves(iValve))];
        time_variable_name = sprintf('open_time_%d', deliveryValves(iValve));
        valveStimTimes(iValve) = round(BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000, 4);
    end

    % Get valve time for stimulus loading
    % Make sure the values allow for full ITI
    valveLoadingTime = round(mean(GetValveTimes(expV.LOAD_VOLUME, centerStimValves)), 3);
    if (expV.ITI_TIME - expV.ITI_ENDTIME) < (valveLoadingTime + expV.GAS_TIME + expV.GAS_DELAY + 0.25)
        error('Error: calibration values for rinse and preloading are incompatible with this protocol. ');
    end

    % Save protocol settings (after updating valve timings)
    BpodSystem.ProtocolSettings = ProtocolSettings;
    SaveProtocolSettings(BpodSystem.ProtocolSettings); 
    BpodParameterGUI('init', ProtocolSettings); % initialize GUI to keep track of parameters

    % GET CONDITION FOR CURRENT SUBJECT
    condition = ProtocolSettings.GUIMeta.CONDITION_CODE.String;
    if ~any(contains(condition, "null")); error('Error: no condition selected for this subject. '); end
    SUBJECT_CONDITION_CODE = condition(~contains(condition, "null"));

    % Get current stimulus-valve assignments from valve_config.mat
    configFile = fullfile(fileparts(which('valve_config.mat')), 'valve_config.mat');
    if ~isfile(configFile)
        error(['Error: stimulus valve assignments not found (valve_config.mat). ' ...
            'Check general function setValveStimuli. ']);
    end
    valveConfig = load(configFile);

    %% Generate port instances
    % port 1 = LEFT, port 2 = CENTER, port 3 = RIGHT

    % Instances (the variables for each port below) of the Port class (which sets the properties for each port) are 
    % set up below and remain constant throughout the session. 
    left_port = Port(1, expV.LEFT_VALVE, valveStimTimes(deliveryValves == expV.LEFT_VALVE));
    center_port = Port(2, expV.CENTER_DRIVER_VALVE, valveStimTimes(deliveryValves == expV.CENTER_DRIVER_VALVE));
    right_port = Port(3, expV.RIGHT_VALVE, valveStimTimes(deliveryValves == expV.RIGHT_VALVE));

    % Instances of the PortTrialManager class receive the properties of the left or right ports according to the trial.
    % This determines which port is correct or incorrect for each trial.
    correct_port = PortTrialManager; % Recieves properties of the "correct" port for the current trial. 
    incorrect_port = PortTrialManager; % Receives properties of the "incorrect" port for the current trial. 
    
    addToBpodData(); % Adds session information to BpodSystem.Data to be saved (starts at the end of the first trial). 

    %% Configure valve, analog in, and waveplayer modules
    % Modules are additional microcontrollers which interface with the Bpod machine to record and control events. For
    % this protocol, three modules are required: 
    %   - The ValveModule1 manages the valve open/closed states. 
    %   - AnalogIn1 records licking and generates events. 
    %   - WavePlayer1 produces tones. 
    [ValveModule1, AnalogIn1, WavePlayer1] = ConfigureBpodModules(); % configure Bpod modules
    
    % Start the oscilliscope GUI to view capacitance sensor inputs.
    AnalogIn1.scope();
    AnalogIn1.scope_StartStop();

    %% PRINT SESSION START INFO TO COMMAND WINDOW
    disp(['Subject Name: ' subject]);
    disp(['Condition: ' char(SUBJECT_CONDITION_CODE)]);
    disp([sessionStimulus ' session. ']);
    fprintf('Date and time: %s\n', datetime("now"));
    disp(['Water valves: [', num2str(expV.CENTER_VALVE_SET1), ...
          ']. Odor valves: [', num2str(expV.CENTER_VALVE_SET2), ']. ', ...
          'Odor is ',  valveConfig.config.stimulus_slots{2}, '. ']);
    fprintf(['Valve Durations (' num2str(expV.STIM_VOLUME) 'ul): ']);
    for iValves = 1:length(valveID)
        fprintf('%s=%.1fms. ', valveID(iValves), valveStimTimes(iValves)*1000);
    end
    fprintf(['\nLoad: ' num2str(expV.LOAD_VOLUME) 'ul, ' num2str(valveLoadingTime) 's. \n']);

    % Reset and start session timer (persistent function)
    clear elapsedTime; % Make sure session timer starts at 0. 
    elapsedTime; % First call to start timer. 

    %% MAIN TRIAL LOOP
    % Loops until one end conditions are met (trial number, session time, or manually stopped). 
    for trial = 1:expV.MAXIMUM_TRIALS

        ProtocolSettings = BpodParameterGUI('sync', ProtocolSettings); % Sync parameters with BpodParameterGUI plugin

        %% Get parameters for the current trial and save to variables
        BpodSystem.Status.trial  = trial;
        fprintf('Trial %d: ', trial)

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

        % Global counters for each port (AnalogIn1 ports 1-3). 
        % First 3 are for dry licks before stimulus, the last 2 are for dry licks after stimulus delivery. 
        sma = SetGlobalCounter(sma, left_port.COUNTER_ID, left_port.LICK_ONSET, expV.DRY_LICKS_PRESTIM);
        sma = SetGlobalCounter(sma, center_port.COUNTER_ID, center_port.LICK_ONSET, expV.DRY_LICKS_PRESTIM);
        sma = SetGlobalCounter(sma, right_port.COUNTER_ID, right_port.LICK_ONSET, expV.DRY_LICKS_PRESTIM);
        sma = SetGlobalCounter(sma, center_port.COUNTER_ID_2, center_port.LICK_ONSET, expV.DRY_LICKS_POSTSTIM);
        sma = SetGlobalCounter(sma, correct_port.COUNTER_ID_2, correct_port.LICK_ONSET, expV.DRY_LICKS_POSTSTIM);

        %% Adding States

        %%%% MAIN ITI: GAS CLEARING, WATER RINSE, AND STIMULUS LOADING %%%%%
        % trialStart: make sure all doors are up and all valves are closed.
        sma = AddState(sma, 'Name', 'trialStart', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'ITI_gasClear'}, ...
            'OutputActions', {left_port.DOOR, expV.UP, center_port.DOOR, expV.UP, right_port.DOOR, expV.UP, ...
            'ValveModule1', ['B' 0], expV.GAS_VALVE, 0});
        % ITI_gasClear1: clear center port with gas and start ITI timer
        sma = AddState(sma, 'Name', 'ITI_gasClear', ...
            'Timer', expV.GAS_TIME, ...
            'StateChangeConditions', {'Tup', 'ITI_gasDelay'}, ...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 1,'GlobalTimerTrig', expV.ITI_TIMER_ID});
         % ITI_gasDelay1: pause after gas to allow pressure to rebalance
        sma = AddState(sma, 'Name', 'ITI_gasDelay', ...
            'Timer', expV.GAS_DELAY, ...
            'StateChangeConditions', {'Tup', 'ITI_stimLoad'}, ...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0});
        
        % ITI_stimLoad: stimulus loading in the center spout
        sma = AddState(sma, 'Name', 'ITI_stimLoad', ...
            'Timer', valveLoadingTime, ...
            'StateChangeConditions', {'Tup', 'ITI_waitForRemaining'}, ...
            'OutputActions',{center_port.DOOR, expV.UP, expV.GAS_VALVE, 0, 'ValveModule1', ['O' center_stimulus_valve]});
        % ITI_waitForRemaining: wait for ITI timer to finish and start the trial 
        sma = AddState(sma, 'Name', 'ITI_waitForRemaining', ...
            'Timer', 0, ...
            'StateChangeConditions', {expV.ITI_TIMER_END, 'TTC_Center'}, ...
            'OutputActions',{center_port.DOOR, expV.UP, 'ValveModule1', ['C' center_stimulus_valve], ...
            'GlobalCounterReset', center_port.COUNTER_ID});

        %%%%% CENTER PORT: SAMPLING PHASE %%%%%
        % Center port door opens, wait for lick or timeout
        sma = AddState(sma, 'Name', 'TTC_Center', ...
            'Timer', expV.TTC_CENTER_TIME, ...
            'StateChangeConditions', {'Tup', 'reportSkip', center_port.LICK_ONSET, 'waitCenterDryLicks'}, ...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'AnalogIn1', ['#' 0], 'WavePlayer1', ['P' 8 0]});
        % Wait for pre-stim dry licks at the center port
        sma = AddState(sma, 'Name', 'waitCenterDryLicks', ...
            'Timer', 0, ...
            'StateChangeConditions', {center_port.COUNTER_EVENT, 'waitCenterSampleLick1', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});
        
        % SAMPLING: deliver 3 pulses of the center stimulus, each triggered by lick offset at the center port. 
        sma = AddState(sma, 'Name', 'waitCenterSampleLick1', ...
            'Timer', 0, ...
            'StateChangeConditions', {center_port.LICK_OFFSET, 'openCenterValve1', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve1', ...
            'Timer', center_port.VALVE_TIME, ...
            'StateChangeConditions', {'Tup', 'closeCenterValve1'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCenterValve1', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'waitCenterSampleLick2'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitCenterSampleLick2', ...
            'Timer', 0, ...
            'StateChangeConditions', {center_port.LICK_OFFSET, 'openCenterValve2', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve2', ...
            'Timer', center_port.VALVE_TIME, ...
            'StateChangeConditions', {'Tup', 'closeCenterValve2'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCenterValve2', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'waitCenterSampleLick3'}, ...
            'OutputActions',{center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitCenterSampleLick3', ...
            'Timer', 0, ...
            'StateChangeConditions', {center_port.LICK_OFFSET, 'openCenterValve3', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCenterValve3', ...
            'Timer', center_port.VALVE_TIME, ...
            'StateChangeConditions', {'Tup', 'closeCenterValve3'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN, 'ValveModule1', ['O' center_port.VALVE], ...
            'GlobalCounterReset', center_port.COUNTER_ID_2});
        % Wait for final post-stimulus dry licks, but don't punish at this training stage
        sma = AddState(sma, 'Name', 'closeCenterValve3', ...
            'Timer', 0, ...
            'StateChangeConditions', {center_port.COUNTER_EVENT_2, 'Delay', ...
            expV.LICK_WINDOW_TIMER_END, 'Delay'}, ...
            'OutputActions', {center_port.DOOR, expV.DOWN, 'ValveModule1', ['C' center_port.VALVE]});

        %%%%% LATERAL PORT: RESPONSE PHASE %%%%%
        % Delay: waiting before lateral ports open
        sma = AddState(sma, 'Name', 'Delay', ...
            'Timer', expV.DELAY_TIME, ...
            'StateChangeConditions', {'Tup', 'TTC_Lateral'}, ...
            'OutputActions',{center_port.DOOR, expV.UP, 'GlobalCounterReset', incorrect_port.COUNTER_ID});
        % Open correct lateral door ONLY, wait for first lick
        sma = AddState(sma, 'Name', 'TTC_Lateral', ...
            'Timer', expV.TTC_LATERAL_TIME,...
            'StateChangeConditions', {'Tup', 'reportSkip', correct_port.LICK_ONSET, 'waitLateralDryLicks'}, ...
            'OutputActions',{correct_port.DOOR, expV.DOWN, 'GlobalCounterReset', correct_port.COUNTER_ID});
        % Wait for dry licks
        sma = AddState(sma, 'Name', 'waitLateralDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {correct_port.COUNTER_EVENT, 'waitLateralRewardLick1', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'},...
            'OutputActions',{correct_port.DOOR, expV.DOWN, 'GlobalTimerTrig', expV.LICK_WINDOW_TIMER_ID});
        
        % If correct choice: deliver 3 reward pulses, each triggered by lick offset
        sma = AddState(sma, 'Name', 'waitLateralRewardLick1', ...
            'Timer', 0, ...
            'StateChangeConditions', {correct_port.LICK_OFFSET, 'openCorrectValve1', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCorrectValve1', ...
            'Timer', correct_port.VALVE_TIME, ...
            'StateChangeConditions', {'Tup', 'closeCorrectValve1'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN, ...
            'ValveModule1', ['O', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCorrectValve1', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick2'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN, ...
            'ValveModule1', ['C', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitLateralRewardLick2', ...
            'Timer', 0, ...
            'StateChangeConditions', {correct_port.LICK_OFFSET, 'openCorrectValve2', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCorrectValve2', ...
            'Timer', correct_port.VALVE_TIME, ...
            'StateChangeConditions', {'Tup', 'closeCorrectValve2'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN, ...
            'ValveModule1', ['O', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'closeCorrectValve2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitLateralRewardLick3'},...
            'OutputActions', {correct_port.DOOR, expV.DOWN, ...
            'ValveModule1', ['C', correct_port.VALVE]});
        sma = AddState(sma, 'Name', 'waitLateralRewardLick3', ...
            'Timer', 0, ...
            'StateChangeConditions', {correct_port.LICK_OFFSET, 'openCorrectValve3', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'openCorrectValve3', ...
            'Timer', correct_port.VALVE_TIME, ...
            'StateChangeConditions', {'Tup', 'closeCorrectValve3'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN, ...
            'ValveModule1', ['O', correct_port.VALVE], 'GlobalCounterReset', correct_port.COUNTER_ID_2});
        % Waits for additional dry licks after stimulus delivery, but no punish if licking stops before lick window
        sma = AddState(sma, 'Name', 'closeCorrectValve3', ...
            'Timer', 0, ...
            'StateChangeConditions', {correct_port.COUNTER_EVENT_2, 'ITI_correctTrialEnd', ...
            expV.LICK_WINDOW_TIMER_END, 'ITI_correctTrialEnd'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN, ...
            'ValveModule1', ['C', correct_port.VALVE]});
        % Correct trial end: raise doors, send SoftCode 15
        sma = AddState(sma, 'Name', 'ITI_correctTrialEnd', ...
            'Timer', expV.ITI_ENDTIME, ...
            'StateChangeConditions', {'Tup', 'exit'}, ...
            'OutputActions', {left_port.DOOR, expV.UP, right_port.DOOR, expV.UP, 'SoftCode', 15});
        
        % Incorrect choice - should never occur during side training
        sma = AddState(sma, 'Name', 'waitFinalIncorrectLick', ...
            'Timer', 0, ...
            'StateChangeConditions', {incorrect_port.LICK_ONSET, 'reportIncorrect', ...
            expV.LICK_WINDOW_TIMER_END, 'reportSkip'}, ...
            'OutputActions', {correct_port.DOOR, expV.DOWN});
        sma = AddState(sma, 'Name', 'reportIncorrect', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'ITI_punishTrialEnd'}, ...
            'OutputActions', {'SoftCode', 14});
        
        % If trial is skipped, report skipped trial and go to punish
        sma = AddState(sma, 'Name', 'reportSkip', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'ITI_punishTrialEnd'}, ...
            'OutputActions', {'SoftCode', 2});
        
        % Punishment for incorrect/skipped trial end: raise doors, extra gas clear, extra ITI
        sma = AddState(sma, 'Name', 'ITI_punishTrialEnd', ...
            'Timer', expV.ITI_ENDTIME, ...
            'StateChangeConditions', {'Tup', 'ITI_punishExtraGasClear'}, ...
            'OutputActions', {left_port.DOOR, expV.UP, right_port.DOOR, expV.UP});
        sma = AddState(sma, 'Name', 'ITI_punishExtraGasClear', ...
            'Timer', expV.GAS_TIME, ...
            'StateChangeConditions', {'Tup', 'ITI_punish'}, ...
            'OutputActions', {left_port.DOOR, expV.UP, right_port.DOOR, expV.UP, expV.GAS_VALVE, 1});
        sma = AddState(sma, 'Name', 'ITI_punish', ...
            'Timer', (expV.PUNISHMENT_TIME - expV.GAS_TIME), ...
            'StateChangeConditions', {'Tup', 'exit'}, ...
            'OutputActions', {left_port.DOOR, expV.UP, right_port.DOOR, expV.UP, ...
            'ValveModule1', ['B' 0], expV.GAS_VALVE, 0});

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

            disp(['Experiment duration: ' num2str(t) 'sec.' ]);
            clear elapsedTime; % Stop counting time from session start.

            AnalogIn1.scope_StartStop; % Close oscilloscope GUI
            AnalogIn1.endAcq; % Stop recording events (threshold crossings)
            AnalogIn1.stopReportingEvents; % Stop sending events to state machine
            ValveModule1.isOpen = zeros(1,8); % Make sure all valves are closed
            clear AnalogIn1
            clear WavePlayer1
            clear ValveModule1

            nTotalTr=length(SessionData.TrialStartTimestamp);
            nEngagedTr=sum(BpodSystem.Data.summary.engagedTrials==1);
            disp([num2str(nEngagedTr) ' engaged trials out of ' num2str(nTotalTr) ' total trials. ' ]); 
            return
        end
    end

    %% Nested Functions
    % These are divided into subfunctions just for organization and readability.

    % Function to add session info to BpodSystem.Data (helps with organization)
    function addToBpodData
        % Organizing what to save to BpodSystem data structure
        BpodSystem.Data.condition = SUBJECT_CONDITION_CODE;
        %BpodSystem.Data.trialOrder.trialTypeOrder = trial_order;
        BpodSystem.Data.trialOrder.centerValveOrder = center_stim_valve_order;

        % save valve stimulus assignment config (should contain stim id)
        BpodSystem.Data.valveStimulusAssignments = valveConfig.config; 

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
        BpodSystem.Data.valveTimings.valveLoadingTime = valveLoadingTime;
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