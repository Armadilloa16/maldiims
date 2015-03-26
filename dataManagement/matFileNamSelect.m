function [mFileNam,regexpVars] = matFileNamSelect(dataType,paramStruct)
    
%     EXAMPLE USE:
% 
%     [mFileNam,regexpVars] = matFileNamSelect('Clus',curDataParams);
%     save(matType,[mFileNam matExt],'-regexp',regexpVars)
% 

    matFileFolder = './dataMATfiles/';
    regexpVars = '';
    
    switch dataType
        case 'Dataset Index'
            mFileNam = [matFileFolder 'datasetNames'];
            regexpVars = 'dataNams|dataTypeNams|dataExists';
            
        case 'Supplementary Data'
            mFileNam = [matFileFolder 'supplementaryData'];
            regexpVars = 'metaData';
            
            
        otherwise
            dataTypeNam = dataTypeNamSelect(dataType,paramStruct);
            mFileNam = [matFileFolder paramStruct.folNam dataTypeNam];
            
            switch dataType
                case 'Raw'
                    regexpVars = 'L|X|Y|R|emptySpec|fExists|LXY|XYL|Vars';

                case 'Classes'
                    regexpVars = 'p_number|classes|classNams';

                case 'Annotation'
                    regexpVars = 'annot_gurjeet|annot_martin|annotNams';

                case 'Binned'
                    if ~isfield(paramStruct,'smoothParam')
                        if ~isfield(paramStruct,'dataType')
                            regexpVars = 'mcdata|vbincentrs|mdataL';
                        elseif strcmp(paramStruct.dataType,'Binary')
                            regexpVars = 'mcdata|vbincentrs|mdataL';
                        else
                            regexpVars = 'mdata';
                        end
                    elseif paramStruct.smoothParam == 0
                        if ~isfield(paramStruct,'dataType')
                            regexpVars = 'mcdata|vbincentrs|mdataL';
                        elseif strcmp(paramStruct.dataType,'Binary')
                            regexpVars = 'mcdata|vbincentrs|mdataL';
                        else
                            regexpVars = 'mdata';
                        end
                    else
                        regexpVars = 'mbdata|vbincentrs|fExists|emptySpec|nIter|converged';                
                    end
                    
                case 'Normalisation'
                    regexpVars = 'Shat|nCal|meanCalIntensity|CV';

                case 'PCA'
                    regexpVars = 'veigval|meigvec|vmean|mpc';
                    
                case 'Clus'
                    if ~isfield(paramStruct,'dataType')
                        regexpVars = 'clus|centroicell|DIPScell|cutOFFcell|plotCutOFFcell|plotDistcell|Kmax';
                    elseif strcmp(paramStruct.dataType,'Binary')
                        regexpVars = 'clus|centroicell|DIPScell|cutOFFcell|plotCutOFFcell|plotDistcell|Kmax';
                    else
                        regexpVars = 'clus|centroicell|Kmax';
                    end
                    
                case 'rSummary'
                    regexpVars = 'nSpec|rdata|r_list|r_list_count|r_number';
                    
            end
           
    end
    
    regexpVars = ['^' strjoin(regexp(regexpVars,'\|','split'),'$|^') '$'];
    
    
end