%% Code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% SIDE TRANING DAYS 3-4
% ODOR LEFT | WATER CENTER 
% ODOR IS DELIVERED ON THE LEFT PORT ONLY. WATER IS DELIVERED IN THE CENTER PORT ONLY.


function side_training_day_1_odor_right
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

port_3_valve_time_variable = sprintf('open_time_%d', PORT_3_VALVE); 
port_3_valve_time = BpodSystem.ProtocolSettings.GUI.(port_3_valve_time_variable)/1000;

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
%   - AnalogIn1_1-> rat interaction on port, move to 'firstCenterLick' state
%   - GlobalTimer1_End -> sixty minute time limit is up, move to cleanup state to finish experiment

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'TTC_Center', ...
    'Timer', 30,...
    'StateChangeConditions', {'Tup', 'exit','AnalogIn1_1', 'firstCenterLick', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalCounterReset', 1});

% firstCenterLick triggers the global timer (sets 0) for available lick time (2 seconds) upon first lick. immediately transition to oddLick state, 
% to wait for even lick

%State change conditions include: 
%   - tup -> immediately move to oddLick

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'firstCenterLick', ... 
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'oddLick'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalTimerTrig', 2});

% oddLick state to handle the case where we've detected an odd lick and are waiting for even lick. 

%State change conditions include: 
%   - AnalogIn1_1 -> even lick, move to 'waterRewardLick' to dispense reward. 
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalTimer2_End (2 seconds since first lick passed)  -> back to ITI

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'oddLick', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_1', 'waterRewardLick', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0});


% waitForNonFirstOdd handles the case where we've just finished dispensing a reward, but have not yet detected another lick. 
% It is an intermediate state, waiting for more licks to move on to other states. 
% State change conditions include: 
%   - AnalogIn1_1  -> move to oddLick to wait for an another even lick to dispense a reward
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalTimer2_End (2 seconds since first lick passed)  -> back to ITI

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'waitForNonFirstOdd', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_1', 'oddLick', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalTimerTrig', 2});

% waterRewardLick handles the case where we've detected an even lick and need to dispense the water reward on port. 
% State change conditions include: 
%   - tup -> immediately move to beginCenterValve to open the valve
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalCounter1_End -> 6th lick detected, move to ttc.

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'waterRewardLick', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'beginCenterValve', 'GlobalTimer1_End', 'cleanup', 'GlobalCounter1_End', 'lateralTTC_Timeout'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0});

% beginCenterValve handles the opening of the center valve
% State change conditions include: 
%   - tup -> immediately move to beginCenterValve to open the valve
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data

% OutputActions
%   - Flex2DO remains on to keep center port open. 
%   - Call LoadSerialMessages number 1 (see line 74) on ValveModule1 to open the chosen valve. 
%   - Force BNC1 high (ttl logical 1) to activate extra valves during center valve opening. 
sma = AddState(sma, 'Name', 'beginCenterValve', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'centerValveDelay', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});


% centerValveDelay delays the chosen valve 'center_valve_time' milliseconds. This is pulled from the valve calibration times. 
% State change conditions include: 
%   - tup -> move to centerValveOff to close the valve  after 'center_valve_time' milliseconds.
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data

% OutputActions
%   - Flex2DO remains on to keep center port open. 
%   - ValveModule1 remains on to keep the valve open.
%   - BNC1 remains on to keep extra valves open during center valve opening. 
sma = AddState(sma, 'Name', 'centerValveDelay', ...
    'Timer', center_valve_time,...
    'StateChangeConditions', {'Tup', 'centerValveOff', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 1, 'BNC1', 1});

% centerValveOff turns the center valve to the off (closed) position
% State change conditions include: 
%   - tup -> immediately move to 'waitForNonFirstOdd' state

% OutputActions
%   - Flex2DO remains on to keep center port open. 
%   - Call LoadSerialMessages number 2 (see line 74) on ValveModule1 to open the chosen valve
%   - Force BNC1 to low (ttl 0) state to turn off (close) extra valves 
sma = AddState(sma, 'Name', 'centerValveOff', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'waitForNonFirstOdd', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 2, 'BNC1', 0});


% OutputActions
%   - All doors remain closed
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
    'StateChangeConditions', {'Tup', 'exit','AnalogIn1_4', 'firstLateralLick', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'GlobalCounterReset', 4});

% firstLateralLick triggers the global timer (sets 0) for available lick time (2 seconds) upon first lick. immediately transition to oddLick state, 
% to wait for even lick

