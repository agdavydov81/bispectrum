function varargout = phase_demod_dlg(varargin)
% PHASE_DEMOD_DLG MATLAB code for phase_demod_dlg.fig
%      PHASE_DEMOD_DLG, by itself, creates a new PHASE_DEMOD_DLG or raises the existing
%      singleton*.
%
%      H = PHASE_DEMOD_DLG returns the handle to a new PHASE_DEMOD_DLG or the handle to
%      the existing singleton*.
%
%      PHASE_DEMOD_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHASE_DEMOD_DLG.M with the given input arguments.
%
%      PHASE_DEMOD_DLG('Property','Value',...) creates a new PHASE_DEMOD_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before phase_demod_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to phase_demod_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help phase_demod_dlg

% Last Modified by GUIDE v2.5 25-May-2015 19:32:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @phase_demod_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @phase_demod_dlg_OutputFcn, ...
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


% --- Executes just before phase_demod_dlg is made visible.
function phase_demod_dlg_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to phase_demod_dlg (see VARARGIN)

% Choose default command line output for phase_demod_dlg
handles.output = hObject;

try
	load([mfilename '_cfg.mat']);

	fl = fieldnames(handles);
	for fi = 1:numel(fl)
		if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol') && isfield(dlg_cfg,fl{fi})
			switch get(handles.(fl{fi}),'Style')
				case 'edit'
					set(handles.(fl{fi}),'String',dlg_cfg.(fl{fi}));
				case {'checkbox' 'popupmenu'}
					set(handles.(fl{fi}),'Value',dlg_cfg.(fl{fi}));
			end
		end
	end

	% Position to center of screen
	old_units = get(hObject,'Units');
	scr_sz = get(0,'ScreenSize');
	set(hObject,'Units',get(0,'Units'));
	cur_pos = get(hObject,'Position');
	set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
	set(hObject,'Units',old_units); 	
catch
end

% Update handles structure
guidata(hObject, handles);

is_framing_Callback(handles.is_framing, [], handles);

% UIWAIT makes phase_demod_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = phase_demod_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in inputfile_sel_btn.
function inputfile_sel_btn_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to inputfile_sel_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist('audioread','file') || exist('libsndfile_read','file')
	dlg_filter = {'*.wav;*.flac;*.ogg;*.mp3','Sound files';'*.*','All files'};
else
	dlg_filter = {'*.wav','Wave files (*.wav)';'*.*','All files'};
end
[dlg_name,dlg_path]=uigetfile(dlg_filter,'Выберите файл для обработки',get(handles.inputfile_edit,'String'));
if dlg_name==0
	return
end
set(handles.inputfile_edit,'String',fullfile(dlg_path,dlg_name));


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Visible','off');
pause(0.2);

fl = fieldnames(handles);
for fi = 1:numel(fl)
	if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol')
		switch get(handles.(fl{fi}),'Style')
			case 'edit'
				dlg_cfg.(fl{fi}) = get(handles.(fl{fi}),'String');
			case {'checkbox' 'popupmenu'}
				dlg_cfg.(fl{fi}) = get(handles.(fl{fi}),'Value');
		end
	end
end

save([mfilename '_cfg.mat'], 'dlg_cfg');

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[cfg, x, fs, t] = prepare_data(handles);
[Y, x, t] = process_data(cfg, x, fs, t);
if ~isempty(Y)
	display_data(handles, cfg, x, fs, t, Y);
end


function [cfg, x, fs, t] = prepare_data(handles)
cfg.filename = get(handles.inputfile_edit,'String');
if exist('audioread','file')
	[x,fs] = audioread(cfg.filename);
elseif exist('libsndfile_read','file')
	[x,x_info] = libsndfile_read(cfg.filename);
	fs = x_info.SampleRate;
else
	[x,fs] = wavread(cfg.filename); %#ok<*DWVRD>
end
x(:,2:end) = [];
if get(handles.inputfile_invert,'Value')
	x = x(end:-1:1,:);
end

eval(['cfg.F=' get(handles.freq_f,'String') ';']);
cfg.F = cfg.F(:)';
cfg.Kk = str2double_my(get(handles.freq_k,'String'));
eval(['cfg.theta=' get(handles.freq_phase_shift,'String') ';']);
cfg.theta = cfg.theta(1);
cfg.isclip = get(handles.freq_isclip,'Value');
cfg.is_freq_hilbert = get(handles.freq_hilbert,'Value');

