function fname_spm = core_remove_bad(param)

    % subtract the baseline average from the data
    S = [];
    S.D = param.fname_spm;
    D = spm_eeg_remove_bad_trials(S);
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);

end