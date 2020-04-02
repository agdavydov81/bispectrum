function [harm_phi, f0_freq, harm_x, harm_fs, harm_t]=phase_analysis(x, fs, alg)
	if nargin<2
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		file_name=fullfile(dlg_path,dlg_name);
		if exist('audioread','file') == 2
			[x,fs] = audioread(file_name);
		else
			[x,fs] = wavread(file_name);
		end
	end
	if size(x,2)>1
		warning('phase_analysis:signaldimension','Поддерживаются только моно записи. Дополнительны каналы будут проигнорированы.');
		x(:,2:end)=[];
	end

	if nargin<3
		alg.pitch=struct('frame_size',0.040, 'frame_shift',0.001, 'pitch_mul',[0.8 0.9 1 1.1 1.2], 'fine_side_band',35);
		alg.phase=struct('mul',[2 4 5], 'filt',struct('type','azarov', 'frame_size',0.040, 'frame_shift',0.001, 'side_band',35) ); % 'type' can be 'firls' or 'azarov'
	end

	f0_freq=get_fine_pitch(x, fs, alg);

	[harm_phi, harm_x, harm_fs, harm_t]=get_phase(x, fs, f0_freq, alg);
end

function [phs_phi, phs_x, harm_fs, harm_t]=get_phase(x, fs, f0_freq, alg)
%	phs_phi - графики полной фазы каждой выделяемой гармоники
%	phs_x   - графики каждой выделяемой гармоники
%	fs_out  - частота дискретизации выделямых phs_phi и phs_x

	ord2=round(alg.phase.filt.frame_size*fs/2);
	ord=ord2*2+1;
	side_band=alg.phase.filt.side_band;

	frame_shift=round(alg.phase.filt.frame_shift*fs);
	frame_shift=min(frame_shift, floor(fs/(4*(max(f0_freq)*max(alg.phase.mul)+side_band))));
	frame_shift=max(frame_shift, 1);
