function varargout = phase_analysis_dlg(varargin)
% PHASE_ANALYSIS_DLG M-file for phase_analysis_dlg.fig
%      PHASE_ANALYSIS_DLG, by itself, creates a new PHASE_ANALYSIS_DLG or raises the existing
%      singleton*.
%
%      H = PHASE_ANALYSIS_DLG returns the handle to a new PHASE_ANALYSIS_DLG or the handle to
%      the existing singleton*.
%
%      PHASE_ANALYSIS_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHASE_ANALYSIS_DLG.M with the given input arguments.
%
%      PHASE_ANALYSIS_DLG('Property','Value',...) creates a new PHASE_ANALYSIS_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before phase_analysis_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to phase_analysis_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help phase_analysis_dlg

% Last Modified by GUIDE v2.5 05-Aug-2010 12:25:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @phase_analysis_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @phase_analysis_dlg_OutputFcn, ...
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


% --- Executes just before phase_analysis_dlg is made visible.
function phase_analysis_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to phase_analysis_dlg (see VARARGIN)

% Choose default command line output for phase_analysis_dlg
handles.output = hObject;

try
	load('phase_analysis_dlg_cfg.mat');

	set(handles.ed_filename,'String',dlg_cfg.filename);
	set(handles.chk_harm_save,'Value',dlg_cfg.harm_save);
	set(handles.ed_harm_dir,'String',dlg_cfg.harm_dir);
	set(handles.ed_func,'String',dlg_cfg.func);

	set(handles.ed_f0_framesize,'String',dlg_cfg.f0.framesize);
	set(handles.ed_f0_frameshift,'String',dlg_cfg.f0.frameshift);
	set(handles.ed_f0_pitchmul,'String',dlg_cfg.f0.pitchmul);
	set(handles.ed_f0_sideband,'String',dlg_cfg.f0.sideband);

	set(handles.ed_flt_framesize,'String',dlg_cfg.flt.framesize);
	set(handles.ed_flt_frameshift,'String',dlg_cfg.flt.frameshift);
	set(handles.ed_flt_sideband,'String',dlg_cfg.flt.sideband);
	set(handles.pop_flt_type,'Value',dlg_cfg.flt.type);

	set(hObject,'Position',dlg_cfg.position);

	chk_harm_save_Callback(0, eventdata, handles);
catch
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes phase_analysis_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = phase_analysis_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ed_filename_Callback(hObject, eventdata, handles)
% hObject    handle to ed_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_filename as text
%        str2double(get(hObject,'String')) returns contents of ed_filename as a double


% --- Executes during object creation, after setting all properties.
function ed_filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_filename_sel.
function btn_filename_sel_Callback(hObject, eventdata, handles)
% hObject    handle to btn_filename_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки', get(handles.ed_filename,'String'));
	if dlg_name==0
		return;
	end
	set(handles.ed_filename,'String',fullfile(dlg_path,dlg_name));


% --- Executes on button press in chk_harm_save.
function chk_harm_save_Callback(hObject, eventdata, handles)
% hObject    handle to chk_harm_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chk_harm_save
	if get(handles.chk_harm_save,'Value')
		st='on';
	else
		st='off';
	end
	set(handles.ed_harm_dir,'Enable',st);
	set(handles.btn_harm_dir_sel,'Enable',st);


function ed_harm_dir_Callback(hObject, eventdata, handles)
% hObject    handle to ed_harm_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_harm_dir as text
%        str2double(get(hObject,'String')) returns contents of ed_harm_dir as a double


