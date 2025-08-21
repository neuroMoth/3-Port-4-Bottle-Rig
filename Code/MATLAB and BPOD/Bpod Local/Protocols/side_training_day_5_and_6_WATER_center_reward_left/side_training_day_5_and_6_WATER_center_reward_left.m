%% Code written by Blake Hourigan for Samuelsen Lab, Univeristy of Louisville----
% SIDE TRAiNING DAYS 5-6 | ODOR CENTER | VALVE 5 CENTER | LEFT PORT REWARD

function side_training_day_1_odor_right
    global BpodSystem

    SIXTY_MINUTES = 30; %seconds.

    timer_set = 0;

    % these varaibles are used to make door commands more intuitive and easy to understand & read.
    UP = 0;
    DOWN = 1;
    LEFT_SPOUT = 0;
    RIGHT_SPOUT = 1;

    LICK_WINDOW = 2; % Defines amount of seconds rat has to complete required amount of licks.

    %%%%%% MAJOR DIFFERENCE FROM ODOR CENTER FILE. VALVE IS CHANGED FROM 5->2. %%%%%%
    CENTER_VALVE = 2;
    PORT_1_VALVE = 1;
    PORT_3_VALVE = 8;

    LATERAL_VALVE = PORT_1_VALVE;

    % remap unhelpful analoginput port number strings to variables that can easily be changed
    % to make the code more reusable.
    CENTER_LICK = 'AnalogIn1_1';
    CENTER_LICK_2 = 'AnalogIn1_2'; % input for the second spout in the center port.
    PORT_1_INPUT = 'AnalogIn1_3';
    PORT_3_INPUT = 'AnalogIn1_4';

    PORT_1_DOOR = 'Flex1DO';
    CENTER_PORT_DOOR = 'Flex2DO';
    PORT_3_DOOR = 'Flex3DO';
    CENTER_PORT = 'Flex4DO';

    % these variables are the numbers of the global counters that are used to track
    % lick counts. The numbers are stored in variables here to make this script
    % reusable and give the ability to easily flip the desired port.
    CENTER_1_COUNT_NUM = 1;
    CENTER_2_COUNT_NUM = 2;
    PORT_1_COUNT_NUM = 3;
    PORT_3_COUNT_NUM = 4;

    CENTER_1_COUNT_COMPLETE = 'GlobalCounter1_End';
    CENTER_2_COUNT_COMPLETE = 'GlobalCounter2_End';
    PORT_1_COUNT_COMPLETE = 'GlobalCounter3_End';
    PORT_3_COUNT_COMPLETE = 'GlobalCounter4_End';

    % save port_1 variables into lateral variables. This way, we can copy this EXACT script and
    % change ONLY these variables to PORT_3 to flip the 'correct' side.
    LATERAL_INPUT = PORT_1_INPUT;
    LATERAL_DOOR = PORT_1_DOOR;
    LATERAL_LICK_COUNTER = PORT_1_COUNT_NUM;
    LATERAL_COUNTER_COMPLETE = PORT_1_COUNT_COMPLETE;

    CENTER_LICK_COUNTER = CENTER_1_COUNT_NUM;

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
    if isempty(fieldnames(S)) % If settings file was an empty struct, populate struct with default settings

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

    % this variable is created to indicate when the protocol should halt (after 60 minutes). This is set
    % in the softcode handler function 'BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_exit'
    BpodSystem.Status.ExitTrialLoop = false;

    % do infinite trials while 60 minutes has not elapsed
    while true
        center_valve_time_variable = sprintf('open_time_%d', CENTER_VALVE);
        center_valve_time = BpodSystem.ProtocolSettings.GUI.(center_valve_time_variable)/1000;

        port_1_valve_time_variable = sprintf('open_time_%d', PORT_1_VALVE);
        port_1_valve_time = BpodSystem.ProtocolSettings.GUI.(port_1_valve_time_variable)/1000;

        port_3_valve_time_variable = sprintf('open_time_%d', PORT_3_VALVE);
        port_3_valve_time = BpodSystem.ProtocolSettings.GUI.(port_3_valve_time_variable)/1000;

        lateral_valve_time =  port_1_valve_time;

        S = BpodParameterGUI('sync', S);

        sma = NewStateMachine();


        % set global timers for the maximum duration of the experiment and the maximum sample time of 2 seconds.
        sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', SIXTY_MINUTES);
        sma = SetGlobalTimer(sma, 'TimerID', 2, 'Duration', LICK_WINDOW);

        % set global counters for each of the possible input ports (AnalogIn1 ports 1-4) to 6.
        sma = SetGlobalCounter(sma, CENTER_1_COUNT_NUM, CENTER_LICK, 3); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?
        sma = SetGlobalCounter(sma, CENTER_2_COUNT_NUM, CENTER_LICK_2, 3);
        sma = SetGlobalCounter(sma, PORT_1_COUNT_NUM, PORT_1_INPUT, 3);
        sma = SetGlobalCounter(sma, PORT_3_COUNT_NUM, PORT_3_INPUT, 3);

        if (timer_set ==0)
            sma = AddState(sma, 'Name', 'triggerExperimentTimer', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'ITI'},...
                'OutputActions',{'GlobalTimerTrig', 1});

            timer_set = 1;
        end

        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', 5,...
            'StateChangeConditions', {'Tup', 'TTC_Center', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, UP, 'GlobalTimerTrig', 1});

        sma = AddState(sma, 'Name', 'TTC_Center', ...
            'Timer', 30,...
            'StateChangeConditions', {'Tup', 'exit', CENTER_LICK, 'firstLick', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'GlobalCounterReset', CENTER_LICK_COUNTER});
        
        sma = AddState(sma, 'Name', 'firstLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitForRemainingCenterDryLicks'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'GlobalTimerTrig', 2});
        
        sma = AddState(sma, 'Name', 'waitForRemainingCenterDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {CENTER_1_COUNT_COMPLETE, 'waitCenterRewardLick1', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN});

        sma = AddState(sma, 'Name', 'waitCenterRewardLick1', ...
            'Timer', 0,...
            'StateChangeConditions', {CENTER_LICK, 'openCenterValve', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit' },...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN});

        sma = AddState(sma, 'Name', 'openCenterValve', ...
            'Timer', center_valve_time,...
            'StateChangeConditions', {'Tup', 'centerValveOff'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'ValveModule1', ['O' CENTER_VALVE], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'centerValveOff', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitCenterRewardLick2'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'ValveModule1', ['C' CENTER_VALVE], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'waitCenterRewardLick2', ...
            'Timer', 0,...
            'StateChangeConditions', {CENTER_LICK, 'openCenterValve2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit' },...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN});

        sma = AddState(sma, 'Name', 'openCenterValve2', ...
            'Timer', center_valve_time,...
            'StateChangeConditions', {'Tup', 'centerValveOff2', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'ValveModule1', ['O' CENTER_VALVE], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'centerValveOff2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitSixthLick', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'ValveModule1', ['C' CENTER_VALVE], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'waitSixthLick', ...
            'Timer', 0,...
            'StateChangeConditions', {CENTER_LICK, 'ttcLateralTimeout', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, DOWN, 'ValveModule1', ['C' CENTER_VALVE], 'BNC1', 0});


        %%%%% BEGIN TTC ON THE LATERAL PORT %%%%%
        sma = AddState(sma, 'Name', 'ttcLateralTimeout', ...
            'Timer', 3,...
            'StateChangeConditions', {'Tup', 'ttcLateral', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, UP});
            
        sma = AddState(sma, 'Name', 'ttcLateral', ...
            'Timer', 30,...
            'StateChangeConditions', {'Tup', 'exit', LATERAL_INPUT, 'firstLateralLick', 'GlobalTimer1_End', 'cleanup'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'GlobalCounterReset', LATERAL_LICK_COUNTER});
        
        sma = AddState(sma, 'Name', 'firstLateralLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitForRemainingLateralDryLicks'},...
            'OutputActions',{LATERAL_DOOR, DOWN,CENTER_PORT_DOOR, UP, 'GlobalTimerTrig', 2});
        
        sma = AddState(sma, 'Name', 'waitForRemainingLateralDryLicks', ...
            'Timer', 0,...
            'StateChangeConditions', {LATERAL_COUNTER_COMPLETE, 'waitForLateralReward1', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP});

        sma = AddState(sma, 'Name', 'waitForLateralReward1', ...
            'Timer', 0,...
            'StateChangeConditions', {LATERAL_INPUT, 'openLateralValve1', 'GlobalTimer2_End', 'exit'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'GlobalTimerTrig', 2});

        sma = AddState(sma, 'Name', 'openLateralValve1', ...
            'Timer', lateral_valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralValve1'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'ValveModule1', ['O' LATERAL_VALVE], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralValve1', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitForLateralReward2'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'ValveModule1', ['C' LATERAL_VALVE], 'BNC1', 0});
        
        sma = AddState(sma, 'Name', 'waitForLateralReward2', ...
            'Timer', 0,...
            'StateChangeConditions', {LATERAL_INPUT, 'openLateralValve2', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP});
        
        sma = AddState(sma, 'Name', 'openLateralValve2', ...
            'Timer', lateral_valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralValve2'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'ValveModule1', ['O' LATERAL_VALVE], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralValve2', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'waitForLateralReward3'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'ValveModule1', ['C' LATERAL_VALVE], 'BNC1', 0});
        
        sma = AddState(sma, 'Name', 'waitForLateralReward3', ...
            'Timer', 0,...
            'StateChangeConditions', {LATERAL_INPUT, 'openLateralValve3', 'GlobalTimer1_End', 'cleanup', 'GlobalTimer2_End', 'exit'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP});
        
        sma = AddState(sma, 'Name', 'openLateralValve3', ...
            'Timer', lateral_valve_time,...
            'StateChangeConditions', {'Tup', 'closeLateralValve3'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'ValveModule1', ['O' LATERAL_VALVE], 'BNC1', 1});

        sma = AddState(sma, 'Name', 'closeLateralValve3', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{LATERAL_DOOR, DOWN, CENTER_PORT_DOOR, UP, 'ValveModule1', ['C' LATERAL_VALVE], 'BNC1', 0});

        sma = AddState(sma, 'Name', 'cleanup', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions',{LATERAL_DOOR, UP, CENTER_PORT_DOOR, UP, 'ValveModule1', ['B' 00000000], 'BNC1', 0, 'SoftCode', 3});

        % function will check if softcode '3' has been sent by the state machine in cleanup state. if it has, it is time to exit the
        % trial loop.
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

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

