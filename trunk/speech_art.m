function speech_art()
	scr_sz = get(0,'ScreenSize');
	axis_sz = 400;
	fig_sz = [0 0 40+axis_sz+40+axis_sz+10, 40+axis_sz+10];
	fig_sz([1 2])=fix((scr_sz([3 4])-fig_sz([3 4]))/2);
	fig = figure('NumberTitle','off', 'Toolbar','none', 'Name','SpeechArt', 'Units','pixels', 'Position',fig_sz, 'UserData',false, 'KeyPressFcn',@(obj,evt) set(obj,'UserData',true));

	ax_spectrum = axes('Parent',fig, 'Units','pixels', 'Position',[40 40 axis_sz axis_sz]);
	ax_art = axes('Parent',fig, 'Units','pixels', 'Position',[40+axis_sz+40 40 axis_sz axis_sz]);

	signal.sample_rate = 11025;
	signal.frame_size = round(0.030*signal.sample_rate);
	signal.FFT_N = pow2(2+nextpow2(signal.frame_size));
	signal.band = round([300 4000]*signal.FFT_N/signal.sample_rate);
	signal.power_rg = [-40 20];
	signal.rceps = round(0.004*signal.sample_rate);
	signal.lpc_order = round(signal.sample_rate/1000+4);
	signal.snake_length = 100;

	hold(ax_spectrum, 'on');
	gui.fft_hndl =   plot(ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1));
	gui.rceps_hndl = plot(ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1), 'm', 'LineWidth',2);
	gui.lpc_hndl =   plot(ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1), 'r', 'LineWidth',2);
	axis(ax_spectrum, [0 signal.sample_rate/2 -60 20]);

	hold(ax_art, 'on');
	gui.snake_hndl = scatter(ax_art, -ones(1,signal.snake_length), -ones(1,signal.snake_length), ones(1,signal.snake_length), [1 0 0]);
	gui.snake_head_hndl = scatter(ax_art, -1, -1, 1, [0 0 1], 'filled');
	axis(ax_art, [0.1 0.6 0.5 1.4]);

	fill([0.354 0.600 0.600 0.352 0.321 0.279 0.284], ...
		 [0.817 1.023 1.400 1.400 1.269 0.990 0.901],[0 0.5 0],'EdgeColor','none', 'FaceAlpha',0.5);
	text(0.4413, 1.1398, '�');
	fill([0.354 0.600 0.600 0.377 0.363], ...
		 [0.817 1.023 0.500 0.500 0.651],[0.5 0 0],'EdgeColor','none', 'FaceAlpha',0.5);
	text(0.4905, 0.7188, '�');
	fill([0.284 0.354 0.363 0.377 0.234 0.239 0.248 0.258 0.270], ...
		 [0.901 0.817 0.651 0.500 0.500 0.593 0.686 0.763 0.837],[0 0 0.5],'EdgeColor','none', 'FaceAlpha',0.5);
	text(0.3037, 0.6622, '�');
	fill([0.100 0.234 0.239 0.248 0.258 0.270 0.284 0.279 0.229 0.190 0.156 0.126 0.100], ...
		 [0.500 0.500 0.593 0.686 0.763 0.837 0.901 0.990 0.937 0.888 0.842 0.796 0.741],[1 1 0],'EdgeColor','none', 'FaceAlpha',0.5);
	text(0.1843, 0.7202, '�');
	fill([0.352 0.321 0.279 0.229 0.190 0.156 0.126 0.100 0.100 0.130 0.159 0.183 0.202 0.215 0.225 0.229 0.231 0.231 0.229 0.225 0.219 0.210 0.197 0.179], ...
		 [1.400 1.269 0.990 0.937 0.888 0.842 0.796 0.741 0.889 0.920 0.960 0.997 1.035 1.072 1.116 1.146 1.175 1.197 1.225 1.255 1.286 1.320 1.357 1.400],[0 0.5 1],'EdgeColor','none', 'FaceAlpha',0.5);
	text(0.260, 1.250, '�');
	fill([0.100 0.130 0.159 0.183 0.202 0.215 0.225 0.229 0.231 0.231 0.229 0.225 0.219 0.210 0.197 0.179 0.100], ...
		 [0.889 0.920 0.960 0.997 1.035 1.072 1.116 1.146 1.175 1.197 1.225 1.255 1.286 1.320 1.357 1.400 1.400],[1 0 0.5],'EdgeColor','none', 'FaceAlpha',0.5);
	text(0.1564, 1.1871, '�');
	
	set(ax_spectrum, 'Units','normalized');
	set(ax_art, 'Units','normalized');

	win = hamming(signal.frame_size);

	recorder=audiorecorder(signal.sample_rate,16,1);
	record(recorder);

	frames = 0;
	tic;
	while ishandle(fig) && ~get(fig,'UserData')
		if recorder.TotalSamples>recorder.SampleRate*30
			stop(recorder); % Clear audio recorder buffer
			record(recorder);
		end
		if recorder.TotalSamples<signal.frame_size
			pause(0.001);
			continue
		end
		
		cur_frame = getaudiodata(recorder);
		cur_frame(1:end-signal.frame_size)=[];

		% Preemphasis
