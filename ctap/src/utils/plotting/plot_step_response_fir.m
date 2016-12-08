function plot_step_response_fir(b, varargin)
%plot_step_response_fir - Plot FIR filter response to a unit step function
% See also: plotfresp.m in firfilt plugin for EEGLAB

%% Parse inputs
p = inputParser;
p.addRequired('b', @isnumeric); % FIR filter coefficients
p.addParameter('xlim', NaN, @isnumeric);
p.addParameter('ylim', NaN, @isnumeric);
p.addParameter('plotType', 'line', @isstr);
p.addParameter('lineColors', {'blue','red'}, @iscellstr); %{step, response}

p.parse(b, varargin{:});
Arg = p.Results;


%% Compute response
% Step response
% Response starts at first element of sr1 but time is shifted such that
% step will happen at x = 0.
n1 = length(b);
x1 = -(n1 - 1) / 2:(n1 - 1) / 2;
sr1 = cumsum(b); 


%% Create plot
switch Arg.plotType
    case 'line'
        plot(x1, sr1); %plot to get axes set up
    case 'stem'
        stem(x1, sr1); %plot to get axes set up
    otherwise
        error();
end

title('FIR unit step response');
ylabel('Amplitude');
xlabel('Sample');

%% Set axis limits
if ~isnan(Arg.xlim)
   xlim(Arg.xlim); 
end

if ~isnan(Arg.ylim)
   ylim(Arg.ylim); 
end


%% Add step function
hold on;

% plot step (cannot use line() as x=0 has many y values)
line([x1(1) 0], [0, 0], 'Color', Arg.lineColors{1}); % lower part
line([0 0], [0, 1], 'Color', Arg.lineColors{1}); % step
line([0 x1(end)], [1, 1], 'Color', Arg.lineColors{1}); % upper part

% Plot response on top (again)
switch Arg.plotType
    case 'line'
        line(x1, sr1,...
            'Marker', '.',...
            'Color', Arg.lineColors{2});
    case 'stem'
        stem(x1, sr1, 'Color', Arg.lineColors{2}); 
end

hold off;