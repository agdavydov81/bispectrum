clear;

% F0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
figure;
for t=0.9:0.005:1.1
    [dphi, dphi_t]=Intercomponent_Analysis('A000_L.wav',97.5664*t,1,[2 4],0,0.7,0.5,0,0);
    display(sprintf('%f mean %f',t,mean(dphi)));
    plot3(t*ones(size(dphi)),dphi_t,dphi);
    hold on;
end
grid on;
view(120,50);
%}

%wavs_name=char('A000_A.WAV','A000_H.WAV','A000_L.WAV','A000_V.WAV','A030_L.WAV');
%wavs_F0=      [ 99.3243,     113.0769,    97.5664,     193.4211,    98.0000];

%wavs_name=char('Lobanov\A000.wav','Lobanov\A001.wav','Lobanov\A002.wav','Lobanov\A010.wav','Lobanov\A011.wav','Lobanov\A013.wav','Lobanov\A020.wav','Lobanov\A021.wav','Lobanov\A022.wav','Lobanov\A030.wav','Lobanov\A031.wav','Lobanov\A040.wav','Lobanov\A041.wav');
wavs_name=char('Lobanov\U000.wav','Lobanov\U001.wav','Lobanov\U002.wav','Lobanov\U010.wav','Lobanov\U011.wav','Lobanov\U012.wav','Lobanov\U013.wav','Lobanov\U020.wav','Lobanov\U030.wav','Lobanov\U033.wav','Lobanov\U040.wav','Lobanov\U042.wav');
wavs_F0=90*ones(1,13);
wavs_mark=char('ko-','kx-','k+-','k*-','ks-','kd-','kv-','k^-','k<-','k>-','kp-','kh-');

K_factors=  [1 2; 1 3; 2 4];

figure;
for wavs_ind=1:size(wavs_name,1)
    for K_ind=1:size(K_factors,1)
        [dphi, dphi_t]=Intercomponent_Analysis(wavs_name(wavs_ind,:), wavs_F0(wavs_ind), 1, K_factors(K_ind,:), 1, 0.7, 0.5, 0, 0);
        wavs_psi(K_ind,wavs_ind)=mean(dphi);
        hold on;
    end
    plot3(wavs_psi(1,wavs_ind),wavs_psi(2,wavs_ind),wavs_psi(3,wavs_ind),wavs_mark(1,:));
    wavs_mark=[wavs_mark(2:end,:);wavs_mark(1,:)];
%    text(wavs_psi(1,wavs_ind),wavs_psi(2,wavs_ind),wavs_psi(3,wavs_ind),wavs_name(wavs_ind,:),'Interpreter','none','VerticalAlignment','top');
end
legend(wavs_name,'Location','BestOutside');
axis([0, 360*K_factors(1,1)/K_factors(1,2), 0, 360*K_factors(2,1)/K_factors(2,2), 0, 360*K_factors(3,1)/K_factors(3,2)]);
xlabel(sprintf('\\Delta\\psi_%d^%d',K_factors(1,1),K_factors(1,2)));
ylabel(sprintf('\\Delta\\psi_%d^%d',K_factors(2,1),K_factors(2,2)));
zlabel(sprintf('\\Delta\\psi_%d^%d',K_factors(3,1),K_factors(3,2)));
grid on;
view([30 26]);

