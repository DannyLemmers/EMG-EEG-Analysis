function data = PoPe_filterDat(subject, trial, prbsnumber)
    %%init
    datafolders = "D:\ThesisData\Data\P*";
    participants = dir(datafolders);
    subjectNumber = str2double(participants(subject).name(2:end));
    rawEMGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\PoPe\raw\"], '');
    matFiles = dir(fullfile(rawEMGPath, '*.mat'));
    matFiles = matFiles(2:end-1);
    if trial < 9
        prbsfile = join(["D:\ThesisData\prbs\P_prbs_long_",string(prbsnumber) ,".mat"],'');
        
    elseif trial > 16
        prbsfile = join(["D:\ThesisData\prbs\P_prbs_",string(prbsnumber) ,".mat"],'');
    else
        prbsfile = join(["D:\ThesisData\prbs\P_prbs_",string(prbsnumber) ,".mat"],'');
    end
     %prbsfile = join(["C:\Users\Danny\Documents\Thesis\PRBS Signal\P_prbs_long_",string(1) ,".mat"],'');
    fileName = join([rawEMGPath, matFiles(trial).name], '');
    charName = convertStringsToChars(fileName);
    stringName = join(['Trial', charName(end-5)], '');
    
    %fsNew = 200;
    NyqFreq = 2000/2;
    fco = 120;
    [B, A] = butter (3,fco/NyqFreq, 'low');
    [B2, A2] = butter (4,1/NyqFreq, 'high');
    %Band pass 
    %Eerst rectifying, cut off low pass 80 Hz
    prbs = load(prbsfile);

    load(fileName);
    tempData = data;
    
%     oldFs = 1/(max(tempData(:,1))/length(tempData));
%     if oldFs<=1000
%         tempData = upsample(tempData, 3);
%     end
%     fs = round(1 /  (max(data(:,1))/length(data(:,1))));
%     w = decimate(prbs.w,10,'fir');
    %w = resample(prbs.w,prbs.t.',fsNew);
%     reData = resample(tempData,linspace(0,60, length(tempData)).',fsNew);
    %data(:,6) = filtfilt(B, A, abs(data(:,6)-mean(data(:,6))));
    data(:,6) = filtfilt(B2, A2, data(:,6));
    data(:,6) = abs(data(:,6)-mean(data(:,6)));
    data(:,6) = filtfilt(B, A, data(:,6))*1000;
    
    %data(:,6) = filtfilt(B3, A3, data(:,6));
  
    %data(:,6) = normalize(data(:,6));
    %data(:,6) = data(:,6)/max(data(:,6));
    data(:,7) = filtfilt(B2, A2, data(:,7));
    data(:,7) = abs(data(:,7)-mean(data(:,7)));
    data(:,7) = filtfilt(B, A, data(:,7))*1000;
    
    %data(:,7) = filtfilt(B3, A3, data(:,7));
    
    %plot(data(:,7))
    %data(:,7) = normalize(data(:,7));
    %data(:,7) = data(:,7)/max(data(:,7));
    
    %data(:,7) = filtfilt(B, A, abs(data(:,7)-mean(data(:,7))));
    data(:,8) = prbs.w(1:end);
    v = diff(prbs.w);
    index = find(v>0);
    newImpulse = index(find(diff(index)>1));
    data(:,9) = zeros(length(data),1);
    data(newImpulse-78,9) = 1;
    end