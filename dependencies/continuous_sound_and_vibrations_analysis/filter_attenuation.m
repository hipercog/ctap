function [Ad]=filter_attenuation(f, fc, fil_order, N)
% % filter_attenuation: Nth octave band filter attenuation  
% % 
% % Syntax:
% % 
% % [Ad]=filter_attenuation(f, fc, fil_order, N);
% % 
% % ***********************************************************
% %
% % Description
% % 
% % 
% % This function computes the minimum attenuation requirements specified in  
% % ANSI S1.11-1986 R(1998)
% % 
% % 
% %
% % ***********************************************************
% %
% % Input Variables
% % 
% % f=1:50000;      % f is the frequency distribution Hz;
% % 
% % fc=20;          % fc is the center band frequency in Hz
% % 
% % fil_order=3;    % fil_order is the order of the filter default value is 3;
% % 
% % N=2;            % Number of bands per octave
% %                 %  1 is octave
% %                 %  3 is third octave
% %                 %  6 is sixth octave
% %                 % 12 is twelth octave 
% %                 % default value is 2;
% % 
% % 
% % ***********************************************************
% %
% % Output Variables
% %
% % Ad is the array of attenuation values in dB
% % 
% % 
% %
% %
% % **********************************************************************
% % 
% % References
% % 
% % ANSI S1.11-1986 R(1998)
% % Octave-Band and Fractional-Octave-Band Analog and Digital Filters
% % 
% % 
% % **********************************************************************
% %
% % filter_attenuation is written by Edward L. Zechmann
% %
% %     date  2 October     2007
% %
% % modified 19 November    2008
% %
% % modified  4 August      2010    Updated Comments.
% %
% % modified 15 March       2012    Updated Comments.
% %
% %
% % **********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also: filter, filtfilt, resample, ACweight_time_filter,
% %           hand_arm_time_fil, whole_body_time_filter
% %

uno_a=ones(size(f));
 
if (nargin < 1 || isempty(f)) || ~isnumeric(f)
    f=1:50000;
end

if (nargin < 2 || isempty(fc)) || ~isnumeric(fc)
    fc=20;
end

if (nargin < 3 || isempty(fil_order)) || ~isnumeric(fil_order)
    fil_order=2;
end

if (nargin < 4 || isempty(N)) || ~isnumeric(N)
    N=2;
end


b=1./N;

Qr=1./(2.^(b./2)-2.^(-b./2));

Qd=pi./(2.*fil_order.*sin(pi./(2.*fil_order))).*Qr;

Ad=10.*log10(uno_a+(Qd.*((1./fc.*f)-(fc.*uno_a./f))).^(2.*fil_order));


