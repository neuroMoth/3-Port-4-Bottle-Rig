%{
Fs = 44100;    % Sampling rate in Hz (e.g., CD quality)
T = .5;         % Duration in seconds
f = 800;       % Frequency of the tone in Hz

% Generate the time vector
t = 0:1/Fs:T;

% Generate the sinusoidal waveform
y = sin(2*pi*f*t);
%Five_volts = 5 * ones(1, W.SamplingRate/1000); % 1ms 5Volt signal
W.loadWaveform(1, y);         % Loads a sound as waveform 1

W.play(4, 1);
%}
% --- Setup Bpod WavePlayer ---
W = BpodWavePlayer(BpodSystem.ModuleUSB.WavePlayer1);
W.SamplingRate = 44100; % Use a higher sampling rate for better quality

% --- Parameters ---
PreNoiseDuration_s = 2;
BeepDuration_s = 1;
PostNoiseDuration_s = 2;
TotalDuration_s = PreNoiseDuration_s + BeepDuration_s + PostNoiseDuration_s;
BeepFreq_Hz = 5000;    % 5kHz beep
TargetPeakLevel_V = 4; % Target peak voltage, leaving headroom below the 5V limit

% --- Calculate sample counts ---
nSamples = round(TotalDuration_s * W.SamplingRate);
nBeepSamples = round(BeepDuration_s * W.SamplingRate);
nPreSilenceSamples = round(PreNoiseDuration_s * W.SamplingRate);
% Calculate post-noise samples as the remainder to ensure total length is perfect
nPostSilenceSamples = nSamples - nBeepSamples - nPreSilenceSamples;

% --- Generate continuous brown noise for the full duration ---
whiteNoise = randn(1, nSamples);
brownNoise_unscaled = cumsum(whiteNoise);
brownNoise = (brownNoise_unscaled / max(abs(brownNoise_unscaled))) * TargetPeakLevel_V;

% --- Generate the beep ---
% --- Generate the beep using basic MATLAB functions ---
% Create a time vector from 0 to the duration, with the correct number of samples
t = (0:nBeepSamples - 1) / W.SamplingRate;

% Generate the sinusoidal waveform directly
beepWave = sin(2*pi*BeepFreq_Hz*t);

% This ensures beepWave will always have the exact number of samples (nBeepSamples)
beepWave = beepWave * (TargetPeakLevel_V / 2); % Make beep audible but not max volume

% Pad the beep with zeros to match the total duration
beepSignal = [zeros(1, nPreSilenceSamples), beepWave, zeros(1, nPostSilenceSamples)];

% --- Calculate RMS values ---
rms_noise = sqrt(mean(brownNoise.^2));
rms_beep = sqrt(mean(beepWave.^2)); % Only calculate RMS of the beep part, not the silence

% *** FIX #2: Add a check to prevent a complex number result ***
if rms_beep^2 >= rms_noise^2
    error('Beep power is too high compared to noise power. Reduce beep amplitude or increase noise amplitude.');
end

% This is the gain factor we need to apply to the noise during the beep
noise_gain_during_beep = sqrt(rms_noise^2 - rms_beep^2) / rms_noise;

% --- Create the gain envelope for the brown noise ---
noiseEnvelope = ones(1, nSamples); % Start with a gain of 1 (100% volume)
beep_start_index = nPreSilenceSamples + 1;
beep_end_index = nPreSilenceSamples + nBeepSamples;
noiseEnvelope(beep_start_index:beep_end_index) = noise_gain_during_beep;

% --- Create the final waveform ---
adjustedBrownNoise = brownNoise .* noiseEnvelope;
finalWaveform = adjustedBrownNoise + beepSignal; % This will now work without error

% Final safety check: ensure we don't exceed the hardware limit
if max(abs(finalWaveform)) > 5
    finalWaveform = finalWaveform * (5 / max(abs(finalWaveform)));
    disp('Warning: Final waveform was rescaled to prevent clipping.');
end

% --- Load and Play the Correct Waveform ---
% *** FIX #3: Load and play the 'finalWaveform', not the intermediate one ***
W.loadWaveform(1, finalWaveform);
W.loadWaveform(2,brownNoise);

     sma = NewStateMachine();
     
     sma = SetGlobalCounter(sma, 1, 'AnalogIn1_1', 3); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)?


     sma = AddState(sma, 'Name', 'start', ...
         'Timer', 5,...
         'StateChangeConditions', {'Tup', 'centerDown'},...
         'OutputActions',{'WavePlayer1', ['P' 8 2]});

          sma = AddState(sma, 'Name', 'centerDown', ...
         'Timer', 0,...
         'StateChangeConditions', {'Tup', 'backToBrown'},...
         'OutputActions',{'WavePlayer1', ['P' 8 2]});

                    sma = AddState(sma, 'Name', 'backToBrown', ...
         'Timer', 5,...
         'StateChangeConditions', {'Tup', 'exit'},...
         'OutputActions',{'WavePlayer1', ['P' 8 1]});

          SendStateMachine(sma);
     events = RunStateMachine();