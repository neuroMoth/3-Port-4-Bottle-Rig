function [water_lineup, odor_lineup] = GenerateCenterLineup_SideTraining()
%% --- Initialize random number generator ---
rng("shuffle"); % Creates a new seed for each time to ensure independent values

% --- Define parameters ---
expV = ExperimentVariables;
total_trials = expV.TOTAL_ALLOWED_TIME / 5; % FOR SIDE TRAINING: "total trials" variable is a function of total time.
block_size = expV.TRIALS_PER_BLOCK;

valveSet1 = expV.VALVE_SET1; % water valves
valveSet2 = expV.VALVE_SET2; % odor valves

num_blocks = ceil(total_trials / block_size); % = 8
n_v1 = numel(valveSet1); n_v2 = numel(valveSet2);

% Set threshold for valve repeats on the same side (constraint in addition to max side repeats)
if n_v1 == 1; maxV1Rep = inf; else; maxV1Rep = 2; end
if n_v2 == 1; maxV2Rep = inf; else; maxV2Rep = 2; end

%% --- Shuffle center valves for each trial type ---
water_lineup = []; odor_lineup = [];

% --- Loop through each block to create the full lineup ---
for j = 1:num_blocks
    % Generate roughly balanced sampling for each variable type
    % Each list is sampled so each element appears about equally often
    numValves1 = floor(block_size / (2*n_v1)); numValves2 = floor(block_size / (2*n_v2));

    % Check whether each valve sequence per side exceeds repeat limits
    isValidV1 = false; attemptsV1 = 0;
    while ~isValidV1
        attemptsV1 = attemptsV1 + 1;
        % Correct side randomization
        v1_seq = repmat(valveSet1, 1, numValves1);
        extra_v1 = valveSet1(randperm(n_v1,(block_size/2)-(numValves1*n_v1)));
        v1_seq = [v1_seq, extra_v1];
        % Shuffle the block
        v1_seq = v1_seq(randperm(numel(v1_seq)));
        v1_seq = v1_seq(1:(block_size/2));
        % Check validity of this block
        if isValidSequence(v1_seq, maxV1Rep); isValidV1 = true; end
        % Safety break
        if attemptsV1 > 2000
            error('Could not find a valid sequence after many attempts. Try loosening constraints.');
        end
    end
    isValidV2 = false; attemptsV2 = 0;
    while ~isValidV2
        attemptsV2 = attemptsV2 + 1;
        % Correct side randomization
        v2_seq = repmat(valveSet2, 1, numValves2);
        extra_v2 = valveSet2(randperm(n_v2,(block_size/2)-(numValves2*n_v2)));
        v2_seq = [v2_seq, extra_v2];
        % Shuffle the block
        v2_seq = v2_seq(randperm(numel(v2_seq)));
        v2_seq = v2_seq(1:(block_size/2));
        % Check validity of this block
        if isValidSequence(v2_seq, maxV2Rep); isValidV2 = true; end
        % Safety break
        if attemptsV2 > 2000
            error('Could not find a valid sequence after many attempts. Try loosening constraints.');
        end
    end
    
    % -- Append the newly shuffled block to our master list --
    water_lineup = [water_lineup, v1_seq];
    odor_lineup = [odor_lineup, v2_seq];
end

end

%% Helper function: checks that no more than maxRepeats consecutive values occur (chatGPT, checked by TVD)
function valid = isValidSequence(seq, maxRepeats)
runLength = 1;
valid = true;
for i = 2:length(seq)
    if seq(i) == seq(i-1)
        runLength = runLength + 1;
        if runLength > maxRepeats
            valid = false;
            return;
        end
    else
        runLength = 1;
    end
end
end
