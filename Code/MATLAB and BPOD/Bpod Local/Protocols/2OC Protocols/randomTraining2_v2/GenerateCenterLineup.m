function [center_lineup, rewardLickOrder, rewardDelays] = GenerateCenterLineup()
%% --- Initialize random number generator ---
rng("shuffle"); % Creates a new seed for each time to ensure independent values

% --- Define parameters ---
expV = ExperimentVariables;
total_trials = expV.MAXIMUM_TRIALS;
block_size = expV.TRIALS_PER_BLOCK;
maxRepeats = expV.MAX_REPEATS;

rewardLickRange = expV.REWARD_LICKS;
rewardDelayRange = expV.REWARD_VALVE_DELAY;

valveSet1 = expV.VALVE_SET1;
valveSet2 = expV.VALVE_SET2;

num_blocks = total_trials / block_size; % = 8
n_v1 = numel(valveSet1); n_v2 = numel(valveSet2);
n_lickRange = numel(rewardLickRange); % = 3
n_rewardDelay = numel(rewardDelayRange); % = 3

% Set threshold for valve repeats on the same side (constraint in addition to max side repeats)
if n_v1 == 1; maxV1Rep = inf; else; maxV1Rep = 2; end
if n_v2 == 1; maxV2Rep = inf; else; maxV2Rep = 2; end

%% --- First: pseudorandom order generation for trial side order ---
isValid = false; attempts = 0;
while ~isValid
    attempts = attempts + 1;
    % Initialize an empty array to store the final side lineup
    side_lineup = [];

    % --- Loop through each block to create the full lineup ---
    for i = 1:num_blocks

        % -- Apply the randomization logic to a SINGLE block of 20 --
        side_num_reps = floor(block_size / 2);
        isValidBlock = false;
        while ~isValidBlock
            % Correct side randomization
            side_base_list = repmat([0,1], 1, side_num_reps); % 0 is Left, 1 is Right
            side_shuffled_block = side_base_list(randperm(block_size)); % Shuffle the block

            % Check validity of this block
            if isValidSequence(side_shuffled_block, maxRepeats)
                isValidBlock = true;
            end
        end
        side_lineup = [side_lineup, side_shuffled_block];
    end

    % Check validity of whole session sequence
    if isValidSequence(side_lineup, maxRepeats)
        isValid = true; % Must pass for the whole session sequence for this sequence to be accepted
    end

    % Safety break
    if attempts > 5000
        error('Could not find a valid sequence after many attempts. Try loosening constraints.');
    end
end

%% You can use these plots to check distribution of trial side repeats from this function
% changeIdx = [find(diff(side_lineup) ~= 0), length(side_lineup)]; sideReps = diff([0, changeIdx]);
% histogram(sideReps, 'Normalization','probability','Normalization','pdf','DisplayStyle','stairs','LineWidth',2);
% keyboard

%% --- Second: Shuffle center valves, reward lick #, and delay for each trial type ---
center_lineup = []; rewardLickOrder = []; rewardDelays = [];
blockStep = 1:block_size:total_trials;

% --- Loop through each block to create the full lineup ---
for j = 1:num_blocks
    % Generate roughly balanced sampling for each variable type
    % Each list is sampled so each element appears about equally often
    numValves1 = floor(block_size / (2*n_v1)); numValves2 = floor(block_size / (2*n_v2));
    numRewLick = floor(block_size / (2*n_lickRange));
    numDelays = floor(block_size / (2*n_rewardDelay));

    lickN_seq = repmat(rewardLickRange, 1, numRewLick);
    extra_lickN = rewardLickRange(randperm(n_lickRange,(block_size/2)-(numRewLick*n_lickRange)));
    lickN_seq = [lickN_seq, extra_lickN];

    delay_seq = repmat(rewardDelayRange, 1, numDelays);
    extra_delay = rewardDelayRange(randperm(n_rewardDelay,(block_size/2)-(numDelays*n_rewardDelay)));
    delay_seq = [delay_seq, extra_delay];

    % Truncate to desired trial count
    lickN_seq = lickN_seq(1:(block_size/2));
    delay_seq = delay_seq(1:(block_size/2));
    % Randomly permute within each variable type
    lickN_seq = lickN_seq(randperm(numel(lickN_seq)));
    delay_seq = delay_seq(randperm(numel(delay_seq)));

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

    % Optimize reward lick and delay shuffling to minimize repeated combinations
    % Heuristic search – reshuffles B and C to reduce identical combinations
    bestCombo1 = []; bestCombo2 = [];
    bestRepeatCount = inf; maxIterations = 500;
    % Split each sequence to shuffle independently for each side (L/R)
    % Two separate for loops
    for k1 = 1:maxIterations
        % Shuffle reward lick and delays while keeping valve order fixed
        % Split each sequence to shuffle independently for each side (L/R)
        lickN_seq1 = lickN_seq(randperm(block_size/2));
        delay_seq1 = delay_seq(randperm(block_size/2));

        % Combine into trial matrix
        Trials_temp1 = [v1_seq(:), lickN_seq1(:), delay_seq1(:)];

        % Count repeated rows
        [~, ~, ic] = unique(Trials_temp1, 'rows');
        counts = histcounts(ic, 1:(max(ic)+1));
        maxRepeat = max(counts);

        % Keep configuration with fewest repeats
        if maxRepeat < bestRepeatCount
            bestRepeatCount = maxRepeat;
            bestCombo1 = Trials_temp1;
            if bestRepeatCount <= 1
                break; % Perfect (no duplicates)
            end
        end
    end
    bestRepeatCount = inf;
    for k2 = 1:maxIterations
        % Shuffle reward lick and delays while keeping valve order fixed
        lickN_seq2 = lickN_seq(randperm(block_size/2));
        delay_seq2 = delay_seq(randperm(block_size/2));

        % Combine into trial matrix
        Trials_temp2 = [v2_seq(:), lickN_seq2(:), delay_seq2(:)];

        % Count repeated rows
        [~, ~, ic] = unique(Trials_temp2, 'rows');
        counts = histcounts(ic, 1:(max(ic)+1));
        maxRepeat = max(counts);

        % Keep configuration with fewest repeats
        if maxRepeat < bestRepeatCount
            bestRepeatCount = maxRepeat;
            bestCombo2 = Trials_temp2;
            if bestRepeatCount <= 1
                break; % Perfect (no duplicates)
            end
        end
    end

    %% USE THE SIDE LINEUP GENERATED EARLIER TO CREATE THE FULL CENTER ORDER
    valveBlock = zeros(1, block_size); lickBlock = valveBlock; delayBlock = lickBlock;
    thisBlockSides = side_lineup(blockStep(j):(blockStep(j)+block_size-1));

    valveBlock(thisBlockSides == 0) = v1_seq; valveBlock(thisBlockSides == 1) = v2_seq;
    lickBlock(thisBlockSides == 0) = bestCombo1(:,2); lickBlock(thisBlockSides == 1) = bestCombo2(:,2);
    delayBlock(thisBlockSides == 0) = bestCombo1(:,3); delayBlock(thisBlockSides == 1) = bestCombo2(:,3);

    % -- Append the newly shuffled block to our master list --
    center_lineup = [center_lineup, valveBlock];
    rewardLickOrder = [rewardLickOrder, lickBlock];
    rewardDelays = [rewardDelays, delayBlock];
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

