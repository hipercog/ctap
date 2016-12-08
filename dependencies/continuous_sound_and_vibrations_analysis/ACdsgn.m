function [Ba, Aa, Bc, Ac] = ACdsgn(Fs)
% % ACdsgn:  Design of an A and C-weighting filter.
% % 
% % Syntax;  
% % 
% % [Ba, Aa, Bc, Ac] = ACdsgn(Fs);
% % 
% % **********************************************************************
% % 
% % Description
% % 
% % [Ba, Aa, Bc, Ac] = ACdsgn(Fs); 
% %
% % returns Ba, Aa, and Bc, Ac which are arrays of filter 
% % coefficients for A and C-weighting respectively.  Fs is the sampling 
% % rate in Hz.    
% % 
% % This program is intended to be used with teh built-in Matlab progam 
% % filter, or ACweight_time_filter, which implements resmapling and filter
% % settling.  
% % 
% % This progam is a recreation of adsgn and cdsgn 
% % by Christophe Couvreur, see	Matlab FEX ID 69
% % 
% % Author: Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
% %         couvreur@thor.fpms.ac.be
% % 
% % **********************************************************************
% % 
% % Output Variables
% % 
% % Ba is an array of feedforward filter coefficients for A-weighting.   
% %           There are three cells and the filter function is applied
% %           iteratively to each cell of filter coefficiients.  
% % 
% % Aa is an array of feedback filter coefficients for A-weighting. 
% % 
% % Bc is an array of feedforward filter coefficients for C-weighting. 
% % 
% % Ac is an array of feedback filter coefficients for C-weighting. 
% % 
% % **********************************************************************
% 
% 
% Example='1';
% Fs=50000;  % Design of filters for a sampling rate of 50000 Hz
% [Ba, Aa, Bc, Ac] = ACdsgn(Fs);
% 
% 
% 
% Example='2';
% Fs=50000;  % Design of filters for a sampling rate of 100000 Hz
% [Ba, Aa, Bc, Ac] = ACdsgn(Fs);
% 
% 
% 
% Example='3';
% % Calculating an A-weighted time record follows this basic procedure.
% % Additional code is necessary for resampling, settling the filter
% % and for multiple channels of data.  (see ACweight_time_filter)
% 
% % Set the sampling rate
% Fs=50000;  % Design of filters for a sampling rate of 50000 Hz
%
% % Design the filter
% [Ba, Aa, Bc, Ac] = ACdsgn(Fs);
%
% % Create a time record
% buf=randn(1, 50000);
% t=1/Fs*(0:(Fs-1));
% buf2=buf;
% 
% % Apply the A-weighting filters
% buf = real(filter(Ba, Aa, buf ));
%
% % Plot the results!
% figure(1); plot(t, buf2, 'k'); hold on; plot(t,buf, 'g'); legend('Linear Time Record', 'A-weighted');
% 
% buf3=buf2;
% % Apply the C-weighting filters
% buf3 = real(filter(Bc, Ac, buf3 ));
%
% % Plot the results!
% figure(2); plot(t,buf2, 'k'); hold on; plot(t,buf3, 'g'); legend('Linear Time Record', 'C-weighted');
% 
% % **********************************************************************
% % 
% % References
% % 
% % IEC/CD 1672: Electroacoustics-Sound Level Meters, Nov. 1996. 
% % 
% % ANSI S1.4: Specifications for Sound Level Meters, 1983. 
% % 
% % **********************************************************************
% % 
% % Subprograms
% %
% % This program requires the Matlab Signal Processing Toolbox
% % This program is based on the Octave Toolbox	by Christophe Couvreur
% % Matlab Central File Exchange ID 69
% % 
% % 
% % **********************************************************************
% % 
% % Program recreated by Edward Zechmann 11 December  2008  
% % 
% % modified 16 December    2008    Use convolution to make filter
% %                                 coefficients (b and a) into  
% %                                 arrays from cell arrays.
% % 
% % modified  4 August      2010    Updated Comments
% % 
% % **********************************************************************
% % 
% % Please feel free to modify this code.
% % 
% % See also: Leq_all_calc, adsgn, cdsgn, Aweight_time_filter, Cweight_time_filter,
% %           resample, filter  
% % 


% Definition of analog A-weighting filter according to IEC/CD 1672.
f1 = 20.598997; 
f2 = 107.65265;
f3 = 737.86223;
f4 = 12194.217;
A1000 = 1.9997;
C1000 = 0.0619;


coef1=(2*pi*f4)^2*(10^(C1000/20));
coef2=(2*pi*f4)^2*(10^(A1000/20));

Num1 = [coef1 0 ];
Den1 = [1 +4*pi*f4 (2*pi*f4)^2]; 

Num2=[1 0];
Den2=[1 +4*pi*f1 (2*pi*f1)^2];

Num3=[coef2/coef1 0 0];
Den3=conv([1 2*pi*f2], [1 2*pi*f3]);

% Use the bilinear transformation to get the digital filters. 
[B1, A1] = bilinear(Num1, Den1, Fs); 
[B2, A2] = bilinear(Num2, Den2, Fs); 
[B3, A3] = bilinear(Num3, Den3, Fs); 


% Append the filter coefficients to a cell arrays for the A and C-Weighting
% filters.
% 
% The C-weighting filters use the first two cell arrays and A-Weighting
% filters use all three.  
Ac=conv(A1, A2);
Aa=conv(Ac, A3);


Bc=conv(B1, B2);
Ba=conv(Bc, B3);



