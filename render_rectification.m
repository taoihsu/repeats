function [rimg,refpt] = render_rectification(img,H,cc,q,v,varargin)
cfg = struct('minscale', 0.1, ...
             'maxscale', 5); 
cfg = cmp_argparse(cfg,varargin{:});

[ny,nx,~] = size(img);
x =  PT.renormI(H*CAM.ru_div(v,cc,q));
idx = convhull(x(1,:),x(2,:))
mux = mean(x(:,idx),2);

refpt = CAM.rd_div(PT.renormI(inv(H)*mux),cc,q)

rimg = IMG.ru_div_rectify(img,cc,H,q, ...
                          'Fill', [255 255 255]', ...
                          'ReferencePoint', refpt, ...
                          'MinScale', cfg.minscale, ...
                          'MaxScale', cfg.maxscale, ...
                          'CSpond', v, ...
                          'Dims', [ny nx], ...
                          'Registration', 'affinity');