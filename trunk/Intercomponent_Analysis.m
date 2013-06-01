function [out_dphi, out_dphi_t]=Intercomponent_Analysis(file_name, F_base, ret_type, K, phasometr_type, amp_thres_beg, amp_thres_end, freq_factor, is_display, F0_bnd)
% ������� ���������������� �������� ������� �������
% [dphi, dphi_t] = Intercomponent_Analysis(file_name, F_base, ret_type, K, phasometr_type, amp_thres, freq_factor, is_display)
%
%   ������� ��������:
%       file_name - ��� �������� �����;
%       F_base - ������� ��������� ����;
%       ret_type - ��� ������������ ��������:   0-������� ���������;
%                                               1-������� ��������������;
%       K - ������������ �������� ��� ���������������� �������� ������, ��������
%           ������ 1-�� � 2-��, 1-�� � 3-��, 2-�� � 4-�� �������� ��������
%           � ���� [1 2; 1 3; 2 4];
%       phasometr_type - ��� ���������: 0 - ���������� ��������;
%                                       1 - �������� ��������;
%       amp_thres - ������������� ����� �������� �������� �� �� ���������;
%       freq_factor - ����������� ��� ��������� �����������������
%           (����� �����); 0 - ������������ ������������� ��������;
%       is_display - ���� ����������� ������������� ��������.
%
%   ������������ ��������:
%       dphi - �������� �������� ���������� ��� ���������������
%           (� ����������� �� ������� ����������);
%       dphi_t - �������� �������� ���������� ��� ���������������.

% ������: �������� �.�., ������� �.�., ������� �.�. (c) 2008
% ������: 1.2  ����: ���� 2008

