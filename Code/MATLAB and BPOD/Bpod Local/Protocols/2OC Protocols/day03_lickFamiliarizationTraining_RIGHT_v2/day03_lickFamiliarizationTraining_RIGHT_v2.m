% Original code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% V2 code edited/written by Timothy Vladimir Dong for Samuelsen Lab, Univeristy of Louisville----

%% LICK FAMILIARIAZATION | DAY 3: RIGHT | WATER ONLY AT ONE OF THE 3 PORTS
% Unlimited access at one of the 3 ports. Valve opens for the 1st lick, then opens on every 5th lick.
function day03_lickFamiliarizationTraining_RIGHT_v2

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
% BpodSystem.Status.consecutiveRatSkips = 0;
BpodSystem.Status.ExitTrialLoop = false; % session end

% FOR ALTERNATION:
% BpodSystem.Status.switchStimulusFlag = false; % used to indicate when middle stimulus should switch
% BpodSystem.Status.currentTrialType = nan; % tracking current trial type (0 = water, 1 = odor)
% BpodSystem.Status.numberNonconsecutiveCorrect = 0;
BpodSystem.Status.iOdorTrial = 1; % for iterating odor trial variables
BpodSystem.Status.iWaterTrial = 1; % for iterating water trial variables

% Organizing what to save to data structure
% BpodSystem.Data.correctTrials = nan(expV.MAXIMUM_TRIALS, 1);
% BpodSystem.Data.correctPort = zeros(expV.MAXIMUM_TRIALS, 1);
% BpodSystem.Data.centerValve = zeros(expV.MAXIMUM_TRIALS, 1);
BpodSystem.Data.rewardLick = nan;
% BpodSystem.Data.trialsEngaged = zeros(expV.MAXIMUM_TRIALS, 1);

% Saving ExperimentVariables
propNames = properties(expV); propValues = cell(size(propNames));
for i = 1:numel(propNames); propValues{i} = expV.(propNames{i}); end
expVarTable = cell2table(propValues,'RowNames', propNames, 'VariableNames', {'Value'}); % Convert to table
BpodSystem.Data.experimentVariables = expVarTable; % Save table to structure

% Generating lineup for valve openings
% FOR SIDE TRAINING valve orders assigned separately for odor and water trials, but only use one
% [waterValveLineup, ~] = GenerateCenterLineup_SideTraining();

num_dryLicks = expV.REWARD_LICKS-1;
center_valveDelay = expV.REWARD_VALVE_DELAY;

% FOR FAMILIARIZATION SESSIONS
portSession = expV.PORT_FAMILIARIZATION; % 1=left, 2=center, 3=right

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

% Save valve open times
valveID = ["Valve1"; "Valve2"; "Valve3"; "Valve4"; "Valve5"; "Valve6"; "Valve7"; "Valve8"];
valveOpenTimes = [BpodSystem.ProtocolSettings.GUI.open_time_1; BpodSystem.ProtocolSettings.GUI.open_time_2; ...
    BpodSystem.ProtocolSettings.GUI.open_time_3; BpodSystem.ProtocolSettings.GUI.open_time_4; ...
    BpodSystem.ProtocolSettings.GUI.open_time_5; BpodSystem.ProtocolSettings.GUI.open_time_6;
    BpodSystem.ProtocolSettings.GUI.open_time_7; BpodSystem.ProtocolSettings.GUI.open_time_8];
BpodSystem.Data.valveOpenTimes = table(valveID,valveOpenTimes); % This time is in ms

center_stimulus_valve = expV.VALVE_SET1(1);

port_1 = LateralPort(1); % port_1 is the instance of the class Port1
port_3 = LateralPort(3); % port_3 is the instance of the class Port3
center_port = CenterPort; % center_port the instance of the class center_port

thisPort = PortHandler; % PortHandler takes properties of current port
thisValve = nan;

% Print to command window the start of the Session
disp(['Subject Name: ' subj]);
fprintf('Date and time: %s\n',datetime("now"))
fprintf('Valve Durations: ');
for iValves=1:length(valveID); fprintf('%s=%.1fms. ',num2str(iValves),valveOpenTimes(iValves)); end
fprintf('\nSTIMULUS: ')

%% MAIN
S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

%% Get parameters for the current trial and save

% Get trial parameters according to trial type
if portSession == 1 % Left port
    thisPort = thisPort.setPort(portSession, port_1);
    thisValve = 1;
