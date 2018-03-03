function intc = plotIntcpts(phis, ts, frmls, fileNm)
    %=Find clear (non NaN) pieces of phases, find equal time parts.=
    vcdIdxs = ones(size(phis{1})); %Exclude NaN indexes.
    idxs = cellfun(@(x) ~isnan(x), phis, 'UniformOutput', false);
    for ai = 1:numel(idxs)
        vcdIdxs = bsxfun(@times, vcdIdxs, idxs{ai});
    end
    vcdIdxs = find(vcdIdxs);
    for ai = 1:numel(ts) %Limit indexes to minimum time length.
        vcdIdxs = vcdIdxs( vcdIdxs <= numel(ts{ai}) );
    end
    fullTime = min(cellfun(@(x) min(x(vcdIdxs)), ts)); %Voiced parts limits.
    fullTime(2) = max(cellfun(@(x) max(x(vcdIdxs)), ts)); t = fullTime(1):fullTime(2);
    for ai = 1:numel(ts) %Limit indexes to minimum time length.
        t = intersect(t, ts{ai}); %Time vector for all phases.
        [d, idxs{ai}] = arrayfun(@(x) min(abs(t-x)), ts{ai}); %Indexes of voiced pieces samples.
    end
    %=Use formulas to all phases on the common time samples.=
    for ai = 1:numel(phis) %Get voiced phases.
        eval(sprintf('phi%d = phis{ai}(idxs{ai});', ai));
    end
    intc = cell(size(frmls));
    for i = 1:numel(frmls), intc{i} = eval(frmls{i}); end %eval(['intc{i} = ' frmls{i}]);
    F = figure('units', 'points', 'Position', [0 ,0 ,800,600], 'Visible', 'on'); hold on;
    for i = 1:numel(intc), plot(t, intc{ai}); end
    legend(frmls); title('Intercomponent measures');
    saveas(F, fileNm, 'jpg');
end