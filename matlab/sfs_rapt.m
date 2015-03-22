function [f0_freq, f0_time, f0_tone]=sfs_rapt(x, fs)
% SFS_RAPT RAPT algorithm pitch estimation (from Speech Filling System).
%
%   [f0_freq, f0_time, f0_tone]=sfs_rapt(x, fs) return pitch time and
%   tone vectors.
%   Input arguments:
%   x - signal
%   fs - sampling frequency

%   Copyright Давыдов Андрей (andrew.aka.manik@gmail.com).
%   Revision: 1.0.13

	tmp_dir=tempname();
	mkdir(tmp_dir);

	tmp_wav=[tmp_dir filesep 'in.wav'];
	tmp_sfs=[tmp_dir filesep 'object.sfs'];
	tmp_out=[tmp_dir filesep 'out_pitch.txt'];
	tmp_bat=[tmp_dir filesep 'proc.bat'];

	if nargin<2 && isa(x,'char')
		[~, ~, snd_ext] = fileparts(x);
		if ~strcmpi(snd_ext,'.wav') && exist('libsndfile_read','file')
			[x, x_info] = libsndfile_read(x);
			fs = x_info.SampleRate;
		else
			tmp_wav = x;
		end
	end
	if isnumeric(x)
		x(:,2:end) = [];
		wavwrite(x,fs,16,tmp_wav);
	end
	if ~exist('fs','var')
		if exist('libsndfile_read','file')
			x_info = libsndfile_info(tmp_wav);
			fs = x_info.SampleRate;
		else
			[~,fs] = wavread(tmp_wav);
		end
	end

	copyfile(which('sfs_proj.sfs'), tmp_sfs);

	fh_bat=fopen(tmp_bat, 'w');
	fprintf(fh_bat, '"%s" -t WAV -isp "%s" "%s"\n', which('sfs_slink.exe'), tmp_wav, tmp_sfs);
	fprintf(fh_bat, '"%s" "%s"\n', which('sfs_fxrapt.exe'), tmp_sfs);
	fprintf(fh_bat, '"%s" -i4.01 -f "%s" > "%s"', which('sfs_sdump.exe'), tmp_sfs ,tmp_out);
	fclose(fh_bat);
	[dos_res, dos_out] = dos(tmp_bat); %#ok<NASGU,ASGLU>

	double_regexpr = '[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?';
	data_out_ind=13;

	out_txt=textread(tmp_out, '%s', 'delimiter','\n'); %#ok<REMFF1>
	pitch_fs = str2double(regexp(out_txt{9}, ['(?<=Frame Duration : ' double_regexpr ' \()\d+(?= Hz\))'], 'match','once'));
	pitch_fs = fs/fix(fs/pitch_fs);
	
	try
		rmdir(tmp_dir,'s');
	catch ME
		disp(ME.message);
		disp(ME.stack(1));
	end

	if not(strcmp(out_txt{data_out_ind}, 'Data:'))
		data_out_ind=find(strcmp(out_txt, 'Data:'));
	end
	out_txt(1:data_out_ind)=[];
	
	f0_freq = transpose(str2num([out_txt{:}])); %#ok<ST2NM>

	f0_tone=f0_freq>0;
	f0_time=((0:size(f0_freq,1)-1)'+0.5)/pitch_fs;
end
