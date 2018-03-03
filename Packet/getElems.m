function [listByData, idxs] = getElems(findIn, vect2find, col)
%Function finds vect2find elements in cell array findIn, 
%returns found data, grouped in cells, and it's indexes.
if numel(col) > 1
    [~, indexes] = arrayfun(@(x) getElems(findIn, vect2find, x), col, 'UniformOutput', false);
    nonEmpts = cellfun(@(x) nnz(x), indexes); idxs = []; listByData = {};
    if nnz(nonEmpts)<numel(indexes), return; end %If there is at least one empty element, data is not found.
    idxs = indexes{1};
    for i = 2:numel(indexes)
        idxs = intersect(idxs, indexes{i});
    end
    listByData = cell(size(idxs));
    for i = 1:numel(listByData)
        listByData{i} = findIn(idxs(i), :); %Get row with matched data
    end
    listByData = vertcat(listByData{:});
    return;
end
vect2find = reshape(vect2find, [], 1);
[~, idxs] = uniteData(findIn, vect2find, col, 1);
%idxs = idxs(:, col); %Indexes of rows, where data is match.
nonEmpts = cellfun(@(x) nnz(x), idxs);
idxs = reshape(find(nonEmpts), 1, []);
listByData = cell(size(idxs));
for i = 1:numel(listByData)
    listByData{i} = findIn(idxs(i), :); %Get row with matched data
end
listByData = vertcat(listByData{:});
end