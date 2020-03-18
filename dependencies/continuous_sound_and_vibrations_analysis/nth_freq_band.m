function [fc, fc_l ,fc_u, fc_str, fc_l_str, fc_u_str] = nth_freq_band(N, min_f, max_f, SI_prefixes)
% % nth_freq_band: Calculates the 1/nth octave frequency bands center, lower, and upper bandedge limits
% % 
% % Syntax;    
% % 
% % [fc, fc_l ,fc_u, fc_str, fc_l_str, fc_u_str] = nth_freq_band(N, min_f, max_f);
% % 
% % **********************************************************************
% % 
% % Description
% % 
% % This program calculates the 1/N-octave band center frequencies and also
% % the lower and upper bandedge limits of every frequency band from 
% % min_f to max_f (Hz).
% % 
% % The values are rounded to three significant digits and the last digit
% % is rounded to the nearest multiple of 5.  If the number is within 
% % 1 percent of the value rounded to 1 digit, then only 1 digit is kept.
% % The numeric frequency values and character string representation of 
% % the values are output.  
% % 
% % This update of nth_freq_band satisfies the preferred band values of 
% % ANSI S1.6 for full octave bands and third octave center band 
% % frequencies; however, for other fractional octave bands and the 
% % lower and upper limits further testing is necessary.    
% % 
% % 
% % nth_freq_band is a modification of centr_freq
% % centr_freq can be found on Matlab Central File Exchange
% % The Matlab ID is 17590.
% % 
% % **********************************************************************
% % 
% % Input Variables
% % 
% % N is the number of frequency bands per octave.  
% %   Can be any number > 0.  Default is 3 for third octave bands.  
% % 
% % min_f is the minimum frequency band to calculate (Hz).
% %       Must be graeater than 0.  default is 20;
% % 
% % max_f is the maximum frequency band to calculate (Hz).
% %       Must be graeater than 0.  default is 20000;
% % 
% % If no input arguments are given then the third octave frequencies in 
% % the human audiometric range 20 to 20000 (Hz) are output 
% % 
% % SI_prefixes=0;  % 1 for using SI prefixes (i.e. K for 1000)
% %                 % 0 for not using prefixes.
% %                 % default is SI_prefixes=0;
% %
% %
% % **********************************************************************
% % 
% % Output Variables
% % 
% % fc is the vector of center frequency bands in Hz.
% % 
% % fc_l is the vector of lower bounds of the frequency bands in Hz.
% % 
% % fc_u is the vector of uppper bounds of the frequency bands in Hz.
% % 
% % fc_str is the vector of center frequency bands in Hz.
% % 
% % fc_l_str is the vector of lower bounds of the frequency bands in Hz.
% % 
% % fc_u_str is the vector of uppper bounds of the frequency bands in Hz.
% % 
% % 
% % **********************************************************************
% 
% 
% Example
% 
% % Full octave band center frequencies from 20 Hz to 20000 Hz
% [fc, fc_l, fc_u] = nth_freq_band(1, 20, 20000);
% 
% % third octave band center frequencies from 20 Hz to 20000 Hz
% [fc, fc_l, fc_u] = nth_freq_band(3, 20, 20000);
% 
% % twelveth octave band center frequencies from 100 Hz to 10000 Hz
% [fc, fc_l, fc_u] = nth_freq_band(12, 100, 10000);
% 
% % hundreth octave band center frequencies from 0.001 Hz to 10000000 Hz
% [fc, fc_l, fc_u] = nth_freq_band(100, 0.001, 10000000);
% 
% 
% % **********************************************************************
% % 
% % References
% % 
% % 1)  ANSI S1.6-R2006 Preferred Frequencies, Frequency Levels, and 
% %     Band Numbers for Acoustical Measurements, 1984.
% % 
% % 
% % 
% % **********************************************************************
% % 
% % nth_freq_band is a modification of centr_freq
% % centr_freq can be found on Matlab Central File Exchange
% % The Matlab ID is 17590.
% % 
% % Written by   Author  Eleftheria  
% %              E-mail  elegeor@gmail.com 
% %              Company/University: University of Patras 
% % 
% % 
% % 
% % List of Dependent Subprograms for 
% % nth_freq_band
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) sd_round		Edward L. Zechmann			
% % 
% % 
% % **********************************************************************
% % 
% % 
% % Program Modified by Edward L. Zechmann
% % 
% % modified  3 March       2008    Original modification of program
% %                                 updated comments 
% % 
% % modified 13 August      2008    Updated comments.  
% %   
% % modified 18 August      2008    Added rounding last digit to nearest 
% %                                 multiple of 5.  Added Examples.  
% %                                 Updated comments.  
% %    
% % modified 21 August      2008    Fixed a bug in usign min_f and max_f 
% %                                 which does not include 1000 Hz.  
% %                                 Zipped the depended program sd_round. 
% %                                 Updated comments.  
% % 
% % modified 18 November    2008   	Added additional rounding 
% % 
% % modified  8 December    2008    Updated comments.
% % 
% % modified 18 December    2008    Updated comments.
% % 
% % modified  4 January     2008    Changed rounding of the lower and upper 
% %                                 bandedge frequency limits.
% % 
% % modified  6 October     2009    Updated comments
% % 
% % modified 22 January     2010    Modified the number of significant 
% %                                 digits for rounding. The number of  
% %                                 significnat digits increases as the
% %                                 number of bands per octave increases.  
% %                                 This supports high resolution octave
% %                                 band analysis.
% % 
% % 
% % **********************************************************************
% % 
% % Please Feel Free to Modify This Program
% %   
% % See Also: centr_freq, sd_round
% %   

