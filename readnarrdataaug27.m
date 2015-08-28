%Reads in NARR data from netCDF files downloaded by FTP
%Each matrix is comprised of daily data for a month -- have 1979-2014
%Temperatures here are the ***DAILY AVERAGE***, not the max or min as in the obs
%For these netCDF files:
%Dim 1 is lat; Dim 2 is lon; Dim 3 is pressure (1000, 850, 500, 300, 200); Dim 4 is day of month

%Current runtime: about 3 min per variable for all 36 years

%Variables to set
%I. For Science
yeariwf=2005;yeariwl=2014; %years to compute over
monthiwf=6;monthiwl=8; %months to compute over
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;

prefixes={'atlcity';'bridgeport';'islip';'jfk';'lga';'mcguireafb';...
'newark';'teterboro';'whiteplains'};
a=size(prefixes);numstns=a(1);
varlist={'air';'shum';'uwnd';'vwnd'};
varsdes=[1]; %indices refer to varlist
varlistnames={'2-m Temperature';'Mixing Ratio';'Zonal Wind';'Meridional Wind'};
deslat=41.068;deslon=-73.709;
arrsz=[277;349]; %size of lat & lon arrays

%II. For Managing Workflow & Files
needtoconvert=0;
readplotnarrdata=0; %whether to create the main variable matrices and plot the basic resulting seasonal climo
derivesecondarystats=0; %whether matrices for variables need to be saved for calculation of secondary stats
    %only one such matrix can be saved per season
donarrheatwaveanalysis=1; %whether to plot & analyze NARR data on heatwave days (as defined in readnycdata)
    showwbgtplots=0; %whether to show maps of WBGT during heatwaves
    showindiveventplots=1; %whether to show maps of temp, shum, &c for each event w/in the 15 hottest reg days covered by NARR

curDir='/Users/colin/Desktop/General_Academics/Research/Exploratory_Plots';
missingymdailyair=[08 2005;09 2005;06 2006;12 2007;01 2008;02 2008;03 2008;04 2008;...
    05 2008;06 2008;07 2008;08 2008;09 2008;10 2008;11 2008;12 2008];
missingymdailyshum=[];
%Some examples of input arguments
%vararginnew={'contour';0;'plotCountries';1;'colormap';'jet';'caxismin';0.1;'caxismax';0.5};
%vararginnew={'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet'};



%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?
%Start of script
numy=yeariwl-yeariwf+1;numm=numy*(monthiwl-monthiwf+1);
exist figc;if ans==0;figc=1;end 
oldmatrix1=0;oldmatrix2=0;
numvars=length(varlist);

if needtoconvert==1
    %Converts raw .nc files to .mat ones using handy function from Ethan
    rawNcDir='/Users/colin/Desktop/General_Academics/Research/Exploratory_Plots/Raw_nc_files';
    outputDir='/Users/colin/Desktop/General_Academics/Research/Exploratory_Plots';
    varName='shum';
    maxNum=100; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum); %function only does computation if files don't already exist
end


%Example of quick data exploration (old way)
%Think I need to flip upside-down to have north at top
%figure(figc);figc=figc+1;
%matrix=Tcell{1,1,7}(:,:,1,4);  %avg daily air temp, 1st year, July, all lat/lon, 1000 mb, day 4
%imagescnan(flip(matrix,1),[270 310]);
%colormap jet;colorbar;




