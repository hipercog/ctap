function tmp2 = read_unique_ranges(srcfile)
%READ_UNIQUE_RANGES - Reads data written by write_unique_ranges()

fileID = fopen(srcfile,'r');
tmp = textscan(fileID,'%s');
fclose(fileID);

tmp = tmp{1}; %unwrap
tmp2 = cell(1,length(tmp)/2);
ind = 1;
for i=1:2:length(tmp)
    tmp2{ind} = {tmp{i}, tmp{i+1}};
    ind = ind + 1;
end