function urlatency_arr = eeg_urlatency_arr(Events, relative_latency_arr)
%EEG_URLATENCY_ARR - A vector input version of eeg_urlatency.m (EEGLAB compatible)
%
% Description:
%   Calculates urlatency values as given by eeg_urlatency.m for a vector of
%   relative latency values. Needed because eeg_urlatency.m does the job 
%   right only if latencies are calculated one-by-one (i.e. input variable 
%   "lat_in" is a scalar).
%
% Inputs:
%   Events                  struct, EEG.event
%   relative_latency_arr    [1,m] or [m,1] numeric, Discontinuous data
%                           latencies (relative latencies) in datapoints
%
% Outputs:
%   urlatency_arr   [1,m] or [m,1] numeric, Continuous data latencies 
%                   (urlatencies) in datapoints


% Initialize variables
urlatency_arr = NaN(size(relative_latency_arr));

% Calculate urlatencies one-by-one 
for i = 1:length(relative_latency_arr)  
   urlatency_arr(i) = eeg_urlatency(Events, relative_latency_arr(i));     
end