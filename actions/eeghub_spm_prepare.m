function fname_spm = eeghub_spm_prepare(param)
   
    % Import the data
    S = [];
    S.dataset = fullfile(param.rawfiles_datapath,[param.fname param.data.raw_extension]);
    S.outfile = param.fname_spm;
    S.channels = 'all';
    S.timewindow = [];
    S.blocksize = 3276800;
    S.checkboundary = 1;
    S.usetrials = 1;
    S.datatype = 'float32-le';
    S.eventpadding = 0;
    S.saveorigheader = 0;
    S.conditionlabel = {'Undefined'};
    S.inputformat = [];
    S.continuous = true;
    S.autoloc = false;
    S.units='uV'; % it will be lost at montage anyway...
    D = spm_eeg_convert(S);
    
    % Remove bad channels
    if ~isempty(param.badchan)
        D = badchannels(D,param.badchan,1);
        D.save;
    end

    % Specifying which unit
    D = D.units(:,'uV');
    D.save;

    % specify EEG and REF channels
    % If I don't have the EEGCHANLABELS, take a sequence
    if ~isfield(param, 'eegchanlabelsfile')
        s = load(param.sensfile);
        neegchan = size(s.sens,1);
        if D.nchannels > neegchan
            D = chantype(D,1:neegchan,'EEG');
            D = chantype(D,neegchan+1:D.nchannels,'Other');
        else
            D = chantype(D,1:D.nchannels,'EEG');
        end
        D.save;
    else
        e = load(param.eegchanlabelsfile, 'eegchanlabels');
        eegchanlabelsindices = zeros(size(e.eegchanlabels)); %#ok<*USENS> comes from load
        for i=1:length(e.eegchanlabels)
            eegchan = find(strcmpi(D.chanlabels, e.eegchanlabels{i}));
            if eegchan
                eegchanlabelsindices(i) = eegchan;
            else
                error('Invalid EEG chan label : %s', e.eegchanlabels{i});
            end
        end
        D = chantype(D,eegchanlabelsindices,'EEG');
        otherchan = setdiff(1:D.nchannels,eegchanlabelsindices);
        if ~isempty(otherchan)
        D = chantype(D,otherchan,'Other');
        end
        D.save;
    end

    % Remove empty/non-existent channels if necessary/requested
    S = [];
    S.D = D;
    otherchan = find(strcmp(D.chantype, 'Other'));
    if ~isempty(otherchan) && param.removenoneeg
        if param.removenoneeg % if specified, remove all Other channels
            usedchan = setdiff(1:D.nchannels, otherchan);
        elseif isempty(find(D(otherchan, :, :))) % Or at least remove empty channels #ok<EFIND>
            usedchan = setdiff(1:D.nchannels, otherchan);
        else
            usedchan = 1:D.nchannels;
        end
    
        goodchan = ones(length(usedchan),1);
%         % Not deleting bad chans for now
%         [~,indxused] = intersect(usedchan,D.badchannels);
%         goodchan(indxused) = 0;

        S.montage.labelorg = D.chanlabels(usedchan);
        tra = diag(goodchan);
        if ~isfield(param, 'eegchanlabelsfile')
            S.montage.labelnew = S.montage.labelorg;
        else
            e = load(param.eegchanlabelsfile, 'eegchanlabels');
            S.montage.labelnew = e.eegchanlabels;
        end
        S.montage.tra = tra;
        if isfield(param, 'keepothers')
            S.keepothers = param.keepothers;
        else
            S.keepothers = 'no';
        end
        S.updatehistory=  0;
        D = spm_eeg_montage(S);
    end

    % for EGI 64 channels nets
    if D.nchannels==65 && strcmp(D.chanlabels{65},'E65')
        D = chantype(D,65,'EEG');
    end
    % Add sensor positions and fiducials
    if isfield(param, 'sensfile') && isfield(param, 'fidfile')
        S = [];
        S.sensfile = param.sensfile;
        S.source = 'mat';
        S.headshapefile = param.fidfile;
        S.fidlabel = 'nas lpa rpa';
        S.D = D;
        S.task = 'loadeegsens';
        S.save = 1;
        D = spm_eeg_prep(S);
    end
    
    %     % Code for verification of sensor positions in 3D
    %     figure
    %     plot3(sens(:,1),sens(:,2),sens(:,3),'.')
    %     hold on
    %     text(sens(:,1),sens(:,2),sens(:,3),ChLabels)
    %     axis equal
    %     grid on

    % Project 3D positions down to 2D for scalp maps
    S = [];
    S.D = D;
    S.task = 'project3d';
    S.modality = 'EEG';
    S.save = 1; S.updatehistory = 1;
    D = spm_eeg_prep(S);

    % save file name for future use
    D.save;
    fname_spm = fullfile(param.spm_datapath,D.fname);
end
