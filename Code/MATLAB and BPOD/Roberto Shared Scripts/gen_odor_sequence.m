function OdorSequence = gen_odor_sequence(BpodSystem)

curr_odor_numb = size(BpodSystem.ProtocolSettings.GUIPanels.Current_Odor_ID,2)-1; % remove the blank vial  
odor_lines = (1:curr_odor_numb)+4; % because the olfactometer has lines 5 to 11
[~,~,Perms] = uniqperms(odor_lines);  % use the function uniqperm to generate unique permutation depending on the taste
OdorSequence = reshape(Perms',1,size(odor_lines,2)*size(Perms,1));  
OdorSequence = OdorSequence(1:BpodSystem.ProtocolSettings.GUI.notrials);