close all;
clear all;
clc;

Fs = 122.88e6; % Sampling frequency
Fc = [1.024e6] ; % tone frequency
Amp = [0.8]; % Amplitude
interp_factor = 8;

% Generate time vector
Length = 120;
t = 0:1/Fs:(Length-1)/Fs;
t_interp = 0:1/(Fs*interp_factor):(Length*interp_factor-1)/(Fs*interp_factor);

% Generate complex signal with two tones
s = Amp(1)*exp(1j*2*pi*Fc(1)*t);

% Call the function to process the complex signal and save it to a file
convert_and_save_complex_signal(s, 'waveform.txt');

%% method-1. function interp
[s_interp, b] = interp(s, interp_factor, 8, 0.618);
% b = intfilt(interp_factor,8,0.618)'; % the same coeffs generated using function intfilt and interp
% fvtool(b);
% save the coefficients to a file
hq = dfilt.dffir(b);
set(hq,'arithmetic','fixed'); coewrite(hq,10,'mycoefile_int');

%display signal in time-domain
figure;
subplot(2,1,1);
plot(t, real(s), 'bo'); hold on
plot(t_interp, real(s_interp), '--r.');
title('data-i before vs after interp x8');
legend('before', 'after');
subplot(2,1,2);
plot(t, imag(s), 'bo'); hold on
plot(t_interp, imag(s_interp), '--r.');
title('data-q before vs after interp x8');
legend('before', 'after');

%% method-2. insert zeros then pass a lp filter
% note: with the same filter coeffs
s1 = s.';
s1 = [s1, zeros(length(s),7)].';
s1 = reshape(s1, length(s)*8, 1);
%figure; plot(imag(s), '--.');
%figure; plot(imag(s1), '--.');
s2 = conv(b, [s1;s1]);
s2 = s2(64+(1:length(s_interp)));

figure;
plot(imag(s2), '--.'); hold on
plot(imag(s_interp), '--o');
plot(imag(s2-s_interp.'));
title('method-2 vs method-1');

%% method-3. recalculate s_interp using FPGA method
s3 = custom_interpolation(b, interp_factor, [s,s]);
s3 = s3(1:interp_factor*length(s),1);
convert_and_save_complex_signal(s3, 'ifir_out_matlab.txt');

figure;
plot(imag(s3), '--.'); hold on
plot(imag(s_interp), '--o');
plot(imag(s3-s_interp.'));
title('method-3 vs method-1');

figure;
plot(imag(s3), '--.'); hold on
plot(imag(s2), '--o');
plot(imag(s3-s2));
title('method-3 vs method-2');

%% interp method
plot_signal_freq_domain(Fs, interp_factor, s, s_interp);

%% Helper functions
% plot singal in freq-domain before and after interpolation
function plot_signal_freq_domain(Fs, interp_factor, s, s_interp)
    % plot singal in freq-domain before and after interpolation
    NFFT = 1024;
    f = Fs * (0:NFFT/2-1)/NFFT;
    Y1 = fft(s.*hanning(length(s))',NFFT); Y1 = abs(Y1(1:NFFT/2));
    Y2 = fft(s_interp.*hanning(length(s_interp))',NFFT); Y2 = abs(Y2(1:NFFT/2));

    figure;
    subplot(2,1,1);
    plot(f, (Y1)); title('singal before interp');
    subplot(2,1,2);
    plot(f*interp_factor, (Y2)); title('signal after interp');
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

function s_interp = custom_interpolation(b, interp_factor, s)
    hh = reshape(b(1:end-1), interp_factor, 16);
    s1 = zeros(interp_factor, length(s));
    for i = interp_factor:-1:1
        tmp = conv(hh(i,:), s);
        s1(i,:) = tmp(1, 9:end-7);
    end
    
    %figure;
    %plot(imag(s1(:,1:length(s)/2).'), '--.');

    s_interp = reshape(s1, interp_factor * length(s), 1);
end