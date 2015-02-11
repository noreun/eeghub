
% Usually you can do the inspection of the results with your favorite tool
% Here we are going just to look at the results quicly
% And present the cluster / permutation tool implemented in eeghub

%% Set inspection parameters

results_path = '/data/eeghub_tutorial/EEGHUB_E_150_700_F_05_30_onepasszerophase_firws_A_80_013_33ms_cue/';
results_file_prefix = 'IArBadbefehspm8_';

%% usgin spm inspection tool

% inspect Subject 4
D = spm_eeg_load(fullfile(results_path, [results_file_prefix 'Suj4.mat']));
spm_eeg_review(D);


%% load manually

time = D.time;
subjects = dir (fullfile(results_path, [results_file_prefix '*.mat']));
nsuj = length(subjects);
data = zeros(2, nsuj, D.nchannels, D.nsamples);
for is =1:nsuj
    
    fprintf('loading subject %s \n', subjects(is).name);
    
    D = spm_eeg_load(fullfile(results_path, subjects(is).name));
    c = D.conditions;

    cond1 = ~cellfun(@isempty, regexp(c, '^.*Face.*$', 'match'));
    data(1,is,:,:) = mean(D(:,:, find(cond1 & ~D.reject) ), 3); %#ok<*FNDSB>
    
    cond2 = ~cellfun(@isempty, regexp(c, '^.*Alternative.*$', 'match'));
    data(2,is,:,:) = mean(D(:,:, find(cond2 & ~D.reject) ), 3);
    
end


%% simple plot

figure;

electrodes_of_insterest = [93:97 103:108 111:116 120:124 133 134 166 174 178 170 161 158 167 175 187 149 159 168 176 188 199 150 200 189 177 169 160 151 201 190]; 

plot_cond1 = mean(data(1,:,electrodes_of_insterest,:),3);
plot(time, squeeze(mean(plot_cond1,2)), 'b', 'LineWidth', 2);

hold on;

plot_cond2 = mean(data(2,:,electrodes_of_insterest,:),3);
plot(time, squeeze(mean(plot_cond2,2)), 'r', 'LineWidth', 2);
legend({'Condition 1', 'Condition 2'})


%% cluster perm

% usually you need more then 3 subjects as used in this tutorial to get
% meaningful permutation statistics (here only 2^3 = 8 possible
% permutations)
% here we do it nevertheless for the sake of example

montecarloalpha = 0.2; % in the real world, this should be 0.05

s = size(plot_cond1); s(1) = [];
data2stat = reshape(plot_cond1 - plot_cond2, s);
permstatv2(2, data2stat, [], 'milliTime', time, 'clusteralpha', 0.05, 'montecarloalpha', montecarloalpha, 'detailed_legend', true);