if (nargin < 1 || isempty(N)) || (logical(N < 0) || ~isnumeric(N))
    N=3;
end

if (nargin < 2 || isempty(min_f)) || (logical(min_f < 0) || ~isnumeric(min_f))
    min_f=20;
end

if (nargin < 3 || isempty(max_f)) || (logical(max_f < 0) || ~isnumeric(max_f))
    max_f=20000;
end

if (nargin < 4 || isempty(SI_prefixes)) ||  ~isnumeric(SI_prefixes)
    SI_prefixes=0;
end


% Calculate number of bands above 1000 Hz
Nmax=round(N*ceil(log(max_f/1000)/log(2))+1);

if Nmax < 1
    Nmax=1;
end

f_ab=zeros(Nmax, 1);
f_ab(1)=1000;

for n=1:Nmax;          
    % center frequencies over 1000 Hz
    % Center frequencies are based on a 1/3 octave band
    % falling exactly at each factor of 10
    f_ab(n+1, 1)=f_ab(n)*10^(3/(10*N)); 
end

% Remove bands above the extended max_f limit
f_ab=f_ab(f_ab < max_f*(2^(0.5/N)));


% Calculate number of bands below 1000 Hz
Nmin=round(N*ceil(log(1000/min_f)/log(2))+1);

if Nmin < 1
    Nmin=1;
end

f_bl=zeros(Nmin, 1);
f_bl(1)=1000;

for e1=1:Nmin;           
    % center frequencies below 1000 Hz
    % In the base 10 system, the center frequencies fall exactly at each 
    % factor of 10 based on third octave intervals.  
    f_bl(e1+1, 1)=f_bl(e1)/(10^(3/(10*N)));
end

% Remove bands below the extended min_f limit
f_bl=f_bl(f_bl > min_f*(2^(-0.5/N)));

% Concatenate center frequency bands
% Make center frequency bands unique
fc = unique([f_bl;f_ab]);           


% Remove bands above the extended max_f limit
fc=fc(fc < max_f*(2^(0.5/N)));


% Remove bands below the extended min_f limit
fc=fc(fc > min_f*(2^(-0.5/N)));

num_sd_digits=max([ceil(log10(N)/log10(2)), 3]);
% Apply appropriate rounding to the center frequencies
[fc,   fc_str]   = sd_round(fc, num_sd_digits, 1, 5, SI_prefixes);
[fc2,  fc_str2]  = sd_round(fc, num_sd_digits, 1, 100, SI_prefixes);

% If the center frequency rounded to 3 significant digits and the last 
% digit rounded to the nearest multiple of 5 is within 1% of the center 
% frequency rounded to 1 significant digit, then round to 1 significant 
% digit. 
%
ix=find(abs(100*(1-fc./fc2)) < 1);
fc(ix)=fc2(ix);
fc_str(ix)=fc_str2(ix);

% Calculate the number of center frequency bands
num_bands=length(fc);


% Calculate the lower and upper bounds for the lower and upper bandedge 
% frequencies
fc_lu = [fc(1)./2.^(1./(2.*N)); fc.*( 2.^(1./(2.*N)) )];          


% Apply the same rounding technique to the lower and upper frequency 
% bandedge limits as was applied to the center frequencies.  
[fc_lu,   fc_lu_str]   = sd_round(fc_lu, num_sd_digits, 1, 5, SI_prefixes);
[fc_lu2,  fc_lu_str2]  = sd_round(fc_lu, num_sd_digits, 1, 100, SI_prefixes);


% If the center frequency rounded to 3 significant digits and the last 
% digit rounded to the nearest multiple of 5 is within 1% of the center 
% frequency rounded to 1 significant digit, then round to 1 significant 
% digit. 
%
ix=find(abs(100*(1-fc_lu./fc_lu2)) < 1);
fc_lu(ix)=fc_lu2(ix);
fc_lu_str(ix)=fc_lu_str2(ix);


% Form the numeric and string arrays of the lower frequency bandedge
% limits.
fc_l=fc_lu(1:num_bands);
fc_l_str=fc_lu_str(1:num_bands);

% Form the numeric and string arrays of the upper frequency bandedge 
% limits.
fc_u=fc_lu(1+(1:num_bands));
fc_u_str=fc_lu_str(1+(1:num_bands));

