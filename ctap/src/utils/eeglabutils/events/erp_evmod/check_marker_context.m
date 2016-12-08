function check_marker_context(EEG, trgmarker_arr, allmarkers_arr)

if ~exist('allmarkers_arr', 'var')
   allmarkers_arr = unique({EEG.event.type}); 
end

n_markers_before = 4;
n_markers_after = 4;

markers_match = ismember({EEG.event(:).type}, union(trgmarker_arr, allmarkers_arr));
Event = EEG.event(markers_match);

trgmarker_inds = find(ismember({Event(:).type},trgmarker_arr));

for i=1:length(trgmarker_inds)
   disp('==============================');
   
   start = max(1, trgmarker_inds(i)-n_markers_before); 
   stop = min(trgmarker_inds(i)+n_markers_after, numel(Event));
   
   {Event(start:stop).type}'
    
end