%% Old shuffle code
% jitterBlock = lickBlock; jitterBlock_lateral = lickBlock;
% % Loop by valve to assign randomized reward lick and delay selection
% for iValve = 1:num_valves
%     thisValve = valve_shuffled_block==valves(iValve); % idx for current valve
%     nValveTr = sum(thisValve);
%
%     % Following steps for producing unshuffled blocks
%     lick_nReps = floor(nValveTr / n_lickRange); % = 1
%     lick_remaining = mod(nValveTr, n_lickRange); % = 0 or 1
%
%     delay_nReps = floor(nValveTr / n_rewardDelay); % = 1
%     delay_remaining = mod(nValveTr, n_rewardDelay); % = 0 or 1
%
%     % jitter_nReps = floor(nValveTr / n_jitter);
%     % jitterRemaining = mod(nValveTr, n_jitter);
%
%     lickBlock_base = repmat(rewardLickRange, 1, lick_nReps);
%     delayBlock_base = repmat(rewardDelayRange, 1, delay_nReps);
%     % jitterBlock_base = repmat(jitterRange, 1, jitter_nReps);
%
%     extra_licks = rewardLickRange(randsample(n_lickRange, lick_remaining));
%     extra_delays = rewardDelayRange(randsample(n_rewardDelay, delay_remaining));
%     % extra_jitter = jitterRange(randsample(n_jitter, jitterRemaining));
%
%     lickBlock_unshuffled = [lickBlock_base, extra_licks];
%     delayBlock_unshuffled = [delayBlock_base, extra_delays];
%     % jitterBlock_unshuffled = [jitterBlock_base,extra_jitter];
%
%     lickBlock(thisValve) = lickBlock_unshuffled(randperm(nValveTr));
%     delayBlock(thisValve) = delayBlock_unshuffled(randperm(nValveTr));
% %     % jitterBlock(thisValve) = jitterBlock_unshuffled(randperm(nValveTr));
%
% % 20 trials / 6 valves = 3 with a remainder of 2
%             valve_num_reps = floor(block_size / num_valves); % = 3
%             num_remaining = mod(block_size, num_valves); % = 2
%             % Create the base list for one block
%             valve_base_list = repmat(valves, 1, valve_num_reps); % repeat 1 row matrix of valves num_reps times
%
% % Randomly select the 2 extra valves for this block
% if mod(num_remaining,2) == 0 && mod(num_valves,2) == 0
%     % keep number of tastes and water trials equal per block
%     extra_valves1 = valveSet1(randi(floor(num_valves/2), 1, floor(num_remaining/2)));
%     extra_valves2 = valveSet2(randi(floor(num_valves/2), 1, floor(num_remaining/2)));
%     extra_valves = [extra_valves1,extra_valves2];
% else
%     extra_valves = valves(randsample(num_valves, num_remaining)); % select 2 random integers in the range of num_valves
% end
%
% % Combine to create one complete, unshuffled block
% valve_unshuffled_block = [valve_base_list, extra_valves];
%
%
% % end
% %
% % % jitterBlock_lateral = jitterBlock(randperm(block_size));
% %
% % % -- Append the newly shuffled block to our master lists --
% rewardLickOrder = [rewardLickOrder, lickBlock];
% rewardDelays = [rewardDelays, delayBlock];
% % % blankValveJitter = [blankValveJitter, jitterBlock];
% % % blankValveJitter_lateral = [blankValveJitter_lateral, jitterBlock_lateral];
%
% Blank valve jitter also applies to the reward valves
%blankValveJitter = [blankValveJitter; blankValveJitter_lateral]';