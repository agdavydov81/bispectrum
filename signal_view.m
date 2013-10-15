function signal_view(cfg)
	if nargin<1
		cfg_file_name='signal_view_cfg.mat';
		if exist(cfg_file_name,'file')
			load(cfg_file_name, 'cfg');
		end
	end

	if ~exist('cfg','var');					cfg = struct();						end
	if ~isfield(cfg,'fs');					cfg.fs = 0;							end % 0 - auto
	if ~isfield(cfg,'lpc_order');			cfg.lpc_order = 0;					end % 0 - auto
	if ~isfield(cfg,'frame_size');			cfg.frame_size = 0.025;				end
	if ~isfield(cfg,'frame_shift');			cfg.frame_shift = 0.005;			end
	if ~isfield(cfg,'fft_size');			cfg.fft_size = 512;					end
	if ~isfield(cfg,'preemphasis');			cfg.preemphasis = 'adaptive';		end
	if ~isfield(cfg,'window');				cfg.window = 'hamming';				end
	if ~isfield(cfg,'F0');					cfg.F0 = [80 500];					end
	if ~isfield(cfg,'roots_threshold');		cfg.roots_threshold = sqrt(0.5);	end
	if ~isfield(cfg,'display_spectrogram');	cfg.display_spectrogram = 'lpc';	end % 'display_spectrogram' must be either 'lpc' either 'fft'
	if ~isfield(cfg,'display_palette');		cfg.display_palette = 'antigray';	end
	if ~isfield(cfg,'show_lsf');			cfg.show_lsf = true;				end
	if ~isfield(cfg,'show_strong_roots');	cfg.show_strong_roots = true;		end
	if ~isfield(cfg,'show_weak_roots');		cfg.show_weak_roots = true;			end

	if nargin<1
		[cfg, press_OK]=settings_dlg(cfg);
		if ~press_OK
			return
		end
		save(cfg_file_name,'cfg');
	end

	%% Signal preparation
	[x,fs]=wavread(cfg.file_name);
	x(:,2:end)=[];
	
	[region_pos, region_name]=safe_wav_regions_read(cfg.file_name);
	region_pos = [region_pos(:,1)-1 sum(region_pos,2)]/fs;

	if isfield(cfg,'fs') && cfg.fs && cfg.fs~=fs
		x=resample(x,cfg.fs,fs);
	else
		cfg.fs=fs;
	end

	frame_size=round(cfg.frame_size*cfg.fs);
	frame_shift=round(cfg.frame_shift*cfg.fs);

	cfg.T0=sort(min(frame_size, round(cfg.fs./cfg.F0)));
	
	if not(isfield(cfg,'lpc_order')) || cfg.lpc_order==0
		cfg.lpc_order=round(cfg.fs/1000)+4;
	end

	%% Waveform display
	[fig_file_path,fig_file_name]=fileparts(cfg.file_name); %#ok<ASGLU>
	fig=figure(	'NumberTitle','off', 'Name',fig_file_name, 'ToolBar','figure', 'Units','normalized', ...
				'Position',[0 0 1 1], 'WindowButtonDownFcn',@OnMouseDown, 'KeyPressFcn',@OnKeyPress);

	signal_subplot=axes('Units','normalized', 'Position',[0.06 0.75 0.92 0.20]);
	plot((0:length(x)-1)/cfg.fs, x);
	x_lim=[0 length(x)-1]/cfg.fs;
	signal_lim=max(abs(x))*1.1*[-1 1];
	axis([x_lim signal_lim]);
	grid on;	ylabel('Oscillogram');
	title(cfg.file_name,'Interpreter','none');
	stat_ylim=ylim();
	stat_ylim=stat_ylim+0.01*diff(stat_ylim)*[1 -1];
	stat_caret=line(zeros(1,5), stat_ylim([1 2 2 1 1]), 'Color','k', 'LineWidth',1.5);
	caret=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

	if ~isempty(region_pos)
		plot_regions_str(region_pos, [0.5 0.5 0.5], 0.5, 'k', region_name);
	end
	
	%% Calculate observations: LPC spectrogramm, LSFs, roots
	spectrum_subplot=axes('Units','normalized', 'Position',[0.06 0.42 0.92 0.30]);
	frames_num=fix((size(x,1)-frame_size)/frame_shift+1);
	lsf_obs=zeros(frames_num,cfg.lpc_order);
	time_obs=((0:frames_num-1)'*frame_shift+frame_size/2)/cfg.fs;
	freq_obs=(0:cfg.fft_size-1)'*cfg.fs/(2*cfg.fft_size);
	roots_weak_obs=  cell(frames_num,1);
	roots_strong_obs=cell(frames_num,1);

	is_preemphasis = isfield(cfg,'preemphasis') && not(isequal(cfg.preemphasis,0)) && not(isequal(cfg.preemphasis,'none'));
	is_preemphasis_adaptive=false;
	if is_preemphasis
		is_preemphasis_adaptive=isequal(cfg.preemphasis,'adaptive');
	end

	ind=1:frame_shift:size(x,1)-frame_size+1;

	try
		if frames_num>300 && matlabpool('size')==0
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

	if strcmp(cfg.display_spectrogram,'lpc')
		signal_spectrogram=zeros(cfg.fft_size,frames_num);
	end
	x_win=window(cfg.window,frame_size);

	parfor obs_ind=1:length(ind)
		i=ind(obs_ind);
		cur_x=x(i:i+frame_size-1).*x_win; %#ok<PFBNS>

		if is_preemphasis
			if is_preemphasis_adaptive
				% J.D. Markel and A.H. Gray, Linear Prediction of Speech, Springer-Verlag, New York, USA, 1976.
				% part 6.5.6 Preemphasis
%				preemphasis_factor=sum(cur_x(1:end-1).*cur_x(2:end)) / sum(cur_x.*cur_x);
				preemphasis_factor=lpc(cur_x,1); % sum(cur_x(1:end-1).*cur_x(2:end)) / sum(cur_x.*cur_x);
				preemphasis_factor=-preemphasis_factor(2);
			else
				preemphasis_factor=cfg.preemphasis; %#ok<PFBNS>
			end
			cur_x=filter([1 -preemphasis_factor],1,cur_x);
		end

		[cur_a, cur_err_pwr]=lpc(cur_x, cfg.lpc_order);
		if cur_err_pwr>0
			cur_a=cur_a./sqrt(cur_err_pwr*frame_size);
		end
		if any(isnan(cur_a))
			cur_a=[1 zeros(1, cfg.lpc_order)];
		end
		lsf_obs(obs_ind,:)=poly2lsf(cur_a);

		if strcmp(cfg.display_spectrogram,'lpc')
			signal_spectrogram(:,obs_ind)=20*log10(abs(freqz(1, cur_a, cfg.fft_size)));
		end

		cur_r=roots(cur_a);
		cur_r(imag(cur_r)<0)=[];
		strong_ind=abs(cur_r)>cfg.roots_threshold & imag(cur_r)>0;
		cur_r_strong=cur_r(strong_ind);
		cur_r(strong_ind)=[];

		if isempty(cur_r_strong)
			roots_strong_obs{obs_ind}=zeros(0,3);
		else
			roots_strong_obs{obs_ind}=[time_obs(obs_ind)+zeros(size(cur_r_strong)) angle(cur_r_strong)*cfg.fs/2/pi abs(cur_r_strong)];
		end

		if isempty(cur_r)
			roots_weak_obs{obs_ind}=zeros(0,3);
		else
			roots_weak_obs{obs_ind}=[time_obs(obs_ind)+zeros(size(cur_r)) angle(cur_r)*cfg.fs/2/pi abs(cur_r)];
		end
	end
	if strcmp(cfg.display_spectrogram,'fft')
		[signal_spectrogram,freq_obs,time_obs]=spectrogram(x, frame_size, frame_size-frame_shift, cfg.fft_size*2, cfg.fs);
		signal_spectrogram=10*log10(signal_spectrogram.*conj(signal_spectrogram));
		time_obs=time_obs(:);
	end

	roots_weak_obs=cell2mat(roots_weak_obs);
	roots_strong_obs=cell2mat(roots_strong_obs);
	spec_max=max(signal_spectrogram(:));
	spec_min=quantile(signal_spectrogram(:),0.05);
	signal_spectrogram(signal_spectrogram<spec_min)=spec_min;
	spec_minmax=[ceil(spec_min/10-1)*10 floor(spec_max/10+1)*10];

	%% Plot spectrogram
	imagesc(time_obs,freq_obs,signal_spectrogram);
	axis('xy');
	axis([x_lim 0 cfg.fs/2]);
	ylabel('Spectrogram, Hz');
	stat_ylim=ylim();
	stat_ylim=stat_ylim+0.01*diff(stat_ylim)*[1 -1];
	stat_caret(end+1)=line(zeros(1,5), stat_ylim([1 2 2 1 1]), 0.1+zeros(1,5), 'Color','k', 'LineWidth',1.5);
	caret(end+1)=line([0 0], ylim(), 0.1+[0 0], 'Color','r', 'LineWidth',2);
	if isfield(cfg,'display_palette')
		setcolormap(cfg.display_palette);
	end

	hold('on');

	%% Plot LSFs
	lsf_tracks=plot3(repmat(time_obs,1,size(lsf_obs,2)), lsf_obs*cfg.fs/(2*pi), 0.2+zeros(size(lsf_obs)), 'k');

	%% Plot roots
	roots_weak_tracks=  plot3(roots_weak_obs(:,1),  roots_weak_obs(:,2),  0.3+zeros(size(roots_weak_obs  ,1),1),'o', 'MarkerEdgeColor','k', 'MarkerFaceColor',0.7+[0 0 0], 'MarkerSize',3);
	roots_strong_tracks=plot3(roots_strong_obs(:,1),roots_strong_obs(:,2),0.3+zeros(size(roots_strong_obs,1),1),'o', 'MarkerEdgeColor','k', 'MarkerFaceColor','w', 'MarkerSize',5);
	
	stat_axes=	axes('Units','normalized', 'Position',[0.06 0.08 0.28 0.28]);
%				axes('Units','normalized', 'Position',[0.38 0.08 0.28 0.28]) ...
%				axes('Units','normalized', 'Position',[0.70 0.08 0.28 0.28])];

	%% GUI setup
	ctrl_pos=get(signal_subplot,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);
	ui_show_lsf =	uicontrol('Parent',fig,	'Style','checkbox',	'String','Show LSF',			'Units','normalized',	'Position',[ctrl_pos(1)	  ctrl_pos(2)+ctrl_pos(4) 0.10 0.03],		'Value',cfg.show_lsf,			'Callback', @OnShowLSF);
	ui_show_strong=	uicontrol('Parent',fig,	'Style','checkbox',	'String','Show strong roots',	'Units','normalized',	'Position',[ctrl_pos(1)+0.10 ctrl_pos(2)+ctrl_pos(4) 0.10 0.03],	'Value',cfg.show_strong_roots,	'Callback', @OnShowStrongRoots);
	ui_show_weak =	uicontrol('Parent',fig,	'Style','checkbox',	'String','Show weak roots',		'Units','normalized',	'Position',[ctrl_pos(1)+0.20 ctrl_pos(2)+ctrl_pos(4) 0.10 0.03],	'Value',cfg.show_weak_roots,	'Callback', @OnShowWeakRoots);
	
	pan('xon');
	zoom('xon');
	zoom('off');
	set(zoom,'ActionPostCallback',@OnZoomPan);
	set(pan ,'ActionPostCallback',@OnZoomPan);

	player = audioplayer(x, cfg.fs);
	set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
				'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	sig_pos=get(signal_subplot,'Position');
	spec_pos=get(spectrum_subplot,'Position');
	data.user_data = struct('cfg',cfg, 'player',player, 'frame_size',frame_size, 'frame_shift',frame_shift, ...
		'signal',x, 'signal_lim',signal_lim, 'spec_minmax',spec_minmax, ...
		'lsf_tracks',lsf_tracks, 'roots_strong_tracks',roots_strong_tracks, 'roots_weak_tracks',roots_weak_tracks, ...
		'signal_subplot',signal_subplot, 'spectrum_subplot',spectrum_subplot, 'btn_play',btn_play, ...
		'stat_rect',[spec_pos(1:2) sig_pos(1:2)+sig_pos(3:4)], 'stat_caret',stat_caret, 'stat_axes',stat_axes);
	guidata(fig,data);

	%% Current estimations display
	UpdateFrameStat(data, 0);
	
	if ~cfg.show_lsf
		OnShowLSF(ui_show_lsf);
	end
	if ~cfg.show_strong_roots
		OnShowStrongRoots(ui_show_strong);
	end
	if ~cfg.show_weak_roots
		OnShowWeakRoots(ui_show_weak);
	end
