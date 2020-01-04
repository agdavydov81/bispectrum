function [phis, ts] = outPhs(tbl, result, dict, sound, rlzn, phsNmbs, fileNm)
%Return pack of phases of assigned harmonics numbers, according dictors, letters, realization numbers.
%Optional file name can be pattern: %t - type (phase/hilbert phase);
% %d - dictor; %s - sound; %r - realization number.
detrForm = 'linear, median'; %Assigns way of detrinding.
    if ~iscell(dict), dict = {dict}; end; if ~iscell(sound), sound = {sound}; end
    if numel(dict) == 1, dict = repmat(dict, size(phsNmbs)); 
        sound = repmat(sound, size(phsNmbs)); rlzn = repmat(rlzn, size(phsNmbs)); end
    ts = cell(size(dict)); phis = ts; legendos = ts;
    if exist('fileNm', 'var'), F = figure('units', 'points', 'Position', [0 ,0 ,800,600], 'Visible', 'on'); hold on; end
    for ai = 1:numel(dict)
        [elems, ~] = getElems(tbl, [dict(ai) sound(ai)], [1 2]);
        idx = strfind( elems(:, 3), num2str(rlzn(ai)) ); idx = logical(cellfun(@(x) nnz(x), idx));
        idx = elems{idx, end}; %Get index of the current realization in the files results list.
        phis{ai} = eval(sprintf( 'result{idx}.phi%d;', phsNmbs(ai) ));
        phases_detr = phis{ai}(~isnan(phis{ai})); ts{ai} = result{idx}.t;
        if exist('fileNm', 'var') %Is it possible consider each dict/sound/realisation in the one file name? Think agiain.
            fileName = strrep(fileNm, '%d', dict{ai});
            fileName = strrep(fileName, '%s', sound{ai});
            fileName = strrep(fileName, '%r', num2str(rlzn(ai)));
           legendos{ai} = [dict{ai} ' ' sound{ai} num2str(rlzn(ai))];
           phases_detr = detrndAdpt(phases_detr, detrForm);
            plot(ts{ai}(~isnan(phis{ai})), phases_detr/phsNmbs(ai));
        end
    end
    if exist('fileNm', 'var'), legend(legendos); title('Phases'); saveas(F, fileName, 'jpg'); end
end