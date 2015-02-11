function fname_spm = core_referencing(param)

    if ~isfield(param,'reref')
        param.reref='all';
    end
    % Re-reference to the average and add sensor locations, units, etc
    S = [];
    S.D = param.fname_spm;
    D = spm_eeg_load(S.D);
    if D.nchannels==65 && strcmp(D.chanlabels{65},'E65')
        D = chantype(D,65,'EEG');
    end
    S.D = D;

    % save EEG chqnnels
    types = D.chantype;
        
    % Rereference to the mean
    S.montage.labelorg = D.chanlabels;
    tra = diag(ones(D.nchannels,1));
    tra = detrend(tra, 'constant'); % rereference to the mean
    S.montage.labelnew = S.montage.labelorg;
    S.montage.tra = tra;
    S.keepothers = 'no';
    S.updatehistory=  1;
    D = spm_eeg_montage(S);

    % fix problem of loosing channel type during montage
    D = chantype(D, 1:D.nchannels, types);
    D.save;
    
    oldTypes=D.chantype;
    if isnumeric(param.reref)
        fprintf('... reref to '); for n=1:length(param.reref), fprintf('E%g ',param.reref(n)); end; fprintf('\n')
        S.montage.labelorg = D.chanlabels;
        tra = diag(ones(D.nchannels,1));
        %         tra = detrend(tra, 'constant'); % rereference to the mean
        tra(:,param.reref)=-1/length(param.reref);
        tra(param.reref,param.reref)=0;
        % Take out non-EEG channels from reref
        tra(setdiff(1:D.nchannels,D.meegchannels),:)=0;
        tra(setdiff(1:D.nchannels,D.meegchannels),setdiff(1:D.nchannels,D.meegchannels))=diag(ones(length(setdiff(1:D.nchannels,D.meegchannels)),1));
        S.montage.labelnew = S.montage.labelorg;
        S.montage.tra = tra;
        S.keepothers = 'no';
        S.updatehistory=  1;
        D = spm_eeg_montage(S);
        D = chantype(D,1:D.nchannels,oldTypes);
    elseif iscell(param.reref)
        fprintf('... reref to '); for n=1:length(param.reref), fprintf('%s ',param.reref{n}); end; fprintf('\n')
        S.montage.labelorg = D.chanlabels;
        tra = diag(ones(D.nchannels,1));
        %         tra = detrend(tra, 'constant'); % rereference to the mean
        rerefindexes=match_str(D.chanlabels,param.reref);
        tra(:,rerefindexes)=-1/length(param.reref);
        tra(rerefindexes,rerefindexes)=0;
        % Take out non-EEG channels from reref
        tra(setdiff(1:D.nchannels,D.meegchannels),:)=0;
        tra(setdiff(1:D.nchannels,D.meegchannels),setdiff(1:D.nchannels,D.meegchannels))=diag(ones(length(setdiff(1:D.nchannels,D.meegchannels)),1));
        S.montage.labelnew = S.montage.labelorg;
        S.montage.tra = tra;
        S.keepothers = 'no';
        S.updatehistory=  1;
        D = spm_eeg_montage(S);
        D = chantype(D,1:D.nchannels,oldTypes);
    elseif strcmp(param.reref,'all')
        fprintf('... reref to the MEAN\n')
        % Rereference to the mean
        S.montage.labelorg = D.chanlabels;
        tra = diag(ones(D.nchannels,1));
        tra = detrend(tra, 'constant'); % rereference to the mean
        % Take out non-EEG channels from reref
        tra(setdiff(1:D.nchannels,D.meegchannels),:)=0;
        tra(setdiff(1:D.nchannels,D.meegchannels),setdiff(1:D.nchannels,D.meegchannels))=diag(ones(length(setdiff(1:D.nchannels,D.meegchannels)),1));
        S.montage.labelnew = S.montage.labelorg;
        S.montage.tra = tra;
        S.keepothers = 'no';
        S.updatehistory=  1;
        D = spm_eeg_montage(S);
        D = chantype(D,1:D.nchannels,oldTypes);
    end
    
    if D.nchannels==65 && strcmp(D.chanlabels{65},'E65')
        D = chantype(D,65,'EEG');
    end
    save(D);
    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
    
end