% --- Executes during object creation, after setting all properties.
function ed_harm_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_harm_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_harm_dir_sel.
function btn_harm_dir_sel_Callback(hObject, eventdata, handles)
% hObject    handle to btn_harm_dir_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	dlg_name=uigetdir(get(handles.ed_harm_dir,'String'), 'Выберите директорию для сохранения гармоник основного тона');
	if dlg_name==0
		return;
	end
	set(handles.ed_harm_dir,'String',dlg_name);


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function ed_func_Callback(hObject, eventdata, handles)
% hObject    handle to ed_func (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_func as text
%        str2double(get(hObject,'String')) returns contents of ed_func as a double


% --- Executes during object creation, after setting all properties.
function ed_func_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_func (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_calc.
function btn_calc_Callback(hObject, eventdata, handles)
% hObject    handle to btn_calc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	filename=get(handles.ed_filename,'String');
	[cur_path,cur_name,cur_ext]=fileparts(filename);
	[x,fs_x]=wavread(filename);
	x(:,2:end)=[];
	
	eval_str = cellstr(get(handles.ed_func,'String'));
	regexp_str = cellfun(@(x) [x ';'], eval_str, 'UniformOutput',false);
	regexp_str = [regexp_str{:}];
	phase_mul  = [regexp(regexp_str, '(?<=(^p|\Wp)hi)\d+', 'match') regexp(regexp_str, '(?<=(^x|\Wx))\d+', 'match')];
	phase_mul  = sort( cellfun(@str2double, phase_mul) );

	alg.pitch=struct(	'frame_size',	str2double(get(handles.ed_f0_framesize,'String')),	...
						'frame_shift',	str2double(get(handles.ed_f0_frameshift,'String')),	...
						'pitch_mul',	str2num(get(handles.ed_f0_pitchmul,'String')),		...
						'fine_side_band',str2double(get(handles.ed_f0_sideband,'String')));

	filt_names=get(handles.pop_flt_type,'String');
	alg.phase=struct(	'mul',			phase_mul,			...
						'filt',struct(	'frame_size',	str2double(get(handles.ed_flt_framesize,'String')),	...
										'frame_shift',	str2double(get(handles.ed_flt_frameshift,'String')),...
										'type',			filt_names{get(handles.pop_flt_type,'Value')},		...
										'side_band',	str2double(get(handles.ed_flt_sideband,'String')) )	);

	try
		if matlabpool('size')==0
			local_jm=findResource('scheduler','type','local');
			if local_jm.ClusterSize>1 && ... 
				strcmp(questdlg({'No matlabpool opened.' ...
					'Matlab pool usage can significantly increase analysis performance.' ...
					'Open local matlabpool?'},'Parallel computations','Yes','No','Yes'),'Yes')
				matlabpool('local');
			end
			pause(0.2);
		end
	catch %#ok<CTCH>
	end

	[harm_phi, f0_freq, harm_x, harm_fs, harm_t]=phase_analysis(x, fs_x, alg);

	if get(handles.chk_harm_save,'Value')
		new_path=get(handles.ed_harm_dir,'String');
		if isempty(new_path)
			new_path=cur_path;
		end
		for ch=1:numel(alg.phase.mul)
			cur_ch=harm_x(:,ch);
			cur_ch(isnan(cur_ch))=0;
			wavwrite(cur_ch, harm_fs, 32, [new_path filesep cur_name '_harm' num2str(alg.phase.mul(ch)) '.wav']);
		end
	end

	notnan_ind=not(any(isnan(harm_phi),2));
	notnan_diff=diff([false; notnan_ind; false]);
	voiced_reg=[find(notnan_diff==1) find(notnan_diff==-1)-1];
	y_cell=cell(size(voiced_reg,1),1);
	for ri=1:size(voiced_reg,1)
		cur_phi = harm_phi(voiced_reg(ri,1):voiced_reg(ri,2),:);
		cur_x = harm_x(voiced_reg(ri,1):voiced_reg(ri,2),:);
		cur_t = harm_t(voiced_reg(ri,1):voiced_reg(ri,2),:);
		cur_f0= f0_freq(voiced_reg(ri,1):voiced_reg(ri,2),:);
		y_cell{ri} = func_eval_block(cur_t, cur_f0, cur_phi, cur_x, harm_fs, alg, eval_str);
	end
	y=nan(size(harm_phi,1),size(y_cell{1},2));
	y(notnan_ind,:)=cell2mat(y_cell);

	fig=figure('NumberTitle','off', 'Name',[cur_name cur_ext], 'Toolbar','figure', 'Units','normalized', 'Position',[0 0 1 1]);

	subplot_sgnl=axes('Units','normalized', 'Position',[0.05 0.8 0.93 0.10]);
	plot((0:size(x,1)-1)/fs_x, x);
	axis([0 (size(x,1)-1)/fs_x max(abs(x))*1.1*[-1 1]]);
	caret(1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
	grid('on');
	set(subplot_sgnl, 'XTickLabel',[]);
%	xlabel('Время, с');
%	ylabel('Сигнал');
	title({filename eval_str{:}}, 'Interpreter','none');
	
	subplot_spectrogram=axes('Units','normalized', 'Position',[0.05 0.6 0.93 0.18]);
	frame_size=round(alg.pitch.frame_size*fs_x);
	frame_shift=max(1,round(alg.pitch.frame_shift*fs_x));
	[sp_s, sp_f, sp_t]=spectrogram(x, frame_size, frame_size-frame_shift, 2^nextpow2(round(alg.pitch.frame_size*fs_x)), fs_x);
	imagesc(sp_t,sp_f,20*log10(abs(sp_s)));
	axis('xy');
	y_lim=ylim();
	ylim([y_lim(1) min(2000,y_lim(2))]);
	set(subplot_spectrogram, 'XTickLabel',[]);
	
	colormap(makecolormap([    0      1   1   1;  0.5      1   1   1;   1      0   0   0]));

	subplot_hist=axes('Units','normalized', 'Position',[0.05 0.05 0.3 0.21]);
	subplot_histd=axes('Units','normalized', 'Position',[0.68 0.05 0.3 0.21]);
	
	subplot_est=axes('Units','normalized', 'Position',[0.05 0.3 0.93 0.28]);
%{
	y_marks={'b.-' 'go-' 'rx-' 'm+-' 'ks-' 'bd-' 'gv-' 'r^-' 'm<-' 'k>-' 'b*-' 'gp-' 'rh-'};
	y_marks_out=[];
	for i=1:size(y,2)
		cur_mark=y_marks{rem(i-1,length(y_marks))+1};
		plot(t,y(:,i),cur_mark);
		hold('on');
		y_marks_out=[y_marks_out '  ' cur_mark];
	end
%}
	plot(harm_t,y);
	caret(2)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
	grid('on');
%	ylabel('y');
%	xlabel('Время, с');

	set(zoom,'ActionPostCallback',@OnZoomPan);
	set(pan ,'ActionPostCallback',@OnZoomPan);
	pan('xon');
	zoom('xon');
	
	ctrl_pos=get(subplot_sgnl,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
		'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);
%	set(fig, 'Units','pixels', 'Position',get(0,'ScreenSize'));

	player = audioplayer(x, fs_x);
	set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
				'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	data.user_data = struct('player',player, 'btn_play',btn_play, 'x_len',(size(x,1)-1)/fs_x, 'zoom_axes',[subplot_sgnl subplot_spectrogram subplot_est], ...
							'subplot_hist',subplot_hist, 'subplot_histd',subplot_histd, ...
							'harm_phi',harm_phi, 'f0_freq',f0_freq, 'harm_x',harm_x, 'harm_fs',harm_fs, 'evals',y);
	guidata(fig,data);
	OnZoomPan(fig);

function map=makecolormap(map_info)
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


function OnZoomPan(hObject, eventdata)
	data = guidata(hObject);

	x_lim=xlim();
	rg=x_lim(2)-x_lim(1);
	if x_lim(1)<0
		x_lim=[0 rg];
	end
	if x_lim(2)>data.user_data.x_len
		x_lim=[max(0, data.user_data.x_len-rg) data.user_data.x_len];
	end

	if isfield(data.user_data,'zoom_axes')
		set(data.user_data.zoom_axes, 'XLim', x_lim);
	else
		child=get(hObject,'Children');
		set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
	end
	
	x_lim_smpl=min(round(x_lim*data.user_data.harm_fs)+1, size(data.user_data.evals,1));
	evals=data.user_data.evals(x_lim_smpl(1):x_lim_smpl(2),:);
	devals=diff(evals)*data.user_data.harm_fs;
	evals(any(isnan(evals),2),:)=[];

	evals_2pi=rem(evals,2*pi);
	evals_2pi(evals_2pi<0)=evals_2pi(evals_2pi<0)+2*pi;

	hx=linspace(0,2*pi,20)';
	hy=histc(evals_2pi, hx);
	bar(data.user_data.subplot_hist, hx,hy./repmat(sum(hy),size(hy,1),1));
	xlim(data.user_data.subplot_hist, [0 2*pi]);
	set(data.user_data.subplot_hist, 'XTick',0:6);
	grid(data.user_data.subplot_hist, 'on');
	ylabel(data.user_data.subplot_hist, '2*Pi warped Y distribution');

	stat_str={	'Y statistics:'
				['mean: ' sprintf('%.2f  ',mean(evals))]
				['median: ' sprintf('%.2f  ',median(evals))]
				['std: ' sprintf('%.2f  ',std(evals))]};
	title(data.user_data.subplot_hist, stat_str, 'Units','normalized', ...
		'Position',[1.1 1 0], 'VerticalAlignment','top', 'HorizontalAlignment','left');

	hx=(-1:0.1:1)*(max(max(abs(quantile(devals, [0.01 0.99]))))+0.000001);
	hy=histc(devals, hx);
	bar(data.user_data.subplot_histd, hx,hy./repmat(sum(hy),size(hy,1),1));
	grid(data.user_data.subplot_histd, 'on');
	ylabel(data.user_data.subplot_histd, 'Y derivative distribution');


function OnPlaySignal(hObject, eventdata)
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples, max(1, round( xlim()*data.user_data.player.SampleRate+1 ) ) );
		play(data.user_data.player, x_lim);
		set(data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(data.user_data.player);
	end


function CallbackPlay(obj, event, string_arg)
	user_data=get(obj, 'UserData');
	cur_pos=(get(obj, 'CurrentSample')-1)/get(obj, 'SampleRate');
	for i=1:length(user_data.caret)
		set(user_data.caret(i),'XData',[cur_pos cur_pos]);
	end


function CallbackPlayStop(obj, event, string_arg)
	CallbackPlay(obj);
	user_data=get(obj, 'UserData');
	set(user_data.btn_play, 'String', 'Play view');


function y=func_eval_block(t, F0, phi, x, fs, alg, eval_str)
	for ch=1:numel(alg.phase.mul)
		eval(['x' num2str(alg.phase.mul(ch)) '=x(:,ch);']);
		eval(['phi' num2str(alg.phase.mul(ch)) '=phi(:,ch);']);
	end

	if isa(eval_str,'cell')
		for eval_cell_ind=1:numel(eval_str)
			eval(eval_str{eval_cell_ind});
		end
	else
		if size(eval_str,1)>1
			eval_str=eval_str';
			eval_str=eval_str(1:numel(eval_str));
		end
		eval(eval_str);
	end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	set(gco, 'Visible','off');
	pause(0.2);

	dlg_cfg.filename=		get(handles.ed_filename,'String');
	dlg_cfg.harm_save=		get(handles.chk_harm_save,'Value');
	dlg_cfg.harm_dir=		get(handles.ed_harm_dir,'String');
	dlg_cfg.func=			cellstr(get(handles.ed_func,'String'));

	dlg_cfg.f0.framesize=	get(handles.ed_f0_framesize,'String');
	dlg_cfg.f0.frameshift=	get(handles.ed_f0_frameshift,'String');
	dlg_cfg.f0.pitchmul=	get(handles.ed_f0_pitchmul,'String');
	dlg_cfg.f0.sideband=	get(handles.ed_f0_sideband,'String');

	dlg_cfg.flt.framesize=	get(handles.ed_flt_framesize,'String');
	dlg_cfg.flt.frameshift=	get(handles.ed_flt_frameshift,'String');
	dlg_cfg.flt.sideband=	get(handles.ed_flt_sideband,'String');
	dlg_cfg.flt.type=		get(handles.pop_flt_type,'Value');

	dlg_cfg.position=		get(hObject,'Position');

	save('phase_analysis_dlg_cfg.mat', 'dlg_cfg');

	% Hint: delete(hObject) closes the figure
	delete(hObject);



function ed_f0_framesize_Callback(hObject, eventdata, handles)
% hObject    handle to ed_f0_framesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_f0_framesize as text
%        str2double(get(hObject,'String')) returns contents of ed_f0_framesize as a double


% --- Executes during object creation, after setting all properties.
function ed_f0_framesize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_f0_framesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_f0_frameshift_Callback(hObject, eventdata, handles)
% hObject    handle to ed_f0_frameshift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_f0_frameshift as text
%        str2double(get(hObject,'String')) returns contents of ed_f0_frameshift as a double


% --- Executes during object creation, after setting all properties.
function ed_f0_frameshift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_f0_frameshift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_f0_pitchmul_Callback(hObject, eventdata, handles)
% hObject    handle to ed_f0_pitchmul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_f0_pitchmul as text
%        str2double(get(hObject,'String')) returns contents of ed_f0_pitchmul as a double


% --- Executes during object creation, after setting all properties.
function ed_f0_pitchmul_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_f0_pitchmul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_f0_sideband_Callback(hObject, eventdata, handles)
% hObject    handle to ed_f0_sideband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_f0_sideband as text
%        str2double(get(hObject,'String')) returns contents of ed_f0_sideband as a double


% --- Executes during object creation, after setting all properties.
function ed_f0_sideband_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_f0_sideband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_flt_framesize_Callback(hObject, eventdata, handles)
% hObject    handle to ed_flt_framesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_flt_framesize as text
%        str2double(get(hObject,'String')) returns contents of ed_flt_framesize as a double


% --- Executes during object creation, after setting all properties.
function ed_flt_framesize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_flt_framesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_flt_sideband_Callback(hObject, eventdata, handles)
% hObject    handle to ed_flt_sideband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_flt_sideband as text
%        str2double(get(hObject,'String')) returns contents of ed_flt_sideband as a double


% --- Executes during object creation, after setting all properties.
function ed_flt_sideband_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_flt_sideband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_flt_type.
function pop_flt_type_Callback(hObject, eventdata, handles)
% hObject    handle to pop_flt_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_flt_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_flt_type


% --- Executes during object creation, after setting all properties.
function pop_flt_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_flt_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_flt_frameshift_Callback(hObject, eventdata, handles)
% hObject    handle to ed_flt_frameshift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_flt_frameshift as text
%        str2double(get(hObject,'String')) returns contents of ed_flt_frameshift as a double


% --- Executes during object creation, after setting all properties.
function ed_flt_frameshift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_flt_frameshift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
