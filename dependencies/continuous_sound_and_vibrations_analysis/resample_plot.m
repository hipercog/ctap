function [t_SP_rs, SP_rs]=resample_plot(t_SP, SP)
% % resample_plot: Resamples a plot to 10000 data points using the max and%min from each bin
% % 
% % Syntax:  [t_SP_rs, SP_rs]=resample_plot(t_SP, SP);
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Description
% % 
% % This program resamples the time record for plotting.  The time record
% % is separated into bins, then the max and min of each bin are the
% % values for that bin.  The program outputs the time and data arrays
% % that have the first and last indices of te origianl data and have the
% % indices of max and min data points is .
% %
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Output Variables
% % t_SP_rs is the resampled time array
% % SP_rs is the resampled data array
% %
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% Example;
% m1=4; n1=10004; Fs=50000;
% t_SP=1/Fs*(1:n1);         % (seconds) is an array of time values
% SP=randn(m1, n1);         % (Pa) is an array of sound pressure values
%                           % For the varibale SP, the first index be
%                           % the channels and the seconds index is
%                           % the data
%
% [t_SP_rs, SP_rs]=resample_plot(t_SP, SP);
% figure(1); for e1=1:m1; subplot(m1, 1, e1); plot(t_SP_rs(e1, :), ...
% SP_rs(e1, :)); end;
% figure(2); for e1=1:m1; subplot(m1, 1, e1); plot(t_SP(1, :), ...
% SP(e1, :)); end;
% %
% % Figures 1 and 2 are nearly identical but Figure 1 has only 1/5th
% % as many data points as Figure 2

% %
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Program Written by Edward L. Zechmann
% %                date 25 July 2007
% %            modified 19 December 2007 added comments and an example
% %            modified 21 December 2007 preallocated memory to arrays
% %            modified  3 Augustg  2008 added comments
% %
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Please feel free to modify this code.
% %

if nargin < 2

    warning('Not Enough input arguments for resample_plot.m');

else

    [m1, n1]=size(SP);

    if m1 > n1
        SP=SP';
        [m1 n1]=size(SP);
    end

    [m10, n10]=size(t_SP);

    if m10 > n10
        t_SP=t_SP';
        [m1 n1]=size(t_SP);
    end

    if ~isequal(n1, n10)
        n1=min(n1, n10);
        n10=n1;
        SP=SP(:, 1:n1);
        t_SP=t_SP(:, 1:n1);
    end

    num_pts=3000;
    if 3.01*num_pts > n1
        for e1=1:m1;
            t_SP_rs(e1, :)=t_SP(1, :);
            SP_rs=SP;
        end
    else
        r=floor(n1/num_pts);

        rs_ix=1:r:n1;

        num_rs=length(rs_ix);
        n2=2*num_rs;

        % The array should contain the first and last indices and the
        % indices of the max and min for each bin
        IX_buf=zeros(m1, n2+2);

        for e1=1:m1;

            % preallocate memeory to the index buffer array
            ixbuf=zeros(1, n2);

            for e2=1:num_rs;

                % select a bin of the data
                if (e2 < num_rs)
                    bin=SP(e1, rs_ix(e2)+[0:r-1]);
                else
                    bin=SP(e1, rs_ix(e2):n1);
                end

                % get the indices of the max and min of the data bin
                [buf, ixmax]=max(bin);
                [buf, ixmin]=min(bin);

                % calculate the data indices from the bin indices
                % and append to the buffer array

                ixbuf(2*e2+(-1:0))=(rs_ix(e2)-1)+[ixmax ixmin];

            end

            % append the first and last indices.
            % Make sure that the indices are unique.
            
            bufix=unique([1 ixbuf n1]);

            % If there aren't n2+2 indices append the necessary unique indices
            % to make the array have the length n2+2
            if length(bufix) < n2+2
                
                aa=zeros(n2+2-length(bufix), 1);
                count=0;
                count2=0;
                
                while (count < n1+1) && logical(count2 < length(aa))
                    count=count+1;
                    if ~any(ismember(count, bufix)) && logical(count2 < length(aa))
                        count2=count2+1;
                        aa(count2)=count;
                    end
                end
                
                bufix=[bufix aa(1:((n2+2)-length(bufix)))'];
            end

            % sort the indices to make sure that the
            % data is in order of increasing time
            bufix=sort(bufix);

            IX_buf(e1, :)=bufix;

        end


        % initialize and pre-allocate memory to the output arrays
        t_SP_rs=zeros(size(IX_buf));
        SP_rs=zeros(size(IX_buf));

        % set the values of the time array
        for e1=1:m1;
            t_SP_rs(e1, :)=t_SP(1, IX_buf(e1, :));
        end

        % set the values of the data array
        for e1=1:m1;
            SP_rs(e1, :)=SP(e1, IX_buf(e1, :));
        end

    end
end