%    error(nargchk(0,9,nargin));
    if nargin<1
        file_name=input('������� ������������ ��������� ����� ','s');
             % ������ 's' �������� ���� ����� ����� ��� ����������
    end
    if nargin<2
        F_base=-1;
    end
    if nargin<3
        ret_type=-1;
    end
    if nargin<4
        K=-1;
    end
    if nargin<5
        phasometr_type=-1;
    end
    if nargin<6
        amp_thres_beg=-1;
    end
    if nargin<7
        amp_thres_end=-1;
    end
    if nargin<8
        freq_factor=-1;
    end
    if nargin<9
        is_display=input('�������� ������������� ������� (1/0 - ��/���)? ');
    end

    out_dphi=[];
    out_dphi_t=[];

    [x,fs]=wavread(file_name);    % Input
    %x=x(end:-1:1); % �������� ��������� ���������� �����

    %% ����������� ������� ��������� ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if F_base==-1
        [F0_r, F0_c, F0_phi, F0_swipep]=base_tone([file_name ' ������ ���'],x,fs,is_display);
        disp('������ ������� ��������� ���� ������������, ����������� � ������������ �������� ���� �������������� ������� � �������� swipep');
        sw_F0=F0_swipep{1};
        F0_sw=mean(sw_F0(find(F0_swipep{3}>0.5)));
        disp([F0_r, F0_c, F0_phi, F0_sw]);
        F_base=input('������� ������� ��������� ���� (��) ');
    end

    %% ����� ������������� �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ret_type==-1
        ret_type=input('��������� ������� ��������� (0) ��� �������������� (1)? ');
    end

    %% ���� ������������� ��������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if K(1,1)==-1
        K=[];
        while 1
            K(end+1,1)=input('������� ����������� ��������� ��� ������� ������ ���������� p (0-������) ');
            if K(end,1)==0
                K(end,:)=[];
                break;
            end
            K(end,2)=input('������� ����������� ��������� ��� ������� ������ ���������� q (0-������) ');
            if K(end,2)==0
                K(end,:)=[];
                break;
            end
        end
    end

    %% ����� ���� ��������� � �������������� ������ �������� �������� %%%%%
    if phasometr_type==-1
        phasometr_type=input('������������ ����������(0) ��� ��������(1) ��������? ');
    end
    if amp_thres_beg==-1
        amp_thres_beg=input('������� ������������� ����� �������� ������ �������� �� �� ��������� ');
    end
    if amp_thres_end==-1
        amp_thres_end=input('������� ������������� ����� �������� ��������� �������� �� �� ��������� ');
    end

    %% ��� ����������� ��������� ��� ����� ������ ���������� ������ �������������
    %% ������������� ������� ������������
    if phasometr_type==0
        freq_factor_recomended=ceil(100*(F_base*max(max(K)))/fs);
        if freq_factor==0
            freq_factor=freq_factor_recomended;
        end
        if freq_factor==-1
            freq_factor=input(sprintf('������� ����������� ��� ��������� ����������������� (����� �����, ������������� %d) ',freq_factor_recomended));
        end
        x=resample(x,freq_factor,1);
        fs=fs*freq_factor;
    end

    %% �������� ����� �����, ������������ ��� ����������� �������� %%%%%%%%
    plot_colors=char('k','k--','k-.','k:');

    if nargout==0
        scrsz = get(0,'ScreenSize');
        figure('Name',file_name,'NumberTitle','off','Position',scrsz);
        fig_handle=gcf();
    end
    for k_i=1:size(K,1)
        [dphi,dphi_t]=intercomp_analysis(sprintf('%s; F0=%.2f; p=%d; q=%d',file_name, F_base, K(k_i,1), K(k_i,2)), x, fs, ret_type, F_base, [K(k_i,1) K(k_i,2)], amp_thres_beg, amp_thres_end, phasometr_type, is_display, F0_bnd);
        dphi=dphi*(180/pi);             % ������� � �������
        if nargout~=0
            out_dphi=   dphi;
            out_dphi_t= dphi_t;
            if size(out_dphi,1)<size(out_dphi,2)
                out_dphi=out_dphi';
            end
            if size(out_dphi_t,1)<size(out_dphi_t,2)
                out_dphi_t=out_dphi_t';
            end
            return;
        end
        figure(fig_handle);
        plot(dphi_t,dphi,plot_colors(1,:));
        plot_colors=[plot_colors(2:end,:); plot_colors(1,:)];
        msg=sprintf('p=%d, q=%d, �������=%.2f, ��������=%.2f',K(k_i,1),K(k_i,2),mean(dphi),max(dphi)-min(dphi));
        [min_val min_ind]=min(dphi);
        text(dphi_t(min_ind),min_val,msg,'HorizontalAlignment','center','VerticalAlignment','top');
        hold on;
    end
    msg=sprintf('���� %s; ��� %.2f��;', file_name, F_base);
    if ret_type==0
        msg=[msg ' ������� ���������;'];
    else
        msg=[msg ' ������� ��������������;'];
    end
    if phasometr_type==0
        msg=[msg sprintf(' ���������� �������� (����������� ����������������� %d);',freq_factor)];
    else
        msg=[msg ' �������� ��������;'];
    end
    title(msg,'Interpreter','none'); xlabel('�����, �'); ylabel('�������� ���, �������.');
    grid on;
end

