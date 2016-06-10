function [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(SP, Fs, bands_per_oct, fc, sensor, method, fil_order)
% % fourier_nth_oct_time_filter: Computes fraction octave filters using ffts or hilbert transforms. 
% % 
% % Syntax: 
% % 
% % [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(SP, Fs, bands_per_oct, fc, sensor, method, fil_order);
% % 
% % ***********************************************************************
% % 
% % Description
% % 
% % This program applies Nth octave band filters to the input time record.
% % The program outputs the center frequency bands, the time average rms
% % values, the peak values, and band filtered time records for each
% % Nth octave band respectively.
% %
% % This program uses an fft method which is non-causal (waves travel
% % forward and backward in space and time simultaneously).  
% % 
% % The filter attenuationsat each fft frequency are computed with a 3rd 
% % order butterworth filter for an Nth octave band filter according to
% % ANSI S1.11 using the program filter_attenuation.
% %
% % This program has two methods for signal processing.  
% % Method 1) Using ffts alone then adding the real and imaginary part.  
% % Method 2) Using the hilbert transform and ffts then using the real 
% % part alone. 
% % 
% % 
% % 
% % ***********************************************************************
% % 
% % Input Variables
% %
% % SP=randn(10, 50000);
% %                     % (Pa) is the time record of the sound pressure
% %                     % default is SP=rand(1, 50000);
% %
% % Fs=50000;           % (Hz) is the sampling rate of the time record.
% %                     % default is Fs=50000; Hz.
% %
% % bands_per_oct=3;    % is the number of frequency bands per octave.  
% %                     % Can be any number > 0.  
% %                     % Default is bands_per_oct=3; for third octave bands.  
% % 
% % fc=[];              % is the array of center frequency bands (Hz). 
% %                     % Must be graeater than 0.  
% %                     % default is third octave bands from 20 to 20000 Hz;
% %
% % sensor=1;           % Constant integer input for selecting the sensor type
% %                     % 1 is for acoustic microphone Pref=20E-6 (Pa)
% %                     %
% %                     % 2 is for accelerometer output is in same
% %                     %   units as the input (m/s^2)
% %                     %
% %                     % 3 generic sensor multiply by 1: output is in same
% %                     %   units as the input
% %                     %
% %                     % default is sensor=1; For a microphone
% % 
% % method=1;           % Can use hilbert transform and real part 
% %                     % or fft and sum real and imaginary parts
% %                     % 
% %                     % 1 uses fft and sums real and imaginary parts. 
% %                     % 2 uses hilbert transform
% %                     % 
% %                     % default is method=1; (fft and real part).
% % 
% % fil_order=3;        % fil_order is the order of the filter default value is 3;
% %                     % 
% %                     % 3 uses 3rd order butterworth filters. 
% %                     % 5 uses 5th order butterworth filters. 
% %                     % 
% %                     % default fil_order=3; (3rdorder filters).
% % 
% % 
% % ***********************************************************************
% % 
% % Output Variables
% %
% % fc_out          % (Hz) array of center frequencies
% %
% % SP_levels       % (dB)sound pressure levels for each mic channel
% %                 % and f or each frequency band
% % 
% % SP_peak_levels  % (dB) Maximum of the absolute value of the Peak
% %                 % levels and for each frequency band
% %
% % SP_bands        % Time record for each mic channel and for each
% %                 % frequency band after filtering
% % 
% % 
% % 
% % ***********************************************************************
% % 
% % Examples
% % 
% 
% 
% % Example='1';
% % pure tone excitation 
% 
% Fs=100000;
% fc=200;
% buf1=sin(pi/4+2*pi*fc./Fs.*(-1+(1:Fs)));
% [fc2] = nth_freq_band(3, 20, 20000);
% [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(buf1, Fs, 3, fc2, 1);
% close all; for e1=1:31; figure(e1); plot(squeeze(SP_bands(1, e1, :))); end;
% buf2=sum(SP_bands);
% figure(32); plot(buf1, 'b'); hold on; plot(squeeze(buf2), 'r');
% figure(33); semilogx(fc_out, SP_levels);
% figure(34); semilogx(fc_out, SP_peak_levels);
% 
% 
% % Example='2';
% % random noise 
% 
% Fs=100000;
% 
% buf1=randn(Fs,1);
% [fc2] = nth_freq_band(3, 20, 20000);
% [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(buf1, Fs, 3, fc2, 1);
% close all; for e1=1:31; figure(e1); plot(squeeze(SP_bands(1, e1, :))); end;
% buf2=sum(SP_bands);
% figure(32); plot(buf1, 'b'); hold on; plot(squeeze(buf2), 'r');
% figure(33); semilogx(fc_out, SP_levels);
% figure(34); semilogx(fc_out, SP_peak_levels);
% 
% 
% 
% % Example='3';
% % square step input
% 
% Fs=50000;
% buf3=[zeros(1,10000) ones(1,10000) zeros(1,30000)];
% [fc2] = nth_freq_band(3, 20, 20000);
% [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(buf3, Fs, 3, fc2, 1);
% close all; 
% for e1=1:31; figure(e1); plot(squeeze(SP_bands(1, e1, :))); end;
% buf2=sum(SP_bands);
% figure(32); plot(buf3, 'b'); hold on; plot(squeeze(buf2), 'r');
% figure(33); semilogx(fc_out, SP_levels);
% figure(34); semilogx(fc_out, SP_peak_levels);
% 
% 
% 
% % Example='3b';
% % Analytic impulse (impulsive in high continuous noise)
% 
% Fs=100000; fc=1000; td=1; tau=0.01; delay=0.1; A1=2; A2=20;
% [SP, t]=analytic_impulse(Fs, fc, td, tau, delay, A1, A2);
% [fc2] = nth_freq_band(3, 20, 20000);
% [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(SP, Fs, 3, fc2, 1);
% buf2=sum(SP_bands);
% figure(32); plot(SP, 'b'); hold on; plot(squeeze(buf2), 'r');
% figure(33); semilogx(fc_out, SP_levels);
% figure(34); semilogx(fc_out, SP_peak_levels);
% 
% 
% 
% % Example='3c';
% % Analytic impulse fast decay and higher amplitude (more impulsive)
% 
% Fs=100000; fc=1000; td=1; tau=0.001; delay=0.1; A1=0.2; A2=200;
% [SP, t]=analytic_impulse(Fs, fc, td, tau, delay, A1, A2);
% [fc2] = nth_freq_band(3, 20, 20000);
% [fc_out, SP_levels, SP_peak_levels, SP_bands]=fourier_nth_oct_time_filter3(SP, Fs, 3, fc2, 1);
% buf2=sum(SP_bands);
% figure(32); plot(SP, 'b'); hold on; plot(squeeze(buf2), 'r');
% figure(33); semilogx(fc_out, SP_levels);
% figure(34); semilogx(fc_out, SP_peak_levels);
% 
% 
% 
% Example='4';
% 
% Fs=50000;
% 
% x1 = spatialPattern([1,Fs],0);        % white noise has a linearly
%                                       % increasing spectrum
%
% x2 = spatialPattern([1,Fs],-1);       % pink noise has a constant
%                                       % spectrum
%
% x3 = spatialPattern([1,Fs],-2);       % brownian noise has a linearly
%                                       % decreasing spectra
% 
% 
% [fc2] = nth_freq_band(3, 20, 20000);
% [fc_out1, SP_levels1, SP_peak_levels1]=fourier_nth_oct_time_filter3(x1, Fs, 3, fc2, 1);
% [fc_out2, SP_levels2, SP_peak_levels2]=fourier_nth_oct_time_filter3(x2, Fs, 3, fc2, 1);
% [fc_out3, SP_levels3, SP_peak_levels3]=fourier_nth_oct_time_filter3(x3, Fs, 3, fc2, 1);
% 
% % Plot the results
% figure(1); 
% semilogx(fc_out1, SP_levels1, 'color', [1 1 1],         'linewidth', 2,                    'marker', 's', 'MarkerSize', 8);
% hold on;
% semilogx(fc_out2, SP_levels2, 'color', [1 0.6 0.784],   'linewidth', 2, 'linestyle', '--', 'marker', 'o', 'MarkerSize', 8);
% semilogx(fc_out3, SP_levels3, 'color', [0.682 0.467 0], 'linewidth', 2, 'linestyle', ':',  'marker', 'x', 'MarkerSize', 12);
% set(gca, 'color', 0.7*[1 1 1]);
% legend({'White Noise', 'Pink Noise', 'Brownian Noise'}, 'location', 'SouthEast');
% xlabel('Frequency Hz', 'Fontsize', 28);
% ylabel('Sound Pressure Level (dB ref. 20 \mu Pa)', 'Fontsize', 28);
% title('Classical Third Octave Band Spectra', 'Fontsize', 40);
% set(gca, 'Fontsize', 20);
% 
% 
% 
% 
% % ***********************************************************************
% % 
% % This program requires the Matlab Signal Processing Toolbox
% % 
% % 
% % List of Dependent Subprograms for 
% % fourier_nth_oct_time_filter3
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) convert_double		Edward L. Zechmann			
% % 2) filter_attenuation		Edward L. Zechmann			
% % 3) nth_freq_band		Edward L. Zechmann			
% % 4) sd_round		Edward L. Zechmann			
% % 
% % 
% % 
% % ***********************************************************************
% % 
% % References
% %  
% % 1)  ANSI S1.11-1986 American National Stadard Specification for 
% %     Octave-Band and Fractional-Octave-Band Analog 
% %     and Digital Filters.
% %  
% % 2) Hatziantoniou, Panagiotis D.; Mourjopoulos, John N, Generalized 
% %    Fractional-Octave Smoothing of Audio and Acoustic Responses, 
% %    Audio Eng. Soc, vol. 48, part 4, pp. 259--280, 2000
% % 
% % 
% % 
% % ***********************************************************************
% % 
% % 
% % fourier_nth_oct_time_filter is written by Edward L. Zechmann
% % 
% % date     19 November    2008
% % 
% % modified 15 March       2012    Updated code implemented hilbert 
% %                                 transform method. 
% % 
% % modified 16 March       2012    Updated comments and examples.
% % 
% % modified 26 March       2012    Updated comments and examples.
% % 
% % 
% %
% %
% % ***********************************************************************
% % 
% % Feel free to modify this code.
% %   
% % See Also: spectra_estimate, fft, Aweight_time_filter, Cweight_time_filter, AC_weight_NB
% %           fft, fft2
% %
% %
% %


