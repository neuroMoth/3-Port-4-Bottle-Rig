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
S = update_valve_open_times(S, 1:8);

% Save protocol settings (after updating valve timings)
BpodSystem.ProtocolSettings = S;
SaveProtocolSettings(BpodSystem.ProtocolSettings)

BpodParameterGUI('init', S); % initialize GUI to keep track of parameters

disp('Doors down for 1 hour or until the protocol is stopped. ')

%% DOORS DOWN STATE MACHINE
sma = NewStateMachine();

sma = AddState(sma, 'Name', 'start', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'doorsOpen'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0, 'ValveModule1', ['B' 0], 'BNC1', 0});

sma = AddState(sma, 'Name', 'doorsOpen', ...
    'Timer', 3600,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 1,'Flex3DO', 1, 'Flex4DO', 0});

SendStateMachine(sma);
events = RunStateMachine();




