function [center_lineup,rewardLickSelect, rewardDelays] = GenerateCenterLineup()
    % --- Initialize random number generator --- 
    rng("shuffle"); % Creates a new seed for each time to ensure independent values 

    % --- Define parameters ---
    expV = ExperimentVariables;
    total_trials = expV.MAXIMUM_TRIALS;
    block_size = expV.TRIALS_PER_BLOCK;
    valveSet1 = [2,3,4]; valveSet2 = [5,6,7]; 
    valves = [valveSet1,valveSet2]; % Now with all valves
    rewardLickRange = [4 5 6]; % Range of possible reward licks
    rewardDelayRange = [0 30 60]/1000; % delay from lick detection to valve opening

    num_blocks = total_trials / block_size; % = 10
    num_valves = length(valves); % = 6
    n_lickRange = length(rewardLickRange); % = 3
    n_rewardDelay = length(rewardDelayRange); % = 3

    % Initialize an empty array to store the final lineup
    center_lineup = []; rewardLickSelect = []; rewardDelays = []; 

    % --- Loop through each block to create the full lineup ---
    for i = 1:num_blocks

        % -- Apply the randomization logic to a SINGLE block of 20 --
        % 20 trials / 6 valves = 3 with a remainder of 2
        valve_num_reps = floor(block_size / num_valves); % = 3
        num_remaining = mod(block_size, num_valves); % = 2

        % Create the base list for one block
        valve_base_list = repmat(valves, 1, valve_num_reps); % repeat 1 row matrix of valves num_reps times

        % Randomly select the 2 extra valves for this block
        if mod(num_remaining,2) == 0 && mod(num_valves,2) == 0 
            % if possible, keep number of tastes and water trials equal per block
            extra_valves1 = valveSet1(randi(floor(num_valves/2), 1, floor(num_remaining/2)));
            extra_valves2 = valveSet2(randi(floor(num_valves/2), 1, floor(num_remaining/2)));
            extra_valves = [extra_valves1,extra_valves2];
        else
            extra_valves = valves(randi(num_valves, 1, num_remaining)); % select 2 random integers in the range of num_valves
        end

        % Combine to create one complete, unshuffled block
        valve_unshuffled_block = [valve_base_list, extra_valves];

        % Shuffle the block
        valve_shuffled_block = valve_unshuffled_block(randperm(block_size));

        % -- Append the newly shuffled block to our master list --
        center_lineup = [center_lineup, valve_shuffled_block];

        % -- NEW: use valve_shuffled_block to select random reward licks and delays --
        % Preallocate arrays
        lickBlock = zeros(1,block_size); delayBlock = lickBlock; 

        % Loop by valve to assign randomized reward lick and delay selection
        for iValve = 1:num_valves
            thisValve = valve_shuffled_block==valves(iValve); % idx for current valve
            nValveTr = sum(thisValve); 

            % Following steps for producing unshuffled blocks
            lick_nReps = floor(nValveTr / n_lickRange); % = 1
            lick_remaining = mod(nValveTr, n_lickRange); % = 0 or 1
            
            delay_nReps = floor(nValveTr / n_rewardDelay); % = 1
            delay_remaining = mod(nValveTr, n_rewardDelay); % = 0 or 1
            
            lickBlock_base = repmat(rewardLickRange, 1, lick_nReps); 
            delayBlock_base = repmat(rewardDelayRange, 1, delay_nReps); 

            extra_licks = rewardLickRange(randi(n_lickRange, 1, lick_remaining));
            extra_delays = rewardDelayRange(randi(n_rewardDelay, 1, delay_remaining));

            lickBlock_unshuffled = [lickBlock_base, extra_licks];
            delayBlock_unshuffled = [delayBlock_base, extra_delays];

            lickBlock(thisValve) = lickBlock_unshuffled(randperm(nValveTr));
            delayBlock(thisValve) = delayBlock_unshuffled(randperm(nValveTr));
        end

        % -- Append the newly shuffled block to our master list --
        rewardLickSelect = [rewardLickSelect, lickBlock];
        rewardDelays = [rewardDelays, delayBlock];
    end

end
