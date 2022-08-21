datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
subjectNumber = "17";
rawEMGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\PoPe\raw\"], '');
matFiles = dir(fullfile(rawEMGPath, '*.mat'));
matFiles = matFiles(2:end-1);

for i = 1:length(matFiles)
     fileName = join([rawEMGPath, matFiles(i).name], '');
     load(fileName);
     data = data;
     tempdata = data;
     data(:,6) = tempdata(:,7);
     data(:,7) = tempdata(:,6);
     save(fileName, 'data')
end