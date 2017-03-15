classdef MleImpl < handle
    properties    
        params = [];
        predict = [];

        x = [];        

        model0;
        dz0 = [];

        K = 0;
    end
    
    methods(Static)
        function err = errfun(dz,mle_impl)
            [Hinf,q,U,Rt_i,Rt_ij] = mle_impl.unpack(dz);            
            yi = LAF.apply_rigid_xforms(U(:,mle_impl.predict.G_u),...
                                        Rt_i(:,mle_impl.predict.G_i));
            yj = LAF.apply_rigid_xforms(yi, ...
                                        Rt_ij(:,mle_impl.predict.G_ij));
            Hinv = inv(Hinf);
            ylaf = LAF.renormI(blkdiag(Hinv,Hinv,Hinv)*[yi yj]);
            yu = reshape(ylaf,3,[]);
            yd = CAM.rd_div(yu(1:2,:),mle_impl.model0.cc,q);
            err = reshape(yd-mle_impl.x,[],1);
        end
    end

    methods(Access = public)
        function this = MleImpl(u,u_corr,model0,varargin)
            this.pack(u,u_corr,model0);
        end
        
        function [] = pack(this,u,u_corr,model0)
            this.model0 = model0;
            this.K = height(u_corr);
            
            x_laf = [u(:,u_corr{:,'i'}) u(:,u_corr{:,'j'})];
            x = reshape(x_laf,3,[]);
            this.x = x(1:2,:); 
            
            rtxn_idx = find(u_corr.MotionModel == 'HG.laf2xN_to_RtxN');
            
            q_idx = 1;

            if isempty(rtxn_idx)
                H_idx = [1:3]+q_idx(end);
            else
                H_idx = [1:8]+q_idx(end);
            end

            U_idx = [1:6*size(this.model0.U,2)]+H_idx(end);

            dt_i_idx = [1:2*size(this.model0.Rt_i,2)]+U_idx(end);
            dt_ij_idx = [1:2*size(this.model0.Rt_ij,2)]+dt_i_idx(end);
            
            [G_theta,uG_theta] = ...
                findgroups(u_corr(rtxn_idx,:).MotionModel);         

            if isempty(rtxn_idx)
                dtheta_i_idx = [];
                dtheta_ij_idx = [];
                uGi_theta = [];
                uGij_theta = [];
            else
                [Gi_theta,uGi_theta] = findgroups(u_corr.G_i(rtxn_idx));
                dtheta_i_idx = [1:numel(uGi_theta)]+dt_ij_idx(end);
                [Gij_theta,uGij_theta] = findgroups(u_corr.G_ij(rtxn_idx));
                dtheta_ij_idx = [1:numel(uGij_theta)]+dtheta_i_idx(end);
            end
            
            this.params =  ...
                struct('q', q_idx,'H', H_idx, ...
                       'U', U_idx, ...
                       't_i', dt_i_idx, 't_ij', dt_ij_idx, ...
                       'theta_i', dtheta_i_idx,'theta_ij',dtheta_ij_idx, ...
                       'active', struct('theta_i', uGi_theta, 'theta_ij', uGij_theta));

            this.predict =  struct('G_u',u_corr.G_u,'G_i',u_corr.G_i,'G_ij',u_corr.G_ij, ...
                                   'active', struct('u_corr_i',rtxn_idx));
           
            if isempty(this.params.theta_ij)
                this.dz0 = zeros(this.params.t_ij(end),1);
            else
                this.dz0 = zeros(this.params.theta_ij(end),1);                
            end
        end
        
        function [Hinf,q,U,Rt_i,Rt_ij] = unpack(this,dz)
            dq = dz(this.params.q);
            dH = dz(this.params.H);
            dU = LAF.pt2x3_to_pt3x3(reshape(dz(this.params.U),6,[]));
            dt_i = reshape(dz(this.params.t_i),2,[]);
            dt_ij = reshape(dz(this.params.t_ij),2,[]);
            dtheta_i = reshape(dz(this.params.theta_i),1,[]);
            dtheta_ij = reshape(dz(this.params.theta_ij),1,[]);
            
            q = this.model0.q+dq;
            
            U = this.model0.U+dU;

            theta_i = this.model0.Rt_i(1,:);
            t_i = this.model0.Rt_i(2:3,:)+dt_i;
            
            theta_ij = this.model0.Rt_ij(1,:);            
            t_ij = this.model0.Rt_ij(2:3,:)+dt_ij;
            
            if isempty(this.params.theta_ij)    
                Hinf = this.model0.Hinf;
                Hinf(3,:) = Hinf(3,:)+dH';
            else
                Hinf = [1+dH(1)   dH(4)   dH(7); ...
                        dH(2)    1+dH(5)  dH(8); ...
                        dH(3)     dH(6)     1  ]*this.model0.Hinf;
                theta_i(1,this.params.active.theta_i) = ...
                    this.model0.Rt_i(1,this.params.active.theta_i)+dtheta_i;
                theta_ij(1,this.params.active.theta_ij) = ...
                    this.model0.Rt_ij(1,this.params.active.theta_ij)+dtheta_ij;
            end
            
            Rt_i = [theta_i;t_i];
            Rt_ij = [theta_ij;t_ij];
        end
        
        function Jpat = make_Jpat(this)
            K = this.K;
            M = 12*K;

            if isempty(this.params.theta_ij)
                N = this.params.t_ij(end);
            else
                N = this.params.theta_ij(end);
            end
            
            dq = this.params.q;
            dH = this.params.H;
            dU = reshape(this.params.U,6,[]);

            dt_i = reshape(this.params.t_i,2,[]);
            dt_ij = reshape(this.params.t_ij,2,[]);
            dtheta_i = this.params.theta_i;
            dtheta_ij = this.params.theta_ij;
            
            [dq_ii dq_jj] = meshgrid(1:M,dq);
            [dH_ii dH_jj] = meshgrid(1:M,dH);

            dU_ii = reshape(repmat([1:M],6,1),1,[]);
            dU_jj = reshape(repmat(dU(:,this.predict.G_u),6,2),1,[]);

            dti_ii = reshape(repmat([1:M],2,1),1,[]);
            dti_jj = reshape(repmat(dt_i(:,this.predict.G_i),6,2),1,[]);

            dt_ij_ii = reshape(repmat([1:M],2,1),1,[]);
            dt_ij_jj = reshape(repmat(dt_ij(:,this.predict.G_ij),6,2),1,[]);

            tmp = reshape([1:M],6,[]);

            active_responses = reshape(tmp(:,[this.predict.active.u_corr_i; ...
                                this.predict.active.u_corr_i+K]),1,[]);

            dtheta_i_ii = active_responses;
            dtheta_i_jj = ...
                reshape(repmat(dtheta_i(this.predict.G_i(this.predict.active.u_corr_i)),6,2),1,[]);

            dtheta_ij_ii = active_responses;
            dtheta_ij_jj = reshape(repmat(dtheta_ij(this.predict.G_ij(this.predict.active.u_corr_i)),6,2),1,[]);

            Jpat = ...
                sparse([dq_ii dH_ii(:)' dU_ii dti_ii dt_ij_ii ...
                        dtheta_i_ii dtheta_ij_ii], ...
                       [dq_jj dH_jj(:)' dU_jj dti_jj dt_ij_jj ...
                        dtheta_i_jj dtheta_ij_jj],1,M,N);
        end
        
        function err = calc_err(this,dz)
            if nargin < 2
                dz = this.dz0;
            end
            err = MleImpl.errfun(dz,this);
        end
                
        function [model,stats] = fit(this,varargin)
            cfg.rho = 'l2';
            cfg = cmp_argparse(cfg,varargin{:});
            cfg.rho = str2func(cfg.rho);
            
            l2_0 = this.calc_err();
            sigma = 1.4826*mad(l2_0);
            rho_0 = cfg.rho(this.calc_err(),sigma);
            Jpat = this.make_Jpat();

            options = optimoptions('lsqnonlin','Display','iter', ...
                                   'MaxIter',30,'JacobPattern', Jpat);
            [dz,resnorm,rho] = ...
                lsqnonlin(@(dz) cfg.rho(MleImpl.errfun(dz,this),sigma), ...
                          this.dz0,[],[],options);

            l2 = this.calc_err(dz);

            model = this.model0;

            [model.Hinf,model.q, ...
             model.U,model.Rt_i,model.Rt_ij] = this.unpack(dz);
            
            stats = struct('dz', dz, ...
                           'resnorm', resnorm, ...
                           'err0', l2_0, ...
                           'err', l2, ...
                           'l2_0', l2_0.^2, ...
                           'l2', l2.^2, ...
                           'rho_0', rho_0.^2, ...
                           'rho', rho.^2);
        end
    end
end
