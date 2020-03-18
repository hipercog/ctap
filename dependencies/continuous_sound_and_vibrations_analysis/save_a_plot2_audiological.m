function save_a_plot2_audiological(fig_format, filename, flag2)
% % save_a_plot2_audiological: Saves current figure to specified image type.
% %
% % Syntax: save_a_plot2_audiological(fig_format, filename, flag2);
% %
% % **********************************************************************
% %
% % Description
% %
% % save_a_plot2_audiological(fig_format, filename);
% %
% % Saves the current figure to a file named by the string input filename
% % using the specified format given by the integer vector fig_format. The default format
% % is pdf.  The default file name is 'default_file_name'.
% %
% % The options for the format are
% %
% % fig_format=1; %  pdf
% % fig_format=2; %  fig
% % fig_format=3; %  jpeg 200 dpi
% % fig_format=4; %  epsc 200 dpi
% % fig_format=5; %  tiff 200 dpi
% % fig_format=6; %  no compression tiff
% %
% % save_a_plot2_audiological(fig_format, filename, flag2);
% % orients the paper usign teh integer intoput flag2.
% % Flag2=1, orients the paper in portrait.
% % For any other value of Flag2 the paper is in landscape.
% % The default paper orientation is portrait.
% %
% %
% % **********************************************************************
%
%
% Example='1';
%
% figure(1);
% plot([-1 1],[-1 1]);      % make a figure to save
% fig_format=1;                      % 1 pdf
%                           % 2 fig
%                           % 3 jpeg 200 dpi
%                           % 4 epsc 200 dpi
%                           % 5 tiff 200 dpi
%                           % 6 no compression tiff
%
% filename='straightline';  % The file name is a string
%
% flag2=0;                  % Orient the paper in landscape.
%                           % Values other than 1 result in landscape
%                           % orientation.
%
% save_a_plot2_audiological(fig_format, filename, flag2);
%
%
% % **********************************************************************
% %
% %
% % Subprograms
% %
% % List of Dependent Subprograms for
% % save_a_plot2_audiological
% %
% % FEX ID# is the File ID on the Matlab Central File Exchange
% %
% %
% % Program Name   Author   FEX ID#
% % 1) file_extension		Edward L. Zechmann
% %
% %
% % **********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date    April       2007
% %
% % modified 27 December    2007    Added a description and an example
% %                                 Added comments
% %
% % modified 21 August      2008    Updated Comments
% %
% % modified  6 October     2009    Updated comments
% %
% % modified  2 May         2012    Added support for saving to multiple 
% %                                 figure formats by supporting fig_format being 
% %                                 a vector. 
% %                                 Updated comments
% %
% % **********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also: print, saveas
% %

rect=[0.05 0.05 0.85 0.85];
hf=gcf;

if nargin < 1 || isempty(fig_format) || ~isnumeric(fig_format)
    fig_format=1;
end

if nargin < 2 || isempty(filename) || ~ischar(filename)
    filename='default_file_name';
end

if nargin < 3 || isempty(flag2) || ~isnumeric(flag2)
    flag2=1;
end

if flag2 == 1
    orientation='portrait';
else
    orientation='landscape';
end

set(hf, 'PaperOrientation', orientation, 'PaperType', 'usletter', 'PaperUnits', 'normalized', 'PaperPosition', rect, 'PaperSize', 0.6*[1.3 0.6] );

[filename, ext]=file_extension(filename);

for e1=1:length(fig_format);
    
    switch fig_format(e1)
        case 1
            set(hf, 'PaperOrientation', orientation, 'PaperType', 'usletter', 'PaperUnits', 'normalized', 'PaperPosition', rect );
            print(hf, '-dpdf',  filename );
        case 2
            saveas(hf, filename, 'fig'  );
        case 3
            print(hf, '-djpeg', '-r200', filename  );
        case 4
            print(hf, '-depsc2', '-r200', filename  );
        case 5
            print(hf, '-dtiff', '-r200', filename  );
        case 6
            print(hf, '-dtiffn', filename  );
        case 7
            print(hf, '-dmeta', filename  );
        otherwise
            set(hf, 'PaperOrientation', orientation, 'PaperType', 'usletter', 'PaperUnits', 'normalized', 'PaperPosition', rect );
            print(hf, '-dpdf',  filename );
    end
    
end
