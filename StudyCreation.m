clear all; close all;
clc; 
addpath("eeglab\");
eeglab nogui;
%%
datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
conditions = {'1. Relax', '2. Let go', '3. Resist'};
k = 1;
for i = 1: length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawEEGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\EEG\set_filt"], '');
    sets = dir(fullfile(rawEEGPath, '*.set'));
    run = 1;
    for j = 1 : length(sets)
        [STUDY, ALLEEG] = std_editset( STUDY, ALLEEG, 'name','Groupstudy','commands' , ...
                        {'index' k 'load' join([sets(j).folder, '\', sets(j).name], '') 'subject' mat2str(subjectNumber) 'condition' char(conditions(str2double(sets(j).name(end-5))))...
                        'run' mat2str(run) 'session' '1'},'updatedat','on' );
        k = k+1;
        run = run + 1;
        if run > 8
            run = run - 8;
        end
%         EEG = pop_loadset(sets(j).name, sets(j).folder); 
%         [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);
    end
    
end

%%
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels','erp', 'on', 'erpparams', {'rmbase' [-100 250]} ); 