function boxInfo = HYSPLIT_boxIntercept(T,boxLat,boxLon,boxAlt,options)
% function boxInfo = HYSPLIT_boxIntercept(T,boxLat,boxLon,boxAlt,options)
% Determines when trajectories pass through a pre-defined box and returns details about it.
% Note that this code does not do any interpolation between trajectory endpoints, thus it only looks
% for trajectory endpoints that fall within the box. Keep this in mind when dtermining trajectory
% resolution (default is 60 minutes) and size of the box.
%
% INPUTS:
% T: trajectory structure ss output by HYSPLIT_runModel.
% boxLat: 2-element vector of box latitudes
% boxLon: 2-element vector of box longitudes
% boxAlt: 2-element vector of box altitude. Units are m above ground level.
% options: optional arguments as a structure.
%   MLbox: flag to use ML depth to define box altitude instead of fixed altitude (0 or 1).
%           For this to work, trajectories must include the MIXDEPTH field.
%           This overrides the boxAlt input.
%
%  Other potential options (TBD):
%   startLatLim, etc: limits for trajectory starting location/time, used as a pre-filter.
%   xLim: other filtering by external variables (e.g. gas concentration)
%   interpTraj: option to interpolate trajectories to higher time resolution
%   options to control advanced outputs...
%
% OUTPUTS:
% boxInfo: a structure containing fields of details related to the box intercept.
%
% 20171110 GMW

%% CHECK INPUTS

Tnames = fieldnames(T);
Tnames(strcmp('init',Tnames))=[];

% box inputs
assert(diff(boxLat)>0,'input boxLat must be of the form [min max].')
assert(diff(boxLon)>0,'input boxLon must be of the form [min max].')
assert(diff(boxAlt)>0,'input boxAlt must be of the form [min max].')

% options
if nargin<5, options = struct; end
default.MLbox = 0;
options = parsepropval(default,options);

if options.MLbox
    assert(isfield(T.(Tnames{1}),'MIXDEPTH'),'options.MLbox=1 but MIXDEPTH not specified in trajectories.')
end

%% GET INTERCEPT DETAILS

% initialize outputs
n = nan(length(Tnames),1);
boxVars = {'age','dwell','intSunFlux'};
for i = 1:length(boxVars)
    boxInfo.(boxVars{i}) = n;
end
boxInfo.trajnum = (1:length(Tnames))';

% step through trajectories
for i=1:length(Tnames)
    traj = T.(Tnames{i});
    
    % index traj points inside box
    if options.MLbox
        j = traj.lat>=boxLat(1) & traj.lat<=boxLat(2) & ...
            traj.lon>=boxLon(1) & traj.lon<=boxLon(2) & ...
            traj.alt<=traj.MIXDEPTH;
    else
        j = traj.lat>=boxLat(1) & traj.lat<=boxLat(2) & ...
            traj.lon>=boxLon(1) & traj.lon<=boxLon(2) & ...
            traj.alt>=boxAlt(1) & traj.alt<=boxAlt(2);
    end
    
    if ~any(j), continue; end
    j1 = find(j,1,'first');
    
    % time details
    boxInfo.age(i) = traj.age(j1); % age at time of intercept
    boxInfo.dwell(i) = sum(j)*median(diff(traj.age)); %hours in the box

    % trajectory-integrated info
    if isfield(traj,'SUN_FLUX')
        boxInfo.intSunFlux(i) = trapz(traj.age(1:j1),traj.SUN_FLUX(1:j1)); %integrated sun exposure, W/m^2*h
    end
    
end


