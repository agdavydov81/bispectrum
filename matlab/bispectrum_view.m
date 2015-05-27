function bispectrum_view(cfg)
	if nargin<1
		cfg=struct('file_name','', 'frame_size',0.025, 'frame_shift',0.005, 'fft_size',1024, 'max_freq',[1500 750], ...
			'is_preemphasis',false, 'is_bispec_view_log',true, 'is_bispec_view_contour',false, ...
			'calc_obj','lpc_error' ... % 'fft' or 'lpc_error' or 'lpc_envelope'
		);

		cfg_file='bispectrum_view_cfg.mat';
		if exist(cfg_file,'file')
			load_cfg=load(cfg_file);
			load_cfg_fl=fieldnames(load_cfg.cfg);
			for i=1:length(load_cfg_fl)
				cfg.(load_cfg_fl{i})=load_cfg.cfg.(load_cfg_fl{i});
			end
		end

		[cfg, press_OK]=settings_dlg(cfg);
		if not(press_OK)
			return
		end

		save(cfg_file,'cfg');
	end

	%% Signal preparation
	[x,fs]=wavread(cfg.file_name);
	x(:,2:end)=[];
	
	if cfg.max_freq(1)<=0 || cfg.max_freq(1)>fs/2
		cfg.max_freq(1)=fs/2;
	end
	if cfg.max_freq(2)<=0 || cfg.max_freq(2)>fs/4
		cfg.max_freq(2)=fs/4;
	end

	if cfg.is_preemphasis
		x=fftfilt([1 -1],x);
	end

	frame.size=round(cfg.frame_size*fs);
	frame.shift=round(cfg.frame_shift*fs);

	%% Waveform display
	[fig_file_path,fig_file_name]=fileparts(cfg.file_name); %#ok<ASGLU>
	fig=figure(	'NumberTitle','off', 'Name',fig_file_name, 'ToolBar','figure', 'Units','normalized', ...
				'Position',[0 0 1 1], 'WindowButtonDownFcn',@OnMouseDown, 'KeyPressFcn',@OnKeyPress);

	signal_subplot=axes('Units','normalized', 'Position',[0.06 0.75 0.92 0.20]);
	plot((0:length(x)-1)/fs, x);
	x_lim=[0 length(x)-1]/fs;
	signal_lim=max(abs(x))*1.1*[-1 1];
	axis([x_lim signal_lim]);
	grid on;	ylabel('Oscillogram');
	title([cfg.file_name ' (frame_size=' num2str(cfg.frame_size) 's)'],'Interpreter','none');
	stat_ylim=ylim();
	stat_ylim=stat_ylim+0.01*diff(stat_ylim)*[1 -1];
	stat_caret=line(zeros(1,5), stat_ylim([1 2 2 1 1]), 'Color','k', 'LineWidth',1.5);
	caret=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

	%% Spectrogram display
	spectrum_subplot=axes('Units','normalized', 'Position',[0.06 0.52 0.92 0.20]);
	spec_fr_size=min(frame.size,size(x,1)-1);
	spec_fr_over=min(frame.size-frame.shift,spec_fr_size-1);
	if fix((size(x,1)-spec_fr_size)/(spec_fr_size-spec_fr_over)+1)<2
		spec_fr_over=spec_fr_size-1;
	end
	[sp_s, sp_f, sp_t]=spectrogram(x, spec_fr_size, spec_fr_over, 2^nextpow2(spec_fr_size), fs, 'yaxis');
	sp_s=20*log10(abs(sp_s));
	sp_s_max=max(max(sp_s));
	spec_minmax=[quantile(sp_s(:),0.05) sp_s_max+10];
	surf(sp_t,sp_f,sp_s,'EdgeColor','none');
	view(0,90);
	axis([x_lim 0 fs/2]);
	ylabel('Spectrogram, Hz');
	stat_ylim=ylim();
	stat_ylim=stat_ylim+0.01*diff(stat_ylim)*[1 -1];
	stat_caret(end+1)=line(zeros(1,5), stat_ylim([1 2 2 1 1]), sp_s_max+zeros(1,5), 'Color','k', 'LineWidth',1.5);
	caret(end+1)=line([0 0], ylim(), sp_s_max+[0 0], 'Color','r', 'LineWidth',2);

	stat_axes=[	axes('Units','normalized', 'Position',[0.06 0.10 0.28 0.36]) ...
				axes('Units','normalized', 'Position',[0.38 0.10 0.28 0.36]) ...
				axes('Units','normalized', 'Position',[0.70 0.10 0.28 0.36])];

	set(stat_axes(2),'XLim',[0 cfg.max_freq(1)], 'YLim',[0 cfg.max_freq(2)]);
	set(stat_axes(3),'XLim',[0 cfg.max_freq(1)], 'YLim',[0 cfg.max_freq(2)]);
	view(stat_axes(2), [0 90]);


	%% GUI setup
	ctrl_pos=get(signal_subplot,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);

	set(zoom,'ActionPostCallback',@OnZoomPan);
	set(pan ,'ActionPostCallback',@OnZoomPan);