isclip_str = 'Клипирование ';
if cfg.isclip
	isclip_str = [isclip_str 'ВКЛ.'];
else
	isclip_str = [isclip_str 'ВЫКЛ.'];
end
is_freq_hilbert_str = 'Фазовращение ВЧ сигнала ';
if cfg.is_freq_hilbert
	is_freq_hilbert_str = [is_freq_hilbert_str 'ВКЛ.'];
else
	is_freq_hilbert_str = [is_freq_hilbert_str 'ВЫКЛ.'];
end

cfg.fc = str2double_my(get(handles.filterlp_cutoff_edit,'String'));
cfg.b = fir1(round(str2double_my(get(handles.filterlp_order_edit,'String'))*fs), cfg.fc*2/fs);
cfg.b_ord2 = fix(numel(cfg.b)/2);
cfg.b_delay = numel(cfg.b);

cfg.is_framing = get(handles.is_framing, 'Value');
cfg.frame_size = str2double_my(get(handles.frame_size_edit, 'String'));
cfg.frame_shift = str2double_my(get(handles.frame_shift_edit, 'String'));
cfg.frame_shift = min(cfg.frame_shift, cfg.frame_size);
is_framing_str = 'Покадровая обработка ';
if cfg.is_framing
	is_framing_str = [is_framing_str 'ВКЛ.(Размер кадра ' num2str(cfg.frame_size) 'мс, Смещение между кадрами ' num2str(cfg.frame_shift) 'мс)'];
else
	is_framing_str = [is_framing_str 'ВЫКЛ.'];
end
cfg.frame_size = cfg.frame_size/1000;
cfg.frame_shift = cfg.frame_shift/1000;

x = [x; zeros(cfg.b_ord2,1)];
t = (0:size(x,1)-1)'/fs;

cfg.report_str = {	['F=' get(handles.freq_f,'String') 'Гц; Kk=' num2str(cfg.Kk) '; \theta=' num2str(cfg.theta) '; ' isclip_str ';' is_freq_hilbert_str '; Fs=' num2str(fs) 'Гц;'] ...
					['НЧ КИХ фильтр (Fc=' num2str(cfg.fc) 'Гц, порядок ' num2str(numel(cfg.b)) '); ' is_framing_str ';']};

cfg.usepool = false;
try
	if get(handles.gui_usepool,'Value')
		if exist('parpool','file')
			p = gcp('nocreate');
			if isempty(p)
				c = parcluster();
				if c.NumWorkers>1
					parpool();
				end
				pause(0.2);
			end
			cfg.usepool = ~isempty(gcp('nocreate'));
		else
			if matlabpool('size')==0 %#ok<DPOOL> % R2011b
				local_jm = findResource('scheduler','type','local'); %#ok<DFNDR>
				if local_jm.ClusterSize>1 && pool_dlg(handles)
					matlabpool('local'); %#ok<DPOOL>
				end
				pause(0.2);
			end
			cfg.usepool = matlabpool('size')>0; %#ok<DPOOL>
		end
	end
catch
end


function [Y, x, t] = process_data(cfg, x, fs, t)
if cfg.is_framing
	[Y, x, t] = process_data_frames(cfg, x, fs, t);
else
	[Y, x, t] = process_data_stream(cfg, x, fs, t);
end


function [Y, x, t] = process_data_frames(cfg, x, fs, t)
frame_size = round(cfg.frame_size * fs);
frame_shift = round(cfg.frame_shift * fs);
frame_offset = fix((frame_size - frame_shift)/2);

x(end-cfg.b_ord2+1:end) = [];
t(end-cfg.b_ord2+1:end) = [];
Y = [];

tic();
wait_hndl = waitbar(0, 'Progress...', 'CloseRequestFcn',@terminate_req);
global phase_demod_dlg_closereq;
phase_demod_dlg_closereq = false;

