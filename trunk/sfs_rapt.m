function [f0_freq, f0_time, f0_tone]=sfs_rapt(x, fs, alg)
% SFS_RAPT RAPT algorithm pitch estimation (from Speech Filling System).
%
%   [f0_freq, f0_time, f0_tone]=sfs_rapt(x, fs, alg) return pitch time and
%   tone vectors.
%   Input arguments:
%   x - signal
%   fs - sampling frequency
%   alg - structure with fields
%   alg.frame_step - shift between frames in sec. (default value 0.010)
%   alg.frame_size - frame size in sec. (default value 0.080)
%   alg.frame_step_smpl - shift between frames in samples. Main value if
%     present. If absent calculated as round(alg.frame_step*fs)
%   alg.frame_size_smpl - frame size in samples. Main value if present.
%     If absent calculated as round(alg.frame_size*fs).

%   Copyright Давыдов Андрей (andrew.aka.manik@gmail.com).
%   Revision: 1.0.10.20

	tmp_wav=[tempname() '.wav'];
	tmp_sfs=[tempname() '.sfs'];
	tmp_out=[tempname() '.txt'];
	tmp_bat=[tempname() '.bat'];

	if nargin<2 && isa(x,'char')
		copyfile(x, tmp_wav);
	else
		wavwrite(x,fs,16,tmp_wav);
	end

	if nargin<3
		alg.frame_step=0.010;
		alg.frame_size=0.080;
	end

	copyfile(which('sfs_proj.sfs'), tmp_sfs);

	fh_bat=fopen(tmp_bat, 'w');
	fprintf(fh_bat, '"%s" -t WAV -isp "%s" "%s"\n', which('sfs_slink.exe'), tmp_wav, tmp_sfs);
	fprintf(fh_bat, '"%s" "%s"\n', which('sfs_fxrapt.exe'), tmp_sfs);
	fprintf(fh_bat, '"%s" -i4.01 -f "%s" > "%s"', which('sfs_sdump.exe'), tmp_sfs ,tmp_out);
	fclose(fh_bat);
	dos(['"' tmp_bat '" 1>nul 2>nul']);

% 	dos(['"' which('sfs_slink.exe') '" -t WAV -isp "' tmp_wav '" "' tmp_sfs '" 1> nul 2>&1']);
% 
% 	dos(['"' which('sfs_fxrapt.exe') '" "' tmp_sfs '" 1> nul 2>&1']);
% 
% 	dos(['"' which('sfs_sdump.exe') '" -i4.01 -f "' tmp_sfs '" > "' tmp_out '"']);


	out_file=textread(tmp_out, '%s', 'delimiter','\n'); %#ok<REMFF1>

	delete(tmp_bat);
	delete(tmp_wav);
	delete(tmp_sfs);
	delete(tmp_out);

	out_ind=13;
	if not(strcmp(out_file{out_ind}, 'Data:'))
		out_ind=find(strcmp(out_file, 'Data:'));
	end
	out_file(1:out_ind)=[];

	f0_freq=zeros(0,1);
	for i=1:length(out_file)
		cur_f0=str2num(out_file{i}); %#ok<ST2NM>
		f0_freq(end+1:end+length(cur_f0),1)=cur_f0';
	end

	sfs_frame_step_smpl=round(0.010*fs);
	sfs_frame_size_smpl2=round(0.080*fs/2);

	f0_tone=f0_freq>0;
	f0_time=((0:size(f0_freq,1)-1)'*sfs_frame_step_smpl + sfs_frame_size_smpl2)/fs;
	f0_time=f0_time-alg.frame_size/2;

	if not(isfield(alg,'frame_step_smpl'))
		alg.frame_step_smpl=round(alg.frame_step*fs);
	end
	if not(isfield(alg,'frame_size_smpl'))
		alg.frame_size_smpl=round(alg.frame_size*fs);
	end

	if alg.frame_step_smpl==sfs_frame_step_smpl && alg.frame_size_smpl==2*sfs_frame_size_smpl2
		return;
	end

	sfs_time=f0_time;
	obs_sz=fix((size(x,1)-alg.frame_size_smpl)/alg.frame_step_smpl+1);
	f0_time=((0:obs_sz-1)'*alg.frame_step_smpl + alg.frame_size_smpl/2)/fs;

	f0_interp=interp1q([0; sfs_time; max(sfs_time(end),f0_time(end))+0.1], ...
		[f0_tone(1) f0_freq(1); f0_tone f0_freq; f0_tone(end) f0_freq(end)], f0_time);
	f0_freq=f0_interp(:,2);
	f0_tone=f0_interp(:,1)==1;
	f0_freq(not(f0_tone))=0;
end
