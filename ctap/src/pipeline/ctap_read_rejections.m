function rejtab = ctap_read_rejections(inf)

hdr = textscan(fopen(inf), '%s', 1, 'Delimiter', ',');

cols = strsplit(hdr{:}{:}, ',');

data = textscan(fopen(inf), repmat('%s', 1, numel(cols))...
                    , 'Delimiter', ',', 'Headerlines', 1);
                
rnms = data{1};

bdix = contains(cols, '_bad');
pcix = contains(cols, '_pc');

least = find(bdix, 1);
bnms = {};
for ix = find(pcix)
    if ~all(bdix(least:ix - 1))
        error('ctap_read_rejections:failure', 'Sthg has gone terribly wrong!')
    end
    bads = cols(least:ix - 1);
    prts = cellfun(@(x) strsplit(x, '_'), bads, 'Un', 0);
    stfn = strjoin(unique(cellfun(@(x) x{1}, prts, 'Un', 0)), '_');
    bdnm = unique(cellfun(@(x) x{2}, prts, 'Un', 0));
    if numel(bdnm) > 1
        error('ctap_read_rejections:failure', 'Sthg has gone terribly wrong!')
    end
    bnms{end} = sprintf('%s_%s_%d:%d', stfn, bdnm, 1, numel(bads));
    least = ix + 1;
end

% vars = 

% sthg like this!
% rejtab = table(data...
%     , 'RowNames', rnms...
%     , 'VariableNames', [cols{1} bnms cols{pcix}]);

end %ctap_read_rejections()