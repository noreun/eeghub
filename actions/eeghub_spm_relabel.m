function fname_spm = core_relabel(param)

    if ~isfield(param,'relabel')
        error('No parameters for relabelling!')
    else
        fprintf('Relabelling conditions for averaging\n')
    end
    D=spm_eeg_load(param.fname_spm);

    oldCond=param.relabel.old;
    newCond=param.relabel.new;
    newconditions=cell(size(D.conditions));
    newconditions(find(cellfun(@isempty,newconditions)))={'NA'};
    for nCond=1:length(oldCond)
        myT=find(cellfun(@any, regexp(D.conditions,oldCond{nCond})));
        newconditions(myT)=newCond(nCond);
    end
    D=conditions(D,[],newconditions);
    S.D = D;
    S.newname = ['C' S.D.fname];
    D = spm_eeg_copy(S);
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
end