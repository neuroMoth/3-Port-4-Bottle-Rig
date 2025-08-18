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


THIRTY_MINUTES = 1800; %seconds.

CENTER_VALVE = 2;
PORT_1_VALVE = 1;
PORT_3_VALVE = 8;

LoadSerialMessages('ValveModule1', {['O' CENTER_VALVE], ['C' CENTER_VALVE]});  % load valve for center port into serial messages.

center_valve_time_variable = sprintf('open_time_%d', CENTER_VALVE); 
valve_time = BpodSystem.ProtocolSettings.GUI.(center_valve_time_variable)/1000;

S = BpodParameterGUI('sync', S);  

sma = NewStateMachine();

sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', THIRTY_MINUTES);


sma = AddState(sma, 'Name', 'start', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'centerPortDown', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'GlobalTimerTrig', 1});

sma = AddState(sma, 'Name', 'centerPortDown', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_2', 'noRewardLick', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 1});

sma = AddState(sma, 'Name', 'noRewardLick', ...
    'Timer', 0,...
    'StateChangeConditions', {'AnalogIn1_2', 'RewardLick', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 1});

sma = AddState(sma, 'Name', 'RewardLick', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'valveDelay', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 1, 'ValveModule1', 1, 'BNC1', 1});

sma = AddState(sma, 'Name', 'valveDelay', ...
    'Timer', valve_time,...
    'StateChangeConditions', {'Tup', 'flipValveOff', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 1, 'ValveModule1', 1, 'BNC1', 1});


sma = AddState(sma, 'Name', 'flipValveOff', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'centerPortDown', 'GlobalTimer1_End', 'cleanup'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 1,'Flex3DO', 0, 'Flex4DO', 1, 'ValveModule1', 2, 'BNC1', 0});

sma = AddState(sma, 'Name', 'cleanup', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', 2});


SendStateMachine(sma);
events = RunStateMachine();
    events

        if ~isempty(fieldnames(events)) % If you didn't stop the session manually mid-trial
                BpodSystem.Data = AddTrialEvents(BpodSystem.Data,events); % Adds raw events to a human-readable data struct
                    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
                end


                HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
                if BpodSystem.Status.BeingUsed == 0
                    A.scope_StartStop;
                    A.endAcq; % Close Oscope GUI
                    A.stopReportingEvents; % Stop sending events to state machine
                    clear A
                    RunProtocol('Stop')
                    return
                end










