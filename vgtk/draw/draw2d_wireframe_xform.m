%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function [x2,y2] = draw2d_wireframe_xform(ax1,u,edges,xform)
un = renormI(u);
axes(ax1);

t = [0:0.1:1]';

vx = reshape(un(1,edges),2,[]);
vy = reshape(un(2,edges),2,[]);

wx = bsxfun(@plus,vx(1,:),bsxfun(@times,t,vx(2,:)-vx(1,:)));
wy = bsxfun(@plus,vy(1,:),bsxfun(@times,t,vy(2,:)-vy(1,:)));

ud = tformfwd(xform, [wx(:) wy(:) ones(numel(wx),1)]);

x = reshape(ud(:,1),numel(t),[]);
y = reshape(ud(:,2),numel(t),[]);

hold on;
plot(x,y,'k');
hold off;
