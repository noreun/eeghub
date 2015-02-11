function fname_spm = core_contrasts(param)
    % recover the contrast model
    S = [];
    S.D = param.fname_spm;
    switch nargin(param.contrastmodel)
        case{0} 
            model = param.contrastmodel();
        case{1}
            model = param.contrastmodel(param.group);
        otherwise
            model = param.contrastmodel(param.group,param.fname);
    end

    % compute the contrasts
    S.c = cell2mat(model(:,1));
    S.label =model(:,2)';
    S.WeightAve = param.contrastweight;
    D = spm_eeg_weight_epochs(S);
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
end