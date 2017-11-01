function SEGMENT = generate_segment(blockfile)
% GENERATE_SEGMENT - Create variable SEGMENT based on blockfile
%
% Blockfile has to contain data indices as time variables.
% todo: name not descriptive. Very close to generate_segments.m...

bdef = read_block_defs(blockfile);

%% Preallocate memory space
n_trials = bdef.limits(end,2);
n_properties = length(bdef.property);
n_property_levels = length(fieldnames(bdef.property(1)))-1;


SEGMENT.labels = cell(1,n_properties*n_property_levels+1);
SEGMENT.units = SEGMENT.labels;
SEGMENT.data = cell(n_trials, n_properties*n_property_levels+1);
SEGMENT.units(:) = {'N/A'};

%% Create trial vector
inds = 1:n_trials;
SEGMENT.data(:,1) = mat2cell(inds', ones(1,n_trials),1);
SEGMENT.labels(1) = {'trial'};

%% Create trial metadata
ind = 2;
for n = 1:n_properties
    for i = 1:size(bdef.limits,1)

         i_match = (bdef.limits(i,1) <= inds) & (inds <= bdef.limits(i,2));


         %n_property_names = fieldnames(bdef.property(n))
         %for k = 1:n_property_levels
         SEGMENT.data(i_match,ind) = bdef.property(n).levelsShortStr(i,1);
         SEGMENT.data(i_match,ind+1) = bdef.property(n).levelsLongStr(i,1);
         SEGMENT.data(i_match,ind+2) = num2cell(bdef.property(n).levelsNum(i,1));


         %end
         SEGMENT.labels(ind) = {[bdef.property(n).name,]};
         SEGMENT.labels(ind+1) = {[bdef.property(n).name,'_lstr']};
         SEGMENT.labels(ind+2) = {[bdef.property(n).name,'_num']};  
    end

    ind = ind+3;
end

