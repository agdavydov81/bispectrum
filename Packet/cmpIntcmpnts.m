function intcs = cmpIntcmpnts(phis, t, formulas, fileNm)
    %Function counts intercomponents of phases according to formulas, saves pic with fileNm if it's assigned.
    if ~exist('fileNm', 'var'), fileNm = ''; end
    for ai = 1:numel(phis) %Fill an phase variables.
        eval(sprintf('phi%d = phis{%d};', ai, ai));
    end
    intcs = cell(size(formulas));
    for ai = 1:numel(formulas)
        intcs{ai} = eval(formulas{ai});
    end
    if ~isempty(fileNm)
        F = figure('units', 'points', 'Position', [0 ,0 ,800,600], 'Visible', 'on'); hold on;
        for ai = 1:numel(phis), plot(t, phis{ai}); end
        legend(formulas); title('Intercomponent measures');
        saveas(F, fileNm, 'jpg');
    end
end