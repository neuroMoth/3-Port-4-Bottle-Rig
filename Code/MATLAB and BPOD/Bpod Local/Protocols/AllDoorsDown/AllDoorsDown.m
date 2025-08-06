BpodSystem.FlexIOConfig.channelTypes = [1 1 1 1];

sma = NewStateMachine();

sma = AddState(sma, 'Name', 'start', ...
    'Timer', 2000,...
    'StateChangeConditions', {'Tup', 'doorsOpen'},...
    'OutputActions',{'Flex1DO', 1, 'Flex2DO', 1,'Flex3DO', 1, 'Flex4DO', 0});


sma = AddState(sma, 'Name', 'doorsOpen', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions',{'Flex1DO', 0, 'Flex2DO', 0,'Flex3DO', 0, 'Flex4DO', 0});


SendStateMachine(sma);
events = RunStateMachine();

events




