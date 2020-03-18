function fg = plot_filter_response(EEG, EEG0, step, varargin)
%plot_filter_response - Plot filter response to spectrum and unit step function
% See also: plot_step_response_fir.m in CTAP

%% Parse inputs
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('EEG0', @isstruct);
p.addRequired('step', @isnumeric); % filter coefficients for step plot

p.addParameter('xlimits', [0 60], @isnumeric); %lower and upper bounds to plot
p.addParameter('chind', 1, @isnumeric); %channel index
p.addParameter('lineColors', {'blue','red'}, @iscellstr); %{original, filtered}

p.parse(EEG, EEG0, step, varargin{:});
Arg = p.Results;



%% Set up stuff
srg = [1, min(EEG.pnts, 2^12)]; %sample range

% Quality control 1/2: original PSD
x = EEG0.data(Arg.chind, srg(1):srg(2));
nfft = 2^nextpow2(length(x));
[Pxx0,~] = periodogram(x, hamming(length(x)), nfft, EEG0.srate); %V^2/Hz

% Quality control 2/2: filtered PSD
x = EEG.data(Arg.chind, srg(1):srg(2));
nfft = 2^nextpow2(length(x));
[Pxx,f] = periodogram(x, hamming(length(x)), nfft, EEG.srate);

PxxMat = [Pxx0, Pxx];


%% Create plot
fg = figure('Visible','off');
subplot(2,1,1);
ph = plot(f, 10*log10(PxxMat));
ph(1).Color = Arg.lineColors{1};
ph(2).Color = Arg.lineColors{2};
xlim(Arg.xlimits);

xlabel('Frequency (Hz)');
ylabel('Power (V^2/Hz in dB)');
legend('original','filtered');
title({sprintf('Power spectrum of channel %s', EEG.chanlocs(Arg.chind).labels);...
       sprintf('sample range %d:%d', srg)});

% Unit step response
subplot(2,1,2);
plot_step_response_fir(step, 'plotType', 'line', 'lineColors', Arg.lineColors);