end

function plot_regions_str(reg, patch_clr, patch_transparency, border_clr, str)
	if nargin<2
		patch_clr=[1 0 1];
	end
	if nargin<3
		patch_transparency=0.3;
	end

	y_lim=ylim();
	z_pos=-0.1;
	pv=[0 y_lim(1) z_pos; 0 y_lim(2) z_pos; 1 y_lim(2) z_pos; 1 y_lim(1) z_pos];
	pc=[patch_clr;  patch_clr;  patch_clr;  patch_clr];
	pf=[1 2 3; 1 3 4];
	zlim([-1 0]);

	for i=1:size(reg,1)
		pv([1 2],1)=reg(i,1);
		pv([3 4],1)=reg(i,2);
		patch('Vertices',pv,'Faces',pf,'FaceVertexCData',pc,'FaceColor','flat','EdgeColor','none','FaceAlpha',patch_transparency);
		line(reg(i,[1 1 2 2 1]), y_lim([1 2 2 1 1]), 'Color',border_clr, 'LineWidth',1.5);
	end

	text(reg(:,1), max(ylim)+zeros(size(str)), str, 'Interpreter','none', 'HorizontalAlignment','left', 'VerticalAlignment','top');
end

function [region_pos, region_name]=safe_wav_regions_read(wav_file)
% Функция [region_pos, region_name]=safe_wav_regions_read(wav_file) предназначена для загрузки
%   регионов из .wav файла.
%   Параметры:
%       wav_file - имя файла, откуда будут загружены регионы;
%       region_pos - матрица Nx2 регионов [начало длинна] (в отсчетах начиная с 1).
%		region_name - cell имен регионов
%
%   See also WAV_REGIONS_WRITE.

