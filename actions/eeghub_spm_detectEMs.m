function core_detectEMs(CNT_filename,CNT_path)

% Debug
% CNT_path='/home/andrillon/Data/SleepSemanticDecision/semanticsleep_data/AllSubjects/EEGdata_NF/';
% CNT_filename='147.cnt';

hdr=ft_read_header([CNT_path filesep CNT_filename]);
data=ft_read_data([CNT_path filesep CNT_filename]);

HEOG=data(match_str(hdr.label,'HEOG'),:);
VEOG=data(match_str(hdr.label,'VEOG'),:);

param.Fs=hdr.Fs;
param.thresholdParam=[1.5 10]; %[detection thr (SD) exclusion thr (SD)]
param.exclusionParam=[2 1 0.4]; 
% (1) max time duration between negcross and poscross 
% (2) minimal duration between REMs (in seconds)
% (3) minimal initial slope (in )
param.displayFlag=0;


[REMs , false_detection] = detect_REMs_HEOG_VEOG(HEOG, VEOG, param);

mySubj=CNT_filename(1:findstr(CNT_filename,'.cnt')-1);
save(sprintf('%s/EMsDetection_%s',CNT_path,mySubj),'REMs','param')