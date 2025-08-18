%% Code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% SIDE TRANING DAYS 3-4
% ODOR LEFT | WATER CENTER 
% ODOR IS DELIVERED ON THE LEFT PORT ONLY. WATER IS DELIVERED IN THE CENTER PORT ONLY.


function side_training_day_1_reward_left
    global BpodSystem


A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
A.nActiveChannels = 4;
% enable event reporting on AnalogInput1. This sends lick 'events' (5v
% threshold reached) to the state machine to be processed/counted.
A.SMeventsEnabled(1:4) = 1;
% This sets threshold voltages that we want to exceed to generate events.
% Here we use 5 volts.
A.Thresholds(1:4) = 5;
% ResetVoltages sets the lower voltage bound that must be crossed before a
% new event can trigger. Here we must go below 1 volt.
A.ResetVoltages(1:4) = 1;
% Tell the AnalogInput1 module to start reporting events to the
% state machine
A.startReportingEvents();
% start the oscilliscope.
A.scope();
A.scope_StartStop;

S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

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
end;

BpodParameterGUI('init', S); % initialize GUI to keep track of parameters


SIXTY_MINUTES = 3600; %seconds.

BpodSystem.Status.ExitTrialLoop = false; 

while true


LICK_WINDOW = 2; %2 seconds to complete required amount of licks

CENTER_VALVE = 2;
PORT_1_VALVE = 1;
PORT_3_VALVE = 8;

LoadSerialMessages('ValveModule1', {['O' CENTER_VALVE], ['C' CENTER_VALVE], ['O' PORT_1_VALVE], ['C' PORT_1_VALVE],['B' 00000000]});  % load valve for center port into serial messages.

center_valve_time_variable = sprintf('open_time_%d', CENTER_VALVE); 
center_valve_time = BpodSystem.ProtocolSettings.GUI.(center_valve_time_variable)/1000;

port_1_valve_time_variable = sprintf('open_time_%d', PORT_1_VALVE); 
port_1_valve_time = BpodSystem.ProtocolSettings.GUI.(port_1_valve_time_variable)/1000;

S = BpodParameterGUI('sync', S);  

sma = NewStateMachine();

% set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds. 
sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', SIXTY_MINUTES);
sma = SetGlobalTimer(sma, 'TimerID', 2, 'Duration', LICK_WINDOW);

% set global counters for each of the possible input ports (AnalogIn1 ports 1-4)  to 6. 
sma = SetGlobalCounter(sma, 1, 'AnalogIn1_1', 6); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?
sma = SetGlobalCounter(sma, 2, 'AnalogIn1_2', 6); 
sma = SetGlobalCounter(sma, 3, 'AnalogIn1_3', 6); 
sma = SetGlobalCounter(sma, 4, 'AnalogIn1_4', 6); 


% Initial TTC_Center state. This is the state entered at the end of every ITI time and the script remains here only while there are zero licks. 

%State change conditions include: 
%   - tup -> move to new TTC
%   - AnalogIn1_1-> rat interaction on port, move to 'firstCenterLick' state
%   - GlobalTimer1_End -> sixty minute time limit is up, move to cleanup state to finish experiment

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'ITI', ...
    'Timer', 5,...
    'StateChangeConditions', {'Tup', 'TTC_Center', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalTimerTrig', 1, 'GlobalCounterReset', 1});

% Initial TTC_Center state. This is the state entered at the end of every ITI time and the script remains here only while there are zero licks. 

%State change conditions include: 
%   - tup -> no rat interaction, move to new ITI by exiting this iteration (trial)
%   - AnalogIn1_1-> rat interaction on port, move to 'dryLick1' state
%   - GlobalTimer1_End -> sixty minute time limit is up, move to cleanup state to finish experiment

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'TTC_Center', ...
    'Timer', 30,...
    'StateChangeConditions', {'Tup', 'exit','AnalogIn1_1', 'centerDryLick1', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalCounterReset', 1});

% dryLick1 triggers the global timer (sets 0) for available lick time (2 seconds) upon first lick. wait for further dry licks.

%State change conditions include: 
%   - AnalogIn1_1-> rat interaction on port, move to 'dryLick1' state

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'centerDryLick1', ... 
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_1', 'centerDryLick2', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalTimerTrig', 2});

% dryLick2. Wait for last dry lick.

%State change conditions include: 
%   - AnalogIn1_1-> rat interaction on port, move to 'monitorForRewardLicks' state

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'centerDryLick2', ... 
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_1', 'monitorForCenterRewardLicks', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0});

% monitorForRewardLicks

%State change conditions include: 
%   - AnalogIn1_1-> centerReward1

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'monitorForCenterRewardLicks', ... 
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_1', 'centerReward1', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0});

% open valve once
sma = AddState(sma, 'Name', 'centerReward1', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'centerRewardDelay1', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});

