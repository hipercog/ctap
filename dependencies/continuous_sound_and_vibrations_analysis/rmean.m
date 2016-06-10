function [ rm ] = rmean(y, db_or_lin)
% % get_stats: Calculates descriptive statistics for the input variable y.
% %
% % Sytnax:
% %
% % [stats, stats_descriptions]=get_stats(y, db_or_lin);
% %
% % **********************************************************************
% %
% % Description
% %
% % Calculates descriptive statistics for the input variable y.
% %
% %
% % **********************************************************************
% %
% % Input Variables
% %
% % y
% %
% % db_or_lin
% %
% %
% %
% % **********************************************************************
% %
% % Output Variables
% %
% % rm
% %
% % **********************************************************************
% %
% %
% % List of Dependent Subprograms for
% % get_stats
% %
% % FEX ID# is the File ID on the Matlab Central File Exchange
% %
% %
% % Program Name   Author   FEX ID#
% % 1) fastlts		Peter J. Rousseeuw		NA
% % 2) fastmcd		Peter J. Rousseeuw		NA
% % 3) genHyper		Ben Barrowes		6218
% % 4) t_alpha		Edward L. Zechmann
% % 5) t_confidence_interval		Edward L. Zechmann
% % 6) t_icpbf		Edward L. Zechmann
% %
% %
% % **********************************************************************
% %
% % get_stats is written by Edward L. Zechmann
% %
% %     date  4 January   2011    Added comments.
% %
% %
% %
% % **********************************************************************
% %
% % See also: allstats by Duane Hanselman
% %

if nargin < 1 || isempty(y) || ~isnumeric(y)
    y=[];
end

if nargin < 2 || isempty(db_or_lin) || ~isnumeric(db_or_lin)
    db_or_lin=0;
end

rm=[];
am=[];

% get rid of the NaN elements
buf2=find(~isnan(y));
y=y(buf2); %#ok<FNDSB>
y=y(:);
nmax=200;

num_pts=length(y);

if ~isempty(y);
    
    %  Calculate the arithmetic mean
    if isequal(db_or_lin, 1)
        [mn_rt1]=mean(10.^(y./20));
        am=20.*log10(mn_rt1);
    else
        am=mean(y);
    end
    
    % Calculate the robust estimate of the mean.
    %
    % Statistical language for this type of mean is
    % "calculates the Least Median of Squares (LMS)
    % location parameter of the columns of a matrix
    % X. If X is a vector, it returns the LTS
    % location parameter of its components. If X
    % is a scalar, it returns X."
    
    if num_pts >= 4
        
        if num_pts > nmax
            
            num_bins=max([min([floor(num_pts/nmax), 50]), 1]);
            pts_per_bin=floor(num_pts/num_bins);
            
            rma=zeros(num_bins, 1);
            
            for e1=1:num_bins;
                
                [ndraw]=rand_int(1+(e1-1)*pts_per_bin, e1*pts_per_bin, nmax, 1, 1);
                
                if isequal(db_or_lin, 1)
                    [res] = fastlts(10.^(y(ndraw)./20));
                    rm1=20.*log10(res.coefficients);
                else
                    [res] = fastlts(y(ndraw));
                    rm1=res.coefficients;
                end
                
                rma(e1)=rm1;
                
            end
            
        else
            
            num_bins=1;
            if isequal(db_or_lin, 1)
                [res] = fastlts(10.^(y./20));
                rm1=20.*log10(res.coefficients);
            else
                [res] = fastlts(y);
                rm1=res.coefficients;
            end
            
            rma=rm1;
            
        end
        
        
        
        if num_bins >= 4
            
            if isequal(db_or_lin, 1)
                [res] = fastlts(10.^(rma./20));
                rm=20.*log10(res.coefficients);
            else
                [res] = fastlts(rma);
                rm=res.coefficients;
            end
            
        else
            
            if isequal(db_or_lin, 1)
                [mn_rt1]=mean(10.^(rma./20));
                rm=20.*log10(mn_rt1);
            else
                rm=mean(rma);
            end
            
        end
        
    else
        
        rm=am;
        
    end
    
else
    rm=am;
end


