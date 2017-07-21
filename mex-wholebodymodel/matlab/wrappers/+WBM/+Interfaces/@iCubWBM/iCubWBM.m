classdef iCubWBM < WBM.Interfaces.IWBM
    properties(Dependent)
        % public properties for fast get/set methods:
        robot_name@char
        robot_model@char
        robot_manuf@char
        robot_params@WBM.wbmBaseRobotParams
        sim_config@WBM.absSimConfig
        base_link@char
        base_tform@double matrix
        tool_tform@double matrix
        feet_conf@struct
        hand_conf@struct
        gravity@double    vector
        jlimits@struct
        ndof@uint16       scalar
    end

    properties(Access = protected)
        mwbm_icub@WBM.WBM
        mrobot_name@char
        mrobot_model@char
        mrobot_manuf@char
        msim_config@WBM.absSimConfig
        mbase_tform@double matrix
        mtool_tform@double matrix
        mfeet_conf@struct
        mhand_conf@struct
    end

    methods
        % Constructor:
        function obj = iCubWBM(robot_model, robot_config, wf2fixLnk)
            switch nargin
                % initialize the mex-WholeBodyModel for the iCub-Robot:
                case 3
                    obj.mwbm_icub = WBM.WBM(robot_model, robot_config, wf2fixLnk);
                case 2
                    obj.mwbm_icub = WBM.WBM(robot_model, robot_config);
                otherwise
                    error('iCubWBM::iCubWBM: %s', WBM.wbmErrorMsg.WRONG_NARGIN);
            end
            obj.mrobot_name  = 'iCub';
            obj.mrobot_manuf = 'Istituto Italiano di Tecnologia (IIT) - Genoa, Italy.';

            obj.mbase_tform = eye(4,4);
            obj.mtool_tform = obj.mbase_tform;
        end

        function initRobot(obj, robot_wbm)
            if ~isa(robot_wbm, 'WBM.WBM')
                error('iCubWBM::initRobot: %s', WBM.wbmErrorMsg.WRONG_DATA_TYPE);
            end
            obj.mwbm_icub = copy(robot_wbm);
        end

        function initRobotFcn(obj, fhInitRobotWBM, wf2fixLnk)
            if ~isa(fhInitRobotWBM, 'function_handle')
                error('iCubWBM::initRobotFcn: %s', WBM.wbmErrorMsg.WRONG_DATA_TYPE)
            end

            if ~exist('wf2fixLnk', 'var')
                wf2fixLnk = true;
            end
            obj.mwbm_icub = fhInitRobotWBM(wf2fixLnk);
        end

        function initBaseRobotParams(obj, robot_params)
            if ~isa(robot_params, 'WBM.wbmBaseRobotParams')
                error('iCubWBM::initBaseRobotParams: %s', WBM.wbmErrorMsg.WRONG_DATA_TYPE);
            end
            obj.mwbm_icub = WBM.WBM(robot_params.model, robot_params.config, robot_params.wf2fixLnk);
        end

        function delete(obj)
            delete(obj);
        end

        function [vqT_b, q_j, v_b, dq_j] = getState(obj)
            [vqT_b, q_j, v_b, dq_j] = obj.mwbm_icub.getState();
        end

        function stFltb = getFloatingBaseState(obj)
            stFltb = obj.mwbm_icub.getFloatingBaseState();
        end

        function ddq_j = jointAccelerations(obj, tau, q_j, dq_j, stFltb)
            if (nargin == 4) % much faster than the exist-function
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            ddq_j = obj.mwbm_icub.jointAcceleration(tau, stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function ddq_j = jointAccelerationsFPC(obj, tau, q_j, dq_j, stFltb) % FPC ... feet pose correction
            if (nargin == 5)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            ac_0  = obj.mwbm_icub.zeroCtcAcc(obj.mfeet_conf);
            ddq_j = obj.mwbm_icub.jointAccelerationsFPC(obj.mfeet_conf, tau, ac_0, stFltb.wf_R_b, ...
                                                        stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function ddq_j = jointAccelerationsFHPC(obj, tau, fe_h, q_j, dq_j, stFltb) % FHPC  ... feet & hand pose correction
            if (nargin == 5)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            ddq_j = obj.mwbm_icub.jointAccelerationsFHPC(obj.mfeet_conf, obj.mhand_conf, tau, fe_h, ...
                                                         stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function ddq_j = jointAccelerationsFHPCPL(obj, tau, fhTotCWrench, f_cp, q_j, dq_j, stFltb) % FHPCPL  ... feet & hand pose correction with payload
            if (nargin == 6)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            ddq_j = obj.mwbm_icub.jointAccelerationsFHPCPL(obj.mfeet_conf, obj.mhand_conf, tau, fhTotCWrench, f_cp, ...
                                                           stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function ac_h = handAccelerations(obj, tau, q_j, dq_j, stFltb)
            if (nargin == 4)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            nu   = vertcat(stFltb.v_b, dq_j); % mixed generalized velocity
            ac_0 = obj.mwbm_icub.zeroCtcAcc(obj.mfeet_conf);
            ac_h = obj.mwbm_icub.handAccelerations(obj.mfeet_conf, obj.mhand_conf, tau, ac_0, stFltb.wf_R_b, ...
                                                   stFltb.wf_p_b, q_j, dq_j, stFltb.v_b, nu);
        end

        function vc_h = handVelocities(obj, q_j, dq_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            vc_h = obj.mwbm_icub.handVelocities(obj.mhand_conf, stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function c_qv = coriolisForces(obj, q_j, dq_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            c_qv = obj.mwbm_icub.coriolisBiasForces(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function tau_fr = frictionForces(obj, dq_j)
            tau_fr = obj.mwbm_icub.frictionForces(dq_j);
        end

        function c_qv = generalizedBiasForces(obj, q_j, dq_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            c_qv = obj.mwbm_icub.generalizedBiasForces(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function tau_gen = generalizedForces(obj, q_j, dq_j, Je_t, f_e, stFltb)
            if (nargin == 5)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            tau_gen = obj.mwbm_icub.generalizedForces(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b, Je_t, f_e);
        end

        function g_q = gravityForces(obj, q_j, stFltb)
            if (nargin == 2)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            g_q = obj.mwbm_icub.gravityForces(stFltb.wf_R_b, stFltb.wf_p_b, q_j);
        end

        function tau_j = inverseDyn(obj, q_j, dq_j, ddq_j, dv_b, stFltb)
            if (nargin == 5)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            tau_j = obj.mwbm_icub.inverseDynamics(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, ...
                                                  stFltb.v_b, ddq_j, dv_b);
        end

        function tau_j = inverseHybridDyn(obj, q_j, dq_j, ddq_j, stFltb)
            if (nargin == 4)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            tau_j = obj.mwbm_icub.inverseDynamics(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, ...
                                                  stFltb.v_b, ddq_j);
        end

        function [t, stmChi] = forwardDyn(obj, tspan, fhTrqControl, stvChi_0, ode_opt, varargin)
            f_cfg = ~isempty(obj.mfeet_conf);
            h_cfg = ~isempty(obj.mhand_conf);

            if (f_cfg && h_cfg)
                switch nargin
                    case 8
                        % forward dynamics with feet and hand pose correction and payload:
                        % fhTotCWrench = varargin{1}
                        % f_cp         = varargin{2}
                        % ac_f         = varargin{3}
                        [t, stmChi] = obj.mwbm_icub.intForwardDynamicsFHPCPL(tspan, stvChi_0, fhTrqControl, ode_opt, varargin{1,1}, ...
                                                                             obj.mfeet_conf, obj.mhand_conf, varargin{1,2}, varargin{1,3});
                    case 7
                        % forward dynamics with feet and hand pose correction:
                        % fe_h = varargin{1}
                        % ac_f = varargin{2}
                        [t, stmChi] = obj.mwbm_icub.intForwardDynamicsFHPC(tspan, stvChi_0, fhTrqControl, ode_opt, obj.mfeet_conf, ...
                                                                           obj.mhand_conf, varargin{1,2}, varargin{1,3});
                    otherwise
                        error('iCubWBM::forwardDyn: %s', WBM.wbmErrorMsg.WRONG_NARGIN);
                end
            elseif h_cfg
                % only with hand pose correction:
                % fe_h = varargin{1}
                % ac_f = varargin{2}
                [t, stmChi] = obj.mwbm_icub.intForwardDynamicsHPC(tspan, stvChi_0, fhTrqControl, ode_opt, ...
                                                                  obj.mhand_conf, varargin{1,1}, varargin{1,2});
            elseif f_cfg
                % only with feet pose correction:
                % ac_f = varargin{1}
                [t, stmChi] = obj.mwbm_icub.intForwardDynamicsFPC(tspan, stvChi_0, fhTrqControl, ode_opt, ...
                                                                  obj.mfeet_conf, varargin{1,1});
            else
                % simple forward dynamics without any pose corrections:
                [t, stmChi] = obj.mwbm_icub.intForwardDynamics(tspan, stvChi_0, fhTrqControl, ode_opt);
            end
        end

        function visualizeForwardDyn(obj, stmChi, sim_tstep, vis_ctrl)
            pos_out = obj.mwbm_icub.getPositionsData(stmChi);
            obj.mwbm_icub.visualizeForwardDynamics(pos_out, obj.msim_config, sim_tstep, vis_ctrl);
        end

        function wf_H_lnk = forwardKin(obj, lnk_name, q_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            vqT_lnk  = obj.mwbm_icub.forwardKinematics(stFltb.wf_R_b, stFltb.wf_p_b, q_j, lnk_name);
            wf_H_lnk = WBM.utilities.tfms.frame2tform(vqT_lnk);
        end

        function wf_H_lnk = linkFrame(obj, lnk_name, q_j, stFltb) % link transformation matrix
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            wf_H_lnk = obj.mwbm_icub.transformationMatrix(stFltb.wf_R_b, stFltb.wf_p_b, q_j, lnk_name);
        end

        function wf_H_tt = toolFrame(obj, t_idx, q_j, stFltb) % tool-tip transformation matrix
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            wf_H_tt = obj.mwbm_icub.toolFrame(stFltb.wf_R_b, stFltb.wf_p_b, q_j, t_idx);
        end

        function M = massMatrix(obj, q_j, stFltb)
            if (nargin == 2)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            M = obj.mwbm_icub.massMatrix(stFltb.wf_R_b, stFltb.wf_p_b, q_j);
        end

        function h_c = centroidalMomentum(obj, q_j, dq_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            h_c = obj.mwbm_icub.centroidalMomentum(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function [M, c_qv, h_c] = wholeBodyDyn(obj, q_j, dq_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            [M, c_qv, h_c] = obj.mwbm_icub.wholeBodyDynamics(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b);
        end

        function wf_J_lnk = jacobian(obj, lnk_name, q_j, stFltb)
            if (nargin == 3)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            wf_J_lnk = obj.mwbm_icub.jacobian(stFltb.wf_R_b, stFltb.wf_p_b, q_j, lnk_name);
        end

        function djdq_lnk = jacobianDot(obj, lnk_name, q_j, dq_j, stFltb)
            if (nargin == 4)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            djdq_lnk = obj.mwbm_icub.dJdq(stFltb.wf_R_b, stFltb.wf_p_b, q_j, dq_j, stFltb.v_b, lnk_name);
        end

        function wf_J_tt = jacobianTool(obj, q_j, stFltb) % Jacobian matrix in tool-frame
            if (nargin == 2)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            % compute the Jacobian of the tool-tip:
            % use the default tool (1st element of the tool list)
            wf_J_tt = obj.mwbm_icub.jacobianTool(stFltb.wf_R_b, stFltb.wf_p_b, q_j, 1);
        end

        function payload(obj, pl_data)
            obj.mwbm_icub.setLinkPayloads(pl_data);
        end

        function f_pl = payloadForces(obj, fhTotCWrench, f_cp, tau, q_j, dq_j, stFltb)
            if (nargin == 6)
                stFltb = obj.mwbm_icub.getFloatingBaseState();
            end
            nu    = vertcat(stFltb.v_b, dq_j); % mixed generalized velocity
            acf_0 = obj.mwbm_icub.zeroCtcAcc(obj.mfeet_conf);
            [ac_h, a_prms] = obj.mwbm_icub.handAccelerations(obj.mfeet_conf, obj.mhand_conf, tau, acf_0, stFltb.wf_R_b, ...
                                                             stFltb.wf_p_b, q_j, dq_j, stFltb.v_b, nu);
            v_pl = a_prms.Jc_h * dq_j;
            a_pl = ac_h;
            % calculate the payload forces of the hands:
            f_pl = obj.mwbm_icub.handPayloadForces(obj.mhand_conf, fhTotCWrench, f_cp, v_pl, a_pl);
        end

        function resv = islimit(obj, q_j)
            resv = obj.mwbm_icub.isJointLimit(q_j);
        end

        function dispParams(obj, prec)
            if (nargin == 2)
               obj.mwbm_icub.dispModel(prec);
               obj.mwbm_icub.dispConfig(prec);
               return
            end
            % else, display the values with the default precision ...
            obj.mwbm_icub.dispModel();
            obj.mwbm_icub.dispConfig();
        end

        function set.robot_name(obj, robot_name)
            obj.mrobot_name = robot_name;
        end

        function robot_name = get.robot_name(obj)
            robot_name = sprintf('%s, model: %s', obj.mrobot_name, obj.robot_model);
        end

        function set.robot_model(obj, model_name)
            if (nargin == 1)
                if ~isempty(obj.mwbm_icub)
                    % get the model name from WBM-object of the iCub ...
                    [~,model_name, ext] = fileparts(obj.mwbm_icub.robot_model.urdfRobot);
                    obj.mrobot_model = strcat(model_name, ext);
                    return
                end
            end
            % else ...
            obj.mrobot_model = model_name;
        end

        function model_name = get.robot_model(obj)
            if isempty(obj.mrobot_model)
                model_name = 'unknown'; return
            end
            % else ...
            model_name = obj.mrobot_model;
        end

        function set.robot_manuf(obj, manuf)
            obj.mrobot_manuf = manuf;
        end

        function robot_manuf = get.robot_manuf(obj)
            if isempty(obj.mrobot_manuf)
                robot_manuf = 'unknown'; return
            end
            % else ...
            robot_manuf = obj.mrobot_manuf;
        end

        function robot_params = get.robot_params(obj)
            robot_params = obj.mwbm_icub.robot_params;
        end

        function set.sim_config(obj, sim_config)
            obj.msim_config = obj.mwbm_icub.setupSimulation(sim_config);
        end

        function sim_config = get.sim_config(obj)
            sim_config = obj.msim_config;
        end

        function set.base_link(obj, rlnk_name)
            if isempty(rlnk_name)
                error('iCubWBM::set.base_link: %s', WBM.wbmErrorMsg.EMPTY_STRING);
            end
            [~,q_j,~,~] = obj.mwbm_icub.getState();
            % update the fixed link ...
            obj.mwbm_icub.fixed_link = rlnk_name;
            % calculate the the position and orientation of the new base link
            % (fixed link) to the world frame (WF) and set the WF at this new base:
            [wf_p_b, wf_R_b] = obj.mwbm_icub.getWorldFrameFromFixLnk(rlnk_name, q_j);
            obj.mwbm_icub.setWorldFrame(wf_R_b, wf_p_b);
        end

        function rlnk_name = get.base_link(obj)
            rlnk_name = obj.mwbm_icub.fixed_link;
        end

        function set.base_tform(obj, wf_H_b)
            if (nargin == 1)
                % get the initial base transformation matrix
                % from the WBM-object of the iCub ...
                wf_R_b = obj.mwbm_icub.init_wf_R_b;
                wf_p_b = obj.mwbm_icub.init_wf_p_b;
                obj.mbase_tform = WBM.utilities.tfms.posRotm2tform(wf_p_b, wf_R_b);
                return
            end
            % else, update the base transformation ...
            if ~WBM.utilities.isHomog(wf_H_b)
                error('iCubWBM::set.base_tform: %s', WBM.wbmErrorMsg.NOT_HOMOG_MAT);
            end
            [wf_p_b, wf_R_b] = WBM.utilities.tfms.tform2posRotm(wf_H_b);
            obj.mwbm_icub.setInitWorldFrame(wf_R_b, wf_p_b);
            obj.mbase_tform = wf_H_b;
        end

        function wf_H_b = get.base_tform(obj)
            wf_H_b = obj.mbase_tform;
        end

        function set.tool_tform(obj, ee_H_tt)
            if (nargin == 1)
                % try to get the tool-tip transformation matrix
                % from the WBM-object of the iCub ...
                [tool_lnks, nTools] = obj.mwbm_icub.getToolLinks();
                if (nTools > 0)
                    % use the default tool (is always the first element of the list)
                    obj.mtool_tform = WBM.utilities.tfms.frame2tform(tool_lnks(1,1).ee_vqT_tt);
                else
                    obj.mtool_tform = eye(4,4);
                end
                return
            end
            % else, update the transformation matrix of the default tool-tip ...
            if ~WBM.utilities.isHomog(ee_H_tt)
                error('iCubWBM::set.tool_tform: %s', WBM.wbmErrorMsg.NOT_HOMOG_MAT);
            end
            ee_vqT_tt = WBM.utilities.tfms.tform2frame(ee_H_tt);
            obj.mwbm_icub.updateToolFrame(ee_vqT_tt, 1);
            obj.mtool_tform = ee_H_tt;
        end

        function ee_H_tt = get.tool_tform(obj)
            ee_H_tt = obj.mtool_tform;
        end

        function set.feet_conf(obj, feet_conf)
            obj.mfeet_conf = feet_conf;
        end

        function feet_conf = get.feet_conf(obj)
            feet_conf = obj.mfeet_conf;
        end

        function set.hand_conf(obj, hand_conf)
            obj.mhand_conf = hand_conf;
        end

        function hand_conf = get.hand_conf(obj)
            hand_conf = obj.mhand_conf;
        end

        function set.gravity(obj, g_wf)
            obj.mwbm_icub.g_wf = g_wf;
            obj.mwbm_icub.setInitWorldFrame();
        end

        function g_wf = get.gravity(obj)
            g_wf = obj.mwbm_icub.g_wf;
        end

        function jlmts = get.jlimits(obj)
            jlmts = obj.mwbm_icub.joint_limits;
        end

        function set.ndof(obj, ndof)
            obj.mwbm_icub.ndof = ndof;
        end

        function ndof = get.ndof(obj)
            if isempty(obj.mwbm_icub)
                ndof = 0; return
            end
            ndof = obj.mwbm_icub.ndof;
        end

    end
end
