function T = HYSPLIT_runModel(time,lat,lon,alt,metPath,hysplitPath,param)
% function T = HYSPLIT_runModel(time,lat,lon,alt,metPath,hysplitPath,param)
% Executes HYSPLIT for a series of input start times/locations and collects trajectory endpoints.
% NOTE that options in the SETUP.CFG file can affect how trajectories are executed.
% This file is best modified with the HYSPLIT GUI (Advanced -> Configuration Setup -> Trajectory)
%
% INPUTS:
% time: starting point time as a UTC date vector: [yyyy mm dd HH MM]. Minutes column is optional.
% lat: starting point latitude
% lon: starting point longitude
% alt: starting point altitude, m above ground level.
%       Note, if you wish to input this in m above sea level, you have to change the appropriate
%       setting in the SETUP.CFG file (easiest to do via HYSPLIT GUI)
% metPath: folder containing desired met files. ALL files in this folder will be included.
% hysplitPath: directory containing hysplit model, e.g. 'C:\hysplit4\'
% param: OPTIONAL structure of parameters for model execution. May include:
%   runTime:  total runtime in hours. For back-traj, this should be negative.     Default: 48
%   top:      top of model, m.                                                    Default: 10000
%   vert:     vertical motion option. See HYSPLIT documentation for options.      Default: 0
%   outPath:  directory to store output file.                                     Default: hysplitPath/working/
%   outName:  filename for output file, WITHOUT EXTENSION.                        Default: tdump
%   modelType: Type of HYSPLIT run:'std' (standard) or 'ens' (ensemble).          Default: std
%              Additional options for ens available in Config Setup.
%
% OUTUPUTS:
% T: structure containing the following fields:
%   traj#####: sub-structure of trajectory endpoint info. Sequentially numbered in order of inputs.
%       See HYSPLIT_parseTraj for info on fields
%   init: structure containing information on initialization conditions and options.
%
% 20171108 GMW

%% CHECK INPUTS

% note, additional input checks occur within HYSPLIT_writeControl

% check lengths
L = [length(lat) length(lon) length(alt) size(time,1)];
if L(4)==1
    assert(length(unique(L(1:3)))==1,'Inputs lat, lon, alt must be have same number of rows.')
else
    assert(length(unique(L))==1,'Inputs lat, lon, alt, time must be have same number of rows.')
end

% defaults
if nargin<7, param = struct; end
if ~isfield(param,'modelType'), param.modelType = 'std'; end

%initialize variables to keep track of runs that fail
bad.index=[];
bad.status=[];
bad.result={};

% choose executable
switch param.modelType
    case 'std', exec = 'hyts_std.exe';
    case 'ens', exec = 'hyts_ens.exe';
    otherwise, error('HYSPLIT_runModel: modelType %s not recognized.',param.modelType)
end

%% LOOP THROUGH INPUTS

ntraj = size(time,1);
T = struct; %output structure
dirnow = cd; % get current directory 
cd(fullfile(hysplitPath,'working')) %have to change directories for hysplit to find CONTROL file
    
tic
for i=1:ntraj
    fprintf('Trajectory %d of %d ...\n',i,ntraj)
    
    % write control file
    if ntraj>1
        param = HYSPLIT_writeControl(time(i,:),lat(i),lon(i),alt(i),metPath,hysplitPath,param);
    else
        param = HYSPLIT_writeControl(time,lat,lon,alt,metPath,hysplitPath,param);
    end
    
    % call the model
    [status,result] = dos(fullfile(hysplitPath,'exec',exec));
    if status~=0
        disp('Trouble running HYSPLIT ...');
        bad.index(end+1) = i;
        bad.status(end+1) = status;
        bad.result{end+1} = result;
        continue;
    end
    
    % parse .trj text file and add to output structure
    trjPath = fullfile(param.outPath,param.outName);
    tname = ['traj' num2str(i,'%d')];
    T.(tname) = HYSPLIT_parseTraj(trjPath,1);
    
    % guess total runtime
    if i==1
        t1 = toc; %first time slower b/c loading met files
    elseif i==2 
        fprintf('Estimated run time is %2.2f hours.\n',t1/3600 + (toc-t1)/3600*(ntraj-1));
    end  
end
toc %actual total runtime

% store intitialization info
T.init = param;
T.init.metPath = metPath;
T.init.lat = lat;
T.init.lon = lon;
T.init.alt = alt;
T.init.time = time;
T.init.bad = bad;

cd(dirnow) %go back to original directory


