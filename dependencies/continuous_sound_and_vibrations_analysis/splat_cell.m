function [buf2, num_files_not_empty]=splat_cell(buf)
% % splat_cell: Returns a row vector of numbers containng all of the numbers in a cell array 
% % 
% % Syntax:   [buf2, num_files_not_empty]=splat_cell(buf);
% % 
% % *****************************************************************
% % 
% % Description
% % 
% % [buf2, num_files_not_empty]=splat_cell(buf);
% % Returns a row vector containing all of the numbers contained 
% % in the cell array buf.  
% % 
% % The input s is a cell array which was output from the 
% % Impulsive_Noise_Meter.  
% % 
% % This program is intended to be used with the 
% % make_table_compare_systems.  
% % 
% % *****************************************************************
% %
% %     date    1 September 2008
% %
% %  modified  10 September 2008  Updated comments.
% %
% %
% % *****************************************************************
% %
% % See Also:  Impulsive_Noise_Meter, Continuous_Sound_and_Vibrations_Analysis
% %


[nx ny]=size(buf);

bb=0;
num_files_not_empty=0;

for e1=1:nx;
    for e2=1:ny;
        
        bb=bb+length(buf{e1, e2});
        if ~isempty(buf{e1, e2})
            num_files_not_empty=num_files_not_empty+1;
        end
        
    end
end

buf2=zeros(bb,1);
bb=0;

for e1=1:nx;
    for e2=1:ny;
        
        bb2=bb+1;
        bb=bb+length(buf{e1, e2});
        
        if ~isempty(buf{e1, e2})
            buf2(bb2:bb)=buf{e1, e2};
        end

    end
end

