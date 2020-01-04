function sgnl2detr = detrndAdpt(sgnl2detr, detrForm)
if ~exist('detrForm', 'var'), detrForm = ''; end
    leftB = sgnl2detr(1); rightB = sgnl2detr(end);
    step = (rightB-leftB)/numel(sgnl2detr);
    submitTrnd = leftB:step:rightB-step; submitTrnd = submitTrnd-leftB;
    if nnz(strfind(detrForm, 'detrend'))
        sgnl2detr = detrend(sgnl2detr);
    end
    if nnz(strfind(detrForm, 'linear'))
        sgnl2detr = sgnl2detr-reshape(submitTrnd, size(sgnl2detr));
    end
    if nnz(strfind(detrForm, 'median'))
        sgnl2detr = sgnl2detr - repmat(floor( median(sgnl2detr, 1)/pi )*pi, size(sgnl2detr, 1), 1);
    end
end