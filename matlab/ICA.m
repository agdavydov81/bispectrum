function [dphi, dphi_t]=ICA(x, fs, K, ret_type, phasometr_type, env_thres)
% Функция межкомпонентного фазового анализа сигнала
% [dphi, dphi_t] = ICA(x, fs, K, ret_type, phasometr_type, env_thres)
%
%   Входные парамеры:
%       x - сигнал, анализируемые компоненты которого расположены в стоблцах;
%       fs - частота дискретизации сигнала;
%       K - вектор коэффициентов гармоник для межкомпонентного фазового анализа;
%       ret_type - Тип возвращаемых значений: 0 - фазовый квазиинвариант;
%                                             1 - фазовый инвариант;
%       phasometr_type - тип фазометра: 0 - аналоговый фазометр;
%                                       1 - цифровой фазометр;
%       env_thres - относительный порог селекции сигналов по их огибающим;
%
%   Возвращаемые значения:
%       dphi - ордината фазового инварианта или квазиинварианта
%           (в зависимости указанного типа возвращаемых значений);
%       dphi_t - абсцисса фазового инварианта или квазиинварианта.

% Авторы: Воробъев В.И., Давыдов А.Г., Давыдов И.Г. (c) 2008
% Версия: 1.3  Дата: Июнь 2008


    % Для аналогового фазометра для более точных вычислений иногда
    % целесообразно увелеличивать частоту дискретизаци
    if phasometr_type==0
        freq_factor=ceil(10000*max(K)/fs);
        x=resample(x,freq_factor,1);
        fs=fs*freq_factor;
    end

    hilb_x=     hilbert(x);
    hilb_ampl=  abs(hilb_x);
    hilb_angl=  unwrap(angle(hilb_x));

    dphi_t=     (0:(length(x)-1))'/fs; 

    %**********************************************
    range=thres_proc(hilb_ampl, env_thres); % Вычисление диапазона совместного превышения уровня
    if isempty(range)
        dphi=[];
        dphi_t=[];
        return;
    end
    hilb_x=     hilb_x(range(1):range(2),:);
    hilb_ampl=  hilb_ampl(range(1):range(2),:);
    hilb_angl=  hilb_angl(range(1):range(2),:);
    dphi_t=     dphi_t(range(1):range(2));

    if phasometr_type==0    % Аналоговый фазометр %%%%%%%%%%%%%%%%%%%%%%%%%
        pt1=zero_points(hilb_x(:,1),1);
        if length(pt1)<3
            dphi=[];
            dphi_t=[];
            return;
        end
        T1=zeros(1,length(pt1)-2);
        for i=3:length(pt1)
            T1(i-2)=dphi_t(pt1(i))-dphi_t(pt1(i-2));
        end

        pt2=zero_points(hilb_x(:,2),pt1(1));
        if isempty(pt2)
            dphi=[];
            dphi_t=[];
            return;
        end
        pt2=pt2(1:K(2)/K(1):end);

        min_len=min([length(pt1), length(pt2), length(T1)]);
        dphi=(dphi_t(pt2(1:min_len))-dphi_t(pt1(1:min_len)))*2*pi./T1(1:min_len)';
        dphi_t=dphi_t(pt1(1:min_len));
    else   % Цифровой фазометр %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ret_type==0 % Фазовый квазиинвариант
            % Приведение фазы к диапазону однозначного отсчета %%%%%%%%%%%%
            hilb_angl(:,1)=(hilb_angl(:,1)+pi/2);
            hilb_angl(:,2)=(hilb_angl(:,2)+pi/2)/(K(2)/K(1));

            dphi=hilb_angl(:,1)-hilb_angl(:,2);
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
        else % Фазовый инвариант (Зверев)
            dphi=(hilb_angl(:,1)+hilb_angl(:,3))/2-hilb_angl(:,2);
        end
    end
end

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

% Вычисление диапазона превышения относительного урованя ON_thres в начале
% сигнала и OFF_thres в конце сигнала %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function range=thres_proc(x, env_thres)
    range=[1, size(x,1)];

    for col_ind=1:size(x,2)
        max_lvl=max(x(:,col_ind));
        lvl_cnt=1;
        while lvl_cnt<=range(2) && x(lvl_cnt,col_ind)<max_lvl*env_thres(1)
            lvl_cnt=lvl_cnt+1;
        end
        range(1)=max(range(1),lvl_cnt);
        lvl_cnt=size(x,1);
        while lvl_cnt>=range(1) && x(lvl_cnt,col_ind)<max_lvl*env_thres(2)
            lvl_cnt=lvl_cnt-1;
        end
        range(2)=min(range(2),lvl_cnt);

        if range(1)>range(2)
            range=[];
            return;
        end
    end
end
