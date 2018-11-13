function idx = canonical_eloc(chlocs, canon)
%CANONICAL_ELOC returns the index of a single channel location
%corresponding to one of the supported canonical locations (with 10/20 name):
% 
%     occipital = 'Oz'
%     parietal = 'Pz'
%     vertex = 'Cz'
%     frontal = 'Fz', 'Fp1', 'Fp2'
%     frontopolar = 'Fpz'
%     midleft = 'C3'
%     midright = 'C4'
%     frontleft = 'F3'
%     frontright = 'F4'
%     backleft = 'P3'
%     backright = 'P4'
%     farleft = 'T7'
%     farright = 'T8'
%   NOTE: if chanlocs are not 10/20, the function attempts to use Cartesian
%   coordinates and this is not guaranteed to work well.

idx = []; %#ok<NASGU>


%% Start by assuming 10/20 naming scheme
%Define canonical channel names, with matching location
locs.occipital = {'Oz'};
locs.parietal = {'Pz'};
locs.vertex = {'Cz'};
locs.frontal = {'Fz'}; %TODO: WHY WOULD WE WANT THESE ALSO? 'Fp1' 'Fp2'
locs.frontopolar = {'Fpz'};
locs.midleft = {'C3'};
locs.midright = {'C4'};
locs.frontleft = {'F3'};
locs.frontright = {'F4'};
locs.backleft = {'P3'};
locs.backright = {'P4'};
locs.farleft = {'T7'};
locs.farright = {'T8'};

%...and find the requested channel index by label
if ismember(canon, fieldnames(locs))
    idx = find(ismember({chlocs.labels}, locs.(canon)));
else
    error('canonical_eloc:bad_param'...
        , 'requested canonical location %s not supported', canon)
end


%% If 10/20 assumption fails, try using cartesian coordinates.
% WHAT IF NAMED CHANNELS DON'T EXIST? USE GEOMETRY TO FIND CANONICAL LOCATIONS,
% E.G. VERTEX, OCCIPITAL, FRONTAL
if isempty(idx)
% Convert to cartesian if needed, and assume cartesian coordinates have: 
% X = min at inion, max at nasion
% Y = min at right ear, max at left ear
    if ~isfield(chlocs, 'X') || ~isfield(chlocs, 'Y')
        if isfield(chlocs, 'theta') && isfield(chlocs, 'radius')
            [x, y] = pol2cart([chlocs.theta], [chlocs.r]);
            x = num2cell(x);    y = num2cell(y);
            [chlocs.X, chlocs.Y] = deal(x{:}, y{:});
        end
    end
    switch canon
        case 'occipital' % most negative / minimal X
            idx = find([chlocs.X] == min([chlocs.X]));

        case 'frontopolar' % most positive / maximal X
            idx = find([chlocs.X] == max([chlocs.X]));

        case 'farleft' % most positive / maximal Y
            idx = find([chlocs.Y] == max([chlocs.Y]));

        case 'farright' % most negative / minimal Y
            idx = find([chlocs.Y] == min([chlocs.Y]));

        case 'vertex' %assume the vertex is closest to x,y = 0,0
            xy = [min(abs([chlocs.X])); min(abs([chlocs.Y]))];

        case 'parietal' %parietal is halfway between vertex and inion
            xy = [min([chlocs.X]) / 2; min(abs([chlocs.Y]))];

        case 'frontal' %frontal is halfway between vertex and nasion
            xy = [max([chlocs.X]) / 2; min(abs([chlocs.Y]))];

        case 'midleft' %midleft is halfway between vertex and left ear
            xy = [min(abs([chlocs.X])); max([chlocs.Y]) / 2];

        case 'midright' %midright is halfway between vertex and right ear
            xy = [min(abs([chlocs.X])); min([chlocs.Y]) / 2];

        case 'frontleft' %frontleft has x = frontal, y = midleft
            xy = [max([chlocs.X]) / 2; max([chlocs.Y]) / 2];

        case 'frontright' %frontright has x = frontal, y = midright
            xy = [max([chlocs.X]) / 2; min([chlocs.Y]) / 2];

        case 'backleft' %backleft has x = parietal, y = midleft
            xy = [min([chlocs.X]) / 2; max([chlocs.Y]) / 2];

        case 'backright' %backright has x = parietal, y = midright
            xy = [min([chlocs.X]) / 2; min([chlocs.Y]) / 2];

    end
    if isempty(idx)
        [~, idx] = min(eucl_dist(xy, [[chlocs.X]; [chlocs.Y]]));
    end

end

end %canonical_eloc()