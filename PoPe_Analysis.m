%% Clear workspace
clear all; clc; 
%% initialize data folders

datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
fs = 2000;
presamples =50*fs/1000;
aftersamples = 250*fs/1000;

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
    x2 = [epoched(2,1:end,1), fliplr(epoched(2,1:end,1))];    
    std_relax =  std(epoched_relax(:,:,7), 'omitnan');
    c1_relax = mean(epoched_relax(:,:,7))+std_relax;
    c2_relax = mean(epoched_relax(:,:,7))-std_relax;
    inBetween_relax = [c1_relax, fliplr(c2_relax)];
    std_letgo=  std(epoched_letgo(:,:,7), 'omitnan');
    c1_letgo = mean(epoched_letgo(:,:,7))+std_letgo;
    c2_letgo = mean(epoched_letgo(:,:,7))-std_letgo;
    inBetween_letgo = [c1_letgo, fliplr(c2_letgo)];
    std_resist =  std(epoched_resist(:,:,7), 'omitnan');
    c1_resist = mean(epoched_resist(:,:,7))+std_resist;
    c2_resist = mean(epoched_resist(:,:,7))-std_resist;
    inBetween_resist = [c1_resist, fliplr(c2_resist)];

%%
% figure()
% sgtitle(join(['Participant ', participants(i).name(2:end)]))
% subplot(131)
% title('Long let go')
% patch([epoched(2,1:end,1) fliplr(epoched(2,1:end,1))], [mean(epoched_relax(:,:,7),'omitnan')-std_relax  fliplr(mean(epoched_relax(:,:,7),'omitnan')+std_relax)], [0.8  0.8  0.8], 'LineStyle','none'); hold on;
% plot(epoched(2,1:end,1),mean(epoched_relax(:,:,7),'omitnan'), 'Color', [0 0 0]);
% hold off;
% xticks([ -50 0 50 100 150 200 250])
% ylabel('[\muV/max(\muV)]')
% xlabel('time [ms]')
% 
% subplot(132)
% title('Let go')
% patch([epoched(2,1:end,1) fliplr(epoched(2,1:end,1))], [mean(epoched_letgo(:,:,7),'omitnan')-std_letgo  fliplr(mean(epoched_letgo(:,:,7),'omitnan')+std_letgo)], [0.8  0.8  0.8], 'LineStyle','none'); hold on;
% plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,7),'omitnan'), 'Color', [0 0 0]);
% hold off;
% xticks([-50 0 50 100 150 200 250])
% ylabel('[\muV/max(\muV)]')
% xlabel('time [ms]')
% 
% subplot(133)
% title('resist')
% patch([epoched(2,1:end,1) fliplr(epoched(2,1:end,1))], [mean(epoched_resist(:,:,7),'omitnan')-std_resist  fliplr(mean(epoched_resist(:,:,7),'omitnan')+std_resist)], [0.8  0.8  0.8], 'LineStyle','none'); hold on;
% plot(epoched(2,1:end,1),mean(epoched_resist(:,:,7),'omitnan'), 'Color', [0 0 0]);
% hold off;
% xticks([-50 0 50 100 150 200 250])
% ylabel('Let go [\muV/max(\muV)]')
% xlabel('time [ms]')
    meanLongLetGo = mean(epoched_relax(:,:,7),'omitnan');
    meanLetGo = mean(epoched_letgo(:,:,7),'omitnan');
    meanResist = mean(epoched_resist(:,:,7),'omitnan');
    rmsSubj_longletgo = mean(meanLongLetGo);
    rmsSubj_letgo = mean(meanLetGo);
    rmsSubj_resist = mean(meanResist);
    subjData(i,1:8) = rmsSubj_longletgo;
    subjData(i,9:16) = rmsSubj_letgo;
    subjData(i,17:24) = rmsSubj_resist;  
    
    figure()
    
    plot(epoched(2,1:end,1),meanLongLetGo); hold on
    plot(epoched(2,1:end,1),meanLetGo);
    plot(epoched(2,1:end,1),meanResist);
    legend('Long let go', 'Let go', 'Resist')
    xticks([50 75 100])
    ylabel('Let go [\muV/max(\muV)]')
    xlabel('time [ms]')
    title(join(['Participant ', participants(i).name(2:end)]))

end
 %%
meas = reshape(subjData(:,1:24),[240,1]);

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
t = table(condition.',meas,...
'VariableNames',{'condition','meas1'});
Meas = table([1]','VariableNames',{'Measurements'});
[p,tblanova,stats] = anova1(meas,condition);
[c,~,~,gnames] = multcompare(stats);
tbl = array2table(c,"VariableNames", ...
    ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
tbl.("Group A") = gnames(tbl.("Group A"));
tbl.("Group B") = gnames(tbl.("Group B"))



% subplot(331)
% plot(epoched(2,1:end,1),epoched_relax(:,:,6), ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on;
% %plot(epoched(2,1:end,1),mean(epoched_relax(:,:,6),'omitnan'), '*');
% plot(epoched(2,1:end,1),mean(epoched_relax(:,:,6),'omitnan'), 'Color', [0 0 0]);
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% %ylim([0 90])
% title('Extensor')
% ylabel('Long let go [\muV/max(\muV)]')
% 
% subplot(332)
% plot(epoched(2,1:end,1),epoched_relax(:,:,7), ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on
% %plot(epoched(2,1:end,1),mean(epoched_relax(:,:,7),'omitnan'), '*');
% plot(epoched(2,1:end,1),mean(epoched_relax(:,:,7),'omitnan'), 'Color', [0 0 0]);
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% title('Flexor ')
% %ylim([0 90])
% 
% subplot(333)
% plot(epoched(2,1:end,1),((epoched_relax(:,:,4))))
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% title('Torque')
% 
% subplot(334)
% plot(epoched(2,1:end,1),epoched_letgo(:,:,6), ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on;
% %plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,6),'omitnan'), '*');
% plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,6),'omitnan'), 'Color', [0 0 0]);
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% ylabel('Let go [\muV/max(\muV)]')
% %ylim([0 90])
% 
% subplot(335)
% plot(epoched(2,1:end,1),epoched_letgo(:,:,7), ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on
% %plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,7),'omitnan'), '*');
% plot(epoched(2,1:end,1),mean(epoched_letgo(:,:,7),'omitnan'), 'Color', [0 0 0]);
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% %ylim([0 90])
% 
% subplot(336)
% plot(epoched(2,1:end,1),((epoched_letgo(:,:,4))))
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% subplot(337)
% xlabel('time [ms]')
% plot(epoched(2,1:end,1),epoched_resist(:,:,6), ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on;
% %plot(epoched(2,1:end,1),mean(epoched_resist(:,:,6),'omitnan'), '*');
% plot(epoched(2,1:end,1),mean(epoched_resist(:,:,6),'omitnan'), 'Color', [0 0 0]);
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% ylabel('Resist [\muV/max(\muV)]')
% %ylim([0 120])
% subplot(338)
% plot(epoched(2,1:end,1),epoched_resist(:,:,7), ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.1); hold on; 
% %plot(epoched(2,1:end,1),mean(epoched_resist(:,:,7),'omitnan'), '*');
% plot(epoched(2,1:end,1),mean(epoched_resist(:,:,7),'omitnan'), 'Color', [0 0 0])
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% xlabel('time [ms]')
% %ylim([0 120])
% subplot(339)
% plot(epoched(2,1:end,1),epoched_resist(:,:,4))
% xticks([-250 -200 -150 -100 -50 0 50 100 150 200 250 300 350 400 450])
% xlabel('time [ms]')