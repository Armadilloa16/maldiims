clc
clear all
close all

%%
% Add my code folders.
addpath('./functionMfiles/dataManagement',...
    './functionMfiles/analysisFunctions',...
    './functionMfiles/plottingFunctions')
% Some of Steve Marrons code, most particularly pcaSM for PCA.
addpath('./functionMfiles/codeSM/General',...
    './functionMfiles/codeSM/BatchAdjust',...
    './functionMfiles/codeSM/Smoothing')
% Some other peoples code I have used.
addpath('./functionMfiles/otherPeoplesCode')        
% addpath('./SDPT3-4.0/Solver')        

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

vDatTypes = {'Binary','LogIntensity',,'Intensity','SN','Area'};
vClasMethods = {'DWD' 'NB' 'pcaDWD' 'pcaNB' 'pcaLDA' 'cca1DWD' 'cca1NB' 'cca1LDA' 'cca2DWD' 'cca2NB' 'cca2LDA'};

vUseAnnot = [false true];

vNcal = [0 3 4];
v_minNspec_r = [1 100];
v_minNspec_bin = [1 100];

fid = fopen('.\output\Etma_majority_classification.txt','wt');

% Print Header
disp('Me, Mloo, N, Dataset, Method, DataType, Normalisation, includeEmptyValues, Smooth, CancerAnnotation, minNcal, minNspecPerCore, minNspecPerBin, nComponents')
fprintf(fid,'Me,Mloo,N,Dataset,Method,DataType,Normalisation,includeEmptyValues,Smooth,CancerAnnotation,minNcal,minNspecPerCore,minNspecPerBin,nComponents\n');

%% Dataset
for folnam_idx = 1:length(vFolNams)
curDataParams.folNam = vFolNams{folnam_idx};

%% Data Type
for datType_idx = 1:length(vDatTypes) 
curDataParams.dataType = vDatTypes{datType_idx};

%% Annotated Cancer Spectra
for use_cancer_annot = [false true]
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

%% Classification Method
for clas_method_idx = 1:length(vClasMethods)
    curDataParams.classificationMethod = vClasMethods{clas_method_idx};

switch curDataParams.classificationMethod
    case {'pcaDWD' 'pcaNB' 'pcaLDA'}
        curDataParams.restrict_p_suit = true;
        [mFileNam,~] = matFileNamSelect('pPCA',curDataParams);
        load([mFileNam matExt],'veigval')
        vNcomponents = 1:length(veigval);
        clear veigval
        
    case {'cca1DWD' 'cca1NB' 'cca1LDA' 'cca2DWD' 'cca2NB' 'cca2LDA'}
        vNcomponents = 1:45;
        
    otherwise
        vNcomponents = 1;
end

%% Dimension reduction
for cur_nComponents = vNcomponents
    curDataParams.nComponents = cur_nComponents;

    MeISna = false;
    MlooISna = false;
    %% Majority Rule
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for w_n = 0:2
        curDataParams.wiggle_num = w_n;

        [mFileNam,~] = matFileNamSelect('pClassification',curDataParams);
        load([mFileNam matExt],'class_out','class_out_LOO')

        % Check for NA's
        if sum(isnan(class_out)) + sum(isnan(class_out_LOO)) > 0
            if sum(isnan(class_out)) > 0
                MeISna = true;
            end
            if sum(isnan(class_out_LOO)) > 0
                MlooISna = true;
            end
            break
        end

        if w_n == 0
            class_mr = class_out;
            class_mr_LOO = class_out_LOO;
        else
            class_mr = class_mr + class_out;
            class_mr_LOO = class_mr_LOO + class_out_LOO;
        end
    end
    
    class_mr = round(class_mr/curDataParams.wiggle_den);
    class_mr_LOO = round(class_mr_LOO/curDataParams.wiggle_den);
    
    curDataParams.dataType = 'Binary';
    curDataParams.normalisation = false;
    [mFileNam,~] = matFileNamSelect('pSummary',curDataParams);
    load([mFileNam matExt],'p_lnm','p_suit')    
    curDataParams.dataType = vDatTypes{datType_idx};
    curDataParams.normalisation = n;

    if MeISna
        Me_str = 'NA';
    else
        switch curDataParams.classificationMethod
            case {'NB' 'DWD'}
                Me_str = num2str(sum(class_mr(p_suit) ~= p_lnm(p_suit)'));
            otherwise
                Me_str = num2str(sum(class_mr ~= p_lnm(p_suit)'));                
        end
    end
    if MlooISna
        Mloo_str = 'NA';
    else
        Mloo_str = num2str(sum(class_mr_LOO ~= p_lnm(p_suit)'));
    end        

    fprintf(fid,[Me_str ',' ...
          Mloo_str ',' ...
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
          num2str(curDataParams.nComponents) '\n']);
    
    disp([Me_str ',' ...
          Mloo_str ',' ...
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
          num2str(curDataParams.nComponents)]);
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

fclose(fid);













