function [tone_rceps, tone_cceps, tone_phiceps, tone_swipep]=base_tone(fig_title,y,FD,is_display)
    error(nargchk(3,4,nargin));
    if nargin<4
        is_display=0;
    end

    m=size(y,1);
    y=y-mean(y);
    y=y.*hamming(m);

    [sy,f]=psd(y,m,FD,'mean');
    if is_display==1
        scrsz = get(0,'ScreenSize');
        figure('Name',fig_title,'NumberTitle','off','Position',scrsz);
        t=(0:(length(y)-1))/FD;
        subplot(2,2,1);
            plot(t,y);
            grid on;    zoom on;    title('������, ���������� �� ���� ��������');
            xlabel('�����, �');     ylabel('�������, ��.');
        subplot(2,2,3);
            sy_dB=20*log10(sy);
            plot(f,sy_dB);
            grid on;    zoom on;    title('������������ ��������� ��������');
            xlabel('�������, ��');  ylabel('�������, ��');
            ylim([-120 max(sy_dB)]);
    end

    %��-���������� ����� ������������ ��������
    filter_info  =  fdesign.lowpass('N,F3dB', 20, 3400, FD);
    filter_handle = design(filter_info, 'butter');
    yK= filter2way(filter_handle, y);

    if is_display==1
        subplot(2,2,2);
            plot(t,yK);
            grid on;    zoom on;    title('������, ���������� �� ���� �������� � ���������������');
            xlabel('�����, �');     ylabel('�������, ��.');
        subplot(2,2,4);    
            [yK_fl,f]=psd(yK,m,FD,'mean');
            yK_fl=20*log10(yK_fl);
            plot(f,yK_fl);
            grid on;    zoom on;    title('������������ ��������� �������� ���������������� �������');
            xlabel('�������, ��');  ylabel('�������, ��');
            ylim([-120 max(yK_fl)]);
    end

    tone_rceps=ceps_tone(yK,FD,'rceps',[50 500]);   % ������ ������� ��������� ���� ������������ �������� (��)
    tone_cceps=ceps_tone(yK,FD,'cceps',[50 500]);   % ������ ������� ��������� ���� ����������� �������� (��)

    %��������� � ���� ��������� �������
    y_analytic=hilbert(y);
    y_angle=unwrap(angle(y_analytic));
    fir2_order=min(fix(length(y_angle)/6)*2,400);
    b=fir2(fir2_order,[0 0.01 0.02 1],[0 0 1 1],hamming(fir2_order+1));
    y_angle_phil=filtfilt(b,1,y_angle);
    
    if is_display==1
        figure('Name',fig_title,'NumberTitle','off','Position',scrsz);
        subplot(3,1,1);
            plot(t,y_angle);
            grid on;    zoom on;    title('���� �������������� �������');
            xlabel('�����, �');     ylabel('����, ���.');
        subplot(3,1,2);
            plot(t,y_angle_phil);
            grid on;    zoom on;    title('�� ��������������� ���� �������������� �������');
            xlabel('�����, �');     ylabel('����, ���.');
        subplot(3,1,3);
            y_afc=rceps(y_angle_phil);
            plot((0:(length(y_afc)-1))/FD,y_afc);
            grid on;    zoom on;    title('������������ ������ �� ��������������� ���� �������������� �������');
            xlabel('�������, �');   ylabel('�������, ��.');
    end
    tone_phiceps=ceps_tone(y_angle_phil,FD,'rceps',[60 300]);   % ������ ������� ��������� ���� ������������ �������� �� ��������������� ���� �������������� ������� (��)
    
    [swipep_f0, swipep_time, swipep_trust]=swipep(y,FD,[80 500]); % ������ ������� ��������� ���� ������� swipep
    tone_swipep={swipep_f0, swipep_time, swipep_trust};
    if is_display==1
        figure('Name',[fig_title ' (swipep)'], 'NumberTitle', 'off', 'Position', scrsz);

        x_lim=[0 (length(y)-1)/FD];

        subplot(311);
        plot((0:length(y)-1)/FD, y, 'k');
        grid on;    zoom xon;
        ylabel('�������� ������');
        title(fig_title,'Interpreter','none');
        xlim(x_lim);

        subplot(312);
        plot(swipep_time, swipep_f0, 'k');
        grid on;    zoom xon;
        ylabel('������ ��� (��)');
        xlim(x_lim);

        subplot(313);
        plot(swipep_time, swipep_trust, 'k');
        grid on;    zoom xon;
        ylabel('������� � ������');
        xlabel('����� (�)');
        axis([x_lim 0 1]);
    end
end

function [out_sgnl, out_hilb_ampl, out_hilb_angl]=GetComponentData(x, fs, F, F0_bnd)   % ���������� � ��������� ��������� � ���� �������������� ������� �� ������� F
    filter_info   = fdesign.bandpass('N,F3dB1,F3dB2', 20, F*(1-F0_bnd), F*(1+F0_bnd), fs);
    filter_handle = design(filter_info, 'butter');
    out_sgnl=filter2way(filter_handle, x);%������ y1 ����� ��������� ����������

    out_hilb=hilbert(out_sgnl);
    out_hilb_ampl=abs(out_hilb);
    out_hilb_angl=unwrap(angle(out_hilb));
end

