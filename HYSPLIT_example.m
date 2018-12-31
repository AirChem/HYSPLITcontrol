% HYSPLIT_example.m
% Example script for running hysplit trajectories for a portion of a flight.
% 20171107 GMW

%% INPUTS

% paths
hysplitPath = 'C:\hysplit4\'; %HYSPLIT core directory
metPath = fullfile(hysplitPath,'met','NARR',filesep); %directory containing met files to be used

% options
param.runTime = -24; %trajectory run time in h. Back-traj are negative.
param.top = 8000; %top of model, m
param.outName = 'exampleOutput'; %name of output trajectory text files
param.outPath = fullfile(hysplitPath,'output',filesep); %place to stuff output files

% data for start locations
load HYSPLIT_exampleData.mat %structure D with fields JDAY,UTC,lat,lon,alt

% trim to a few points
Dnames = fieldnames(D);
for i=1:length(Dnames)
    D.(Dnames{i}) = D.(Dnames{i})(1:10:end);
end

% massage time
year = 2013;
D.fdoy = D.JDAY + D.UTC/86400;
D.time = doy2datevec(D.fdoy,year);
D.time(:,5) = D.time(:,5) + round(D.time(:,6)/60);
D.time(:,6)=[]; %no seconds

%% DO IT
T = HYSPLIT_runModel(D.time,D.lat,D.lon,D.alt,metPath,hysplitPath,param);

%% DUMP OUTPUT TO KML (requires Google Earth and GE matlab toolbox)
kmzPath = fullfile(fileparts(mfilename('fullpath')),'exampleTraj.kmz');
HYSPLIT_traj2kmz(T,kmzPath,1)

%% BOX ANALYSIS

% Rim Fire
boxLat = [37.75 38.1];
boxLon = [-120.25 -119.7];
boxAlt = [0 4000]; %relative to ground level

boxInfo = HYSPLIT_boxIntercept(T,boxLat,boxLon,boxAlt);



