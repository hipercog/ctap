function [B, A, H]=hand_arm_fil(Fs, fc)
% % hand_arm_fil: Calculates the hand arm vibrations filter coefficients
% %
% % Syntax;
% %
% % [B, A]=hand_arm_fil2(Fs);
% %
% % ********************************************************************
% %
% % Description
% %
% % This program calculates the frequency weighting filter coefficients
% % for the hand-arm vibrations filters.
% %
% % ********************************************************************
% %
% % Input Variables
% %
% % Fs (Hz) is the sampling rate.
% %
% % ********************************************************************
% %
% % Output Variables
% %
% % B, A are the coefficients of the weighting filter.
% %
% % ********************************************************************
% %
% % Program Modified by Edward L. Zechmann
% %
% %  created 27 April       2005
% %
% % modified  3 March       2008    updated comments
% %
% % modified  3 September   2008    updated comments
% %
% % modified 16 December    2008    Use convolution to simplify filter
% %                                 coefficients (B1, B2, A1, A2) into
% %                                 arrays B and A.
% %
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% %


% filter parameters
f1=6.31;
f2=1258.9;
Q1=0.71;
f3=15.915;
f4=15.915;
Q2=0.64;
K=1;

a1=4*pi^2*f2^2;
b1=2*pi*f3;
g1=2*pi*K*f4^2;

a=2*pi*f1/Q1;
b=4*pi^2*f1^2;
c=2*pi*f2/Q1;
d=4*pi^2*f2^2;
e=2*pi*f4/Q2;
f=4*pi^2*f4^2;

num1=[a1 0 0];
den1=[1 (a+c) (a*c+b+d) (a*d+b*c) b*d];

% Calculate the filter Coefficients for the Band Limiting Filters
[B1, A1] = bilinear(num1, den1, Fs);

num2=[g1 b1*g1];
den2=f3*[1 e f];

% Calculate the filter Coefficients for the Frequency weighting
[B2, A2] = bilinear(num2, den2, Fs);

B=conv(B1, B2);
A=conv(A1, A2);

if nargout > 2
    
    if nargin < 2 || isempty(fc) || ~isnumeric(fc)
        fc=[4	5.00E+00	6.3	8	10	12.5	16	20	25	31.5	40	50	63	80	100	125	160	200	250	315	400	500	630	800	1000	1250	1600	2000	2500	3150	4000	5.00E+03];
    end
    
    fcj=j*2*pi*fc(:)';
    
    
    FC2=[fcj; ones(size(fc))];
    FC3=[fcj.^2; fcj; ones(size(fc))];
    FC5=[fcj.^4; fcj.^3; fcj.^2; fcj; ones(size(fc))];
    
    num1=num1(:)';
    num2=num2(:)';
    
    den1=den1(:)';
    den2=den2(:)';
        
    H=(num1*FC3).*(num2*FC2)./((den1*FC5).*(den2*FC3));
    
end
