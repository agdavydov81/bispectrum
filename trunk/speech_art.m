function speech_art()
	scr_sz = get(0,'ScreenSize');
	axis_sz = 400;
	fig_sz = [0 0 40+axis_sz+40+axis_sz+10, 40+axis_sz+10];
	fig_sz([1 2])=fix((scr_sz([3 4])-fig_sz([3 4]))/2);
	fig = figure('NumberTitle','off', 'Toolbar','none', 'Name','SpeechArt', 'Units','pixels', 'Position',fig_sz, 'UserData',false, 'KeyPressFcn',@(obj,evt) set(obj,'UserData',true));

	ax_spectrum = axes('Parent',fig, 'Units','pixels', 'Position',[40 40 axis_sz axis_sz]);
	ax_art = axes('Parent',fig, 'Units','pixels', 'Position',[40+axis_sz+40 40 axis_sz axis_sz]);

	signal.sample_rate = 11025;
	signal.frame_size = round(0.040*signal.sample_rate);
	signal.FFT_N = pow2(2+nextpow2(signal.frame_size));
	signal.band = round([300 4000]*signal.FFT_N/signal.sample_rate);
	signal.power_rg = [-40 20];
	signal.rceps = round(0.004*signal.sample_rate);
	signal.lpc_order = round(signal.sample_rate/1000+4);
	signal.snale_length = 100;

	hold(ax_spectrum, 'on');
	gui.fft_hndl =   plot(ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1));
	gui.rceps_hndl = plot(ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1), 'm');
	gui.lpc_hndl =   plot(ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1), 'r');
	for li=1:signal.lpc_order
		gui.lsf_hndl(li) = line('Parent',ax_spectrum, 'XData',[0 0],'YData',[-60 20], 'Color','r');
	end
	axis(ax_spectrum, [0 signal.sample_rate/2 -60 20]);

	hold(ax_art, 'on');
	gui.snake_hndl = scatter(ax_art, -ones(1,signal.snale_length), -ones(1,signal.snale_length), ones(1,signal.snale_length), [1 0 0]);
	gui.snake_head_hndl = scatter(ax_art, -1, -1, 1, [0 0 1], 'filled');
	axis(ax_art, [0 pi/2 0 pi/2]);

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
		cur_frame = filter([1 -0.97],1,cur_frame);

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
		
		% LSF lines
		for li=1:signal.lpc_order
			set(gui.lsf_hndl(li), 'XData',cur_lsf(li)*signal.sample_rate/2/pi+[0 0]);
		end
		
		% Draw snake
		snake_head_x = get(gui.snake_head_hndl, 'XData');
		snake_head_y = get(gui.snake_head_hndl, 'YData');
		snake_head_s = get(gui.snake_head_hndl, 'SizeData');
		snake_x = get(gui.snake_hndl, 'XData');
		snake_y = get(gui.snake_hndl, 'YData');
		snake_s = get(gui.snake_hndl, 'SizeData');
		cur_s = realmin+(20*(cur_power-signal.power_rg(1))/(signal.power_rg(2)-signal.power_rg(1)))^2;
		set(gui.snake_hndl, 'XData',[snake_x(2:end) snake_head_x], 'YData',[snake_y(2:end) snake_head_y], 'SizeData',[snake_s(2:end) snake_head_s]);
		set(gui.snake_head_hndl, 'XData',cur_lsf(3), 'YData',cur_lsf(5), 'SizeData',cur_s);

		% Draw image
		pause(0.000001);
		frames=frames+1;
	end
	elapsedTime = toc;
	fprintf('Average fps: %f\n',frames/elapsedTime);

	stop(recorder);
	delete(recorder);
end
