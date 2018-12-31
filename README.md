# HYSPLITcontrol
Matlab scripts for interfacing with and analyzing output from the HYSPLIT trajectory model.

To use these scripts, you first need to install the HYSPLIT desktop application, available at http://www.arl.noaa.gov/ready/hysplit4.html whenever the US Government isn't shut down. Remember you also need to acquire meteorology files to drive your trajectories (also available through the HYSPLIT website or through the desktop GUI).

These scripts where specifically written to initialize trajectories along an aircraft flight track and then evaluate, statistically, how many such trajectories passed through a geographic box (e.g. a giant wild fire). Look at the HYSPLIT_example.m script and go from there. Commenting isn't great and there may be bugs, but if you want to do something with HYSPLIT and you like matlab, this will hopefully get you started.

