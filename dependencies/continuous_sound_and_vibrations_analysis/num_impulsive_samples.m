function [num_samples_ca, s]=num_impulsive_samples(s)
% % num_impulsive_samples: Counts the number of impulsive noise samples
% % 
% % Syntax:   [num_samples_ca, s]=num_impulsive_samples(s);
% % 
% % *****************************************************************
% % 
% % Description
% % 
% % [num_samples_ca, s]=num_impulsive_samples(s);
% % Returns the number of impulsive noise samples for each 
% % file, variables, and channel.  Teh output num_samples_ca is a 
% % cell array of row vetors.  
% % 
% % The input s is a cell array which was output from the 
% % Impulsive_Noise_Meter.  
% % 
% % This program is intended to be used with the 
% % make_table_compare_systems.  
% % 
% % *****************************************************************
% %
% % Written by Edward L. Zechmann
% %
% %      date  26 August 2008
% %
% %  modified  10 September     2008  Updated comments.
% %
% %
% % *****************************************************************
% %
% % See Also:  Impulsive_Noise_Meter, Continuous_Sound_and_Vibrations_Analysis
% %



[num_files, num_vars]=size(s);

num_samples_ca=cell(num_files, num_vars);

for e1=1:num_files;
    for e2=1:num_vars;
        
        num_chans=size(s{e1,e2}.metrics, 1);
        count=0;
        num_samples=zeros(num_chans,1);
        
        for e3=1:num_chans;
            
            if ~isempty(s{e1, e2})
                count=count+1;
                num_samples(count)=size(s{e1,e2}.metrics{count,1}, 1);
            end
        
        end

        num_samples_ca{e1, e2}=num_samples;
        
    end
end


for e1=1:num_files;
    for e2=1:num_vars;
        
        s{e1,e2}.num_samples=num_samples_ca{e1, e2};
        
    end
end

