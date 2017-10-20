function psuedo_box(h_array)
% % 
% % Draws black lines around the perimeter of the figure
% % 
% % 
% h_array=[];    % array of handles for the subaxes 
% psuedo_box(h_array)              
%
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Program Written by Edward L. Zechmann 
% %                date  8 August 2007
% %            modified 19 December 2007    added comments    
% %                                                         
% %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 
% % Please feel free to modify this code.
% % 

hold on;

for e1=1:length(h_array);
   	axes(h_array(e1));
    xlim1=get(gca, 'xlim');
    ylim1=get(gca, 'ylim');
    
    min_x1=min(min(xlim1));
    max_x1=max(max(xlim1));
    
    min_y1=min(min(ylim1));
    max_y1=max(max(ylim1));
    r=max_y1-min_y1;
    
    xlim11=[min_x1, max_x1];
    ylim11=[min_y1, max_y1];
    
    plot(min_x1*[1 1], ylim11, 'LineWidth', 0.5, 'color', [0 0 0] );
    plot(max_x1*[1 1], ylim11, 'LineWidth', 0.5, 'color', [0 0 0] );
    
    if e1 == 1
        plot(xlim11, max_y1*[1 1], 'LineWidth', 0.5, 'color', [0 0 0] );
    end
    
    if e1 == length(h_array)
        plot(xlim11, min_y1*[1 1], 'LineWidth', 0.5, 'color', [0 0 0] );
    end
    
end

hold off;