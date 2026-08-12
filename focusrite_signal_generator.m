%% Focusrite Scarlett 2i2 - Signal Generator v1.0
% OASiS Acoustics Bootcamp
% Created: 20260811 SJM sjmurr@mit.edu
% Updated:

% Notes:

clear;
clc;

%% ================= USER SETTINGS =================

deviceName = "Focusrite USB ASIO";
filename = "Impulse_5.0kHz.wav";

playFs      = 44100;    % Playback sample rate [Hz]
toneFreq    = 10000;     % Sine-wave frequency [Hz]
duration    = 1;      % Signal duration [seconds]
amplitude   = 0.20;     % Amplitude: 0 to 1 -> Playback gain


frameSize   = 1024;     % Samples sent to interface per write

% Output routing:
%   "both"  -> Scarlett outputs 1 and 2
%   "left"  -> output 1 only
%   "right" -> output 2 only
outputMode = "both";

%% ================= CHECK SETTINGS =================

if toneFreq >= playFs/2
    error("toneFreq must be less than the Nyquist frequency playFs/2.");
end

if amplitude < 0 || amplitude > 1
    error("amplitude must be between 0 and 1.");
end

%% ================= CREATE AUDIO =================

% Number of samples in the requested signal
numSamples = round(duration * playFs);

% Time vector
t = (0:numSamples-1)' / playFs;

% Generate sine wave
tone = amplitude * sin(2*pi*toneFreq*t);

%plot(tone);

%% Optional short fade-in/fade-out
% Prevents an abrupt start/stop from producing clicks.
%{
fadeTime = 0.005;                   % 5 ms
fadeSamples = round(fadeTime*playFs);

if 2*fadeSamples < numSamples

    fadeIn = linspace(0,1,fadeSamples)';
    fadeOut = linspace(1,0,fadeSamples)';

    tone(1:fadeSamples) = ...
        tone(1:fadeSamples).*fadeIn;

    tone(end-fadeSamples+1:end) = ...
        tone(end-fadeSamples+1:end).*fadeOut;
end
%}
%% ================= OUTPUT CHANNELS =================

switch lower(outputMode)

    case "both"
        % Column 1 -> output 1
        % Column 2 -> output 2
        audioSignal = [tone tone];

    case "left"
        % Signal on output 1, silence on output 2
        audioSignal = [tone zeros(size(tone))];

    case "right"
        % Silence on output 1, signal on output 2
        audioSignal = [zeros(size(tone)) tone];

    otherwise
        error('outputMode must be "both", "left", or "right".');

end

%% ================= CREATE DEVICE WRITER =================

deviceWriter = audioDeviceWriter( ...
    Driver="ASIO", ...
    Device=deviceName, ...
    SampleRate=playFs);

%% ================= DEVICE INFORMATION =================

disp(" ");
disp("===== DEVICE INFORMATION =====");
disp(info(deviceWriter));

%% ================= SHOW ALL PROPERTIES =================

disp(" ");
disp("===== AUDIO DEVICE WRITER PROPERTIES =====");

propNames = properties(deviceWriter);

for k = 1:numel(propNames)

    propName = propNames{k};
    propValue = deviceWriter.(propName);

    fprintf("%-30s : ", propName);
    disp(propValue);

end

%% ================= PLAY SOUND =================

fprintf("\nPlaying %.3f Hz sine wave...\n", toneFreq);
fprintf("Duration    : %.3f seconds\n", duration);
fprintf("Sample rate : %.0f Hz\n", playFs);
fprintf("Amplitude   : %.3f\n", amplitude);
fprintf("Output      : %s\n\n", outputMode);

%audiowrite(filename,tone, t);


%%
numFrames = ceil(numSamples/frameSize);

totalUnderrun = 0;

for k = 1:numFrames

    % Determine samples for current frame
    firstSample = (k-1)*frameSize + 1;
    lastSample  = min(k*frameSize,numSamples);

    frame = audioSignal(firstSample:lastSample,:);

    % Pad the final frame with zeros if required
    if size(frame,1) < frameSize

        numMissing = frameSize - size(frame,1);

        frame = [
            frame;
            zeros(numMissing,size(frame,2))
        ];

    end

    % Send frame to Focusrite
    underrun = deviceWriter(frame);

    totalUnderrun = totalUnderrun + underrun;

end

%% ================= CLEAN UP =================

release(deviceWriter);

fprintf("Playback complete.\n");
fprintf("Total underrun samples: %d\n", totalUnderrun);