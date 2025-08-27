function SoftCodeHandler(Byte)
    global BpodSystem       

    expV = ExperimentVariables;

    switch (Byte)
        case 1
            BpodSystem.Status.ExitTrialLoop = true;
            BpodSystem.Status.BeingUsed = 0;
        case 2
            % trial was not engaged, increment consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = BpodSystem.Status.consecutiveRatSkips + 1; 
            BpodSystem.Status.consecutiveRatSkips 
            
            BpodSystem.Data.trialsEngaged(BpodSystem.Status.trial) = 0;
        case 3 
            trial = BpodSystem.Status.trial;
            % trial *was* engaged, reset consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = 0; 
            
            BpodSystem.Data.trialsEngaged(trial) = 1;
        case 15 
            BpodSystem.Data.CorrectTrials = BpodSystem.Data.CorrectTrials + 1;

            if (mod(BpodSystem.Data.CorrectTrials, expV.CORRECT_REQUIRED_TO_SWITCH) == 0)
                BpodSystem.Status.switchStimulusFlag = true;
            end
    end
end