function [dphi,dphi_t]=intercomp_analysis(fig_title, x, fs, ret_type, F_base, K, ampl_thres_beg, ampl_thres_end, phasometr_type, is_display, F0_bnd)
    if nargin<10
        is_display=0;
    end

    if ret_type==0
        K(3)=max(K)+abs(K(2)-K(1));
    end
    K=sort(K);

    [Y_sgnl(:,1), Y_hilb_ampl(:,1), Y_hilb_angl(:,1)]=      GetComponentData(x, fs, F_base*K(1), F0_bnd);
    [Y_sgnl(:,2), Y_hilb_ampl(:,2), Y_hilb_angl(:,2)]=      GetComponentData(x, fs, F_base*K(2), F0_bnd);
    if ret_type==0
        [Y_sgnl(:,3), Y_hilb_ampl(:,3), Y_hilb_angl(:,3)]=  GetComponentData(x, fs, F_base*K(3), F0_bnd);
    end
    dphi_t=(0:(length(x)-1))/fs;

    %**********************************************
    range=thres_proc(Y_hilb_ampl,ampl_thres_beg,ampl_thres_end); % ���������� ��������� ����������� ���������� ������
    if isempty(range)
        dphi=[];
        dphi_t=[];
        return;
    end
    Y_sgnl=     Y_sgnl(range(1):range(2),:);
    Y_hilb_ampl=Y_hilb_ampl(range(1):range(2),:);
    Y_hilb_angl=Y_hilb_angl(range(1):range(2),:);
    dphi_t=     dphi_t(range(1):range(2));

    if phasometr_type==0    % ���������� �������� %%%%%%%%%%%%%%%%%%%%%%%%%
        pt1=zero_points(Y_sgnl(:,1),1);
        if length(pt1)<3
            dphi=[];
            dphi_t=[];
            return;
        end
        T1=zeros(1,length(pt1)-2);
        for i=3:length(pt1)
            T1(i-2)=dphi_t(pt1(i))-dphi_t(pt1(i-2));
        end

        pt2=zero_points(Y_sgnl(:,2),pt1(1));
        if isempty(pt2)
            dphi=[];
            dphi_t=[];
            return;
        end
        pt2=pt2(1:K(2)/K(1):end);

        min_len=min([length(pt1), length(pt2), length(T1)]);
        dphi=(dphi_t(pt2(1:min_len))-dphi_t(pt1(1:min_len)))*2*pi./T1(1:min_len);
        dphi_t=dphi_t(pt1(1:min_len));
    else   % �������� �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if is_display==1
            scrsz = get(0,'ScreenSize');
            figure('Name',fig_title,'NumberTitle','off','Position',scrsz);
            msg=sprintf(' �������������� ������� ');
            for K_ind=1:length(K)
                msg=[msg sprintf('F%d(%0.2f��) ',K_ind, F_base*K(K_ind))];
            end
            if ret_type==0
                legends_str=char('F1','F2','F3');
            else
                legends_str=char('F1','F2');
            end
            % ������� � ������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            subplot(2,1,1);
                plot(dphi_t,Y_hilb_ampl);
                grid on;    zoom on;    title(['��������� ' msg]);
                legend(legends_str);    xlabel('�����, �');   ylabel('�������, ��.');
            subplot(2,1,2);
                plot(dphi_t,Y_hilb_angl);
                grid on;    zoom on;    title(['���� ' msg]);
                legend(legends_str);    xlabel('�����, �');   ylabel('����, ���.');
        end

        % ���������� �������� ��� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ret_type==0 % ������� ��������� (������)
            dphi=(Y_hilb_angl(:,1)+Y_hilb_angl(:,3))/2-Y_hilb_angl(:,2);
        else % ������� ��������������
            % ���������� ���� � ��������� ������������ ������� %%%%%%%%%%%%
            Y_hilb_angl(:,1)=(Y_hilb_angl(:,1)+pi/2);
            Y_hilb_angl(:,2)=(Y_hilb_angl(:,2)+pi/2)/(K(2)/K(1));

            if is_display==1
                figure('Name',fig_title,'NumberTitle','off','Position',scrsz);
                subplot(2,1,1);
                    plot(dphi_t,Y_hilb_angl);
                    grid on;    zoom on;    title(['���� ����������� � ��������� ������������ �������' msg]);
                    legend(legends_str);    xlabel('�����, �');   ylabel('����, ���.');
            end

            dphi=Y_hilb_angl(:,1)-Y_hilb_angl(:,2);
            dphi_mean=mean(dphi);

            dphi_porog=(2*pi)/(K(2)/K(1));
            dphi_adder=0;
            while dphi_mean+dphi_adder<0
                dphi_adder=dphi_adder+dphi_porog;
            end
            while dphi_mean+dphi_adder>=dphi_porog
                dphi_adder=dphi_adder-dphi_porog;
            end
            dphi=dphi+dphi_adder;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if is_display==1
            subplot(2,1,2);
                plot(dphi_t,dphi,'r');
                grid on;    zoom on;    title('�������� ���');
                xlabel('�����, �');   ylabel('����, �������.');
        end
    end
