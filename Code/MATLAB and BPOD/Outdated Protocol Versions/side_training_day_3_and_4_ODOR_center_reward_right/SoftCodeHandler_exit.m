function SoftCodeHandler_exit(Byte)
    global BpodSystem       

    if(Byte == 3)
        BpodSystem.Status.ExitTrialLoop = true;
   
        BpodSystem.Status.BeingUsed = 0;
    end
end
