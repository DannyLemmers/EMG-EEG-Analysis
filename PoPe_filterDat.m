function data = PoPe_filterDat(subject, trial, prbsnumber)
    %%init
    datafolders = "D:\ThesisData\Data\P*";
    participants = dir(datafolders);
    subjectNumber = str2double(participants(subject).name(2:end));
    rawEMGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\PoPe\raw\"], '');
    matFiles = dir(fullfile(rawEMGPath, '*.mat'));
    matFiles = matFiles(2:end-1);
    prbsfile = join(["prbs\P_prbs_",string(prbsnumber) ,".mat"],'');
    fileName = join([rawEMGPath, matFiles(trial).name], '');
    charName = convertStringsToChars(fileName);
    stringName = join(['Trial', charName(end-5)], '');
    
    fsNew = 200;
    NyqFreq = fsNew/2;
    fco = 80;
    [B, A] = butter (3,fco/NyqFreq, 'low');
    %Band pass 
    %Eerst rectifying, cut off low pass 80 Hz
    prbs = load(prbsfile);

    load(fileName);
    tempData = data;
    
    oldFs = 1/(max(tempData(:,1))/length(tempData));
    if oldFs<=1000
        tempData = upsample(tempData, 3);
    end
    fs = round(1 /  (max(data(:,1))/length(data(:,1))));
    w = decimate(prbs.w,10,'fir');
    %w = resample(prbs.w,prbs.t.',fsNew);
    reData = resample(tempData,linspace(0,60, length(tempData)).',fsNew);
    reData(:,6) = filtfilt(B, A, abs(reData(:,6)-mean(reData(:,6))));
    reData(:,7) = filtfilt(B, A, abs(reData(:,7)-mean(reData(:,7))));
    reData(:,1) = linspace(0,60,12001);
    reData(:,8) = w(1:end);
    reData(:,9) = zeros(length(reData),1);
    reData(diff(w)>0.01016,9) = 1;
    data = reData;
    end