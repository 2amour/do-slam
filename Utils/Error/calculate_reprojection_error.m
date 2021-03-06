function reprojectionError = calculate_reprojection_error(K)

% Measurements
filepath = '/home/mina/workspace/src/Git/do-slam/Data/GraphFiles/noOverlapLongerGraph_v10.graph';
fileID = fopen(filepath,'r');
Data = textscan(fileID, '%s', 'delimiter', '\n', 'whitespace', '');
CStr = Data{1};
fclose(fileID);

posesID = [];
pointsID = [];
pointSeen = [];
pointsAssociation = {};
pointSeenByCamera = {};

for i =1:size(CStr,1)
    line = CStr{i};
    splitLine = strsplit(line,' ');
    if strcmp(line(1:length('EDGE_3D')),'EDGE_3D')
        camID = str2double(cell2mat(splitLine(2)));
        pointID = str2double(cell2mat(splitLine(3)));
        posesID = [posesID; camID];
        pointsID = [pointsID; pointID];
        pointSeenByCamera{camID, end+1} = pointID;
    end
    if strcmp(line(1:length('EDGE_R3_SO3')),'EDGE_R3_SO3')
        cam1ID = str2double(cell2mat(splitLine(2)));
        cam2ID = str2double(cell2mat(splitLine(3)));
        posesID = [posesID; cam1ID];
        posesID = [posesID; cam2ID];
    end
    if strcmp(line(1:length('EDGE_2POINTS_SE3Motion')),'EDGE_2POINTS_SE3Motion')
        dynamicPoint1ID = str2double(cell2mat(splitLine(2)));
        dynamicPoint2ID = str2double(cell2mat(splitLine(3)));
        if isempty(pointsAssociation)
            pointsAssociation{1,1} = [dynamicPoint1ID,dynamicPoint2ID];
            pointSeen = [pointSeen;dynamicPoint1ID;dynamicPoint2ID];
        else
            if ismember(dynamicPoint1ID, pointSeen)
                [row,~] = find(cellfun(@(subc) ismember(dynamicPoint1ID, subc), pointsAssociation));
                pointsAssociation{row,1} = [pointsAssociation{row,1},dynamicPoint2ID];
                pointSeen = [pointSeen;dynamicPoint1ID;dynamicPoint2ID];
            else
                pointsAssociation{size(pointsAssociation,1)+1,1} = [dynamicPoint1ID,dynamicPoint2ID];    
                pointSeen = [pointSeen;dynamicPoint1ID;dynamicPoint2ID];
            end
        end
    end
end

posesID = unique(posesID);
pointsID = unique(pointsID);

filepath = '/home/mina/workspace/src/Git/do-slam/Data/GraphFiles/app10_results.graph';
fileID = fopen(filepath,'r');
Data = textscan(fileID, '%s', 'delimiter', '\n', 'whitespace', '');
CStr = Data{1};
fclose(fileID);

reprojectionError = zeros(2,1);
count= 0;
for i=1:size(pointsID,1)
    %find camera that sees this point
    for j=1:length(posesID)
        if ~isempty(cell2mat(pointSeenByCamera(posesID(j),:)))
            pointSeen = cell2mat(pointSeenByCamera(posesID(j),:));
            if ismember(pointsID(i),pointSeen)
                cameraID = posesID(j);
            end
        end
    end
    % get camera pose
    IndexC = strfind(CStr, strcat({'VERTEX_POSE_R3_SO3'},{' '},{num2str(cameraID)},{' '}));
    lineIndex = find(~cellfun('isempty', IndexC));
    fileID = fopen(filepath,'r');
    line = textscan(fileID,'%s',1,'delimiter','\n','headerlines',lineIndex-1);
    line = cell2mat(line{1,1});
    splitLine = str2double(strsplit(line,' '));
    cameraPose = splitLine(1,3:8)';
    fclose(fileID);
    % get point position
    IndexC = strfind(CStr, strcat({'VERTEX_POINT_3D'},{' '},{num2str(pointsID(i))},{' '}));
    lineIndex = find(~cellfun('isempty', IndexC));
    fileID = fopen(filepath,'r');
    line = textscan(fileID,'%s',1,'delimiter','\n','headerlines',lineIndex-1);
    line = cell2mat(line{1,1});
    splitLine = str2double(strsplit(line,' '));
    pointPosition = splitLine(1,3:5)';
    fclose(fileID);
    % get pixel location
    pointImageFrame = AbsoluteToRelativePositionR3xso3Image(cameraPose,pointPosition,K);
    %pointImageFrame = pointImageFrame/pointImageFrame(3);
    % get GT pixel location -- 54 corner
    boardPoints = generateCheckerboardPoints([10,7],25);    
    [row,~] = find(cellfun(@(subc) ismember(pointsID(i),subc),pointsAssociation));
    if mod(row,54)~=0
        firstPoint = cell2mat(pointsAssociation(mod(row,54),1));
    else
        firstPoint = cell2mat(pointsAssociation(row,1));
    end
    pointGTImageFrame = boardPoints(firstPoint(1)-1,:)';
%     switch firstPoint(1)
%         case num2cell(1:9)
%             %pointGTImageFrame = [(firstPoint(1)-1)*0.025; 0];             
%         case num2cell(10:18)
%             %pointGTImageFrame = [(firstPoint(1)-1)*0.025; 0.025];
%         case num2cell(19:27)
%             %pointGTImageFrame = [(firstPoint(1)-1)*0.025; 0.05];
%         case num2cell(28:36)
%             %pointGTImageFrame = [(firstPoint(1)-1)*0.025; 0.075];
%         case num2cell(37:45)
%             %pointGTImageFrame = [(firstPoint(1)-1)*0.025; 0.1];
%         case num2cell(46:54)
%             %pointGTImageFrame = [(firstPoint(1)-1)*0.025; 0.125];
%     end
    % calculate reprojectionr  error
    reprojectionError = reprojectionError + (pointGTImageFrame - pointImageFrame(1:2,:));
    count = count+1;
end

reprojectionError = reprojectionError/count;

end