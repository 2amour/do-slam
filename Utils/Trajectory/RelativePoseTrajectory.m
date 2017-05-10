classdef RelativePoseTrajectory < PoseTrajectory
    %RELATIVEPOSETRAJECTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    %% 1. Properties
    properties(GetAccess = 'protected', SetAccess = 'protected')
        referenceTrajectory
        relativePose
    end
    
    %% 2. Methods
    % Constructor
    methods(Access = public)
        function self = RelativePoseTrajectory(referenceTrajectory,relativePose)
            self.referenceTrajectory = referenceTrajectory;
            self.relativePose        = relativePose;
        end
    end
    
    % Get & Set
    methods(Access = public)
        function value = getSwitch(self,property,varargin)
            switch property
                case 'GP_Pose'
                    t             = varargin{1};
                    referencePose = self.referenceTrajectory.get('GP_Pose',t);
                    value         = self.relativePose.RelativeToAbsolutePose(referencePose);
                case {'R3xso3Pose','logSE3Pose','R3xso3Position','logSE3Position','axisAngle','R'}
                    t             = varargin{1};
                    referencePose = self.referenceTrajectory.get('GP_Pose',t);
                    pose          = self.relativePose.RelativeToAbsolutePose(referencePose);
                    value         = pose.get(property);
                case 'static'
                    value = self.referenceTrajectory.get('static');
                otherwise 
                    error('Error: invalid property')
            end
        end
        
        function self = setSwitch(self,property,value,varargin)
            self.(property) = value;
        end
        
    end
    
end
