function fname_spm = core_baseline(param)

    % subtract the baseline average from the data
    S = [];
    S.D = param.fname_spm;
    S.time = param.baselinewind;
    D = spm_eeg_bc(S);
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);

end