end

%==========================================================================
function pt=zero_points(x, start_pos)
    pt=[];
    i=max(start_pos,2);
    while i<length(x) && ~(x(i-1)<0 && x(i)>=0)
        i=i+1;
    end
    if i>=length(x)
        return;
    end
    while i<=length(x)
        if (x(i-1)<0 && x(i)>=0) || (x(i-1)>0 && x(i)<=0)
            pt(end+1)=i;
        end
        i=i+1;
    end
end

%==========================================================================
function F0_est=ceps_tone(x, fs, type, F0_range, x_mul)
% ������� ���������� ������ ������� ��������� ���� �������� �������.
%   T0=ceps_period(x, fs, type, F0_range, x_mul)
%   ������� ���������� ������ ������� ��������� ���� ������� x.
%   fs - ������� ������������� �������� �������.
%   type - ��� ������������� �������: 'rceps' ��� ���������� ���������������
%       ��������� ��� 'cceps' ��� ���������� ������������ �������.
%       �� ��������� ����������� 'cceps'.
%   F0_range - ���������������� ������ ��������� ������ �������� �������
%       ��������� ����. ����������� ������ [50 500] ���� �� ����� ����.
%   x_mul - ��������� ���������� ������� �������. ����������� ������ 1
%       ���� �� ����� ����.

    error(nargchk(1,5,nargin));

    if nargin<3
        type='cceps';
    end;
    if nargin<4
        F0_range=[50 500];
    end;
    if nargin<5
        x_mul=1;
    end;

    T0_range=round(fs./sort(F0_range));

    if strcmp(type,'rceps')
        c = real(ifft(log(abs(fft(x,length(x)*x_mul)))));
    end;
    if strcmp(type,'cceps')
        c=cceps(x,length(x)*x_mul);
    end;

    T0_range(1)=min(T0_range(1),floor(length(c)/2));
    T0_range(2)=min(T0_range(2),floor(length(c)/2));

    [c_val,c_ind]=max(c(T0_range(2):T0_range(1)));

    F0_est=fs/(c_ind+T0_range(2)-1);
end

%==========================================================================
function y=filter2way(fltr, x)
    dl=round(max(grpdelay(fltr))*1.5);
    
    y_forward=  filter(fltr, [x; zeros(dl,1)]);
    y_back=     filter(fltr, y_forward(length(y_forward):-1:1));
    y=y_back(end:-1:(dl+1));
end

% ���������� ��������� ���������� �������������� ������� ON_thres � ������
% ������� � OFF_thres � ����� ������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function range=thres_proc(sgnl, ON_thres, OFF_thres)
    error(nargchk(1,3,nargin));
    if nargin<2
        ON_thres=0.7;
    end;
    if nargin<3
        OFF_thres=0.7;
    end;

    range=[1, size(sgnl,1)];
    for col_ind=1:size(sgnl,2)
        max_lvl=max(sgnl(:,col_ind));
        lvl_cnt=1;
        while lvl_cnt<=range(2) && sgnl(lvl_cnt,col_ind)<max_lvl*ON_thres
            lvl_cnt=lvl_cnt+1;
        end
        range(1)=max(range(1),lvl_cnt);
        lvl_cnt=size(sgnl,1);
        while lvl_cnt>=range(1) && sgnl(lvl_cnt,col_ind)<max_lvl*OFF_thres
            lvl_cnt=lvl_cnt-1;
        end
        range(2)=min(range(2),lvl_cnt);
        
        if range(1)>range(2)
            range=[];
            return;
        end
    end
end

