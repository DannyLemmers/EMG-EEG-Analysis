function epochedData = epochedEMG(data, presamples, aftersamples)
    indexes = find(data(:,9)==1);
    for i = 1 : length(indexes)
        samples = [indexes(i)-presamples:indexes(i)+aftersamples];
        if max(samples)>12000
            continue
        else
            epochedData(i,:,:) = data(samples,:);
            epochedData(i,:,1) = linspace(-presamples/200*1000,aftersamples/200*1000,aftersamples+presamples+1);
        end
    end
