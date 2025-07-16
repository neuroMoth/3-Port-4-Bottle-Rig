function launch_lick_stick(byte)

if ismember('L1', who('global'))
    clear global L1
    clear L1
    global L1
    if byte==1
        L1 = LickStick('COM7');
        L1.samplingRate = 2000;
        L1.stream;
        %if threshold == 0
        %else
        %    L1.threshold = threshold;
        %end
    else
    end
else
    global L1
    if byte==1
        L1 = LickStick('COM7');
        L1.samplingRate = 2000;
        L1.stream;
        %if threshold == 0
        %else
        %    L1.threshold = threshold;
        %end
    else
    end
end