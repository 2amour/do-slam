classdef PositionTrajectory < Trajectory
    %POSITIONTRAJECTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    %% 1. Properties
    properties
    end
    
    %% 2. Methods
    % Constructor
    methods(Access = public) %set to private later??
        function self = PositionTrajectory(parameterisation,mode,varargin)
            switch nargin
                case 0
                    %allows pre-allocation
                otherwise
                    self.parameterisation = parameterisation;
                    assert(strcmp(parameterisation,'R3'),'Error: Only R3 positions trajectories implemented.')
                    switch mode
                        case 'waypoints'
                            waypoints = varargin{1};
                            tFit      = varargin{2};
                            fitType   = varargin{3};
                            self.fitTrajectory(waypoints,tFit,fitType);
                        case 'discrete'
                            self.dataPoints = varargin{1};
                        case 'continuous'
                            self.model = varargin{1};
                    end
            end
        end
        
    end
    
    % Fitting
    methods(Access = private)
        function self = fitTrajectory(self,waypoints,tFit,fitType)
            %models
            fX = fit(waypoints(1,:)',waypoints(2,:)',fitType);
            fY = fit(waypoints(1,:)',waypoints(3,:)',fitType);
            fZ = fit(waypoints(1,:)',waypoints(4,:)',fitType);
            
            %use model to get positions
            positions = zeros(3,numel(tFit));
            positions(1,:) = fX(tFit)';
            positions(2,:) = fY(tFit)';
            positions(3,:) = fZ(tFit)';
            
            %datapoints
            self.dataPoints = [tFit; positions];
        end
    end
    
    % Plotting
    methods(Access = public)
        function plot(self,varargin)
            positions = self.dataPoints(2:4,:);
            
            %plot positions
            plot3(positions(1,:),positions(2,:),positions(3,:),'k.')
            
        end
    end
    
end
