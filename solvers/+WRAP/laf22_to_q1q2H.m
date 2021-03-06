%
%  Copyright (c) 2018 James Pritts
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts
%
classdef laf22_to_q1q2H < WRAP.LafRectSolver
    properties
        solver_impl = [];
    end
    
    methods
        function this = laf22_to_q1q2H(cc)
            this = this@WRAP.LafRectSolver([2 2]);
            this.solver_impl = WRAP.pt5x2_to_q1q2H(cc);
        end

        function M = fit(this,x,corresp,idx,varargin)
            m = corresp(:,idx);
            x = x(:,m(:));
            x = [x(1:3,:) x(4:6,:) x(7:9,:)];
            M = this.solver_impl.fit(x, ...
                                     [1 3 5 7 9; 2 4 6 8 10], ...
                                     [1 2 3 4 5]);            
        end
    end
end
