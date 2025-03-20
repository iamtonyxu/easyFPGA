close all;
clear all;
clc;

decfir_matlab = read_complex_data('decfir_out_matlab.txt');
decfir_vivado = read_complex_data('decfir_out_vivado.txt');

decfir_vivado = decfir_vivado *(max(abs(decfir_matlab))/max(abs(decfir_vivado)));

figure;
subplot(2,1,1);
plot(real(decfir_matlab), 'o'); hold on
plot(real(decfir_vivado), '--.');
plot(diff(real(decfir_vivado-decfir_matlab)));
title("real(signal) decimation compare"); legend('matlab', 'vivado');
subplot(2,1,2);
plot(imag(decfir_matlab), 'o'); hold on
plot(imag(decfir_vivado), '--.');
plot(diff(imag(decfir_vivado-decfir_matlab)));
title("imag(signal) decimation compare"); legend('matlab', 'vivado');

%% Helper functions
function data = read_complex_data(file_name)
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
        if data_i(i) > 2^15
            data_i(i) = data_i(i) - 2^16;
        end
        if data_q(i) > 2^15
            data_q(i) = data_q(i) - 2^16;
        end
    end

    data_i = data_i ./ 2^15;
    data_q = data_q ./ 2^15;

    % combine data_i and data_q into complex data
    data = data_i + 1j * data_q;
end