if (nargin < 1 || isempty(SP)) || ~isnumeric(SP)
    SP=rand(1, 50000);
end

% Make the data have the correct data type and size
[SP]=convert_double(SP);

[num_mics, num_pts]=size(SP);
flag1=0;

if num_mics > num_pts
    SP=SP';
    flag1=1;
    [num_mics num_pts]=size(SP);
end


if mod(num_pts, 2) == 1
    num_pts=2*floor(num_pts/2);
    SP=SP(:, 1:num_pts);
end


if (nargin < 2 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 3 || isempty(bands_per_oct)) || ~isnumeric(bands_per_oct)
    bands_per_oct=3;
end

if (nargin < 4 || isempty(fc)) || ~isnumeric(fc)
    [fc] = nth_freq_band(bands_per_oct, 20, 20000);
end

if (nargin < 5 || isempty(sensor)) || ~isnumeric(sensor)
    sensor=1;
end

if (nargin < 6 || isempty(method)) || ~isnumeric(method)
    method=1;
end

if (nargin < 7 || isempty(fil_order)) || ~isnumeric(fil_order)
    fil_order=3;
end


if method~=1
    method=2;
end

if ~isequal(exist('hilbert'), 2)
    method=1;
end


   

% Create the frequency array
df=Fs/num_pts;

