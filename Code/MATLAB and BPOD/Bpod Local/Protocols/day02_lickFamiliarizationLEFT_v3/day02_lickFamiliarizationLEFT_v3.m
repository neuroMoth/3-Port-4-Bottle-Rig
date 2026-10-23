
%% DAY 02: LICK FAMILIARIZATION - LEFT PORT PROTOCOL V3
% Protocol function to get new animals adjusted to licking from each port.
% This protocol only opens the left port (port 1). The first lick delivers water, then every other lick.
%
% Lateral and center driver valves should be calibrated for 5 uL pulses in ~70 ms for delivering stimuli.

% This protocol calls the following custom functions (all others are from Bpod or MATLAB):
%   Located in the current protocol folder (...\Bpod Local\Protocols\testing_v3):
%      ExperimentVariables     % Holds parameters for the current session (e.g. state timing and valve assignments).
%      Port                    % Holds properties for each of the 3 ports. These are static throughout the session.
%      SoftCodeHandler         % Prints trial information to the MATLAB command window.
%   Located in the general protocol functions folder (...\Bpod Local\General Functions):
%      elapsedTime             % Allows MATLAB check the duration of the session.
%      updateValveTimes        % Updates valve times according to the current calibration values (for driver valves).
%      setValveStimuli         % Is not called directly by the protocol, but sets up the valve stimulus assignments.
%   Nested functions (located inside the main function towards the end of this script):
%      addToBpodData           % Organizes and adds info to BpodSystem.Data to be saved at the end of the session.
%      ConfigureBpodModules    % Sets up the ValveDriver, AnalogIn, and WavePlayer Modules.

% Original code written by Blake Hourigan for Samuelsen Lab, University of Louisville.
% V2 code and beyond edited/written by Timothy Vladimir Dong for Samuelsen Lab, University of Louisville.

