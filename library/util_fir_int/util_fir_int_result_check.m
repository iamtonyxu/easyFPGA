close all;
clear all;
clc;

ifir_matlab = read_complex_data('ifir_out_matlab.txt');
ifir_vivado = read_complex_data('ifir_out_vivado.txt');

figure;
subplot(2,1,1);
plot(real(ifir_matlab), 'o'); hold on
plot(real(ifir_vivado), '--.');
plot(diff(real(ifir_vivado-ifir_matlab)));
title("data-i before vs after interp x8"); legend('matlab', 'vivado');
subplot(2,1,2);
plot(imag(ifir_matlab), 'o'); hold on
plot(imag(ifir_vivado), '--.');
plot(diff(imag(ifir_vivado-ifir_matlab)));
title("data-q before vs after interp x8"); legend('matlab', 'vivado');

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