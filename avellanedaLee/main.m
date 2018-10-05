%This scripts assumes you start from A
%A is a matrix of returns and dates. All stocks are listed
%in columns and all days are listed in rows
%Anton Fadic
%Dic 2017
%TODO: Simulation and Backtesting

clearvars -except A

n = 4; %num of factors

%% Step 1. Compute the PCA
%for i=1:(length(A(:,1))-252-1) %look back for 1 year and 1 day
for i=1:length(A)-252
    %separate the observations into Apast i:252+i-1 and Anow 252+i (today)
    iend = 252+i-1;
    Apast = A(i:iend,:); % 252x471 %from 1-252.
    Atoday = A(i+252,:); %take today's return
    %B = Atemp - ones(252,1)*mean(Atemp); %this is to do PCA by hand
    [coeff, score, latent, tsquared, explained] = pca(Apast); %252x471
    %close all;plot(explained,'.'); %this plots the %explained variance
    
    % Step 2. Calculate the factors
    F(252+i,:) = Atoday*coeff(:,1:n); %this is the eigenvectors of the past with the information of Anext. Should generate only one data point
    %%
    if i>60
        %come here only if i>60
        regIndex = 252+i-60;
        for ii=1:471
            %beta = mvregress([F(1:60,:)],A(1:60,1)); %without constant term constant term
            % Step 3. Compute the linear regression and the residuals.
            [beta,~,resid] = mvregress([ones(60,1),F(regIndex:regIndex+60-1,:)],A(regIndex:regIndex+60-1,ii)); %with constant term
            alpha = beta(1)*252;
            resid = cumsum(resid); %cumulate of residuals
            [beta,sigma,resid] = mvregress([ones(59,1),resid(1:59)],resid(2:60)); %regres the cumulate
            a = beta(1);
            b = beta(2);
            
            k = -log(b)*252;
            m = a/(1-b);
            if (b<0)||(b>0.9672)
                s(regIndex,ii) = 0;
                smod(regIndex,ii) = 0;
            else
                seq = sqrt(var(resid)/(1-b^2));
                s(regIndex,ii) = -m/seq;
                smod(regIndex,ii) = s(regIndex,ii) - alpha/k/seq;
            end
        end
    end
end

