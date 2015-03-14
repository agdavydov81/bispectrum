function varargout = ICA_dlg(varargin)
% ICA_DLG M-file for ICA_dlg.fig
%      ICA_DLG, by itself, creates a new ICA_DLG or raises the existing
%      singleton*.
%
%      H = ICA_DLG returns the handle to a new ICA_DLG or the handle to
%      the existing singleton*.
%
%      ICA_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ICA_DLG.M with the given input arguments.
%
%      ICA_DLG('Property','Value',...) creates a new ICA_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ICA_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ICA_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ICA_dlg

% Last Modified by GUIDE v2.5 20-Jul-2010 13:55:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ICA_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @ICA_dlg_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ICA_dlg is made visible.
function ICA_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ICA_dlg (see VARARGIN)

% Choose default command line output for ICA_dlg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ICA_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);
    cfg.tdpath1='Гармоника 1.wav';    cfg.tdval1=1;
    cfg.tdpath2='Гармоника 2.wav';    cfg.tdval2=2;
    cfg.tdpath3='Гармоника 1.wav';    cfg.tdval3=1;
    cfg.tdpath4='Гармоника 3.wav';    cfg.tdval4=3;
    cfg.tdpath5='Гармоника 2.wav';    cfg.tdval5=2;
    cfg.tdpath6='Гармоника 4.wav';    cfg.tdval6=4;

    cfg.phmtr=  1;
    cfg.ph=     1;
    cfg.env=    '0.5   0.5';
    
	try
		cfg=load('ICA_dlg_cfg.mat','cfg');
		cfg=cfg.cfg;
	catch
	end

    if cfg.phmtr,   set(handles.phmtr_radio1,'Value',1);    else    set(handles.phmtr_radio2,'Value',1);    end;
    if cfg.ph,      set(handles.ph_radio1,'Value',1);       else    set(handles.ph_radio2,'Value',1);       end;
    set(handles.env_edit1,'String',cfg.env);

    table_data={cfg.tdpath1     cfg.tdval1; ...
                cfg.tdpath2     cfg.tdval2; ...
                cfg.tdpath3     cfg.tdval3; ...
                cfg.tdpath4     cfg.tdval4; ...
                cfg.tdpath5     cfg.tdval5; ...
                cfg.tdpath6     cfg.tdval6};
    set(handles.src_table1,'Data',table_data);


% --- Outputs from this function are returned to the command line.
function varargout = ICA_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function env_edit1_Callback(hObject, eventdata, handles)
% hObject    handle to env_edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of env_edit1 as text
%        str2double(get(hObject,'String')) returns contents of env_edit1 as a double