%		cur_frame = filter([1 -1],1,cur_frame);
		% Adaptive preemphasis
		cur_frame = filter(lpc(cur_frame,1),1,cur_frame);

		% Windowing
		cur_frame = cur_frame.*win;

		% FFT spectrum
		cur_fx = fft(cur_frame, signal.FFT_N);
		cur_fx(signal.FFT_N/2+2:end)=[];
		cur_fx = cur_fx.*conj(cur_fx);
				
		cur_power = mean(cur_fx(signal.band(1):signal.band(2))); % Signal power in speech band
		cur_power = 10*log10(cur_power);
		cur_power = min(signal.power_rg(2),max(signal.power_rg(1),cur_power));

		cur_fx = 10*log10(cur_fx);

		set(gui.fft_hndl, 'YData', cur_fx);
		
		% Real cepstrum
		cur_rceps=ifft([cur_fx; cur_fx(end-1:-1:2)]);
		cur_rceps(signal.rceps:end-signal.rceps+2)=0;
		cur_rceps_H=real(fft(cur_rceps));
		cur_rceps_H(length(cur_rceps_H)/2+2:end)=[];

		set(gui.rceps_hndl, 'YData', cur_rceps_H);

		% LPC spectrum
		[cur_a, cur_err_pwr] = lpc(cur_frame, signal.lpc_order);
		if any(isnan(cur_a))
			cur_a=[1 zeros(1, signal.lpc_order)];
		end
		cur_lsf = poly2lsf(cur_a);
		if cur_err_pwr>0
			cur_a=cur_a./sqrt(cur_err_pwr*signal.frame_size);
		end
		cur_lpc_H = 1./fft(cur_a,signal.FFT_N);
		cur_lpc_H(signal.FFT_N/2+2:end)=[];

		set(gui.lpc_hndl, 'YData', 10*log10(cur_lpc_H.*conj(cur_lpc_H)));
		
		% Draw snake
		snake_head_x = get(gui.snake_head_hndl, 'XData');
		snake_head_y = get(gui.snake_head_hndl, 'YData');
		snake_head_s = get(gui.snake_head_hndl, 'SizeData');
		snake_x = get(gui.snake_hndl, 'XData');
		snake_y = get(gui.snake_hndl, 'YData');
		snake_s = get(gui.snake_hndl, 'SizeData');
		cur_s = realmin+(20*(cur_power-signal.power_rg(1))/(signal.power_rg(2)-signal.power_rg(1)))^2;
		set(gui.snake_hndl, 'XData',[snake_x(2:end) snake_head_x], 'YData',[snake_y(2:end) snake_head_y], 'SizeData',[snake_s(2:end) snake_head_s]);
		set(gui.snake_head_hndl, 'XData',cur_lsf(2), 'YData',cur_lsf(5), 'SizeData',cur_s);

		% Draw image
		pause(0.000001);
		frames=frames+1;
	end
	elapsedTime = toc;
	fprintf('Average fps: %f\n',frames/elapsedTime);

	stop(recorder);
	delete(recorder);
end
