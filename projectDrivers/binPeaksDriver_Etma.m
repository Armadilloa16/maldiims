clc
clear all
close all

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
                    
% Preproccessing parameters
curDataParams = struct();
curDataParams.binSize = 0.25;

disp('---------------------')
disp('       Binning       ')
disp('---------------------')

vFolNams = {'Etma1B1_2kHz','Etma1B2_2kHz',...
            'Etma2B1_2kHz','Etma2B2_2kHz'};
for folnam_idx = 1:length(vFolNams)
curDataParams.folNam = vFolNams{folnam_idx};
disp(' ')
disp(curDataParams.folNam)

mFileNam = matFileNamSelect('Raw',curDataParams);
load([mFileNam matExt],'L','LXY')
sortedPeaks = sortPeaks(L,LXY);
clear L LXY

curDataParams.wiggle = false;

[mcdata,vbincentrs,mdataL] = bin1dFast(sortedPeaks,curDataParams.binSize);
[mFileNam,regexpVars] = matFileNamSelect('Binned',curDataParams);
save(matType,[mFileNam matExt],'-regexp',regexpVars)

curDataParams.wiggle = true;
w_d = 3;
for w_n = 1:(w_d-1)
        
disp(['  wiggle ' num2str(w_n) ' / ' num2str(w_d)])
curDataParams.wiggle_den = w_d;
curDataParams.wiggle_num = w_n;

if curDataParams.wiggle
    if isfield(curDataParams,'wiggle_den')
        if curDataParams.wiggle_den == 2
            [mcdata,vbincentrs,mdataL] = bin1dFast(sortedPeaks,curDataParams.binSize,(curDataParams.binSize/2));
        elseif isfield(curDataParams,'wiggle_num')
            if curDataParams.wiggle_num <= (curDataParams.wiggle_den/2)
                [mcdata,vbincentrs,mdataL] = bin1dFast(sortedPeaks,curDataParams.binSize,curDataParams.wiggle_num*(curDataParams.binSize/curDataParams.wiggle_den));
            else                
                [mcdata,vbincentrs,mdataL] = bin1dFast(sortedPeaks,curDataParams.binSize,(curDataParams.wiggle_num*(curDataParams.binSize/curDataParams.wiggle_den))-curDataParams.binSize);
            end
        end
    else
        [mcdata,vbincentrs,mdataL] = bin1dFast(sortedPeaks,curDataParams.binSize,(curDataParams.binSize/2));
    end
else
    [mcdata,vbincentrs,mdataL] = bin1dFast(sortedPeaks,curDataParams.binSize);
end

[mFileNam,regexpVars] = matFileNamSelect('Binned',curDataParams);
save(matType,[mFileNam matExt],'-regexp',regexpVars)

end

end