ind = 1:frame_shift:size(x)-frame_size+1;
for ind_i = 1:numel(ind)
	ii = ind(ind_i);
	cur_i = ii:ii+frame_size-1;
	cur_x = [x(cur_i); zeros(cfg.b_ord2,1)];
	cur_t = (0:size(cur_x,1)-1)'/fs;
	cur_Y = process_data_stream(cfg, cur_x , fs, cur_t);
	if isempty(Y)
		Y = nan(size(x,1), size(cur_Y,2));
	end
	Y(ii+frame_offset:ii+frame_offset+frame_shift-1,:) = cur_Y(frame_offset+1:frame_offset+frame_shift,:);

	a = toc*((numel(ind)/ind_i)-1);
	rem_str = sprintf('%.0f%%; %02d:%02d:%02d remain...',ind_i*100/numel(ind), fix(a/3600), fix(rem(a,3600)/60), fix(rem(rem(a,3600),60)));
	set(wait_hndl, 'Name',rem_str);
	waitbar(ind_i/numel(ind),wait_hndl,['Progress ' rem_str]);

	if phase_demod_dlg_closereq
		Y = [];
		return
	end
end

close(wait_hndl);

ii = isnan(Y(:,1));
Y(ii,:) = [];
x(ii,:) = [];
t(ii,:) = [];

function terminate_req(hObject, eventdata)
global phase_demod_dlg_closereq;
phase_demod_dlg_closereq = true;
delete(hObject);


function [Y, x, t] = process_data_stream(cfg, x, fs, t)
global phase_demod_dlg_closereq;

Y = cell(size(cfg.F));
if cfg.usepool
	parfor fi = 1:numel(cfg.F)
		Y{fi} = for_body(cfg.F(fi), cfg, x, fs, t);
	end
else
	if ~cfg.is_framing
		tic();
		wait_hndl = waitbar(0, 'Progress...', 'CloseRequestFcn',@terminate_req);
		phase_demod_dlg_closereq = false;
	end

	for fi = 1:numel(cfg.F)
		Y{fi} = for_body(cfg.F(fi), cfg, x, fs, t);

		if ~cfg.is_framing
			a = toc*((numel(cfg.F)/fi)-1);
			rem_str = sprintf('%.0f%%; %02d:%02d:%02d remain...',fi*100/numel(cfg.F), fix(a/3600), fix(rem(a,3600)/60), fix(rem(rem(a,3600),60)));
			set(wait_hndl, 'Name',rem_str);
			waitbar(fi/numel(cfg.F),wait_hndl,['Progress ' rem_str]);
			
			if phase_demod_dlg_closereq
				Y = [];
				return
			end
		end
	end

	if ~cfg.is_framing
		close(wait_hndl);
	end
	
end
Y = cell2mat(Y);
x(end-cfg.b_ord2+1:end) = [];
t(end-cfg.b_ord2+1:end) = [];


function Yp = for_body(F, cfg, x, fs, t)
x_lo = proc_signal(x, F, t, 0, cfg.isclip, false);
if cfg.is_freq_hilbert
	x_hi = -imag(hilbert(x));
else
	x_hi = x;
end
x_hi = proc_signal(x_hi, cfg.Kk*F, t, cfg.theta, cfg.isclip, cfg.is_freq_hilbert);
if cfg.is_freq_hilbert
	Yp = x_lo + x_hi;
else
	Yp = x_lo - x_hi;
end
Yp = fftfilt(cfg.b, Yp);
Yp(1:fix(numel(cfg.b)/2)) = [];


function display_data(handles, cfg, x, fs, t, Y)
[cur_dir, cur_name] = fileparts(cfg.filename); %#ok<*ASGLU>
figure('NumberTitle','off', 'Name',cur_name, 'Units','normalized', 'Position',[0 0 1 1]);
subplot(2,1,1);
plot(t,x);
x_lim = t([1 end])';
axis([x_lim max(abs(x))*1.1*[-1 1]]);
title(cfg.filename,'Interpreter','none');

subplot(2,1,2);
if size(Y,2) == 1
	plot(t,Y);
	xlim(x_lim);
