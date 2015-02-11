function fname_spm = core_average(param)

    % average all trials per condition

    % copy to a new file
    S = [];
    D = spm_eeg_load(param.fname_spm);
    S.D = D;
    S.newname = ['T' S.D.fname];
    D = spm_eeg_copy(S);

    % option to use only specified trials
    if param.average.trials
        D = reject(D, setdiff(1:D.ntrials,param.average.trials),1);
    end

    % sort trials according to the specified list
    S = [];
    S.D = D;
    try 
	if isempty(param.group)
		S.condlist = param.condlist;
	else
        	S.condlist = param.condlist.(param.group);
	end
    catch
        S.condlist = unique(D.conditions);
    end

%                 % -- Sanity check
%                 condiff = setdiff(D.condlist,S.condlist);
%                 if ~isempty(condiff)
%                     error('User %s has unexpected conditions : %s\n', fname, cprintf(condiff));
% %                     keyboard;
%                 end
%                 condiff = setdiff(S.condlist,D.condlist);
%                 if ~isempty(condiff)
%                     error('User %s has fewer conditions then expected : %s', fname, cprintf(condiff));
% %                     keyboard;
%                 end

    D = spm_eeg_sort_conditions(S);
    disp('Sorting conditions - done')
    D.save;

    % average the data
    S = [];
    S.D = D;
    if param.average.robust
        S.robust.savew = true;
        S.robust.bycondition = true;
        S.robust.ks = param.average.ks;
    else
        S.robust = false;
    end
    S.review = false;
    [D, Dvar] = spm_eeg_average(S); %#ok<NASGU> saved with save
% PARFORLIM                
%                 save(fullfile(spm_datapath,['var_' fname '.mat']), 'Dvar');
    D.save;

    % if robust average, low pass filter again because it introduces high-freq noise
    if param.average.robust
        S = [];
        %S.D = fullfile(spm_datapath,['mIArbreMfspm8_' fname '.mat']);
        S.D = D;
        S.filter.band = 'low';
        S.filter.type = 'butterworth';
        S.filter.order = 5;
        S.filter.dir = 'twopass';
        S.filter.PHz = param.maxfilter;
        D = spm_eeg_filter(S);
        D.save;
    end

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
    
end
