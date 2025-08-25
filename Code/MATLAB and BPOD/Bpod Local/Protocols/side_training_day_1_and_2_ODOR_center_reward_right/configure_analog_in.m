function A = configure_analog_in
    global BpodSystem

    % Assert Analog Input module is present + USB-paired (via USB button on console GUI)
    BpodSystem.assertModule('AnalogIn', 1);

    A = BpodAnalogIn(BpodSystem.ModuleUSB.AnalogIn1);
    A.nActiveChannels = 4;
    % enable event reporting on AnalogInput1. This sends lick 'events' (5v
    % threshold reached) to the state machine to be processed/counted.
    A.SMeventsEnabled(1:4) = 1;
    % This sets threshold voltages that we want to exceed to generate events.
    % Here we use 5 volts.
    A.Thresholds(1:4) = 5;
    % ResetVoltages sets the lower voltage bound that must be crossed before a
    % new event can trigger. Here we must go below 1 volt.
    A.ResetVoltages(1:4) = 1;
    % Tell the AnalogInput1 module to start reporting events to the
    % state machine
    A.startReportingEvents();
    % start the oscilliscope.
    A.scope();
    A.scope_StartStop;
end
