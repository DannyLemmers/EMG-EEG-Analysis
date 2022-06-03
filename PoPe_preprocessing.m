%% Clear workspace
clear all; clc; 
%% initialize data folders

datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
fsNew = 200;
for i = 2 : 2%  length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawEMGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\PoPe\raw\"], '');
    matFiles = dir(fullfile(rawEMGPath, '*.mat'));
    matFiles = matFiles(2:end-1);
    
    for j = 1 : 1% length(matFiles)
        fileName = join([rawEMGPath, matFiles(j).name], '');
        charName = convertStringsToChars(fileName);
        stringName = join(['Trial', charName(end-5)], '');
        load(fileName);
        tempData = data;
        tempData = upsample(tempData, 3);
        fs = round(1 /  (max(data(:,1))/length(data(:,1))));
        reData = resample(tempData,linspace(0,60, length(tempData)).',fsNew);
        reData = reData(1:12000,:)./max(reData(1:12000,1:end));
        reData(:,1) = linspace(0,60,12000);
    end

end

%%
figure(1)

subplot(211)
plot(data(:,1),data(:,3)./max(data(:,3)))
xlim([0, 60])
ylim([-3, 3])
subplot(212)
plot(reData(:,1),reData(:,3))
xlim([0, 60])
ylim([-3, 3])