%	dphi_max=max(f0_freq)*max(alg.phase.mul)*2*pi/fs;
%	frame_shift=max(1,min(frame_shift, fix(3*pi/(2*dphi_max))));  % @WTF?
	harm_fs=fs/frame_shift;
	
	out_sz=ceil(size(x,1)/frame_shift);
	harm_t=(ord/2+(0:out_sz-1)'*frame_shift)/fs;

	x=[zeros(ord2,1); x; zeros(ord2,1)];
	f0_freq_buf=[f0_freq(1)+zeros(ord2,1); f0_freq; f0_freq(end)+zeros(ord2,1)];

	[x_buf,tmp]=buffer(x, ord, ord-frame_shift, 'nodelay'); %#ok<NASGU>
	[f0_freq_buf,tmp]=buffer(f0_freq_buf, ord, ord-frame_shift, 'nodelay'); %#ok<NASGU>
	harm_f0=f0_freq_buf(ord2+1,:);
	harm_f0=harm_f0(:);

	nan_ind=any(isnan(f0_freq_buf));
	f0_freq_buf(:,nan_ind)=[];
	x_buf(:,nan_ind)=[];
	if isempty(x_buf)
		phs_phi = [];
		phs_x = [];
		return
	end

	alg_phase_mul_pf=alg.phase.mul;
	alg_phase_filt_type=alg.phase.filt.type;
	phs_x_c=cell(size(x_buf,2),1);
	phs_phi_c=cell(size(x_buf,2),1);
	parfor ii=1:size(x_buf,2) % parfor
		cur_x=x_buf(:,ii);
		cur_f0=f0_freq_buf(:,ii);
		phs_x_pf=zeros(1,numel(alg_phase_mul_pf));
		phs_phi_pf=zeros(1,numel(alg_phase_mul_pf));
		for ch=1:numel(alg_phase_mul_pf)
			switch alg_phase_filt_type
				case 'firls'  %% untested
					f_center=alg_phase_mul_pf(ch)*cur_f0(ord2+1);
					b=firls(ord-1, [0 f_center-side_band f_center-side_band f_center+side_band f_center+side_band fs/2]/(fs/2), [0 0 1 1 0 0]);
					phs_x_pf(ch)=b*cur_x;
				case 'azarov'
					[cur_A, cur_F, cur_P]=TakeHParamsXflc(cur_x', alg_phase_mul_pf(ch)*cur_f0, side_band, 1/fs, 0);
					phs_phi_pf(ch)=cur_P;
					phs_x_pf(ch)=cur_A*cos(cur_P);
				otherwise
					error('phase_analysis:get_phase', 'Unsupported filter type');
			end
		end
		phs_phi_c{ii}=phs_phi_pf;
		phs_x_c{ii}=phs_x_pf;
	end
	phs_x=nan(out_sz, size(phs_x_c{1},2));
	phs_x(not(nan_ind),:)=cell2mat(phs_x_c);

	notnan_ind=not(any(isnan(phs_x),2));
	notnan_diff=diff([false; notnan_ind; false]);
	voiced_reg=[find(notnan_diff==1) find(notnan_diff==-1)-1];

	phs_phi=nan(size(phs_x));
	switch alg.phase.filt.type
		case 'firls'
			y_cell=cell(size(voiced_reg,1),1);
			for vi=1:size(voiced_reg,1)
				y_cell{vi}=angle(hilbert(phs_x(voiced_reg(vi,1):voiced_reg(vi,2),:)));
			end
			phs_phi(notnan_ind,:)=cell2mat(y_cell);
		case 'azarov'
			phs_phi(not(nan_ind),:)=cell2mat(phs_phi_c);
	end

	% nonstandart unwrapt
	for vi=1:size(voiced_reg,1)
		v_ind=voiced_reg(vi,1):voiced_reg(vi,2);
		dphi_rg=[min(harm_f0(v_ind))-side_band max(harm_f0(v_ind))+side_band]*2*pi/harm_fs;
		dphi_rg(3)=mean(dphi_rg);

		f0_phi=cumtrapz(harm_t(v_ind),harm_f0(v_ind))*2*pi;
		f0_phi=f0_phi-f0_phi(1);

		for ch=1:size(phs_phi,2)
			cur_f0_phi=f0_phi*alg.phase.mul(ch)+phs_phi(voiced_reg(vi,1),ch);
			cur_dphi_rg=dphi_rg*alg.phase.mul(ch);
			for ii=voiced_reg(vi,1)+1:voiced_reg(vi,2)
				f0_ii=ii-voiced_reg(vi,1)+1;
				dp=phs_phi(ii,ch)-phs_phi(ii-1,ch);
				if cur_dphi_rg(1)<dp && dp<cur_dphi_rg(2) % && abs(cur_f0_phi(f0_ii)-phs_phi(ii,ch))<cur_dphi_rg(2)
					cur_f0_phi(f0_ii:end)=cur_f0_phi(f0_ii:end)-cur_f0_phi(f0_ii)+phs_phi(ii,ch);
					continue;
				end
				dd=cur_f0_phi(f0_ii)-phs_phi(ii,ch);
				phs_phi(ii:voiced_reg(vi,2),ch)=phs_phi(ii:voiced_reg(vi,2),ch)+round(dd/(2*pi))*2*pi;
			end
		end
	end
end

function f0_fine=get_fine_pitch(x, fs, alg)
	f0_freq=get_raw_pitch(x,fs);

	fr_shift=max(1, round(alg.pitch.frame_shift*fs) );
	fr_size=round( round(alg.pitch.frame_size*fs)/2)*2+1;

	pitch_mul=alg.pitch.pitch_mul;
	alg_pitch_fine_side_band=alg.pitch.fine_side_band;
	[x_buf,tmp]=buffer(x, fr_size, fr_size-fr_shift, 'nodelay');
	[f0_freq_buf,tmp]=buffer(f0_freq, fr_size, fr_size-fr_shift, 'nodelay');
	f0_fine_ind=(0:size(x_buf,2)-1)'*fr_shift+1 + fix((fr_size-1)/2);

	nan_ind=any(isnan(f0_freq_buf));
	x_buf(:,nan_ind)=[];
	f0_freq_buf(:,nan_ind)=[];

	f0_fine=nan(size(x_buf,2),1);
	parfor i=1:size(x_buf,2) % parfor
		cur_x=x_buf(:,i).*hamming(fr_size);
		cur_f0_freq=f0_freq_buf(:,i);

		A=zeros(numel(pitch_mul),1);
		for tm_i=1:numel(pitch_mul)
			A(tm_i)=TakeHParamsXflc(cur_x', pitch_mul(tm_i)*cur_f0_freq, alg_pitch_fine_side_band, 1/fs, 0);
		end
		mm=findmaxval(pitch_mul, A);

		[tmp1,f0_fine(i),tmp3]=TakeHParamsXflc(cur_x', mm*cur_f0_freq, alg_pitch_fine_side_band, 1/fs, 0);
	end

	f0_fine_out=nan(size(f0_fine_ind));
	f0_fine_out(not(nan_ind))=f0_fine;

	f0_fine=interp1q([0; f0_fine_ind; size(x,1)+1], [f0_fine_out(1); f0_fine_out; f0_fine_out(end)], (1:size(x,1))');
end

function r=findmaxval(x,y)
	x=x(:);
	y=y(:);

	pA=ones(length(x));
	pA(:,end-1)=x;
	for pi=size(pA)-2:-1:1
		pA(:,pi)=pA(:,pi+1).*x;
	end
	pp=pA\y;

	pd=polyder(pp);
	pr=roots(pd);

	pr(imag(pr)~=0)=[]; % Только действительные корни

	if not(isempty(pr))
		pr=sort(pr);        % Только максимумы полинома
		pdv=sign(polyval(pd, [pr(1)-1; (pr(1:end-1)+pr(2:end))/2; pr(end)+1]));
		pr(pdv(1:end-1)-pdv(2:end)~=2)=[];
	end

	pr(pr<x(1) | pr>x(end))=[]; % Только в диапазоне интерполяции

	if not(isempty(pr))
		[tmp_val, mi]=max(polyval(pp(end:-1:1), pr)); % Полюс с максимальной амплитудой
		r=pr(mi);
	else
		r=max(x);
	end
end

function [f0_freq, f0_time, f0_tone]=get_raw_pitch(x,fs)
	[f0_freq, f0_time, f0_tone]=sfs_rapt(x,fs);
%	[f0_freq, f0_time, f0_tone]=swipep(x,fs,[80 800]);	f0_tone=f0_tone>0.1;
%	[f0_freq, f0_time, f0_tone]=f0_track('signal',x, 'fs',fs);
%	[f0_freq, f0_time, f0_tone]=f0_grundton(x, fs);

	f0_freq(f0_freq<1)=nan;

	f0_time_up=(0:length(x)-1)'/fs;
	f0_freq=interp1q([0; f0_time; length(x)/fs], [f0_freq(1); f0_freq; f0_freq(end)], f0_time_up);

	dtone=diff([0; f0_tone; 0]);
	vocal_regs=[find(dtone==1) find(dtone==-1)-1]';
	vocal_regs=min(round(f0_time(vocal_regs)*fs)+1, size(f0_freq,1));
	f0_tone=zeros(size(f0_freq));
	for i=1:size(vocal_regs,2)
		f0_tone(vocal_regs(1,i):vocal_regs(2,i))=1;
	end

	f0_time=f0_time_up;
end


%Определение гармонических параметров при помощи частотно-модулированного
%фильтра анализа (Илья Азаров)
function [Amp,Frc,Phs]=TakeHParamsXflc(Frame,FC,FD,Dt,X) % harmonic parameters estimation within specified bandwidth
	%      Frame is the frame to analyze (odd value)
	%      FC is the centre frequency of the filter (in Hz)
	%      FD is half of the bandwidth (in Hz)
	%      Dt is 1/FS (FS is the sample rate)
	%      X  is relative sample to estimate (zero is the centre of the frame)
	Ln=length(Frame);
	Centre=floor(Ln/2)+1;
	A=0;
	B=0;
	A1=0;
	B1=0;
	Frame=Frame(:)';

	PhFC=zeros(1,Ln);
	Ph=0;
	for N=(Centre+X):-1:1
		PhFC(N)=Ph;
		Ph=Ph-FC(N);
	end

	Ph=0;
	for N=(Centre+X):Ln
		PhFC(N)=Ph;
		Ph=Ph+FC(N);
	end


	for n=3:Ln-2
		if(n==Centre+X-1)
			A=A+2*FD*Frame(n);
		else
			A=A+Frame(n)/(Centre-n+X-1)/pi/Dt*sin(2*pi*Dt*FD*(Centre-n+X-1))*cos(2*pi*Dt*PhFC(n+1));
			B=B+Frame(n)/(Centre-n+X-1)/pi/Dt*sin(2*pi*Dt*FD*(Centre-n+X-1))*sin(2*pi*Dt*PhFC(n+1));
		end
		if(n==Centre+X+0)
			A1=A1+2*FD*Frame(n);
		else
			A1=A1+Frame(n)/(Centre-n+X+0)/pi/Dt*sin(2*pi*Dt*FD*(Centre-n+X+0))*cos(2*pi*Dt*PhFC(n));
			B1=B1+Frame(n)/(Centre-n+X+0)/pi/Dt*sin(2*pi*Dt*FD*(Centre-n+X+0))*sin(2*pi*Dt*PhFC(n));
		end
	end

	% n=3:Ln-2;
	% Am=Frame(n)./(Centre-n+X-1)./pi./Dt.*sin(2*pi*Dt*FD*(Centre-n+X-1)).*cos(2*pi*Dt*PhFC(n+1));
	% Bm=Frame(n)./(Centre-n+X-1)./pi./Dt.*sin(2*pi*Dt*FD*(Centre-n+X-1)).*sin(2*pi*Dt*PhFC(n+1));
	% Am(Centre+X-1-2)=2*FD*Frame(Centre+X-1);
	% Bm(Centre+X-1-2)=0;
	% A=sum(Am);
	% B=sum(Bm);
	% 
	% Am=Frame(n)./(Centre-n+X+0)./pi./Dt.*sin(2*pi*Dt*FD*(Centre-n+X+0)).*cos(2*pi*Dt*PhFC(n));
	% Bm=Frame(n)./(Centre-n+X+0)./pi./Dt.*sin(2*pi*Dt*FD*(Centre-n+X+0)).*sin(2*pi*Dt*PhFC(n));
	% Am(Centre+X+0-2)=2*FD*Frame(Centre+X+0);
	% Bm(Centre+X+0-2)=0;
	% A1=sum(Am);
	% B1=sum(Bm);

	Amp=((A*A+B*B)^0.5)*Dt*2;
	dx=zeros(1,2);
	if(A && B)
		dx(1)=atan2(-B,A);
	else
		dx(1)=0;
	end

	if(A1 && B1)
		dx(2)=atan2(-B1,A1);
	else
		dx(2)=0;
	end
	dx=unwrap(dx);
	Frc=(dx(2)-dx(1))/2/pi/Dt;
	Phs=dx(1);
end

%Вычисление гармонических парамеров при помощи стационарного фильтра
%анализа (Илья Азаров)
function [Amp,Frc,Phs]=TakeHParamsX_turbo(Frame,FC,FD,Dt,X)
	%      Frame is the frame to analyze (odd value)
	%      FC is the centre frequency of the filter (in Hz)
	%      FD is half of the bandwidth (in Hz)
	%      Dt is 1/FS (FS is the sample rate)
	%      X  is relative sample to estimate (zero is the centre of the frame)
	Ln=length(Frame);
	Centre=floor(Ln/2)+1;
	A=zeros(Ln+1,1);
	B=zeros(Ln+1,1);

	LInd=1:Centre+X-1;
	RInd=(Centre+X+1):Ln+1;

	Part=[sin(2*pi*Dt*FD*(Centre-LInd+X))./(Centre-LInd+X)/pi/Dt 0 sin(2*pi*Dt*FD*(Centre-RInd+X))./(Centre-RInd+X)/pi/Dt];
	A(1:Ln+1)=Part.*cos(2*pi*Dt*FC*(((1:Ln+1)-Centre-X)));
	B(1:Ln+1)=Part.*sin(2*pi*Dt*FC*(((1:Ln+1)-Centre-X)));

	A(Centre+X)=2*FD;

	Ap=Frame*A(2:Ln+1);
	Bp=Frame*B(2:Ln+1);
	Ap1=Frame*A(1:Ln);
	Bp1=Frame*B(1:Ln);

	Amp=((Ap*Ap+Bp*Bp)^0.5)*Dt*2;
	dx=zeros(1,2);
	if(Ap && Bp)
		dx(1)=atan2(-Bp,Ap);
	else
		dx(1)=0;
	end

	if(Ap1 && Bp1)
		dx(2)=atan2(-Bp1,Ap1);
	else
		dx(2)=0;
	end
	dx=unwrap(dx);
	Frc=(dx(2)-dx(1))/2/pi/Dt;
	Phs=dx(1);
end