%% Main Protocol Function
function day02_lickFamiliarizationLEFT_v3

    %% SESSION SETUP
    % Getting experiment constant variables and generating the trial order.

    global BpodSystem % Imports the BpodSystem object to the function workspace

    expV = ExperimentVariables(); %expV is used to access experiment constants from the ExperimentVariables function

    BpodSystem.Status.trial = 1;
    BpodSystem.Status.ExitTrialLoop = false; % set to true for session to end
    
    BpodSystem.Data.rewardedLickCount = 0;

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
    %centerStimValves = [expV.CENTER_VALVE_SET1, expV.CENTER_VALVE_SET2]; % Valves for loading center port stimuli
    ProtocolSettings = updateValveTimes(ProtocolSettings, deliveryValves, expV.STIM_VOLUME);

    % save stimulus delivery valve open times to session data (saved from the protocol settings GUI)
    valveID = strings(size(deliveryValves))';
    valveStimTimes = zeros(size(deliveryValves))';
    for iValve = 1:length(deliveryValves)
        valveID(iValve) = ['Valve', num2str(deliveryValves(iValve))];
        time_variable_name = sprintf('open_time_%d', deliveryValves(iValve));
        valveStimTimes(iValve) = round(BpodSystem.ProtocolSettings.GUI.(time_variable_name)/1000, 4);
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
    disp('Day 01 Lick Familiarization Protocol - Center Port')
    fprintf('Date and time: %s\n', datetime("now"));
    fprintf(['Valve Durations (' num2str(expV.STIM_VOLUME) 'ul): ']);
    for iValves = 1:length(valveID)
        fprintf('%s=%.1fms. ', valveID(iValves), valveStimTimes(iValves)*1000);
    end

    % Reset and start session timer (persistent function)
    clear elapsedTime; % Make sure session timer starts at 0.
    elapsedTime; % First call to start timer.

    %% GUI and Port Selection
    ProtocolSettings = BpodParameterGUI('sync', ProtocolSettings); % Sync parameters with BpodParameterGUI plugin

    % Get trial parameters according to trial type
    if expV.CURRENT_PORT == 1 % Left port
        thisPort = left_port; 
    elseif expV.CURRENT_PORT == 2 % Center port
        thisPort = center_port; 
    elseif expV.CURRENT_PORT == 3 % Right port
        thisPort = right_port; 
    else; error('Port selection error. ');
    end

    fprintf('Port%d. Valve%d. \n', expV.CURRENT_PORT, thisPort.VALVE);
    fprintf('\nCount Number of Reward Licks (stimulus deliveries): \n'); 

    %% Assemble the State Machine
    sma = NewStateMachine(); 
    
    % set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
    sma = SetGlobalTimer(sma, 'TimerID', expV.SESSION_TIMER_ID, 'Duration', expV.TOTAL_ALLOWED_TIME);

    %% Adding States

    %%%%% Start Session and First Reward Lick %%%%%
    sma = AddState(sma, 'Name', 'triggerExperimentTimer', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'start'},...
        'OutputActions', {'GlobalTimerTrig', expV.SESSION_TIMER_ID});
    sma = AddState(sma, 'Name', 'start', ...
        'Timer', 3,...
        'StateChangeConditions', {'Tup', 'waitForFirstLick'},...
        'OutputActions', {thisPort.DOOR, expV.UP});
    sma = AddState(sma, 'Name', 'waitForFirstLick', ...
        'Timer', 0,...
        'StateChangeConditions', {thisPort.LICK_OFFSET, 'firstRewardLick', expV.SESSION_TIME_END, 'cleanup'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN});
    sma = AddState(sma, 'Name', 'firstRewardLick', ...
        'Timer', thisPort.VALVE_TIME,...
        'StateChangeConditions', {'Tup', 'closeFirstReward'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN, 'ValveModule1', ['O' thisPort.VALVE], 'SoftCode', 4});
    sma = AddState(sma, 'Name', 'closeFirstReward', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'waitDryLick'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN, 'ValveModule1', ['C' thisPort.VALVE]});

    %%%%% Main Lick Loop %%%%%
    sma = AddState(sma, 'Name', 'waitDryLick', ...
        'Timer', 0,...
        'StateChangeConditions', {thisPort.LICK_OFFSET, 'waitRewardLick', expV.SESSION_TIME_END, 'cleanup'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN});
    sma = AddState(sma, 'Name', 'waitRewardLick', ...
        'Timer', 0,...
        'StateChangeConditions', {thisPort.LICK_OFFSET, 'rewardLick', expV.SESSION_TIME_END , 'cleanup'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN});
    sma = AddState(sma, 'Name', 'rewardLick', ...
        'Timer', thisPort.VALVE_TIME,...
        'StateChangeConditions', {'Tup', 'closeReward'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN, 'ValveModule1', ['O' thisPort.VALVE], 'SoftCode', 4});
    sma = AddState(sma, 'Name', 'closeReward', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'waitDryLick'},...
        'OutputActions', {thisPort.DOOR, expV.DOWN, 'ValveModule1', ['C' thisPort.VALVE]});

    %%%%% SESSION END %%%%%
    sma = AddState(sma, 'Name', 'cleanup', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {thisPort.DOOR, expV.UP, 'ValveModule1', ['B' 0]});
    
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
        
        fprintf('%d total licks.', BpodSystem.Data.rewardedLickCount)
        fprintf('\n')

        AnalogIn1.scope_StartStop; % Close oscilloscope GUI
        AnalogIn1.endAcq; % Stop recording events (threshold crossings)
        AnalogIn1.stopReportingEvents; % Stop sending events to state machine
        ValveModule1.isOpen = zeros(1,8); % Make sure all valves are closed
        clear AnalogIn1
        clear WavePlayer1
        clear ValveModule1

        return
    end

    %% Nested Functions
    % These are divided into subfunctions just for organization and readability.

    % Function to add session info to BpodSystem.Data (helps with organization)
    function addToBpodData
        % Organizing what to save to BpodSystem data structure
        BpodSystem.Data.condition = SUBJECT_CONDITION_CODE;

        % save valve stimulus assignment config (should contain stim id)
        BpodSystem.Data.valveStimulusAssignments = valveConfig.config;

        % save port properties
        BpodSystem.Data.portInfo.port1 = left_port;
        BpodSystem.Data.portInfo.port2 = center_port;
        BpodSystem.Data.portInfo.port3 = right_port;

        % Saving ExperimentVariables
        propNames = properties(expV); propValues = cell(size(propNames));
        for i = 1:numel(propNames); propValues{i} = expV.(propNames{i}); end
        expVarTable = cell2table(propValues,'RowNames', propNames, 'VariableNames', {'Value'}); % Convert to table
        BpodSystem.Data.experimentVariables = expVarTable; % Save table to structure

        % Save calibrated valve times for stimulus drivers
        BpodSystem.Data.valveTimings.valveStimTimes = table(valveID, valveStimTimes); % time in seconds
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