function SoftCodeHandler(Byte)
    global BpodSystem       

    expV = ExperimentVariables;

    switch (Byte)
        case 1
            BpodSystem.Status.ExitTrialLoop = true; % End of session
            BpodSystem.Status.BeingUsed = 0;
        case 2 
            % trial was not engaged, increment consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = BpodSystem.Status.consecutiveRatSkips + 1; 
            
            fprintf('-> %d consecutive skips. ',BpodSystem.Status.consecutiveRatSkips); 
            % fprintf('Punish. %d sec. ',expV.PUNISHMENT_TIME)
        case 3 
            % Trial *was* engaged, reset consecutiveRatSkips
            BpodSystem.Status.consecutiveRatSkips = 0; 
            BpodSystem.Data.trialsEngaged(BpodSystem.Status.trial) = 1;
        case 14
            % Report Incorrect
            BpodSystem.Data.correctTrials(BpodSystem.Status.trial) = 0;
            % fprintf('-> %d total incorrect. ',sum(BpodSystem.Data.correctTrials==0))
            % fprintf('Punish. %d sec. ',expV.PUNISHMENT_TIME)
        case 15 
            % Report Correct
            BpodSystem.Data.correctTrials(BpodSystem.Status.trial) = 1;
            %fprintf('-> %d total correct. ',sum(BpodSystem.Data.correctTrials==1))
    end
end
