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

disp('---------------------')
disp('  Reading Peaklists  ')
disp('---------------------')

vFolNams = {'Etma1B1_2kHz','Etma1B2_2kHz',...
            'Etma2B1_2kHz','Etma2B2_2kHz'};
for folnam_idx = 1:length(vFolNams)
    curDataParams.folNam = vFolNams{folnam_idx};
    disp(' ')
    disp(curDataParams.folNam)

    [L,LXY,XYL,X,Y,fExists,Vars,emptySpec,R] = readData(curDataParams.folNam);
    [mFileNam,regexpVars] = matFileNamSelect('Raw',curDataParams);
    save(matType,[mFileNam matExt],'-regexp',regexpVars)
end

