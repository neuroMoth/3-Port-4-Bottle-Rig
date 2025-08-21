BpodSystem.FlexIOConfig.channelTypes = [1 1 1 1];
A = BpodAnalogIn('COM6');
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

% Decimal:8 -> binary:1000 -> analog output 4 (WavePlayer1)
% Decimal:4 -> binary:0100 -> analog output 3 (WavePlayer1)
W = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1); % Create an instance of the WavePlayer 4 channels
%J = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer2); % Create an instance of the WavePlayer 8 channels

W.SamplingRate = 44100; %10KHz sampilng rate
%J.SamplingRate = 10000; %10KHz sampilng rate

Fs = 44100;    % Sampling rate in Hz (e.g., CD quality)
T = 5;         % Duration in seconds
f = 800;       % Frequency of the tone in Hz

% Generate the time vector
t = 0:1/Fs:T;

% Generate the sinusoidal waveform
y = sin(2*pi*f*t);
%Five_volts = 5 * ones(1, W.SamplingRate/1000); % 1ms 5Volt signal
W.loadWaveform(1, y);         % Loads a sound as waveform 1
%W.loadWaveform(2, -1*Five_volts); % Loads a single -5V sample as waveform 2
%W.loadWaveform(3, Five_volts);    % Loads a single 5V sample as waveform 3

%%
 S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'

 for current_trial = 1:60
  

     sma = NewStateMachine();
     
     sma = SetGlobalCounter(sma, 1, 'AnalogIn1_1', 3); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?


     sma = AddState(sma, 'Name', 'start', ...
         'Timer', 30,...
         'StateChangeConditions', {'Tup', 'exit'},...
         'OutputActions',{'WavePlayer1', ['P' 8 1]});

   

     SendStateMachine(sma);
     events = RunStateMachine();
     events
     
     HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
     if BpodSystem.Status.BeingUsed == 0
        A.endAcq; % Close Oscope GUI
        A.stopReportingEvents; % Stop sending events to state machine
        return
    end
 end








    