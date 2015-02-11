%==========================================================================
%
%	eeghub is meant to be a bridge between many different m/eeg tools.
% the idea is to use the best of each one, avoiding repeting code and 
% optimizing everyday pipelines, like reruning the analysis after change
% in some parameter.
%
% 	For this end eeghub controls the execution of each step in the 
% preprocessing of the eeg data, evaluating the need to re-run it in case
% some parameter changed, even if it affects the steps after it.. 
%
%	eeghub reuses the output of each step as the input for the next one
% in the case where nothing changed, but it forces the execution of a step
% (even if no parameters specific for this step where changed) in the case
% some step before it needed to be executed.
%
% Mandatory Input:    
%
%       param      	      - configuration of what needs to be done
%
%    	actions           - cell with instructions to run per subject : import data, filter, reject artefact, average, contrast, etc
% 
% Optional Fields :
%
%	groupsdirs - cell with the dirs of the different groups with the data that follow the same preprocessing
%
%
% Authors:
%   Leonardo Barbosa, Ecole Normale Superieure
%   Thomas Andrillon, Ecole Normale Superieure
%   Carsten Stahlhut, Technical University of Denmark, DTU Informatics
%   Sid Kouider, Ecole Normale Superieure
%==========================================================================

function eeghub_main(param, actions, varargin)
    
    % set default path to SPM
    spm('defaults', 'eeg');
    
    % get current path
    [p,~,~] = fileparts(mfilename('fullpath'));
    
    % add path to lib folder
    libdirname = fullfile(p, 'lib');
    addpath(libdirname)
    
    % check we have compiled mex files
    check_mex_compiled([libdirname filesep 'semaphore.c'])

    % update available memory before preproc starts
    if isunix
        [~,w] = unix('free -b | grep Mem');
        stats = str2double(regexp(w, '[0-9]*', 'match'));
        param.memsize = stats(1);
        param.freemem = stats(3)+stats(end);
        fprintf('Available memory %2.2f Gb\n', param.freemem / 2^30);
    else
        % FIXME NEEDS TO BE TESTEST! no windows machine for the moment..
        [~, sys] = memory;
        param.memsize = sys.PhysicalMemory.Total;
