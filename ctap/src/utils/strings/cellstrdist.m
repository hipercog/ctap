function arrout = cellstrdist(cellstr, str)
% CELLSTRDIST  computes Levenshtein and editor distance between a string
% and each member of a cell array of strings.

% parameter entry order not important
if iscell(str)
    if ischar(cellstr)
        temp = str;
        str = cellstr;
        cellstr=temp;
    else
        disp('Check inputs. Aborting cellstrdist()');
    end
end
%%
cellsize = numel(cellstr);
arrout = zeros(1, cellsize);

for i = 1:cellsize
    arrout(i) = strdist( cellstr{i}, str );
end
