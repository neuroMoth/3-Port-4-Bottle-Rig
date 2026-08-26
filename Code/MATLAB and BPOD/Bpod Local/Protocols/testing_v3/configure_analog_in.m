function A = configure_analog_in
    global BpodSystem

    % Assert Analog Input module is present + USB-paired (via USB button on console GUI)
    BpodSystem.assertModule('AnalogIn', 1);

    A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
    A.SamplingRate = 5000; % Set the sampling rate to 5kHz
    A.nActiveChannels = 4;
    % enable event reporting on AnalogInput1. This sends lick 'events' to the state machine to be processed/counted.
    [A.InputRange{1:4}] = deal('0V:5V'); % Set input range
    A.SMeventsEnabled(1:4) = 1; 
    % This sets threshold voltages that we want to cross to generate events. Here we use 1 volt.
    %A.Thresholds(1:4) = 1;
    A.Thresholds = [5 5 5 5 0 0 0 0; 1 1 1 1 0 0 0 0];
    % ResetVoltages sets the higher voltage bound that must be crossed before a
    % new event can trigger. Here we must go above 5 volts.
    %A.ResetVoltages(1:4) = 5;
    A.Thresholds = [1 1 1 1 0 0 0 0; 5 5 5 5 0 0 0 0];
    % Tell the AnalogInput1 module to start reporting events to the
    % state machine
    A.startReportingEvents();
    % View all channels by default - added by TVD 10/11/2025
    A.Stream2USB(1:4) = 1;
    
    %behaviorDataFile = BpodSystem.Path.CurrentDataFile;
    %A.USBStreamFile = [behaviorDataFile(1:end-4) '_Alg.mat']; % Set datafile for analog data captured in this session
    
    % start the oscilliscope.
    A.scope();
    A.scope_StartStop;
end