elseif portSession == 2 % Center port
    % Set center valve
    center_port = center_port.setValve(1, center_stimulus_valve);
    thisPort = thisPort.setPort(portSession, center_port);
    thisValve = center_stimulus_valve;

    % waterTrial = BpodSystem.Status.iWaterTrial;
    % % Get center valve for this trial
    % center_stimulus_valve = waterValveLineup(waterTrial);
    % % Set center valve
    % center_port = center_port.setValve(1, center_stimulus_valve);
    %
    % BpodSystem.Status.iWaterTrial = waterTrial + 1; % iterate
elseif portSession == 3 % Right port
    thisPort = thisPort.setPort(portSession, port_3);
    thisValve = 8;
else; error('Port selection error. ');
end

fprintf('Port%d. Valve%d. %d dry licks. %dms valve delay. ', portSession, thisValve, num_dryLicks, center_valveDelay*1000);

%% Assemble the State Machine
sma = NewStateMachine();

% set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
sma = SetGlobalTimer(sma, 'TimerID', expV.EXPERIMENT_TIMER_ID, 'Duration', expV.TOTAL_ALLOWED_TIME);

% set global counters for each of the possible input ports (AnalogIn1 ports 1-4).
% Arguments: (sma, CounterNumber, TargetEvent, Threshold)
sma = SetGlobalCounter(sma, thisPort.lick_counter_id, thisPort.lick_input, num_dryLicks);

%% Adding States
% Start experiment global timer
sma = AddState(sma, 'Name', 'triggerExperimentTimer', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'start'},...
    'OutputActions',{'GlobalTimerTrig', expV.EXPERIMENT_TIMER_ID});

%%%%% Start Session and First Reward Lick %%%%%
sma = AddState(sma, 'Name', 'start', ...
    'Timer', 3,...
    'StateChangeConditions', {'Tup', 'waitForFirstLick', expV.experimentTimeExpired, 'cleanup'},...
    'OutputActions',{thisPort.door, expV.UP});
sma = AddState(sma, 'Name', 'waitForFirstLick', ...
    'Timer', 0,...
    'StateChangeConditions', {thisPort.lick_input, 'firstRewardLick', expV.experimentTimeExpired, 'cleanup'},...
    'OutputActions',{thisPort.door, expV.DOWN, 'WavePlayer1', ['P' 8 0]});
sma = AddState(sma, 'Name', 'firstRewardLick', ...
    'Timer', thisPort.valve_time,...
    'StateChangeConditions', {'Tup', 'closeFirstReward'},...
    'OutputActions',{thisPort.door, expV.DOWN, 'ValveModule1', ['O' thisPort.valve], ...
    'GlobalCounterReset', thisPort.lick_counter_id});
sma = AddState(sma, 'Name', 'closeFirstReward', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'waitDryLicks'},...
    'OutputActions',{thisPort.door, expV.DOWN, 'ValveModule1', ['C' thisPort.valve]});

%%%%% Main Lick Loop %%%%%
sma = AddState(sma, 'Name', 'waitDryLicks', ...
    'Timer', 0,...
    'StateChangeConditions', {thisPort.lick_counter_event, 'waitRewardLick', expV.experimentTimeExpired, 'cleanup'},...
    'OutputActions',{thisPort.door, expV.DOWN});
sma = AddState(sma, 'Name', 'waitRewardLick', ...
    'Timer', 0,...
    'StateChangeConditions', {thisPort.lick_input, 'rewardLick', expV.experimentTimeExpired , 'cleanup'},...
    'OutputActions',{thisPort.door, expV.DOWN});
sma = AddState(sma, 'Name', 'rewardLick', ...
    'Timer', thisPort.valve_time,...
    'StateChangeConditions', {'Tup', 'closeReward'},...
    'OutputActions',{thisPort.door, expV.DOWN, 'ValveModule1', ['O' thisPort.valve], ...
    'GlobalCounterReset', thisPort.lick_counter_id});
sma = AddState(sma, 'Name', 'closeReward', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'waitDryLicks'},...
    'OutputActions',{thisPort.door, expV.DOWN, 'ValveModule1', ['C' thisPort.valve]});

%%%%% SESSION END %%%%%
sma = AddState(sma, 'Name', 'cleanup', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions',{thisPort.door, expV.UP, 'ValveModule1', ['B' 00000000], 'SoftCode', 1});

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
    %sessionSummary();
    return
end
end
