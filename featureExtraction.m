clear; clc; 
addpath("eeglab\");
eeglab nogui;
%%
datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
% dataFolder = 'D:\ThesisData\Data\P12\EEG\set_filt';
% sets = dir(fullfile(dataFolder, '*.set'));
highestSnrchan = [];
s50 = 60;
sm250 = 300;
load('EEGChannels64TMSi.mat');
channelsAnalysed = ['FC5' 'FC3' 'FC1' 'FCZ' 'C5' 'C3' 'C1' 'CZ' 'CP5' 'CP3' 'CP1' 'CPZ' 'P5' 'P3' 'P1' 'PZ'];
chanNums = [9 10 41 42 44 15 45 16 20 48 21 49 51 25 52 26];
for i = 1: length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawEEGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\EEG\set_filt"], '');
    sets = dir(fullfile(rawEEGPath, join(['FiltIcaNoEye65_', '*.set'], '')));
    for j = 1 :length(sets)
        EEG = pop_loadset(sets(j).name, sets(j).folder);
        [~, epochIndex] = find(ismember(EEG.times, [s50 sm250]));
        data = EEG.data(:,epochIndex(1):epochIndex(2),:);
        channels = {ChanLocs.labels};
        index = find(ismember(channels, ["FC1" "C1" "CP3"]));%% || channels == "M2");
        data = EEG.data(index,:,:);
        partdata(j,:,:) = mean(data,3);
    end
    rmsSubj_longletgo = rms((squeeze(partdata(1:8,:,:))),3);
    rmsSubj_letgo = rms((squeeze(partdata(9:16,:,:))),3);
    rmsSubj_resist = rms((squeeze(partdata(17:24,:,:))),3);
    subjData(i,1:8,:) = rmsSubj_longletgo;
    subjData(i,9:16,:) = rmsSubj_letgo;
    subjData(i,17:24,:) = rmsSubj_resist;   
end
%%
meas = reshape(subjData(:,1:24,2),[240,1]);

cond = ["long let go"; "let go"; "resist"];
k = 1;
condition = [];
for i = 1:240
        condition = [condition, cond(k)];
        if mod(length(condition),80) == 0
            k = k+1;
        end
end
%%

[~,~,stats] = anova1(meas,condition);
[c,~,~,gnames] = multcompare(stats);
tbl = array2table(c,"VariableNames", ...
    ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
tbl.("Group A") = gnames(tbl.("Group A"));
tbl.("Group B") = gnames(tbl.("Group B"))

