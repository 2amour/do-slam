function generateMeasurements(self,config,sensorEnvironment)
%GENERATEMEASUREMENTS Summary of this function goes here
%   Detailed explanation goes here

%% 1. Initialise variables
% load frequently accessed variables from config
graphFileFolderPath = strcat(config.folderPath,config.sep,'GraphFiles',config.sep,config.graphFileFolderName);
if ~exist(graphFileFolderPath,'dir')
    mkdir(graphFileFolderPath)
end
gtFileID = fopen(strcat(config.folderPath,config.sep,'GraphFiles',...
                 config.sep,config.graphFileFolderName,config.sep,config.groundTruthFileName),'w');
mFileID  = fopen(strcat(config.folderPath,config.sep,'GraphFiles',...
                 config.sep,config.graphFileFolderName,config.sep,config.measurementsFileName),'w');
t      = config.t;
nSteps = numel(t);

% indexing variables
vertexCount         = 0;
cameraVertexIndexes = zeros(1,nSteps);
sensorTrajectory    = self.get('trajectory');
pointVisibility     = zeros(sensorEnvironment.nPoints,nSteps);

%% 2. Loop over timestep, simulate observations, write to graph file
for i = 1:nSteps
    %*Write to several graph files at once -> no need to
    %preallocate & store noise

    %sensor @ time t
    currentSensorPose = self.get('GP_Pose',t(i));
    vertexCount = vertexCount + 1;
    cameraVertexIndexes(i) = vertexCount;
    %WRITE VERTEX TO FILE
    
    %odometry
    if i> 1
        prevSensorPose = self.get('GP_Pose',t(i-1));
        poseRelative = currentSensorPose.AbsoluteToRelativePose(prevSensorPose);
        
        %WRITE EDGE TO FILE
        %label = config.posePoseEdgeLabel
        %value = poseRelative.get('logSE3Pose'/'R3xso3Pose')
        %index1 = cameraVertexIndexes(i-1)
        %index2 = cameraVertexIndexes(i)
    end
    
    %point observations
    for j = 1:sensorEnvironment.nPoints
        jPoint = sensorEnvironment.get('points',j);
        jRelativePoint = jPoint.get('trajectory').AbsoluteToRelativePoint(sensorTrajectory,t(i));
        S2xRRelativePosition = jRelativePoint.get('S2xRPosition');
        %check if az,el,r within limits
        if (S2xRRelativePosition(1) >= self.fieldOfView(1)) && (S2xRRelativePosition(1) <= self.fieldOfView(2)) &&...
           (S2xRRelativePosition(2) >= self.fieldOfView(3)) && (S2xRRelativePosition(2) <= self.fieldOfView(4)) &&...   
           (S2xRRelativePosition(3) >= self.fieldOfView(5)) && (S2xRRelativePosition(3) <= self.fieldOfView(6))
            %point visibility
            pointVisibility(j,i) = 1;
            %check if point observed before
            if isempty(jPoint.get('vertexIndex'))
                vertexCount = vertexCount + 1;
                jPoint.set('vertexIndex',vertexCount); %*Passed by reference - changes sensorEnvironment 
                %WRITE VERTEX TO FILE
            end
            %WRITE EDGE TO FILE
            %label = config.posePointEdgeLabel
            %value = jRelativePoint.get('R3Position')
            %index1 = cameraVertexIndexes(i)
            %index2 = jPoint.get('vertexIndex')
        end
    end
    
    %point-plane observations
    for j = 1:sensorEnvironment.nObjects
        jObject = sensorEnvironment.get('objects',j);
        jPointVisibility = pointVisibility(jObject.get('pointIndexes'),i);
        jNVisiblePoints  = sum(jPointVisibility);
        jVisiblePointIndexes = find(jPointVisibility);
        %check visibility
        if jNVisibilePoints > 3
            if isempty(jObject.get('vertexIndex'))
                vertexCount = vertexCount + 1;
                jObject.set('vertexIndex',vertexCount); %*Passed by reference - changes sensorEnvironment 
                %WRITE VERTEX TO FILE
            end
        end
        for k = 1:jNVisiblePoints
            %WRITE EDGE TO FILE
            %label = config.pointPlaneEdgeLabel
            %value = 0;
            %index1 = sensorEnvironment.get('points',jVisiblePointIndexes(k)).get('vertexIndex')
            %index2 = jObject.get('vertexIndex')
        end
        
    end
    
end

fclose(gtFileID);
fclose(mFileID);


end
