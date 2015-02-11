
%
% Simple eeghub tutorial
% 
% 11/02/2015
%
%   Leonardo S. Barbos, lsbarbosa@gmail.com
%

%% Initial configuration : Please set the correct paths!
clear all
param = struct;

% change path to script path
cd(fileparts(mfilename('fullpath')))

% add eeghub to path
addpath_recurse(fullfile(pwd,'../'), '.git');

% do you have the necessary libraries in your path?
% addpath('/usr/local/spm8/');
% addpath('/usr/local/fieldtrip/');
% addpath('/usr/local/eeglab/');

% param.data.path = '/path_where_you_downloaded_the_data';
param.data.path = '/data/eeghub_tutorial/';
param.data.evt_extension = '.evt';
param.data.raw_extension = '.raw';

%% Define WHAT we are going to do, and in which order

actions = {...
    @eeghub_spm_prepare,               1;...
    @eeghub_fieldtrip_highpassfilter,  1;
    @eeghub_spm_epoching,              1;...
    @eeghub_spm_lowpassfilter,         1;...
    @eeghub_spm_crop,                  1;...
    @eeghub_spm_baseline,              1;...
    @eeghub_spm_ARautomatic,           1;...
    @eeghub_spm_eeglab_ARinterp,       1;...
};

%% Configuration of each step

%: eeghub_spm_prepare : parameters for import
param.badchan = [ ];   % in case some sensor is known to be bad

% keep the sensors file in the param because interpolation after
% artefact rejection will need it
param.fname_sensfile = 'egi64_GSN_HydroCel_v1_0';
param.fname_sensfileext = '.sfp';

% occasionaly, we can remove unused channels such as HEOG, etc (if they
% are not specified next)
param.removenoneeg = 0;

% create a simple array of sensors and fiducials and save in a .mat
% since spm_eeg_prep needs this format
% sensors and fiducials variables 
param.fname_sensfile = 'egi256_GSN_HydroCel';
% param.fname_sensfile = 'egi256_GSN_HydroCel_128subset';
param.fname_sensfileext = '.sfp';
param.sensfile = fullfile(pwd,[param.fname_sensfile '_sensors.mat']);
param.fidfile = fullfile(pwd,[param.fname_sensfile '_fiducials.mat']);
if ~exist(param.sensfile,'file') || ~exist(param.fidfile,'file')

    fid = fopen(fullfile(pwd,[param.fname_sensfile param.fname_sensfileext]),'r');
    sensC = textscan(fid,'%s %f %f %f',[4 inf]);
    fclose(fid);

    nchannels = size(sensC{1},1);
    sens = [sensC{2} sensC{3} sensC{4}];
    fid = sens([17 44 114],:);  
    
    % Save sensor positions and fiducials
    save(param.sensfile, 'sens');
    save(param.fidfile, 'fid');
end


%:  eeghub_fieldtrip_highpassfilter : High pass filtering uses FIR

% instead of butterworth coded in spm since it avoid contamination of
% early components by late activity (Acunzo et al. 2012 doi:10.1016/j.jneumeth.2012.06.011)
param.minfilter = 0.5;
param.minfilterorder = [];
param.minfiltertype = 'firws';
param.minfilterdir = 'onepass-zerophase';

%:  eeghub_spm_epoching : epoching

param.epoch.epochinfo = true; % provides a function that lists trials in the format : [ sample label; ...]
param.epoch.decode = @decode_event; % this is the function 

% for automatic event detection use param.epoch.epochinfo = false and :
% param.epoch.conditionlabel, param.epoch.eventtype, param.epoch.trialvalue
% for more information see eeghub_spm_epoch and spm_eeg_epochs

% this means that the information returned from decode_event is in sample, not in mili-seconds
param.epoch.sampled = true;

% set a big epoch so the we can crop afterwards and avoid border effects from filtering
param.epoch.pretrig = -1400;
param.epoch.posttrig = 1400;

