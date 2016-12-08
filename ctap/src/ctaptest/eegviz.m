% Dead simple EEG visualization function
%
% Jari Torniainen
% 2015
% Brain Work Research Centre, Finnish Institute of Occupational Health
% MIT License

function eegviz(dataset, varargin)

	if isstruct(dataset)
		dataset = dataset.data';
	end

	if length(varargin) == 1
		scale = varargin{1};
		indices = 1:size(dataset, 2);
	elseif length(varargin) == 2
		scale = varargin{1};
		indices = varargin{2};
	else
		scale = 100;
		indices = 1:size(dataset, 2);
	end
	dataset = dataset(:, indices);

	dataset = bsxfun(@plus, dataset, (1:size(dataset, 2)) * scale);

	fg = figure();
    plot(dataset, 'k');
    axis tight;
    set(gca, 'ytick', []);
    close(fg);
end
