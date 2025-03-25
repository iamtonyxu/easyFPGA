close all;
clear all;
clc;

Fs = 122.88e6; % Sampling frequency
Fc = [122.88e3] ; % Cutoff frequency
Amp = [0.8]; % Amplitude

% Generate time vector
Length = 1000;
t = 0:1/Fs:(Length-1)/Fs;

% Generate complex signal
s = Amp(1)*exp(1j*2*pi*Fc(1)*t);

figure;
plot(real(s)); hold on
plot(imag(s)); title("waveform");

% Call the function to process the complex signal and save it to a file
convert_and_save_complex_signal(s, 'waveform.txt');

%% Helper functions
% Function convert_and_save_complex_signal
function convert_and_save_complex_signal(s, filename)
    ADC_BITS = 12;
    % convert this complex signal into fixed point with 16 bits, 1 integer bit
    % and 15 fraction bits, round it to the nearest integer, saturate it to
    % [-2^15, 2^15-1] range, scale it by 1
    s1 = fi(s, 1, ADC_BITS, (ADC_BITS-1), 'RoundingMethod', 'Round', 'OverflowAction', 'Saturate');
    s2 = s1 * 2^(ADC_BITS-1);
    % convert s2 into hex format considering complement format and save it into a file
    % one sample per line and the format is AAAA, BBBB, where A is the real part and B is the imaginary part
    fid = fopen(filename, 'w');
    for i = 1:length(s2)
        tmp_r = real(s2(i));
        if tmp_r < 0
            tmp_r = 2^ADC_BITS + tmp_r; 
        end

        tmp_i = imag(s2(i));
        if tmp_i < 0
            tmp_i = 2^ADC_BITS + tmp_i; 
        end
        fprintf(fid, '%04X%04X\n', tmp_r, tmp_i);
    end
    fclose(fid);
end