function [ytick_m, YTickLabel1, ytick_good, ytick_new, yticklabel_new]=fix_YTick(fmtz, dB_scale)
% % fix_YTick:  Sets appropriate Y-Tick values for small plots 
% % 
% % Syntax: 
% % 
% % [ytick_m, YTickLabel1, ytick_good, ytick_new, yticklabel_new]=fix_YTick(fmtz);
% % 
% % *********************************************************************
% % 
% % Description
% % 
% % fix_YTick(fmtz, dB_scale);
% % 
% % Modifies a plot to have 3 values displayed on the y axis.  
% % The values are plotted at about 70% percent of the displacement from
% % the mean value to the maximum or minimum.  
% % 
% % *********************************************************************
% %
% % Input Arguments
% %
% % fmtz=1;         % 1 forces the mean to zero.
% %                 % means force mean to zero
% %                 % default is fmtz=0;
% % 
% % dB_scale=0;         % 1 use a dB scale to plot Y-sxis time record 
% %                     % 0 use a linear scale to plot Y-sxis time record 
% %                     %
% %                     % default is dB_scale=0; 
% %                     
% %
% %
% % *********************************************************************
% % 
% % Output Arguments
% %
% % ytick_m old ytick numeric values.
% % 
% % YTickLabel1 old Y-Tick label values.
% % 
% % ytick_good collection of the old appropriate y-Tick values.
% % 
% % ytick_new new y-Tick numeric values.
% % 
% % yticklabel_new new y-Tick labels.
% % 
% %
% % *********************************************************************
% 
% 
% Example='1';
% 
% Fs=50000;
% y=randn(1, 10000);
% t=1/Fs*0:(10000-1);
% plot(t, y);
% fmtz=0;
% dB_scale=1;
% 
% [ytick_m, YTickLabel1, ytick_good, ytick_new, yticklabel_new]=fix_YTick(fmtz, 1);
% 
% 
% % *********************************************************************
% %
% % Program Written by Edward L. Zechmann 
% % 
% %     date  8 August      2007
% % 
% % modified 10 February    2009    Added plot in dB scale
% % 
% % modified 22 March       2009    Updated Comments
% % 
% % 
% % *********************************************************************
% % 
% % Please feel free to modify this code.
% % 



if nargin < 1 || isempty(fmtz) || ~isnumeric(fmtz)
    fmtz=0; 
end

if nargin < 2 || isempty(dB_scale) || ~isnumeric(dB_scale)
    dB_scale=0;
end


YTickLabel1=get(gca, 'YTickLabel');
ytick_m=get(gca, 'YTick');
ylim1=get(gca, 'ylim');

max_yl=max(ylim1);
min_yl=min(ylim1);

ytick_ix_low=find(ytick_m < -0.25*(max_yl-min_yl)+max_yl );
ytick_ix_high=find(ytick_m > 0.25*(max_yl-min_yl)+min_yl );

ytick_good=intersect(ytick_ix_low, ytick_ix_high);

ytick_new=ytick_m(ytick_good);

for e1=1:length(ytick_good);
    if iscell(YTickLabel1(ytick_good(e1), :))
        yticklabel_new{e1}=YTickLabel1{ytick_good(e1), :};
    else
        yticklabel_new{e1}=YTickLabel1(ytick_good(e1), :);
    end
    
end

if length(ytick_good) < 3  || fmtz
    
    if fmtz == 1
        
        buf=max(abs([max_yl, min_yl]));
        
        max_yl=buf;
        min_yl=-buf;
        
    end

    max11=max_yl-0.25*(max_yl-min_yl);
    min11=min_yl+0.25*(max_yl-min_yl);
    
    dif=max11-min11;
    nd3=floor(log10(abs(dif)));
    nd33=log10(abs(dif));
    
    if nd3+0.302 >= nd33
        nd4=-nd3+1;
    else
        nd4=-nd3;
    end
    
    max1=sign(max11)*10^(-nd4)*floor(10^(nd4)*max11);
    min1=10^(-nd4)*ceil(10^(nd4)*min11);
    mean1=0.5*(max1+min1);
    
    ytick_new=[min1 mean1 max1];
    yticklabel_new=cell(3,1);
    for e1=1:3;
        if isequal(dB_scale, 1)
            buf=5*round(0.2*20*log10(abs(ytick_new(e1))/0.00002));
            yticklabel_new{e1}=num2str(buf);
            ytick_new(e1)=sign(ytick_new(e1))*0.00002*10^(buf/20);
        else
            yticklabel_new{e1}=num2str(ytick_new(e1));
        end
    end
    
end


set(gca, 'YTick', ytick_new, 'YTickLabel', yticklabel_new );

