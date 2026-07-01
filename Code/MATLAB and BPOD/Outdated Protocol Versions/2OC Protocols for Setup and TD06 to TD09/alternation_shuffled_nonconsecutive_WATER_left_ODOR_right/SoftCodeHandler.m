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

            trial = BpodSystem.Status.trial;
            BpodSystem.Data.lateralPortChoice(trial) = BpodSystem.Data.correctPort(trial);

            % TVD - trying to call a system variable instead of expV constant
            if (mod(BpodSystem.Data.CorrectTrials, BpodSystem.Status.correct_required_to_switch) == 0)
                BpodSystem.Status.switchStimulusFlag = true;
            end
    end
end
