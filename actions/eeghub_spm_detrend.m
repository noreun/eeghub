function fname_spm = core_detrend(param)

    D = spm_eeg_load(param.fname_spm);
    if D.ntrials == 1
        error('Detrend on epoched data!');
    end

    fprintf('\nRunning detrending...\n\n'); 

    % clone the spm object
    Dnew = clone(D, ['L' fnamedat(D)], [D.nchannels length(D.time) D.ntrials]);

    % for each trial
    for i = 1:D.ntrials
        % copy only the desired samples
        for nE=1:D.nchannels
            d =  squeeze(D(nE,:,i));
            LinFit=polyfit(D.time,d,1);
            d_detrended(nE,:)=d-(LinFit(1)*D.time + LinFit(2));
        end
        Dnew(:, :, i) = d_detrended;
    end
    % save cloned M/EEG dataset
    D = Dnew;
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
end
