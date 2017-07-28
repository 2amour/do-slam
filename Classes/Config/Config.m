%--------------------------------------------------------------------------
% Author: Montiel Abello - montiel.abello@gmail.com - 23/05/17
% Contributors:
%               Mina Henein -- aded solver related parameters
%--------------------------------------------------------------------------

classdef Config < ArrayGetSet
    %CONFIG is used to store user settings
    %   Properties must be set with the 'set' method
    %   Properties can be accessed with '.' notation instead of the 'get'
    %   method for ease of use.
    %
    %   *Suggestion: rather than each user adding properties only relevant
    %   to their application, subclasses should be created with
    %   non-fundamental properties for specific applications
    
    %% 1. Properties
    properties(GetAccess = 'public', SetAccess = 'protected')
        %array of time values when measurements are made
        t
        
        % rng seed
        rngSeed
        
        % noise model
        noiseModel
        
        %measurement std dev
        stdPosePrior
        stdPointPrior
        stdPosePose
        stdPosePoint
        stdPointPoint
        stdPoint3
        stdPointPlane
        
        %R3xso3 or logSE3
        poseParameterisation
        
        % measurement type for point motion - can be point2Edge, point3Edge,
        % or velocity - ONLY affects the pre-measurements file stage.
        pointMotionMeasurement
        
        % function handles moved to public temporarily
        
        %% TODO: both shouldnt be here!!
        cameraPointParameterisation
        cameraControlInput
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %dimensions
        dimPose
        dimPoint
        
        %plane parameterisation
        planeNormalParameterisation
        
        %constraints
        applyAngleConstraints
        automaticAngleConstraints
        
        %first linearisation point
        startPose
        
        %static assumption
        staticAssumption
        
        %solver settings
        sortVertices
        sortEdges
        processing
        nVerticesThreshold
        nEdgesThreshold
        solveRate
        solverType
        threshold
        maxNormDX
        maxIterations
        
        %graph file labels
        poseVertexLabel
        pointVertexLabel
        planeVertexLabel
        posePoseEdgeLabel
        posePointEdgeLabel
        pointPointEdgeLabel
        point3EdgeLabel
        pointPlaneEdgeLabel
        posePriorEdgeLabel
        angleVertexLabel
        angleEdgeLabel
        distanceVertexLabel
        distanceEdgeLabel
        pointRGBVertexLabel
        pointPointRGBEdgeLabel
        fixedAngleEdgeLabel
        fixedDistanceEdgeLabel
        
        % general settings
        displayProgress
        plotPlanes
        displaySPPARMS
        
        %files
        sep
        folderPath
        savePath
        graphFileFolderName
        groundTruthFileName
        measurementsFileName
        
    end
    
    properties(GetAccess = 'public', SetAccess = 'public')
        absoluteToRelativePoseHandle 
        absoluteToRelativePointHandle
        relativeToAbsolutePoseHandle
        relativeToAbsolutePointHandle
    end
    
    properties (Dependent)
        %measurement covariances
        covPosePrior
        covPointPrior
        covPosePose
        covPosePoint
        covPointPoint
        covPoint3
        covPointPlane
    end
    
    %% 2. Methods
    % Constructor
    methods(Access = public)
        function self = Config()
            self.initPath();
        end
    end
    
    % Get & Set
    methods(Access = public)
        function out = getSwitch(self,property)
            out = self.(property);
        end
        
        function self = setSwitch(self,property,value)
            self.(property) = value;
        end
    end
    
    % Dependent properties
    methods
        function covPosePrior = get.covPosePrior(obj)
            covPosePrior = stdToCovariance(obj.stdPosePrior);
        end
        function covPointPrior = get.covPointPrior(obj)
            covPointPrior = stdToCovariance(obj.stdPointPrior);
        end
        function covPosePose = get.covPosePose(obj)
            covPosePose = stdToCovariance(obj.stdPosePose);
        end
        function covPosePoint = get.covPosePoint(obj)
            covPosePoint = stdToCovariance(obj.stdPosePoint);
        end
        function covPointPoint = get.covPointPoint(obj)
            covPointPoint = stdToCovariance(obj.stdPointPoint);
        end
        function covPoint3 = get.covPoint3(obj)
            covPoint3 = stdToCovariance(obj.stdPoint3);
        end
        function covPointPlane = get.covPointPlane(obj)
            covPointPlane = stdToCovariance(obj.stdPointPlane);
        end
    end
    
    % initialise file stuff
    methods(Access = protected)
        function self = initPath(self)
            if ispc
                self.sep = '\';
            elseif isunix || ismac
                self.sep = '/';
            end
            self.folderPath = pwd;
        end
    end
end