%Plot some basic seasonal-climo results
if readplotnarrdata==1
    %Plot mean daily temp for DJF, MAM, JJA, SON from NARR
    %This requires wrangling lots of mat-files
    for variab=1:size(varsdes,1)
        if strcmp(varlist(varsdes(variab)),'air')
            vararginnew={'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet'};
            adj=273.15;
        elseif strcmp(varlist(varsdes(variab)),'shum')
            vararginnew={'contour';1;'mystep';0.001;'plotCountries';1;'colormap';'jet'};
            adj=0;
        end
        djfvar=zeros(arrsz(1),arrsz(2));mamvar=zeros(arrsz(1),arrsz(2));
        jjavar=zeros(arrsz(1),arrsz(2));sonvar=zeros(arrsz(1),arrsz(2));
        djfdays=0;mamdays=0;jjadays=0;sondays=0;
        for year=yeariwf:yeariwl
            narrryear=year-yeariwf+1;
            for month=monthiwf:monthiwl
                ymmissing=0;
                missingymdaily=eval(['missingymdaily' char(varlist{varsdes(variab)})]);
                for row=1:size(missingymdailyair,1)
                    if month==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                end
                if ymmissing==1 %Do nothing, just skip the month
                else
                    fprintf('Current year and month are %d, %d\n',year,month);
                    if month<=9
                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                        '_0',num2str(month),'_01.mat')));
                        lastpart=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01'));
                    else 
                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                        '_',num2str(month),'_01.mat')));
                        lastpart=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_01'));
                    end
                    curArr=eval(['curFile.' lastpart])-adj;
                    sumvar=sum(curArr{3}(:,:,1,:),4); %{3} indicates variable (not lat/lon); sum is along 4th dimension (days)
                    monlen=size(curArr{3},4);
                    if month==12 || month==1 || month==2
                        djfvar=djfvar+sumvar;djfdays=djfdays+monlen;
                    elseif month==3 || month==4 || month==5
                        mamvar=mamvar+sumvar;mamdays=mamdays+monlen;
                    elseif month==6 || month==7 || month==8
                        jjavar=jjavar+sumvar;jjadays=jjadays+monlen;
                    else
                        sonvar=sonvar+sumvar;sondays=sondays+monlen;
                    end
                end
            end
        end
        
        llsource=eval(['curFile.' char(varlist{varsdes(variab)}) '_' num2str(yeariwl) '_0' num2str(monthiwl) '_01']);
        lats=llsource{1};lons=llsource{2};
        if djfdays~=0
            numdjfm=round(djfdays/30);
            matrix=djfvar/djfdays;data={lats;lons;matrix};
            plotModelData(data,'us-ne',vararginnew);figc=figc+1;
            title(sprintf('Average Daily %s for DJF, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
        if mamdays~=0
            nummamm=round(mamdays/30.667);
            matrix=mamvar/mamdays;data={lats;lons;matrix};
            plotModelData(data,'us-ne',vararginnew);figc=figc+1;
            title(sprintf('Average Daily %s for MAM, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
        if jjadays~=0
            numjjam=round(jjadays/30.667);
            matrix=jjavar/jjadays;data={lats;lons;matrix};
            plotModelData(data,'us-ne',vararginnew);figc=figc+1;
            title(sprintf('Average Daily %s for JJA, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
        if sondays~=0
            numsonm=round(sondays/30.333);
            matrix=sonvar/sondays;data={lats;lons;matrix};
            plotModelData(data,'us-ne',vararginnew);figc=figc+1;
            title(sprintf('Average Daily %s for SON, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
        
        if strcmp(varlist(varsdes(variab)),'air')
            oldmatrix1=matrix; %contains the avg over all months in whatever season was last computed
        elseif strcmp(varlist(varsdes(variab)),'shum')
            oldmatrix2=matrix; %ditto
        end
    end
end
    
%Calculate and map the mean WBGT field
%WBGT=0.567*T+0.393*e+3.94, with T in C and e in hPa (Fischer & Knutti 2012)
if derivesecondarystats==1
    if size(oldmatrix1,1)~=1 && size(oldmatrix2,1)~=1 %i.e. both 'air' and 'shum' data has been read in
        oldmatrix2=oldmatrix2*1000; %to convert from kg/kg to g/kg
        P=1000; %assumption valid at least at this exploratory stage
        e=(oldmatrix2.*P)./(622+oldmatrix2); %vapor-pressure field (hPa)
        wbgt=0.567.*oldmatrix1+0.393.*e+3.94;data={lats;lons;wbgt};
        vararginnew={'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet'};
        plotModelData(data,'us-ne',vararginnew);figc=figc+1;
        title(sprintf('Average Daily WBGT for JJA, %d-%d',yeariwf,yeariwl),...
            'FontSize',16,'FontWeight','bold');
        %Metric below can probably be improved
        wbgtminust=wbgt-oldmatrix1;data={lats;lons;wbgtminust};
        vararginnew={'contour';1;'mystep';0.2;'plotCountries';1;'colormap';'jet'};
        plotModelData(data,'us-ne',vararginnew);figc=figc+1;
        title(sprintf('Humidity Contribution to Avg Daily WBGT for JJA, %d-%d',yeariwf,yeariwl),...
            'FontSize',16,'FontWeight','bold');
    end
end

%Already have a list of 35 hottest region-wide days (as determined by avg stn-obs
%max T) from readnycdata, but only some of those are within the 1979-2014 NARR period of record
%Analyze synoptic conditions on the subset of days within that, then
%Don't want to include this loop in with the one above, and since it's not
%that computationally expensive, some partial repetition is OK
if donarrheatwaveanalysis==1
    exist dailymaxregsorted;if ans==0;disp('Need to compute hottest region-wide days');end
    numd=35;c=1;hoteventsarrs={};heahelper=0;
    for row=1:numd
        if dailymaxregsorted(row,3)>=1979
            dmrsstarts(c,1)=dailymaxregsorted(row,2);
            dmrsstarts(c,2)=dailymaxregsorted(row,3);
            c=c+1;
        end
    end
    dmrsstarts=sortrows(dmrsstarts,2); %sort chronologically

    %Look at temperatures first
    %And, first thing will just be a composite of them all
    for variab=1:size(varsdes,1)
        if strcmp(varlist(varsdes(variab)),'air')
            vararginnew={'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet'};
            adj=273.15;
        elseif strcmp(varlist(varsdes(variab)),'shum')
            vararginnew={'contour';1;'mystep';0.001;'plotCountries';1;'colormap';'jet'};
            adj=0;
        end
        djfvar=zeros(arrsz(1),arrsz(2));mamvar=zeros(arrsz(1),arrsz(2));
        jjavar=zeros(arrsz(1),arrsz(2));sonvar=zeros(arrsz(1),arrsz(2));
        total=zeros(arrsz(1),arrsz(2));hotdaysc=0;hoteventsc=0;
        djfdays=0;mamdays=0;jjadays=0;sondays=0;
        for year=yeariwf:yeariwl
            narrryear=year-yeariwf+1;
            if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
            for month=monthiwf:monthiwl
                ymmissing=0;
                missingymdaily=eval(['missingymdaily' char(varlist{varsdes(variab)})]);
                for row=1:size(missingymdailyair,1)
                    if month==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                end
                if ymmissing==1 %Do nothing, just skip the month
                else
                    fprintf('Current year and month are %d, %d\n',year,month);
                    curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                    curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);
                    %Search through listing of region-wide hottest days to see if this month contains one of them
                    for row=1:size(dmrsstarts,1)
                        if dmrsstarts(row,2)==year && dmrsstarts(row,1)>=curmonstart && dmrsstarts(row,1)<curmonstart+curmonlen
                            dayinmonth=dmrsstarts(row,1)-curmonstart+1;disp(dayinmonth);
                            if month<=9
                                curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                    num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                '_0',num2str(month),'_01.mat')));
                                lastpart=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01'));
                            else 
                                curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                    num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                '_',num2str(month),'_01.mat')));
                                lastpart=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_01'));
                            end
                            curArr=eval(['curFile.' lastpart]);
                            if hotdaysc>=1;prevDOI=arrDOI;end
                            arrDOI=curArr{3}(:,:,1,dayinmonth)-adj; %DOI is day of interest
                            total=total+arrDOI;
                            hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                            %Save arrays on hot days into a cell matrix to be able to plot & compare them
                            %The beauty of this is that this loop need not be run again as long as the arrays are saved!
                            %Have to decide if day is part of a multiday event, in which case their synoptic conds are
                            %of course highly correlated -- average the two days
                            if dmrsstarts(row,2)==dmrsstarts(row-1,2) && abs(dmrsstarts(row,1)-dmrsstarts(row-1,1))<=7
                                arrEvent=(prevDOI+arrDOI)./2;
                                hoteventsarrs{hoteventsc-1,variab}=arrEvent; %the actual data
                                heahelper(hoteventsc-1,1)=dmrsstarts(row,1); %this includes dates for map-title purposes
                                heahelper(hoteventsc-1,2)=dmrsstarts(row-1,1); %the previous day that's also part of this event
                                heahelper(hoteventsc-1,3)=dmrsstarts(row,2); %year of event
                                hoteventsc=hoteventsc-1;%disp('Multiday event found');
                            else
                                arrEvent=arrDOI;
                                hoteventsarrs{hoteventsc,variab}=arrEvent;
                                heahelper(hoteventsc,1)=dmrsstarts(row,1);
                                heahelper(hoteventsc,2)=0; %so it's clear later that it's a simple one-day event
                                heahelper(hoteventsc,3)=dmrsstarts(row,2);
                            end
                        end
                    end
                end
            end
        end
        total=(total)/hotdaysc;data={lats;lons;total};
        plotModelData(data,'na-east',vararginnew);figc=figc+1;
        title(sprintf('Avg Daily %s for the %d Hottest Days in the NYC Area, %d-%d',...
            char(varlistnames{variab}),hotdaysc,yeariwf,yeariwl),'FontSize',16,'FontWeight','bold');
        
        if strcmp(varlist(varsdes(variab)),'air')
            oldtotal1=total;
        elseif strcmp(varlist(varsdes(variab)),'shum')
            oldtotal2=total; %ditto
        end
    end
    
    if showwbgtplots==1
        if size(oldtotal1,1)~=1 && size(oldtotal2,1)~=1 %i.e. both 'air' and 'shum' data has been read in
            oldtotal2=oldtotal2*1000; %to convert from kg/kg to g/kg
            P=1000; %assumption valid at least at this exploratory stage
            e=(oldtotal2.*P)./(622+oldtotal2); %vapor-pressure field (hPa)
            wbgt=0.567.*oldtotal1+0.393.*e+3.94;data={lats;lons;wbgt};
            vararginnew={'contour';1;'mystep';0.5;'plotCountries';1;'colormap';'jet';...
                'caxismethod';'regional'};
            plotModelData(data,'nyc-area',vararginnew);figc=figc+1;
            title(sprintf('Avg Daily WBGT for the %d Hottest Days in the NYC Area, %d-%d',hotdaysc,yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            %Metric below can probably be improved
            wbgtminust=wbgt-oldtotal1;data={lats;lons;wbgtminust};
            vararginnew={'contour';1;'mystep';0.2;'plotCountries';1;'colormap';'jet'};
            plotModelData(data,'us-ne',vararginnew);figc=figc+1;
            title(sprintf('Humidity Contrib. to Daily WBGT for %d Hot Days, %d-%d',hotdaysc,yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
    end
    
    if showindiveventplots==1
        for variab=1:size(varsdes,1)
            for event=1:size(hoteventsarrs,1)
                data={lats;lons;hoteventsarrs{event}};
                vararginnew={'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet';'caxismethod';'regional'};
                plotModelData(data,'nyc-area',vararginnew);figc=figc+1;
                %INCLUDE STATION DATA
                h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker',mark,...
        'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',11);
                if heahelper(event,2)>0 %a multi-day event
                    title(sprintf('Daily %s on %s and %s, %d',...
                    char(varlistnames{variab}),DOYtoDate(heahelper(event,2),heahelper(event,3)),...
                    DOYtoDate(heahelper(event,1),heahelper(event,3)),heahelper(event,3)),'FontSize',16,'FontWeight','bold');
                else %one singleton hot day
                    title(sprintf('Daily %s on %s, %d',...
                    char(varlistnames{variab}),DOYtoDate(heahelper(event,1),heahelper(event,3)),...
                    heahelper(event,3)),'FontSize',16,'FontWeight','bold');
                end
            end
        end
    end
end


            
        
        