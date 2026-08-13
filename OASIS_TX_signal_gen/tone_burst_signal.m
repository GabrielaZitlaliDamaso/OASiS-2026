clear; close all; clc;
%% Parameters
fs = 192e3;                      % sampling frequency [Hz]
freqs = [3000, 6000];            % tone frequencies to play, in order [Hz]
tone_dur = 30;                   % duration each tone plays [s]
off_dur = 30;                    % silence between tones [s]
lead_in_dur = 3;                 % silence before the first tone [s]
lead_out_dur = 3;                % silence after the last tone [s]
r = 0.5;                         % Tukey taper ratio (0 = rectangular, 1 = full cosine/Hann)
 
%% Build each tone (tapered) and the off-period silence
t_tone = 0:1/fs:tone_dur-1/fs;
w = tukeywin(length(t_tone), r)';
off = zeros(1, round(off_dur*fs));
lead_in = zeros(1, round(lead_in_dur*fs));
lead_out = zeros(1, round(lead_out_dur*fs));
 
x = lead_in;
for k = 1:length(freqs)
    tone = sin(2*pi*freqs(k)*t_tone) .* w;
    x = [x, tone]; %#ok<AGROW>
    if k < length(freqs)
        x = [x, off]; %#ok<AGROW>
    end
end
x = [x, lead_out];
t_full = (0:length(x)-1)/fs;     % full time vector [s]
 
fprintf('Sequence: %s Hz, %g s on / %g s off between tones\n', mat2str(freqs), tone_dur, off_dur);
fprintf('Total signal duration: %.2f s\n', t_full(end));
 
%% Plot time-domain signal
figure;
plot(t_full, x, 'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('3 kHz / off / 5 kHz Sequence');
grid on;
 
%% Spectrogram
% Signal is long (~1.5 min), so window/overlap must stay modest to
% avoid the fft memory blowup seen with the pulse train earlier.
window = round(0.1*fs);          % 100 ms analysis window
noverlap = 0;                    % no overlap -> segment count = N/window
nfft = 4096;
[s, f_axis, t_axis] = spectrogram(x, window, noverlap, nfft, fs);
 
% Most segments fall in silence, so scale color relative to peak
% instead of relying on auto scaling.
S_db = 20*log10(abs(s) + eps);
S_db = S_db - max(S_db(:));
 
figure;
imagesc(t_axis, f_axis/1e3, S_db);
axis xy;
clim([-40 0]);
colorbar;
xlabel('Time (s)');
ylabel('Frequency (kHz)');
ylim([0 max(freqs)/1e3 + 2]);
title('Spectrogram of Sequence');
 
%% Export as WAV
audiowrite('OASIS_TX1.wav', x, fs);
 


