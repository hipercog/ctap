function [y2, num_settle_pts, settling_time]=filter_settling_data3(Fs, y, settling_time)
% % filter_settling_data: Creates data to append to a time record for settling a filter
% %
% % Syntax:
% %
% % [y2, num_settle_pts, settling_time]=filter_settling_data3(Fs, y, settling_time);
% %
% % **********************************************************************
% %
% % Description
% %
% % [y2, num_settle_pts]=filter_settling_data(Fs, y, settling_time);
% % Returns y2 a set of data for settling a filter having num_settle_pts of
% % data points.  Fs (Hz) is the sampling rate, y is the time record, and
% % settling_time (s)is the time require for the impulse response of the
% % filter to decay to the desired amount.
% %
% % The settling data is at least first order continuous to the original
% % data and exponentially decayed to zero to help remove transient effects
% % when filtering.
% %
% % 
% %
% % ***********************************************************
% %
% % Input Variables
% %
% % Fs=50000;           % (Hz) is the sampling rate.
% %                     % default is 50000 Hz.
% %
% % y=rand(50000, 1);   % is the multichannel input time record
% %                     % Processsing assumes
% %                     % that y has more channels than time record samples.
% %                     % y=randn(50000, 1) is the default.
% %
% % settling_time=0.1;  % (seconds) is the time it takes the filter to settle (seconds).
% %                     % default is settling_time=0.1;
% %
% % ***********************************************************
% %
% % Output Variables
% %
% % y2 is the filter settling data
% %
% % num_settle_pts is the number of data points in the settling data.
% %
% % settling_time is the actual amount of time for settling the filter.
% %
% % **********************************************************************
%
%
% % These examples show the need for using the settling data especially
% % when using the filter command.
%
%
% Example='1';
% % A sinusoid is processed and the change from the filter settling data to
% % the actual signal is almost perfectly continuous.
%
% f_sig=20;
% Fs=50000;
% t_SP=(0:(1/Fs):(100/f_sig));
% y=sin(2*pi*t_SP*f_sig);
% settling_time=0.1;
% [y2, num_pts_se]=filter_settling_data3(Fs, y, settling_time);
% buf2=hilbert(y2);
% t_SP=1/Fs*(1:length(y2));
% figure(1);
% subplot(3,1,1); plot(t_SP, y2); ylabel('signal (Pa)');
% hold on;
% subplot(3,1,2); plot(t_SP, abs(buf2)); ylabel('Amplitude (Pa)');
% subplot(3,1,3); plot(t_SP, 180/pi*angle(buf2)); ylabel('Phase deg.');
%
% [y2, num_pts_se]=filter_settling_data3(Fs, y, settling_time);
% bb=Fs.^3.*gradient(gradient(gradient(y2)));
% figure(2); plot(t_SP, bb);
% title('Third Time Derivative of Amplitude');
% % Observe the phase mismatch at 0.1 seconds and 5.1
% % seconds.
%
%
%
% Example='2';
% The lack of settling the filter causes the beginning of the filtered time
% record to oscillate with a very high amplitude.
%
% load Example_Data
% t=1/Fs*(1:length(SP));
% settling_time=0.1;
%
% [y2, num_pts_se]=filter_settling_data3(Fs, SP, settling_time);
%
% % Now apply a 1/3 octave band filter
% Fc=100;
% N=3;
% n=3;
%
% [Bc, Ac]=Nth_octdsgn(Fs, Fc, N, n);
% SP2 = filter(Bc, Ac, [y2 SP]);
% SP2=SP2((num_pts_se+1):end);
% SP22 = filtfilt(Bc, Ac, [y2 SP]);
% SP22=SP22((num_pts_se+1):end);
%
% SP1 = filter(Bc, Ac, [SP]);
% SP11 = filtfilt(Bc, Ac, [SP]);
% plot(t, SP2, 'k');
% hold on;
% plot(t, 0.05+SP22, 'b');
% plot(t, 0.1+SP1, 'r');
% plot(t, 0.15+SP11, 'c');
% legend('"filter" With Filter settling', '"filtfilt" With Filter settling', '"filter" No Filter Settling',  '"filtfilt" No Filter Settling');
%
%
% Example='3';
%
% % Only the first data point using the resample program is problematic,
% % however this discontinuity can cause problems with additional signal
% % processing.
%
% load Example_Data
% [y2, num_pts_se]=filter_settling_data3(Fs, SP, settling_time);
% SP2=resample([y2 SP], 1, 8);
% SP2=SP2((floor(num_pts_se/8)+1):end);
% SP1=resample(SP, 1, 8);
% plot(SP2, 'k');
% hold on;
% plot(SP1, 'r');
% legend('With Filter settling', 'No Filter Settling');
%
%
%
%
% % ***********************************************************
% %
% %
% % 
% % List of Dependent Subprograms for 
% % filter_settling_data3
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) convert_double		Edward L. Zechmann			
% % 2) fastlts		Peter J. Rousseeuw		NA	
% % 3) fastmcd		Peter J. Rousseeuw		NA	
% % 4) geospace		Edward L. Zechmann			
% % 5) match_height_and_slopes2		Edward L. Zechmann			
% % 6) rmean		
% % 7) rms_val		Edward L. Zechmann				
% % 
% % 
% % **********************************************************************
% %
% % Program was written by Edward L. Zechmann
% %
% %     date  2 July        2010
% %    
% % modified  5 August      2010    Update Comments
% % 
% % modified  4 Janaury     2012    Replace LMSloc with fastlts.  
% %                                 Updated comments
% % 
% %  
% %
% %
% % **********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also: filter, filtfilt, resample, ACweight_time_filter,
% %           hand_arm_time_fil, whole_body_time_filter
% % 
% % 