%         param.freemem = user.MemAvailableAllArrays;
        param.freemem = sys.PhysicalMemory.Available;
    end
    
    % read input parameters
    % FIXME put all parameters inside param
    groupsdirs = {''}; % FIXME find a better way to deal with single group case 
    
    fixed = 3;
    if(nargin > fixed)
        for index = 1:2:(nargin-fixed),
            switch lower(varargin{index})
            	case 'groupsdirs'
        		    groupsdirs = varargin{index+1};
                otherwise
                    error('%s: Invalid input arguments',varargin{index});
            end
        end
    end

    % set default parameter values inside param structure
    if ~isfield(param, 'lrp'), param.lrp = 0; end
    if ~isfield(param, 'parallel'), param.parallel = false; end
    
    if ~isfield(param, 'freqtime'), param.freqtime.method = 'morlet'; end
    if ~isfield(param.freqtime, 'method'), param.freqtime.method = 'morlet'; end
    if ~isfield(param.freqtime, 'frequencies'), param.freqtime.frequencies = 1:2:100; end
    if ~isfield(param.freqtime, 'scale'), param.freqtime.scale = 'none'; end
    if ~isfield(param.freqtime, 'baselinewind'), param.freqtime.baselinewind = [param.epoch.pretrig/1000  0]; end

    if ~isfield(param, 'notchmethod'), param.notchmethod = 'sinfit'; end
    
    if ~isfield(param, 'fsample_new'), param.fsample_new = 0; end
    
    if ~isfield(param.epoch, 'sampled'), param.epoch.sampled = false; end
    if ~isfield(param, 'data'), param.data = struct; end
    if ~isfield(param.data, 'evt_extension'), param.data.evt_extension = []; end
    if ~isfield(param.data, 'raw_extension'), param.data.raw_extension = '.raw'; end
    if ~isfield(param, 'removenoneeg'), param.removenoneeg = 0; end

    if ~isfield(param, 'datafolderprefix'), param.datafolderprefix = 'V2dataFiles_'; end
    if ~isfield(param, 'autonamedatafolder'), param.autonamedatafolder = 1; end

    if ~isfield(param, 'multiplefiles'), param.multiplefiles = 0; end
    if ~isfield(param.artefact, 'forcenewautomatic'), param.artefact.forcenewautomatic = 1; end
    if ~isfield(param.artefact, 'eegonly'), param.artefact.eegonly = true; end
    if ~isfield(param.artefact, 'stdlim'), param.artefact.stdlim = 0; end
    if ~isfield(param.artefact, 'manualguiICA'), param.artefact.manualguiICA = 0; end

    if ~isfield(param, 'contrastweight'), param.contrastweight = 0; end
    
    if isfield(param, 'average') && ~isfield(param.average, 'trials')
        param.average.trials = 0;
    end
    if ~isfield(param, 'average') || ~isfield(param.average, 'robust')
        param.average.robust = 0;
        param.average.ks = 0;
    else
        if ~isfield(param.average, 'ks')
            param.average.ks = 3;
        end
    end
    
    % load initial values for artefact rejection parameters
    if ~isfield(param.artefact, 'ignorecond'), param.artefact.ignorecond = ''; end
    opts_artefact.thresh = param.artefact.ChTresh;
    opts_artefact.LevelBadCh = param.artefact.badtrialthresh;


    if isfield(param.artefact, 'gradwin')
        opts_artefact.gradwin = param.artefact.gradwin;
        opts_artefact.gradthresh = param.artefact.gradthresh;
        try opts_artefact.gradand = param.artefact.gradand; catch, opts_artefact.gradand = 0; end
        try opts_artefact.gradloop = param.artefact.gradloop; catch, opts_artefact.gradloop = 1; end
        
    end

    if isfield(param.artefact, 'borderthresh')
        opts_artefact.borderthresh = param.artefact.borderthresh;
    end

    param.opts_artefact = opts_artefact;

    % For each group of subjects
    for igroup=1:length(groupsdirs)

        param.group=char(groupsdirs(igroup));
        param.groupsdirs=groupsdirs;
        param.igroup=igroup;

        % directory with spm files reflects parameters used to create it
        if param.autonamedatafolder
            param.spm8dataFilesDir = [param.datafolderprefix num2str(param.artefact.badtrialthresh*100) 'chan_' num2str(param.artefact.ChTresh)  'trial_' num2str(param.epoch.pretrig) 'prestim'];
        else
            param.spm8dataFilesDir = param.datafolderprefix;
        end
        
        % Build directories names
        param.rawfiles_datapath = [param.data.path filesep param.group];
        param.spm_datapath = [param.rawfiles_datapath filesep param.spm8dataFilesDir];

        % create output folder if not exists
        if ~exist(param.spm_datapath, 'dir'); mkdir(param.spm_datapath); end; 

        % make sure the input folder with the raw data existis
        if ~exist(param.rawfiles_datapath,'dir')
            error('Directory %s doesnt exists', param.rawfiles_datapath);
        end
       
        % list input files 
        if ~isempty(param.data.evt_extension)

            % list all EVENT files
            allSubs=dir([param.rawfiles_datapath filesep '*' param.data.evt_extension]);

        elseif isfield(param, 'list_subjects')

            % retrieve prepared list
            listSub=param.list_subjects;
%             allSubs = struct(1,length(listSub));
            for nS=1:length(listSub)
                allSubs(nS).name=listSub{nS};
            end
        else
            error('Impossible to list subjects');
        end
        
        % make sure we have at least one subject to preprocess
        nsubs = length(allSubs);
        if ~nsubs
            fprintf('No subjects to process... probably path is wrong : %s \n', [param.rawfiles_datapath filesep '*' param.data.evt_extension]);
            return;
        end
        
        % index to record the files created for each step
        groupfiles = [];
        
        % load previously created index
        resultfile = [param.spm_datapath filesep 'groupfiles.mat'];
        if exist(resultfile, 'file')
            load(resultfile, 'groupfiles');
        end

        % add the current information about this specific preprocessing
        param.actions1level = actions;
        groupfiles.param = param;
        save(resultfile, 'groupfiles');
        
        % process each subject, in parallel if demanded
        poolsize = matlabpool('size');
        isOpen = poolsize > 0;
        if param.parallel
            
            % Start parallel processing, if necessary
            if ~isOpen
                fprintf('Oppening matlabpool...\n');
                if param.parallel > 1
                    matlabpool(param.parallel);
                else
                    matlabpool;
                end
            end
            
            poolsize = matlabpool('size');

            % specify memory per job
            param.freememperjob = param.freemem / poolsize;

            % create semaphore to avoid corruption of the index file
            param.semkey = 42;
            semaphore('create', param.semkey, 1);
            try
                parfor iSub = 1 : nsubs
                    process_one_subject(iSub, param, groupfiles, allSubs, actions);
                end
            catch e
                semaphore('destroy', param.semkey);
                rethrow(e)
            end
            semaphore('destroy', param.semkey);
        else
            for iSub = 1 : nsubs
                process_one_subject(iSub, param, groupfiles, allSubs, actions);
            end
        end

    end % End of loop for each group

end % End of eeghub_main function


