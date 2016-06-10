function str = myToString(in)
%MYTOSTRING converts whatever input into a printable format
%
% Description:
%   Uses a few tweaks to try and get a prettier output than just doing:
%   >> evalc(['disp(in)'])
%   However this is the default if input is not a cell or numeric array
%
%
% Syntax:
%   str = myToString(in)
%
% Inputs:
%   'in'            unknown, any Matlab data type
%
% Outputs:
%   'str'           string, some printable string version of 'in'
%
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ndims(in) > 2 %#ok<ISMAT>
        disp( ['Can''t convert: ' num2str(ndims(in)) 'D input to string!'] );
        str = in;
        return;
    end
    
    if iscell(in)
        if isscalar(in),    in = in{:};
        else
            if ismatrix(in) && ~isscalar(in)
                if size(in,1) > 1
                    if size(in,2) > 1
                        in = reshape( shiftdim(in,1), 1, size(in,1)*size(in,2) );
                    else
                        in = in';
                    end
                end
            end
            try
                in = cell2mat(in);
            catch iamerr,   
                disp( strcat('Can''t convert to string!', iamerr.identifier) );
            end
        end
    else
        if ismatrix(in) && ~isscalar(in)
            if size(in,1) > 1
                if size(in,2) > 1
                    in = reshape( shiftdim(in,1), 1, size(in,1)*size(in,2) );
                else
                    in = in';
                end
            end
        end
    end
    if isnumeric(in)
        in = num2str(in);
    end
    if isstruct(in) || ~ischar(in)
        in = evalc(['disp(in)']); %#ok<NBRAK>
    end
    str = in;
end
