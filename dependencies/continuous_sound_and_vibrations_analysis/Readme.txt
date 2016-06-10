
These programs were written by Edward L. Zechmann for the purposes of 
characterizing sound and vibrations of machinery.


The main program is Main_sound_and_vibs.m please read the help section for details on using the program.
Main_sound_and_vibs calls the primary depedent function 
"Continuous_Sound_and_Vibrations_Analysis" which contians the switch statement controlling
the data flow.  Loading, plotting, calculating exposures, and saving the data is all controlled in 
"Continuous_Sound_and_Vibrations_Analysis."

Read the help section in "Continuous_Sound_and_Vibrations_Analysis" carefully.

data_loader2.m controls how the variables are configured as sound vibrations, time incrments, or
samling rates.  Read the help in data_loader2 if the menus and dialog boxes are not clear enough.


The following list of programs can be run separately.

Leq_all_calc.m		% Calculates the A-weighted level and other data
ACweight_time_filter.m	% applies the selected A-weighting or C-weighting filter to the time record


kurtosis2.m			% Calculates the kurtosis metric

data_outliers.m  		% performs a simple statistical analysis of the data

An example is shown below for running the main program.  

Instructions:
 
     1) Open Matlab.
     2) Copy the text between the lines.  
     3) Paste the text on the matlab command line.
     4) Press return. 

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% Example='a';
% 
% % One Example is shown for sound and vibrations.  
% % The example illustrates the definitions of the time
% % increment variables which the user is prompted to select.
% 
% 
% % Step 1)  Create a data file;
% 
% % Set the sampling rate variables for sound and vibrations
Fs_SP=50000;
Fs_vibs=5000;
% 
% % Set the time increment variables for sound and vibrations
% % t_SP, dt_SP        are time increment varialbes for sound
% % t_vibs, dt_vibs    are time increment varialbes for vibrations

dt_SP=1/Fs_SP;
dt_vibs=1/Fs_vibs;
t_SP=0:(1/Fs_SP):20;
t_vibs=0:(1/Fs_vibs):20;
 
% % SP is the sound pressure data 
% % (3 channels for 20 seconds at 50 KHz sampling rate)
SP=randn(3, length(t_SP));

% % vibs is the sound pressure data
% % (3 channels triaxial accelerometer
% % for 20 seconds at 5 KHz sampling rate)
vibs=randn(3, length(t_vibs));
 
save('Example_data_file.mat', 'SP', 'Fs_SP','t_SP', 'dt_SP', 'vibs', 'Fs_vibs','t_vibs', 'dt_vibs');
 
% % Step 2)  Run the program;
 
main_sound_and_vibs;
 
 

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



