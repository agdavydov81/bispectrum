function fileListValid = ValidList(path, extent_list)
	%Return file names with extentions from extent_list.
	if ~iscell(extent_list) extent_list = {extent_list}; end
	extent_list = cellfun( @(x)(strrep(x,'.','')), extent_list,'UniformOutput',false );
	fileListValid   =[];
    dirData = dir(path);	% Get the data for the current directory
    dirIndex = [dirData.isdir];	% Find the index for directories
    fileList = {dirData(~dirIndex).name}';	% Get a list of the files
    
	if ~isempty(fileList)
		fileList = cellfun(@(x) fullfile(path,x),...	% Prepend path to files
					   fileList,'UniformOutput',false);

	   k=1;
		for i=1:1:numel(fileList)
			[pathstr,name,ext] = fileparts(fileList{i,1}) ;
			ext = strrep(ext,'.','');
			ValidVect = find(cellfun( @(x) strcmp({lower(ext)}, lower(x)), extent_list ));
			if ValidVect	% Cut file type
				fileListValid{k,1} = fileList{i,1}; 
				k = k+1;
			end
		end
	end
end