half_pts=floor(num_pts/2)+1; 

f=df*(0:half_pts);
f = [f f((half_pts-2):(-1):2)]; 



% set the reference sensor value 
switch sensor

    case 1
        % reference sound pressure
        Pref=20*10^(-6); % Pa
    case 2
        % reference acceleration 
        Pref=1; % m/s^2
    case 3
        Pref=1;
    otherwise
        Pref=1;
end

fc_out=fc;

num_bands=length(fc);


if logical(num_mics > 0) && logical(num_bands > 0) && logical(num_pts > 0)

    SP_levels=zeros(num_mics, num_bands);
    SP_peak_levels=zeros(num_mics, num_bands);

    % if the band data is not requested save the memory
    if nargout > 3
        SP_bands=zeros(num_mics, num_bands, num_pts);
    end
    
    for e1=1:num_mics;

        if method == 1
            buf2=SP(e1, :); 
        else
            buf2=hilbert(SP(e1, :));
        end
        
        SPc=fft(buf2-mean(buf2));
                
        for e2=1:num_bands;
                        
            [Ad]=filter_attenuation(f, fc(e2), fil_order, bands_per_oct);
            
            band2=10.^(-Ad./10);
            
            buf=ifft(band2.*SPc);
            
            if method == 1
                SP_trunc22=real(buf)+imag(buf);
            else
                SP_trunc22=real(buf);
            end

            % Only concatenate the third octave bands if the output variable exists.
            if nargout > 3
                SP_bands(e1, e2, :)=SP_trunc22;
            end

            switch sensor

                case 1
                    SP_levels(e1, e2)=10*log10((norm(SP_trunc22)./sqrt(length(SP_trunc22))./Pref).^2);
                    SP_peak_levels(e1, e2)=20*log10(max(abs(SP_trunc22))./Pref);
                case 2
                    SP_levels(e1, e2)=norm(SP_trunc22)./sqrt(length(SP_trunc22));
                    SP_peak_levels(e1, e2)=max(abs(SP_trunc22));
                case 3
                    SP_levels(e1, e2)=norm(SP_trunc22)./sqrt(length(SP_trunc22));
                    SP_peak_levels(e1, e2)=max(abs(SP_trunc22));
                otherwise
                    SP_levels(e1, e2)=norm(SP_trunc22)./sqrt(length(SP_trunc22));
                    SP_peak_levels(e1, e2)=max(abs(SP_trunc22));
            end

        end
    end
    
else
    SP_levels=[]; 
    SP_peak_levels=[];

end

