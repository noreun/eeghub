function fname_spm = eeghub_spm_crop(param)

    fprintf ('New croping function!\n');

    D = spm_eeg_load(param.fname_spm);
    if D.ntrials == 1
        error('Cant run second epoching without frist. Change do.epoching = 1 and do.epoching2 = 0');
    end

    fprintf('\nRunning second epoching...\n\n'); 

    % find the limits of the new epochs
    goodsamples = find(D.time >= 0.001*param.crop.pretrig & D.time <= 0.001*param.crop.posttrig);
    nsampl = length(goodsamples);

    % clone the spm object
    Dnew = clone(D, ['e' fnamedat(D)], [D.nchannels nsampl, D.ntrials]);

    % for each trial
    for i = 1:D.ntrials
        % copy only the desired samples
        d =  D(:,goodsamples,i);
        Dnew(:, :, i) = d;
        % and copy the events inside this period
        Dnew = events(Dnew, i, select_events(D.events{i}, ...
            [D.trialonset(i)+goodsamples(1)/D.fsample  D.trialonset(i)+goodsamples(end)/D.fsample]));
    end

    % need to copy the onsets to the new clone
    Dnew = trialonset(Dnew, [], D.time(goodsamples(1)) - D.time(1) + D.trialonset);
    Dnew = timeonset(Dnew, D.time(goodsamples(1)));

    % save cloned M/EEG dataset
    D = Dnew;
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
end

% Utility function to select events according to time segment
function event = select_events(event, timeseg)

    if ~isempty(event)
        [time ind] = sort([event(:).time]);

        selectind = ind(time >= timeseg(1) & time <= timeseg(2));

        event = event(selectind);
    end
    
end