else
	imagesc(t,cfg.F,Y');
	pal = get(handles.gui_palette,'String');
	pal = pal{get(handles.gui_palette,'Value')};
	colormap(getcolormap(pal));
	axis('xy');
end
title(cfg.report_str);

set(zoom,'ActionPostCallback',@on_zoom_pan);
set(pan ,'ActionPostCallback',@on_zoom_pan);
zoom('xon');
set(pan, 'Motion', 'horizontal');



function x = str2double_my(str)
if any(str==',')
	errordlg('При указании чисел с плавающей запятой в полях ввода должна использоваться точка, а не запятая.');
	error('Incorrect input parameters.');
end
x = str2double(str);


function y = proc_signal(x,f,t,phi,isclip,is_freq_hilbert)
if is_freq_hilbert
	y = cos(2*pi*f*t+phi);
else
	y = sin(2*pi*f*t+phi);
end
if isclip
	ii = y>=0;
	y(ii) = 1;
	y(~ii) = -1;
end
y = x.*y;


function on_zoom_pan(hObject, eventdata) %#ok<*INUSD>
%	Usage example:
%	set(zoom,'ActionPostCallback',@on_zoom_pan);
%	set(pan ,'ActionPostCallback',@on_zoom_pan);
%	zoom('xon');
%	set(pan, 'Motion', 'horizontal');

x_lim=xlim();

data=guidata(hObject);
if isfield(data,'user_data') && isfield(data.user_data.x_len)
	rg=x_lim(2)-x_lim(1);
	if x_lim(1)<0
		x_lim=[0 rg];
	end
	if x_lim(2)>data.user_data.x_len
		x_lim=[max(0, data.user_data.x_len-rg) data.user_data.x_len];
	end
end

child=get(hObject,'Children');
set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);


function map = getcolormap(colormaptype)
switch lower(colormaptype)
	case 'antigray'
		map=makecolormap([	  0   1   1   1;
							0.4   1   1   1;
							0.9   0   0   0;
							  1   0   0   0]);
	case 'speech'
		map=makecolormap([	0	  0   0   1;...
							1/3	  0   1   0;...
							2/3	  1   0   0;...
							  1	  1   1   0]);
	case 'fire'
		map=makecolormap([	0	  0   0   0;...
						  0.113	0.5   0   0;...
						  0.315	  1   0   0;...
						  0.450	  1 0.5   0;...
						  0.585	  1   1   0;...
						  0.765	  1   1 0.5;...
							  1	  1   1   1]);
	case 'hsl'
		map=makecolormap([	0	  0   0   0;...
							1/7	  1   0   1;...
							2/7	  0   0   1;...
							3/7	  0   1   1;...
							4/7	  0 0.5   0;...
							5/7	  1   1   0;...
							6/7	  1   0   0;...
							  1	  1   1   1]);
	otherwise
		map=colormaptype;
end


function map = makecolormap(map_info)
map=zeros(64,3);
map(1,:)=map_info(1,2:4);
index=1;
for i=2:63
	pos=(i-1)/63;
	while map_info(index,1)<=pos
		index=index+1;
	end
	map(i,:)=map_info(index-1,2:4)+(map_info(index,2:4)-map_info(index-1,2:4))*(pos-map_info(index-1,1))/(map_info(index,1)-map_info(index-1,1));
end
map(64,:)=map_info(end,2:4);


% --- Executes on button press in filterlp_view.
function filterlp_view_Callback(hObject, eventdata, handles)
% hObject    handle to filterlp_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = get(handles.inputfile_edit,'String');
if exist('audioread','file')
	[x,fs] = audioread(filename);
elseif exist('libsndfile_read','file')
	[x,x_info] = libsndfile_read(filename);
	fs = x_info.SampleRate;
else
	[x,fs] = wavread(filename); %#ok<*DWVRD>
end
fc = str2double_my(get(handles.filterlp_cutoff_edit,'String'));
w = fc*2/fs;
b = fir1(round(str2double_my(get(handles.filterlp_order_edit,'String'))*fs), w);
[H,w] = freqz(b,1,256*1024);
figure('NumberTitle','off', 'Name','FIR filter responce');
H = 20*log10(abs(H));
plot(w*fs/(2*pi), H, 'LineWidth',1.5);
axis([0 fc*3 -120 5]);
line([0 fc fc],[0 0 -300],'Color','r','LineStyle','--','LineWidth',1.5);
grid('on');
title(sprintf('АЧХ НЧ КИХ фильтра, частота среза %s Гц, порядок %d, частота дискретизации %s Гц',num2str(fc),numel(b),num2str(fs)), 'interpreter','none');
xlabel('Частота, Гц');
ylabel('Амплитуда, дБ');


% --- Executes on button press in is_framing.
function is_framing_Callback(hObject, eventdata, handles)
% hObject    handle to is_framing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of is_framing
if get(hObject,'Value')
	state_str = 'on';
else
	state_str = 'off';
end
set(handles.frame_size_edit,'Enable',state_str);
set(handles.frame_shift_edit,'Enable',state_str);


% --- Executes on button press in inputfile_play_btn.
function inputfile_play_btn_Callback(hObject, eventdata, handles)
% hObject    handle to inputfile_play_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dos(['start "" "' get(handles.inputfile_edit,'String') '"']);
