function fname_spm = denoise_eogreg(param)
%   
%    Apply time shifted regression of reference electrodes on epoched data.
%    should remove occular components (blinks, saccades, etc...) from the signal.
%    
%    ATTENTION : 
%       outliers trials (e.g. sd > 2) have to be removed before calling this
%       function !!!!!!
%    
%    input parameters :
%       param.denoise.time_shifts (default 10)
%           - array of shifts to apply
%       param.denoise.electrode_ref
%           - list of reference electrode index
%
%   Author: Romain Trachel (adapted from Alain Cheveigne - NoiseTools)
%   
    
    if isfield(param.denoise,'time_shifts')
        shifts = param.denoise.time_shifts;
    else
        shifts = 10;
    end
    
    if isfield(param.denoise,'electrode_ref')
        eeglist = param.denoise.electrode_ref;
    else
        eeglist = 225:256;
    end
    
    % load data and reshape it
    D = spm_eeg_load(param.fname_spm);
    
    x = permute(D(:,:,:),[2,1,3]);
    % normalize reference electrodes
    xref = nt_normcol(x(:,eeglist,:));
    % and smooth it
    xref = nt_smooth(xref, 2*shifts);
    % xref = xref(11:end,:,:);
    % regress out the PCA components
    clean = nt_tsr(x, xref, shifts);
    
    % duplicate D and save cleaned signals in a new spm structure
    Dnew = clone(D, ['eogreg_' fnamedat(D)], [D.nchannels length(D.time)-shifts D.ntrials]);
    Dnew(:,:,:) = permute(clean,[2,1,3]);
    % and copy the events inside this period
    for i = 1:D.ntrials
        Dnew = events(Dnew, i, select_events(D.events{i}, ...
            [D.trialonset(i)  (length(D.time)-shifts)/D.fsample]));
    end
    
    % need to copy the onsets to the new clone
    Dnew = trialonset(Dnew, [], D.trialonset);
    Dnew = timeonset(Dnew, D.time(shifts+1:end));
    
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);
end


% Utility function to select events according to time segment
function event = select_events(event, timeseg)

    if ~isempty(event)
        [time ind] = sort([event(:).time]);

        selectind = ind(time >= timeseg(1) & time <= timeseg(2));

        event = event(selectind);
    end
    
end