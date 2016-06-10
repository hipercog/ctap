function latout = eeg_latency(Events, latin)
%EEG_LATENCY - Discontinuous data latency value(s) for urlatency value(s) (EEGLAB compatible)
%
% Description:
%   Calculates the discontinous data latency value(s) corresponding 
%   continuous data latency value(s) based on event table 'Events'.
%   Does the opposite compared to eeg_urlatency.m 
%   Returns NaN and issues a warning for every element in 'latin' that  
%   overlap with a boundary event in 'Events'. 
%
% Inputs:
%   Events  struct, EEG.event
%   latin   [1,n] OR [n,1] numeric, Continuous data latency value(s) (urlatency) in 
%           samples
%
% Outputs:
%   latout  [1,n] OR [n,1] numeric, Discontinuous data latency value(s) (relative 
%           latency) corresponding to 'latin' in samples.           
%
% References:
%
% Example:
%
% Notes:
%
% See also: eeg_urlatency.m, eeg_urlatency_arr.m
%
% Version History:
% 9.4.2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


% Initialize variables
latout = NaN(size(latin));
urlatencies = eeg_urlatency_arr(Events, [Events.latency]');


% Calculate latencies one-by-one 
for i = 1:length(latin)  
   latout(i) = getlatency(Events, urlatencies, latin(i));     
end


    function latency_out = getlatency(Events, urlatencies, latency_in)
        %% Calculates the discontinuous time latency value
        
        %%Identify preceding event in continuous time   
        latin_preceding_event_ind = find(urlatencies < latency_in, 1, 'last');


        %% Construct discontinous time latency value based on 
        %  the preceding event
        if isempty(latin_preceding_event_ind)
            % Preceding event not found
            latency_out = latency_in;
            
        else
            % Preceding event found
            
            if strcmp(Events(latin_preceding_event_ind).type, 'boundary')
                % Preceding event is a boundary event
                
                latin_lag_from_preceding = ...
                    latency_in - urlatencies(latin_preceding_event_ind) -...
                    Events(latin_preceding_event_ind).duration;
                
                if latin_lag_from_preceding <0
                    % Overlaps with the preceding 'boundary' event
                    msg = 'Latency value overlaps with boundary event. Discontinous data latency value cannot be assigned. Returning NaN.';
                    warning('eeg_latency:boundaryOverlap',msg);

                    latency_out = NaN;
                else
                    % Does not overlap with the preceding 'boundary' event
                    latency_out = Events(latin_preceding_event_ind).latency + ...
                              latin_lag_from_preceding;
                end
                
                
                
            else
                % Preceding event is regular event
                latin_lag_from_preceding = ...
                    latency_in - urlatencies(latin_preceding_event_ind);
                latency_out = Events(latin_preceding_event_ind).latency + ...
                              latin_lag_from_preceding;
            end
        end %latency value construction
        
    end %getlatency
end %eeg_latency