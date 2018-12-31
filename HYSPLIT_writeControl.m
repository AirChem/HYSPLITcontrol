function param = HYSPLIT_writeControl(time,lat,lon,alt,metPath,hysplitPath,param)
% function param = HYSPLIT_writeControl(time,lat,lon,alt,metPath,hysplitPath,param)
% Builds a HYSPLIT control file from data.
% NOTE that options in the SETUP.CFG file can also affect how trajectories are executed. This file
% is best modified with the HYSPLIT GUI (Advanced -> Configuration Setup)
%
% REQUIRED INPUTS:
% time: starting point time as a UTC date vector: [yyyy mm dd HH MM]. Minutes column is optional.
% lat: starting point latitude
% lon: starting point longitude
% alt: starting point altitude, m above ground level.
%       Note, if you wish to input this in m above sea level, you have to change the appropriate
%       setting in the SETUP.CFG file (easiest to do via HYSPLIT GUI)
% metPath: folder containing desired met files. ALL files in this folder will be included.
% hysplitPath: directory containing hysplit model, e.g. 'C:\hysplit4\'
% param: structure of optional inputs for model execution.
%   runTime:  total runtime in hours. For back-traj, this should be negative.     Default: 48
%   top:      top of model, m.                                                    Default: 10000
%   vert:     vertical motion option. See HYSPLIT documentation for options.      Default: 0
%   outPath:  directory to store output file.                                     Default: hysplitPath/working/
%   outName:  filename for output file, WITHOUT EXTENSION.                        Default: tdump
%
% OUTPUTS
% param: structure containing final used values for optional inputs listed above.
%
% 20171107 GMW

%% CHECK INPUTS

% required
assert(size(time,1)==1,'Input time can only contain one row.')
assert(length(time)==4 || length(time)==5, 'Input time must be a date vector [yyyy mm dd HH MM].')
assert(length(num2str(time(1,1)))==4,'Year column in time must be 4-digits.')
assert(length(lat)==length(lon) && length(lat)==length(alt),'Inputs lat, lon, alt must all be same length.')
assert(exist(metPath,'dir')==7,'Input metPath %s does not exist.',metPath)
assert(exist(hysplitPath,'dir')==7,'Input hysplitPath %s does not exist.',hysplitPath)
assert(strcmp(metPath(end),filesep),'Input metPath must end in %s',filesep)
assert(strcmp(hysplitPath(end),filesep),'Input hysplitPath must end in %s',filesep)

% optional
if nargin<7, param = struct; end
defparam.runTime = 48;
defparam.top = 10000;
defparam.vert = 0;
defparam.outPath = fullfile(hysplitPath,'working',filesep);
defparam.outName = 'tdump';
defparam.modelType = 'std';
param = parsepropval(defparam,param);

assert(strcmp(param.outPath(end),filesep),'Input param.outPath must end in %s',filesep)

s = filesep; if ~strcmp(s,'\'), s=''; end %need this later to deal with escape behavior of \ in fprintf

%% WRITE FILE

% open it
ctrlPath = fullfile(hysplitPath,'working','CONTROL');
[fid,message]=fopen(ctrlPath,'w');
if fid==-1, error(message); end

% time and location
timestr = datestr([time 0],'yy mm dd HH MM');
fprintf(fid,[timestr '\r\n']); % time
fprintf(fid,[num2str(length(lat)) '\r\n']); %# of starting locations
for i=1:length(lat)
    fprintf(fid,[num2str(lat(i)) ' ' num2str(lon(i)) ' ' num2str(alt(i)) '\r\n']);%starting location
end

% options
fprintf(fid,[num2str(param.runTime) '\r\n']);%Total runtime in hours (negative means backwards)
fprintf(fid,[num2str(param.vert) '\r\n']);%vertical coordinate system
fprintf(fid,[num2str(param.top) '\r\n']);%top of model, m

% met files
metFiles = dir(metPath);
metFiles = metFiles(~cell2mat({metFiles(:).isdir})); %exclude directories
nmet = length(metFiles);
fprintf(fid,[num2str(nmet) '\r\n']); %# of met files
for i=1:nmet
    fprintf(fid,[strrep(metPath,s,[s s]) '\r\n']);
    fprintf(fid,[metFiles(i).name '\r\n']);
end

% endpoints
fprintf(fid,[strrep(param.outPath,s,[s s]) '\r\n']);%pathbase for endpoints file
fprintf(fid,[param.outName]);%filename

%close it up
status=fclose(fid);
if status~=0
    error('HYSPLIT_control: Problem closing CONTROL file.');
end


