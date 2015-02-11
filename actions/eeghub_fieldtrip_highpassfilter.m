function fname_spm = eeghub_fieldtrip_highpassfilter(param)            

    D = spm_eeg_load(param.fname_spm);

    % generate new meeg object with new filenames
    Dnew = clone(D, ['h' fnamedat(D)], [D.nchannels D.nsamples D.ntrials]);

    type = 'firws';
    %order = 250; %5*(param.minfilter*250);
    order = [];
    dir = 'onepass-zerophase';
    
    if isfield(param, 'minfiltertype')
        type = param.minfiltertype;
    end
        
    if isfield(param, 'minfilterorder')
        order = param.minfilterorder;
    end
        
    if isfield(param, 'minfilterdir')
        dir = param.minfilterdir;
    end

    Fs = D.fsample;
    Fchannels = unique([D.meegchannels, D.eogchannels]);

    fprintf('High filter (%2.2f | %s | %s ) for %s ...', param.minfilter, type, order, D.fname);

    % look for old version of fieldtrip preproc and remove from path
    x = regexp(path, ':', 'split');
    y = find(~cellfun(@isempty, strfind(regexp(path, ':', 'split'), 'spm8/external/fieldtrip/preproc')));
    if ~isempty(y)
        rmpath(x{y});
    end
    
    if strcmp(D.type, 'continuous')

        % work on blocks of channels
        % determine blocksize
        % determine block size, dependent on memory
        if isfield(param, 'freememperjob')
            freemem = .8 * param.freememperjob; % take 80% of available memory for this job (parallel)
        elseif isfield(param, 'freemem')
            freemem = .8 * param.freemem; % take 80% of available memory
        else
            % default, 1G
            freemem = 2^30;
        end

        fprintf(' memchunk %2.2f Gb ... ', freemem/2^30);
                
        datasz = nchannels(D)*nsamples(D)*8; % datapoints x 8 bytes per double value
        blknum = ceil(datasz/freemem);
        blksz  = ceil(nchannels(D)/blknum);
        blknum = ceil(nchannels(D)/blksz);

        % now filter blocks of channels
        chncnt=1;
        for blk=1:blknum
            % load old meeg object blockwise into workspace
            blkchan=chncnt:(min(nchannels(D), chncnt+blksz-1));
            if isempty(blkchan), break, end
            Dtemp=D(blkchan,:,1);
            chncnt=chncnt+blksz;
            %loop through channels
            for j = 1:numel(blkchan)

                if ismember(blkchan(j), Fchannels)
                    Dtemp(j, :) = ft_preproc_highpassfilter(Dtemp(j,:),Fs,param.minfilter,order,type,dir);
                end

            end

            % write Dtemp to Dnew
            Dnew(blkchan,:,1)=Dtemp;
            clear Dtemp;

        end;
    
    else
    
    
        for i = 1:D.ntrials

            d = squeeze(D(:, :, i));

            for j = 1:nchannels(D)
                if ismember(j, Fchannels)
                    d(j,:) = ft_preproc_highpassfilter(double(d(j,:)),Fs,param.minfilter,order,type,dir);
    %                 d(j,:) = ft_preproc_highpassfilter(dat,Fs,Fhp,N,type,dir,instabilityfix,df,wintype,dev,plotfiltresp);
                end
            end

            Dnew(:, 1:Dnew.nsamples, i) = d;

        end
    end

    fprintf('Done.\n');
    
    %if there was an old version of fieldtrip, put it back to avoid
    %compatibility errors
    if ~isempty(y)
        addpath(x{y});
    end
    
    %-Save new evoked M/EEG dataset
    %--------------------------------------------------------------------------
    D = Dnew;
    S = [];
    S.D = param.fname_spm;
    S.filter.band = 'high';
    S.filter.type = type;
%     S.filter.order = order;
    S.filter.dir = dir;
    S.filter.PHz = param.minfilter;
    D = D.history(mfilename, S);

    % save file name for future use
    D.save;
    fname_spm = fullfile(param.spm_datapath,D.fname);
    
end
