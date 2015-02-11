function fname_spm = core_ARinterp(param)


    % interpolate bad channels using the remaning channels

    % IMPORTANT DO NOT REMOVE TRIALS BEFORE INTERPOLATION AND DATA
    % IS PUT BACK TO THE D OBEJCT. THE FUNCTION
    % spm_eeg_remove_bad_trials.m WILL ALSO SORT THE TRIALS SUCH
    % THAT TRIALS WITH THE SAME CONDITIONS WILL BE IN ORDER AND
    % THEN THE INFO IN badChAll DOES NOT CORRESPOND TO THE TRIALS
    % IN THE NEW D

    if ~isfield(param.artefact,'manualgui'), param.artefact.manualgui=1; end
    
    S = [];
    D = spm_eeg_load(param.fname_spm);
    S.D = D;
    S.newname = ['IAr' S.D.fname];
    D = spm_eeg_copy(S);

    % if the file with the BadChannels was not createed in the last step, it must already exist                
    autochan = load(fullfile(param.spm_datapath,['BadChannels_' param.fname '.mat']),'badChAll');
    autotrial = load(fullfile(param.spm_datapath,['BadTrials_' param.fname '.mat']),'badTrl');
    mBadTrialFile = fullfile(param.spm_datapath, ['mBadTrials_' param.fname '.mat']);
    if param.artefact.manualgui && exist(mBadTrialFile, 'file')
        % Load the manualy bad channels
        b = load(fullfile(param.spm_datapath,['mBadChannels_' param.fname '.mat']),'badChAll');
        badChAll = b.badChAll;

        % if automatic has extra channels assume them as bad!
        nm = size(badChAll,1);
        na = size(autochan.badChAll,1);
        if nm < na
            badChAll(nm+1:na, :) = autochan.badChAll(nm+1:na, :);
        elseif na < nm
            autochan.badChAll(na+1:nm, :) = badChAll(na+1:nm, :);
        end

        % if required, override old automatic information with new one
        if param.artefact.forcenewautomatic
            badChAll(badChAll==1) = 0;
            badChAll(autochan.badChAll==1) = 1;
            fprintf('Using automatic bad channels instead of mBad* information\n');
        end

        badChAll = logical(badChAll);

        % Statistics of automatic and manual Bad Channels
        [nchannels,~] = find(badChAll);
        fprintf ('\n%d bad channels interpolated.\n', length(unique(nchannels)));                    
        percentmbad =  (size(find(badChAll-autochan.badChAll > 0),1) / size(find(badChAll),1)) * 100;
        fprintf ('%2.2f %% manually removed.\n', percentmbad);                    
        percentmunbad =  (size(find(badChAll-autochan.badChAll < 0),1) / size(find(badChAll),1)) * 100;
        fprintf ('%2.2f %% manually add bad channels.\n',percentmunbad);                    

        % Load the manualy bad trials
        b = load(fullfile(param.spm_datapath,['mBadTrials_' param.fname '.mat']),'badTrl');
        badTrl = b.badTrl;
        badTrl = logical(badTrl);

        % Statistics of automatic and manual Bad Trials
        trldiff = autotrial.badTrl - badTrl;
        ndiff = size(find(trldiff<0),2);
        fprintf('\nManual bad trials %d\n', ndiff);
%         totaldiff = [totaldiff ndiff]; 

    else
        fprintf('%i bad channels found!\n', sum(autochan.badChAll(:,1)));
        badChAll = autochan.badChAll;
        badTrl = autotrial.badTrl;
    end

    % Detect for bad trials
    Nc = size(badChAll,1);
    ratioBadCh = squeeze(sum(badChAll,1)/Nc);
    
%     save('qpasaBadCh','ratioBadCh');
%     save('qpasaparambadtr','param.artefact.badtrialthresh');
%     
    abadTrl = ratioBadCh > param.artefact.badtrialthresh;
    badTrl = badTrl | abadTrl;

    fprintf('Bad trials for thresh %2.0f%%/%d : %d of %d\n', param.artefact.badtrialthresh*100, param.artefact.ChTresh, length(find(abadTrl)), length(abadTrl));
    fprintf('Total bad trials : %d of %d\n\n', length(find(badTrl)), length(badTrl));

    % Report bad trials to the meeg object
    badtrialind = find(badTrl);
    if ~isempty(badtrialind)
        D = reject(D, badtrialind,1);
    end

    % print the statistics
    Ncond = length(D.condlist);
    goodtrl = zeros(1,Ncond);
    alltrl = zeros(1,Ncond);

    ratio=[];
    for ig=1:Ncond
        alltrl(ig) = length(pickconditions(D,D.condlist{ig},0)); % includes rejected trials
        goodtrl(ig) = length(pickconditions(D,D.condlist{ig})); % excludes rejected trials
        ratio=[ratio D.condlist{ig} ': ' num2str(goodtrl(ig)) '/' num2str(alltrl(ig)) '; ' ]; %#ok<*AGROW>
    end
    totalratio=[num2str(sum(goodtrl(:))) '/' num2str(sum(alltrl(:))) '; '];

    fid=fopen('rejectinfo.txt' , 'a');
    fprintf(fid, ' %s %s  ; %s ; %s ; All trials: %s %s %s rejected channels %s  \n ' ,datestr(now), param.group, param.spm8dataFilesDir, param.fname, totalratio, ratio, num2str(length(D.badchannels)), num2str(D.badchannels));
    fprintf(' %s %s  ; %s ; %s ; All trials: %s %s %s rejected channels %s  \n ' ,datestr(now), param.group, param.spm8dataFilesDir, param.fname, totalratio, ratio, num2str(length(D.badchannels)),num2str(D.badchannels));
    fclose(fid);

    D = interpolate_channels(D, param.artefact.interp_method, badTrl, badChAll, param.fname_sensfile);

    % save file name for future use
    D.save;
    fname_spm = fullfile(param.spm_datapath,D.fname);
   
    fprintf('\nInterpolation for subject %s done.\n\n', param.fname);

end