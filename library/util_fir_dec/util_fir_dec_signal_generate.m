close all;
clear all;
clc;

Fs = 122.88e6; % Sampling frequency
Fc = [2.56e6] ; % Cutoff frequency
Amp = [0.8]; % Amplitude
dec_factor = 8;

% Generate time vector
Length = dec_factor*120;
t = 0:1/Fs:(Length-1)/Fs;
t_interp = 0:1/(Fs*dec_factor):(Length*dec_factor-1)/(Fs*dec_factor);

% Generate complex signal with two tones
s = Amp(1)*exp(1j*2*pi*Fc(1)*t);

% Call the function to process the complex signal and save it to a file
convert_and_save_complex_signal(s, 'waveform.txt');

ss = reshape(s, dec_factor, length(s)/dec_factor);

b = intfilt(dec_factor, 8, 0.618);
b = [b 0];
% save the coefficients to a file
hq = dfilt.dffir(b);
set(hq,'arithmetic','fixed'); coewrite(hq,10,'mycoefile_dec');

hh = reshape(b, dec_factor, length(b)/dec_factor);

yy = zeros(1, Length/dec_factor);
for i = dec_factor:-1:1
    tmp = conv(hh(i,:), ss(i,:));
    yy =  yy + tmp(1, 8:end-8);
end
yy = yy ./dec_factor;

convert_and_save_complex_signal(yy, 'decfir_out_matlab.txt');

% display signal in time-domain
figure;
subplot(2,1,1);
plot(1:length(s), real(s), '--.'); hold on
plot(1:dec_factor:length(s), real(yy), '--o');
title('data-i before and after decimation');
legend('before', 'after');
subplot(2,1,2);
plot(1:length(s), imag(s), '--.'); hold on
plot(1:dec_factor:length(s), imag(yy), '--o');
title('data-q before and after decimation');
legend('before', 'after');

%% interp method
plot_signal_freq_domain(Fs, dec_factor, 0, s, yy);

%% Helper functions
% plot singal in freq-domain before and after decimation
function plot_signal_freq_domain(Fs, dec_factor, win, s, s_dec)
    % plot singal in freq-domain before and after decimation
    NFFT = length(s);
    f = Fs * (0:NFFT/2-1)/NFFT;
    
    if win == 1
        Y1 = fft(s.*hanning(length(s))',NFFT); Y1 = abs(Y1(1:NFFT/2));
        Y2 = fft(s_dec.*hanning(length(s_dec))',NFFT); Y2 = abs(Y2(1:NFFT/2));
    else
        Y1 = fft(s,NFFT); Y1 = abs(Y1(1:NFFT/2));
        Y2 = fft(s_dec,NFFT); Y2 = abs(Y2(1:NFFT/2));
    end

    figure;
    subplot(2,1,1);
    plot(f, (Y1)); title('singal before decimation');
    % find peak frequency and mark it
    [pks, locs] = findpeaks(Y1);
    [max_val, max_idx] = max(pks);
    hold on; plot(f(locs(max_idx)), Y1(locs(max_idx)), 'ro');
    % show frequency of the peak in the plot
    text(f(locs(max_idx)), Y1(locs(max_idx)), [num2str(f(locs(max_idx))/1e6), 'MHz']);
    subplot(2,1,2);
    plot(f/dec_factor, (Y2)); title('signal after decimation');
    % find peak frequency and mark it
    [pks, locs] = findpeaks(Y2);
    [max_val, max_idx] = max(pks);
    hold on; plot(f(locs(max_idx))/dec_factor, Y2(locs(max_idx)), 'ro');
    % show frequency of the peak in the plot
    text(f(locs(max_idx))/dec_factor, Y2(locs(max_idx)), [num2str(f(locs(max_idx))/dec_factor/1e6), 'MHz']);
end

% Function convert_and_save_complex_signal
function convert_and_save_complex_signal(s, filename)
    % convert this complex signal into fixed point with 16 bits, 1 integer bit
    % and 15 fraction bits, round it to the nearest integer, saturate it to
    % [-2^15, 2^15-1] range, scale it by 1
    s1 = fi(s, 1, 16, 15, 'RoundingMethod', 'Round', 'OverflowAction', 'Saturate');
    s2 = s1 * 2^15;
    % convert s2 into hex format considering complement format and save it into a file
    % one sample per line and the format is AAAA, BBBB, where A is the real part and B is the imaginary part
    fid = fopen(filename, 'w');
    for i = 1:length(s2)
        tmp_r = real(s2(i));
        if tmp_r < 0
            tmp_r = 2^16 + tmp_r; 
        end

        tmp_i = imag(s2(i));
        if tmp_i < 0
            tmp_i = 2^16 + tmp_i; 
        end
        fprintf(fid, '%04X%04X\n', tmp_r, tmp_i);
    end
    fclose(fid);
end