%State change conditions include: 
%   - tup -> immediately move to oddLick

% OutputActions
%   - Flex3DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'firstLateralLick', ... 
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'oddLateralLick'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'GlobalTimerTrig', 2});

% oddLateralLick state to handle the case where we've detected an odd lick and are waiting for even lick. 

%State change conditions include: 
%   - AnalogIn1_4 -> even lick on the third capacitive board/left port, move to 'odorRewardLick' to dispense reward. 
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalTimer2_End (2 seconds since first lick passed)  -> back to ITI

% OutputActions
%   - Flex3DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'oddLateralLick', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_4', 'odorRewardLick', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0});


% waitForNonFirstLateralOdd handles the case where we've just finished dispensing a reward, but have not yet detected another lick. 
% It is an intermediate state, waiting for more licks to move on to other states. 
% State change conditions include: 
%   - AnalogIn1_1  -> move to oddLick to wait for an another even lick to dispense a reward
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalTimer2_End (2 seconds since first lick passed)  -> back to ITI

% OutputActions
%   - Flex3DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'waitForNonFirstLateralOdd', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_4', 'oddLateralLick', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'GlobalTimerTrig', 2});

% odorRewardLick handles the case where we've detected an even lick and need to dispense the water reward on port. 
% State change conditions include: 
%   - tup -> immediately move to beginCenterValve to open the valve
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalCounter1_End -> 6th lick detected, move to ttc.

% OutputActions
%   - Flex3DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'odorRewardLick', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'beginLateralValve', 'GlobalTimer1_End', 'cleanup', 'GlobalCounter4_End', 'rewardLick6_ITI'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0});



% beginLateralValve handles the opening of the left valve
% State change conditions include: 
%   - tup -> immediately move to beginCenterValve to open the valve
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data

% OutputActions
%   - Flex3DO remains on to keep center port open. 
%   - Call LoadSerialMessages number 3 (see line 74) on ValveModule1 to open the left valve. 
%   - Force BNC1 high (ttl logical 1) to activate extra valves during center valve opening. 
sma = AddState(sma, 'Name', 'beginLateralValve', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lateralValveDelay', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});


% lateralValveDelay delays the chosen valve 'port_1_valve_time' milliseconds. This is pulled from the valve calibration times. 
% State change conditions include: 
%   - tup -> move to centerValveOff to close the valve  after 'center_valve_time' milliseconds.
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data

% OutputActions
%   - Flex1DO remains on to keep center port open. 
%   - ValveModule1 remains on to keep the valve open.
%   - BNC1 remains on to keep extra valves open during center valve opening. 
sma = AddState(sma, 'Name', 'lateralValveDelay', ...
    'Timer', center_valve_time,...
    'StateChangeConditions', {'Tup', 'lateralValveOff', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

% lateralValveOff turns the port 1 (left) valve to the off (closed) position
% State change conditions include: 
%   - tup -> immediately move to 'waitForNonFirstOdd' state

% OutputActions
%   - Flex2DO remains on to keep center port open. 
%   - Call LoadSerialMessages number 4 (see line 74) on ValveModule1 to close the left valve
%   - Force BNC1 to low (ttl 0) state to turn off (close) extra valves 
sma = AddState(sma, 'Name', 'lateralValveOff', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'waitForNonFirstLateralOdd', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'ValveModule1', 4, 'BNC1', 0});

% rewardLick6_ITI handles the case where we've detected an even lick and need to dispense the water reward on port. 
% State change conditions include: 
%   - tup -> immediately move to beginCenterValve to open the valve
%   - GlobalTimer1_End (60 minutes expired) -> cleanup state to exit state machine and save data
%   - GlobalCounter1_End -> 6th lick detected, move to ttc.

% OutputActions
%   - Flex2DO remains on to keep center port open. 
sma = AddState(sma, 'Name', 'rewardLick6_ITI', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lick_6_beginLateralValve', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0});

sma = AddState(sma, 'Name', 'lick_6_beginLateralValve', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'lick_6_lateralValveDelay', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lick_6_lateralValveDelay', ...
    'Timer', center_valve_time,...
    'StateChangeConditions', {'Tup', 'lick_6_lateralValveOff', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'ValveModule1', 3, 'BNC1', 1});

sma = AddState(sma, 'Name', 'lick_6_lateralValveOff', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 1, 'Flex4DO', 0, 'ValveModule1', 4, 'BNC1', 0});

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
