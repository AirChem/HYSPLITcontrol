function traj = HYSPLIT_parseTraj(trjPath,deleteTRJ)
% function traj = HYSPLIT_parseTraj(trjPath,deleteTRJ)
% Reads a HYSPLIT trajectory output file into matlab.
% Optionally deletes the original file to save disk space.
%
% INPUTS:
% trjPath: path and/or name of file to read. If only name is given, the containing folder must be on
% the MATLAB search path.
% deleteTRJ: optional flag to delete .trj text file. Default = 0 (no).
%
% OUTPUT:
% traj: a structure containing trajectory endpoints info in the following fields.
%   trajnum: trajectory number
%   metnum: index for which met file is being used (I think)
%   year, month, day, hour, minute: output time
%   forecastHour: time from last met forecast
%   age: number of hours from start of trajectory
%   lat, lon, alt: latitude, longitude, altitude above ground level
%       Note that Alt is always magl, regardless of input altitude type (magl or masl)
%   fdoy: fractional day of year
%
% optional met diagnostic fields, if selected in SETUP.CFG:
% PRESSURE 
% THETA 
% AIR_TEMP 
% RAINFALL 
% MIXDEPTH 
% RELHUMID 
% SPCHUMID 
% H2OMIXRA 
% TERR_MSL 
% SUN_FLUX
%
% 20171108 GMW

%% CHECK INPUTS

assert(exist(trjPath,'file')==2,'Input trjPath %s not found.',trjPath)

if nargin<2, deleteTRJ = 0; end


%% READ FILE

% open file
[fid,message] = fopen(trjPath);
if fid==-1
    warning(message);
end

%scroll through header junk
nmet=fscanf(fid,'%d',1);%number of meteorology files in header
for i=1:(nmet+1), fgetl(fid); end
ntrj=fscanf(fid,'%d',1);%number of trajectory startpoints in header
for i=1:(ntrj+1), fgetl(fid); end

%get names for optional met diagnostics
dvars = fgetl(fid);
[ndvar dvarnames] = strtok(dvars);
ndvar = str2num(ndvar);
dvarnames = textscan(dvarnames,'%s',ndvar);
dvarnames = dvarnames{1}';

%grab data and close file
data = fscanf(fid,'%f',[12+ndvar,inf]);
data = data';
status = fclose(fid);
if status~=0, warning('HYSPLIT_parseTraj: problem closing file'); end

% optional delete text file
if deleteTRJ, delete(trjPath); end


%% PARSE TRAJECTORY DATA

varnames = [{'trajnum','metnum','year','month','day','hour','minute','forecastHour','age',...
    'lat','lon','alt'},dvarnames];
traj = struct;
for i=1:length(varnames)
    traj.(varnames{i}) = data(:,i);
end
    
% fractional day of year
L = length(traj.year);
dv = [traj.year traj.month traj.day traj.hour traj.minute zeros(L,1)];
t0 = [traj.year ones(L,2) zeros(L,3)];
traj.fdoy = datenum(dv) - datenum(t0) + 1;


