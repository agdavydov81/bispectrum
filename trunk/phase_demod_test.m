% ������� ������������� � ������������ (� ��������) ������������ ������
fs = 16000;
len = fs;
% ����, ��� ����������� ��������� � ������ � ����� �����
w = window(@hann, len); % rectwin ��� hann

% ��������� ������������� ������������������ �������
F0 = 100:100:5000;
% A = 1./(1:numel(F0));
A  = ones(size(F0));
Phi= (1:numel(F0))*2*pi/numel(F0);
y = sum(polyharm(fs, len, F0, A, Phi),2);
wavwrite(y.*w*0.95/max(abs(y)), fs, 'phase_test_stat.wav');

% ��������� ������������������ �������, � ������� ��������������� ��������
% �������� �� 100 �� 120 ��
F0 = linspace(100,120,len)'*(1:size(A,2));
y = sum(polyharm(fs, len, F0, A, Phi),2);
wavwrite(y.*w*0.95/max(abs(y)), fs, 'phase_test_flow.wav');
