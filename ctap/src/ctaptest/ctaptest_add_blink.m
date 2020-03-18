% Add a blink artifact to EEG data
%   eeg = ctaptest_add_blink(eeg,ampl,t_start,dur)

% Args:
%   eeg: EEG struct
%   ampl <double>: blink amplitude (in µV)
%   t_start <double>: blink start time (in s) 
%   dur <double>: blink duration (in s)
% Returns:
%   eeg: EEG struct with blink added to data
function eeg = ctaptest_add_blink(eeg, ampl, t_start, dur, jittering)
	if nargin < 5, jittering = false; end
	% Find sample-index corresponding to start time
	[~, start_idx] = min(abs(eeg.times - t_start * 1e3));

	% Calculate how many samples the blink duration is
	blink_dur = floor(dur * eeg.srate);

	% Generate blink-template
	% note that gauss distribution is not the best approximation of the blink
	% maybe try to replace this later with gamma or poisson
	blink = ampl * blink_shape('exp', blink_dur);
	% multiply blink template for each channel
	blink = repmat(blink, eeg.nbchan, 1);

	nose_loc = [1 0 0];
	chc = [[eeg.chanlocs.X]' [eeg.chanlocs.Y]' [eeg.chanlocs.Z]'];
	chd = eucl(chc, nose_loc);

	% This is the "propagation template" 
	% linear might not be good though
	x = linspace(0, 2, 100);
	c = [linspace(1, 0, 60) zeros(1, 40)];

	% combined blink template and propgataion template
	blink = blink .* repmat(interp1(x, c, chd), 1, size(blink, 2));

	% add some jitter
	if jittering
		blink = blink .* (rand(size(blink)) * 0.2 + 1);
	end

	% inject blink sequence into eeg
	eeg.data(:, start_idx:start_idx + blink_dur - 1) = ...
								eeg.data(:, ...
							   	start_idx:start_idx + blink_dur - 1) + blink;

	blink_params.time_window_s = [start_idx, start_idx + blink_dur - 1] / eeg.srate;
	blink_params.amplitude  = ampl;

	if isfield(eeg.CTAP.artifact, 'blink')
		eeg.CTAP.artifact.blink(end + 1) = blink_params;
	else
		eeg.CTAP.artifact.blink = blink_params;
	end
end

function shape = blink_shape(shape_type, blink_len)
	switch shape_type
		case 'gauss'
			shape = gauss(blink_len, 3);
		case 'exp'
			shape = (1:blink_len) .* (exp(-1 * (1:blink_len) / 15));
			shape = shape / max(shape);
		case 'exp2'
			shape = (1:blink_len) .* (exp(-1 * (1:blink_len).^1.5 / 15));
			shape = shape / max(shape);
		otherwise
			error('Shape not recognized!');
	end
end
