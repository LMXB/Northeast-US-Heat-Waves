%Converts .nc files to .mat ones for space and ease

%Example call from within Exploratory_Plots folder:
%ncepNcToMat('Raw_nc_files',pwd,'air',100);
%this creates monthly subdirectories within Exploratory_Plots

%Current runtime: about 1 min per file


function ncepNcToMat(rawNcDir, outputDir, varName, maxNum)
pLevels=[1 3 6 8]; %1000, 850, 500, 300 hPa levels
desPLevel=1; %i.e. 1000 hPa
ncFileNames=dir([rawNcDir, '/', varName, '.*.nc']);
ncFileNames={ncFileNames.name};
fileCount=0;
fprintf('Converting %s to .mat format\n',char(ncFileNames));
msl=[1 32 61 92 122 153 183 214 245 275 306 336];
ms=[1 32 60 91 121 152 182 213 244 274 305 335];

for k=1:length(ncFileNames)
    if fileCount>=maxNum && maxNum~=-1;return;end
    
    %Reset things for this new file
    ncFileName=ncFileNames{k};
    ncid=netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim,nvar,natts]=netcdf.inq(ncid);
    vardata2={};vars={};deltaT=0;dataTime='';timestep=[];
    attIdTitle=-1;atts={};varIdMain=0;
    missingValue=NaN;fillValue=NaN;
    
    %Extract the data arrays in a way that makes sense
    nameoflat=netcdf.inqVar(ncid,1);latid=netcdf.inqVarID(ncid,nameoflat);
    latdata=netcdf.getVar(ncid,latid);
    nameoflon=netcdf.inqVar(ncid,2);lonid=netcdf.inqVarID(ncid,nameoflon);
    londata=netcdf.getVar(ncid,lonid);
    nameoftime=netcdf.inqVar(ncid,3);timeid=netcdf.inqVarID(ncid,nameoftime);
    timedata=netcdf.getVar(ncid,timeid);
    nameoflevel=netcdf.inqVar(ncid,0);levelid=netcdf.inqVarID(ncid,nameoflevel);
    leveldata=netcdf.getVar(ncid,levelid);
    nameofvar=netcdf.inqVar(ncid,4);varid=netcdf.inqVarID(ncid,nameofvar);
    vardata=netcdf.getVar(ncid,varid);
    
    for kk=1:size(pLevels,2);vardata2{kk}=vardata(:,:,pLevels(kk),:);end
    for ii=1:size(londata,1);latdatamatrix(ii,:)=latdata;end
    for jj=1:size(latdata,1);londatamatrix(:,jj)=londata;end
    
    %Extract metadata from the file name
    parts=strsplit(ncFileName, '/');parts=parts(end);parts=strsplit(parts{1}, '.');
    dataTime=lower(parts{end-1});
    dataYear=dataTime(1:4);dataMonth='01';
    
    outputVarName=varName;
    if length(findstr('air.2m', ncFileName))~=0;outputVarName='air_2m';end
    
    %Check for desired output folder and create it if it doesn't exist
    folDataTarget=[outputDir,'/',outputVarName,'/',dataYear];
    if ~isdir(folDataTarget);mkdir(folDataTarget);end
    disp(folDataTarget);
    
    for i=0:natts-1
        attname=netcdf.inqAttName(ncid, netcdf.getConstant('NC_GLOBAL'), i);
        attval=netcdf.getAtt(ncid, netcdf.getConstant('NC_GLOBAL'), attname);
        
        if length(findstr(attname, 'title'))~=0;attIdTitle=i+1;end
        atts{i+1}={attname,attval};
    end

    for i=0:nvar-1
        [vname,vtype,vdim,vatts]=netcdf.inqVar(ncid,i);
        if length(findstr(vname,varName))~=0;varIdMain=i+1;end
        vars{i+1}={vname,vtype,vdim,vatts};
    end

    for i=0:vars{varIdMain}{4}-1
        %Made modifications if .nc file requests them
        attname = netcdf.inqAttName(ncid, varIdMain-1, i);
        if strcmp(attname, 'scale_factor')
            scaleFactor = double(netcdf.getAtt(ncid, varIdMain-1,'scale_factor'));
        elseif strcmp(attname, 'add_offset')
            addOffset = double(netcdf.getAtt(ncid, varIdMain-1,'add_offset'));
        elseif strcmp(attname, 'missing_value')
            missingValue = int16(netcdf.getAtt(ncid, varIdMain-1,'missing_value'));
        elseif strcmp(attname, '_FillValue')
            fillValue = int16(netcdf.getAtt(ncid, varIdMain-1,'_FillValue'));
        end
    end
    
    %Find this file's timestep
    if length(findstr('8x', atts{attIdTitle}{2}))~=0 %3-hr timestep
        deltaT=etime(datevec('03','HH'),datevec('00','HH'));
    elseif length(findstr('4x', atts{attIdTitle}{2}))~=0 %6-hr timestep
        deltaT=etime(datevec('06','HH'),datevec('00','HH'));
    else %daily timestep
        deltaT=etime(datevec('24','HH'),datevec('00','HH'));
    end
    
    data=vardata2;
    monthlyDataSet={latdata,londata,double(data{desPLevel})};
    disp('here comes a new file!');
    %Save the .mat file in the correct location and with the correct name
    %This means figuring out the months, and specifically the breaks between them
    if rem(dataYear,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
    prevendhour=0;
    for totalhour=1:size(timedata,1)-1
        curhour=timedata(totalhour);nexthour=timedata(totalhour+1);
        curcorrespday=round2(curhour/24,1,'floor')+657438; %offset figured out by a close examination
        nextcorrespday=round2(nexthour/24,1,'floor')+657438;
        curdate=datestr(curcorrespday,'yyyy_mm_dd');curmonfortitle=datestr(curcorrespday,'yyyy_mm');
        nextdate=datestr(nextcorrespday,'yyyy_mm_dd');
        monofcurhour=str2num(curdate(6:7));monstartsthisyear=eval(['ms' suffix]);
        if monofcurhour~=12
            curmonlen=monstartsthisyear(monofcurhour+1)-monstartsthisyear(monofcurhour);
        else
            curmonlen=31; %has to be Dec by process of elimination
        end
        monofnexthour=str2num(nextdate(6:7));
        if monofnexthour~=12
            nextmonlen=monstartsthisyear(monofnexthour+1)-monstartsthisyear(monofnexthour);
        else
            nextmonlen=31; %ditto
        end
        %If at the end of a month, organize all its data and save to a .mat file
        if monofnexthour~=monofcurhour %last hour of a month
            %disp('line 125');disp(totalhour);disp(monofnexthour);
            datathismon={latdatamatrix;londatamatrix;data{desPLevel}(:,:,:,prevendhour+1:totalhour)};
            disp(size(datathismon));
            prevendhour=totalhour;
            fileName=[outputVarName,'_',curmonfortitle];
            eval([fileName ' = datathismon;']);
            save([folDataTarget,'/',fileName,'.mat'],fileName,'-v7.3');
        end
    end
   
    eval(['clear ' fileName ';']);
	clear data dims vars timestep;
    netcdf.close(ncid);
    fileCount=fileCount+1;
end

