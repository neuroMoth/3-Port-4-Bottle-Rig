%%% test startup script for rotating stimulus column assignments

bpod % open bpod software

fprintf('Conditions for %s\n',datetime("today")); 
[waterValves, odorValves] = currentDayConditions; % get and print the valve assignments for the current day
disp(['Water valves: [', num2str(waterValves), ']. Odor valves: [', num2str(odorValves), '].']); 

setValveStimuli % opens UI to allow user to check/modify valve stimulus assignments (saved to valve_config)