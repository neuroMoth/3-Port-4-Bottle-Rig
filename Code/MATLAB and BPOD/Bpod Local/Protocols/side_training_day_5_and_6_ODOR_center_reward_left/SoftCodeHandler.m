function SoftCodeHandler(Byte)
    global BpodSystem       

    if(Byte == 1)
    end

    if(Byte == 3)
        BpodSystem.Status.ExitTrialLoop = true;
   
        BpodSystem.Status.BeingUsed = 0;
    end
end
