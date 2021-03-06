%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function v = warp_fwd(u,T)
[x,y] = LAF.pt3x3_to_xy(u);
[tx,ty] = tformfwd(T,x,y);
v = LAF.xy_to_pt3x3(tx,ty);