%   Версия: 1.1
%   Автор: Давыдов А.Г. (18.05.2010)
	region_pos = zeros(0, 2);
	region_name= {};

	exe_path = which('WavRegionsExtractor.exe');
	if isempty(exe_path)
		return
	end
	txt_file=tempname();
	dos(['"' which('WavRegionsExtractor.exe') '" "' wav_file '" "' txt_file '" >nul']);
	[a b region_name]=textread(txt_file,'%d%d%s', 'whitespace','\t');
	region_pos=[a+1, b];
	delete(txt_file);
end


function UpdateFrameStat(data, x_pos)
	% Function for short-time estimations display

	%% Current frame selection
	stat_axes=data.user_data.stat_axes;
	cfg=data.user_data.cfg;

	x_pos = round(x_pos * cfg.fs + data.user_data.frame_size*[-0.5 0.5]);
	if x_pos(1)<1
		x_pos=[1 data.user_data.frame_size+1];
	end
	if x_pos(2)>data.user_data.player.TotalSamples
		x_pos=[max(1, data.user_data.player.TotalSamples-data.user_data.frame_size) data.user_data.player.TotalSamples];
	end

	%% Select current frame in plots
	stat_rg=[x_pos(1) x_pos(2)-1]/cfg.fs;
	for i=1:length(data.user_data.stat_caret)
		set(data.user_data.stat_caret(i), 'XData',stat_rg([1 1 2 2 1]));
	end

	%% Current frame analysis
	cur_frame=data.user_data.signal(x_pos(1):x_pos(2)-1);
	cur_frame=cur_frame.*window(cfg.window,length(cur_frame));

	if isfield(cfg,'preemphasis') && not(isequal(cfg.preemphasis,0)) && not(isequal(cfg.preemphasis,'none'))
		if isequal(cfg.preemphasis,'adaptive')
