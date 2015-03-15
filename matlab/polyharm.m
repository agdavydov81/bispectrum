function [y F0 A Phi] = polyharm(fs, len, F0, A, Phi)
	t=(0:len-1)'/fs;

	if nargin<4;	A=ones(size(F0));				end;
	if nargin<5;	Phi=2*pi*rand(1,size(F0,2));	end;

	if size(F0,1)==1;	F0=repmat(F0,size(t,1),1);	end;
	if size(A,1)==1;	A=repmat(A,size(t,1),1);	end;
	if size(Phi,1)==1;	Phi=repmat(Phi,size(t,1),1);end;

	ff=cumtrapz(t,F0);
	y=A.*cos(2*pi*ff+Phi);
end

