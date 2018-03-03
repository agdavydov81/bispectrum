function res = takeOneByOneBands(data, config)
	%Function returns bands of data elements, that are in succession, in terms of start-end points.
    if ~exist('config', 'var')
        config = [];
    end
    config = fill_struct(config, 'minInSuccession', '1');
    %'up' - growing sequence; 'down' - decrease sequence; 'const' - stable.
    config = fill_struct(config, 'succession', 'up');
    minInSuccession = str2double(config.minInSuccession);
    if numel(data) > 1000
        %If vector is too long, computing result may take a long time.
        %Divide in cell size 1000 elems.
        len = numel(data) - rem(numel(data), 1000);
        dt = data(1:len);
        tail = data(len+1:end);
        rm = reshape(dt, 1000, len/1000);
        c = num2cell(rm, 1);
        if ~isempty(tail)
            c{end+1} = tail;
        end
        %Cells with ranges (cells with indexes) in a signal pieces.
        conf = setfield(config, 'minInSuccession', '1'); %To avoid loosing teared apart ranges.
        res = cellfun(@(x) takeOneByOneBands(x, conf), c, 'UniformOutput', false);
        %Make the common sequence from the ranges.
        ranges = []; iVect = [];
        for i = 1:numel(res)
           ranges = [ranges res{i}];
           iVect = [iVect repmat(i-1, numel( res{i} ), 1)'];
        end
        if isempty(ranges), res = {}; return; end
        iVect = num2cell(iVect);
        ranges = cellfun(@(x, y) x+1000*y, ranges, iVect, 'UniformOutput', false);
        res = [];
        currRange = ranges{1};
        for i = 2:numel(ranges)
            if currRange(end) - ranges{i}(1) == -1
                %Ranges are in succession - add the one the common.
                currRange = [currRange(1) ranges{i}(end)];
            else
                if currRange(end) - currRange(1) >= minInSuccession
                    res = [res {currRange}]; %Add all previous ranges.
                end
                currRange = ranges{i};
            end
        end
        if currRange(end) - currRange(1) >= minInSuccession
            res = [res {currRange}];
        end
        return;
    end
    %Get necessary comparison function names.
    cmpF = strrep(config.succession, 'up', 'gt'); cmpF = strrep(cmpF, 'down', 'lt');
    cmpF = strrep(cmpF, 'const', 'eq'); cmpF = strrep(cmpF, 'zero', 'iszero');
    inc = 1; %Use the next element 2 comparison 4 binary functions.
    if strcmp(cmpF, 'iszero')
       inc = 0; %Process one element, including the last 4 unary functions.
    end
	res = {};
	while nnz(~isnan(data))
		nonNaN = find(~isnan(data)); %NaN as processed flag.
		startPos = nonNaN(1);
		k = startPos; d = 1;
        %A previous value in range. A function value is constant in range; compare value with previous.
        preVal = [];
        currBand = [];
		while d == 1
			nextEl = k + inc;
			if nextEl > numel(data)
				d = 0;
			else
				val = feval(cmpF, data(k), data(nextEl)); %Compute function that characterises belonging 2 range.
                %Check a previous value if it is. In other case range contain at least one element.
                if ~isempty(preVal)
                    %If values are the same, they are belong 2 one range.
                   d = eq(val, preVal);
                end
                if d %Remember only in-range values.
                    preVal = val;
                end
			end
			k = k + 1;
        end
        if preVal %Remember only ranges, where it keeps assigned conditions.
            currBand = [startPos k - 2]; %Subtract the next index after range and increment after it.
        end
        data(startPos:(k - 2)) = NaN(size( data(startPos:(k - 2)) ));
		res = [res {currBand}];
	end
	%Rest only bands where there are pointed one-by-one elements as minimum.
	numElems = zeros(size(res)); nonEmpts = cellfun(@(x) ~isempty(x), res);
    numElems(nonEmpts) = cellfun(@(x) numel(x(1):x(end)), res(nonEmpts));
	inclIdxs = find(numElems >= minInSuccession);
	res = res(inclIdxs);
end

function answ = iszero(checkArg, secArg)
    answ = 0;
    if (~checkArg)
        answ = 1;
    end
end

% function idx = firstEl(data)
%     idx = 0;
%     for i = 1:numel(data)
%         if ~isnan(data(i))
%             idx = i;
%             return;
%         end
%     end
% end