%	zoom xon;	zoom off;
%	set(pan, 'Motion', 'horizontal');

	player = audioplayer(x, fs);
	set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
				'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	sig_pos=get(signal_subplot,'Position');
	spec_pos=get(spectrum_subplot,'Position');
	data.user_data = struct('cfg',cfg, 'player',player, 'frame',frame, 'signal',x, 'signal_lim',signal_lim, 'spec_minmax',spec_minmax, ...
		'signal_subplot',signal_subplot, 'spectrum_subplot',spectrum_subplot, 'btn_play',btn_play, ...
		'stat_rect',[spec_pos(1:2) sig_pos(1:2)+sig_pos(3:4)], 'stat_caret',stat_caret, 'stat_axes',stat_axes);
	guidata(fig,data);

	%% Current estimations display
	UpdateFrameStat(data, 0);

	pause(0.2);
	bispectrum_mean(x, fs, cfg, fig_file_name);
end

function bispectrum_mean(x, fs, cfg, fig_file_name)
	%% Mean bispectum calculation and display
	fr_sz=round([cfg.frame_shift cfg.frame_size]*fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);

	wait_fig=waitbar(0, 'Mean bispectrum calculation ...', 'Name',['Mean: ' fig_file_name], 'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
	setappdata(wait_fig,'canceling',0);
	wait_clk=clock();
	
	for i=1:fr_sz(1):size(x,1)-fr_sz(2)+1
		cur_x=x(i:i+fr_sz(2)-1);
		if exist('bispec_f1','var')
			bispec=bispec+analyse_frame(cur_x, fs, cfg);
		else
			[bispec, bispec_f1, bispec_f2]=analyse_frame(cur_x, fs, cfg);
		end

		wait_left=etime(clock(), wait_clk);
		x_left=i+fr_sz(1);
		left_time=wait_left*(size(x,1)-x_left)/x_left;
		left_time_s=rem(left_time,60);	left_time=fix(left_time/60);
		left_time_m=rem(left_time,60);	left_time_h=fix(left_time/60);
		if left_time_h>0
			left_time_str=sprintf('%dh ',left_time_h);
		else
			left_time_str=[];
		end
		if left_time_m>0
			left_time_str=[left_time_str sprintf('%dm ',left_time_m)]; %#ok<AGROW>
		end
		wait_msg=['Please wait ' left_time_str sprintf('%.0fs',left_time_s)];
		waitbar(x_left/size(x,1), wait_fig, wait_msg);
		if getappdata(wait_fig,'canceling')
			delete(wait_fig);
			return;
		end
	end
	bispec=bispec/obs_sz;
	delete(wait_fig);


	%% Mean bispecrum display
	figure(	'NumberTitle','off', 'Name',['Mean: ' fig_file_name], 'Units','normalized', 'Position',[0 0 1 1]);

	bispec_power=abs(bispec);
	nan_mask=isnan(bispec_power);
	if cfg.is_bispec_view_log && not(cfg.is_bispec_view_contour)
		bispec_power=20*log10(bispec_power);
	end
	bispec_power=max(-2000,bispec_power);
	bispec_power(nan_mask)=nan;

	subplot(2,1,1);
	if cfg.is_bispec_view_contour
		contour(bispec_f2, bispec_f1, bispec_power);
		line([0 fs/4 fs/2],[0 fs/4 0], 'Color','k');
	else
		surf(bispec_f2, bispec_f1, bispec_power, 'EdgeColor','none');
		view([0 90]);
	end
	axis([bispec_f2([1 end]) bispec_f1([1 end])]);
	grid('on');		xlabel('Frequency, Hz');	ylabel('Frequency, Hz');
	title(['Power of mean bispectrum ' cfg.file_name ' (frame_size=' num2str(cfg.frame_size) 's)'],'Interpreter','none');

	subplot(2,1,2);
	bispec_phase=angle(bispec);
	imagesc(bispec_f2, bispec_f1, bispec_phase, 'AlphaData',not(nan_mask));
	axis('xy');
	grid('on');		xlabel('Frequency, Hz');	ylabel('Frequency, Hz');
	title('Biphase of mean bispecrum');
end

function [bispec, bispec_f1, bispec_f2, cur_fft, cur_a]=analyse_frame(cur_frame, fs, cfg)
	cur_frame=cur_frame.*hamming(length(cur_frame));

	%% Prediction error analysis insted of signal analysis
	if strcmp(cfg.calc_obj,'lpc_error')
		tmp_ord=round(fs/1000)+2;
		tmp_a=aryule(cur_frame, tmp_ord);
		if all(not(isnan(tmp_a)))
			tmp_a_lin=ifftshift(ifft(abs(fft(tmp_a, round(tmp_ord*4)))));
			tmp_a_lin(1)=[];
%			tmp_a_lin=tmp_a_lin.*hamming(length(tmp_a_lin))';
			tmp_delay=(length(tmp_a_lin)-1)/2;
			cur_frame=filter(tmp_a_lin,1,[cur_frame; zeros(tmp_delay,1)]);
			cur_frame(1:tmp_delay)=[];
		end
	end

	if nargout>4 || strcmp(cfg.calc_obj,'lpc_envelope')
		%% Current frame LPC spectrum
		[cur_a, cur_e_power]=lpc(cur_frame, round(fs/1000)+2);
		if any(isnan(cur_a))
			cur_a(:)=0;
			cur_a(1)=1;
		end
		if cur_e_power>0
			cur_e_power=cur_e_power*length(cur_frame);
			cur_a=cur_a./sqrt(cur_e_power);
		end
	end

	NFFT=cfg.fft_size;
	if NFFT<length(cur_frame)
		NFFT=2^nextpow2(size(cur_frame,1));	
	end

	max_freq=cfg.max_freq([2 1])*2/fs;
	max_freq=min(max(0,max_freq),[0.5 1]);

	%% Current frame FFT spectrum
	cur_fft=fft(cur_frame, NFFT);
	cur_fft(fix(length(cur_fft)/2+2):end)=[];

	switch cfg.calc_obj
		case 'fft'
			bisp_obj=cur_fft;
		case 'lpc_error'
			bisp_obj=cur_fft;
		case 'lpc_envelope'
			bisp_obj=freqz(1, cur_a, NFFT/2);
	end

	%% Bispecrum calculation range
	max_freq=fix(max_freq*(length(cur_fft)-1))+1;
	bispec_f1=((1:max_freq(1))-1)*fs/2/(length(cur_fft)-1);
	bispec_f2=((1:max_freq(2))-1)*fs/2/(length(cur_fft)-1);

	%% Calculate bispectrum in given range
	bispec=zeros(max_freq(1), max_freq(2))/0;
	for i=1:size(bispec,1)
		ind=i:min(length(bisp_obj)-i+1,max_freq(2));
		bispec(i,ind)=bisp_obj(i)*bisp_obj(ind).*conj(bisp_obj(ind+i-1));
	end
end

function UpdateFrameStat(data, x_pos)
	% Function for short-time estimations display

	%% Current frame selection
	fs=data.user_data.player.SampleRate;
	stat_axes=data.user_data.stat_axes;

	x_pos = round(x_pos * fs + data.user_data.frame.size*[-0.5 0.5]);
	if x_pos(1)<1
		x_pos=[1 data.user_data.frame.size+1];
	end
	if x_pos(2)>data.user_data.player.TotalSamples
		x_pos=[max(1, data.user_data.player.TotalSamples-data.user_data.frame.size) data.user_data.player.TotalSamples];
	end

	%% Select current frame in plots
	stat_rg=[x_pos(1) x_pos(2)-1]/fs;
	for i=1:length(data.user_data.stat_caret)
		set(data.user_data.stat_caret(i), 'XData',stat_rg([1 1 2 2 1]));
	end

	%% Current frame bispectrum calculation
	cur_frame=data.user_data.signal(x_pos(1):x_pos(2)-1);
	[bispec, bispec_f1, bispec_f2, cur_fft, cur_a]=analyse_frame(cur_frame, fs, data.user_data.cfg);
	fft_freq=linspace(0, fs/2, length(cur_fft));

	%% Current frame FFT and LPC spectrum display
	[cur_H, cur_w]=freqz(1,cur_a,512);
	plot(stat_axes(1),	fft_freq,max(-2000,20*log10(abs(cur_fft))),'b', ...
						cur_w*fs/2/pi,20*log10(abs(cur_H)),'r');
	grid(stat_axes(1), 'on');	xlabel(stat_axes(1),'Frequency, Hz');	title(stat_axes(1),'Power spectrum, dB');
	legend(stat_axes(1), 'FFT','LPC', 'Location','NE');
	legend(stat_axes(1), 'boxoff');
	axis(stat_axes(1), [0 fs/2 data.user_data.spec_minmax]);

	%% Current frame bispecrum estimation display
	bispec_power=abs(bispec);
	bispec_phase=angle(bispec);
	nan_mask=isnan(bispec_power);
	if data.user_data.cfg.is_bispec_view_log && not(data.user_data.cfg.is_bispec_view_contour)
		bispec_power=20*log10(bispec_power);
	end
	bispec_power=max(-2000,bispec_power);
	bispec_power(nan_mask)=nan;

	x_lim=get(stat_axes(2),'XLim');		y_lim=get(stat_axes(2),'YLim');
	if data.user_data.cfg.is_bispec_view_contour
		contour(stat_axes(2), bispec_f2, bispec_f1, bispec_power);
		line([0 fs/4 fs/2],[0 fs/4 0], 'Color','k', 'Parent',stat_axes(2));
	else
		view_pt=get(stat_axes(2),'view');
		surf(bispec_f2, bispec_f1, bispec_power, 'Parent',stat_axes(2), 'EdgeColor','none');
		view(stat_axes(2), view_pt);
%		imagesc(bispec_f2, bispec_f1, bispec_power, 'AlphaData',not(isnan(bispec_power)), 'Parent',stat_axes(2));
%		axis(stat_axes(2), 'xy');
	end
	grid(stat_axes(2), 'on');	set(stat_axes(2), 'XLim',x_lim, 'YLim',y_lim);
	xlabel(stat_axes(2),'Frequency, Hz');
	title(stat_axes(2), 'Bispectrum, dB');

	x_lim=get(stat_axes(3),'XLim');		y_lim=get(stat_axes(3),'YLim');
	imagesc(bispec_f2, bispec_f1, bispec_phase, 'AlphaData',not(isnan(bispec_phase)), 'Parent',stat_axes(3));
	axis(stat_axes(3), 'xy');	grid(stat_axes(3), 'on');	set(stat_axes(3), 'XLim',x_lim, 'YLim',y_lim);
	xlabel(stat_axes(3),'Frequency, Hz');
	title(stat_axes(3), 'Biphase');
end

function OnPlaySignal(hObject, eventdata) %#ok<*INUSD>
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
	if eventdata.Axes==data.user_data.signal_subplot || eventdata.Axes==data.user_data.spectrum_subplot
		x_lim=correct_range(xlim(), [0 data.user_data.player.TotalSamples/data.user_data.player.SampleRate]);
		set(data.user_data.signal_subplot, 'XLim',x_lim, 'YLim',data.user_data.signal_lim);
		set(data.user_data.spectrum_subplot, 'XLim',x_lim, 'YLim',[0 data.user_data.player.SampleRate/2]);
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
		UpdateFrameStat(data, mean(stat_caret_x([2 3]))+data.user_data.frame.shift*shift_steps/data.user_data.player.SampleRate);
	end
end

function [cfg, press_OK]=settings_dlg(cfg)
	dlg.handle=dialog('Name','Settings', 'Units','pixels', 'Position',get(0,'ScreenSize'));
	set(dlg.handle,'Units','characters');
	scr_sz=get(dlg.handle,'Position');
	dlg_width=80;
	dlg_height=27;
	set(dlg.handle, 'Units','characters', 'Position',[round([(scr_sz(3)-dlg_width)/2 (scr_sz(4)-dlg_height)/2]) dlg_width dlg_height]);
	ctrl_pos=get(dlg.handle, 'Position');
	ctrl_pos=[1.5 ctrl_pos(4)-2 ctrl_pos(3)-3 1.2   12 1.5];
	ctrl_pos=[ctrl_pos  ctrl_pos(5)+2.5 ctrl_pos(3)-(ctrl_pos(5)+2) 1.2];

	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Path to sound file',  'Units','characters',  'Position',ctrl_pos(1:4),  'HorizontalAlignment','left');
	ctrl_pos(2)=ctrl_pos(2)-1.6;

	dlg.file_name=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',cfg.file_name,  'Units','characters',  'Position', [ctrl_pos(1) ctrl_pos(2) ctrl_pos(3)-5 ctrl_pos(6)],  'HorizontalAlignment','left',  'BackgroundColor','w');
	dlg.file_name_btn=		uicontrol('Parent',dlg.handle,  'Style','pushbutton',  'String','...',  'Units','characters',  'Position', [ctrl_pos(1)+ctrl_pos(3)-4 ctrl_pos(2) 4 ctrl_pos(6)],  'Callback',@OnFileNameSel);
	ctrl_pos(2)=ctrl_pos(2)-2.1;

	dlg.frame_size=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.frame_size),  'Units','characters',  'Position', ctrl_pos([1 2 5 6]),  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Frame size (s)',  'Units','characters',  'Position',ctrl_pos([7 2 8 9]),  'HorizontalAlignment','left');
	ctrl_pos(2)=ctrl_pos(2)-2.1;

	dlg.frame_shift=		uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.frame_shift),  'Units','characters',  'Position', ctrl_pos([1 2 5 6]),  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Frame shift (s)',  'Units','characters',  'Position',ctrl_pos([7 2 8 9]),  'HorizontalAlignment','left');
	ctrl_pos(2)=ctrl_pos(2)-2.1;

	dlg.fft_size=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.fft_size),  'Units','characters',  'Position', ctrl_pos([1 2 5 6]),  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','FFT size',  'Units','characters',  'Position',ctrl_pos([7 2 8 9]),  'HorizontalAlignment','left');
	ctrl_pos(2)=ctrl_pos(2)-2.1;

	dlg.max_freq1=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.max_freq(1)),  'Units','characters',  'Position', ctrl_pos([1 2 5 6]),  'HorizontalAlignment','right',  'BackgroundColor','w');
	dlg.max_freq2=			uicontrol('Parent',dlg.handle,  'Style','edit',  'String',num2str(cfg.max_freq(2)),  'Units','characters',  'Position', [sum(ctrl_pos([1 5]))+1 ctrl_pos([2 5 6])],  'HorizontalAlignment','right',  'BackgroundColor','w');
	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Bispectrum frequency range (Hz)',  'Units','characters',  'Position',[sum(ctrl_pos([7 5]))+1 ctrl_pos(2) ctrl_pos(8)-ctrl_pos(5)-1 ctrl_pos(9)],  'HorizontalAlignment','left');
	ctrl_pos(2)=ctrl_pos(2)-2.1;

	dlg.is_preemphasis=		uicontrol('Parent',dlg.handle,  'Style','checkbox',  'String','Preemphasis',  'Units','characters',  'Position',ctrl_pos(1:4),  'Value',cfg.is_preemphasis);
	ctrl_pos(2)=ctrl_pos(2)-1.6;

	dlg.calc_obj_grp=		uibuttongroup('Parent',dlg.handle, 'Units','characters', 'Position',[ctrl_pos(1) ctrl_pos(2)-4 ctrl_pos(3) 5]);
	radio_pos=[1.2 3.2 ctrl_pos(3)-2*ctrl_pos(1) ctrl_pos(4)];
	dlg.is_calc_fft=		uicontrol('Parent',dlg.calc_obj_grp, 'Style','Radio', 'String','Signal analysis', 'Units','characters', 'Position',radio_pos);
	radio_pos(2)=radio_pos(2)-1.4;
	dlg.is_calc_lpc_err=	uicontrol('Parent',dlg.calc_obj_grp, 'Style','Radio', 'String','LPC prediction error analysis', 'Units','characters', 'Position',radio_pos);
	radio_pos(2)=radio_pos(2)-1.4;
	dlg.is_calc_lpc_env=	uicontrol('Parent',dlg.calc_obj_grp, 'Style','Radio', 'String','Spectrum envelope analysis', 'Units','characters', 'Position',radio_pos);
	switch(cfg.calc_obj)
		case 'fft'
			set(dlg.calc_obj_grp,'SelectedObject',dlg.is_calc_fft);
		case 'lpc_error'
			set(dlg.calc_obj_grp,'SelectedObject',dlg.is_calc_lpc_err);
		case 'lpc_envelope'
			set(dlg.calc_obj_grp,'SelectedObject',dlg.is_calc_lpc_env);
	end

	ctrl_pos(2)=ctrl_pos(2)-5.8;

	dlg.is_bispec_view_log=	uicontrol('Parent',dlg.handle,  'Style','checkbox',  'String','Display bispectrum in dB',  'Units','characters',  'Position',ctrl_pos(1:4),  'Value',cfg.is_bispec_view_log);
	ctrl_pos(2)=ctrl_pos(2)-2.1;

	dlg.is_bispec_view_contour=uicontrol('Parent',dlg.handle,  'Style','checkbox',  'String','Bispectrum contour display',  'Units','characters',  'Position',ctrl_pos(1:4),  'Value',cfg.is_bispec_view_contour);
	ctrl_pos(2)=ctrl_pos(2)-2.8;

	uicontrol('Parent',dlg.handle,  'Style','text',  'String','Version 1.0.0.7(en) 2011/03/18',  'Units','characters',  'Position',[ctrl_pos(1) ctrl_pos(2) ctrl_pos(3)-38 ctrl_pos(4)],  'HorizontalAlignment','left');
	uicontrol('Parent',dlg.handle,  'Style','pushbutton',  'String','OK',      'Units','characters',  'Position',[ctrl_pos(1)+ctrl_pos(3)-37 ctrl_pos(2) 18 2],  'Callback',@OnSettingsDlgOK);
	uicontrol('Parent',dlg.handle,  'Style','pushbutton',  'String','Cancel',  'Units','characters',  'Position',[ctrl_pos(1)+ctrl_pos(3)-18 ctrl_pos(2) 18 2],  'Callback',@OnSettingsDlgCancel);

	handles=guihandles(dlg.handle);
	handles.user_data.dlg=dlg;
	handles.user_data.cfg=cfg;
	handles.user_data.press_OK=false;
	guidata(dlg.handle,handles);
	uiwait(dlg.handle);
	try
		handles=guidata(dlg.handle);
	catch %#ok<CTCH>
		press_OK=false;
		return;
	end
	close(dlg.handle);
	pause(0.2);
	cfg=		handles.user_data.cfg;
	press_OK=	handles.user_data.press_OK;
