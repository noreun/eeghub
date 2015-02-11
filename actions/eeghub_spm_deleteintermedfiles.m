function fname_spm = core_deleteintermedfiles(param, thesefiles)

    % Delete non Re-Usable files to save disk space

    % select the files I want to keep
    % If == 2, delete everything BUT the last.
    % If == 1, delete only files NOT IN the groupfiles.mat
    sthesefiles = struct2cell(thesefiles);
    if do.deleteintermedfiles == 1
        ini = 1;
    else
        ini = length(sthesefiles);
    end

    % find all the files
    fnamefiles = ls([param.spm_datapath filesep '*spm8_' param.fname '.*']);
    fnamefilesa = ossafe_ls_parse(fnamefiles, param.spm_datapath);
    for i = ini:length(sthesefiles)

        % take the prefix from the files saved in thesefiles
        goodmask = [filesep define_prefix(sthesefiles{i}) 'spm8_' param.fname]; 

        % For each file in the spm_datapath, remove from the
        % list if it is in the thesefiles
        nfiles = size(fnamefilesa,1);
        j=1;
        while j <= nfiles
            if ~isempty(regexp(fnamefilesa(j,:), goodmask, 'match'))
                fnamefilesa(j,:) = [];
                nfiles = nfiles - 1;
            else
                j=j+1;
            end
        end
    end

    % for the remaning files not removed from the list, delete them.
    for i=1:size(fnamefilesa,1)
        spm_unlink(deblank(fnamefilesa(i,:)));
    end
    
    fname_spm = param.fname_spm;
end