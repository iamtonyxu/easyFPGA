close all;
clear all;
clc;

Fs = 122.88e6; % Sampling frequency
Fc = [30.72e6] ; % Cutoff frequency
Amp = [0.5]; % Amplitude

% Generate time vector
Length = 4096;
t = 0:1/Fs:(Length-1)/Fs;

% Generate complex signal with two tones
s = Amp(1)*exp(1j*2*pi*Fc(1)*t);

% interpolate signal by 8x
interp_factor = 8;
[s_interp, b] = interp(s, interp_factor, 8, 0.618);
% b = intfilt(interp_factor,8,0.618)';

hq = dfilt.dffir(b); 
set(hq,'arithmetic','fixed'); coewrite(hq,10,'mycoefile_int');
coe_read = coeread('coefile_int.coe');
% export coefficients to matlab
h = coe_read.coeffs;
h = h.Numerator;
% display frequency response of the coefficients
%fvtool(h);
%fvtool(b);

%% interp method
plot_signal_freq_domain(Fs, interp_factor, s, s_interp);

%% ADI Coefile
hh = reshape(h(1:end-1), interp_factor,16);
s1 = zeros(interp_factor, length(s));
for i=interp_factor:-1:1
    tmp = conv(hh(i,:), s);
    s1(i,:) = tmp(1, 8:end-8);
end
s2 = reshape(s1, length(s_interp), 1);
plot_signal_freq_domain(Fs, interp_factor, s, s2);

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
    plot(f, 20*log10(Y1)); title('singal before interp');
    subplot(2,1,2);
    plot(f*interp_factor, 20*log10(Y2)); title('signal after interp');
end