end

function OnFileNameSel(hObject, eventdata)
	handles=guidata(hObject);
	[file_name,file_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Select file ...',get(handles.user_data.dlg.file_name,'String'));
	if file_name==0
		return;
	end
	set(handles.user_data.dlg.file_name,'String',fullfile(file_path,file_name));
end

function OnSettingsDlgOK(hObject, eventdata)
	handles=guidata(hObject);
	
	dlg=handles.user_data.dlg;

	cfg.file_name=				get(dlg.file_name,'String');
	cfg.frame_size=				str2double(get(dlg.frame_size,'String'));
	cfg.frame_shift=			str2double(get(dlg.frame_shift,'String'));
	cfg.fft_size=				str2double(get(dlg.fft_size,'String'));
	cfg.fft_size(isnan(cfg.fft_size) | isinf(cfg.fft_size))=0;
	cfg.max_freq=			[	str2double(get(dlg.max_freq1,'String')), ...
								str2double(get(dlg.max_freq2,'String'))	];
	cfg.max_freq(isnan(cfg.max_freq) | isinf(cfg.max_freq))=0;

	cfg.is_preemphasis=			get(dlg.is_preemphasis,'Value');

	calc_obj_hndl=				[dlg.is_calc_fft  dlg.is_calc_lpc_err  dlg.is_calc_lpc_env];
	calc_obj_name=				{'fft'            'lpc_error'          'lpc_envelope'};
	cfg.calc_obj=				calc_obj_name{get(dlg.calc_obj_grp,'SelectedObject')==calc_obj_hndl};

	cfg.is_bispec_view_log=		get(dlg.is_bispec_view_log,'Value');
	cfg.is_bispec_view_contour=	get(dlg.is_bispec_view_contour,'Value');

	handles.user_data.cfg=cfg;

	handles.user_data.press_OK=true;
	guidata(hObject, handles);

	uiresume(handles.user_data.dlg.handle);
end

function OnSettingsDlgCancel(hObject, eventdata)
	handles=guidata(hObject);
	uiresume(handles.user_data.dlg.handle);
end