% --- Executes during object creation, after setting all properties.
function env_edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to env_edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calc_pushbutton1.
function calc_pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to calc_pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    try
        td=         get(handles.src_table1,'Data');

        cfg.tdpath1=td{1,1};    cfg.tdval1=td{1,2};
        cfg.tdpath2=td{2,1};    cfg.tdval2=td{2,2};
        cfg.tdpath3=td{3,1};    cfg.tdval3=td{3,2};
        cfg.tdpath4=td{4,1};    cfg.tdval4=td{4,2};
        cfg.tdpath5=td{5,1};    cfg.tdval5=td{5,2};
        cfg.tdpath6=td{6,1};    cfg.tdval6=td{6,2};

        cfg.phmtr=  get(handles.phmtr_radio1,'Value');
        cfg.ph=     get(handles.ph_radio1,'Value');
        cfg.env=    get(handles.env_edit1,'String');
        save('ICA_dlg_cfg.mat','cfg');

        cfg.phmtr=  1-cfg.phmtr;
        cfg.ph=     1-cfg.ph;
        cfg.env=    str2num(cfg.env);

        fig=0;

        if cfg.phmtr==0 && cfg.ph==1
            throw(MException('ICA:unsupportedrequest', 'Вычисление фазового инварианта аналоговым фазометром не поддерживается.'));
        end

        i_mul=2;
        if cfg.ph==1
            i_mul=3;
        end
        fig=figure('Units','pixels','Position',get(0,'ScreenSize'));
        plot_colors={'k','b--','r-.','m:'};
        for i=0:size(td,1)/i_mul-1
            fs=[];
            [x{1},fs(1)]=wavread(td{i*i_mul+1,1});
            x{1}(:,2:end)=[];
            [x{2},fs(2)]=wavread(td{i*i_mul+2,1});
            x{2}(:,2:end)=[];
            K=[td{i*i_mul+1,2} td{i*i_mul+2,2}];
            if cfg.ph==1
                [x{3},fs(3)]=wavread(td{i*i_mul+3,1});
                x{3}(:,2:end)=[];
                K(3)=td{i*i_mul+3,2};
            end
            fs_out=max(fs);

            min_len=inf;
            for ind=1:size(x,2)
                if fs(ind)~=fs_out
                    x{ind}=resample(x{ind}, fs_out, fs(i));
                end
                min_len=min(min_len,size(x{ind},1));
            end

            x_out=[x{1}(1:min_len) x{2}(1:min_len)];
            phlbl=sprintf('{\\fontsize{10}\\Delta\\Psi_{%d}^{%d}(t)}',K(1),K(2));
            if cfg.ph==1
                x_out(:,3)=x{3}(1:min_len);
                phlbl=sprintf('{\\fontsize{10}\\Delta\\Psi_{%d}^{%d;%d}(t)}',K(2),K(1),K(3));
            end
            [dphi, dphi_t]=ICA(x_out, fs_out, K, cfg.ph, cfg.phmtr, cfg.env);
			if get(handles.view_phs_chk,'Value')
				dphi_out=interp1q([-1; dphi_t; size(x_out,1)/fs_out(1)], [dphi(1); dphi; dphi(end)], (0:size(x_out,1)-1)'/fs_out(1) );
				view_phs(x_out(:,1), x_out(:,2), fs_out(1), get_tone(x_out(:,1),fs(1))/K(1), K(1), K(2), dphi_out);
			end
			dphi=dphi*180/pi;
            dphi_collection{i+1, 1}=[dphi, dphi_t];
            dphi_collection{i+1, 2}=phlbl;
            color_ind=rem(i,length(plot_colors))+1;
            figure(fig);
            plot(dphi_t, dphi, plot_colors{color_ind});
            msg=[phlbl sprintf(', среднее=%.2f\\circ, диапазон=%.2f\\circ, медиана=%.2f\\circ',mean(dphi),max(dphi)-min(dphi),median(dphi))];
            [min_val min_ind]=min(dphi);
            if min_ind<length(dphi_t)/2
                hz_align='left';
            else
                hz_align='right';
            end
            text(dphi_t(min_ind),min_val,msg,'HorizontalAlignment',hz_align,'VerticalAlignment','top','Color',plot_colors{color_ind}(1));
            hold on;
        end
    catch ME
        if ~strcmp(ME.identifier,'wavread:InvalidFile')
            errordlg([ME.identifier ': ' ME.message],'Ошибка','modal');
        end
    end
    if fig
        figure(fig);
        grid on;
        xlabel('Время, с');
        if cfg.ph==0
            ylab='Фазовый квазиинвариант,';
        else
            ylab='Фазовый инвариант,';
        end
        ylabel([ylab ' \circ']);
        zoom xon;
        if cfg.phmtr==0
            phsmlab=' аналоговый фазометр';
        else
            phsmlab=' цифровой фазометр';
        end
        title_str=[ylab phsmlab ', относительный порог селекции начала и окончания сигнала по огибающей ' num2str(cfg.env(1)) ' ' num2str(cfg.env(2))];
        title(title_str);
    end
    
    if size(dphi_collection,1)>1
        dnum=size(dphi_collection,1);
        drg=[-inf inf];
        for i=1:dnum
            dt=dphi_collection{i,1}(:,2);
            drg=[max(drg(1),dt(1)), min(drg(2),dt(end))];
        end
        dlen=0;
        for i=1:dnum
            dt=dphi_collection{i,1}(:,2);
            dlen=max(dlen, length(find(dt>=drg(1) & dt<=drg(2))));
        end
        dtime=drg(1)+(0:(dlen-1))'*(drg(2)-drg(1))/(dlen-1);
        for i=1:dnum
            dt=dphi_collection{i,1}(:,2);
            dv=dphi_collection{i,1}(:,1);
            dphi_collection{i,1}=spline(dt, dv, dtime);
        end

        figure('Units','pixels','Position',get(0,'ScreenSize'));
        switch dnum
            case 2
                plot3(dtime, dphi_collection{1,1}, dphi_collection{2,1});
                view([-90 0]);
                xlabel('Время, с');
                ylabel(dphi_collection{1,2});
                zlabel(dphi_collection{2,2});
            case 3
                plot3(dphi_collection{1,1}, dphi_collection{2,1}, dphi_collection{3,1});
                xlabel(dphi_collection{1,2});
                ylabel(dphi_collection{2,2});
                zlabel(dphi_collection{3,2});
        end
        grid on;
        title(title_str);
	end

function [f0_freq, f0_time, f0_tone]=get_tone(x,fs)
	[f0_freq, f0_time, f0_tone]=sfs_rapt(x,fs);
%	[f0_freq, f0_time, f0_tone]=swipep(x,fs,[80 800]);	f0_tone=f0_tone>0.1;
%	[f0_freq, f0_time, f0_tone]=f0_track('signal',x, 'fs',fs);
%	[f0_freq, f0_time, f0_tone]=f0_grundton(x, fs);

	f0_time_up=(0:length(x)-1)'/fs;
	f0_freq=interp1q([0; f0_time; length(x)/fs], [f0_freq(1); f0_freq; f0_freq(end)], f0_time_up);

	dtone=diff([0; f0_tone; 0]);
	vocal_regs=[find(dtone==1) find(dtone==-1)-1]';
	vocal_regs=round(f0_time(vocal_regs)*fs);
	f0_tone=zeros(size(f0_freq));
	for i=1:size(vocal_regs,2)
		f0_tone(vocal_regs(1,i):vocal_regs(2,i))=1;
	end

	f0_time=f0_time_up;

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    td=         get(handles.src_table1,'Data');

    cfg.tdpath1=td{1,1};    cfg.tdval1=td{1,2};
    cfg.tdpath2=td{2,1};    cfg.tdval2=td{2,2};
    cfg.tdpath3=td{3,1};    cfg.tdval3=td{3,2};
    cfg.tdpath4=td{4,1};    cfg.tdval4=td{4,2};
    cfg.tdpath5=td{5,1};    cfg.tdval5=td{5,2};
    cfg.tdpath6=td{6,1};    cfg.tdval6=td{6,2};

    cfg.phmtr=  get(handles.phmtr_radio1,'Value');
    cfg.ph=     get(handles.ph_radio1,'Value');
    cfg.env=    get(handles.env_edit1,'String');
	save('ICA_dlg_cfg.mat','cfg');

    % Hint: delete(hObject) closes the figure
    delete(hObject);


% --- Executes on button press in view_phs_chk.
function view_phs_chk_Callback(hObject, eventdata, handles)
% hObject    handle to view_phs_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of view_phs_chk


function view_phs(x1, x2, fs, f0, k1, k2, phs)
%{
	if nargin==0
		[x1,fs]=wavread('h_100_01.wav');
		x2=wavread('h_100_02.wav');
		k1=1;
		k2=2;
		t=(0:size(x1,1)-1)'/fs;
		f0=100+zeros(size(t));
		phs=pi/8+zeros(size(t));
	end
%}
	t=(0:size(x1,1)-1)'/fs;
	gcd_k=gcd(k1,k2);
	k1=k1/gcd_k;
	k2=k2/gcd_k;

	x1z=find( (x1(2:end)>0 & x1(1:end-1)<=0) | (x1(2:end)<=0 & x1(1:end-1)>0) );
	x1=x1+1;
	x2=x2-1;

	old_fig=gcf();
	figure('Units','pixels', 'Position',get(0,'ScreenSize'));

	plot(t,x1,'b', t,x2,'r');
	grid on;
	zoom xon;
	set(pan, 'Motion', 'horizontal');

	i_st=lcm(k1,k2)/k2;
	if i_st~=1
		x_up=find(x1(2:end)>1 & x1(1:end-1)<=1, 1);
		x1z(x1z<x_up)=[];
	end
	for i=1:i_st:length(x1z)
		xci1=x1z(i);
		[mv,xci2]=min(abs(t(xci1)+phs(xci1)/(2*pi*f0(xci1)) - t));
		line([t(xci1) t(xci2)], [x1(xci1) x2(xci2)], 'Color','m');
	end
