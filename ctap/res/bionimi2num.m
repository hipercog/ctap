function num = bionimi2num( str, varargin )
%% Function bionimi2num converts from a Biosemi electrode name to number
%   
%   Syntax num = bionimi2num( str, varargin )
%   str     -   name of electrodes to convert, should be bounded [1, 261]
% 
% Varargin
%   capSize -   scalar, number of EEG trodes on cap, needed to interpret
%                       EXG trodes
%               default: 128 (most common cap size CTAP sees)

P = inputParser;

P.addRequired('str', @(x) ischar(x) | iscell(x) | iscellstr(x) | isstring(x))

P.addParameter('capSize', 128, @(x) any(x == [16 32 64 128 160 256]))

P.parse(str, varargin{:})
P = P.Results;



if isempty(str)
    num=[];
    return;
end

%Handle cell input
if iscell( str )
    % Handle matrix input
    if ismatrix(str) && ~isscalar(str)
        [x,y] = size(str);
        num = zeros(x,y);
        for i=1:x
            for j=1:y
                num(i,j) = bionimi2num( str{i,j} );
            end
        end
        return;
    else
        str = myToString(str);
    end
end
% Finally handle actual Biosemi trode string
if isnumeric(str)
    num = str;
else
    ref='ABCDEFGH';
    % Read the string's two parts
    mtch = regexp(str, '\D');
    ltr = str(mtch);
    num = str2double(strrep(str, ltr, ''));
    
    % Check format of input
    if strcmp('EXG', ltr)
        fprintf('Interpreting based on cap size: %d\n%s', P.capSize...
            , 'Set cap size with name/value pair: ''capSize'', N')
        num = num + P.capSize;
    elseif  ~contains(ref, ltr)  || isnan(num)
        error('bionimi2num:bad_string', '%s is no good; try again.', str)
    else
        % Convert to 1 number
        ltr = (strfind(ref, ltr) - 1) * 32;
        num = num + ltr;
    end
end