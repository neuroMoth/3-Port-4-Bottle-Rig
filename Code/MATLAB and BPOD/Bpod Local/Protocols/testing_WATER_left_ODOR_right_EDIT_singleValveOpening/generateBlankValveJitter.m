function blankValveJitter = generateBlankValveJitter()
    % --- Initialize random number generator --- 
    rng("shuffle");

    % --- Define parameters ---
    expV = ExperimentVariables;
    total_trials = expV.MAXIMUM_TRIALS;
    a = -10/1000; % bottom of range converted to ms
    b = 10/1000; % top of range converted to ms
    N = 6; % for each potential valve opening in a trial

    blankValveJitter = round((a + (b-a) * rand(total_trials,N)), 4);
end