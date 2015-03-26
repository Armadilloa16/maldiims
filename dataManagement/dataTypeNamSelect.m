function dataTypeNam = dataTypeNamSelect(dataType,paramStruct)

    switch dataType
        case 'Raw'
            dataTypeNam = '_rawData';
            
        case 'Classes'
            dataTypeNam = '_classes';
                        
        case 'Annotation'
            dataTypeNam = '_annotations';

        case 'Normalisation'
            dataTypeNam = '_normalisation';
            
        case {'Binned','PCA','Clus','Intensity','Area','SN','rSummary'}
            dataTypeNam = ['_Bin' num2str(100*paramStruct.binSize)];
            if isfield(paramStruct,'wiggle')
                if paramStruct.wiggle
                    if isfield(paramStruct,'wiggle_den')
                        if paramStruct.wiggle_den == 2
                            dataTypeNam = [dataTypeNam '_wiggle'];                            
                        elseif isfield(paramStruct,'wiggle_num')
                            if paramStruct.wiggle_num ~= 0
                                dataTypeNam = [dataTypeNam '_' num2str(paramStruct.wiggle_num) 'wiggle' num2str(paramStruct.wiggle_den)];
                            end
                        end
                    else
                        if ~isfield(paramStruct,'wiggle_num')
                            dataTypeNam = [dataTypeNam '_wiggle'];
                        else
                            error('wiggle_den exists but wiggle_num does not!')
                        end
                    end
                end
            end
            if isfield(paramStruct,'smoothParam')
                if paramStruct.smoothParam ~= 0
                    dataTypeNam = [dataTypeNam '_' num2str(100*paramStruct.smoothParam) 'smooth'];
                end
            end
            if isfield(paramStruct,'dataType')
                switch paramStruct.dataType
                    case 'Intensity'
                        dataTypeNam = [dataTypeNam '_intensity'];
                    case 'Area'
                        dataTypeNam = [dataTypeNam '_area'];
                    case 'SN'
                        dataTypeNam = [dataTypeNam '_sn'];
                end
            end         
            switch dataType                    
                case 'PCA'
                    dataTypeNam = [dataTypeNam '_pca'];
                case 'Clus'
                    dataTypeNam = [dataTypeNam '_' paramStruct.clusType 'Clus'];
                case 'rSummary'
                    if paramStruct.normalisation
                        dataTypeNam = [dataTypeNam '_normalised'];
                    end
                    dataTypeNam = [dataTypeNam '_minNcal' num2str(paramStruct.norm_minNcal)];
                    dataTypeNam = [dataTypeNam '_rSummary'];
            end
            
        otherwise
            error('mFileNam Selection went awry!')
    
    end

end