%			preemphasis_factor=sum(cur_frame(1:end-1).*cur_frame(2:end)) / sum(cur_frame.*cur_frame);
			preemphasis_factor=lpc(cur_frame,1);
			preemphasis_factor=-preemphasis_factor(2);
		else
			preemphasis_factor=cfg.preemphasis;
		end
		cur_frame=filter([1 -preemphasis_factor],1,cur_frame);
	end

	%% Current frame FFT spectrum
	NFFT=cfg.fft_size;
	if NFFT<length(cur_frame)
		NFFT=2^nextpow2(size(cur_frame,1));	
	end
	cur_fft=fft(cur_frame, NFFT);


	%% Real cepstrum noise estimation
	cur_rceps=ifft(20*log10(abs(cur_fft)));
	noise_rceps=cur_rceps;
	noise_rceps(cfg.T0(1):end-cfg.T0(1)+2)=0;
	noise_H=real(fft(noise_rceps));
	noise_H(fix(NFFT/2+2):end)=[];

	cur_fft(fix(NFFT/2+2):end)=[];
	fft_freq=linspace(0, cfg.fs/2, length(cur_fft));

	%% Current frame LPC spectrum
	[cur_a, cur_e_power]=lpc(cur_frame, cfg.lpc_order);
	if any(isnan(cur_a))
		cur_a=[1 zeros(1, cfg.lpc_order)];
	end
	if cur_e_power>0
		cur_a=cur_a./sqrt(cur_e_power*length(cur_frame));
	end

	%% Current frame FFT and LPC spectrum display
	[cur_H, cur_w]=freqz(1,cur_a,512);
	plot(stat_axes(1),	fft_freq,max(-2000,20*log10(abs(cur_fft))),'b', ...
						cur_w*cfg.fs/2/pi,20*log10(abs(cur_H)),'r', ...
						fft_freq,noise_H,'k');
	grid(stat_axes(1), 'on');	xlabel(stat_axes(1),'Frequency, Hz');	title(stat_axes(1),'Power spectrum, dB');
	legend(stat_axes(1), {'FFT spectrum','LPC envepole','Real cepstrum envepole'}, 'Location','SW');
	legend(stat_axes(1), 'boxoff');
	axis(stat_axes(1), [0 cfg.fs/2 data.user_data.spec_minmax]);

	%% Roots display
	cur_r=roots(cur_a);
	cur_r(imag(cur_r)<0)=[];
	hold(stat_axes(1),'on');
	y_lim=ylim(stat_axes(1));
	scatter(stat_axes(1), angle(cur_r)*cfg.fs/(2*pi), abs(cur_r)*(y_lim(2)-y_lim(1))+y_lim(1), 10+1./(1-abs(cur_r)), 'filled','MarkerEdgeColor','k', 'MarkerFaceColor',0.5+[0 0 0]);
	hold(stat_axes(1),'off');

	line([0 cfg.fs/2],cfg.roots_threshold*diff(y_lim)+y_lim(1)+[0 0], 'Parent',stat_axes(1), 'Color','c');
