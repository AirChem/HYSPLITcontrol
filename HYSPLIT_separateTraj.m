function Tsep = HYSPLIT_separateTraj(traj,baseName)
% function Tsep = HYSPLIT_separateTraj(traj,baseName)
% Takes a trajectory structure containing multiple interleaved trajectories
% (e.g. from an ensemble or other multi-trajectory calculation) and separates them into
% distinct trajectory sub-structures.
%
% INPUTS:
% traj: trajectory structure as output by HYSPLIT_parseTraj.m.
% baseName: optional name to assign to each output trajectory structure. Default is 'traj'.
%
% OUTPUTS:
% Tsep is a structure containing all of the trajectory sub-structures.
%   Each trajecory sub-structure will have the name baseName_n, where n is the trajectory number.
%
% 20171113 GMW

% defaults
if nargin<2, baseName = 'traj'; end

% loop through trajectories and variables
varnames = fieldnames(traj);
tnum = unique(traj.trajnum);
Tsep = struct;
for i = 1:length(tnum)
    tname = [baseName '_' num2str(i)];
    for j = 1:length(varnames)
        Tsep.(tname).(varnames{j}) = traj.(varnames{j})(traj.trajnum==tnum(i));
    end
end


