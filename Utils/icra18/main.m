%icra18 main
% 0- $ roscore

% I- copy to a new terminal
    % $ rostopic echo /odom >> odom.txt
    % $ rostopic echo /mobile_base/sensors/imu_data >> imu.txt
    % $ rosbag play <rosbag_name.bag>
    
% II- run the matlab script getOdomIMUTimeStamp & getOdomIMUMeas.m
getOdomIMUTimeStamp()
[odomMeas,imuMeas] = getOdomIMUMeas();

% III- in a new terminal
    % $ cd catkin_ws/
    % $ catkin_make
    % $ source devel/setup.bash
    % $ rosrun depth_extraction extract_depth_images.py
    % save rgbTimeStamp & depthTimeStamp as .mat 
    % - in a different terminal
        % $ roscore 
        % $ rosbag play <rosbag_name.bag>

% IV- sunchronise Data
load('rgbTimeStamp');
rgbTimeStamp = rgbTimeStamp(3:30,1);
load('odomTimeStamp');
load('imuTimeStamp');
load('GTCameraPoseTimeStamp');
load('GTObj1PoseTimeStamp');
load('GTObj2PoseTimeStamp');
synchronisedData = synchroniseROSVICONData(rgbTimeStamp,odomTimeStamp,imuTimeStamp,...
    GTCameraPoseTimeStamp,GTObj1PoseTimeStamp,GTObj2PoseTimeStamp);
save('synchronisedData','synchronisedData');

% V- write odometry measurements
writeOdomMeas(odomMeas, imuMeas, synchronisedData)
% writeOdomMeas2() % obtained from GT data + noise

% VI-
%% GT & Measurements Graph Files
VICONFilePath = '/home/mina/Downloads/icra18/VICON/';
robotGTPoses = getVICONGroundtruth(VICONFilePath,'robot.txt');
obj1GTPoses = getVICONGroundtruth(VICONFilePath,'obj1.txt');
obj2GTPoses = getVICONGroundtruth(VICONFilePath,'obj2.txt');

writeVICONGroundtruth('robot',robotGTPoses,synchronisedData)
writeVICONGroundtruth('obj1',obj1GTPoses,synchronisedData)
writeVICONGroundtruth('obj2',obj2GTPoses,synchronisedData)

rgbImagesPath =  '/home/mina/Downloads/icra18/images/rgb/';
depthImagesPath =  '/home/mina/Downloads//icra18/images/depth/';
K_Cam = [526.37013657, 0.00000000  , 313.68782938;
         0.00000000  , 526.37013657, 259.01834898;
         0.00000000  , 0.00000000  , 1.00000000 ];
     
[pointsMeasurements,pointsLabels,pointsTurtlebotID,pointsCameras] = ...
    manualLandmarkExtraction(rgbImagesPath,depthImagesPath, K_Cam);
pointsMeasurements = reshape(pointsMeasurements,[3,size(pointsMeasurements,1)/3])';
save('pointsMeasurements','pointsMeasurements');
save('pointsLabels','pointsLabels');
save('pointsTurtlebotID','pointsTurtlebotID');
save('pointsCameras','pointsCameras');
writeLandmarkMeas(pointsMeasurements,pointsLabels,pointsCameras)

filePath = '/home/mina/workspace/src/Git/do-slam/Utils/icra18/';
unique3DPoints = extractUnique3DPoints(filePath);
writeGroundtruthGraphFile(filePath,unique3DPoints)
writeMeasurementsGraphFile(filePath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VII-
config = CameraConfig();
setAppConfig(config); % copy same settings for error Analysis
config.set('std2PointsSE3Motion', [0.1,0.1,0.1]');
config.set('groundTruthFileName','icra18GT_GraphFile2.graph');
config.set('measurementsFileName','icra18Measurement_GraphFile2.graph');

obj1FilePath = '/home/mina/workspace/src/Git/do-slam/Utils/icra18/obj1Groundtruth.txt';
constantSE3Object1Motion = getSE3MotionVertexValue(obj1FilePath);
obj2FilePath = '/home/mina/workspace/src/Git/do-slam/Utils/icra18/obj2Groundtruth.txt';
constantSE3Object2Motion = getSE3MotionVertexValue(obj2FilePath);
constantSE3ObjectMotion = [constantSE3Object1Motion,...
    constantSE3Object2Motion];
writeDataAssociationVerticesEdges(config,constantSE3ObjectMotion);

% VIII-
groundTruthCell  = graphFileToCell(config,config.groundTruthFileName);
measurementsCell = graphFileToCell(config,config.measurementsFileName);

% IX-
timeStart = tic;
graph0 = Graph();
solver = graph0.process(config,measurementsCell,groundTruthCell);
solverEnd = solver(end);
totalTime = toc(timeStart);
fprintf('\nTotal time solving: %f\n',totalTime)

graph0  = solverEnd.graphs(1);
graphN  = solverEnd.graphs(end);
fprintf('\nChi-squared error: %f\n',solverEnd.systems(end).chiSquaredError)
graphN.saveGraphFile(config,'icra18_results2.graph');

% X- Error analysis
graphGT = Graph(config,groundTruthCell);
results = errorAnalysis(config,graphGT,graphN);

% XI- Plot
figure
subplot(1,2,1)
spy(solverEnd.systems(end).A)
subplot(1,2,2)
spy(solverEnd.systems(end).H)

h = figure; 
xlabel('x')
ylabel('y')
zlabel('z')
hold on
view([-50,25])
plotGraphFile(config,groundTruthCell,[0 0 1]);
resultsCell = graphFileToCell(config,'icra18_results2.graph');
plotGraphFile(config,resultsCell,[1 0 0])