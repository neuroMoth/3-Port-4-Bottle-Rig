function [waterValves, odorValves] = currentDayConditions
    % CURRENTDAYCONDITIONS returns condition rotations for today (currently just for valve stimuli assignments). 
    % Modified from DeepSeek generated script.
    
    % true  = odor
    % false = water
    %
    % N         : number of variables, must be even
    % startDate : datetime of first experiment day, e.g. datetime(2026,9,29)
    
    %% Set variables (MAKE CHANGES HERE TO CHANGE STIMULI VALVE ASSIGNMENTS)
    columns = [2, 3, 5, 6]; % valves/lines for holding stimuli 
    % (for the 1st experiment day, first half are water and the second half are odor)
    startDate = datetime(2026,9,29); % <-- set the first experiment day here 
    % (or set to today to use default stimulus column assignments) 
    
    %% Run
    N = length(columns); 
    dayNum = floor(days(datetime('today') - startDate)); % 0 on first day

    if mod(N,2) ~= 0; error('N must be even to have equal numbers in both states.'); end
    if dayNum < 0; error('Start date is in the future.'); end

    condRotation = conditionsForDay(dayNum, N);
    
    waterValves = columns(~condRotation); 
    odorValves = columns(condRotation); 
    
    fprintf('Conditions for %s\n',datetime("today")); 
    disp(['Water valves: ', num2str(waterValves)]); 
    disp(['Odor valves: ', num2str(odorValves)]);
end

function condRotation = conditionsForDay(dayNum, N)
    % Core rotation. dayNum can be any integer day counter.

    if mod(N,2) ~= 0
        error('N must be even.');
    end

    base = [false(1, N/2), true(1, N/2)];   % first day: N/2 water, N/2 odor
    idx  = mod((0:N-1) - dayNum, N) + 1;    % rotate by one each day
    condRotation = base(idx);
end