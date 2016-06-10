function A = filterA(f,plotFilter)

% FILTERA Generates an A-weighting filter.
%    FILTERA Uses a closed-form expression to generate
%    an A-weighting filter for arbitary frequencies.
%
% Author: Douglas R. Lanman, 11/21/05

% Define filter coefficients.
% See: http://www.beis.de/Elektronik/AudioMeasure/
% WeightingFilters.html#A-Weighting
c1 = 3.5041384e16;
c2 = 20.598997^2;
c3 = 107.65265^2;
c4 = 737.86223^2;
c5 = 12194.217^2;

% Evaluate A-weighting filter.
f(find(f == 0)) = 1e-17;
f = f.^2; num = c1*f.^4;
den = ((c2+f).^2) .* (c3+f) .* (c4+f) .* ((c5+f).^2);
A = num./den;

% Plot A-weighting filter (if enabled).
if exist('plotFilter') & plotFilter
    
   % Plot using dB scale.
   figure(2); clf;
   semilogx(sqrt(f),10*log10(A));
   title('A-weighting Filter');
   xlabel('Frequency (Hz)');
   ylabel('Magnitude (dB)');
   xlim([10 100e3]); grid on;
   ylim([-70 10]);
   
   % Plot using linear scale.
   figure(3); plot(sqrt(f),A);
   title('A-weighting Filter');
   xlabel('Frequency (Hz)');
   ylabel('Amplitude');
   xlim([0 44.1e3/2]); grid on;

end