end

function OnShowStrongRoots(hObject, eventdata) %#ok<*INUSD>
	data = guidata(hObject);
	if get(hObject,'Value');
		is_show='on';
	else
		is_show='off';
	end
	set(data.user_data.roots_strong_tracks, 'Visible', is_show);
	zlim(data.user_data.spectrum_subplot, [-1 1]);
end

function OnShowWeakRoots(hObject, eventdata)
	data = guidata(hObject);
	if get(hObject,'Value');
		is_show='on';
	else
		is_show='off';
	end
	set(data.user_data.roots_weak_tracks, 'Visible', is_show);
	zlim(data.user_data.spectrum_subplot, [-1 1]);
end

function OnShowLSF(hObject, eventdata)
	data = guidata(hObject);
	if get(hObject,'Value');
		is_show='on';
	else
		is_show='off';
	end
	arrayfun(@(x) set(x,'Visible',is_show), data.user_data.lsf_tracks);
	zlim(data.user_data.spectrum_subplot, [-1 1]);
end

function OnPlaySignal(hObject, eventdata)
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples,max(1,round( xlim()*data.user_data.player.SampleRate+1 )));
		play(data.user_data.player, x_lim);
		set(data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(data.user_data.player);
	end
end

function CallbackPlay(obj, event, string_arg)
	user_data=get(obj, 'UserData');
	cur_pos=(get(obj, 'CurrentSample')-1)/get(obj, 'SampleRate');
	for i=1:length(user_data.caret)
		set(user_data.caret(i),'XData',[cur_pos cur_pos]);
	end
end

function CallbackPlayStop(obj, event, string_arg)
	CallbackPlay(obj);
	user_data=get(obj, 'UserData');
	set(user_data.btn_play, 'String', 'Play view');
end

function OnZoomPan(hObject, eventdata)
	data = guidata(hObject);
	zlim(data.user_data.spectrum_subplot, [-1 1]);

	if eventdata.Axes==data.user_data.signal_subplot || eventdata.Axes==data.user_data.spectrum_subplot
		x_lim=correct_range(xlim(), [0 data.user_data.player.TotalSamples/data.user_data.player.SampleRate]);
		set(data.user_data.signal_subplot, 'XLim',x_lim, 'YLim',data.user_data.signal_lim);
		set(data.user_data.spectrum_subplot, 'XLim',x_lim, 'YLim',[0 data.user_data.player.SampleRate/2]);
		return;
	end
	
	if any(eventdata.Axes==data.user_data.stat_axes)
		x_lim=correct_range(xlim(), [0 data.user_data.player.SampleRate/2]);
		set(eventdata.Axes, 'XLim',x_lim);
	end
	if any(eventdata.Axes==data.user_data.stat_axes(2:3))
		y_lim=correct_range(ylim(), [0 data.user_data.player.SampleRate/4]);
		set(eventdata.Axes, 'YLim',y_lim);
	end
end

function x_lim=correct_range(x_lim, x_range)
	rg=min(diff(x_lim), diff(x_range));
	if x_lim(1)<x_range(1)
		x_lim=x_range(1)+[0 rg];
	end
	if x_lim(2)>x_range(2)
		x_lim=x_range(2)-[rg 0];
	end
end

function OnMouseDown(hObject, eventdata)
	data = guidata(hObject);
	mouse_pos = get(hObject, 'CurrentPoint');
	
	if	mouse_pos(1)<data.user_data.stat_rect(1) || mouse_pos(1)>data.user_data.stat_rect(3) || ...
		mouse_pos(2)<data.user_data.stat_rect(2) || mouse_pos(2)>data.user_data.stat_rect(4)
		return
	end
	x_lim = get(data.user_data.signal_subplot, 'XLim');
	x_pos = (mouse_pos(1)-data.user_data.stat_rect(1))*diff(x_lim)/(data.user_data.stat_rect(3)-data.user_data.stat_rect(1))+x_lim(1);

	UpdateFrameStat(data, x_pos);
end

function OnKeyPress(hObject, eventdata)
	shift_steps=0;
	switch eventdata.Key
		case 'space'
			OnPlaySignal(hObject);
		case 'leftarrow'
			shift_steps=-1;
		case 'rightarrow'
			shift_steps=1;
		case 'pageup'
			shift_steps=-10;
		case 'pagedown'
			shift_steps=10;
		case 'home'
			shift_steps=-inf;
		case 'end'
			shift_steps=inf;
	end
	if any(strcmp(eventdata.Modifier,'shift'))
		shift_steps=shift_steps*5;
	end
	if any(strcmp(eventdata.Modifier,'control'))
		shift_steps=shift_steps*20;
	end
	if shift_steps
		data = guidata(hObject);
		stat_caret_x=get(data.user_data.stat_caret(1), 'XData');
		UpdateFrameStat(data, mean(stat_caret_x([2 3]))+data.user_data.frame_shift*shift_steps/data.user_data.player.SampleRate);
	end
end

function setcolormap(palette)
	if ischar(palette)
		palette=getcolormap(palette);
	end
	if isa(palette,'float') && size(palette,2)==4
		palette=makecolormap(palette);
	end
	colormap(palette);
end

function map=getcolormap(colormaptype)
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
end

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
end

function [cfg, press_OK]=settings_dlg(cfg)
	dlg.handle=dialog('Name','Настройки SignalView', 'Units','pixels', 'Position',get(0,'ScreenSize'));
	set(dlg.handle,'Units','characters');
	scr_sz=get(dlg.handle,'Position');
	dlg_width=80;
	dlg_height=30;
	set(dlg.handle,'Position',[round([(scr_sz(3)-dlg_width)/2 (scr_sz(4)-dlg_height)/2]) dlg_width dlg_height]);
	ui_text_pos=get(dlg.handle, 'Position');
	ui_text_pos=[1.5 ui_text_pos(4)-2 ui_text_pos(3)-3 1.2];

	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Путь к звуковому файлу',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_text_pos(2)=ui_text_pos(2)-1.5;

	ui_ctrl_pos=[ui_text_pos(1:3) 1.5];
	dlg.file_name=		uicontrol('Parent',dlg.handle,  'Style','edit',  'Units','characters',  'Position', [ui_ctrl_pos(1) ui_ctrl_pos(2) ui_ctrl_pos(3)-5 ui_ctrl_pos(4)],  'HorizontalAlignment','left',  'BackgroundColor','w');
	if isfield(cfg,'file_name')
		set(dlg.file_name, 'String',cfg.file_name);
	end
	dlg.file_name_btn=	uicontrol('Parent',dlg.handle,  'Style','pushbutton',  'String','...',  'Units','characters',  'Position', [ui_ctrl_pos(1)+ui_ctrl_pos(3)-4 ui_ctrl_pos(2) 4 ui_ctrl_pos(4)],  'Callback',@OnFileNameSel);
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	ui_ctrl_pos(3)=20;
	ui_text_pos=[22.5 ui_text_pos(2) ui_text_pos(3)-17 ui_text_pos(4)];

	dlg.fs=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.fs),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Частота дискретизации (Гц)',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.lpc_order=	uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.lpc_order),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Порядок фильтра предсказания',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.frame_size=		uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.frame_size),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Размер кадра анализа (с)',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.frame_shift=	uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.frame_shift),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Размер шага анализа (с)',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.fft_size=		uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.fft_size),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Число точек БПФ',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.preemphasis=	uicontrol('Parent',dlg.handle,  'Style','edit',  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	if isnumeric(cfg.preemphasis)
		set(dlg.preemphasis,'String',num2str(cfg.preemphasis));
	elseif ischar(cfg.preemphasis)
		set(dlg.preemphasis,'String',cfg.preemphasis);
	end
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Коэффициент предискажения',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	window_popup={'bartlett' 'barthannwin' 'blackman' 'blackmanharris' 'bohmanwin' 'chebwin' 'flattopwin' 'gausswin' 'hamming' 'hann' 'kaiser' 'nuttallwin' 'parzenwin' 'rectwin' 'taylorwin' 'tukeywin' 'triang'};
	dlg.window=		uicontrol('Parent',dlg.handle,  'Style','popupmenu',  'String',window_popup, 'Value',find(strcmp(cfg.window,window_popup)),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Оконная функция',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.F0=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.F0),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Диапазон частоты основного тона (Гц)',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	dlg.roots_threshold=uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.roots_threshold),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Порог амплитуды полюсов',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	display_spectrogram_popup={'fft' 'lpc'};
	dlg.display_spectrogram=uicontrol('Parent',dlg.handle,  'Style','popupmenu',  'String',display_spectrogram_popup, 'Value',find(strcmp(cfg.display_spectrogram,display_spectrogram_popup)),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Вид спектрограммы',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-2;
	ui_text_pos(2)=ui_text_pos(2)-2;

	display_palette_popup={'antigray' 'cool' 'fire' 'hot' 'hsl' 'jet' 'speech'};
	dlg.display_palette=uicontrol('Parent',dlg.handle,  'Style','popupmenu',  'String',display_palette_popup, 'Value',find(strcmp(cfg.display_palette,display_palette_popup)),  'Units','characters',  'Position', ui_ctrl_pos,  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Палитра спектрограммы',  'Units','characters',  'Position',ui_text_pos,  'HorizontalAlignment','left');
	ui_ctrl_pos(2)=ui_ctrl_pos(2)-4;


	ui_ctrl_pos=[ui_ctrl_pos(1:2) dlg_width-3 3];
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','(C) Давыдов Андрей (andrew.aka.manik@gmail.com)',  'Units','characters',  'Position',[ui_ctrl_pos(1) ui_ctrl_pos(2) ui_ctrl_pos(3)-38 ui_ctrl_pos(4)],	'HorizontalAlignment','left');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Версия 1.0.0.5 от 2012/08/02 22:31:34',			'Units','characters',  'Position',[ui_ctrl_pos(1) ui_ctrl_pos(2)-1.2 ui_ctrl_pos(3)-38 ui_ctrl_pos(4)-1],  'HorizontalAlignment','left');

	uicontrol('Parent',dlg.handle,  'Style','pushbutton',  'String','OK',	  'Units','characters',  'Position',[ui_ctrl_pos(1)+ui_ctrl_pos(3)-37 ui_ctrl_pos(2) 18 ui_ctrl_pos(4)],  'Callback',@OnSettingsDlgOK);
	uicontrol('Parent',dlg.handle,  'Style','pushbutton',  'String','Отмена',  'Units','characters',  'Position',[ui_ctrl_pos(1)+ui_ctrl_pos(3)-18 ui_ctrl_pos(2) 18 ui_ctrl_pos(4)],  'Callback',@OnSettingsDlgCancel);

	handles=guihandles(dlg.handle);
	handles.dlg=dlg;
	handles.cfg=cfg;
	handles.press_OK=0;
	guidata(dlg.handle,handles);
	uiwait(dlg.handle);
	try
		handles=guidata(dlg.handle);
	catch %#ok<CTCH>
		press_OK=0;
		return;
	end
	close(dlg.handle);
	pause(0.2);
	cfg=		handles.cfg;
	press_OK=   handles.press_OK;
end

function OnFileNameSel(hObject, eventdata)
	handles=guidata(hObject);
	[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки',get(handles.dlg.file_name,'String'));
	if dlg_name==0
		return;
	end
	set(handles.dlg.file_name,'String',fullfile(dlg_path,dlg_name));
end

function OnSettingsDlgOK(hObject, eventdata)
	handles=guidata(hObject);

	handles.cfg.file_name=			get(handles.dlg.file_name,'String');
	handles.cfg.fs=					str2double(get(handles.dlg.fs,'String'));
	handles.cfg.lpc_order=			round(str2double(get(handles.dlg.lpc_order,'String')));
	handles.cfg.frame_size=			str2double(get(handles.dlg.frame_size,'String'));
	handles.cfg.frame_shift=		str2double(get(handles.dlg.frame_shift,'String'));
	handles.cfg.fft_size=			round(str2double(get(handles.dlg.fft_size,'String')));

	val=get(handles.dlg.preemphasis,'String');
	if strcmp(val,'adaptive')
		handles.cfg.preemphasis=val;
	else
		handles.cfg.preemphasis=	str2double(val);
	end

	val=get(handles.dlg.window,'String');
	handles.cfg.window=val{get(handles.dlg.window,'Value')};

	handles.cfg.F0=					str2num(get(handles.dlg.F0,'String')); %#ok<ST2NM>
	handles.cfg.roots_threshold=	str2double(get(handles.dlg.roots_threshold,'String'));

	val=get(handles.dlg.display_spectrogram,'String');
	handles.cfg.display_spectrogram=	val{get(handles.dlg.display_spectrogram,'Value')};
	
	val=get(handles.dlg.display_palette,'String');
	handles.cfg.display_palette=	val{get(handles.dlg.display_palette,'Value')};
	
	handles.press_OK=1;
	guidata(hObject, handles);

	uiresume(handles.dlg.handle);
end

function OnSettingsDlgCancel(hObject, eventdata)
	handles=guidata(hObject);
	uiresume(handles.dlg.handle);
end
