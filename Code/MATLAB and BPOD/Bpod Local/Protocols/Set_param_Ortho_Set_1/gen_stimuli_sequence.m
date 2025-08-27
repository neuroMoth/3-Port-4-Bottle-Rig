function stimuli_sequence = gen_stimuli_sequence(BpodSystem)

%gives you the number of columns in the curr_odor_numb_array

num_stimuli = size(BpodSystem.ProtocolSettings.GUIPanels.stimuli_ID,2)-1; % remove the blank vial  
stimuli_lines = (1:Set_param_constants.NUM_VALVES); % Lines will be numbered 1 through 8
[~,~,Perms] = uniqperms(stimuli_lines);  % use the function uniqperm to generate unique permutation depending on the taste
stimuli_sequence = reshape(Perms', 1, []);
stimuli_sequence = stimuli_sequence(1:BpodSystem.ProtocolSettings.GUI.num_trials);
