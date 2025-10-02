function center_lineup = GenerateCenterLineup()
    % --- Initialize random number generator --- 
    rng(0,'twister');

    % --- Define parameters ---
    expV = ExperimentVariables;
    total_trials = expV.MAXIMUM_TRIALS;
    block_size = expV.TRIALS_PER_BLOCK;
    valves = [2, 5]; % Only 2 and 5 for preliminary data collection

    num_blocks = total_trials / block_size; % = 10
    num_valves = length(valves); % = 6

    % Initialize an empty array to store the final lineup
    center_lineup = [];

    % --- Loop through each block to create the full lineup ---
    for i = 1:num_blocks

        % -- Apply the randomization logic to a SINGLE block of 20 --
        % 20 trials / 6 valves = 3 with a remainder of 2
        num_reps = floor(block_size / num_valves);      % = 3
        num_remaining = mod(block_size, num_valves); % = 2

        % Create the base list for one block
        base_list = repmat(valves, 1, num_reps); % repeat 1 row matrix of valves num_reps times

        % Randomly select the 2 extra valves for this block
        extra_valves = valves(randi(num_valves, 1, num_remaining)); % select 2 random integers in the range of num_valves

        % Combine to create one complete, unshuffled block
        unshuffled_block = [base_list, extra_valves];

        % Shuffle the block
        shuffled_block = unshuffled_block(randperm(block_size));

        % -- Append the newly shuffled block to our master list --
        center_lineup = [center_lineup, shuffled_block];

    end
end
