clear all; close all;
clc; 
addpath("eeglab\");
eeglab nogui;
%%
datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
conditions = {'1. Long let go', '2. Let go', '3. Resist'};
filenames = {'FiltIcaBrain65_'; 'FiltIcaBrain45_'; 'FiltIcaNoEye65_'; 'FiltIcaNoEye85_'; 'FiltNoIca_'};
type = filenames(3);
type = char(type);
k = 1;
for i = 1: length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawEEGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\EEG\set_filt"], '');
    sets = dir(fullfile(rawEEGPath, join([type, '*.set'], '')));
    run = 1;
    for j = 1 : length(sets)
        [STUDY, ALLEEG] = std_editset( STUDY, ALLEEG, 'name',type(1:end-1), 'filename', type(1:end-1),'commands' , ...
                {'index' k 'load' join([sets(j).folder, '\', sets(j).name], '') 'subject' mat2str(subjectNumber) 'condition' char(conditions(str2double(sets(j).name(end-5))))...
                'run' run 'session' 1},'updatedat','on', 'resave', 'on' );


        k = k+1;
        run = run + 1;
        mat2str(run)
        if run > 8
            run = run - 8;
        end
%         EEG = pop_loadset(sets(j).name, sets(j).folder); 
%         [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);
    end
    
end
CURRENTSET = length(ALLEEG);

