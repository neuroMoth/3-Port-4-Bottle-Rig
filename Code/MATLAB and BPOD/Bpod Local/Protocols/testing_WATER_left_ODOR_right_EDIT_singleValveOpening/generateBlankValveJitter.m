function blankValveJitter = generateBlankValveJitter()
    % --- Initialize random number generator --- 
    rng("shuffle");

    % --- Define parameters ---
    expV = ExperimentVariables;
    total_trials = expV.MAXIMUM_TRIALS;

    jitterRange = [-25 -10 0 10 25]/1000; % range converted to ms
    blankValveJitter = jitterRange(randi([1 length(jitterRange)],total_trials,1));

    % a = -15/1000; % bottom of range converted to ms
    % b = 15/1000; % top of range converted to ms
    % N = 2; % for each potential valve opening in a trial
    % 
    % blankValveJitter = round((a + (b-a) * rand(total_trials,N)), 3);
end