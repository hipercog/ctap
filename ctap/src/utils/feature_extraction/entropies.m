function [S, labels] = entropies(psdArray, freq_res, fmin, fmax)
% ENTROPIES - Calculate spectral entropies based on PSD
%
% Description:
%   Calculates spectral entropies from power spectrum density
%   'psdArray' in the frequency ranges specified by fmin and fmax
%
%   Does not contain runtime constants not defined by function arguments.
%
% Syntax:
%   S = entropies(psdArray, freq_res, fmin, fmax);
%
% Inputs:
%   psdArray     ncs-by-psdlen double, Power spectrum densities to be analyzed
%   freq_res     1-by-1 double, Frequency resolution of the 'psdArray'
%   fmin         1-by-j numeric, frequency band lower bounds in Hz
%   fmax         1-by-j numeric, frequency band upper bounds in Hz
%
% Outputs:
%   S           [ncs,j] double, Spectral entropies
%   labels      [1,j] cell of strings, Spectral entropy names
%
% Jussi Korpela, 22.12.2006, TTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(fmin) ~= length(fmax),
    error('Frequency vectors must have equal lengths!');
end

S = NaN(size(psdArray,1),length(fmin));
labels = cell(1, length(fmin));

for n = 1:size(psdArray,1)
    %Calculating entropies for each segment
    for j = 1:length(fmin),    

        iMin = round(fmin(j)/freq_res);
        iMax = round(fmax(j)/freq_res);
       
        if (fmin(j) < 49 && 51 < fmax(j) && fmax(j) < 100)
            S(n,j) = entropy_ilkka([psdArray(n, iMin:round(49.0/freq_res+1)) ...
                                psdArray(n, round(51.0/freq_res)+1:round(99.0/freq_res)+1)]);
        else
            S(n,j) = entropy_ilkka(psdArray(n,iMin:iMax));
        end
        
        labels{j} = {['S',num2str(fmin(j)),'_',num2str(fmax(j))]};
        clear('iMin','iMax');
    end
end