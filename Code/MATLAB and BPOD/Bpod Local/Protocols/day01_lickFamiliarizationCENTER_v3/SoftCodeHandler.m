
%% SoftCodeHandler
% This function can recieve a byte sent from the Bpod while a trial is running. 
% This is primarily to allow for the MATLAB command window to print the session results trial by trial. 

function SoftCodeHandler(Byte)
    global BpodSystem       

    switch (Byte)
        case 4
            % For lick familiarization only: number of rewarded licks (stimulus deliveries)
            BpodSystem.Data.rewardedLickCount = BpodSystem.Data.rewardedLickCount + 1;
            
            fprintf('%d\n', BpodSystem.Data.rewardedLickCount)
    end
end
