function [] = do_one_img(img_url,varargin)
repeats_init();
cfg = struct('solver', 'WRAP.laf222_to_ql', ...
             'target_dir', '.');
cfg = cmp_argparse(cfg,varargin{:});
img = Img('url', img_url);  
cache_params = { 'read_cache', true, ...
                 'write_cache', true };
cid_cache = CidCache(img.cid,cache_params{:});
[~,name,ext] = fileparts(img_url);
cc = [(img.width+1)/2 (img.height+1)/2];
solver = feval(cfg.solver)
target_fname = [cfg.target_dir '/' name '_' solver.name '.mat'];
if ~exist(target_fname)
    dr = DR.get(img,cid_cache, ...
                    {'type','all', ...
                     'reflection', false });
    [x,Gsamp,Gapp] = group_desc(dr);    
    res = rectify_planes(x,Gsamp,Gapp,solver,cc);
    rex.x = x;
    res.Gsamp = Gsamp;
    res.Gapp = Gapp;
    save(target_fname,'-struct', 'res' );
end