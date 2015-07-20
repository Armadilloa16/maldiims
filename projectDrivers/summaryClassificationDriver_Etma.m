clc
clear all
close all

% Add my code folders.
addCodePaths

%%
[isOctave,matType,matExt] = checkIsOctave();
  
%%
% Calibrant Details.
% calibrantMZ = [1296.685,1570.677,2147.199,2932.588];
% calibrantName = {'Angiotensin I','[Glu]-Fibrinopeptide B', ... 
%     'Dynorphin A','ACTH fragment (1-24)'};


%%
% Proccessing parameters
curDataParams = struct();
curDataParams.binSize = 0.25;
curDataParams.wiggle = true;
curDataParams.wiggle_den = 3;
curDataParams.ppmNormTol = true;
curDataParams.normTol = 10;

vFolNams = {'Etma_2kHz'};        

vDatTypes = {'Binary','Intensity','LogIntensity','SN','Area'};
vUseAnnot = [false true];

vNcal = [0 3 4];
v_minNspec_r = [1 100];
v_minNspec_bin = [1 100];






% fid = fopen('.\output\Etma_classification.txt','wt');

% Print Header
disp('Me, Mloo, N, Dataset, Method, DataType, Normalisation, includeEmptyValues, Smooth, CancerAnnotation, minNcal, minNspecPerCore, minNspecPerBin, nComponents, Wiggle')
% fprintf(fid,'Me, Mloo, N, Dataset, Method, DataType, Normalisation, includeEmptyValues, Smooth, CancerAnnotation, minNcal, minNspecPerCore, minNspecPerBin, nComponents, Wiggle\n');

curDataParams.nComponents = 0;

%% Dataset
for folnam_idx = 1:length(vFolNams)
curDataParams.folNam = vFolNams{folnam_idx};

%% Data Type
for datType_idx = 1:length(vDatTypes) 
curDataParams.dataType = vDatTypes{datType_idx};

%% Wiggled Binning
for w_n = 0:(curDataParams.wiggle_den-1)
curDataParams.wiggle_num = w_n;

%% Annotated Cancer Spectra
for use_cancer_annot = vUseAnnot
curDataParams.use_cancer_annot = use_cancer_annot;

%% Calibrant QA filter
for nCal_tol = vNcal
curDataParams.nCal_tol = nCal_tol;

%% Number of spectra per region filter
for nSpec_r = v_minNspec_r
curDataParams.nSpec_r_tol = nSpec_r;

%% Number of spectra per bin filter
for nSpec_bin = v_minNspec_bin
curDataParams.nSpec_bin_tol = nSpec_bin;

% vSmoothParams = [0];
% vNorm = [false];
% vUseEmptyVals = [true];

switch curDataParams.dataType
    case 'Binary'
        vSmoothParams = [0 0.15 0.25];
        vNorm = [false];
        vUseEmptyVals = [true];
        
    case {'LogIntensity','Intensity','SN','Area'}
        vSmoothParams = [0];
        vNorm = [false true];
        vUseEmptyVals = [true false];
end
        
%% Binary Smoothing
for s = vSmoothParams
curDataParams.smoothParam = s;

%% Normalisation
for n = vNorm
curDataParams.normalisation = n;

