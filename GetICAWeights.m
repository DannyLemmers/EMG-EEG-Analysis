%% Clear workspace, add eeglab to path and start up eeglab withou GUI

clear all; clc; 
addpath("eeglab\")
eeglab nogui;
%% initialize data folders

datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
% participants = participants(1:end);
nameArray = [11 12 13 14 15 16 17 18 21 22 23 24 25 26 27 28 ...
             31 32 33 34 35 36 37 38];
for i = 1 : length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawEEGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\EEG\set_raw"], '');
    filtEEGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\EEG\set_filt"], '');
    setFiles = dir(fullfile(rawEEGPath, '*.set'));
    for j = 1 : length(setFiles)
        setFiles(j).name
        % Load the File and select right channels
        EEG = pop_loadset(setFiles(j).name, setFiles(j).folder);
        EEG = pop_select(EEG, "channel", [1:64, 67, 68]); 
        EEG = pop_select(EEG, "nochannel", [1 2 3 13 19 63 64] );
        EEG = pop_eegfiltnew( EEG,'locutoff', 1, 'hicutoff', 120,'filtorder', [],'revfilt', [0], 'channels', [1:62]);
        EEG = pop_eegfiltnew( EEG,'locutoff', 49, 'hicutoff', 51,'filtorder', [],'revfilt', [1], 'channels', [1:62]);
        % Run ICA
        EEG = pop_runica(EEG, 'icatype', 'runica');
        EEG = iclabel(EEG);
        % Perform IC rejection using ICLabel scores
        ICAstruct.icaact = EEG.icaact;
        ICAstruct.etc = EEG.etc;
        ICAstruct.icawinv = EEG.icawinv;
        ICAstruct.icasphere = EEG.icasphere;
        ICAstruct.icaweights = EEG.icaweights;
        ICAstruct.icachansind = EEG.icachansind;
        save(join([filtEEGPath, '\ICAweights', num2str(nameArray(j))], ''), 'ICAstruct')
        
    end
end
% %% Save filtered data
% nameArray = [11 12 13 14 15 16 17 18 21 22 23 24 25 26 27 28 ...
%              31 32 33 34 35 36 37 38];
% k=1;
% for i = 1:length(participants)
%     for j = 1:24
%         EEG = ALLEEG(k);
%         pop_saveset(EEG, 'filename', join(['FiltIca_', char(num2str((nameArray(j)))), 'n'],'') , 'filepath', char(join(["D:\ThesisData\Data\", participants(i).name, "\EEG\set_filt"], '')));
%         k= k+1;
%     end
% end
