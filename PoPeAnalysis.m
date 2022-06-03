clear; clc; 
%% initialize data folders

datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
participants = participants(1:end);

%% Filter

Freq = 667;
NyqFreq = Freq/2;
fco = 5;
[B,A] = butter (2,fco*1.25/NyqFreq,'low');

condition = ["relax", "letgo", "resist"];
EMG = struct([]);
for i = 1 : length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawPoPePath = join(["D:\ThesisData\Data\P", subjectNumber, "\PoPe\"], '');
    matFiles = dir(fullfile(rawPoPePath, '*.mat'));
    matFiles = matFiles(2:end-1);
    
    for j = 1 : length(matFiles)
        fileName = join([rawPoPePath, matFiles(j).name], '');
        charName = convertStringsToChars(fileName);
        stringName = join(['Trial', charName(end-5)], '');
        load(fileName);
        data(:,6) = filtfilt(B,A, abs(data(:,6)-mean(data(:,6))));
        data(:,7) = filtfilt(B,A, abs(data(:,7)-mean(data(:,7))));
        if isfield(EMG, condition(ceil(j/8)))
         EMG.(condition(ceil(j/8))) = EMG.(condition(ceil(j/8))) + data;
        else
          EMG(1).(condition(ceil(j/8))) = data;
        end
        
    end
end
%%
for i = 1:3
    EMG.(condition(i))= EMG.(condition(i))/8;
end

plot(EMG.(condition(1))(:,1),EMG.(condition(1))(:,6))