sma = AddState(sma, 'Name', 'centerRewardDelay1', ...
    'Timer', center_valve_time,...
    'StateChangeConditions', {'Tup', 'centerValveOff1', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});


% functions as intermediate state that waits for reward lick 2
sma = AddState(sma, 'Name', 'centerValveOff1', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_1', 'centerReward2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 2, 'BNC1', 0});

sma = AddState(sma, 'Name', 'centerReward2', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'centerRewardDelay2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});

sma = AddState(sma, 'Name', 'centerRewardDelay2', ...
    'Timer', center_valve_time,...
    'StateChangeConditions', {'Tup', 'centerValveOff2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});

sma = AddState(sma, 'Name', 'centerValveOff2', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lateralTTC_Timeout' ,'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 2, 'BNC1', 0});


sma = AddState(sma, 'Name', 'lateralTTC_Timeout', ...
    'Timer', 3,...
    'StateChangeConditions', {'Tup', 'TTC_Port_1', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0});
% TTC_Port_1 is extremely similar to 'TTC_Center', except we wait for licks on the lateral port (HERE THE LEFT PORT / PORT 1)
% State change conditions include: 
%   - tup -> immediately move to 'waitForNonFirstOdd' state

% OutputActions
%   - Flex3DO opens to open the right port door. 
%   - Call LoadSerialMessages number 2 (see line 74) on ValveModule1 to open the chosen valve
%   - Force BNC1 to low (ttl 0) state to turn off (close) extra valves 
sma = AddState(sma, 'Name', 'TTC_Port_1', ...
    'Timer', 60,...
    'StateChangeConditions', {'Tup', 'exit','AnalogIn1_3', 'lateralDryLick1', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalCounterReset', 3});


% dryLick1 triggers the global timer (sets 0) for available lick time (2 seconds) upon first lick. wait for further dry licks.

%State change conditions include: 
%   - AnalogIn1_1-> rat interaction on port, move to 'dryLick1' state

% OutputActions
%   - Flex2DO remains on to keep lateral port open. 
sma = AddState(sma, 'Name', 'lateralDryLick1', ... 
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_3', 'lateralDryLick2', 'GlobalTimer1_End', 'cleanup' 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalTimerTrig', 2});

% dryLick2. Wait for last dry lick.

%State change conditions include: 
%   - AnalogIn1_1-> rat interaction on port, move to 'monitorForRewardLicks' state

% OutputActions
%   - Flex2DO remains on to keep lateral port open. 
sma = AddState(sma, 'Name', 'lateralDryLick2', ... 
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_3', 'monitorForLateralRewardLicks', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0});

% monitorForlateralRewardLicks

%State change conditions include: 
%   - AnalogIn1_1-> lateralReward1

% OutputActions
%   - Flex2DO remains on to keep lateral port open. 
sma = AddState(sma, 'Name', 'monitorForLateralRewardLicks', ... 
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_3', 'lateralReward1', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0});


% open valve once
sma = AddState(sma, 'Name', 'lateralReward1', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lateralRewardDelay1', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lateralRewardDelay1', ...
    'Timer', port_1_valve_time,...
    'StateChangeConditions', {'Tup', 'lateralValveOff1', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});


% functions as intermediate state that waits for reward lick 2
sma = AddState(sma, 'Name', 'lateralValveOff1', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_3', 'lateralReward2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 4, 'BNC1', 0});

sma = AddState(sma, 'Name', 'lateralReward2', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lateralRewardDelay2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lateralRewardDelay2', ...
    'Timer', port_1_valve_time,...
    'StateChangeConditions', {'Tup', 'lateralValveOff2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lateralValveOff2', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_3', 'lateralReward3','GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 4, 'BNC1', 0});

sma = AddState(sma, 'Name', 'lateralReward3', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lateralRewardDelay3', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lateralRewardDelay3', ...
    'Timer', port_1_valve_time,...
    'StateChangeConditions', {'Tup', 'lateralValveOff3', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lateralValveOff3', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','exit', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 4, 'BNC1', 0});

sma = AddState(sma, 'Name', 'cleanup', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 5, 'BNC1', 0, 'SoftCode', 3});

% function will check if softcode '3' has been sent by the state machine in cleanup state. if it has, it is time to exit the 
% trial loop. 
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_exit';

SendStateMachine(sma);
events = RunStateMachine();

    if ~isempty(fieldnames(events)) % If you didn't stop the session manually mid-trial
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,events); % Adds raw events to a human-readable data struct
                SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            end

            HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

            if (BpodSystem.Status.ExitTrialLoop == 1 || BpodSystem.Status.BeingUsed == 0) 
                A.scope_StartStop;
                A.endAcq; % Close Oscope GUI
                A.stopReportingEvents; % Stop sending events to state machine
                clear A
                RunProtocol('Stop')
                return
            end

        end
