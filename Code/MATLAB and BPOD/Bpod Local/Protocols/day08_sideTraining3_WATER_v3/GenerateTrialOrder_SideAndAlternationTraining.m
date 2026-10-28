
%% GenerateTrialOrder_SideAndAlternationTraining
% This version of the trial order function is only for use during side training and alternation. 
% 
% Each trial/stimulus type (stim1 vs stim2, water vs odor) has its valve order shuffled independently. 
% An array with the order for each trial type is returned. This script can be used with unequal numbers of valves per
% trial/stimulus type. 

function [valveOrder1, valveOrder2] = GenerateTrialOrder_SideAndAlternationTraining()
    %% --- Initialize random number generator ---
    rng("shuffle"); % Creates a new seed for each time to ensure independent values

    expV = ExperimentVariables;
    total_trials = expV.TOTAL_ALLOWED_TIME / 5; % For side/alternation training total trials is a function of total time.
    maxRepeats = expV.MAX_REPEATS; % max number of valve repeats per side
    block_size = 20; % constant for the number of trials per block. Should not be changed. 

    valveSet1 = expV.CENTER_VALVE_SET1; % set of "water" valves
    valveSet2 = expV.CENTER_VALVE_SET2; % set of "odor" valves

    total_trials = ceil(total_trials / block_size) * block_size; % Fit total_trials to block size
    num_blocks = total_trials / block_size; 
    n_v1 = numel(valveSet1); n_v2 = numel(valveSet2);

    % Set threshold for valve repeats on the same side
    if n_v1 == 1; maxV1Rep = inf; else; maxV1Rep = maxRepeats; end
    if n_v2 == 1; maxV2Rep = inf; else; maxV2Rep = maxRepeats; end

    %% Shuffle center valves for each trial type ---
    valveOrder1 = []; valveOrder2 = [];

    % --- Loop through each block to create the full lineup ---
    for j = 1:num_blocks
        % Generate roughly balanced sampling for each variable type
        % Each list is sampled so each element appears about equally often
        numValves1 = floor(block_size / n_v1); numValves2 = floor(block_size / n_v2);

        % Check whether each valve sequence per side exceeds repeat limits
        if n_v1 ~= 0
            isValidV1 = false; attemptsV1 = 0;
            while ~isValidV1
                attemptsV1 = attemptsV1 + 1;
                % Correct side randomization
                v1_seq = repmat(valveSet1, 1, numValves1);
                extra_v1 = valveSet1(randperm(n_v1, block_size - (numValves1 * n_v1)));
                v1_seq = [v1_seq, extra_v1];
                % Shuffle the block
                v1_seq = v1_seq(randperm(numel(v1_seq)));
                v1_seq = v1_seq(1:block_size);
                % Check validity of this block
                if isValidSequence(v1_seq, maxV1Rep); isValidV1 = true; end
                % Safety break
                if attemptsV1 > 2000
                    error('Could not find a valid sequence after many attempts. Try loosening constraints.');
                end
            end
        else; v1_seq = []; 
        end
        
        if n_v2 ~= 0
            isValidV2 = false; attemptsV2 = 0;
            while ~isValidV2
                attemptsV2 = attemptsV2 + 1;
                % Correct side randomization
                v2_seq = repmat(valveSet2, 1, numValves2);
                extra_v2 = valveSet2(randperm(n_v2, block_size - (numValves2 * n_v2)));
                v2_seq = [v2_seq, extra_v2];
                % Shuffle the block
                v2_seq = v2_seq(randperm(numel(v2_seq)));
                v2_seq = v2_seq(1:(block_size));
                % Check validity of this block
                if isValidSequence(v2_seq, maxV2Rep); isValidV2 = true; end
                % Safety break
                if attemptsV2 > 2000
                    error('Could not find a valid sequence after many attempts. Try loosening constraints.');
                end
            end
        else; v2_seq = []; 
        end

        % -- Append the newly shuffled block to the list for each stimulus type --
        valveOrder1 = [valveOrder1, v1_seq];
        valveOrder2 = [valveOrder2, v2_seq];
    end
end

%% Helper function: checks that no more than maxRepeats consecutive values occur (from chatGPT, validated by TVD)
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