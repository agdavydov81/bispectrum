function path_to_files=Get_pathes(sourceDir,dir_name)
%dir_name is optional. If it's not received, we work with current directory sourceDir.
%dir_name is a current work directory. Standart it's equally to source dir.
    dirName = sourceDir; 
    if nargin==2
       dirName = dir_name;
    else
        dir_name=dirName;
    end
    if ~exist('path_to_files') path_to_files={}; end
    dirData = dir ( dirName );                  % Get the data for the current directory
    dirIndex = [dirData.isdir];                 % Find the index for directories
    dirList = {dirData(dirIndex).name}';	    % Get a list of the directories
    nDir = length ( dirList );
    
    path_to_files={};
    if nDir>2 %If folder contains some subfolders - add them.
        for i=3:nDir
            dirName=fullfile(dir_name,dirList{i});
            path_to_files=[path_to_files Get_pathes(sourceDir,dirName)]; %Receive full path to dir_name arg.
        end
    end
    %If there are some files in directory - return it's name to add in list.
    if (numel(dirData)-numel(dirList))>0 %If the current folder contains some files.
        %If folder contains sobfolders and files, we should add a previous results
        %(names of non-empty subfolders) and current directory.
        path_to_files=[path_to_files {strrep(dir_name,sourceDir,'')}]; %It's a path of files in "set" folder.
    end
end
