function controlParam  = runController(gains,trajectory,DYNAMICS,FORKINEMATICS,CONFIG,STATE)
%RUNCONTROLLER  is the initialization function for iCub balancing controllers
%               in Matlab.
%
%               controlParam  = RUNCONTROLLER(gains,trajectory,dynamics,
%               forKinematics,config,state) takes as input the control gains,
%               the joint reference trajectory, all the configuration parameters
%               and the robot dynamics, forward kinematics and state. The output
%               is the structure CONTROLPARAM which contains the control torques
%               TAU, the contact forces FC and other parameters for visualization.
%
% Author : Gabriele Nava (gabriele.nava@iit.it)
% Genova, May 2016

% ------------Initialization----------------
%% Feet correction gains
KCorrPos              = gains.CorrPosFeet;
KCorrVel              = 2*sqrt(KCorrPos);

%% Config parameters
ndof                  = CONFIG.ndof;
feet_on_ground        = CONFIG.feet_on_ground;
initForKinematics     = CONFIG.initForKinematics;
S                     = [zeros(6,ndof);
                         eye(ndof,ndof)];

%% Dynamics
dJcNu                 = DYNAMICS.dJcNu;
M                     = DYNAMICS.M;
Jc                    = DYNAMICS.Jc;
h                     = DYNAMICS.h;
JcMinv                = Jc/M;
JcMinvS               = JcMinv*S;

%% Forward Kinematics
VelFeet               = FORKINEMATICS.VelFeet;
TLfoot                = FORKINEMATICS.TLfoot;
TRfoot                = FORKINEMATICS.TRfoot;
RFootPoseEul          = FORKINEMATICS.RFootPoseEul;
LFootPoseEul          = FORKINEMATICS.LFootPoseEul;
DeltaPoseRFoot        = TRfoot*(RFootPoseEul-initForKinematics.RFootPoseEul);
DeltaPoseLFoot        = TLfoot*(LFootPoseEul-initForKinematics.LFootPoseEul);

%% BALANCING CONTROLLERS
% Centroidal coordinates transformation
centroidalDynamics    = centroidalConversion(DYNAMICS,FORKINEMATICS,STATE);
controlParam          = jointSpaceController(CONFIG,gains,trajectory,centroidalDynamics,STATE);

%% Feet pose correction
% this will avoid numerical errors during the forward dynamics integration
if     feet_on_ground(1) == 1 && feet_on_ground(2) == 0
    
    DeltaPoseFeet    = DeltaPoseLFoot;
    
elseif feet_on_ground(1) == 0 && feet_on_ground(2) == 1
    
    DeltaPoseFeet    = DeltaPoseRFoot;
    
elseif feet_on_ground(1) == 1 && feet_on_ground(2) == 1
    
    DeltaPoseFeet    = [DeltaPoseLFoot;DeltaPoseRFoot];
end

%% REAL CONTACT FORCES COMPUTATION
controlParam.fc  = (JcMinv*transpose(Jc))\(JcMinv*h -JcMinvS*controlParam.tau -dJcNu -KCorrVel.*VelFeet-KCorrPos.*DeltaPoseFeet);

end
