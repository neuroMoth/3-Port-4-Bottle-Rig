function SoftCodeHandler(Byte)
    global BpodSystem       

    expV = ExperimentVariables;

    switch (Byte)
        case 1
            % End of session, not currently used (no need to end session partway through a trial)
            BpodSystem.Status.ExitTrialLoop = true; 
            BpodSystem.Status.BeingUsed = 0;
        case 2 
            % trial was not engaged
            BpodSystem.Data.summary.engagedTrials(BpodSystem.Status.trial) = 0; 
            
            fprintf('-> %d skipped. ', sum(BpodSystem.Data.summary.engagedTrials == 0))
            fprintf('Punish. %d sec. ', expV.PUNISHMENT_TIME)
        case 14
            % Report Incorrect
            BpodSystem.Data.summary.correctTrials(BpodSystem.Status.trial) = 0;
            
            % Trial *was* engaged, reset consecutiveRatSkips
            BpodSystem.Data.summary.engagedTrials(BpodSystem.Status.trial) = 1;
            
            fprintf('-> %d incorrect. ', sum(BpodSystem.Data.summary.correctTrials == 0))
            fprintf('Punish. %d sec. ', expV.PUNISHMENT_TIME)
        case 15 
            % Report Correct
            BpodSystem.Data.summary.correctTrials(BpodSystem.Status.trial) = 1;
            
            % Trial *was* engaged, reset consecutiveRatSkips
            BpodSystem.Data.summary.engagedTrials(BpodSystem.Status.trial) = 1;
            
            fprintf('-> %d correct. ', sum(BpodSystem.Data.summary.correctTrials == 1))
    end
end