%:  eeghub_spm_lowpassfilter: Lowpass filtering using butterworth
param.maxfilter = 30;

%:  eeghub_spm_crop : Crop trials to the final epoch sizes
param.crop.pretrig = -150; % time to keep before trial onset in ms
param.crop.posttrig = 700; % time to keep after trial onset in ms

%: eeghub_spm_baseline : baseline corerction
param.baselinewind = [param.crop.pretrig  0];

%:  eeghub_spm_ARautomatic : Detects individuals channels that pass the threshold in each trial

% consider only eeg channels in detection?
param.artefact.eegonly = true;

% param.artefact.ChTresh = 50;   %uV - 150uV (Bernal et al. 2010), 200uV (Rik Henson - demo data)
param.artefact.ChTresh = 80;   %uV - 150uV (Bernal et al. 2010), 200uV (Rik Henson - demo data)
% param.artefact.ChTresh = 150;   %uV - 150uV (Bernal et al. 2010), 200uV (Rik Henson - demo data)
% param.artefact.ChTresh = 100;   %uV - 150uV (Bernal et al. 2010), 200uV (Rik Henson - demo data)

% % gradient/slope threshold ?
% param.artefact.gradwin        = 10; % IN SAMPLES, NOT ms !
% param.artefact.gradthresh     = 100; % uV

%: eeghub_spm_eeglab_ARinterp : load the spm file and interpolate

% rejected channels using specified method

% The ratio of rejected bad channels before a trial is declared as bad
param.artefact.badtrialthresh = 0.13; % == 7 channels 

% The minimum number of good trials per condition (0 for disable)
param.artefact.badcondthresh = 0;   

% Interpolation approaches when interpolatin bad channels:
%     Fieldtrip: 'nearest', 'sphere_avg', 'sphere_weighteddistance'.
%     EEGLAB:  'invdist', 'spherical', 'spacetime'
param.artefact.interp_method = 'nearest';

	
%% Run the Pre Processing

% in parallel (one subject per thread)
param.parallel = true;
% param.parallel = false;

% if true, will create a folder with a few parameters in the name. We define our own
param.autonamedatafolder=0;

% check if we are doing high pass filtering
highpass = find(~cellfun(@isempty, (strfind(cellfun(@func2str, actions(:,1)', 'UniformOutput', false), 'highpassfilter'))));
if isempty(highpass) || actions{highpass,2} < 1
    filter_label = '0_(maxfilter%3.0f)';
else
    filter_label = '(minfilter%1.1f)_(maxfilter%3.0f)_(minfilterdir)_(minfiltertype)';
end

% specify the desired format
format_folder = [  'EEGHUB_E_(crop.pretrig)_(crop.posttrig)_' ...
    'F_' filter_label '_' ...
    'A_(artefact.ChTresh)_(artefact.badtrialthresh%0.2f)_' ...
    '33ms_cue'];
% extract information from the parameter structure and create folder name
[param.datafolderprefix, direxists] = eeghub_folder_name(param, format_folder, '%4.0f');

% Check if we didn't change some parameter that changes the folder name
% usually you want to manually create it before and copy
%
% * groupfile.mat
% * all output filest BEFORE the step you are re-doing (e.g. for Artefact
% Rejection, copy the output of eeghub_spm_baseline to the new folder and
% change eeghub_spm_ARautomatic to 2)
go = true;
if ~direxists
    reply = input('Create new preprocessing ? Y/N [Y]:','s');
    if isempty(reply), reply = 'Y'; end
    go = strcmp(reply, 'Y');
end

if go

    tic
    eeghub_main(param, actions);
    toc

    fprintf('Finised at : %s\n', datestr(now));
else
    fprintf('Nothing to do.\n');
end


%% close thread pool and remove added directories to avoid conflict with other projects

if matlabpool('size') > 0;
    matlabpool close; % free objects so we don't get warnings in the rmpath
end

