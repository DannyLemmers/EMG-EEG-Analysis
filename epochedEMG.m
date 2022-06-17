function [epochedData, means] = epochedEMG(data, presamples, aftersamples)
    indexes = find(data(:,9)==1);
    means = [];
    for i = 1 : length(indexes)
        samples = [indexes(i)-presamples:indexes(i)+aftersamples];
        if max(samples)>120000
            continue
        elseif samples(1) < 0
            epochedData(i,:,:) = nan([length(samples),9]);
            continue
        elseif mean(data(samples,4),3) == 0
            disp('mean was zero!')
            continue
        else
                means =mean(data(samples,4),1);
                epochedData(i,:,:) = data(samples,:);
                epochedData(i,:,1) = linspace(-presamples/2000*1000,aftersamples/2000*1000,aftersamples+presamples+1);
        end
    end