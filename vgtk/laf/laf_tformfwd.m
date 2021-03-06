%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
function v = laf_tformfwd(T,u)
[m,n] = size(u);
u1 = reshape(u,3,[]);
v = reshape([tformfwd(T,u1(1:2,:)')';ones(1,m*n/3)],m,[]);