function [res, idxs] = uniteData(set1, set2, col1, col2)
%Function searchs correspondent elements in the first (default) columns of data sets,
%writes to result data combinations. col1,2 assign columns number to search.
    if ~exist('col1', 'var'), col1 = 1; end
    if ~exist('col2', 'var'), col2 = 1; end
    res = []; idxs = [];
    for i = 1:size(set1, 1)
        currIdxs = ones(size(set2, 1), 1);
        for bi = 1:numel(col2) %Compare each element(cellfun) of each assigned column (bi) in both sets.
            currIdxs = currIdxs.*cellfun( @(x) matchData(set1(i, col1(bi)), x), set2(:, col2(bi)) );
            idxs{i, bi} = currIdxs; %Indexes of rows of set1, where data is match in assigned columns.
        end
        secndColIdxs = setxor(1:size(set2, 2), col2); %Get all columns except the reference.
        for j = reshape(find(currIdxs), 1, [])
            curRow = [set1(i, :), set2(j, secndColIdxs)]; res = [res; curRow];
        end
    end
end

function mch = matchData(d1, d2)
%Function compares different data types.
    if iscell(d1), d1 = [d1{:}]; end
    if iscell(d2), d2 = [d2{:}]; end
    s1 = size(d1); s2= size(d2);
    mch = numel(s1) == numel(s2); %Equal dimentions number.
    if ~mch, return; end
    mch = arrayfun(@(x, y) x == y, s1, s2); %Equal dimentions sizes.
    if ~mch, return; end
    mch = strcmp(class(d1), class(d2));
    if ~mch, return; end
    if ischar(d1), mch = strcmp(d1, d2); return; end
    mch = d1==d2;
end