if (nargin < 1 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 2 || isempty(y)) || ~isnumeric(y)
    y=rand(50000, 1);
end

% Make the data have the correct data type and size
[y]=convert_double(y);

% Make the data have the correct data type and size
[y]=convert_double(y);

[num_samples, num_channels]=size(y);
flag1=0;

if num_channels > num_samples
    flag1=1;
    y=y';
    [num_samples, num_channels]=size(y);
end


if (nargin < 3 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=0.1;
end


if settling_time < 0
    settling_time=0.01;
end

num_settle_pts=ceil(settling_time*Fs);


if num_settle_pts > num_samples
    num_settle_pts=num_samples;
end

if isequal(settling_time, 0) || num_settle_pts < 10

    y2=y;
    num_settle_pts=0;

else

    freq_pts_offset=floor(num_settle_pts/10);

    y2=zeros(2*num_settle_pts+num_samples, num_channels);

    decayed_level=0.1;


    for e1=1:num_channels;


        % % ****************************************************************
        % %
        % % get the beginning data
        % %
        % %
        beg_data=y(1:num_settle_pts, e1);

        % Calculate the beginning amplitude
        A=sqrt(2)*rms_val(beg_data);
        
        % % get the beginning frequency
        inst_freq=real(Fs/(2*pi)*gradient(unwrap(angle(hilbert(beg_data)))));
        
        buf=abs(inst_freq(freq_pts_offset:num_settle_pts));

        [ beg_freq ] = rmean(buf, 0);

        
        if beg_freq > Fs/5;
            beg_freq=Fs/5;
        end

        % Calculate the derivatives of the beginning data
        gbeg=Fs.*gradient(beg_data);
        %g2beg=Fs.*gradient(gbeg);

        numpts=ceil(Fs/(2*beg_freq))+1;
        num_half_pts=floor(numpts/2);
        num_half_pts2=numpts-num_half_pts;

        % Set the beginning phase angle and half point polynomial amplitude
        if any(gbeg(1:2) < 0) 
            phi=0;
            A1=max([A, beg_data(1), beg_data(1)-num_half_pts*gbeg(1)/Fs/2]);
            factor1=1;
        else
            phi=pi;
            A1=min([-A, beg_data(1), beg_data(1)-num_half_pts*gbeg(1)/Fs/2]);
            factor1=-1;
        end

        if beg_freq > 0 && logical( num_settle_pts > 4*numpts )

            [y_out1]=match_height_and_slopes2(num_half_pts+1,  0/Fs, num_half_pts/Fs,  0,  A1, factor1*A*2*pi*beg_freq, 0);
            [y_out2]=match_height_and_slopes2(num_half_pts2+2, 0/Fs, (num_half_pts2+1)/Fs, A1, beg_data(1), 0, gbeg(1));

            y_out=[y_out1(1:(num_half_pts)) y_out2(2:(num_half_pts2+1))];

            new_beg_pts=-1+((-num_settle_pts+numpts+1):0);

            halfpts=floor(length(new_beg_pts)/2);
            sec_half_pts=length(new_beg_pts)-halfpts;

            [decay1]=geospace(decayed_level, 1, halfpts, 1);

            decay=[decay1'; ones(sec_half_pts, 1)]';

            decay_curve=decay.*A.*sin(2.*pi.*beg_freq./Fs.*new_beg_pts+phi);


            y2(1:num_settle_pts, e1)=[decay_curve y_out];

        else

            
            % The frequency or number of points is out of range
            % start the settling data from zero gracefully
            % match height and slope of first data point

            if numpts > 10 && logical(num_settle_pts >= 2*numpts)
                num_settle_pts2=num_settle_pts;
                num_half_pts2=numpts;
                num_half_pts=num_settle_pts-num_half_pts2;
            else
                num_settle_pts2=num_settle_pts;
                num_half_pts=floor(num_settle_pts/2);
                num_half_pts2=num_settle_pts-num_half_pts;
            end
            
            
            [y_out1]=match_height_and_slopes2(num_half_pts+1,  0/Fs, num_half_pts/Fs, 0, A1, 0, 0);
            [y_out2]=match_height_and_slopes2(num_half_pts2+2, 0/Fs, (num_half_pts2+1)/Fs, A1, beg_data(1), 0, gbeg(1));

            y_out=[y_out1(1:(num_half_pts)) y_out2(2:(num_half_pts2+1))];

            y2((num_settle_pts-num_settle_pts2+1):num_settle_pts, e1)=y_out;
        end



        % % ****************************************************************
        % %
        % % get the ending data
        % %
        end_data=y((num_samples-num_settle_pts+1):num_samples, e1);

        % Calculate the ending amplitude
        A=sqrt(2)*rms_val(end_data);

        % % get the ending frequency
        inst_freq=Fs/(2*pi)*gradient(unwrap(angle(hilbert(end_data))));
        [ end_freq ] = rmean(abs(inst_freq(1:(num_settle_pts-freq_pts_offset+1))), 0);

        if end_freq > Fs/5;
            end_freq=Fs/5;
        end

        % Calculate the derivatives of the ending data
        gend=Fs.*gradient(end_data);
        %g2end=Fs.*gradient(gend);

        numpts=ceil(Fs/(2*end_freq))+1;
        num_half_pts=floor(numpts/2);
        num_half_pts2=numpts-num_half_pts;


        
        % Set the beginning phase angle and half point polynomial amplitude
        if any((gend(length(gend)-1) > 0))
            phi=pi;
            A1=max([A, end_data(1), end_data(end)-num_half_pts*gend(end)/Fs/2]);
            factor1=-1;
        else
            phi=0;
            A1=min([-A, end_data(1), end_data(end)-num_half_pts*gend(end)/Fs/2]);
            factor1=1;
        end

        if end_freq > 0 && logical( num_settle_pts > 4*numpts )

            [y_out1]=match_height_and_slopes2(num_half_pts+2,  0/Fs, (num_half_pts+1)/Fs, end_data(end), A1, gend(end), 0);
            [y_out2]=match_height_and_slopes2(num_half_pts2+1, 0/Fs, num_half_pts2/Fs, A1, 0, 0, factor1*A*2*pi*end_freq);

            y_out=[y_out1(2:(num_half_pts+1)) y_out2(2:(num_half_pts2+1))];

            new_end_pts=1:(num_settle_pts-numpts);
            halfpts=floor(length(new_end_pts)/2);
            sec_half_pts=length(new_end_pts)-halfpts;

            [decay1]=geospace(1, decayed_level, halfpts, 1);
            decay=[ones(sec_half_pts, 1); decay1']';

            decay_curve=decay.*A.*sin(2.*pi.*end_freq./Fs.*new_end_pts+phi);

            y2((num_settle_pts+num_samples+1):(num_settle_pts*2+num_samples), e1)=[y_out decay_curve];

        else

           
            % The frequency or number of points is out of range
            % start the settling data from zero gracefully
            % match height and slope of first data point
            
            if numpts > 10 && logical(num_settle_pts >= 2*numpts)
                num_settle_pts2=num_settle_pts;
                num_half_pts=numpts;
                num_half_pts2=num_settle_pts-num_half_pts;
            else
                num_settle_pts2=num_settle_pts;
                num_half_pts=floor(num_settle_pts/2);
                num_half_pts2=num_settle_pts-num_half_pts;
            end
        
            [y_out1]=match_height_and_slopes2(num_half_pts+1,  1/Fs, (num_half_pts+1)/Fs, end_data(end), A1, gend(end), 0);
            [y_out2]=match_height_and_slopes2(num_half_pts2+1, 0/Fs, num_half_pts2/Fs, A1, 0, 0, 0);

            y_out=[y_out1(2:(num_half_pts+1)) y_out2(2:(num_half_pts2+1))];

            y2((num_settle_pts+num_samples+1):(num_settle_pts+num_settle_pts2+num_samples), e1)=y_out;

        end


        y2((num_settle_pts+1):(num_settle_pts+num_samples), e1)=y(:, e1);


    end


end



