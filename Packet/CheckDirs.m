function  CheckDirs(Names, Root)
	%If some folder of Names does not exist - create it.
	%Root is optional - make pathes like Root\Name(curr).
	if nargin==2
		%Add root if it's need.
		Names = cellfun( @(x)(fullfile(Root, x)), Names, 'UniformOutput', false );
	end
	for ci = 1:numel(Names)
	if ~exist(Names{ci}, 'dir')
		mkdir(Names{ci})
	end
	end
end