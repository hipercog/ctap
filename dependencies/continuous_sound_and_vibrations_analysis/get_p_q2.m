function [Fsn, p, q, errors]=get_p_q2(Fs, Fsu, Fsl)
% % get_p_q2: Calculate p and q with p <= 3 for faster downsampling
% %
% % Syntax:
% %
% % [Fsn, p, q, errors]=get_p_q2(Fs, Fsu, Fsl);
% %
% % *********************************************************************
% %
% % Description
% %
% % [Fsn, p, q, errors]=get_p_q2(Fs, Fsu, Fsl);
% % Returns the resampling multiples p and q and the resamping rate Fsn (Hz).
% % The inputs are Fs (Hz) the sampling rate and Fsu (Hz) the upper limit
% % of the filters sampling rate.  Fsl (Hz) is the lower limit
% % of the filters sampling rate.  
% % 
% % Outputs Fsn in the range between Fsu and Fsl using the minimum amount
% % of down sampling and upsampling.  For upsampling q=1.  for downsmaling
% % p=1.  If Fsn si not in teh range of Fsu to Fsl then errors=1, 
% % otherwise errors=0.  
% % 
% % 
% % 
% % *********************************************************************
% %
% % Input Variables
% %
% % Fs=50000;   %(Hz) is the sampling rate.
% %
% % Fsd=20000;  %(Hz) is the upper limit of the sampling rate.
% % 
% % Fsl=5000;   %(Hz) is the lower limit of the sampling rate.
% % 
% % *********************************************************************
% %
% % Output Variables
% %
% % Fsn the resampling rate.  See the formula Fsn=Fs*p/q.
% %
% % p is the integer multiple for upsampling.
% %
% % q is the integer multiple for downsampling.
% %
% % errors indicated whether the range upper and lower bounds could be 
% %             satisfied.
% %             0 if satisfied, 1 if not satisfied.
% %
% % *********************************************************************
%
% Example='1';
%
% % downsampling required
% Fs=80000;
% Fsu=60000;
% Fsl=20000;
% 
% [Fsn, p, q, errors]=get_p_q(Fs, Fsu, Fsl);
%
%
% Example='2';
%
% % upsampling required
% Fs=10000;
% Fsu=60000;
% Fsl=20000;
% 
% [Fsn, p, q, errors]=get_p_q2(Fs, Fsu, Fsl);
%
% % *********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date 10 December    2008
% %
% % modified 11 December    2008    Updated Comments
% %
% % modified 12 July        2010    Modified method from desired frequency 
% %                                 and tolerance to upper and lower limits.
% %                                 Updated Comments
% %
% % *********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See also: rat, rats, resample
% %


if nargin < 1 || isempty(Fs) || ~isnumeric(Fs)
    Fs=50000;
end

if nargin < 2 || isempty(Fsu) || ~isnumeric(Fsu)
    Fsu=5000;
end

if nargin < 2 || isempty(Fsl) || ~isnumeric(Fsl)
    Fsl=1000;
end



% Get the number of sampling rates.
num_sr=length(Fs);

% Initialize the output arrays.
p=zeros(num_sr, 1);
q=zeros(num_sr, 1);
Fsn=zeros(num_sr, 1);


for e1=1:num_sr;

    flag1=1;

    if Fs(e1) > Fsu
        flag1=0;
        ratio1=Fs(e1)/Fsu;
    elseif Fs(e1) < Fsl
        ratio1=Fsl/Fs(e1);
    else
        ratio1=1;
    end

    
    if ~isequal(ratio1, 1)
        
        ratio2=(floor(ratio1)-1):(ceil(ratio1)+3);
        ratio2(ratio2 <= 1)=2;
    
    else
        
        ratio2=1;
    
    end

    if isequal(flag1, 0)
        ratio3=1./ratio2;
    else
        ratio3=ratio2;
    end

    if isequal(flag1, 0)
        [ix]=find(Fs*ratio3 <= Fsu, 1, 'first'); 
        errors=Fs*ratio3(ix) > Fsu;
    else
        [ix]=find(Fs*ratio3 >= Fsl, 1, 'first'); 
        errors=Fs*ratio3(ix) < Fsl;
    end
    
    % initialize p1 and q1
    p1=1;
    q1=1;

    % set p1 and q1 respectively
    if isequal(flag1, 0)
        q1=round(1./ratio3(ix));
    else
        p1=ratio3(ix);
    end


    % Set the array values of p and q
    p(e1)=p1;
    q(e1)=q1;

    % Calculate the output sampling rate 
    Fsn(e1)=Fs(e1)*p1/q1;


end


