clear; close all; clc;
%% Parameters
fs = 192e3;                      % sampling frequency [Hz]
f_start = 3000;                   % sweep start frequency [Hz]
f_end = 8000;                   % sweep end frequency [Hz]
sweep_dur = 1;                   % sweep duration [s]
delay_dur = 3;                   % silence (off time) between sweeps [s]
total_dur = 5*60;                 % total signal duration [s] (5 minutes)
taper_ratio = 0.1;               % Tukey (cosine) taper ratio
sweep_type = 'logarithmic';           % 'linear' or 'logarithmic'

%% Generate one on/off cycle: sweep + delay
t_sweep = 0:1/fs:sweep_dur-1/fs;
sweep = chirp(t_sweep, f_start, sweep_dur, f_end, sweep_type);

% Taper the sweep edges to avoid clicks
w = tukeywin(length(sweep), taper_ratio)';
sweep = sweep .* w;

delay = zeros(1, round(delay_dur*fs));
cycle = [sweep, delay];
cycle_dur = sweep_dur + delay_dur;

%% Repeat the on/off cycle to fill total_dur
n_repeats = floor(total_dur / cycle_dur);
x = repmat(cycle, 1, n_repeats);
t = (0:length(x)-1)/fs;          % full time vector [s]

fprintf('Cycle: %g s on, %g s off (%g s total per cycle)\n', sweep_dur, delay_dur, cycle_dur);
fprintf('Number of repeats: %d\n', n_repeats);
fprintf('Total signal duration: %.2f s (%.2f min)\n', t(end), t(end)/60);

%% Plot time-domain signal
figure;
plot(t, x);
xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('Repeated Sweep: %d Hz to %d Hz, %d cycles', f_start, f_end, n_repeats));
grid on;

%% Spectrogram (time-based)
% x is 5 minutes long (~57.6M samples at 192 kHz), so window/overlap
% must stay modest or fft blows up memory (same issue as the pulse
% train earlier). A 100 ms window with no overlap keeps segment count
% low (~3000) while still tracking each 10 s sweep clearly.
window = round(0.8*fs);          % 100 ms analysis window
noverlap = 0;                    % no overlap -> segment count = N/window
nfft = 4096;
[s, f_axis, t_axis] = spectrogram(x, window, noverlap, nfft, fs);

% Most segments fall in the "off" delay periods (silence), so auto
% color scaling gets dominated by near-zero values. Compute dB
% relative to peak and clip the color range manually instead.
S_db = 20*log10(abs(s) + eps);
S_db = S_db - max(S_db(:));      % 0 dB at peak

figure;
imagesc(t_axis, f_axis/1e3, S_db);
axis xy;
clim([-40 0]);                   % show top 40 dB of dynamic range
colorbar;
xlabel('Time (s)');
ylabel('Frequency (kHz)');
ylim([0 f_end/1e3 + 1]);
title('Spectrogram of Repeated Sweep');

%% Export as WAV
audiowrite('OASIS_TX4.wav', x, fs);