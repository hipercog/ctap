function write_unique_ranges(strArr, outfile)
%WRITE_UNIQUE_RANGES2FILE - Writes contiguous ranges the same string into a text file
%
% Can be used to store EEG.chanlocs.type into a text file.

%debug:
%strArr = {'a','a','b','c','c','c','c','a'};
%outfile = fullfile(tempdir,'CTAPsyn','test.txt');


uniqueStr = unique(strArr);
%indsArr = NaN(length(uniqueStr), 2);
%S = struct();
fileID = fopen(outfile,'w');
for i=1:length(uniqueStr)
    inds = find_contiguous_range(ismember(strArr, uniqueStr{i}), 1);
    %S.(uniqueStr{i}) = find_contiguous_range(ismember(strArr, uniqueStr{i}), 1);
    for k = 1:size(inds,1)
        fprintf(fileID,'%d:%d %s\n', inds(k,1), inds(k,2), uniqueStr{i});
    end
    
end
fclose(fileID);