% Code that goes over one subject
function thesefiles = process_one_subject(iSub, param, groupfiles, allSubs, actions1level)

    newfile = false;

    [~, param.fname] = fileparts(allSubs(iSub).name);
    fprintf('\n');
    disp(['     group ' num2str(param.igroup) ' of ' num2str(length(param.groupsdirs)) ' : ' param.group ' ; '...
          '     sub ' num2str(iSub) ' of ' num2str(length(allSubs)) ' : ' param.fname]);
    fprintf('\n');

    % First name the SPM file for this subject (subsequent files are
    % named automaticaly by SPM with prefix according to operations
    % aplied to the data : f : filtered, e : epoched, and so on)
    if ~isfield(param, 'start_file_prefix')
        param.fname_spm = fullfile(param.spm_datapath,['spm8_' param.fname '.mat']);
    else
        param.fname_spm = fullfile(param.spm_datapath,[ 'M' param.fname '.mat']);
    end

    % Then retrieve any previous work done in this subject
    varname = genvarname(['subject_' param.fname]);
    if isfield(groupfiles, varname)
        thesefiles = groupfiles.(varname);
    else
        thesefiles = [];
    end

    % Run all steps specified in actions1level : preproc, filter,
    % artifact rejection, etc IF it didn't run before OR force run
    % is specified 
    for iDo = 1:size(actions1level,1)

        actionfunction = actions1level{iDo,1};
        actionstatus = actions1level{iDo,2};
        actionname = func2str(actionfunction);

        % The function <doaction> verifies if we need to run each step. 
        % - If the actionstatus == 0, don't run. (go == false and dont update fname_spm)
        % - If the actionstatus == 1, AND 
        %       the field <thesefiles.actionname> exisits, don't run. (go == false and update fname_spm = thesefiles.actionname)
        %       the field DOES NOT exist, run for the first time. (go == true)
        % - If the actionstatus == 2, force run. (go == true)
        [go param.fname_spm] = doaction(actionstatus, actionname, thesefiles, newfile, param.fname_spm);
        if go
            if nargin(actionfunction) == 1
                param.fname_spm = actionfunction(param);
            elseif nargin(actionfunction) == 2
                [param.fname_spm, thesefiles] = actionfunction(param, thesefiles);
            else
                error('Action function %s for first level must have 1 or 2 input arguments.', func2str(actionfunction));
            end

            % Save the resulting filename to use in the future and
            % avoid re-processing the step
            [~, fil, ext] = fileparts(param.fname_spm);
            thesefiles.(actionname) = [fil ext];
            newfile = true;
            
            % After each step, save what we just did in the groupfiles.mat
            save_subject_files(param, allSubs(iSub).name, thesefiles)
        end
        
    end

end

% Utility function to decide if a step should be executed or 
% if the result from previous execution should be loaded instead
function [go fname_spm thesefiles] = doaction(what, action, thesefiles, newfile, fname_spm)

    % get the current path
    apat = fileparts(fname_spm);

    % if do.something == 0, do nothing.
    if what == 0
        go = false;
%         try
%             % delete the field if it exists
%             thesefiles = rmfield(thesefiles, action);
%         catch e
%         end
    else
        % if do.something == 2, always redo
        if what > 1
            go = true;
        else
            % if I didn't run any other previous do.something AND
            % I have the file name for this step, try to just use it
            % instead of running this step again
            if ~newfile && isfield(thesefiles, action) %&& exist([apat filesep eval(sprintf('thesefiles.%s', action))])~=0
                eval( [ 'tmp_fname_spm = thesefiles.' action ';' ]);
                
                % update the saved filename with the current path
                [~, ofil, oext]=fileparts(tmp_fname_spm); %#ok<NODEF> loaded with eval
                tmp_fname_spm = [apat filesep ofil oext];

%                 I think we should check this, but after countless
%                 problems recreating the files, I'm disabling it.
%                 % if the file exists, use it
%                 if exist(tmp_fname_spm, 'file')
                    fname_spm = tmp_fname_spm;
                    go = false;
%                 else
%                     % file was deleted, run again
%                     go = true;
%                 end
            else
                go = true;
            end
        end
    end
    
end

% Update index with what was done just now
function save_subject_files(param, filename, thesefiles)
    if param.parallel
        semaphore('wait',param.semkey); % BLOCK
    end

    % Load previous created files
    resultfile = [param.spm_datapath filesep 'groupfiles.mat'];
    if exist(resultfile, 'file')
        load(resultfile, 'groupfiles');
    else
        groupfiles = struct;
    end
    
    % get subject name
    [~, fname] = fileparts(filename);
    varname = genvarname(['subject_' fname]);
    
    % update structure
    groupfiles.(varname) = thesefiles;

    % save files index
    save(resultfile, 'groupfiles');
    if param.parallel
        semaphore('post',param.semkey); % UNBLOCK
    end
end
