function range = exelRange(row, col)
    rw = arrayfun(@(x) char(x), double('A'):double('Z'), 'UniformOutput', false);
    rowTimes = ceil( log(row)/log(numel(rw)) ); %logA(B)=log(B)/log(A)
    rw1 = rw; rowIndxs = [];
    for i = 1:rowTimes %Repeating letter row range. For example: AA, AB...
        rw2 = [];
        for j = 1:numel(rw1)
            rw2 = [rw2, cellfun(@(x) [rw1{j} x], rw, 'UniformOutput', false)]; %Get concatenated row indexes.
        end
        rowIndxs = [rowIndxs, rw2]; rw1 = rw2; %Use gotten indexes for next ineration (AA, AB, ... -> AAA, AAB, ...)
    end
    rowIndxs = [rw rowIndxs]; row = rowIndxs(row);
    col = arrayfun(@(x) num2str(x), col, 'UniformOutput', false);
    rng1 = strjoin([row(1), col(1)], '');
    rng2 = strjoin([row(end), col(end)], '');
    range = [rng1, ':', rng2];
end