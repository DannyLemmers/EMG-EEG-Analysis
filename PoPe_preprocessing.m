%% Clear workspace
clear all; clc; 
%% initialize data folders

datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
fs = 200;
presamples = 30*fs/1000;
aftersamples = 200*fs/1000;
epoched_relax =[];
epoched_letgo = [];
epoched_resist = [];
for i = 2%:length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    k = 1;

    for j = 1: 24
        dat = PoPe_filterDat(i,j,k);
        k = k +1;
        if k > 8
            k = k-8;
        end
        epoched = epochedEMG(dat, presamples, aftersamples);
        if j<9
            epoched_relax = [epoched_relax; epoched];
        elseif j > 16 
            epoched_resist = [epoched_resist; epoched];
        else
            epoched_letgo =  [epoched_letgo; epoched];
        end
    end
    
end

%%
figure(8)
sgtitle('participant')
subplot(321)
plot(epoched(1,1:end,1),((epoched_letgo(:,:,8))))

title('Flexion')
ylabel('Relax')
subplot(322)
plot(epoched(1,1:end,1),((epoched_letgo(:,:,8))))

title('Extension')
subplot(323)
plot(epoched(1,1:end,1),((epoched_letgo(:,:,6))))

ylabel('Let go')
subplot(324)
plot(epoched(1,1:end,1),((epoched_letgo(:,:,7))))

subplot(325)
plot(epoched(1,1:end,1),((epoched_resist(:,:,6))))

xlabel('time [ms]')
ylabel('Resist')
subplot(326)
plot(epoched(1,1:end,1),((epoched_resist(:,:,7))))

xlabel('time [ms]')

while(0)
    figure(1)
    
    subplot(211)
    plot(data(:,1),data(:,3)./max(data(:,3)))
    xlim([0, 60])
    ylim([-3, 3])
    subplot(212)
    plot(reData(:,1),reData(:,3))
    xlim([0, 60])
    ylim([-3, 3])
end