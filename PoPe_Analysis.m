%% Clear workspace
clear all; clc; 
%% initialize data folders

datafolders = "C:\Users\Danny\Documents\Thesis\Data\P*";
participants = dir(datafolders);
fs = 2000;
presamples =100*fs/1000;
aftersamples = 350*fs/1000;

meanval = [];
for i = 1:length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    k = 1;
    epoched_relax =[];
    epoched_letgo = [];
    epoched_resist = [];
    for j = 1:24
        dat = PoPe_filterDat(i,j,k);
        k = k +1;
        if k > 8
            k = k-8;
        end
        [epoched, means] = epochedEMG(dat, presamples, aftersamples);
        if j<9
            epoched_relax = [epoched_relax; (epoched)];
        elseif j > 16 
            epoched_resist = [epoched_resist; (epoched)];
        else
            epoched_letgo =  [epoched_letgo; (epoched)];
           
        end
    end
    


%%
figure()
sgtitle(["participant ", subjectNumber])

subplot(331)
%plot(epoched(2,1:end,1),epoched_relax(:,:,6), '--', 'Color', [0.2 0.2 0.2]); hold on;
%plot(epoched(2,1:end,1),mean(epoched_relax(:,:,6),'omitnan'), '*');
plot(epoched(2,1:end,1),mean(epoched_relax(:,:,6),'omitnan'));
ylim([0 90])
title('Extensor')
ylabel('Long let go [\muV/max(\muV)]')

subplot(332)
%plot(epoched(2,1:end,1),epoched_relax(1:50,:,7), '--'); hold on
%plot(epoched(2,1:end,1),mean(epoched_relax(:,:,7),'omitnan'), '*');
plot(epoched(2,1:end,1),mean(epoched_relax(:,:,7),'omitnan'));
title('Flexor ')
ylim([0 90])

subplot(333)
plot(epoched(2,1:end,1),((epoched_relax(:,:,4))))
title('Torque')

subplot(334)
%plot(epoched(2,1:end,1),epoched_letgo(:,:,6), '--'); hold on;
%plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,6),'omitnan'), '*');
plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,6),'omitnan'));
ylabel('Let go [\muV/max(\muV)]')
ylim([0 90])

subplot(335)
%plot(epoched(2,1:end,1),epoched_letgo(1:50,:,7), '--'); hold on
%plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,7),'omitnan'), '*');
plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,7),'omitnan'));
ylim([0 90])

subplot(336)
plot(epoched(2,1:end,1),((epoched_letgo(:,:,4))))

subplot(337)
xlabel('time [ms]')
%plot(epoched(2,1:end,1),epoched_resist(:,:,6), '--'); hold on;
%plot(epoched(2,1:end,1),mean(epoched_resist(:,:,6),'omitnan'), '*');
plot(epoched(2,1:end,1),mean(epoched_resist(:,:,6),'omitnan'));
ylabel('Resist [\muV/max(\muV)]')
ylim([0 120])
subplot(338)
%plot(epoched(2,1:end,1),epoched_resist(1:50,:,7), '--'); hold on; 
%plot(epoched(2,1:end,1),mean(epoched_resist(:,:,7),'omitnan'), '*');
plot(epoched(2,1:end,1),mean(epoched_resist(:,:,7),'omitnan'))
xlabel('time [ms]')
ylim([0 120])
subplot(339)
plot(epoched(2,1:end,1),epoched_resist(:,:,4))
xlabel('time [ms]')
end
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