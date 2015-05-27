function [y, delay] = filt2way(b, a, x, delay)
%FILT2WAY is filtfilt analog function.
%   [y, delay] = filt2way(b, a, x)
%   [y, delay] = filt2way(b, a, x, delay)
%   [y, delay] = filt2way(filter_handle, x)
%   [y, delay] = filt2way(filter_handle, x, delay)

	if ishandle(b)
		filter_handle = b;
		x = a;
		if nargin<3
			delay = round(3*max( grpdelay(filter_handle) ));
		end

		y_forward=  filter(filter_handle, [x; zeros(delay,size(x,2))]);
		y_back=     filter(filter_handle, y_forward(end:-1:1,:));
		y=y_back(end:-1:(delay+1),:);
	else
		if nargin<4
			[h,w] = freqz(b,a);
			delay = round(3*max( -diff(unwrap(angle(h)))./diff(w) ));
		end

		y_forward=  filter(b, a, [x; zeros(delay,size(x,2))]);
		y_back=     filter(b, a, y_forward(end:-1:1,:));
		y=y_back(end:-1:(delay+1),:);
	end
end
