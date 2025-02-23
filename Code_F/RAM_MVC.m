function [S,iter,obj] = AM_MVC(X,Y,H,lambda)
% m      : the number of anchor. the size of Z is m*n.
% X      : n*di

%% initialize
maxIter = 50 ; % the number of iterations
numview = length(X);
numsample = size(Y,1);
k = length(unique(Y));

%% initial alpha
for iv = 1 : numview
    X{iv} = mapstd(X{iv},0,1);
    XX{iv} = X{iv}'*X{iv};
    alpha(iv) = 1/numview;
    W{iv} = eye(size(X{iv},2));
end

%% initial S
A = zeros(numsample,numsample); 
S = zeros(numsample,numsample); 
F = zeros(numsample-1,1); 
for iv = 1:numview
    XX1{iv} = X{iv}*X{iv}';
    for ii = 1:numsample
        for jj = 1:ii
            B{iv}(ii,jj) = XX1{iv}(ii,ii)+XX1{iv}(jj,jj)-2*XX1{iv}(ii,jj);
        end
    end
    B{iv} = B{iv}+B{iv}';
    A = A+alpha(iv)^2.*B{iv};
end
A = A./(4*lambda);
for ii=1:numsample
    F(1:ii-1) = A(1:ii-1,ii);
    F(ii:numsample-1) = A(ii+1:numsample,ii);
    ss = EProjSimplex_new_ZJP_V2(ones(1,numsample-1),F', 1);
    S(1:ii-1,ii) = ss(1:ii-1);
    S(ii+1:numsample,ii) = ss(ii:numsample-1);
end
clear XX1 A B;
L = diag(sum((S+S')/2))-(S+S')/2;
 
flag = 1;
iter = 0;
%%
while flag
    iter = iter + 1;

    %% optimize Wp
    for iv = 1:numview
        wv=W{iv};
        ap= XX{iv}+alpha(iv)^2*X{iv}'*L*X{iv};
        [~,L_lmd,~] = eig1(ap,k);
        L_lmd_max = max(L_lmd); 
        Lmx= L_lmd_max*eye(size(ap)) - ap;
        
        for rep = 1:20
            M = 2 * Lmx * wv +2 * XX{iv};
            [Um,~,Vm] = svd(M,'econ');
            wv = Um*Vm';
            
            fobj(rep+1) = trace( wv' * Lmx * wv ) + 2 * trace( wv' * XX{iv} );
            if rep>4 && ((fobj(rep)-fobj(rep-1))/fobj(rep)<1e-3)
                break;
            end
        end
        W{iv}=wv;
    end
    
    %% optimize S
    A = zeros(numsample,numsample); 
    S = zeros(numsample,numsample); 
    F = zeros(numsample-1,1); 
    for iv = 1:numview
        XW{iv} = X{iv}*W{iv};
        XWWX{iv} = XW{iv}*XW{iv}';
        for ii = 1:numsample
            for jj = 1:ii
                B{iv}(ii,jj) = XWWX{iv}(ii,ii)+XWWX{iv}(jj,jj)-2*XWWX{iv}(ii,jj);
            end
        end
        B{iv} = B{iv}+B{iv}';
        A = A+alpha(iv)^2.*B{iv};
    end
    A = A./(4*lambda);      
    for ii=1:numsample
        F(1:ii-1) = A(1:ii-1,ii);
        F(ii:numsample-1) = A(ii+1:numsample,ii);
        ss = EProjSimplex_new_ZJP_V2(ones(1,numsample-1),F', 1);
        S(1:ii-1,ii) = ss(1:ii-1);
        S(ii+1:numsample,ii) = ss(ii:numsample-1);
    end
    clear XWWX A B;
        
    L = diag(sum((S+S')/2))-(S+S')/2;
    
    %% optimize alpha
    M = zeros(numview,1);
    for iv = 1:numview
        M(iv) = trace(XW{iv}'*L*XW{iv})+eps;
    end
    Mfra = M.^-1;
    Q = 1/sum(Mfra);
    alpha = Q*Mfra;

    term1 = 0;
    term2 = 0;
    for iv = 1:numview
        term1 = term1 + norm(X{iv}-XW{iv},'fro')^2;
        term2 = term2 + alpha(iv)^2*M(iv);
    end
    
    obj(iter) = term1+term2+lambda*norm(S,'fro')^2;
    
	if (iter>1) && (abs((obj(iter-1)-obj(iter))/(obj(iter-1)))<1e-4 || iter>maxIter || obj(iter) < 1e-10)
%     if (iter>9)     
        A = zeros(numsample,numsample); 
        S = zeros(numsample,numsample); 
        F = zeros(numsample-1,1); 
        for iv = 1:numview
            H1{iv} = ones(size(X{iv},1),size(X{iv},2));
            Xnew{iv} = (H1{iv}-H{iv}).*(XW{iv})+X{iv};
            Xnew{iv} = mapstd(Xnew{iv},0,1);
            XX{iv} = Xnew{iv}*Xnew{iv}';
            for ii = 1:numsample
                for jj = 1:ii
                    B{iv}(ii,jj) = XX{iv}(ii,ii)+XX{iv}(jj,jj)-2*XX{iv}(ii,jj);
                end
            end
            B{iv} = B{iv}+B{iv}';
            A = A+B{iv};
        end
        A = A./(4*lambda);      
        for ii=1:numsample
            F(1:ii-1) = A(1:ii-1,ii);
            F(ii:numsample-1) = A(ii+1:numsample,ii);
            ss = EProjSimplex_new_ZJP_V2(ones(1,numsample-1),F', 1);
            S(1:ii-1,ii) = ss(1:ii-1);
            S(ii+1:numsample,ii) = ss(ii:numsample-1);
        end
        clear A B Xnew XX H1;
        flag = 0;
    end
end
         
         
    
