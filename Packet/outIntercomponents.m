%=Read phases for each sound of each dictor computed by all methods.=
%Format of file names: Root/method_root/dictor/letter_harm_phi.csv.
%Root folder 4 all methods.
close all
pths = 'D:\Repository\Записи голосов\Таблица_биспектрум';
outPth = 'D:\Repository\Записи голосов\Таблица_биспектрум';
formulas = 'phi1-phi2/2, (phi1+phi3)/2-phi2, phi1+phi2-phi3';
formulas = strsplit(formulas, ', ');
filename = fullfile(outPth, 'phaseMeasures.xlsx');
%Get methods roots as a low level, dictors and letters folders.
path_to_files = Get_pathes(pths); path_to_files = cellfun(@(x) fullfile(pths, x), path_to_files, 'UniformOutput', false);
fList = cellfun(@(x) ValidList(x, 'csv')', path_to_files, 'UniformOutput', false);
fList = [fList{:}]; idxs_phi = logical(cellfun(@(x) nnz(strfind(x, 'harm_phi')), fList));
phiList = fList(idxs_phi); tList = fList(~idxs_phi);
splits = cellfun(@(x) strsplit(x, filesep), phiList, 'UniformOutput', false);
dicts = cellfun(@(x) x(end-1), splits); [~, letts] = cellfun(@(x) fileparts(x{end}), splits, 'UniformOutput', false);
letts = cellfun(@(x) strrep(x, 'harm_phi_', ''), letts, 'UniformOutput', false);
sounds = letts; digts = arrayfun(@(x) num2str(x), 0:9, 'UniformOutput', false);
for i = 1:numel(digts) %Get sound letters.
    sounds = cellfun(@(x) strrep(x, digts{i}, ''), sounds, 'UniformOutput', false);
end
nmbs = cellfun(@(x, y) strrep(x, y, ''), letts, sounds, 'UniformOutput', false); %Get sound realization numbers.
dcs = unique(dicts); snd = unique(sounds); dgs = unique(nmbs); %Unique elements.
%=Make the common table containing file indexes and according data.=
%dictor letter(sound) realization_number phase&time_vectors_file_indexes
tbl = cell(numel(phiList), 4);
for ai = 1:numel(phiList)
    tbl(ai, :) = [dicts(ai), sounds(ai), nmbs(ai), {ai}];
end
%=Take intercomponents for the current sound, comp avg and std of realisations.=
for ai = 1:numel(phiList)
    result{ai}.file = phiList{ai}; result{ai}.dicts = dicts{ai}; result{ai}.letts = letts{ai};
    result{ai}.sound = sounds{ai}; result{ai}.real_numb = nmbs{ai};
    phases = csvread(phiList{ai}); t = csvread(tList{ai}); result{ai}.t = t;
    phases = arrayfun(@(x) phases(:, x), 1:size(phases, 2), 'UniformOutput', false);
    commands = arrayfun(@(x) sprintf('phi%d = phases{%d};', x, x), 1:numel(phases), 'UniformOutput', false);
    svComm = arrayfun(@(x) sprintf('result{ai}.phi%d = phi%d;', x, x), 1:numel(phases), 'UniformOutput', false);
    for bi = 1:numel(commands)
        eval(commands{bi}); %Evaluate phase variables.
        eval(svComm{bi}); %Evaluate phase saving.
    end
    fmls = cellfun(@(x) ['intc = ' x ';'], formulas, 'UniformOutput', false); %Evaluate assigned intercomponent measures.
    svNmCm = arrayfun(@(x) sprintf('result{ai}.intc(%d).formula = formulas(%d);', x, x), 1:numel(formulas), 'UniformOutput', false);
    svComm = arrayfun(@(x) sprintf('result{ai}.intc(%d).intcMsr = intc;', x), 1:numel(formulas), 'UniformOutput', false);
    for bi = 1:numel(formulas) %Get intercomponents, restrict them, save all ...
        eval(fmls{bi}); eval(svNmCm{bi});  %values 4 the curr dict/lett file.
        intc = intc - repmat(floor(median(intc, 1, 'omitnan')/pi)*pi, size(intc, 1), 1);
        eval(svComm{bi}); %Save time-domain phase measure signal.
        result{ai}.intc(bi).avg = mean(intc, 'omitnan'); %Comp average value.
        result{ai}.intc(bi).std = std(intc, 'omitnan'); %Comp std.
    end
end
%-Take average parameters of realizations of the one snd and dictor.-
fls = arrayfun(@(x) repmat(x, 1, 2), formulas, 'UniformOutput', false);
avgstds = repmat({'avg', 'std'}, size(formulas));
k = 1; headers = ['Dictor', 'Letter', [fls{:}]];
for i = 1:numel(headers)
    range = exelRange(i, 1); xlswrite(filename, headers(i), 1, range);
end
for i = 3:numel(headers)
    range = exelRange(i, 2); xlswrite(filename, avgstds(i-2), 1, range);
end
for ai = 1:numel(snd)
    for bi = 1:numel(dcs) %Find the same letters and dictors.
        simLettDicts{k}.snd = snd{ai}; simLettDicts{k}.dcs = dcs{bi};
        range = exelRange(1, k+2); xlswrite(filename, dcs(bi), 1, range);
        range = exelRange(2, k+2); xlswrite(filename, snd(ai), 1, range);
        [~, idxs] = getElems(tbl, [dcs(bi) snd(ai)], [1 2]);
        avg = cell(size(idxs)); %Intcmpt msrs avgs 4 each file.
        for ci = idxs %Get results.
            avg{ci} = arrayfun(@(x) x.avg, result{ci}.intc); %Get intercomp. measures avgs.
        end
        avg = vertcat(avg{:}); %Intcmpt (cols, right) and file (rows, down).
        simLettDicts{k}.avg = mean(avg, 1); %Mean of all realizations averages.
        simLettDicts{k}.std = std(avg, 1); %SRD of all realizations averages.
        %-Write 2 xml intercomponent realizations averages.-
        for ci = 1:size(avg, 2) %Intcpt counter; Shift on 2 top headers, 2 left values (dict and letter).
            range = exelRange(ci*2+1, k+2); xlswrite(filename, {simLettDicts{k}.avg(ci)}, 1, range);
            range = exelRange(ci*2+1+1, k+2); xlswrite(filename, {simLettDicts{k}.std(ci)}, 1, range);
        end
        k = k + 1; %Dictor and letter counter.
    end
end
%=Take intercomponents for realisations of the one sound (letter). Plot and avg/std.=
phsN = 1:3;
outPhs(tbl, result, 'pankratenko', 'a', 1, phsN, fullfile(outPth, 'pankko.jpg'));
outPhs(tbl, result, 'vishniakov', 'u', 1, phsN, fullfile(outPth, 'vshkov.jpg'));
dict1 = {'pankratenko', 'pankratenko', 'pankratenko', 'pankratenko', 'pankratenko'};
snds1 = {'a', 'a', 'a', 'a', 'a'}; phiNms = [1 2 3 1 2]; rlzns = [1 1 1 2 2];
[phis, ts] = outPhs(tbl, result, dict1, snds1, rlzns, phiNms, fullfile(outPth, 'pankko_a12.jpg'));
plotIntcpts(phis([1 5 3]), ts([1 5 3]), formulas, fullfile(outPth, 'pa1_pa2_pa1.jpg'), 'linear, median'); %There is a ...
plotIntcpts(phis([4 2 3]), ts([4 2 3]), formulas, fullfile(outPth, 'pa2_pa1_pa1.jpg'), 'linear, median'); %Three symbols code ...
%=Take intercomponents for realisations of the one dictor. Plot and avg/std.=
dict1 = {'pankratenko', 'pankratenko', 'pankratenko', 'pankratenko', 'pankratenko'};
snds1 = {'a', 'a', 'a', 'e', 'e'}; phiNms = [1 2 3 1 2]; rlzns = ones(1, 5);
[phis, ts] = outPhs(tbl, result, dict1, snds1, rlzns, phiNms, fullfile(outPth, 'pankko_a1_e1.jpg'));
plotIntcpts(phis([1 5 3]), ts([1 5 3]), formulas, fullfile(outPth, 'pa1_pe1_pa1.jpg'), 'linear, median'); %Dictor, letter (sound), ...
plotIntcpts(phis([4 2 3]), ts([4 2 3]), formulas, fullfile(outPth, 'pe1_pa1_pa1.jpg'), 'linear, median'); %Realization number.
dict1 = {'pankratenko', 'pankratenko', 'pankratenko', 'vishniakov', 'vishniakov'};
snds1 = {'a', 'a', 'a', 'a', 'a'}; phiNms = [1 2 3 1 2]; rlzns = [1 1 1 2 2];
[phis, ts] = outPhs(tbl, result, dict1, snds1, rlzns, phiNms, fullfile(outPth, 'pankko_a1_vshkov_a2.jpg'));
plotIntcpts(phis([1 5 3]), ts([1 5 3]), formulas, fullfile(outPth, 'pa1_va2_pa1.jpg'), 'linear, median');
plotIntcpts(phis([4 2 3]), ts([4 2 3]), formulas, fullfile(outPth, 'va2_pa1_pa1.jpg'), 'linear, median');
%=Take intercomponents for realisations of the different sounds and dictors. Plot and avg/std.=
dict1 = {'pankratenko', 'pankratenko', 'pankratenko', 'vishniakov', 'vishniakov'};
snds1 = {'a', 'a', 'a', 'e', 'e'}; phiNms = [1 2 3 1 2]; rlzns = ones(1, 5);
[phis, ts] = outPhs(tbl, result, dict1, snds1, rlzns, phiNms, fullfile(outPth, 'pankko_a1_vshkov_e1.jpg'));
plotIntcpts(phis([1 5 3]), ts([1 5 3]), formulas, fullfile(outPth, 'pa1_ve1_pa1.jpg'), 'linear, median');
plotIntcpts(phis([4 2 3]), ts([4 2 3]), formulas, fullfile(outPth, 've1_pa1_pa1.jpg'), 'linear, median');