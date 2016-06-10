function [filtercoeffs, filter_types, scaling_factors, H]=whole_body_filter(Fs, type, k, fc)
% % whole_body_filter: Calculates the filter coefficients for whole body vibrations.
% %
% % Syntax;
% %
% % [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type, k);
% %
% % ********************************************************************
% %
% % Description
% %
% % [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs,
% % type, k);
% %
% % Returns the filter coefficients, filter types, and scaling factors for
% % whole body vibrations according to ISO 2631-1:1997(E) given the
% % sampling rate Fs (Hz), the posture type, and the optional variable k.
% %
% % The input variables and output variablses are described in more detail
% % in the respective sections below.
% %
% % ********************************************************************
% %
% % Input Variables
% %
% % Fs (Hz) is the sampling frequency.  default is Fs=5000;
% %
% % type is an integer for the whole body vibration posture.
% %       For the selected posture types the corresponding transfer
% %       functions, and scaling factors are collected.  The transfer
% %       functions can be used to compute the filter coefficients
% %       (see whole_body_time_filter for more information).
% %       default is type=1;
% %
% %      The table below relates the type integer to each posture.
% %
% %      % type=1;    Standing
% %      % type=2;    Seated (Health)
% %      % type=3;    Seated (Comfort)
% %      % type=4;    Laying on back (recumbent) k=1 Pelvis, k=2 Head
% %      % type=5;    Rotational on supporting seat
% %      % type=6;    Rotational on seated backrest
% %      % type=7;    Rotational on feet
% %      % type=8;    Motion sickness
% %
% %
% %    There are six filter types which are used to calculate the transfer
% %    functions for the seven postures.  The seven posture types and six
% %    filter types are easily confused.   The posture types may use more
% %    than one filter type.
% %
% %    The case structure in this program documents which postures
% %    correspond to the filters.  For example: Posture number 7
% %    (Motion sickness) uses filter number 4, Wf.
% %
% %    Table 1:  ISO 2631 has 6 filter types
% %    Wc Wd We Wf Wk Wj
% %    1  2  3  4  5  6
% %
% %
% % k    ISO 2631 uses the variable k for multiple purposes.
% %      To avoid overloading the definition of k, in these programs,
% %      k is only used for posture type 4, more specifically the
% %      recumbent posture z-axis recording position.
% %
% %      k specifies the pelvis or head if the recumbent posture was used.
% %      k is 1 for Pelvis vibration recordings
% %      k is 2 for Head vibration recordings
% %      default is k=1;
% %
% %
% % ********************************************************************
% %
% % Output Variables
% %
% % filtercoeffs is a cell array of cell arrays of cell arrays of arrays
% %              of filter coefficients.
% %
% %              filtercoeffs{filter_type}{transfer_functions}{1}=B;
% %              filtercoeffs{filter_type}{transfer_functions}{2}=A;
% %
% %              There are three transfer_functions: the Band limiting
% %              filter (high pass and low pass), Acceleration-Velocity
% %              transition, and the Upward step.
% %
% %
% % filter_types There are six filter types
% %
% % Wc Wd We Wf Wk Wj
% % 1  2  3  4  5  6
% %
% % scaling_factors are the factors namely: 0, 1, sqrt(2), or sqrt(3) which
% %             are used to scale a single axis measurement to a multiple
% %             axis estimation of overall acceleration.
% %
% % ********************************************************************
%
%
%
% Example='1';
%
% % Standing Posture
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=1;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='2';
% % Seated Posture (Health)
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=2;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='3';
% % Seated Posture (Comfort)
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=3;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='4';
% % Laying on Back Posture recording at Pelvis location
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=4; k=1;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='5';
% % Laying on Back Posture recording at Head location
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=4; k=2;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='6';
% % Rotational on supporting seat Posture
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=5;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='7';
% % Rotational on seated backrest
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=6;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='8';
% % Rotational on feet
% % Using a sampling rate of 5000 Hz
%
% Fs=5000;  type=7;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='9';
% % Motion Sickness Posture
% % Using a sampling rate of 100 Hz
%
% Fs=100;  type=8;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type);
%
%
%
% Example='10';
% Fs=5000;
% type=4;
% k=2;
%
% N=3;          % three equal divisions per octave
% min_f=0.1;    % minimum frequency
% max_f=400;    % maximum frequency
%
% [fc]=nth_freq_band(N, min_f, max_f);
%
% [filtercoeffs, filter_types, scaling_factors, H]=whole_body_filter(Fs, type, k, fc);
% Hd_band_angle=180/pi*angle(prod(cell2array(H{1,1}(1, 1:2))))';
% Hd_angle=180/pi*unwrap(angle(prod(cell2array(H{1,1}))))';
%
% Hj_band_angle=180/pi*angle(prod(cell2array(H{1,2}(1, 1:2))))';
% Hj_angle=180/pi*unwrap(angle(prod(cell2array(H{1,2}))))';
%
% Hd_band_abs=abs(prod(cell2array(H{1,1}(1, 1:2)))';
% Hd_abs=abs(prod(cell2array(H{1,1})))';
%
% Hj_band_abs=abs(prod(cell2array(H{1,2}(1, 1:2)))';
% Hj_abs=abs(prod(cell2array(H{1,2})))';
%
%
%
% Example='11';
% Fs=5000;
% type=1;
% k=1;
%
% N=3;          % three equal divisions per octave
% min_f=0.1;    % minimum frequency
% max_f=400;    % maximum frequency
%
% [fc]=nth_freq_band(N, min_f, max_f);
%
% [filtercoeffs, filter_types, scaling_factors, H]=whole_body_filter(Fs, type, k, fc);
% Hd_band_angle=180/pi*angle(prod(cell2array(H{1,1}(1, 1:2))))';
% Hd_angle=180/pi*unwrap(angle(prod(cell2array(H{1,1}))))';
%
% Hk_band_angle=180/pi*angle(prod(cell2array(H{1,2}(1, 1:2))))';
% Hk_angle=180/pi*unwrap(angle(prod(cell2array(H{1,2}))))';
%
% Hd_band_abs=abs(prod(cell2array(H{1,1}(1, 1:2))))';
% Hd_abs=abs(prod(cell2array(H{1,1})))';
%
% Hk_band_abs=abs(prod(cell2array(H{1,2}(1, 1:2))))';
% Hk_abs=abs(prod(cell2array(H{1,2})))';
%
%
%
% % ********************************************************************
% %
% % References For whole Body Vibrations
% %
% % ISO 2631-1 1997  Mechanical vibration and shock-Evaluation of human
% %                  exposure to whole-body vibration-Part 1:
% %                  General Requirements
% %
% % ISO 2631-1 2010  Amendment 1 to Mechanical vibration and
% %                  shock-Evaluation of human exposure to whole-body
% %                  vibration-Part 1:  General Requirements
% %
% % ISO 8041   2005  Human response to vibration — Measuring
% %                  instrumentation
% %
% %
% % ********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date    July        2007
% %
% % modified 3  September   2008
% %
% % modified 16 December    2008    Updated comments
% %
% % modified 21 January     2009    Split the seated posture into two cases
% %                                 Seated (Health) and Seated (Comfort).
% %                                 Only documentation needed adjustment.
% %
% % modified 17 January     2011    Fixed a bug in the splitting the seated
% %                                 posture into two cases.  The scaling
% %                                 factors for the two cases were switched.
% %
% % modified  9 October     2012    Fixed a typographical error,
% %                                 changed Wl to Wj.
% %
% %                                 Added the input fc and the output H
% %                                 This modification allows the output of
% %                                 the frequency response expressed in
% %                                 complex floating point numbers.
% %
% %
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% %
% % See Also:   whole_body_time_filter, combine_accel_directions_wb,
% %             config_wb_accels, Vibs_calc_whole_body
% %

if (nargin < 1 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=5000;
end

if (nargin < 2 || isempty(type)) || ~isnumeric(type)
    type=1;
end

if (nargin < 3 || isempty(k)) || ~isnumeric(k)
    k=1;
end

if (nargin < 4 || isempty(fc)) || ~isnumeric(fc)
    
    N=3;          % three equal divisions per octave
    min_f=0.1;    % minimum frequency
    max_f=400;    % maximum frequency
    
    [fc]=nth_freq_band(N, min_f, max_f);
    
end

fc=fc(:);
H={};
filtercoeffs={};
filter_types=[];
scaling_factors=[];

% From ISO 2631

switch type
    
    case 1
        % for standing people
        kx=1;   %Wd;     x-axis
        ky=1;   %Wd;     y-axis
        kz=1;   %Wk;     z-axis
        
        filter_types=[2 5];
        scaling_factors=[kx ky 0; 0 0 kz];
        
    case 2
        % Scaling factors for Health
        kx=1.4;   %Wd;     %x-axis
        ky=1.4;   %Wd;     %y-axis
        kz=1;     %Wk;     %z-axis
        
        filter_types=[2 5];
        scaling_factors=[kx ky 0; 0 0 kz];
        
    case 3
        % for seated persons
        % Scaling factors for Comfort
        
        kx=1;   %Wd;     %x-axis
        ky=1;   %Wd;     %y-axis
        kz=1;   %Wk;     %z-axis
        
        filter_types=[2 5];
        scaling_factors=[kx ky 0; 0 0 kz];
        
    case 4
        % Laying on back (recumbent)
        kx=1;   %Wd;     %x-axis (under pelvis)
        ky=1;   %Wd;     %y-axis (under pelvis)
        kz=1;   %Wk;     %z-axis (under pelvis)
        kz=1;   %Wj;     %z-axis (under head) k=1;
        
        if nargin < 3
            k = menu('Is the Vibration Measurement under the Pelvis or Head?','Pelvis','Head');
        end
        
        if isequal(k, 1)
            filter_types=[2 5];
        else
            filter_types=[2 6];
        end
        
        scaling_factors=[kx ky 0; 0 0 kz];
        
    case 5
        %rotational on supporting seat
        kx=0.63;    %We;     %x-axis
        ky=0.4;     %We;     %y-axis
        kz=0.2;     %We;     %z-axis
        
        filter_types=[3];
        scaling_factors=[kx ky kz];
        
    case 6
        %rotational on seated backrest
        kx=0.8;     %Wc;     %x-axis
        ky=0.5;     %Wd;     %y-axis
        kz=0.4;     %Wd;     %z-axis
        
        filter_types=[1 2];
        scaling_factors=[kx 0 0; 0 ky kz];
        
    case 7
        %rotational on feet
        kx=0.25;    %Wk;     %x-axis
        ky=0.25;    %Wk;     %y-axis
        kz=0.4;     %Wk;     %z-axis
        
        filter_types=[5];
        scaling_factors=[kx ky kz];
        
    case 8
        % Motion sickness
        kz=1;%        Wf;
        
        filter_types=[4];
        scaling_factors=[kz kz kz];
        
    otherwise
        kx=1;   %Wd;     %x-axis
        ky=1;   %Wd;     %y-axis
        kz=1;   %Wk;     %z-axis
        
        filter_types=[2 5];
        scaling_factors=[kx ky 0; 0 0 kz];
        
end

% Constants for Wc Wd We Wf Wk Wj
% This is an array containing all of the filter specification constants
% According to ISO 2631-1-1997
% The large numbers 1000000000 approximate infinity.  Later in the program
% booleans are used to detect the large numbers and use the exact formula
% to calculate the filter coefficients.
%
f1=[    0.4         0.4         0.4         0.08        0.4     0.4         ];
f2=[    100         100         100         0.63        100     100         ];
f3=[    8           2           1           1000000000	12.5	1000000000  ];
f4=[    8           2           1           0.25        12.5	1000000000  ];
Q4=[    0.63        0.63        0.63        0.86        0.63	0           ];
f5=[    1000000000	1000000000	1000000000	0.0625      2.37	3.75        ];
Q5=[    0           0           0           0.8         0.91	0.91        ];
f6=[    1000000000	1000000000	1000000000	0.1         3.35	5.32        ];
Q6=[    0           0           0           0.8         0.91	0.91        ];

% Calculate the frequency domain filter response
if nargout > 3
    s=1i*2*pi*fc';
    
    % s polynomial buffers
    spb=[s.^2; s; ones(size(s))];
    spb2=[s; ones(size(s))];
end

for e1=1:length(filter_types);
    
    % band pass filter implemented by a low pass and a high pass filter
    e2=1; % High Pass Filter
    
    ft=filter_types(e1);
    
    w1=2*pi*f1(ft);
    
    num1=[1 0 0];
    den1=[1 2^(0.5)*w1 w1^2];
    
    [B, A] = bilinear(num1, den1, Fs);
    filtercoeffs{e1}{e2}{1}=B;
    filtercoeffs{e1}{e2}{2}=A;
    
    if nargout > 3
        H{e1}{e2}=num1(1).*spb(1, :)./(den1*spb);
    end
    
    
    e2=2; % Low Pass Filter
    
    w2=2*pi*f2(ft);
    
    num1=[1];
    den1=[ (1/w2)^2 2^(0.5)/w2 1];
    
    [B, A] = bilinear(num1, den1, Fs);
    
    filtercoeffs{e1}{e2}{1}=B;
    filtercoeffs{e1}{e2}{2}=A;
    
    if nargout > 3
        H{e1}{e2}=num1(1)./(den1*spb);
    end
    
    e2=3; % acceleration-velocity transition filter
    
    w3=2*pi*f3(ft);
    w4=2*pi*f4(ft);
    Q44=Q4(ft);
    
    if f3(ft) > 20
        num1=[1];
    else
        num1=[1/w3 1];
    end
    
    if f4(ft) > 20
        den1=[1];
    else
        den1=[ (1/w4)^2 1/(Q44*w4) 1];
    end
    
    if length(den1) < 3
        B=1;
        A=1;
    else
        [B, A] = bilinear(num1, den1, Fs);
    end
    
    filtercoeffs{e1}{e2}{1}=B;
    filtercoeffs{e1}{e2}{2}=A;
    
    if nargout > 3
        if f4(ft) > 20
            if f3(ft) > 20
                H{e1}{e2}=ones(size(s));
            else
                H{e1}{e2}=num1*spb2;
            end
        else
            if f3(ft) > 20
                H{e1}{e2}=ones(size(s))./(den1*spb);
            else
                H{e1}{e2}=num1*spb2./(den1*spb);
            end
        end
    end
    
    e2=4; % upward step filter
    
    w5=2*pi*f5(ft);
    w6=2*pi*f6(ft);
    Q55=Q5(ft);
    Q66=Q6(ft);
    
    if f5(ft) > 20
        num1=[1];
        den1=[1];
    else
        num1=(w5/w6)^2*[ (1/w5)^2 1/(Q55*w5) 1];
        den1=[ (1/w6)^2 1/(Q66*w6) 1];
    end
    
    if length(den1) < 3
        B=1;
        A=1;
    else
        [B, A] = bilinear(num1, den1, Fs);
    end
    
    filtercoeffs{e1}{e2}{1}=B;
    filtercoeffs{e1}{e2}{2}=A;
    
    if nargout > 3
        if f5(ft) > 20
            H{e1}{e2}=ones(size(s));
        else
            H{e1}{e2}=num1*spb./(den1*spb);
        end
    end
    
end

if nargout > 3
    
    for e1=1:size(H, 2);
        for e3=1:size(H{1,e1}{1, 1}, 2);
            for e2=1:size(H{1, e1}, 2);
                if e2 == 1
                    buf=1;
                end
                buf=buf*H{1,e1}{1, e2}(1, e3);
            end
            H_overall(e1, e3)=buf;
        end
        H_overall_angle(e1, :)=180/pi*unwrap(angle(H_overall(e1, :)));
    end
    H_overall_abs=abs(H_overall);

end
