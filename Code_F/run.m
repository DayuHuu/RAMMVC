clear;
clc;
warning off;
addpath(genpath('./'));

%% dataset
ds = {'BMNC-I'};
dsPath = './datasets/';
resPath = './Results/';
for dsi =1:1:length(ds)
    dataName = ds{dsi}; disp(dataName);
    load(strcat(dsPath,dataName));
    txtpath = strcat(resPath,strcat(dataName,'.txt'));
    if (~exist("resPath",'file'))
        mkdir(resPath);
        addpath(genpath(resPath));
    end
    k = length(unique(Y));
    n = length(Y);
    numview = length(X);
    lambda = [100];

    for iv = 1:1:numview
        X{iv} = double(X{iv});
        H{iv} = findMP(X{iv},k);
%         H{iv} = ones(size(X{iv},1),size(X{iv},2));
    end
    allresult = [];
    for id = 1:length(lambda)
        tic;
        [S,iter,obj] = RAM_MVC(X,Y,H,lambda(id));
        F = SpectralClustering((S+S')/2, k);
        stream = RandStream.getGlobalStream;
        reset(stream);
        MAXiter = 1000; 
        REPlic = 20;
        time1 = toc;
        for rep = 1 : 20
            pY = kmeans(F, k, 'maxiter', MAXiter, 'replicates', REPlic, 'emptyaction', 'singleton');
            res(rep, : ) = Clustering8Measure(Y, pY);
        end
        allresult = [allresult; mean(res) std(res) time1 lambda(id)];
    end
    [c,d] = max(allresult(:,1));
    maxresult = allresult(d,:);
    dlmwrite(txtpath, allresult, '-append', 'delimiter', '\t', 'newline', 'unix');

end


