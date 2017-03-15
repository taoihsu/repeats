function [model_list,u_corr_list,stats_list] = greedy_repeats(dr,varargin)
cfg.motion_model = 'HG.laf2xN_to_RtxN';
cfg.img = [];
cfg.cc = [];
cfg.rho = 'l2';
cfg.do_distortion = true;
cfg.num_planes = 1;

[cfg,leftover] = cmp_argparse(cfg,varargin{:});

G_app = group_desc(dr,varargin{:});

for k = 1:cfg.num_planes
    [u_corr0,model0] = generate_model(dr,G_app,cfg.motion_model,cfg.cc,leftover{:});
    [u_corr,model,stats] = refine_model([dr(:).u],u_corr0,model0);
    
    model_list{k} = model;
    u_corr_list{k} = u_corr;
    stats_list{k} = stats;
    
    G_app = rm_inliers(u_corr,G_app);
end


%keyboard;

%for k = 1:max(G_app)
%    figure;imshow(cfg.img);
%    LAF.draw(gca,u(:,G_app==k),'LineWidth',2);
%end
%Gr = get_reflections(dr,G_app);

%tst = intersect(G_app(find([dr(:).reflected]==1)),G_app(find([dr(:).reflected]==0)))
%keyboard;
%
%indo = find([dr(:).reflected] == 0);
%indr = find([dr(:).reflected] == 1);
%figure;
%imshow(cfg.img);
%LAF.draw_groups(gca,u,G_app);
%keyboard;
%
%figure;
%imshow(cfg.img);
%LAF.draw_groups(gca,u(:,indo),G_app(indo));
%figure;
%imshow(cfg.img);
%LAF.draw_groups(gca,u(:,indr),G_app(indr));
%
%figure;
%imshow(cfg.img);
%LAF.draw_groups(gca,u,G_app,'LineWidth',3);
%
