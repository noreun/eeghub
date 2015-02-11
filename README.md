# eeghub

This is a matlab tool born from pratical needs during the pre-processing of eeg data.

It is a state machine to control the steps in the preprocessing of eeg, using popular tools such as fieldtrip, spm, eeglab, etc

Usually when you preprocess eeg data you need to import it from the raw data exported from the eeg aquisition machine, then set the correct electrode positions, filter, downsample, re-reference, epoch, artefact correct/reject, do the time-frequency decomposition, etc.

Since sometimes you just want to re-do one of these steps, and it's useful to have a state machine that knows which steps are already done, and re-do only the necessary work to avoid time consuming calculations. At the same time, if you redo an early pre-processing step, it's useful to automaticaly redo the steps after that. For instance if you change the filter parameters you probabily need to redo the artefact rejection/correction, and perhaps the epoching.

eeghub is designed to concentrate all parameters for the preprocessing of one protocol in a single script, usually called preprocess.m. It comes with example pre-processing scripts to import data, downsample, filter, epoch, artifact/correct reject, and some others, but we strongly encourage people to design it's own steps.

# Interface

The interace for each step is very simple : 

function fname = eeghub_mytool_mypreproc(param)
  
  D = load(param.fname);

  % use the struct param initially set by you to perform the preprocessing
  % 
  % e.g 
  
  D = mytool_mypreproc(D, param.dothis, param.likethat);
  
  % ...
  
  % return the name of the file created as output
  fname = fullfile(param.datapath, D.fname);

end

Where :

- mytool should be the name of the tool used, such as spm, fieldtrip, eeglab, etc
- my proproc should be the pro-processign you are doing, like prepare, filter, epoch, etc 

Afterwards, you should create a cell with the steps that should be applied in the correct sequence to your data,
and pass it to the eeghub_main function. Here is a simple example :

---------------------------------------

actions = {...
  @eeghub_spm_prepare,               1;...
  @eeghub_fieldtrip_highpassfilter,  1;...
  @eeghub_spm_epoching,              1;...
  @eeghub_spm_lowpassfilter,         1;...
  @eeghub_spm_crop,                  1;...
  @eeghub_spm_baseline,              1;...
};

param = struct;

% prepare parameters
param.data.path = data_path;
param.data.evt_extension = '.evt';
param.data.raw_extension = '.raw';

% highpass parameters
param.minfilter = 0.1;
param.minfilterorder = [];
param.minfiltertype = 'firws';
param.minfilterdir = 'onepass-zerophase';

% epoch parameters
param.epoch.pretrig = -1400;
param.epoch.posttrig = 1400;

% lowpass parameters
param.maxfilter = 40;

% crop parameters
param.crop.pretrig = -100;
param.crop.posttrig = 700;

eeghub_main(param, actions);

-----------------------------

This would import, high pass filter, epoch, low pass filter and crop the epochs into smaller epochs, to avoid
border effects from filtering.

If you want to redo the filter at 0.5, just change

param.maxfilter = 20;

and 

@eeghub_spm_lowpassfilter,  2;...
  
2 means to force this step. So when you run 

eeghub_main(param, actions);

it will just load each step, check it is already done, and try to the next, until it reachs 

eeghub_spm_lowpassfilter

where it will redo this step, and importantly, ALL THE STEPS AFTER THIS ONE.

in the end, there will be a folder with the out file of each step for each subject.
this user lots of disk, but ensures that it is easy to redo a given step.

If you did this before, you noticed that probably I sould have informed the events to epoch right? 
For this you could created a function that returns a matrix with epoch onset and label for each trial

function event = decode_event(fname,datapath)
    % ...
end

param.epoch.decode_event = @decode_event;

eeghub_main(param, actions);

And so on.. you can specify hundreds of parameters to at least 15 diferent possible pre-processing stages

# Examples

Please look the folder

tutorial 

It has a basic analysis for know, but very informative.

# Limitations

This software was made for very pratical reasons, so it should be very practical and at the same time needs a lot of caution while using, since it was just published and needs a lot of testing! Use it at your own risk!

If you wan't to help me to develop, you are welcome!

Known problems and tips :

- Don't use twice the same function in your pipe line! If you really need, make a copy of the function and rename it. This happens because the function name IS THE KEY to index the state machine, as the output file name is content of the state. Perhaps in the future I'll change this
- If you change a parameters, don't forget to change the step the uses it in the action cell to 2! otherwise it will go straight to the end. Perhaps also in the future I'll control parameters modifications.
- When you redo something, the output WILL BE OVERWRITEN! so make a copy of the folder. Create new folders for each possible run was constantly filling the disk, so it was disabled.
- The file with the state of the state machine is : groupfiles.mat. If you want to create a new preprocessing, just create a new folder and copy this file into it, the files outputed by the PREVIOUS step you want to run (e.g. to redo the high pass filter here, copy the output files from the epoching) and pass the name of the new folder

param.autonamedatafolder=0;
param.datafolderprefix = 'my_newly_created_folder_for_new_high_pass_filter_parameter';

- Finally, this is the first pre alpha version of this software, be nice :)
