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

            fprintf('-> Punish. ')
            if BpodSystem.Status.consecutiveRatSkips > 1; fprintf('%d consecutive skips. ',BpodSystem.Status.consecutiveRatSkips); end
        case 3 
            trial = BpodSystem.Status.trial;
            % trial *was* engaged, reset consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = 0; 
            
            BpodSystem.Data.trialsEngaged(trial) = 1;
        case 15 
            BpodSystem.Data.CorrectTrials = BpodSystem.Data.CorrectTrials + 1;
            fprintf('-> %d correct. ',BpodSystem.Data.CorrectTrials)

            if (mod(BpodSystem.Data.CorrectTrials, expV.CORRECT_REQUIRED_TO_SWITCH) == 0)
                BpodSystem.Status.switchStimulusFlag = true;
            end
    end
end
