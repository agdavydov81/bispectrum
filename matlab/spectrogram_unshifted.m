function varargout = spectrogram_unshifted(varargin)
	if nargout == 0
		spectrogram(varargin{:});
		return;
	elseif nargout < 4
		[S,F,T] = spectrogram(varargin{:});
		S = rotate_phase(S,F,T);
		varargout = {S,F,T};
	else
		[S,F,T,P] = spectrogram(varargin{:});
		S = rotate_phase(S,F,T);
		varargout = {S,F,T,P};
	end
end

function S = rotate_phase(S, F, T)
	S_a = abs(S);
	S_e = angle(S);
	
	N2 = size(S,1);
	N = (N2-1)*2;
	Fs = 2*F(end);
	if any(imag(S(end,:))~=0)
		Fs = Fs * (N+1) / N;
		N = N+1;
	end
	% win_sz = round(T(1) * Fs * 2);

	sh_ii = round((T - T(1)) * Fs);

	S_e = S_e - (0:N2-1)'*2*pi/N * sh_ii;

	S = S_a .* exp(S_e * 1i);
end

function unittest()
	x = randn(1000,1);
	
	S_ref = spectrogram_unshifted(x, 221, 218, 251, 11025);
	S_test = spectrogram_circshift(x, 221, 218, 251, 11025);

	if ~isequal(size(S_ref),size(S_test))
		error('spectrogram_unshifted:unittest', 'Result size mismatch');
	end
	
	if max(max( abs((abs(S_test)-abs(S_ref))./abs(S_ref)) )) > 1e-7
		error('spectrogram_unshifted:unittest', 'Absolute part relative difference is too big.');
	end
	if max(max( abs((angle(S_test)-angle(S_ref))./angle(S_ref)) )) > 1e-7
		error('spectrogram_unshifted:unittest', 'Angle part relative difference is too big.');
	end
end

function S = spectrogram_circshift(x, nwind, noverlap, nfft, fs)
	nshift = nwind - noverlap;

	nfft2 = floor(nfft/2 + 1);
	ncol = fix((size(x,1)-noverlap)/(nwind-noverlap));

	S = zeros(nfft2, ncol);
	
	win = hamming(nwind);
	for ni = 1:ncol
		sh_i = (ni-1)*nshift;
		cur_x = x(sh_i + (1:nwind));
		cur_x = cur_x .* win;
		if numel(cur_x) < nfft
			cur_x(nfft) = 0;
		end

		sh_i = rem(sh_i, numel(cur_x));
		shift_x = [cur_x(end-sh_i+1:end,:); cur_x(1:end-sh_i)];
		if ~isequal(shift_x, circshift(cur_x,(ni-1)*nshift,1))
			error('circular shift error');
		end
		
		fx = fft(shift_x);
		S(:,ni) = fx(1:nfft2);
	end
end
