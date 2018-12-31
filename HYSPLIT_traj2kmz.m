function kmlStr = HYSPLIT_traj2kmz(T,kmzPath,openit)
% function kmlStr = HYSPLIT_traj2kmz(T,kmzPath,openit)
% Converts trajectories into kmz files. Adapted from var2kml.
% Requires the matlab google earth toolbox, freely available on the matlab file exchange.
%
% INPUTS:
% T: trajectory structure ss output by HYSPLIT_runModel.
% kmzPath: optional full path and/or filename to for saving kmz file.
% openit: optional flag for opening kmz file after generation. Default = 0 (no).
%
% OUTPUT kmlStr is the full kml string. It can be combined with
% other kml  strings (by using ge_folder or concatenating) and written to kml/kmz using ge_output.
%
% 20171110 GMW

%% CHECK INPUTS

if nargin>1
    [pathstr,name,ext] = fileparts(kmzPath);
    if isempty(pathstr)
        pathstr = cd;
    else
        assert(exist(pathstr,'dir')==7,'Input kmzPath directory %s does not exist.',pathstr)
    end
    if isempty(name), name = 'trajectories'; end
    if isempty(ext), ext = '.kmz'; end
    kmzPath = fullfile(pathstr,[name ext]);
else
    kmzPath = [];
end

if nargin<3, openit = 0; end

%% WRITE KML STRINGS FOR EACH TRAJECTORY

T = rmfield(T,'init');
Tnames = fieldnames(T);
ntraj = length(Tnames);
lineStr = cell(1,ntraj);
timeStr = cell(1,ntraj);
for i=1:ntraj
    traj = T.(Tnames{i});
    fprintf('Writing trajectory %d of %d ...\n',i,ntraj)

    % line
    lineStrNow = ge_plot3(traj.lon,traj.lat,traj.alt,...
        'lineWidth',3,...
        'lineColor','FFFFFFFF',...
        'altitudeMode','relativeToGround',...
        'visibility',0,...
        'name',Tnames{i});
    lineStr{i} = lineStrNow;

    % time points
    L = length(traj.lon);
    dispStr1 = datestr([traj.year+2000 traj.month traj.day traj.hour traj.minute zeros(L,1)],'mm/dd HH:MM');
    dispStr2 = [num2str(traj.age,'%+2.1f')];
    timeStrNow = cell(1,L);
    for j=1:L
        timeStrNow{j} = ge_point(traj.lon(j),traj.lat(j),traj.alt(j),...
            'iconURL','http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png',...
            'altitudeMode','relativeToGround',...
            'iconColor','FFFFFFFF',...
            'iconScale',0.5,...
            'name',[dispStr1(j,:) ' t' dispStr2(j,:) 'h'],...
            'extrude',0,...
            'visibility',0);
    end
    timeStrNow = ge_folder([Tnames{i}],cell2mat(timeStrNow));
    timeStr{i} = timeStrNow;
    
end

% concatenate
lineStr = ge_folder('Lines',cell2mat(lineStr));
timeStr = ge_folder('Times',cell2mat(timeStr));
trajStr = ge_folder('Trajectories',[lineStr timeStr]); %stuff it into a folder

%save if desired
if ~isempty(kmzPath)
    
    ge_output(kmzPath,trajStr);
    
    % open if desired
    if openit
        winopen(kmzPath);
    end
    
    % output if desired
    if nargout
        kmlStr = trajStr;
    end
end