%% Include empty values when taking averages?
for includeEmptyVals = vUseEmptyVals
curDataParams.includeEmptyVals = includeEmptyVals;

    %% Load Patient Summary
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~strcmp(curDataParams.dataType,'Binary')
        curDataParams.dataType = 'Binary';
        curDataParams.normalisation = false;

        [mFileNam,regexpVars] = matFileNamSelect('pSummary',curDataParams);
        load([mFileNam matExt],'-regexp',regexpVars)
        pbdata = pdata;
        % Number of spectra per bin filter
        pbdata = pbdata(nSpec >= curDataParams.nSpec_bin_tol,:);

        curDataParams.dataType = vDatTypes{datType_idx};
        curDataParams.normalisation = n;
    end

    [mFileNam,regexpVars] = matFileNamSelect('pSummary',curDataParams);
    load([mFileNam matExt],'-regexp',regexpVars)

    % Number of spectra per bin filter
    pdata = pdata(nSpec >= curDataParams.nSpec_bin_tol,:);
        
    if ~curDataParams.includeEmptyVals
        pdata(pbdata > 0) = pdata(pbdata > 0)./pbdata(pbdata > 0);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    
    %% DWD
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    curDataParams.classificationMethod = 'DWD';
    [dvec,b,class_out] = DWD2XQ(pdata(:,p_suit & p_lnm), ...
                              pdata(:,p_suit & ~p_lnm), ...
                                2,pdata,100);
    class_out = (class_out==1);

    % LOO
    p_list_suit = p_list(p_suit);
    class_out_LOO = zeros(size(p_list_suit'));
    dvec_LOO = zeros(size(pdata,1),length(p_list_suit));
    b_LOO = zeros(size(p_list_suit));
    for p_idx = 1:length(p_list(p_suit))
        p = p_list_suit(p_idx);
        [dirvec,beta,dr] = DWD2XQ(pdata(:,p_suit & p_lnm & p_list ~= p), ...
                                  pdata(:,p_suit & ~p_lnm & p_list ~= p), ...
                                  2,pdata(:,p_list == p),100);
        class_out_LOO(p_idx) = (dr==1);
        dvec_LOO(:,p_idx) = dirvec;
        b_LOO(p_idx) = beta;
    end

    [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
    save(matType,[mFileNam matExt],'-regexp',regexpVars)

%     fprintf(fid,[num2str(sum(class_out(p_suit) ~= p_lnm(p_suit)')) ',' ...
%           num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%           num2str(sum(p_suit)) ',' ...
%           curDataParams.folNam ',' ...
%           curDataParams.classificationMethod ',' ...
%           curDataParams.dataType ',' ...
%           num2str(curDataParams.normalisation) ',' ...
%           num2str(curDataParams.includeEmptyVals) ',' ...
%           num2str(curDataParams.smoothParam) ',' ...
%           num2str(curDataParams.use_cancer_annot) ',' ...
%           num2str(curDataParams.nCal_tol) ',' ...
%           num2str(curDataParams.nSpec_r_tol) ',' ...
%           num2str(curDataParams.nSpec_bin_tol) ',' ...
%           num2str(curDataParams.nComponents) ',' ...
%           num2str(curDataParams.wiggle_num) '\n']);
    
    disp([num2str(sum(class_out(p_suit) ~= p_lnm(p_suit)')) ',' ...
          num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
          num2str(sum(p_suit)) ',' ...
          curDataParams.folNam ',' ...
          curDataParams.classificationMethod ',' ...
          curDataParams.dataType ',' ...
          num2str(curDataParams.normalisation) ',' ...
          num2str(curDataParams.includeEmptyVals) ',' ...
          num2str(curDataParams.smoothParam) ',' ...
          num2str(curDataParams.use_cancer_annot) ',' ...
          num2str(curDataParams.nCal_tol) ',' ...
          num2str(curDataParams.nSpec_r_tol) ',' ...
          num2str(curDataParams.nSpec_bin_tol) ',' ...
          num2str(curDataParams.nComponents) ',' ...
          num2str(curDataParams.wiggle_num)])
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
    %% NB
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    curDataParams.classificationMethod = 'NB';
    [class_out,dvec,b] = maldiDA(pdata(:,p_suit),p_lnm(p_suit)+1,'NaiveBayes',pdata);
    class_out = (class_out == 2);
    
    % LOO
    p_list_suit = p_list(p_suit);
    class_out_LOO = zeros(size(p_list_suit'));
    dvec_LOO = zeros(size(pdata,1),length(p_list_suit));
    b_LOO = zeros(size(p_list_suit));
    for p_idx = 1:length(p_list(p_suit))
        p = p_list_suit(p_idx);
        [dr,dirvec,beta] = maldiDA(pdata(:,p_suit & p_list ~= p), ...
                                   p_lnm(p_suit & p_list ~= p)+1, ...
                                   'NaiveBayes',pdata(:,p_list==p));
        class_out_LOO(p_idx) = (dr==2);
        dvec_LOO(:,p_idx) = dirvec;
        b_LOO(p_idx) = beta;
    end

    [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
    save(matType,[mFileNam matExt],'-regexp',regexpVars)

%     fprintf(fid,[num2str(sum(class_out(p_suit) ~= p_lnm(p_suit)')) ',' ...
%           num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%           num2str(sum(p_suit)) ',' ...
%           curDataParams.folNam ',' ...
%           curDataParams.classificationMethod ',' ...
%           curDataParams.dataType ',' ...
%           num2str(curDataParams.normalisation) ',' ...
%           num2str(curDataParams.includeEmptyVals) ',' ...
%           num2str(curDataParams.smoothParam) ',' ...
%           num2str(curDataParams.use_cancer_annot) ',' ...
%           num2str(curDataParams.nCal_tol) ',' ...
%           num2str(curDataParams.nSpec_r_tol) ',' ...
%           num2str(curDataParams.nSpec_bin_tol) ',' ...
%           num2str(curDataParams.nComponents) ',' ...
%           num2str(curDataParams.wiggle_num) '\n']);
    
    disp([num2str(sum(class_out(p_suit) ~= p_lnm(p_suit)')) ',' ...
          num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
          num2str(sum(p_suit)) ',' ...
          curDataParams.folNam ',' ...
          curDataParams.classificationMethod ',' ...
          curDataParams.dataType ',' ...
          num2str(curDataParams.normalisation) ',' ...
          num2str(curDataParams.includeEmptyVals) ',' ...
          num2str(curDataParams.smoothParam) ',' ...
          num2str(curDataParams.use_cancer_annot) ',' ...
          num2str(curDataParams.nCal_tol) ',' ...
          num2str(curDataParams.nSpec_r_tol) ',' ...
          num2str(curDataParams.nSpec_bin_tol) ',' ...
          num2str(curDataParams.nComponents) ',' ...
          num2str(curDataParams.wiggle_num)])
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    curDataParams.restrict_p_suit = true;
    [mFileNam,~] = matFileNamSelect('pPCA',curDataParams);
    load([mFileNam matExt],'mpc','meigvec','veigval')

    X = pdata(:,p_suit);
    Y = double(p_lnm(p_suit))';
    Z = meigvec*diag(veigval.^(-1/2))*meigvec';
    % Note that p1 = C in this case (because Y is one-dimensional)
    p1 = Z*(1/42)*(X-repmat(mean(X,2),1,size(X,2)))*(Y-mean(Y))'*(var(Y)^(-1/2));
    phi1 = Z*p1;
    
    for rank_type = 1:2
    switch rank_type
        case 1
            [~,I] = sort(abs(p1),'descend');
        case 2
            [~,I] = sort(abs(phi1),'descend');
    end    
    
    
    for n_cca_var = 1:45
        curDataParams.nComponents = n_cca_var;
        pdata_temp = X(I(1:n_cca_var),:);

        %% CCA-DWD
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        curDataParams.classificationMethod = ['cca' num2str(rank_type) 'DWD'];
        [dvec,b,class_out] = DWD2XQ(pdata_temp(:,p_lnm(p_suit)), ...
                                    pdata_temp(:,~p_lnm(p_suit)), ...
                                    2,pdata_temp,100);
        class_out = (class_out==1);

        % LOO
        p_list_suit = p_list(p_suit);
        class_out_LOO = zeros(size(p_list_suit'));
        dvec_LOO = zeros(size(pdata_temp,1),length(p_list_suit));
        b_LOO = zeros(size(p_list_suit));
        for p_idx = 1:length(p_list(p_suit))
            p = p_list_suit(p_idx);
            [dirvec,beta,dr] = DWD2XQ(pdata_temp(:, p_lnm(p_suit) & p_list_suit ~= p), ...
                                      pdata_temp(:,~p_lnm(p_suit) & p_list_suit ~= p), ...
                                      2,pdata_temp(:,p_list_suit == p),100);
            class_out_LOO(p_idx) = (dr==1);
            dvec_LOO(:,p_idx) = dirvec;
            b_LOO(p_idx) = beta;
        end

        [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
        save(matType,[mFileNam matExt],'-regexp',regexpVars)

%         fprintf(fid,[num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(p_suit)) ',' ...
%               curDataParams.folNam ',' ...
%               curDataParams.classificationMethod ',' ...
%               curDataParams.dataType ',' ...
%               num2str(curDataParams.normalisation) ',' ...
%               num2str(curDataParams.includeEmptyVals) ',' ...
%               num2str(curDataParams.smoothParam) ',' ...
%               num2str(curDataParams.use_cancer_annot) ',' ...
%               num2str(curDataParams.nCal_tol) ',' ...
%               num2str(curDataParams.nSpec_r_tol) ',' ...
%               num2str(curDataParams.nSpec_bin_tol) ',' ...
%               num2str(curDataParams.nComponents) ',' ...
%               num2str(curDataParams.wiggle_num) '\n']);

        disp([num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(p_suit)) ',' ...
              curDataParams.folNam ',' ...
              curDataParams.classificationMethod ',' ...
              curDataParams.dataType ',' ...
              num2str(curDataParams.normalisation) ',' ...
              num2str(curDataParams.includeEmptyVals) ',' ...
              num2str(curDataParams.smoothParam) ',' ...
              num2str(curDataParams.use_cancer_annot) ',' ...
              num2str(curDataParams.nCal_tol) ',' ...
              num2str(curDataParams.nSpec_r_tol) ',' ...
              num2str(curDataParams.nSpec_bin_tol) ',' ...
              num2str(curDataParams.nComponents) ',' ...
              num2str(curDataParams.wiggle_num)])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% CCA-NB
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        curDataParams.classificationMethod = ['cca' num2str(rank_type) 'NB'];
        [class_out,dvec,b] = maldiDA(pdata_temp,p_lnm(p_suit)+1,'NaiveBayes',pdata_temp);
        class_out = (class_out == 2);

        % LOO
        p_list_suit = p_list(p_suit);
        class_out_LOO = zeros(size(p_list_suit'));
        dvec_LOO = zeros(size(pdata_temp,1),length(p_list_suit));
        b_LOO = zeros(size(p_list_suit));
        for p_idx = 1:length(p_list(p_suit))
            p = p_list_suit(p_idx);
            [dr,dirvec,beta] = maldiDA(pdata_temp(:,p_list_suit ~= p), ...
                                       p_lnm(p_suit & p_list ~= p)+1, ...
                                       'NaiveBayes',pdata_temp(:,p_list_suit==p));
            class_out_LOO(p_idx) = (dr==2);
            dvec_LOO(:,p_idx) = dirvec;
            b_LOO(p_idx) = beta;
        end

        [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
        save(matType,[mFileNam matExt],'-regexp',regexpVars)

%         fprintf(fid,[num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(p_suit)) ',' ...
%               curDataParams.folNam ',' ...
%               curDataParams.classificationMethod ',' ...
%               curDataParams.dataType ',' ...
%               num2str(curDataParams.normalisation) ',' ...
%               num2str(curDataParams.includeEmptyVals) ',' ...
%               num2str(curDataParams.smoothParam) ',' ...
%               num2str(curDataParams.use_cancer_annot) ',' ...
%               num2str(curDataParams.nCal_tol) ',' ...
%               num2str(curDataParams.nSpec_r_tol) ',' ...
%               num2str(curDataParams.nSpec_bin_tol) ',' ...
%               num2str(curDataParams.nComponents) ',' ...
%               num2str(curDataParams.wiggle_num) '\n']);

        disp([num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(p_suit)) ',' ...
              curDataParams.folNam ',' ...
              curDataParams.classificationMethod ',' ...
              curDataParams.dataType ',' ...
              num2str(curDataParams.normalisation) ',' ...
              num2str(curDataParams.includeEmptyVals) ',' ...
              num2str(curDataParams.smoothParam) ',' ...
              num2str(curDataParams.use_cancer_annot) ',' ...
              num2str(curDataParams.nCal_tol) ',' ...
              num2str(curDataParams.nSpec_r_tol) ',' ...
              num2str(curDataParams.nSpec_bin_tol) ',' ...
              num2str(curDataParams.nComponents) ',' ...
              num2str(curDataParams.wiggle_num)])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% CCA-LDA
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        curDataParams.classificationMethod = ['cca' num2str(rank_type) 'LDA'];
        [class_out,dvec,b] = maldiDA(pdata_temp,p_lnm(p_suit)+1,'LDA',pdata_temp);
        if sum(isnan(class_out)) == 0
            class_out = (class_out == 2);
        end

        % LOO
        p_list_suit = p_list(p_suit);
        class_out_LOO = nan(size(p_list_suit'));
        dvec_LOO = zeros(size(pdata_temp,1),length(p_list_suit));
        b_LOO = zeros(size(p_list_suit));
        for p_idx = 1:length(p_list(p_suit))
            p = p_list_suit(p_idx);
            [dr,dirvec,beta] = maldiDA(pdata_temp(:,p_list_suit ~= p), ...
                                       p_lnm(p_suit & p_list ~= p)+1, ...
                                       'LDA',pdata_temp(:,p_list_suit==p));
            if ~isnan(dr)
                class_out_LOO(p_idx) = (dr==2);
            end
            dvec_LOO(:,p_idx) = dirvec;
            b_LOO(p_idx) = beta;
        end

        [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
        save(matType,[mFileNam matExt],'-regexp',regexpVars)

%         fprintf(fid,[num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(p_suit)) ',' ...
%               curDataParams.folNam ',' ...
%               curDataParams.classificationMethod ',' ...
%               curDataParams.dataType ',' ...
%               num2str(curDataParams.normalisation) ',' ...
%               num2str(curDataParams.includeEmptyVals) ',' ...
%               num2str(curDataParams.smoothParam) ',' ...
%               num2str(curDataParams.use_cancer_annot) ',' ...
%               num2str(curDataParams.nCal_tol) ',' ...
%               num2str(curDataParams.nSpec_r_tol) ',' ...
%               num2str(curDataParams.nSpec_bin_tol) ',' ...
%               num2str(curDataParams.nComponents) ',' ...
%               num2str(curDataParams.wiggle_num) '\n']);

        disp([num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(p_suit)) ',' ...
              curDataParams.folNam ',' ...
              curDataParams.classificationMethod ',' ...
              curDataParams.dataType ',' ...
              num2str(curDataParams.normalisation) ',' ...
              num2str(curDataParams.includeEmptyVals) ',' ...
              num2str(curDataParams.smoothParam) ',' ...
              num2str(curDataParams.use_cancer_annot) ',' ...
              num2str(curDataParams.nCal_tol) ',' ...
              num2str(curDataParams.nSpec_r_tol) ',' ...
              num2str(curDataParams.nSpec_bin_tol) ',' ...
              num2str(curDataParams.nComponents) ',' ...
              num2str(curDataParams.wiggle_num)])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    end

    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    for n_pcs = 1:size(mpc,1)
        curDataParams.nComponents = n_pcs;
        pdata_temp = mpc(1:n_pcs,:);

        %% PCA-DWD
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        curDataParams.classificationMethod = 'pcaDWD';
        [dvec,b,class_out] = DWD2XQ(pdata_temp(:,p_lnm(p_suit)), ...
                                  pdata_temp(:,~p_lnm(p_suit)), ...
                                    2,pdata_temp,100);
        class_out = (class_out==1);

        % LOO
        p_list_suit = p_list(p_suit);
        class_out_LOO = zeros(size(p_list_suit'));
        dvec_LOO = zeros(size(pdata_temp,1),length(p_list_suit));
        b_LOO = zeros(size(p_list_suit));
        for p_idx = 1:length(p_list(p_suit))
            p = p_list_suit(p_idx);
            [dirvec,beta,dr] = DWD2XQ(pdata_temp(:, p_lnm(p_suit) & p_list_suit ~= p), ...
                                      pdata_temp(:,~p_lnm(p_suit) & p_list_suit ~= p), ...
                                      2,pdata_temp(:,p_list_suit == p),100);
            class_out_LOO(p_idx) = (dr==1);
            dvec_LOO(:,p_idx) = dirvec;
            b_LOO(p_idx) = beta;
        end

        [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
        save(matType,[mFileNam matExt],'-regexp',regexpVars)

%         fprintf(fid,[num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(p_suit)) ',' ...
%               curDataParams.folNam ',' ...
%               curDataParams.classificationMethod ',' ...
%               curDataParams.dataType ',' ...
%               num2str(curDataParams.normalisation) ',' ...
%               num2str(curDataParams.includeEmptyVals) ',' ...
%               num2str(curDataParams.smoothParam) ',' ...
%               num2str(curDataParams.use_cancer_annot) ',' ...
%               num2str(curDataParams.nCal_tol) ',' ...
%               num2str(curDataParams.nSpec_r_tol) ',' ...
%               num2str(curDataParams.nSpec_bin_tol) ',' ...
%               num2str(curDataParams.nComponents) ',' ...
%               num2str(curDataParams.wiggle_num) '\n']);

        disp([num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(p_suit)) ',' ...
              curDataParams.folNam ',' ...
              curDataParams.classificationMethod ',' ...
              curDataParams.dataType ',' ...
              num2str(curDataParams.normalisation) ',' ...
              num2str(curDataParams.includeEmptyVals) ',' ...
              num2str(curDataParams.smoothParam) ',' ...
              num2str(curDataParams.use_cancer_annot) ',' ...
              num2str(curDataParams.nCal_tol) ',' ...
              num2str(curDataParams.nSpec_r_tol) ',' ...
              num2str(curDataParams.nSpec_bin_tol) ',' ...
              num2str(curDataParams.nComponents) ',' ...
              num2str(curDataParams.wiggle_num)])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% PCA-NB
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        curDataParams.classificationMethod = 'pcaNB';
        [class_out,dvec,b] = maldiDA(pdata_temp,p_lnm(p_suit)+1,'NaiveBayes',pdata_temp);
        class_out = (class_out == 2);

        % LOO
        p_list_suit = p_list(p_suit);
        class_out_LOO = zeros(size(p_list_suit'));
        dvec_LOO = zeros(size(pdata_temp,1),length(p_list_suit));
        b_LOO = zeros(size(p_list_suit));
        for p_idx = 1:length(p_list(p_suit))
            p = p_list_suit(p_idx);
            [dr,dirvec,beta] = maldiDA(pdata_temp(:,p_list_suit ~= p), ...
                                       p_lnm(p_suit & p_list ~= p)+1, ...
                                       'NaiveBayes',pdata_temp(:,p_list_suit==p));
            class_out_LOO(p_idx) = (dr==2);
            dvec_LOO(:,p_idx) = dirvec;
            b_LOO(p_idx) = beta;
        end

        [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
        save(matType,[mFileNam matExt],'-regexp',regexpVars)

%         fprintf(fid,[num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(p_suit)) ',' ...
%               curDataParams.folNam ',' ...
%               curDataParams.classificationMethod ',' ...
%               curDataParams.dataType ',' ...
%               num2str(curDataParams.normalisation) ',' ...
%               num2str(curDataParams.includeEmptyVals) ',' ...
%               num2str(curDataParams.smoothParam) ',' ...
%               num2str(curDataParams.use_cancer_annot) ',' ...
%               num2str(curDataParams.nCal_tol) ',' ...
%               num2str(curDataParams.nSpec_r_tol) ',' ...
%               num2str(curDataParams.nSpec_bin_tol) ',' ...
%               num2str(curDataParams.nComponents) ',' ...
%               num2str(curDataParams.wiggle_num) '\n']);

        disp([num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(p_suit)) ',' ...
              curDataParams.folNam ',' ...
              curDataParams.classificationMethod ',' ...
              curDataParams.dataType ',' ...
              num2str(curDataParams.normalisation) ',' ...
              num2str(curDataParams.includeEmptyVals) ',' ...
              num2str(curDataParams.smoothParam) ',' ...
              num2str(curDataParams.use_cancer_annot) ',' ...
              num2str(curDataParams.nCal_tol) ',' ...
              num2str(curDataParams.nSpec_r_tol) ',' ...
              num2str(curDataParams.nSpec_bin_tol) ',' ...
              num2str(curDataParams.nComponents) ',' ...
              num2str(curDataParams.wiggle_num)])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% PCA-LDA
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        curDataParams.classificationMethod = 'pcaLDA';
        [class_out,dvec,b] = maldiDA(pdata_temp,p_lnm(p_suit)+1,'LDA',pdata_temp);
        if sum(isnan(class_out)) == 0
            class_out = (class_out == 2);
        end

        % LOO
        p_list_suit = p_list(p_suit);
        class_out_LOO = nan(size(p_list_suit'));
        dvec_LOO = zeros(size(pdata_temp,1),length(p_list_suit));
        b_LOO = zeros(size(p_list_suit));
        for p_idx = 1:length(p_list(p_suit))
            p = p_list_suit(p_idx);
            [dr,dirvec,beta] = maldiDA(pdata_temp(:,p_list_suit ~= p), ...
                                       p_lnm(p_suit & p_list ~= p)+1, ...
                                       'LDA',pdata_temp(:,p_list_suit==p));
            if ~isnan(dr)
                class_out_LOO(p_idx) = (dr==2);
            end
            dvec_LOO(:,p_idx) = dirvec;
            b_LOO(p_idx) = beta;
        end

        [mFileNam,regexpVars] = matFileNamSelect('pClassification',curDataParams);
        save(matType,[mFileNam matExt],'-regexp',regexpVars)

%         fprintf(fid,[num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
%               num2str(sum(p_suit)) ',' ...
%               curDataParams.folNam ',' ...
%               curDataParams.classificationMethod ',' ...
%               curDataParams.dataType ',' ...
%               num2str(curDataParams.normalisation) ',' ...
%               num2str(curDataParams.includeEmptyVals) ',' ...
%               num2str(curDataParams.smoothParam) ',' ...
%               num2str(curDataParams.use_cancer_annot) ',' ...
%               num2str(curDataParams.nCal_tol) ',' ...
%               num2str(curDataParams.nSpec_r_tol) ',' ...
%               num2str(curDataParams.nSpec_bin_tol) ',' ...
%               num2str(curDataParams.nComponents) ',' ...
%               num2str(curDataParams.wiggle_num) '\n']);

        disp([num2str(sum(class_out ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(class_out_LOO ~= p_lnm(p_suit)')) ',' ...
              num2str(sum(p_suit)) ',' ...
              curDataParams.folNam ',' ...
              curDataParams.classificationMethod ',' ...
              curDataParams.dataType ',' ...
              num2str(curDataParams.normalisation) ',' ...
              num2str(curDataParams.includeEmptyVals) ',' ...
              num2str(curDataParams.smoothParam) ',' ...
              num2str(curDataParams.use_cancer_annot) ',' ...
              num2str(curDataParams.nCal_tol) ',' ...
              num2str(curDataParams.nSpec_r_tol) ',' ...
              num2str(curDataParams.nSpec_bin_tol) ',' ...
              num2str(curDataParams.nComponents) ',' ...
              num2str(curDataParams.wiggle_num)])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    end



    
    
    
    
end     
end
end
end
end
end
end
end
end
end

% fclose(fid);













































