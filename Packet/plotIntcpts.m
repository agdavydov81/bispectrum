function intc = plotIntcpts(phis, ts, frmls, fileNm, detrForm)
if ~exist('detrForm', 'var'), detrForm = ''; end
    %=Find clear (non NaN) pieces of phases, find equal time parts.=
    vcdIdxs = cellfun(@(x) ~isnan(x), phis, 'UniformOutput', false); %Exclude NaN indexes.
    vcdTms = cellfun(@(x, y) x(y), ts, vcdIdxs, 'UniformOutput', false); %Time pieces.
    mins = cellfun(@(x) min(x), vcdTms, 'UniformOutput', 1); %Lower borders of time pieces.
    maxs = cellfun(@(x) max(x), vcdTms, 'UniformOutput', 1); %Higher borders of time pieces.
    lwBrd = max(mins); hghBrd = min(maxs); %Intersection of voiced pieces.
    [d, lowIdx] = cellfun(@(x) min(abs(x-lwBrd)), ts, 'UniformOutput', false);
    [d, hghIdx] = cellfun(@(x) min(abs(x-hghBrd)), ts, 'UniformOutput', false);
    tId = cellfun(@(x, y) x:y, lowIdx, hghIdx, 'UniformOutput', false); %The common for all phses indexes.
    %=Use formulas to all phases on the common time samples.=
    for ai = 1:numel(phis) %Get voiced phases.
        myResultSignal = phis{ai}(tId{ai});
        if (ai ~= 1) && ( numel(myResultSignal) ~= numel(phis{1}(tId{1})) ) %Make equal samples number.
            myResultSignal = interp1(ts{ai}(tId{ai}), myResultSignal, ts{1}(tId{1}), 'pchip'); end
        eval(sprintf('phi%d = myResultSignal;', ai));
    end
    intc = cell(size(frmls));
    for i = 1:numel(frmls), intc{i} = detrndAdpt(eval(frmls{i}), detrForm); end
    F = figure('units', 'points', 'Position', [0 ,0 ,800,600], 'Visible', 'on'); hold on;
    for i = 1:numel(intc), plot(ts{1}(tId{1}), intc{i}); end
    legend(frmls); title('Intercomponent measures');
    saveas(F, fileNm, 'jpg');
end