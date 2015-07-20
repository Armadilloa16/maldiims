clc
close all
clear all

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

[isOctave,matType,matExt] = checkIsOctave();

curDataParams = struct();

curDataParams.binSize = 0.25;
curDataParams.smoothParam = 0;

disp('---------------------')
disp('   Non-Binary Data   ')
disp('---------------------')

vFolNams = {'Etma1B1_2kHz','Etma1B2_2kHz',...
            'Etma2B1_2kHz','Etma2B2_2kHz'};
for folnam_idx = 1:length(vFolNams)
curDataParams.folNam = vFolNams{folnam_idx};
disp(' ')
disp(curDataParams.folNam)
    
mFileNam = matFileNamSelect('Raw',curDataParams);
load([mFileNam matExt],'L','Vars')

w_d = 3;
for w_n = 0:(w_d-1)
if w_n == 0
    curDataParams.wiggle = false;
else
    curDataParams.wiggle = true;
end 
    
disp(['  wiggle ' num2str(w_n) ' / ' num2str(w_d)])
curDataParams.wiggle_den = w_d;
curDataParams.wiggle_num = w_n;

curDataParams.dataType = 'Binary';
mFileNam = matFileNamSelect('Binned',curDataParams);
load([mFileNam matExt],'mcdata','mdataL')

for var_idx = [2 5 6]
var_to_extract = Vars{var_idx};
switch var_to_extract
    case 'intensity'
        curDataParams.dataType = 'Intensity';
    case 'area'
        curDataParams.dataType = 'Area';
    case 'SN'
        curDataParams.dataType = 'SN';
    otherwise
        error('Problemo')
end
disp(['    ' curDataParams.dataType])

mdata = zeros(size(mdataL));
peaks = find(mdataL>0);
for peak_idx = 1:length(peaks)
    [var,spec] = ind2sub(size(mdataL),peaks(peak_idx));
    mdata(var,spec) = L{spec}(mdataL(var,spec),strcmp(Vars,var_to_extract));
    if mdata(var,spec) == 0
        disp('zero value? replaced with 10^-10')
        mdata(var,spec) = 10^(-10);
    end
end

groups = find(mcdata>1);
groupSize = mcdata(groups);
for group_idx = 1:length(groups)
    [var,spec] = ind2sub(size(mcdata),groups(group_idx));
    mdata(var,spec) = sum(L{spec}(mdataL(var,spec):(mdataL(var,spec)+groupSize(group_idx)-1),strcmp(Vars,var_to_extract)));
end

[mFileNam,regexpVars] = matFileNamSelect('Binned',curDataParams);
save(matType,[mFileNam matExt],'-regexp',regexpVars)

end
end
end





   