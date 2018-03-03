%Make table from phase measures results.
Root = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(genpath(Root)); cd(Root);
outPh = fullfile(Root, 'Out');
inPh = 'D:\Repository\Записи голосов\Разложения ВВМ\txt';
filename = fullfile(outPh, 'phaseMeasures.xlsx');
MatName = fullfile(outPh, 'phaseMeasures.mat');
MATOBJ = matfile(MatName, 'Writable', false);
formulas = {'y;' 'mod(y, pi);' 'y - repmat(floor(median(y, 1, ''omitnan'')/pi)*pi, size(y,1),1);'};
headers = {'Dictor', 'Letter', 'Mean', 'Median', 'STD', 'Mod pi mean', 'Mod pi median', 'Mod pi STD', 'Submit. mean', 'Submit. median', 'Submit. STD', 'Base tone'};
iterations = [1 2 3 4 5 3 4 5 3 4 5 6 7 8 6 7 8 6 7 8 9 10 11 9 10 11 9 10 11 12]; k = 0;
for i = iterations %1:numel(headers)
    k = k + 1;
    range = exelRange(k, 3); %Header
    xlswrite(filename, headers(i), 1, range);
end

[nrows,ncols] = size(MATOBJ, 'result');
for ai = 1:max([nrows,ncols])
    result = MATOBJ.result(1, ai);
    eval_str = 'phi1-phi2/2,  (phi1+phi3)/2-phi2, phi1+phi2-phi3'; %result.eval_str;
    eval_str = strsplit(eval_str, ',');
    phs = result.evals; %+3 is reserve for header.
    for di = 1:size(phs, 2)
        dff = diff( [0, reshape(phs(:, di), 1, [])] );
        idxsNN = isnan(dff); %Phase NaN  samples;
        idxsJ = abs(dff) > 0.1; %Phase jumps.
        minInSucc = num2str(round(size(phs, 1)/50)); %Min length of stable parts.
        res = takeOneByOneBands( double(idxsJ), struct('succession', 'zero', 'minInSuccession', minInSucc) );
        if ~isempty(res)
            res = cellfun(@(x) x(1):x(end), res, 'UniformOutput', false);
            idxsSt = [res{:}]; %Stable parts.
        else
            idxsSt = [];
        end
        idxsJ = true(size(phs, 1), 1); fls = false(size(phs, 1), 1);
        idxsJ(idxsSt) = fls(idxsSt); %Exclude too short stable parts.
        idxs2del = idxsNN | reshape(idxsJ, size(idxsNN)); %Exclude NaNs and jumps.
        phs(idxs2del, di) = NaN(size( phs(idxs2del, di) ));
    end
    range = exelRange(1, ai+3); %Dictor
    xlswrite(filename, {result.dictor}, 1, range);
    range = exelRange(2, ai+3); %Letter
    xlswrite(filename, {result.letter}, 1, range);
    for bi = 1:numel(formulas)
        figure; hold on;
        for ci = 1:size(phs, 2)
            shft = size(phs, 2)*3*(bi-1)+(ci-1)*3; %Number of processed characteristics.
            y = phs(:, ci); y = eval(formulas{bi}); plot(y);
            range = exelRange(3+shft, ai+3); %Mean
            xlswrite(filename, mean(y, 'omitnan'), 1, range);
            range = exelRange(4+shft, ai+3); %Median
            xlswrite(filename, median(y, 'omitnan'), 1, range);
            range = exelRange(5+shft, ai+3); %STD
            xlswrite(filename, std(y, 'omitnan'), 1, range);
        end
        legendos = arrayfun(@(x) num2str(x), 1:size(phs, 2), 'UniformOutput', false);
        legend(legendos);
        fld = fullfile(num2str(bi), result.dictor);
        fld = fullfile(outPh, fld); CheckDirs(fld);
        fNm = [result.letter '.jpg']; saveas(gcf, fullfile(fld, fNm), 'jpg'); close(gcf);
    end
    if nnz(result.f0_freq)
        range = exelRange(6+shft, ai+3); %Base tone.
        xlswrite(filename, mean(result.f0_freq, 'omitnan'), 1, range);
    else
        %Integrate full phase, multiply by Fs/(2pi).
        
    end
end