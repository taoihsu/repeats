%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function [score opt_labels labels labels2] = orsa_objective_fn(C,u,sample,cfg,T)
if nargin < 5
    T = cfg.orsa.max_tsq;
end

n = size(C,2);

labels = false(1,n);
labels2 = false(1,n);
score = inf;

[maxC,ind1] = max([sum(C(1:2,:).^2); ...
                   sum(C(3:4,:).^2)]);
[smaxC,ind2] = sort(maxC,'ascend');

logalpha = cfg.orsa.logalpha0(ind1(ind2))+0.5*log10(smaxC);

ind3 = sum(sum(C(:,ind2).^2) < T);

if ind3 > cfg.orsa.k
    kk = [cfg.orsa.k+1:ind3];
    e = inf(size(logalpha));
    e(kk) = cfg.orsa.loge0+cfg.orsa.logcombi_n(kk)+ ...
            cfg.orsa.logcombi_k(kk)+logalpha(kk).*(kk-cfg.orsa.k);

    ind5 = max(find(e < 0));
    
    if ~isempty(ind5) 
        [score,ind4] = min(e(1:ind5));
        labels(ind2(1:ind4)) = true;
        labels2(ind2(1:ind5)) = true;
    else
        score = inf;
    end
end

[~,opt_labels] = msac_objective_fn(C,[],[],cfg);    