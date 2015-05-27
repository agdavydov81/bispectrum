function speech_art_fs()
	signal.sample_rate = 11025;
	signal.frame_step = round(0.010*signal.sample_rate);
	signal.frame_size = round(0.030*signal.sample_rate);
	signal.FFT_N = pow2(2+nextpow2(signal.frame_size));
	signal.band = round([300 4000]*signal.FFT_N/signal.sample_rate);
	signal.power_rg = [-40 20];
	signal.rceps = round(0.004*signal.sample_rate);
	signal.lpc_order = round(signal.sample_rate/1000+4);
	signal.snale_length = 100;

	root = ['voiced' filesep 'f0_flow' filesep];
	list = dir([root '*.wav']);
	list = strcat(root, {list.name});

	classes = struct('name',{}, 'obs',{});
	for li=1:length(list)
		[x,info]=libsndfile_read(list{li});
		for ri=1:length(info.Regions)
			x_r = x(info.Regions(ri).Position-1+(1:info.Regions(ri).Length));
			classes = calc_obs(signal, classes, x_r, info.SampleRate, info.Regions(ri).Name);
		end
	end

	data_obs = vertcat(classes.obs);
	data_cl = cell2mat(arrayfun(@(x) repmat(x.name,size(x.obs,1),1), classes(:), 'UniformOutput',false));
%{
	[COSTs, GAMMAs, PREDICTSs] = lib_svm.find_cost_gamma(data_obs, data_cl, 'autoscale',false);
	[~, AVERAGE_RECALL] = lib_svm.rate_prediction(data_cl,PREDICTSs, 'order',vertcat(classes.name));
	figure('NumberTitle','off', 'Name','speech_art_fs: svm');
	surf_x = unique(log2(GAMMAs));
	surf_y = unique(log2(COSTs));
	surf(surf_x, surf_y, reshape(AVERAGE_RECALL, length(surf_y), length(surf_x)));
	xlabel('log2(GAMMA)');
	ylabel('log2(COST)');
	zlabel('Average recall');
	title('Best COST-GAMMA combination finding');
%}
	svm_opt = ' -c 512 -g 0.125 -h 0 -q';
	gmm_opt = {1, 'Replicates',3, 'Regularize',1e-6, 'options',statset('MaxIter',10000, 'TolX',1e-6)};

	C = nchoosek(1:size(data_obs,2),2);
	C = mat2cell(C, ones(1,size(C,1)), size(C,2));
	rate_svm = zeros(size(C));
	rate_gmm = zeros(size(C));
	parfor ci=1:length(C)
		rate_svm(ci) = est_rate_svm(data_obs(:,C{ci}), data_cl, svm_opt); %#ok<PFBNS>
%		rate_gmm(ci) = est_rate_gmm(data_obs(:,C{ci}), data_cl, gmm_opt);
	end

	figure('NumberTitle','off', 'Name','speech_art_fs: fs');
	plot(1:length(rate_svm),rate_svm,'b', 1:length(rate_gmm),rate_gmm,'r');
	legend({'rate SVM', 'rate GMM'});

	fprintf('SVM best\n');
	[~,si]=sort(rate_svm,'descend');
	for i=1:30
		fprintf('%f\t%s\n',rate_svm(si(i)),num2str(C{si(i)}));
	end
	
	fprintf('GMM best\n');
	[~,si]=sort(rate_gmm,'descend');
	for i=1:30
		fprintf('%f\t%s\n',rate_gmm(si(i)),num2str(C{si(i)}));
	end
end

function rate = est_rate_svm(data_obs, data_cl, svm_opt)
	[cl_ind, ~, cl_classes]=grp2idx(data_cl);
	base_sz = arrayfun(@(x) sum(cl_ind==x), 1:length(cl_classes));
	clw_str = cell2mat(arrayfun(@(x,y) sprintf(' -w%d %e',x,y), 1:length(cl_classes), min(base_sz)./base_sz, 'UniformOutput',false));
	cm = confusionmat(cl_ind, libsvmtrain(cl_ind, data_obs, [clw_str ' -v 10 ' svm_opt]));
	cm = cm./repmat(sum(cm,2),1,size(cm,2));
	rate = mean(diag(cm));
end

function rate = est_rate_gmm(data_obs, data_cl, gmm_opt)
	[cl_ind, ~, cl_classes]=grp2idx(data_cl);

	cl_res = nan(size(data_obs,1),numel(cl_classes));
	for cl_i=1:numel(cl_classes)
		gmm = gmdistribution.fit(data_obs(cl_ind==cl_i, :), gmm_opt{:});

		cl_res(:,cl_i)=gmm.pdf(data_obs);
	end
	[~,cl_res] = max(cl_res, [], 2);
	cm = confusionmat(cl_ind, cl_res, 'order',1:numel(cl_classes));

 	cm = cm./repmat(sum(cm,2),1,size(cm,2));
 	rate = mean(diag(cm));
end

function classes = calc_obs(signal, classes, x, fs, reg_name)
	if fs~=signal.sample_rate
		x = resample(x, signal.sample_rate, fs);
		fs = signal.sample_rate;
	end

	obs_sz=fix((length(x)-signal.frame_size)/signal.frame_step+1);
	obs = zeros(obs_sz, signal.lpc_order);

	win = hamming(signal.frame_size);

	obs_ind=0;
	for i=1:signal.frame_step:length(x)-signal.frame_size+1
		cur_frame=x(i:i+signal.frame_size-1);
		obs_ind=obs_ind+1;

		% Windowing
		cur_frame = cur_frame.*win;

		% Preemphasis
%		cur_frame = fftfilt([1 -1],cur_frame);
		% Adaptive preemphasis
		cur_frame = filter(lpc(cur_frame,1),1,cur_frame);

		% LPC spectrum
		cur_a = lpc(cur_frame, signal.lpc_order);
		if any(isnan(cur_a))
			cur_a=[1 zeros(1, signal.lpc_order)];
		end
		obs(obs_ind, :) = transpose(poly2lsf(cur_a));
	end
	
	ind = find(strcmp(reg_name, {classes.name}));
	if isempty(ind)
		classes(end+1) = struct('name',reg_name, 'obs',obs);
	else
		classes(ind).obs = [classes(ind).obs; obs];
	end
end
