function [t, stmChi] = fastIntForwardDynamics(fhCtrlTrqs, tspan, stvChi_0, robot_model, robot_config, ode_opt)
    if ~isa(fhCtrlTrqs, 'function_handle')
        error('fastIntForwardDynamics: %s', WBM.wbmErrorMsg.WRONG_DATA_TYPE)
    end
    if ( (robot_config.stvLen == 0) || (robot_config.nCstrs == 0) )
        error('fastIntForwardDynamics: %s', WBM.wbmErrorMsg.VALUE_IS_ZERO);
    end
    if ( isempty(robot_model.vfrict_coeff) || isempty(robot_model.cfrict_coeff) )
        error('fastIntForwardDynamics: %s', WBM.wbmErrorMsg.EMPTY_VECTOR);
    end

    if ~exist('ode_opt', 'var')
        % setup the default error tolerances ...
        ode_opt = odeset('RelTol', 1e-2, 'AbsTol', 1e-4);
    end

    fhFwdDyn    = @(t, chi)WBM.utilities.fastForwardDynamics(t, chi, fhCtrlTrqs, robot_model, robot_config);
    [t, stmChi] = ode15s(fhFwdDyn, tspan, stvChi_0, ode_opt); % ODE-Solver
end