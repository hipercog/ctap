function str = bionum2nimi(num, varargin)
%% Function bionum2nimi converts from a number to a Biosemi electrode name
%   
%   Syntax str = bionum2nimi( num, varargin )
%   num     -   matrix of numbers to convert, should be bounded [1, 261]
% 
% Varargin
%   capSize -   scalar, number of EEG trodes on cap, defines cutoff point
%               default: 128 (most common cap size CTAP sees)
%   pad     -   boolean, if mulitple numbers, pad output with rhs whitespace, 
%               default: true

P = inputParser;

P.addRequired('num', @isnumeric)

P.addParameter('capSize', 128, @(x) any(x == [16 32 64 128 160 256]))
P.addParameter('pad', true, @(x) islogical(x) | any(x == [0 1]))

P.parse(num, varargin{:})
P = P.Results;


% Handle matrix input
if ismatrix(num) && ~isscalar(num)
    [x,y] = size(num);
    str = cell(x,y);
    for i=1:x
        for j=1:y
            if P.pad
                str{i,j} = [bionum2nimi( num(i,j) ) '   '];
            else
                str{i,j} = bionum2nimi( num(i,j) );
            end
        end
    end
    return;
end

if iscell( num ),	num = num{:};   end

if isnumeric(num)
    str = sbf_names(num, P.capSize);
else
    num = str2double(num);
    if isnan(num)
        str = '';
    else
        str = sbf_names(num, P.capSize);
    end
end

    function str = sbf_names(num, cap)

        if num <= 0 || num > cap + 15
            disp('Biosemi eletrode out of range');
            str='NULL';
            return;
        end

        ref = 'ABCDEFGH';
        ref = ref(1:cap / 32);
        base = ceil(num / 32);
        if base == cap / 32 + 1
            base = 'EXG';
        else
            base = ref(base);
        end
        int = mod(num, 32);
        if int == 0, int = 32;  end
        str = strcat( base, num2str(int) );