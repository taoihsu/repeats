function w = join_to_lafs(u,segments,varargin)
cfg.test = 'cog';
[cfg,leftover] =  cmp_argparse(cfg,varargin{:});

num_lafs = size(u,2);

if strcmpi(cfg.test,'poly')
    v = LAF.p3x3_to_poly(u);
    for k = 1:size(v,2)
        BW = poly2mask(v(1:2:end,k),v(2:2:end,k), ...
                       size(segments,1),size(segments,2));
        w{k} = setdiff(unique(BW.*segments),0);
    end
elseif strcmpi(cfg.test,'cog')
    v = round(u(4:5,:));
    w = segments(sub2ind(size(segments),v(2,:),v(1,:)));
    w = mat2cell(w,1,ones(1,numel(w)));
end