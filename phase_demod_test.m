% Частота дискретизации и длительность (в отсчетах) генерируемых файлов
fs = 16000;
len = fs;
% Окно, для сглаживания пульсаций в начале и конце файла
w = window(@hann, len); % rectwin или hann

% Генерация стационарного полигармонического сигнала
F0 = 100:100:5000;
% A = 1./(1:numel(F0));
A  = ones(size(F0));
Phi= (1:numel(F0))*2*pi/numel(F0);
y = sum(polyharm(fs, len, F0, A, Phi),2);
wavwrite(y.*w*0.95/max(abs(y)), fs, 'phase_test_stat.wav');

% Генерация полигармонического сигнала, с линейно увеличивающейся частотой
% гармоник от 100 до 120 Гц
F0 = linspace(100,120,len)'*(1:size(A,2));
y = sum(polyharm(fs, len, F0, A, Phi),2);
wavwrite(y.*w*0.95/max(abs(y)), fs, 'phase_test_flow.wav');
