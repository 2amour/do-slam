%--------------------------------------------------------------------------
% Author: Mina Henein - mina.henein@anu.edu.au - 23/06/17
% Contributors:
%--------------------------------------------------------------------------

clear all 
% close all 

%% 1. Config
% construct config & set properties
% CameraConfig is subclass of Config with properties specific to
% applications with a camera
config = RGBDSensorConfig();
% set properties of Config
config.set('rngSeed',1);
config.set('noiseModel','Gaussian');
config.set('poseParameterisation','R3xso3');
config.set('poseVertexLabel'     ,'VERTEX_POSE_LOG_SE3');
config.set('pointVertexLabel'    ,'VERTEX_POINT_3D');
config.set('planeVertexLabel'    ,'VERTEX_PLANE_4D');
config.set('posePoseEdgeLabel'   ,'EDGE_LOG_SE3');
config.set('posePointEdgeLabel'  ,'EDGE_3D');
config.set('pointPlaneEdgeLabel' ,'EDGE_1D');
config.set('graphFileFolderName' ,'Testing');
config.set('groundTruthFileName' ,'groundTruth.graph');
config.set('measurementsFileName','measurements.graph');
config.set('stdPosePrior' ,[0.001,0.001,0.001,pi/600,pi/600,pi/600]');
config.set('stdPointPrior',[0.001,0.001,0.001]');
config.set('stdPosePose'  ,[0.01,0.01,0.01,pi/90,pi/90,pi/90]');
config.set('stdPosePoint' ,[0.02,0.02,0.02]');
config.set('stdPointPlane',0.001);
% set properties of RGBDSensorConfig
config.set('synchronizedData',0)
config.set('rgbImagesFolderName','rgb')
config.set('depthImagesFolderName','depth')
config.set('firstRGBImageName','1341847980.722988.png')
config.set('firstDepthImageName','1341847980.723020.png')
config.set('poseRotationRepresentation','quaternion')

% get time stamps and camera poses
gtFileID = fopen(strcat(config.folderPath,config.sep,'GraphFiles',config.sep,...
    config.graphFileFolderName,config.sep,config.groundTruthFileName));
timeStampedCameraPoseFormat = getGTDataFormat(config);
timeStampedCameraPoses = textscan(gtFileID,timeStampedCameraPoseFormat,'delimiter',' ');
timeStamps = cell2mat(timeStampedCameraPoses(1));
cameraPoses = cell2mat(timeStampedCameraPoses(2,:));
fclose(gtFileID);

% set time in config
t  = timeStamps;
config.set('t',t);


%% 2. Initialise Sensor
sensor = RGBDImageSensor();
syncedData = sensor.synchroniseData(config);
[unique3DPoints,unique3DPointsCameras] = ...
         sensor.extractTrackFeatures(config,firstFrame,increment,lastFrame,method);
sensor.addEnvironment(environment);

cameraTrajectory = zeros(size(t,1),6);
switch config.poseRotationRepresentation
    case 'axis-angle'
        cameraTrajectory = cameraPoses;
    case 'quaternion'
        for i=1:size(t,1)
            cameraTrajectory(i,:) = [cameraPoses(i,1:3),q2a(cameraPoses(i,4:end))];
        end
    case 'rotation matrix'
        for i=1:size(t,1)
            cameraTrajectory(i,:) = [cameraPoses(i,1:3),...
                arot(reshape(cameraPoses(i,4:end),[3,3]))];
        end
end
sensor.addCamera(cameraTrajectory);

%% 3. Generate Environment
if config.rngSeed; rng(config.rngSeed); end;
environment = Environment();
environment.set('environmentPoints',unique3DPoints)

%% 5. Generate Measurements & Save to Graph File
sensor.generateRGBDImageMeasurements(config,unique3DPointsCameras);

%% 6. Plot
figure
viewPoint = [-50,25];
axisLimits = [-1,15,-1,20,-1,10];
title('Environment')
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
view(viewPoint)
axis(axisLimits)
hold on
staticTrajectory1.plot()
staticTrajectory2.plot()
cameraTrajectory.plot(t)
environment.plot(t)
