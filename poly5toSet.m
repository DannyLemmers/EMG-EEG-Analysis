clear; clc;
addpath("eeglab\")
eeglab nogui;

dataFolder = 'D:\ThesisData\Data\P*';
participants = dir(dataFolder);

for i = 1:length(participants)
    saveFolderEEG = join([dataFolder(1:end-2), participants(i).name,"\EEG\set_raw" ],'');
    if length(dir(fullfile(saveFolderEEG, '*.set')))> =24
        disp(join(['Participant ', participants(i).name, ' is already done'], ''))
    else
        dataFolderEEG = join([dataFolder(1:end-2), participants(i).name,"\EEG\poly5_raw\" ],'');
        polyFiles = dir(fullfile(dataFolderEEG, '*.poly5'));
        for j = 1:length(polyFiles)
            singleFile = join([dataFolderEEG,polyFiles(j).name], '');
            d = TMSiSAGA.Poly5.read(singleFile);
            load('EEGChannels64TMSi.mat', 'ChanLocs');   
            eegdataset = toEEGLab(d, ChanLocs);
            pop_saveset(eegdataset,'filename',polyFiles(j).name,'filepath',char(saveFolderEEG));
            disp(['Data saved as EEGlab dataset (.set) in this folder: ', char(saveFolderEEG)])
        end
    end
end
