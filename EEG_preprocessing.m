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
        % Load the File and select right channels
        EEG = pop_loadset(setFiles(j).name, setFiles(j).folder);
        EEG = pop_select(EEG, "channel", [1:64, 67, 68]);
        EEG.data(65:66,:) = abs(EEG.data(65:66,:)-1); 
                EEG = pop_select(EEG, "nochannel", [13 19] );
        % Detect Events using leading edge
        EEG = pop_chanevent( EEG, [63:64], 'edge', 'leading', 'duration', 'on', 'delchan', 'on', 'delevent', 'on', 'nbtype', 1, 'typename', 'perb');
        % Remove first and last event, as they are not real events
        EEG.event = EEG.event(:,2:end-1);
        icafile = dir(fullfile(filtEEGPath, join(['*', num2str(nameArray(j)), '.mat'],'')));
        icafile = join([icafile.folder, '\', icafile.name], '');
        load(icafile);
        EEG.icaact = ICAstruct.icaact;
        EEG.etc = ICAstruct.etc;
        EEG.icawinv = ICAstruct.icawinv;
        EEG.icasphere = ICAstruct.icasphere;
        EEG.icaweights = ICAstruct.icaweights;
        EEG.icachansind = ICAstruct.icachansind;
        % Perform IC rejection using ICLabel scores
        brainIdx  = find(EEG.etc.ic_classification.ICLabel.classifications(:,3) <= 0.65);
        EEG = pop_subcomp(EEG, brainIdx, 0, 1);
        EEG = pop_select(EEG, "nochannel", [1 2 3 31 32 33 34] );
        EEG = pop_select(EEG, "nochannel", [1 28 10 14] );
        % Filter data from channels 1:64
        EEG = pop_eegfiltnew( EEG,'locutoff', 1, 'hicutoff', 70,'filtorder', [],'revfilt', [0], 'channels', [1:51]);
        EEG = pop_eegfiltnew( EEG,'locutoff', 49, 'hicutoff', 51,'filtorder', [],'revfilt', [1], 'channels', [1:51]);
        % Remove M1 and M2 and re-reference the signal
        EEG = pop_reref(EEG, []);
        %Epoch time data of trials
        EEG = pop_epoch(EEG, {}, [-0.3, 0.5]);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);
    end
end
%% Save filtered data
nameArray = [11 12 13 14 15 16 17 18 21 22 23 24 25 26 27 28 ...
             31 32 33 34 35 36 37 38];
k=1;
for i = 1:length(participants)
    for j = 1:24
        EEG = ALLEEG(k);
        pop_saveset(EEG, 'filename', join(['FiltIcaNoEye65_', char(num2str((nameArray(j))))],'') , 'filepath', char(join(["D:\ThesisData\Data\", participants(i).name, "\EEG\set_filt"], '')));
        k= k+1;
    end
end
