classdef (Abstract) IWBM < handle
    properties(Abstract, Dependent)
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

    methods(Abstract)
        initRobot(obj, robot_wbm)

        initRobotFcn(obj, fhInitRobotWBM, wf2fixLnk)

        initBaseRobotParams(obj, robot_params)

        [vqT_b, q_j, v_b, dq_j] = getState(obj)

        stFltb = getFloatingBaseState(obj)

        ddq_j = jointAccelerations(obj, tau, q_j, dq_j, stFltb)

        ddq_j = jointAccelerationsFPC(obj, tau, q_j, dq_j, stFltb) % FPC ... feet pose correction

        ddq_j = jointAccelerationsFHPC(obj, tau, fe_h, q_j, dq_j, stFltb) % FHPC  ... feet & hand pose correction

        ddq_j = jointAccelerationsFHPCPL(obj, tau, fhTotCWrench, f_cp, q_j, dq_j, stFltb) % FHPCPL  ... feet & hand pose correction with payload

        ac_h = handAccelerations(obj, tau, q_j, dq_j, stFltb)

        vc_h = handVelocities(obj, q_j, dq_j, stFltb)

        c_qv = coriolisForces(obj, q_j, dq_j, stFltb)

        tau_fr = frictionForces(obj, dq_j)

        c_qv = generalizedBiasForces(obj, q_j, dq_j, stFltb)

        tau_gen = generalizedForces(obj, Je_t, f_e, q_j, dq_j, stFltb)

        g_q = gravityForces(obj, q_j, stFltb)

        tau_j = inverseDyn(obj, q_j, dq_j, ddq_j, dv_b, stFltb)

        tau_j = inverseHybridDyn(obj, q_j, dq_j, ddq_j, stFltb)

        [t, stmChi] = forwardDyn(obj, tspan, fhTrqControl, stvChi_0, ode_opt, varargin)

        visualizeForwardDyn(obj, stmChi, sim_tstep, vis_ctrl)

        wf_H_lnk = forwardKin(obj, lnk_name, q_j, stFltb)

        wf_H_lnk = linkFrame(obj, lnk_name, q_j, stFltb) % link transformation matrix

        wf_H_tt = toolFrame(obj, t_idx, q_j, stFltb) % tool-tip transformation matrix

        M = massMatrix(obj, q_j, stFltb)

        h_c = centroidalMomentum(obj, q_j, dq_j, stFltb)

        [M, c_qv, h_c] = wholeBodyDyn(obj, q_j, dq_j, stFltb)

        wf_J_lnk = jacobian(obj, lnk_name, q_j, stFltb)

        djdq_lnk = jacobianDot(obj, lnk_name, q_j, dq_j, stFltb)

        wf_J_tt = jacobianTool(obj, t_idx, q_j, stFltb) % Jacobian matrix in tool-frame

        payload(obj, pl_data)

        f_pl = payloadForces(obj, fhTotCWrench, f_cp, tau, q_j, dq_j, stFltb)

        resv = islimit(obj, q_j)

        dispParams(obj, prec)

    end
end
