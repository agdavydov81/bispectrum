function [phis, ts] = outPhs(tbl, result, dict, sound, rlzn, phsNmbs, fileNm)
%Return pack of phases of assigned harmonics numbers, according dictors, letters, realization numbers.
%Optional file name can be pattern: %t - type (phase/hilbert phase);
% %d - dictor; %s - sound; %r - realization number.
    if ~iscell(dict), dict = {dict}; end; if ~iscell(sound), sound = {sound}; end
    if numel(dict) == 1, dict = repmat(dict, size(phsNmbs)); 
        sound = repmat(sound, size(phsNmbs)); rlzn = repmat(rlzn, size(phsNmbs)); end
    for ai = 1:numel(dict)
        [elems, ~] = getElems(tbl, [dict(ai) sound(ai)], [1 2]);
        idx = strfind( elems(:, 3), num2str(rlzn(ai)) ); idx = logical(cellfun(@(x) nnz(x), idx));
        idx = elems{idx, end}; %Get index of the current realization in the files results list.
        eval(sprintf( 'phis{ai} = result{idx}.phi%d;', phsNmbs(ai) )); ts{ai} = result{idx}.t;
        if exist('fileNm', 'var')
            fileName = strrep(fileNm, '%d', dict{ai});
            fileName = strrep(fileName, '%s', sound{ai});
            fileName = strrep(fileName, '%r', num2str(rlzn(ai)));
            F = figure('units', 'points', 'Position', [0 ,0 ,800,600], 'Visible', 'on');
            saveas(F, fileName, 'jpg');
        end
    end
end