close all;
clear all;
clc;

dec_rate = 10;
decfir_in = read_complex_data('waveform.txt', 12);
decfir_out = read_complex_data('waveform_out.txt', 12);
amp_scale = mean(abs(decfir_in))/mean(abs(decfir_out))
decfir_out = decfir_out .*amp_scale;

if 1
figure;
subplot(2,1,1);
plot(real(decfir_in), 'o'); hold on
plot(1:10:length(decfir_in),real(decfir_out), '--.');
title("real(signal) decimation compare"); legend('matlab', 'vivado');
subplot(2,1,2);
plot(imag(decfir_in), 'o'); hold on
plot(1:10:length(decfir_in), imag(decfir_out), '--.');
title("imag(signal) decimation compare"); legend('matlab', 'vivado');
end

%% Helper functions
function data = read_complex_data(file_name, data_with)
    % read hex format file line by line
    % the format of each line in the file is like this:
    % AAAABBBB
    % where AAAA is the 16-bit data in hex format, BBBB is the 16-bit data in hex format
    % save AAAA as data_i, and BBBB as data_q
    raw_data = textread(file_name, '%s', 'delimiter', '\n');
    data_i = zeros(length(raw_data), 1);
    data_q = zeros(length(raw_data), 1);
    for i = 1:length(raw_data)
        data_i(i) = hex2dec(raw_data{i}(1:4));
        data_q(i) = hex2dec(raw_data{i}(5:8));
    end

    % convert data_i and data_q to signed 16-bit data
    for i = 1:length(data_i)
        if data_i(i) > 2^(data_with-1)
            data_i(i) = data_i(i) - 2^data_with;
        end
        if data_q(i) > 2^(data_with-1)
            data_q(i) = data_q(i) - 2^data_with;
        end
    end

    data_i = data_i ./ 2^(data_with-1);
    data_q = data_q ./ 2^(data_with-1);

    % combine data_i and data_q into complex data
    data = data_i + 1j * data_q;
end