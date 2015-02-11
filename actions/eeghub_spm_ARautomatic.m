function fname_spm = core_ARautomatic(param)

    % Tries to automaticaly find artefacts using absolute threshold, gradient threshold, etc
    D = spm_eeg_load(param.fname_spm);
    if param.artefact.eegonly
        ic = setdiff(D.meegchannels, D.badchannels); % get the good channels
    else
        ic = setdiff(1:D.nchannels, D.badchannels); %include also non-EEG
    end
    
    fprintf('Running automatic artefact rejection...');
    
    tic;

    % do it trial by trial to avoid memory problems
    badChType = zeros(size(ic,2), D.ntrials);
    badTrl = false(1,D.ntrials);
    rejectable = true(1,D.ntrials);
    if ~isempty(param.artefact.ignorecond)
        fprintf('\n(Ignoring conditions %s)\n',param.artefact.ignorecond);
    end
    for i = 1:D.ntrials
        if ~ mod(i,50), fprintf('%d.', D.ntrials-i); end
        data = D(ic,:,i);       %Only select good channels

        % Find the bad channels
        if isempty(regexp(D.conditions{i}, param.artefact.ignorecond, 'ONCE'))
            if isfield(param.artefact, 'specificond')
                cond = find(strcmp(D.conditions{i}, param.artefact.specificond), 1);
                if isempty(cond)
                    [~, TbadTrl, TbadChAbs, TbadChGrad] = artefacts_detect(data,param.opts_artefact); %#ok<ASGLU>
                else
                    [~, TbadTrl, TbadChAbs, TbadChGrad] = artefacts_detect(data,param.opts_artefact,cond); %#ok<ASGLU>
                end
            else
                [~, TbadTrl, TbadChAbs, TbadChGrad] = artefacts_detect(data,param.opts_artefact); %#ok<ASGLU>
            end
        else
            rejectable(i) = false;
            TbadChAbs= false(length(ic), 1);
            TbadChGrad= false(length(ic), 1);
            TbadTrl = 0; %#ok<NASGU>
        end
        %                     end

        % Bad channels by absolute threshold
        badChType(TbadChAbs,i) = 1;
        % Bad channels by Gradient threshold
        badChType(TbadChGrad,i) = 2;

        % for now mark only the channels, mask the trials latter
        % badTrl(i) = TbadTrl;
    end

    % also reject channels with more then maximum standard deviation
    if param.artefact.stdlim
        data = D(ic,:,:);
        data = reshape(data, size(data,1), size(data,2) * size(data,3), 1);
        TbadChStd = std(data,[],2) > param.artefact.stdlim;
        badChType(TbadChStd, rejectable) = 3;
    end

    t = toc;
    fprintf('Done!\nElapsed time : %f\n\n',t);

    % Also mark the fixed bad channels in param.badchannels
    badChAllType = zeros(D.nchannels,D.ntrials);
    badChAllType(D.badchannels,:)=4*ones(length(D.badchannels),D.ntrials);
    badChAllType(ic,:) = badChType; 
    save( fullfile(param.spm_datapath,['BadChannelsTypes_' param.fname '.mat']), 'badChAllType' );

    % Save this information in the BadChannels_ file
    badChAll = logical(badChAllType);
    save( fullfile(param.spm_datapath,['BadChannels_' param.fname '.mat']), 'badChAll' );

    % Also save the bad trials by threshold of bad channels
    save( fullfile(param.spm_datapath,['BadTrials_' param.fname '.mat']), 'badTrl');

    % Copy the file just to keep a diferent name
    S = [];
    S.D = D;
    S.newname = ['Bad' S.D.fname];
    D = spm_eeg_copy(S);

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
end
