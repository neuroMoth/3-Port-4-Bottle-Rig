%% GenerateTrialOrder
% The current version of this function randomly selects a set of trial order blocks generated using the PyGellermann 
% software package. These generated blocks use sequences which follow the Gellermann series constraints. Sequences that
% cross between blocks are not bound by these constraints, but each full session is additionally constrained by the 
% max repeat threshold set in ExperimentVariables. 
% 
% The first array returned is the order of trials in terms of "type" (in this case, odor or water). 
% The 2nd array returned is the order of stimulus valves used to load each stimulus. 

function [trial_type_order, stim_valve_order] = GenerateTrialOrder()
    %% --- Initialize random number generator ---
    rng("shuffle"); % Creates a new seed for each time to ensure independent values

    % --- Define parameters ---
    gellermannBlocks = load("gellermannSeries_20TrBlock_0.2alternationTolerance");

    expV = ExperimentVariables;
    total_trials = expV.MAXIMUM_TRIALS;
    maxRepeats = expV.MAX_REPEATS; % since gellermann blocks have a default max 3 repeats, this only applies to repeats across blocks
    block_size = 20; % this is now a constant because it can't vary from the pygellermann generated block size

    valveSet1 = expV.CENTER_VALVE_SET1; % set of "water" valves
    valveSet2 = expV.CENTER_VALVE_SET2; % set of "odor" valves

    if rem(total_trials, block_size) ~= 0; error('Maximum trials variable incompatible with trial block size. '); end
    num_blocks = total_trials / block_size; % = 8
    n_v1 = numel(valveSet1); n_v2 = numel(valveSet2);

    % Set threshold for valve repeats on the same side (constraint in addition to max side repeats)
    if n_v1 == 1; maxV1Rep = inf; else; maxV1Rep = 2; end
    if n_v2 == 1; maxV2Rep = inf; else; maxV2Rep = 2; end

    %% --- First: pseudorandom order generation for trial side order ---
    isValid = false; attempts = 0;
    while ~isValid
        attempts = attempts + 1;

        % Select set of blocks from gellermann series
        iSessionBlocks = randperm(size(gellermannBlocks.cell, 1), num_blocks)';
        blockOrders =  gellermannBlocks.cell(iSessionBlocks, :)';
        trial_type_order = cell2mat(blockOrders(:))';

        % Check validity of whole session sequence
        if isValidSequence(trial_type_order, maxRepeats)
            isValid = true; % Must pass for the whole session sequence for this sequence to be accepted
        end

        % Safety break
        if attempts > 5000
            error('Could not find a valid sequence after many attempts. Try loosening constraints.');
        end
    end

    %% You can use these plots to check distribution of trial side repeats from this function
    % changeIdx = [find(diff(trial_type_order) ~= 0), length(trial_type_order)]; sideReps = diff([0, changeIdx]);
    % histogram(sideReps, 'Normalization','probability','Normalization','pdf','DisplayStyle','stairs','LineWidth',2);
    % keyboard

    %% --- Second: Shuffle center valves for each trial type ---
    stim_valve_order = [];
    blockStep = 1:block_size:total_trials;

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

        %% USE THE SIDE LINEUP GENERATED EARLIER TO CREATE THE FULL CENTER ORDER
        valveBlock = zeros(1, block_size); 
        thisBlockSides = trial_type_order(blockStep(j):(blockStep(j)+block_size-1));

        valveBlock(thisBlockSides == 0) = v1_seq; valveBlock(thisBlockSides == 1) = v2_seq;

        % -- Append the newly shuffled block to our master list --
        stim_valve_order = [stim_valve_order, valveBlock];
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