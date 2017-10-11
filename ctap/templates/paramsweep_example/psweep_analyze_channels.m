function results = psweep_analyze_channels(EEGclean, EEGart, EEG, EEGprepro,...
    SWEEG, SweepParams, savedir)

% Working with the output:
%results.rejections{2,'channel_names'}{1}{:}

%Number of blink related components
n_sweeps = numel(SWEEG);
dmat = NaN(n_sweeps, 2);
bad_chans_arr = {};

for i = 1:n_sweeps
    dmat(i,:) = [SweepParams.values{i},...
                numel(SWEEG{i}.CTAP.badchans.variance.chans) ];
    bad_chans_arr{i} = SWEEG{i}.CTAP.badchans.variance.chans;
    %fprintf('mad: %1.2f, n_chans: %d\n', dmat(i,1), dmat(i,2));
end

results.rejections = table(dmat(:,1), dmat(:,2), bad_chans_arr',...
                        'VariableNames', ...
                        {'mad_multip_factor','n_bad_chans','channel_names'});

                    
%% Visualize
figH = figure();
plot(dmat(:,1), dmat(:,2), '-o');
xlabel('MAD multiplication factor');
ylabel('Number of artefactual channels');
saveas(figH, fullfile(savedir, 'sweep_N-bad-chan.png'));
close(figH);


%% Test quality of identifications
%SweepParams.values
%EEG.CTAP.artifact.variance.channel_idx
%EEG.CTAP.artifact.variance.multiplier

th_value = 2;
th_idx = max(find( [SweepParams.values{:}] <= th_value ));

%SWEEG{th_idx}.CTAP.badchans.variance.chans

% channels identified as artifactual which are actually clean
tmp = setdiff(SWEEG{th_idx}.CTAP.badchans.variance.chans, ...
        EEG.CTAP.artifact.variance_table.name);

% wrecked channels not identified
tmp2 = setdiff(EEG.CTAP.artifact.variance_table.name, ...
        SWEEG{th_idx}.CTAP.badchans.variance.chans);

chm = ismember(EEG.CTAP.artifact.variance_table.name, tmp2);
EEG.CTAP.artifact.variance_table(chm,:);



end