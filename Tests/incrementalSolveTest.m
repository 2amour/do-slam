%--------------------------------------------------------------------------
% Author: Mina Henein - mina.henein@anu.edu.au - 17/11/2017
% Contributors:
%--------------------------------------------------------------------------

%% general setup
nSteps = 100;

%% config setup 
config = CameraConfig();
config = setUnitTestConfig(config);
config.set('groundTruthFileName' ,'incrememntalSolveTest_groundTruth.graph');
config.set('measurementsFileName','incrementalSolveTest_measurements.graph');
% config.set('processing','incrementalSolveCholesky'); % L,d
config.set('processing','incrementalSolveHessian'); % Lambda,eta

rng(config.rngSeed);
%% set up sensor - MANUAL
sensorPose = zeros(6,nSteps);

% applies relative motion - constant velocity in forward (x) axis and rotation about z axis
for i=2:nSteps
    rotationMatrix = eul2rot([pi/12 0 0]);
    relativeSensorPose = [1; 0; 0; arot(rotationMatrix)];
    sensorPose(:,i) = RelativeToAbsolutePoseR3xso3(sensorPose(:,i-1),relativeSensorPose);
end

%% create ground truth and measurements
groundTruthVertices = {};
groundTruthEdges = {};
vertexCount = 1;

for i=1:nSteps
    % create vertex for odometry reading
    currentVertex = struct();
    currentVertex.label = config.poseVertexLabel;
    currentVertex.value = sensorPose(:,i);
    currentVertex.index = vertexCount;
    groundTruthVertices{end+1} = currentVertex;
    vertexCount = vertexCount+1;
end

for i=2:size(sensorPose,2)
    % ground Truth edges for odometry
    currentEdge = struct();
    currentEdge.index1 = i-1;
    currentEdge.index2 = i;
    currentEdge.label = config.posePoseEdgeLabel;
    currentEdge.value = AbsoluteToRelativePoseR3xso3(sensorPose(:,i-1),sensorPose(:,i));
    currentEdge.std = config.stdPosePose;
    currentEdge.cov = config.covPosePose;
    currentEdge.covUT = covToUpperTriVec(currentEdge.cov);
    groundTruthEdges{end+1} = currentEdge;
end

measurementEdges = groundTruthEdges; % copies grouthTruth to add noise
for i=1:size(measurementEdges,2) % add noise on measurements
    if strcmp(config.noiseModel,'Gaussian')
        noise = normrnd(measurementEdges{i}.value,measurementEdges{i}.std);
    elseif strcmp(config.noiseModel,'Off')
        noise = measurementEdges{i}.value;
    end
    measurementEdges{i}.value = noise;
end
    
groundTruthGraph = fopen(strcat(config.folderPath,config.sep,'Data',...
    config.sep,config.graphFileFolderName,config.sep,config.groundTruthFileName),'w');

for i=1:size(groundTruthVertices,2)
    vertex = groundTruthVertices{i};
    formatSpec = strcat('%s %d ',repmat(' %6.6f',1,numel(vertex.value)),'\n');
    fprintf(groundTruthGraph, formatSpec, vertex.label, vertex.index, vertex.value);
end

for i=1:size(groundTruthEdges,2)
    edge = groundTruthEdges{i};
    formatSpec = strcat('%s %d %d',repmat(' %.6f',1,numel(edge.value)),repmat(' %.6f',1,numel(edge.covUT)),'\n');
    fprintf(groundTruthGraph, formatSpec, edge.label, edge.index1, edge.index2, edge.value, edge.covUT);
end

fclose(groundTruthGraph);
measurementGraph = fopen(strcat(config.folderPath,config.sep,'Data',...
    config.sep,config.graphFileFolderName,config.sep,config.measurementsFileName),'w');

for i=1:size(measurementEdges,2)
    edge = measurementEdges{i};
    formatSpec = strcat('%s %d %d',repmat(' %.6f',1,numel(edge.value)),repmat(' %.6f',1,numel(edge.covUT)),'\n');
    fprintf(measurementGraph, formatSpec, edge.label, edge.index1, edge.index2, edge.value, edge.covUT);
end

fclose(measurementGraph);

%% solver
groundTruthCell  = graphFileToCell(config,config.groundTruthFileName);
measurementsCell = graphFileToCell(config,config.measurementsFileName);
graph0 = Graph();
solver = graph0.process(config,measurementsCell,groundTruthCell);
solverEnd = solver(end);

graphN  = solverEnd.graphs(end);
graphN.saveGraphFile(config,'incrementalSolveTest_results.graph');

graphGT = Graph(config,groundTruthCell);
% results = errorAnalysis(config,graphGT,graphN);
% fprintf('Chi Squared Error: %.4d \n',solverEnd.systems.chiSquaredError)
% fprintf('Absolute Trajectory Translation Error: %.4d \n',results.ATE_translation_error)
% fprintf('Absolute Trajectory Rotation Error: %.4d \n',results.ATE_rotation_error)
% fprintf('Absolute Structure Points Error: %d \n',results.ASE_translation_error);
% fprintf('All to All Relative Pose Squared Translation Error: %.4d \n',results.AARPE_squared_translation_error)
% fprintf('All to All Relative Pose Squared Rotation Error: %.4d \n',results.AARPE_squared_rotation_error)
% fprintf('All to All Relative Point Squared Translation Error: %.4d \n',results.AARPTE_squared_translation_error)

%% plot graph files
h = figure; 
axis equal;
xlabel('x')
ylabel('y')
zlabel('z')
hold on
plotGraph(config,graphN,'red');
plotGraphFile(config,groundTruthCell,'blue');

figure
subplot(1,2,1)
spy(solverEnd.systems(end).A)
subplot(1,2,2)
spy(solverEnd.systems(end).H)