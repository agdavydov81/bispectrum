function [strPath, iterations] = fileNmStrAnls(strPath, strSource, data)
%Function gets strings specifying target folder and audio source.
%It saves specified data to the target folder estimated harmonic params in *.csv format.
%Keying words begin from %. Symbols of parameters:
% %h - save harmonics; %p - full phases; %b - base frequency; %t - time vector.
%Path specifiers: %f - source file name; %(digital) - source path level folder.
% %n - harmonic number; if it's specified, save each harmonic to separate file.
iterations = 1:numel(data.phase.mul); if ~nnz(strfind(strPath, '%')), return; end; iterations = []; %Use *.csv saving if formatted path specified, *.wav otherwise.
prmtrSmbs = {'%h', '%p', '%b', '%t'}; fileSmbls = {'%f', '%n', '%k'};
fileSmbls = [fileSmbls, arrayfun(@(x) sprintf('%%%d', x), 1:9, 'UniformOutput', false)];
prmtsFlds = {'harmncs', 'harm_phi', 'f0_freq', 'harm_t'};
[~, idxs] = unique(data.phase.mul); data.harmncs = data.harmncs(:, idxs); data.harm_phi = data.harm_phi(:, idxs);
%Find all parameters specifiers.
dataCells = []; nmCells = [];% keyboard; %Data for saving.
for ai = 1:numel(prmtrSmbs)
    if nnz(strfind(strPath, prmtrSmbs{ai}))
        dataCells = [dataCells, {data.(prmtsFlds{ai})}];
        nmCells = [nmCells, prmtsFlds(ai)];
        strPath = strrep(strPath, prmtrSmbs{ai}, '');
    end
end
%Find all file path specifiers and construct path 4 *.csv saving.
srcCells = strsplit(strSource, filesep);% keyboard; %pthCells = strsplit(strPath, filesep); 
for ai = 1:numel(fileSmbls)
    idx = strfind(strPath, fileSmbls{ai});
    if ~nnz(idx), continue; end
    for bi = 1:numel(idx)
        %Find the current element anew after shifting after replacing.
        idxCur = strfind(strPath, fileSmbls{ai}); idxCur = idxCur(1);
        switch ai
        case 1 %Source file name.
            strPath = strrep(strPath, fileSmbls{ai}, srcCells{end});
        case 2 %Harmonic's number.
        otherwise %Source path level.
            nms = strPath(idxCur+1); k = 1;
            while ~nnz(isnan( str2double(nms) ))
                k = k + 1; nms = strPath(idxCur+1:idxCur+k);
            end %Get all one-by-one digital symbols.
            lvl = str2double(nms(1:end-1));
            %Possibly add checking of symbols number to not replace two-digit numbers or sort idxs previously.
            strPath = strrep(strPath, fileSmbls{ai}, srcCells{end-lvl});
        end
    end
end
if ~exist(strPath, 'dir'), mkdir(strPath); end %; keyboard;
for ai = 1:numel(dataCells)
    flNm = strsplit(srcCells{end}, '.'); flNm = flNm{1};
    filename = fullfile(strPath, [nmCells{ai} '_' flNm '.csv']);
    %dataCells{ai}(isnan(dataCells{ai})) = zeros(size( dataCells{ai}(isnan(dataCells{ai})) ));
    csvwrite(filename, dataCells{ai});
end
end