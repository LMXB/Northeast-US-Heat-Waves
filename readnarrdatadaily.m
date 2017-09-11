%Reads in and analyzes NARR data
%See readnarrdata3hourly for a newer version of things, although this has
%some unique loops where daily data is preferred

%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/workspace_readnarrdatadailyavgfields');

%Each matrix of NARR data is comprised of daily values for a month -- have 1979-2014
%All variables here are the ***DAILY AVERAGE***
%For these netCDF files,
%Dim 1 is lat; Dim 2 is lon; Dim 3 is pressure (1000, 850, 500, 300, 200); Dim 4 is day of month
preslevels=[1000;850;500;300;200];

%Variables to set
%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\
%0. Runtime options
needtoconvert=0;                    %from .nc to .mat; target variable is specified within loop
redefinemainvectors=0;              %whether to redefine the main vectors (or overwrite what already exists)
computeavgfields=0;                 %whether to (re)compute average variable fields (3 min/variable)
plotseasonalclimonarrdata=0;        %whether to create the main variable matrices and plot the resulting seasonal climo (3 min/variable)
organizenarrheatwaves=0;            %whether to re-read and set up for plotting NARR data on heat-wave days (1 min/variable)
                                        %as long as standard options are used (preslevel=3, compositehwdays=1), then
                                        %everything needed can come from saved workspace and there's no need to run this section at all
    preslevel=3;                    %for geopotential height, pressure level of interest (as given by preslevels)
    compositehotdays=0;             %whether to analyze hot days (defined by Tmax/WBTmax)
        numd=36;                        %x hottest days to analyze (36 is an avg of once per year when restricting to NARR data)
    compositehwdays=1;              %(mutually exclusive) whether to analyze heat waves (defined by integrated hourly T/WBT values)
        firstday=0;                     %whether to compute for first day (1), last day (0), or both (99) of regional heat waves
    redohotdaysfirstc=0;            %whether to reset the count of number of days belonging to each cluster
                                        %this means having to rerun script for both first and last days
    redohotdayslastc=1;             %change in accordance with above
    %redohotdaysbothc=0;             %ditto for combined counts
plotheatwavecomposites=1;           %whether to plot and analyze NARR heat-wave data (2 min)
    shownonoverlaycompositeplots=0; %whether to show individual composites of temp, shum, or geopotential
    showoverlaycompositeplots=1;    %(mutually exclusive) whether to show composites of wind overlaid with another variable
    varsdes=[1;2;3;4;5];                  %all the variables to be plotted
                                        %1 for T, 2 for WBT, 3 for GPH, 4 & 5 for u & v wind
    vartorankby=1;                  %1 for T, 2 for WBT
    clustdes=5;                     %cluster to plot (0, 1, 2, 4, 5, or 6, with 0 meaning full unclustered data)
    overlay=1;                      %whether to overlay something (wind and possibly something else as well)
        underlaynum=2;              %variable to underlay with shading
        overlaynum=3;               %variable to overlay with lines or contours (4 implies 5 because wind components are inseparable)
        overlaynum2=4;              %second variable to overlay (0 or 4 (implying 5)); i.e. only wind can be 2nd overlay
        anomfromjjaavg=1;           %whether to plot heat-wave composites as anomalies from JJA avg fields
        clusteranomfromavg=1;       %additionally, whether to plot each cluster as an anomaly from the all-cluster avg
                                        %only operational for overlaynum of 1 to 3, and overlaynum2~=0
plotcompositeddifferences=0;        %whether to plot difference composites, e.g. of T between first and last days (1 min 30 sec)
showindiveventplots=0;              %whether to show maps of T, WBT, &c for each event w/in the 15 hottest reg days covered by NARR,
                                        %with station observations overlaid (1 min per plot)
showdaterankchart=0;                %whether to show chart comparing hot days ranked by T and WBT
calchwsatcontigusgridpts=0;         %whether to compute heat waves at all contiguous-US gridpts, for the purposes of
                                        %comparing result with that obtained from station data in FullClimateDataScript
                                        %Times below are based on 5-deg lat/lon spacing; 2.5-deg spacing would take 4 times longer
        spacing=2;                      %for lat & lon both, in degrees
        preparegridptslist=1;           %whether to recalculate the list of gridpts computations will be done for (6 min/1 min)
            selectedgridpts=1;              %1 for selected gridpts (78), 0 for all contiguous-US gridpts (15580)
        compilegridptdata=1;            %whether to compile all available data for selected gridpts into a nice array (300 hr/12 min)
        calcclimoprctiles=1;            %whether to calculated climatological JJA percentiles of T for each gridpt (10 sec)
        defineheatwaves=1;              %whether to compile a listing of heat waves at each gridpt (30 sec)
        buildcompletehwlist=1;          %whether to build a listing of all dates on which any gridpt experienced a heat wave (15 sec)
        computehweofs=1;                %whether to wrap things up by computing heat-wave EOFs across the gridpts & timeseries (30 sec)
        eofanalyzehws=1;                %whether to make maps of EOFs in furtherance of analysis (20 sec)
        plottrendsinpcs=1;              %whether to plot loadings for the EOFs over time (15 sec)


%I. For Science
mapregionsynop='usa-exp';     %larger region to plot over; see plotModelData for full list of options
mapregionclimo='us-ne';       %region to plot over for climatology plots only
mapregionlocal='nyc-area';    %local region to plot over ('nyc-area' or 'us-ne')
yeariwf=1979;yeariwl=2014;    %years to compute over
monthiwf=6;monthiwl=8;        %months to compute over
fpd=152;                      %first possible day (usually Jun 1)
lpd=244;                      %last possible day (Aug 31 on leap years)
deslat=41.068;deslon=-73.709; %default location to calculate closest NARR gridpoints for
prefixes={'atlcity';'bridgeport';'islip';'jfk';'lga';'mcguireafb';...
'newark';'teterboro';'whiteplains'};
varlist={'air';'shum';'hgt';'uwnd';'vwnd'};
varlist2={'t';'wbt';'gh500';'uwnd';'vwnd'};varlist3={'t';'wbt';'gp';'wind'};
varlistnames={'1000-hPa Temp.';'1000-hPa Wet-Bulb Temp.';sprintf('%d-hPa Geopot. Height',preslevels(preslevel));
    '1000-hPa Wind'};
varargnames={'temperature';'wet-bulb temp';'height';'wind';'wind'};
%examples of vararginnew are in the preamble of plotModelData

%II. For Managing Files
curDir='/Volumes/MacFormatted4TBExternalDrive/NARR_daily_data_mat';
savingDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
figloc=sprintf('%s/Plots/',savingDir); %where figures will be placed
missingymdailyair=[08 2005;09 2005;06 2006;12 2007;01 2008;02 2008;03 2008;04 2008;...
    05 2008;06 2008;07 2008;08 2008;09 2008;10 2008;11 2008;12 2008];
missingymdailyshum=[];missingymdailyuwnd=[];missingymdailyvwnd=[];missingymdailyhgt=[];
lsmask=ncread('land.nc','land')';



%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?
%Start of script

if needtoconvert==1
    %Converts raw .nc files to .mat ones using handy function courtesy of Ethan
    rawNcDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Raw_nc_files';
    outputDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
    varName='hgt';
    maxNum=150; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum); %computation only done if files don't already exist
end

if redefinemainvectors==1   
    airtempmatrix=0;shummatrix=0;
    variab=1;month=6; %doesn't matter, because lats & lons are all the same; just need to get one in case full reading is not done
    curFile=load(char(strcat(curDir,'/',varlist{varsdes(variab)},'/',num2str(yeariwl),'/',varlist{varsdes(variab)},...
        '_',num2str(yeariwl),'_0',num2str(month),'_01.mat')));
    llsource=eval(['curFile.' char(varlist{varsdes(variab)}) '_' num2str(yeariwl) '_0' num2str(month) '_01']);
    lats=double(llsource{1});lons=double(llsource{2});
end

%Stuff that always needs to be done
a=size(prefixes);numstns=a(1);
exist figc;if ans==0;figc=1;end
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
prespr={'';'';sprintf('%d-mb ',preslevels(preslevel));'';''};
overlayvar=varargnames{overlaynum};underlayvar=varargnames{underlaynum};
if overlaynum2~=0;overlayvar2=varargnames{overlaynum2};end
narrsz=[277;349]; %size of lat & lon arrays from NARR
maxhwlength=10;
%Set up arrays with first-days data
exist totalfirstcl1;
if ans==0 && (firstday==1 || firstday==99)
    for clust=1:6
        eval(['totalfirstcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
        eval(['totalwbtfirstcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
        needtocalcfirstday=1;
    end
elseif ans~=0
    if firstday==1 && (max(max(totalfirstcl1))==0 || isnan(max(max(totalfirstcl1))))
        needtocalcfirstday=1;%disp('Recalculating first day');
    else
        needtocalcfirstday=0;%disp('NOT recalculating first day');
    end
end
%Set up arrays with last-days data
exist totallastcl1;
if ans==0 && (firstday==0 || firstday==99)
    for clust=1:6
        eval(['totallastcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
        eval(['totalwbtlastcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
        needtocalclastday=1;
    end
elseif ans~=0
    if firstday==0 && (max(max(totallastcl1))==0 || isnan(max(max(totallastcl1))))
        needtocalclastday=1;%disp('Recalculating last day');
    else
        needtocalclastday=0;%disp('NOT recalculating last day');
    end
end
%Labels, titles, etc. based on runtime options
rankby={'byT';'byWBT'};
labels={'Daily-Max Air Temp.';'Daily-Max Wet-Bulb Temp.'};
labelssh={'Temp.';'WBT'};
categlabel=labelssh{vartorankby};
firstlast={'lastday';'firstday';'alldays'};if firstday==99;flarg=3;else flarg=firstday+1;end
clustlb=sprintf('cl%d',clustdes);clustremark={'',', Cluster 1',', Cluster 2','',', Cluster 4',', Cluster 5',', Cluster 6'};
anomavg={'Avg';'Anom.'};anomavg2={'avg';'anom'};
clustanom={'';' Minus All-Cluster Avg'};
clanomlb=sprintf('clanom%d',clusteranomfromavg);
if compositehwdays==1
    hwremark='Heat Waves';
    if firstday==1
        dayremark='for the First Day of';
    elseif firstday==0
        dayremark='for the Last Day of';
    elseif firstday==99
        dayremark='for First & Last Days of';
    end
end
if overlay==1;contouropt=0;else contouropt=1;end
if anomfromjjaavg==1;cbsetting='regional10';else cbsetting='regional25';end


%Compute average NARR variable fields for JJA (so anomalies can be defined with respect to them)
%WBT formula is from Stull 2011, with T in C and RH in %
if computeavgfields==1
    for variab=1:5
        total=zeros(277,349);validjunc=0;validjulc=0;validaugc=0;
        if strcmp(varlist(variab),'air');adj=273.15;else adj=0;end
        for year=1979:2014
            narrryear=year-1979+1;
            for mon=6:8
                ymmissing=0;
                missingymdaily=eval(['missingymdaily' char(varlist{variab})]);
                for row=1:size(missingymdailyair,1)
                    if mon==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                end
                if ymmissing==1 %Do nothing, just skip the month
                else
                    if mon==6;validjunc=validjunc+1;elseif mon==7;validjulc=validjulc+1;elseif mon==8;validaugc=validaugc+1;end
                    fprintf('Current year and month are %d, %d\n',year,mon);
                    if mon<=9
                        curFile=load(char(strcat(curDir,'/',varlist(variab),'/',...
                            num2str(year),'/',varlist(variab),'_',num2str(year),...
                        '_0',num2str(mon),'_01.mat')));
                        lastpartcur=char(strcat(varlist(variab),'_',num2str(year),'_0',num2str(mon),'_01'));
                    else 
                        curFile=load(char(strcat(curDir,'/',varlist(variab),'/',...
                            num2str(year),'/',varlist(variab),'_',num2str(year),...
                        '_',num2str(mon),'_01.mat')));
                        lastpartcur=char(strcat(varlist(variab),'_',num2str(year),'_',num2str(mon),'_01'));
                    end
                    curArr=eval(['curFile.' lastpartcur]);curArr{3}=curArr{3}-adj;
                    if variab==3 %height, where we are most interested in the 500-hPa level
                        total=total+sum(curArr{3}(:,:,3,:),4);
                    else
                        total=total+sum(curArr{3}(:,:,1,:),4); %1000-hPa level for everything else
                    end
                end
            end
        end
        total=total./(validjunc*30+validjulc*31+validaugc*31);
        if variab==1
            narravgdailyjjat=total;
        elseif variab==2
            narravgdailyjjashum=total;
        elseif variab==3
            narravgdailyjjagh500=total;
        elseif variab==4
            narravgdailyjjauwnd=total;
        elseif variab==5
            narravgdailyjjavwnd=total;
        end
    end
    %Convert specific humidity to mixing ratio (nearly identical however)
    narravgjjamr=narravgdailyjjashum./(1-narravgdailyjjashum);
    %Get saturation values from temperature
    narravgjjaes=6.11*10.^(7.5*narravgdailyjjat./(237.3+narravgdailyjjat));
    %Convert saturation vp to saturation mr, assuming P=1000
    narravgjjaws=0.622*narravgjjaes/1000;
    %RH=w/ws
    narravgjjarh=100*narravgjjamr./narravgjjaws;
    %Finally, use T and RH to compute WBT
    narravgjjawbt=narravgdailyjjat.*atan(0.151977.*(narravgjjarh+8.313659).^0.5)+...
        atan(narravgdailyjjat+narravgjjarh)-atan(narravgjjarh-1.676331)+...
        0.00391838.*(narravgjjarh.^1.5).*atan(0.0231.*narravgjjarh)-4.686035;
    
    %Save variables
    save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/workspace_readnarrdatadailyavgfields',...
        'narravgdailyjjat','narravgdailyjjashum','narravgdailyjjagh500','narravgdailyjjauwnd','narravgdailyjjavwnd');
end


%Plot some basic seasonal-climo results
%POSSIBLY COMPLETELY SUPERSEDED BY THE ABOVE LOOP
if plotseasonalclimonarrdata==1
    disp('Plotting some basic seasonal-climo results');
    %Compute and plot mean daily temp for DJF, MAM, JJA, SON from NARR
    %This requires wrangling lots of mat-files
    for variab=1:size(varsdes,1)
        if strcmp(varlist(varsdes(variab)),'air')
            vararginnew={'variable';'temperature';'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet';'overlaynow';0};
            adj=273.15;scalarvar=1;
        elseif strcmp(varlist(varsdes(variab)),'shum')
            vararginnew={'variable';'wet-bulb temp';'contour';1;'mystep';0.001;'plotCountries';1;'colormap';'jet';'overlaynow';0};
            adj=0;scalarvar=1;
        elseif strcmp(varlist(varsdes(variab)),'hgt')
            vararginnew={'variable';'height';'contour';1;'mystep';0.001;'plotCountries';1;'colormap';'jet';'overlaynow';0};
            adj=0;scalarvar=1;
        elseif strcmp(varlist(varsdes(variab)),'uwnd') || strcmp(varlist(varsdes(variab)),'vwnd')
            adj=0;scalarvar=0;
        end
        djfvar=zeros(narrsz(1),narrsz(2));mamvar=zeros(narrsz(1),narrsz(2));
        jjavar=zeros(narrsz(1),narrsz(2));sonvar=zeros(narrsz(1),narrsz(2));
        djfdays=0;mamdays=0;jjadays=0;sondays=0;
        for year=yeariwf:yeariwl
            narrryear=year-yeariwf+1;
            for month=monthiwf:monthiwl
                %disp(month);
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
                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01'));
                    else 
                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                        '_',num2str(month),'_01.mat')));
                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_01'));
                    end
                    curArr=eval(['curFile.' lastpartcur]);curArr{3}=curArr{3}-adj;
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
        
        if djfdays~=0
            numdjfm=round(djfdays/30);
            matrix=djfvar/djfdays;data={lats;lons;matrix};
            if scalarvar==1
                plotModelData(data,mapregionclimo,vararginnew,'NARR');figc=figc+1;
                title(sprintf('Average Daily %s for DJF, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                    'FontSize',16,'FontWeight','bold');
            end
        end
        if mamdays~=0
            nummamm=round(mamdays/30.667);
            matrix=mamvar/mamdays;data={lats;lons;matrix};
            if scalarvar==1
                plotModelData(data,mapregionclimo,vararginnew,'NARR');figc=figc+1;
                title(sprintf('Average Daily %s for MAM, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                    'FontSize',16,'FontWeight','bold');
            end
        end
        if jjadays~=0
            numjjam=round(jjadays/30.667);
            matrix=jjavar/jjadays;data={lats;lons;matrix};
            if scalarvar==1
                plotModelData(data,mapregionclimo,vararginnew,'NARR');figc=figc+1;
                title(sprintf('Average Daily %s for JJA, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                    'FontSize',16,'FontWeight','bold');
            end
        end
        if sondays~=0
            numsonm=round(sondays/30.333);
            matrix=sonvar/sondays;data={lats;lons;matrix};
            if scalarvar==1
                plotModelData(data,mapregionclimo,vararginnew,'NARR');figc=figc+1;
                title(sprintf('Average Daily %s for SON, %d-%d',char(varlistnames{varsdes(variab)}),yeariwf,yeariwl),...
                    'FontSize',16,'FontWeight','bold');
            end
        end

        if strcmp(varlist(varsdes(variab)),'air')
            airtempmatrix=matrix; %contains the avg over all months in whatever season was last computed
        elseif strcmp(varlist(varsdes(variab)),'shum')
            shummatrix=matrix; %ditto
        elseif strcmp(varlist(varsdes(variab)),'hgt')
            hgtmatrix=matrix; %ditto
        end
        
        if scalarvar==0
            if strcmp(varlist(varsdes(variab)),'uwnd')
                uwndmatrix=matrix; %save uwnd data
            elseif strcmp(varlist(varsdes(variab)),'vwnd')
                vwndmatrix=matrix;
                %Now I can plot because uwnd has already been read in
                data={lats;lons;uwndmatrix;vwndmatrix};
                vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';data};
                plotModelData(data,mapregionclimo,vararginnew,'NARR');
            end
        end  
    end
end
    


%Analyze synoptic conditions on hottest region-wide days (i.e. in NYC, from station obs)
%Already have an ordered list of the hottest region-wide days from readnycdata and analyzenycdata 
%(dailymaxXregsorted or reghwbyXstarts), 
%but only some of those are within the 1979-2014 NARR period of record, so need to analyze that subset
%This uses for computation whichever index one desires
%As this loop is not that computationally expensive, some partial repetition vis-à-vis above is OK
%Select number of hot days to include in this analysis by setting numd
%Temperature is a proxy for availability of the data at all (i.e. because
%some months are missing NARR data completely; of particular note, 8/2005 and all of 2008)
%Also restrict to JJA hot days since currently don't have NARR data for May or Sep
if organizenarrheatwaves==1
    hoteventsarrs={};heahelper=0;
    plotdays=cell(2,1);
    reghwstarts=eval(['reghw' rankby{vartorankby} 'starts']);
    if compositehotdays==1
        numtodo=numd;vecsize=10000;
    elseif compositehwdays==1
        numtodo=numreghws;vecsize=eval(['numreghws' rankby{vartorankby}]);
    end
    for categ=1:2
        rowtomake=1;rowtosearch=1;
        vecsize=eval(['numreghws' rankby{categ}]);
        while rowtomake<=numtodo && rowtosearch<=vecsize
            thismonmissing=0;
            if compositehotdays==1
                thismon=DOYtoMonth(dailymaxXregsorted{categ}(rowtosearch,2),dailymaxXregsorted{categ}(rowtosearch,3));
                thisyear=dailymaxXregsorted{categ}(rowtosearch,3);
            elseif compositehwdays==1
                if categ==1
                    thismon=DOYtoMonth(reghwbyTstarts(rowtosearch,1),reghwbyTstarts(rowtosearch,2));
                    thisyear=reghwbyTstarts(rowtosearch,2);
                elseif categ==2
                    thismon=DOYtoMonth(reghwbyWBTstarts(rowtosearch,1),reghwbyWBTstarts(rowtosearch,2));
                    thisyear=reghwbyWBTstarts(rowtosearch,2);
                end
            end
            %Don't include in ranking any months whose NARR data is missing
            for i=1:size(missingymdailyair,1)
                if thismon==missingymdailyair(i,1) && thisyear==missingymdailyair(i,2)
                    thismonmissing=1;
                end
            end
            if compositehotdays==1
                if dailymaxXregsorted{categ}(rowtosearch,3)>=1979 && thismonmissing==0 &&...
                        dailymaxXregsorted{categ}(rowtosearch,2)>=152 && dailymaxXregsorted{categ}(rowtosearch,2)<=243
                    plotdays{categ}(rowtomake,1)=dailymaxXregsorted{categ}(rowtosearch,2);
                    plotdays{categ}(rowtomake,2)=dailymaxXregsorted{categ}(rowtosearch,3);
                    rowtomake=rowtomake+1;
                end
            elseif compositehwdays==1
                if categ==1
                    if reghwbyTstarts(rowtosearch,2)>=1979 && thismonmissing==0 &&...
                        reghwbyTstarts(rowtosearch,1)>=152 && reghwbyTstarts(rowtosearch,1)<=243
                        if firstday==1
                            plotdays{categ}(rowtomake,1)=reghwbyTstarts(rowtosearch,1); %first day of a heat wave
                        else
                            plotdays{categ}(rowtomake,1)=reghwbyTstarts(rowtosearch,1)+reghwbyTstarts(rowtosearch,3)-1; %last day
                        end
                        plotdays{categ}(rowtomake,2)=reghwbyTstarts(rowtosearch,2);
                        rowtomake=rowtomake+1;
                    end
                elseif categ==2
                    if reghwbyWBTstarts(rowtosearch,2)>=1979 && thismonmissing==0 &&...
                        reghwbyWBTstarts(rowtosearch,1)>=152 && reghwbyWBTstarts(rowtosearch,1)<=243
                        if firstday==1
                            plotdays{categ}(rowtomake,1)=reghwbyWBTstarts(rowtosearch,1); %first day of a heat wave
                        else
                            plotdays{categ}(rowtomake,1)=reghwbyWBTstarts(rowtosearch,1)+reghwbyWBTstarts(rowtosearch,3)-1; %last day
                        end
                        plotdays{categ}(rowtomake,2)=reghwbyWBTstarts(rowtosearch,2);
                        rowtomake=rowtomake+1;
                    end
                end
            end
            rowtosearch=rowtosearch+1;
        end
        plotdays{categ}=sortrows(plotdays{categ},[2 1]); %sort chronologically
        %Analogously: corresponding reghwbyTstarts and cluster memberships list
        %compressed to include only those heat waves for which I have valid NARR data 
        %(i.e. 1979-2014 excluding 08/2005 and 2008)
        reghwbyTstartsnarr(1:20,:)=reghwbyTstarts(16:35,:);
        reghwbyTstartsnarr(21:22,:)=reghwbyTstarts(38:39,:);
        reghwbyTstartsnarr(23:30,:)=reghwbyTstarts(41:48,:);
        %First column of idxnarr is cluster memberships of first days; second, of last days
        idxnarr(1:20,1)=idx(31:2:69,1);idxnarr(21:22,1)=idx(75:2:77,1);idxnarr(23:30,1)=idx(81:2:95,1);
        idxnarr(1:20,2)=idx(32:2:70,1);idxnarr(21:22,2)=idx(76:2:78,1);idxnarr(23:30,2)=idx(82:2:96,1);
        if firstday==1;idxnarrtouse=idxnarr(:,1);elseif firstday==0;idxnarrtouse=idxnarr(:,2);end
    end
        
    %First mode of attack is just a composite
    %Essentially, loop consists of reading in & summing data on heat-wave
    %days (both all of them, and separating them out by cluster)
    for variab=1:size(varsdes,1)
        prevArr={};
        if strcmp(varlist{varsdes(variab)},'air')
            vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;...
                'colormap';'jet';'caxismethod';cbsetting};
            adj=273.15;scalarvar=1;
        elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
            vararginnew={'variable';varargnames{varsdes(variab)};'contour';contouropt;'plotCountries';1;...
                'colormap';'jet';'caxismethod';cbsetting};
            adj=0;scalarvar=1;
        elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
            vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';data};
            adj=0;scalarvar=0;
        end
        djfvar=zeros(narrsz(1),narrsz(2));mamvar=zeros(narrsz(1),narrsz(2));
        jjavar=zeros(narrsz(1),narrsz(2));sonvar=zeros(narrsz(1),narrsz(2));
        total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
        for clust=1:6
            eval(['totalcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
            eval(['totalwbtcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
        end
        hotdaysc=0;hoteventsc=0;djfdays=0;mamdays=0;jjadays=0;sondays=0;
        hotdaysccl1=0;hotdaysccl2=0;hotdaysccl3=0;hotdaysccl4=0;hotdaysccl5=0;hotdaysccl6=0;
        exist hotdaysfirstccl1;
        if ans==0 || redohotdaysfirstc==1
            hotdaysfirstccl1=0;hotdaysfirstccl2=0;hotdaysfirstccl3=0;
            hotdaysfirstccl4=0;hotdaysfirstccl5=0;hotdaysfirstccl6=0;
        end
        if ans==0 || redohotdayslastc==1
            hotdayslastccl1=0;hotdayslastccl2=0;hotdayslastccl3=0;
            hotdayslastccl4=0;hotdayslastccl5=0;hotdayslastccl6=0;
        end
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
                    %Search through listing of region-wide heat-wave days to see if this month contains one of them
                    for row=1:size(plotdays{vartorankby},1)
                        if plotdays{vartorankby}(row,2)==year && plotdays{vartorankby}(row,1)>=curmonstart...
                                && plotdays{vartorankby}(row,1)<curmonstart+curmonlen
                            dayinmonth=plotdays{vartorankby}(row,1)-curmonstart+1;disp(dayinmonth);
                            if month<=9
                                curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                    num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                    '_0',num2str(month),'_01.mat')));
                                lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01'));
                                if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                    prevFile=load(char(strcat(curDir,'/','air','/',...
                                    num2str(year),'/','air','_',num2str(year),...
                                    '_0',num2str(month),'_01.mat')));
                                    lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_01'));
                                    prevArr=eval(['prevFile.' lastpartprev]);
                                end
                            else 
                                curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                    num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                '_',num2str(month),'_01.mat')));
                                lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_01'));
                                if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                    prevFile=load(char(strcat(curDir,'/','air','/',...
                                    num2str(year),'/','air','_',num2str(year),...
                                    '_',num2str(month),'_01.mat')));
                                    lastpartprev=char(strcat('air','_',num2str(year),'_',num2str(month),'_01'));
                                    prevArr=eval(['prevFile.' lastpartprev]);
                                end
                            end
                            curArr=eval(['curFile.' lastpartcur]);
                            
                            if hotdaysc>=1;oldDOI=arrDOI;end
                            if strcmp(varlist(varsdes(variab)),'hgt')
                                arrDOI=curArr{3}(:,:,preslevel,dayinmonth)-adj; %DOI is day of interest
                            else
                                arrDOI=curArr{3}(:,:,1,dayinmonth)-adj; %DOI is day of interest
                                %Compute WBT from T and RH (see average-computation loop above for details)
                                if strcmp(varlist{varsdes(variab)},'shum')
                                    arrDOIprev=prevArr{3}(:,:,1,dayinmonth)-273.15;
                                    mrArr=arrDOI./(1-arrDOI);
                                    esArr=6.11*10.^(7.5*arrDOIprev./(237.3+arrDOIprev));
                                    wsArr=0.622*esArr/1000;
                                    rhArr=100*mrArr./wsArr;
                                    arrDOIwbt=arrDOIprev.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                        atan(arrDOIprev+rhArr)-atan(rhArr-1.676331)+...
                                        0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                    totalwbt=totalwbt+arrDOIwbt;
                                end
                            end
                            %Save data indiscriminately if I don't care about clusters
                            total=total+arrDOI;
                            hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                            %If I do, determine what cluster this day belongs to,
                            %and save its data accordingly
                            curcluster=idxnarrtouse(row);
                            totalthisclust=eval(['totalcl' num2str(curcluster)]);
                            totalthisclust=totalthisclust+arrDOI;
                            eval(['totalcl' num2str(curcluster) '=totalthisclust;']);
                            totalwbtthisclust=eval(['totalwbtcl' num2str(curcluster)]);
                            totalwbtthisclust=totalwbtthisclust+arrDOIwbt;
                            eval(['totalwbtcl' num2str(curcluster) '=totalwbtthisclust;']);
                            hotdayscthisclust=eval(['hotdaysccl' num2str(curcluster)]);
                            hotdayscthisclust=hotdayscthisclust+1;
                            eval(['hotdaysccl' num2str(curcluster) '=hotdayscthisclust;']);
                            %To be able to combine data from first & last
                            %days, need to save them between runs
                            if firstday==1
                                if redohotdaysfirstc==1
                                    disp('line 550');disp('Redoing hotdaysfirstc');
                                    hotdaysfirstcthisclust=eval(['hotdaysfirstccl' num2str(curcluster)]);
                                    hotdaysfirstcthisclust=hotdaysfirstcthisclust+1;
                                    eval(['hotdaysfirstccl' num2str(curcluster) '=hotdaysfirstcthisclust;']);
                                end
                                if needtocalcfirstday==1
                                    disp('Redoing cluster counts of first days');
                                    totalthisclustfirst=eval(['totalfirstcl' num2str(curcluster)]);
                                    totalthisclustfirst=totalthisclustfirst+arrDOI;
                                    eval(['totalfirstcl' num2str(curcluster) '=totalthisclustfirst;']);
                                    totalwbtthisclustfirst=eval(['totalwbtfirstcl' num2str(curcluster)]);
                                    totalwbtthisclustfirst=totalwbtthisclustfirst+arrDOIwbt;
                                    eval(['totalwbtfirstcl' num2str(curcluster) '=totalwbtthisclustfirst;']);
                                end
                            elseif firstday==0
                                if redohotdayslastc==1
                                    disp('line 565');disp('Redoing hotdayslastc');
                                    hotdayslastcthisclust=eval(['hotdayslastccl' num2str(curcluster)]);
                                    hotdayslastcthisclust=hotdayslastcthisclust+1;
                                    eval(['hotdayslastccl' num2str(curcluster) '=hotdayslastcthisclust;']);
                                end
                                if needtocalclastday==1
                                    disp('Redoing cluster counts of last days');
                                    totalthisclustlast=eval(['totallastcl' num2str(curcluster)]);
                                    totalthisclustlast=totalthisclustlast+arrDOI;
                                    eval(['totallastcl' num2str(curcluster) '=totalthisclustlast;']);
                                    totalwbtthisclustlast=eval(['totalwbtlastcl' num2str(curcluster)]);
                                    totalwbtthisclustlast=totalwbtthisclustlast+arrDOIwbt;
                                    eval(['totalwbtlastcl' num2str(curcluster) '=totalwbtthisclustlast;']);
                                end
                            end
                            
                            %Save arrays on hot days into a cell matrix to be able to plot & compare them
                            %The beauty of this is that this loop need not be run again as long as the arrays are saved!
                            %Have to decide here if day is part of a multiday event, in which case their synoptic conds are
                            %of course highly correlated -- average the two days
                            if row>=2
                                if plotdays{vartorankby}(row,2)==plotdays{vartorankby}(row-1,2)...
                                        && abs(plotdays{vartorankby}(row,1)-plotdays{vartorankby}(row-1,1))<=7
                                    arrEvent=(oldDOI+arrDOI)./2;
                                    hoteventsarrs{hoteventsc-1,variab}=arrEvent; %the actual NARR data
                                    heahelper(hoteventsc-1,1)=plotdays{vartorankby}(row,1); %includes dates for map-title purposes
                                    heahelper(hoteventsc-1,2)=plotdays{vartorankby}(row-1,1);
                                        %the previous day that's also part of this event
                                    heahelper(hoteventsc-1,3)=plotdays{vartorankby}(row,2); %year of event
                                    hoteventsc=hoteventsc-1;%disp('Multi-day event found');
                                else
                                    arrEvent=arrDOI;
                                    hoteventsarrs{hoteventsc,variab}=arrEvent;
                                    heahelper(hoteventsc,1)=plotdays{vartorankby}(row,1);
                                    heahelper(hoteventsc,2)=0; %so it's clear later that it's a simple one-day event
                                    heahelper(hoteventsc,3)=plotdays{vartorankby}(row,2);
                                end
                            end
                        end
                    end
                end
            end
        end
        
        %Although the first set of totals lack an explicit first/last
        %name, don't be fooled -- they ARE restricted to first/last days
        %only, whatever has just been specified -- and they go into
        %specific first/last arrays arr1f{0,1} etc. below
        total=total/hotdaysc;totalwbt=totalwbt/hotdaysc;
        totalcl1=totalcl1/hotdaysccl1;totalcl2=totalcl2/hotdaysccl2;totalcl4=totalcl4/hotdaysccl4;
        totalcl5=totalcl5/hotdaysccl5;totalcl6=totalcl6/hotdaysccl6;
        totalwbtcl1=totalwbtcl1/hotdaysccl1;totalwbtcl2=totalwbtcl2/hotdaysccl2;totalwbtcl4=totalwbtcl4/hotdaysccl4;
        totalwbtcl5=totalwbtcl5/hotdaysccl5;totalwbtcl6=totalwbtcl6/hotdaysccl6;
        %Therefore, these explicit arrays are essentially the same, but are
        %saved in between runs
        if firstday==1 && needtocalcfirstday==1
            disp('line 617');disp(hotdaysfirstccl1);disp(hotdaysfirstccl2);disp(hotdayslastccl2);
            totalfirstcl1=totalfirstcl1/hotdaysfirstccl1;totalfirstcl2=totalfirstcl2/hotdaysfirstccl2;
            totalfirstcl4=totalfirstcl4/hotdaysfirstccl4;
            totalfirstcl5=totalfirstcl5/hotdaysfirstccl5;totalfirstcl6=totalfirstcl6/hotdaysfirstccl6;
            totalwbtfirstcl1=totalwbtfirstcl1/hotdaysfirstccl1;totalwbtfirstcl2=totalwbtfirstcl2/hotdaysfirstccl2;
            totalwbtfirstcl4=totalwbtfirstcl4/hotdaysfirstccl4;
            totalwbtfirstcl5=totalwbtfirstcl5/hotdaysfirstccl5;totalwbtfirstcl6=totalwbtfirstcl6/hotdaysfirstccl6;
        end
        if firstday==0 && needtocalclastday==1
            disp('line 626');disp(hotdaysfirstccl1);disp(hotdaysfirstccl2);disp(hotdayslastccl2);
            totallastcl1=totallastcl1/hotdayslastccl1;totallastcl2=totallastcl2/hotdayslastccl2;
            totallastcl4=totallastcl4/hotdayslastccl4;
            totallastcl5=totallastcl5/hotdayslastccl5;totallastcl6=totallastcl6/hotdayslastccl6;
            totalwbtlastcl1=totalwbtlastcl1/hotdayslastccl1;totalwbtlastcl2=totalwbtlastcl2/hotdayslastccl2;
            totalwbtlastcl4=totalwbtlastcl4/hotdayslastccl4;
            totalwbtlastcl5=totalwbtlastcl5/hotdayslastccl5;totalwbtlastcl6=totalwbtlastcl6/hotdayslastccl6;
        end
        
        if strcmp(varlist(varsdes(variab)),'air')
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']); %i.e. all the days (no clustering)
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl1=totalcl1;']); %all first days OR last days in cluster 1
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl2=totalcl2;']); %etc.
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl4=totalcl4;']);
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl5=totalcl5;']);
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl6=totalcl6;']);
            %Also make arrays with data from all days in a specific cluster regardless of whether they are first or last
            %Weight cluster average by its composition of first and last
            %days, rather than a straight average of the averages
            %Cluster 4 is composed of first days only
            if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                eval(['arr1f99rb' num2str(vartorankby) 'cl1='...
                    '(totalfirstcl1*hotdaysfirstccl1+totallastcl1*hotdayslastccl1)/(hotdaysfirstccl1+hotdayslastccl1);']);
                eval(['arr1f99rb' num2str(vartorankby) 'cl2='...
                    '(totalfirstcl2*hotdaysfirstccl2+totallastcl2*hotdayslastccl2)/(hotdaysfirstccl2+hotdayslastccl2);']);
                eval(['arr1f99rb' num2str(vartorankby) 'cl4='...
                    '(totalfirstcl4*hotdaysfirstccl4)/(hotdaysfirstccl4+hotdayslastccl4);']);
                eval(['arr1f99rb' num2str(vartorankby) 'cl5='...
                    '(totalfirstcl5*hotdaysfirstccl5+totallastcl5*hotdayslastccl5)/(hotdaysfirstccl5+hotdayslastccl5);']);
                eval(['arr1f99rb' num2str(vartorankby) 'cl6='...
                    '(totalfirstcl6*hotdaysfirstccl6+totallastcl6*hotdayslastccl6)/(hotdaysfirstccl6+hotdayslastccl6);']);
            end
        elseif strcmp(varlist(varsdes(variab)),'shum') %uses shum but output is WBT
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=totalwbt;']);
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl1=totalwbtcl1;']);
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl2=totalwbtcl2;']);
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl4=totalwbtcl4;']);
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl5=totalwbtcl5;']);
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl6=totalwbtcl6;']);
            if max(max(totalwbtfirstcl1))~=0 && max(max(totalwbtlastcl1))~=0
                eval(['arr2f99rb' num2str(vartorankby) 'cl1='...
                    '(totalwbtfirstcl1*hotdaysfirstccl1+totalwbtlastcl1*hotdayslastccl1)/(hotdaysfirstccl1+hotdayslastccl1);']);
                eval(['arr2f99rb' num2str(vartorankby) 'cl2='...
                    '(totalwbtfirstcl2*hotdaysfirstccl2+totalwbtlastcl2*hotdayslastccl2)/(hotdaysfirstccl2+hotdayslastccl2);']);
                eval(['arr2f99rb' num2str(vartorankby) 'cl4='...
                    '(totalwbtfirstcl4*hotdaysfirstccl4)/(hotdaysfirstccl4+hotdayslastccl4);']);
                eval(['arr2f99rb' num2str(vartorankby) 'cl5='...
                    '(totalwbtfirstcl5*hotdaysfirstccl5+totalwbtlastcl5*hotdayslastccl5)/(hotdaysfirstccl5+hotdayslastccl5);']);
                eval(['arr2f99rb' num2str(vartorankby) 'cl6='...
                    '(totalwbtfirstcl6*hotdaysfirstccl6+totalwbtlastcl6*hotdayslastccl6)/(hotdaysfirstccl6+hotdayslastccl6);']);
            end
        elseif strcmp(varlist(varsdes(variab)),'hgt')
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']);
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl1=totalcl1;']);
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl2=totalcl2;']);
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl4=totalcl4;']);
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl5=totalcl5;']);
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl6=totalcl6;']);
            if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                eval(['arr3f99rb' num2str(vartorankby) 'cl1='...
                    '(totalfirstcl1*hotdaysfirstccl1+totallastcl1*hotdayslastccl1)/(hotdaysfirstccl1+hotdayslastccl1);']);
                eval(['arr3f99rb' num2str(vartorankby) 'cl2='...
                    '(totalfirstcl2*hotdaysfirstccl2+totallastcl2*hotdayslastccl2)/(hotdaysfirstccl2+hotdayslastccl2);']);
                eval(['arr3f99rb' num2str(vartorankby) 'cl4='...
                    '(totalfirstcl4*hotdaysfirstccl4+totallastcl4*hotdayslastccl4)/(hotdaysfirstccl4+hotdayslastccl4);']);
                eval(['arr3f99rb' num2str(vartorankby) 'cl5='...
                    '(totalfirstcl5*hotdaysfirstccl5+totallastcl5*hotdayslastccl5)/(hotdaysfirstccl5+hotdayslastccl5);']);
                eval(['arr3f99rb' num2str(vartorankby) 'cl6='...
                    '(totalfirstcl6*hotdaysfirstccl6+totallastcl6*hotdayslastccl6)/(hotdaysfirstccl6+hotdayslastccl6);']);
            end
        elseif strcmp(varlist(varsdes(variab)),'uwnd')
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']);
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl1=totalcl1;']);
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl2=totalcl2;']);
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl4=totalcl4;']);
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl5=totalcl5;']);
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl6=totalcl6;']);
            if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                eval(['arr4f99rb' num2str(vartorankby) 'cl1='...
                    '(totalfirstcl1*hotdaysfirstccl1+totallastcl1*hotdayslastccl1)/(hotdaysfirstccl1+hotdayslastccl1);']);
                eval(['arr4f99rb' num2str(vartorankby) 'cl2='...
                    '(totalfirstcl2*hotdaysfirstccl2+totallastcl2*hotdayslastccl2)/(hotdaysfirstccl2+hotdayslastccl2);']);
                eval(['arr4f99rb' num2str(vartorankby) 'cl4='...
                    '(totalfirstcl4*hotdaysfirstccl4+totallastcl4*hotdayslastccl4)/(hotdaysfirstccl4+hotdayslastccl4);']);
                eval(['arr4f99rb' num2str(vartorankby) 'cl5='...
                    '(totalfirstcl5*hotdaysfirstccl5+totallastcl5*hotdayslastccl5)/(hotdaysfirstccl5+hotdayslastccl5);']);
                eval(['arr4f99rb' num2str(vartorankby) 'cl6='...
                    '(totalfirstcl6*hotdaysfirstccl6+totallastcl6*hotdayslastccl6)/(hotdaysfirstccl6+hotdayslastccl6);']);
            end
        elseif strcmp(varlist(varsdes(variab)),'vwnd')
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']);
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl1=totalcl1;']);
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl2=totalcl2;']);
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl4=totalcl4;']);
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl5=totalcl5;']);
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl6=totalcl6;']);
            if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                eval(['arr5f99rb' num2str(vartorankby) 'cl1='...
                    '(totalfirstcl1*hotdaysfirstccl1+totallastcl1*hotdayslastccl1)/(hotdaysfirstccl1+hotdayslastccl1);']);
                eval(['arr5f99rb' num2str(vartorankby) 'cl2='...
                    '(totalfirstcl2*hotdaysfirstccl2+totallastcl2*hotdayslastccl2)/(hotdaysfirstccl2+hotdayslastccl2);']);
                eval(['arr5f99rb' num2str(vartorankby) 'cl4='...
                    '(totalfirstcl4*hotdaysfirstccl4)/(hotdaysfirstccl4+hotdayslastccl4);']);
                eval(['arr5f99rb' num2str(vartorankby) 'cl5='...
                    '(totalfirstcl5*hotdaysfirstccl5+totallastcl5*hotdayslastccl5)/(hotdaysfirstccl5+hotdayslastccl5);']);
                eval(['arr5f99rb' num2str(vartorankby) 'cl6='...
                    '(totalfirstcl6*hotdaysfirstccl6+totallastcl6*hotdayslastccl6)/(hotdaysfirstccl6+hotdayslastccl6);']);
            end
        end
    end
    if firstday==1
        redohotdaysfirstc=0;
    elseif firstday==0
        redohotdayslastc=0;
    end
end

%Calculate fields of interest and display resulting composite maps of heat-wave days
if plotheatwavecomposites==1
    exist scalarvar;if ans==0;scalarvar=1;end %assume scalar if not yet given
    if shownonoverlaycompositeplots==1
        for variab=1:size(varsdes,1)
            if anomfromjjaavg==1
                data={lats;lons;...
                eval(['arr' num2str(varsdes(variab)) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-...
                eval(['narravgjja' char(varlist2(varsdes(variab)))])};
            else
                data={lats;lons;...
                eval(['arr' num2str(varsdes(variab)) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
            end
            vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'colormap';'jet';'caxismethod';cbsetting;'overlaynow';0};
            %disp(max(max(data{3})));
            plotModelData(data,mapregionsynop,vararginnew,'NARR');
            title(sprintf('%s Daily %s %s %d %s in the NYC Area as Defined by %s%s',anomavg{anomfromjjaavg+1},...
                char(varlistnames{varsdes(variab)}),dayremark,hotdaysc,hwremark,categlabel,clustremark{clustdes+1}),...
                'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarr%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},...
                    varlist3{vartorankby},firstlast{flarg},clustlb);
        end
    end
    if overlay==1 && showoverlaycompositeplots==1 %Make single or double overlay
        if overlaynum==4 %wind
            if strcmp(varlist(varsdes(size(varsdes,1))),'vwnd') %if on uwnd, we don't have enough to plot yet
                if anomfromjjaavg==1
                    overlaydata={lats;lons;...
                        eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgdailyjjauwnd;...
                        eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgdailyjjavwnd};
                    underlaydata={lats;lons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])...
                        -eval(['narravgjja' char(varlist2(underlaynum))])};
                else
                    overlaydata={lats;lons;...
                        eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])}; %wind (both components)
                    underlaydata={lats;lons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                end
                vararginnew={'variable';'wind';'contour';contouropt;'mystep';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';overlaydata;'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                plotModelData(overlaydata,mapregionsynop,vararginnew,'NARR');figc=figc+1;
                %Add title to newly-made figure
                phrpart1=sprintf('%s Daily 1000-hPa Wind and %s%s',anomavg{anomfromjjaavg+1},...
                    prespr{underlaynum},char(varlistnames{underlaynum}));
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s',dayremark,hotdaysc,hwremark,categlabel,clustremark{clustdes+1});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},varlist3{varsdes(2)},...
                    varlist3{vartorankby},firstlast{flarg},clustlb);
            end
        elseif overlaynum==1 || overlaynum==2 || overlaynum==3 %scalars
            if anomfromjjaavg==1
                overlaydata={lats;lons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-...
                    eval(['narravgjja' char(varlist2(overlaynum))])};
                underlaydata={lats;lons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-...
                    eval(['narravgjja' char(varlist2(underlaynum))])};
                if clusteranomfromavg==1 %This cluster's anomalies with respect to both the JJA avg and the all-cluster avg
                    overlaydata{3}=overlaydata{3}-(eval(['arr' num2str(overlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0'])-...
                        eval(['narravgjja' char(varlist2(overlaynum))]));
                    underlaydata{3}=underlaydata{3}-(eval(['arr' num2str(underlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0'])-...
                        eval(['narravgjja' char(varlist2(underlaynum))]));
                end
                if overlaynum2~=0 %Double overlay (contours+barbs)
                    overlaydata2={lats;lons;...
                        eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgdailyjjauwnd;...
                        eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgdailyjjavwnd};
                    if clusteranomfromavg==1 
                        overlaydata2{3}=overlaydata2{3}-...
                            (eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0'])-narravgdailyjjauwnd);
                        overlaydata2{4}=overlaydata2{4}-...
                            (eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0'])-narravgdailyjjavwnd);
                    end
                end
            else
                overlaydata={lats;lons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                underlaydata={lats;lons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                if overlaynum2~=0
                    overlaydata2={lats;lons;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                end
            end
            if overlaynum2~=0 %Double overlay, with one overlayvariable as contours and then wind as barbs
                vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting;...
                'vectorData';overlaydata2;'overlaynow';overlay;'overlayvariable';overlayvar;...
                'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
            else
                vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;...
                'caxismethod';cbsetting;'overlaynow';overlay;'overlayvariable';overlayvar;...
                'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
            end
            %Actually do the plotting
            plotModelData(overlaydata,mapregionsynop,vararginnew,'NARR');figc=figc+1;
            %Add title to newly-made figure
            if overlaynum2==0
                phrpart1=sprintf('%s Daily %s and %s%s',anomavg{anomfromjjaavg+1},char(varlistnames{overlaynum}),...
                    prespr{underlaynum},char(varlistnames{underlaynum}));
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s',dayremark,hotdaysc,hwremark,categlabel,clustremark{clustdes+1});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},varlist3{varsdes(2)},...
                    varlist3{vartorankby},firstlast{flarg},clustlb);
            else
                phrpart1=sprintf('%s Daily %s, %s, and %s%s',anomavg{anomfromjjaavg+1},char(varlistnames{overlaynum}),...
                    char(varlistnames{overlaynum2}),prespr{underlaynum},char(varlistnames{underlaynum}));
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s%s',dayremark,hotdaysc,hwremark,categlabel,...
                    clustremark{clustdes+1},clustanom{clusteranomfromavg+1});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%s%sby%s%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},varlist3{varsdes(2)},...
                    varlist3{varsdes(3)},varlist3{vartorankby},firstlast{flarg},clustlb,clanomlb);
            end
        end
    end
    fig=gcf;saveas(fig,sprintf('%s%s',figloc,figname));
end
        
      
%Plot differences between some of the plots calculated above, as they are
%in many cases quite similar and it's difficult to see by eye
%For the comparisons of first vs. last days and T vs. WBT (plots 1-6), cluster 0 (i.e. no clustering
%at all) is the only thing that really makes sense, as the clusters were
%defined by and include both first and last days...
%Comparing clusters 1, 4, and 6 is the most logical, as 1 & 4 are primarily
%first days, and 6 primarily last days
if plotcompositeddifferences==1
    for plotnum=1:1
        %All arrays are term 1 - term 2 (fterm1=0 --> last day; rbterm1=1 --> ranked by T; etc.)
        if plotnum==1 %T, GPH, winds on last days vs first days (ranked by T)
            torwbt=1;fterm1=0;fterm2=1;rbterm1=1;rbterm2=1; 
        elseif plotnum==2 %WBT, GPH, winds on last days vs first days (ranked by WBT)
            torwbt=2;fterm1=0;fterm2=1;rbterm1=2;rbterm2=2; 
        elseif plotnum==3 %T, GPH, winds defined by WBT vs defined by T (on last days)
            torwbt=1;fterm1=0;fterm2=0;rbterm1=2;rbterm2=1;
        elseif plotnum==4 %WBT, GPH, winds defined by WBT vs defined by T (on last days)
            torwbt=2;fterm1=0;fterm2=0;rbterm1=2;rbterm2=1; 
        elseif plotnum==5 %T, GPH, winds defined by WBT vs defined by T (on first days)
            torwbt=1;fterm1=1;fterm2=1;rbterm1=2;rbterm2=1;
        elseif plotnum==6 %WBT, GPH, winds defined by WBT vs defined by T (on first days)
            torwbt=2;fterm1=1;fterm2=1;rbterm1=2;rbterm2=1;
        elseif plotnum==7 %WBT, GPH, winds defined by T on last days in cluster 1 vs cluster 4
            torwbt=2;fterm1=1;fterm2=1;rbterm1=2;rbterm2=1;
        elseif plotnum==8 %WBT, GPH, winds defined by T on last days in cluster 1 vs cluster 4
            torwbt=2;fterm1=1;fterm2=1;rbterm1=2;rbterm2=1;
        elseif plotnum==9 %WBT, GPH, winds defined by T on last days in cluster 1 vs cluster 4
            torwbt=2;fterm1=1;fterm2=1;rbterm1=2;rbterm2=1;
        end
         
        %T and WBT are made easily swappable with numbers; torwbtdiff1--T and torwbtdiff2--WBT (no mysteries here!)
        torwbtdiff1=eval(['arr1f' num2str(fterm1) 'rb' num2str(rbterm1) 'cl' num2str(clustdes)])-...
            eval(['arr1f' num2str(fterm2) 'rb' num2str(rbterm2) 'cl' num2str(clustdes)]);
        torwbtdiff2=eval(['arr2f' num2str(fterm1) 'rb' num2str(rbterm1) 'cl' num2str(clustdes)])-...
            eval(['arr2f' num2str(fterm2) 'rb' num2str(rbterm2) 'cl' num2str(clustdes)]);
        gpdiff=eval(['arr3f' num2str(fterm1) 'rb' num2str(rbterm1) 'cl' num2str(clustdes)])-...
            eval(['arr3f' num2str(fterm2) 'rb' num2str(rbterm2) 'cl' num2str(clustdes)]);
        uwnddiff=eval(['arr4f' num2str(fterm1) 'rb' num2str(rbterm1) 'cl' num2str(clustdes)])-...
            eval(['arr4f' num2str(fterm2) 'rb' num2str(rbterm2) 'cl' num2str(clustdes)]);
        vwnddiff=eval(['arr5f' num2str(fterm1) 'rb' num2str(rbterm1) 'cl' num2str(clustdes)])-...
            eval(['arr5f' num2str(fterm2) 'rb' num2str(rbterm2) 'cl' num2str(clustdes)]);
        
        %Set up and make the map
        torwbtdiff=eval(['torwbtdiff' num2str(torwbt)]);
        torwbtdiffarr={lats;lons;torwbtdiff};gpdiffarr={lats;lons;gpdiff};wnddiffarr={lats;lons;uwnddiff;vwnddiff};
        vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';'regional10';...
            'vectorData';wnddiffarr;'overlaynow';1;'overlayvariable';'height';'underlayvariable';'temperature';...
            'datatooverlay';gpdiffarr;'datatounderlay';torwbtdiffarr};
        plotModelData(gpdiffarr,mapregionsynop,vararginnew,'NARR');
        
        %Add title and save figure
        if plotnum==1
            phrpart1=sprintf('1000-hPa Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days vs. First Days of T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes+1});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==2
            phrpart1=sprintf('1000-hPa Wet-Bulb Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days vs. First Days of WBT-Ranked NYC-Area Heat Waves%s',clustremark{clustdes+1});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==3
            phrpart1=sprintf('1000-hPa Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes+1});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==4
            phrpart1=sprintf('1000-hPa Wet-Bulb Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes+1});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==5
            phrpart1=sprintf('1000-hPa Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes+1});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindwbtvstrankedfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==6
            phrpart1=sprintf('1000-hPa Wet-Bulb Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes+1});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtvstrankedfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        end
    end
end




if showindiveventplots==1
    for variab=1:size(varsdes,1)
        if varsdes(variab)==4;varhere=3;else varhere=varsdes(variab);end %vwnd is treated the same as uwnd
        argname=varargnames{varhere};
        for event=1:size(hoteventsarrs,1)
            if strcmp(varlist(varsdes(variab)),'uwnd')
                goplot=0;
            elseif strcmp(varlist(varsdes(variab)),'vwnd')
                data={lats;lons;hoteventsarrs{event,3};hoteventsarrs{event,4}};goplot=1;
                vararginnew={'variable';argname;'contour';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';data};
            else %i.e. any scalar variable
                data={lats;lons;hoteventsarrs{event}};goplot=1;
                vararginnew={'variable';argname;'contour';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting};
            end

            if goplot==1 
                [caxisrange,step,mycolormap]=plotModelData(data,mapregionlocal,vararginnew,'NARR');figc=figc+1;

                if strcmp(varlist(varsdes(variab)),'air') %temp is the only useful variable I have from CLIMOD after all
                    %only have air temp for stns so it doesn't make sense to plot anything else
                    %Overlay station data (avg of maxes & mins corresponding to this hot event) for comparison
                    sums=cell(numstnsd,1);
                    for stn=1:numstnsd
                        pt1lat=stnlocs(stn,1);pt1lon=stnlocs(stn,2);c=0;colorset=0;
                        for row=1:size(dailymaxvecs1D{stn},1)
                            if dailymaxvecs1D{stn}(row,2)==heahelper(event,1) && dailymaxvecs1D{stn}(row,3)==heahelper(event,3)
                                %disp('heat wave match');disp(row);
                                if dailymaxvecs1D{stn}(row,1)>-50;sums{stn}=dailymaxvecs1D{stn}(row,1);c=c+1;end
                                if dailyminvecs1D{stn}(row,1)>-50;sums{stn}=sums{stn}+dailyminvecs1D{stn}(row,1);c=c+1;end
                                if heahelper(event,2)>0 %multi-day event, so need to include day before as well
                                    if dailymaxvecs1D{stn}(row-1,1)>-50;sums{stn}=sums{stn}+dailymaxvecs1D{stn}(row-1,1);c=c+1;end
                                    if dailyminvecs1D{stn}(row-1,1)>-50;sums{stn}=sums{stn}+dailyminvecs1D{stn}(row-1,1);c=c+1;end
                                end
                            end 
                        end
                        sums{stn}=sums{stn}./c; %average daily temp for this station over this heat event
                        if sums{stn}>0;continueon=1;else continueon=0;end
                        if continueon==1
                            %disp('Looking for new color match with station temp:');disp(sum{stn});
                            for i=1:11
                                if sums{stn}<caxisrange(1)+step && colorset==0 %station falls in first decile of NARR color range
                                    mycolor=mycolormap(i,:);
                                    colorset=1;
                                elseif i>1 && sums{stn}<caxisrange(1)+i*step && colorset==0
                                    mycolor=mycolormap(round((i-1)*size(mycolormap,1)/10),:);
                                    %disp('Color found');disp(stn);disp(round((i-1)*size(mycolormap,1)/10));disp(sum{stn});
                                    colorset=1;
                                elseif sums{stn}>caxisrange(2) && colorset==0 %station exceeds top decile
                                    mycolor=mycolormap(size(mycolormap,1),:);
                                    colorset=1;
                                end
                            end
                            h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker','s',...
                    'MarkerFaceColor',mycolor,'MarkerEdgeColor','k','MarkerSize',11);
                        end
                    end
                end

                %Add a nice title, just once for each event/map
                if heahelper(event,2)>0 %a multi-day event
                    title(sprintf('Daily %s on %s and %s, %d',...
                    char(varlistnames{varsdes(variab)}),DOYtoDate(heahelper(event,2),heahelper(event,3)),...
                    DOYtoDate(heahelper(event,1),heahelper(event,3)),heahelper(event,3)),...
                    'FontName','Arial','FontSize',16,'FontWeight','bold');
                else %one singleton hot day
                    title(sprintf('Daily %s on %s, %d',...
                    char(varlistnames{varsdes(variab)}),DOYtoDate(heahelper(event,1),heahelper(event,3)),...
                    heahelper(event,3)),'FontSize',16,'FontWeight','bold','FontName','Arial');
                end
            end
        end
    end
end



%A continuation of the above: chart of the 1979-2014 hot days showing how they
%compare when ranking by Tmax and WBTmax
if showdaterankchart==1
    rowtomake=1;allreghotdays=0;rankmatrix={};rankmatrix2=0;
    %First, make a list of all the dates that show up in the top 99th pctile in either one
    for categ=1:2
        for i=1:size(plotdays{1},1)
            alreadyhavethisday=0;
            if size(allreghotdays,2)>1
                for j=1:size(allreghotdays,1)
                    if allreghotdays(j,1)==plotdays{categ}(i,1) && allreghotdays(j,2)==plotdays{categ}(i,2)
                        alreadyhavethisday=1;
                    end
                end
            end
            if alreadyhavethisday==0
                allreghotdays(rowtomake,1)=plotdays{categ}(i,1);
                allreghotdays(rowtomake,2)=plotdays{categ}(i,2);
                rowtomake=rowtomake+1;
            end
        end
    end
    allreghotdays=sortrows(allreghotdays,[2 1]);

    %Now that the list exists, make an auxiliary matrix with shadings for the dates' rankings by Tmax and WBTmax
    for i=1:size(allreghotdays,1)
        for categ=1:2
            rankfound=0;
            for row=1:size(plotdays{categ},1)
                if allreghotdays(i,1)==dailymaxXregsorted{categ}(row,2) && allreghotdays(i,2)==dailymaxXregsorted{categ}(row,3)
                    rankmatrix{i,categ}=row;rankmatrix2(i,categ)=row;
                end
            end
        end       
    end

    %Display list together with shadings dictated by the rankings
    rankmatrix2(rankmatrix2==0)=NaN;
    figure(figc);clf;figc=figc+1;
    imagescnan(rankmatrix2);
    for i=1:size(allreghotdays,1)
        allregmonthdays{i}=strcat(strtrim(DOYtoDate(allreghotdays(i,1),allreghotdays(i,2))));
        allregyears{i}=num2str(allreghotdays(i,2));
    end
    for i=1:61;text(0.22,i,allregmonthdays{i});text(0.34,i,allregyears{i});end
    colormap(flipud(colormap));colorbar;
    %numcols=lastcol-firstcol+1;
    %if numcols==3
    %    text(1.52,-3,'Hot Days Ranked by Regional-Avg...','FontSize',16,'FontWeight','bold');
    %    text(0.72,-1,'Maximum Temperature','FontSize',16,'FontWeight','bold');
    %    text(1.72,-1,'Wet-Bulb Temperature','FontSize',16,'FontWeight','bold');
    %    text(2.87,-1,'Heat Index','FontSize',16,'FontWeight','bold');
    %    text(1.46,65,'Colors represent ranking (with white >=36)','FontSize',16,'FontWeight','bold');
    %elseif firstcol==1 && lastcol==2
        text(1.15,-3,'Hot Days Ranked by Regional-Avg...','FontSize',16,'FontWeight','bold');
        text(0.72,-1,'Maximum Temperature','FontSize',16,'FontWeight','bold');
        text(1.75,-1,'Wet-Bulb Temperature','FontSize',16,'FontWeight','bold');
        text(1.14,65,'Colors represent ranking (with white >=36)','FontSize',16,'FontWeight','bold');
    %elseif firstcol==2 && lastcol==3
    %    text(1.15,-3,'Hot Days Ranked by Regional-Avg...','FontSize',16,'FontWeight','bold');
    %    text(0.72,-1,'Wet-Bulb Temperature','FontSize',16,'FontWeight','bold');
    %    text(1.75,-1,'Heat Index','FontSize',16,'FontWeight','bold');
    %    text(1.14,65,'Colors represent ranking (with white >=36)','FontSize',16,'FontWeight','bold');
    %end
end

%Compute heat waves at NARR gridpts using formula specially adapted for daily data
if calchwsatcontigusgridpts==1
    %0. Prepare list of gridpts to use -- either all contiguous-US gridpts
    %using the narrgridptsparallelogram function, or a custom list of only
    %a few evenly spaced across the contig US -- every 5 deg in lat & lon is a good compromise
    %between efficacy and completeness
    if preparegridptslist==1
        if selectedgridpts==1 %closest of these points to NYC will be 127,257 at 40 N, 75 W
            gridptstouse=zeros(narrsz(1),narrsz(2));
            gridptlistlatlon=0;
            numgridpts=1;
            for deslat=25:spacing:50
                for deslon=-125:spacing:-65
                    disp(deslat);disp(deslon);
                    gridptlistlatlon(numgridpts,1)=deslat;gridptlistlatlon(numgridpts,2)=deslon;
                    temp=wnarrgridpts(deslat,deslon,1,0);
                    thisgridptx=temp(1,1);thisgridpty=temp(1,2);
                    gridptstouse(thisgridptx,thisgridpty)=1;
                    numgridpts=numgridpts+1;
                end
            end
        else
            gridptstouse=narrgridptsparallelogram(50,-125,50,-65,25,-65,25,-125);
        end
    end
    
    %1. Compile all data for each gridpt into a nice array
    if compilegridptdata==1
        validjunc=0;validjulc=0;validaugc=0;validmonc=0;validdayc=1;
        totalbygridpt=zeros(narrsz(1),narrsz(2));
        adj=273.15;
        for year=1979:2014
            narrryear=year-1979+1;
            for mon=6:8
                ymmissing=0;
                missingymdaily=missingymdailyair;
                for row=1:size(missingymdailyair,1)
                    if mon==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                end
                if ymmissing==1 %Do nothing, just skip the month
                else %Data for this month exists, so go ahead
                    if mon==6
                        validjunc=validjunc+1;thismonlen=30;
                    elseif mon==7
                        validjulc=validjulc+1;thismonlen=31;
                    elseif mon==8
                        validaugc=validaugc+1;thismonlen=31;
                    end
                    validmonc=validmonc+1;
                    fprintf('Current year and month are %d, %d\n',year,mon);
                    curFile=load(char(strcat(curDir,'/air/',num2str(year),'/air_',num2str(year),...
                        '_0',num2str(mon),'_01.mat')));
                    lastpartcur=char(strcat('air_',num2str(year),'_0',num2str(mon),'_01'));
                    curArr=eval(['curFile.' lastpartcur]);curArr{3}=curArr{3}-adj;
                    for i=1:narrsz(1)
                        for j=1:narrsz(2)
                            if gridptstouse(i,j)==1
                                %disp('line 1176');disp(i);disp(j);
                                %totalbygridpt(i,j)=totalbygridpt(i,j)+sum(curArr{3}(i,j,1,:),4); %sum across days of month, 1000 hPa
                                %Each row of alldatabygridpt is a day
                                %This allows the format of the first four columns to match that of
                                %citydata in FullClimateDataScript
                                alldatabygridpt(i,j,validdayc:validdayc+thismonlen-1,1)=mon; %month, for all days of month
                                alldatabygridpt(i,j,validdayc:validdayc+thismonlen-1,2)=1:thismonlen; %day
                                alldatabygridpt(i,j,validdayc:validdayc+thismonlen-1,3)=year; %year
                                alldatabygridpt(i,j,validdayc:validdayc+thismonlen-1,4)=curArr{3}(i,j,1,:);
                            end
                        end
                    end
                    validdayc=validdayc+thismonlen;%disp(validdayc);
                end
            end
        end
        for i=1:narrsz(1)
            for j=1:narrsz(2)
                if gridptstouse(i,j)==1
                    totalbygridpt(i,j)=totalbygridpt(i,j)/(validjunc*30+validjulc*31+validaugc*31);
                end
            end
        end
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/readnarrdatadaily_alldatabygridpt',...
            'alldatabygridpt','-v7.3');
    end
    
    %2. Calculate climatological JJA percentiles of T for each gridpt
    if calcclimoprctiles==1
        for i=1:narrsz(1)
            for j=1:narrsz(2)
                if gridptstouse(i,j)==1
                    for month=monthiwf:monthiwl
                        for potentialhwlength=1:maxhwlength
                            validTc=0;summedTvec=0;
                            for k=1:size(alldatabygridpt,3)
                                if alldatabygridpt(i,j,k,1)==month
                                    if k+potentialhwlength-1<=size(alldatabygridpt,3) %so we know it's not right at the end
                                        if alldatabygridpt(i,j,k+potentialhwlength-1,1)==month %segregate by month
                                            summedTvalue=sum(alldatabygridpt(i,j,k:k+potentialhwlength-1,4));
                                            validTc=validTc+1;
                                            summedTvec(validTc)=summedTvalue;
                                        end
                                    end
                                end
                            end
                            summedTvecsaveforlater{i,j,month,potentialhwlength}=summedTvec;
                            %'High' and 'low' standard percentiles of daily T for each station
                            %(typically 97.5 and 81)
                            highpct=0.975;lowpct=0.81;
                            summedTprctiles(i,j,month,potentialhwlength,1)=...
                                quantile(summedTvec,highpct)/(potentialhwlength);
                            summedTprctiles(i,j,month,potentialhwlength,2)=...
                                quantile(summedTvec,lowpct)/(potentialhwlength);
                        end
                    end
                end
            end
        end
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/readnarrdatadaily_summedTprctiles',...
            'summedTprctiles','-v7.3');
    end
    
    %3. Compile a listing of heat waves for each gridpt using the above-calculated threshold
    if defineheatwaves==1
        hwregister={};hwdays=0;hwstarts=0;
        for i=1:narrsz(1)
            for j=1:narrsz(2)
                if gridptstouse(i,j)==1
                    disp(i);disp(j);
                    consechotdayc=0;k=1;numhws=0;
                    while k<=size(alldatabygridpt,3)-maxhwlength
                        month=alldatabygridpt(i,j,k,1);
                        curdoy=DatetoDOY(alldatabygridpt(i,j,k,1),alldatabygridpt(i,j,k,2),alldatabygridpt(i,j,k,3));
                        if month>=monthiwf && month<=monthiwl %month range to search within
                            cursum=sum(alldatabygridpt(i,j,k:k+2,4))/3; %really an average
                            if cursum>=summedTprctiles(i,j,month,3,1) && curdoy+2<=lpd %meets the min reqts for a hw
                                hwlength=3;fprintf('Starting heat wave # %d\n',numhws+1);
                                hwregister{i,j}(numhws+1,1)=...
                                        DatetoDOY(alldatabygridpt(i,j,k,1),alldatabygridpt(i,j,k,2),alldatabygridpt(i,j,k,3));
                                %testing if we can take it to the next level
                                summedTtest=sum(alldatabygridpt(i,j,k:k+(hwlength+1)-1,4))/(hwlength+1);
                                potentialnewdaysum=sum(alldatabygridpt(i,j,k+hwlength,4));
                                hwgoeson=1;
                                while hwlength<=maxhwlength && hwgoeson==1 %now, see about extending the heat wave beyond 3 days
                                    if hwlength<maxhwlength;curmonth=alldatabygridpt(i,j,k+hwlength+1,1);end
                                    if hwlength==maxhwlength || curmonth==monthiwl+1 %%%heat wave needs to end%%%
                                        hwgoeson=0;numhws=numhws+1;
                                        hwregister{i,j}(numhws,2)=...
                                            DatetoDOY(alldatabygridpt(i,j,k+hwlength-1,1),alldatabygridpt(i,j,k+hwlength-1,2),...
                                            alldatabygridpt(i,j,k+hwlength-1,3));
                                        hwregister{i,j}(numhws,3)=alldatabygridpt(i,j,k+hwlength-1,3);
                                    elseif summedTtest>summedTprctiles(i,j,curmonth,hwlength+1,1) && ...
                                        potentialnewdaysum>summedTprctiles(i,j,curmonth,1,2) %%%heat wave is extended%%%
                                        %disp(potentialnewdaysum);disp('here i am');
                                        hwlength=hwlength+1;%disp(hwlength);
                                        summedTtest=sum(alldatabygridpt(i,j,k:k+(hwlength+1)-1,4))/(hwlength+1);
                                        potentialnewdaysum=sum(alldatabygridpt(i,j,k+hwlength,4));
                                    else %%%heat wave is no longer extended%%%
                                        hwgoeson=0;numhws=numhws+1;
                                        hwregister{i,j}(numhws,2)=...
                                            DatetoDOY(alldatabygridpt(i,j,k+hwlength-1,1),alldatabygridpt(i,j,k+hwlength-1,2),...
                                            alldatabygridpt(i,j,k+hwlength-1,3));
                                        hwregister{i,j}(numhws,3)=alldatabygridpt(i,j,k+hwlength-1,3);
                                    end
                                end
                                k=k+hwlength;
                            else
                                k=k+1;
                            end
                        else
                            k=k+1;
                        end
                    end
                end
            end
        end
    end
    
    %4. Build a complete list of all the heat-wave dates
    %(dates on which any of the gridpts were experiencing a heat wave)
    if buildcompletehwlist==1
        %First, combine the heat waves for each gridpt into one array
        hwregistersorted=zeros(1,3); %just to get things started
        for i=1:narrsz(1)
            for j=1:narrsz(2)
                if gridptstouse(i,j)==1
                    hwregistersorted=[hwregistersorted;hwregister{i,j}(:,:)];
                end
            end
        end
        hwregistersorted=hwregistersorted(2:size(hwregistersorted,1),:); %remove seed row of zeros

        %Next, sort this array so each year can be looked at in turn
        %(at this point the dates are still out of order)
        hwregistersorted=sortrows(hwregistersorted,3);
        numrows=size(hwregistersorted,1);

        %Loop through all possible days and see which are included in this
        %giant array, making a new array that's completely chronological
        newrow=1;allhwdaysarray=0;
        for year=hwregistersorted(1,3):hwregistersorted(numrows,3)
            for day=fpd:lpd
                for row=1:numrows
                    if day>=hwregistersorted(row,1) && day<=hwregistersorted(row,2)...
                            && year==hwregistersorted(row,3)
                        allhwdaysarray(newrow,1)=day;
                        allhwdaysarray(newrow,2)=year;
                        %disp(day);disp(year);
                        newrow=newrow+1;
                    end
                end
            end
        end
        
        %Remove duplicate rows so each date appears only once, and in
        %chronological order
        allhwdaysarray=unique(allhwdaysarray,'rows');
        allhwdaysarray=sortrows(allhwdaysarray,2);
        
        %Make a matrix of 1's and 0's indicating whether a gridpt did or did not
        %experience a heat wave on a given date
        %Gridpt #54 (127,257) is closest to NYC
        allgridptshwmatrix=zeros(size(allhwdaysarray,1),1);
        allgridptshwmatrix(:,1)=allhwdaysarray(:,1); %rows are hw days, columns 3-end are gridpts
        allgridptshwmatrix(:,2)=allhwdaysarray(:,2);
        gridptc=0;gridptlistxy=0;
        for i=1:narrsz(1)
            for j=1:narrsz(2)
                if gridptstouse(i,j)==1
                    rowofthisgridptshwregister=1;gridptc=gridptc+1;
                    gridptlistxy(gridptc,1)=i;gridptlistxy(gridptc,2)=j;
                    fprintf('Building heat-wave matrix for gridpoint #%d\n',gridptc);
                    for k=1:size(allhwdaysarray,1)
                        if rowofthisgridptshwregister<=size(hwregister{i,j},1)
                            curday=allhwdaysarray(k,1);curyear=allhwdaysarray(k,2);
                            if curday>=hwregister{i,j}(rowofthisgridptshwregister,1)...
                                    && curday<=hwregister{i,j}(rowofthisgridptshwregister,2)...
                                    && curyear==hwregister{i,j}(rowofthisgridptshwregister,3)
                                allgridptshwmatrix(k,gridptc+2)=1;
                                if curday==hwregister{i,j}(rowofthisgridptshwregister,2) %last day of a hw
                                    rowofthisgridptshwregister=rowofthisgridptshwregister+1;
                                    %disp('Last day of a hw');disp(curday);disp(curyear);disp(i);
                                end
                            else
                                allgridptshwmatrix(k,gridptc+2)=0;
                            end
                        end
                    end
                end
            end
        end
        %Plot to get a sense of the variability & overlap or lack thereof
        figure(figc);clf;figc=figc+1;
        imagescnan(allgridptshwmatrix(:,3:gridptc+2));colorbar;
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/readnarrdatadaily_allgridptshwmatrix',...
            'allgridptshwmatrix','-v7.3');
    end
    
    %5. Compute EOFs of heat waves
    if computehweofs==1
        %Detrend columns (time series for each gridpt)
        aghmdetr=detrend(allgridptshwmatrix(:,3:gridptc+2));
        
        %Apply EOF analysis
        [eigenvalues,eofcalc,eccalc,error,norms]=EOF(aghmdetr); %eigenvalues;EOFs;expansion coeffs;error;norms (if normalizing)
        %Rotate EOFs using varimax formula
        [new_loadings,rotatmatrix]=varimax(eccalc);
        new_eofs=eofcalc*rotatmatrix; %columns of new_eofs are the true eofs we're looking for

        %Plot normalized eigenvalues
        eigenvaluesnorm=eigenvalues/sum(eigenvalues);
        figure(figc);clf;figc=figc+1;
        plot(eigenvaluesnorm);title('Eigenvalues'); %looks like 5 EOFs is a reasonable cutoff for physically-based analysis
                                %however they do only explain 28% of the variance
        figname=sprintf('eofhwanalynarrusa%seigs.fig',num2str(gridptc));
        fig=gcf;saveas(fig,sprintf('%s%s',figloc,figname));

        %Plot EOFs
        figure(figc);clf;figc=figc+1;
        imagescnan(new_eofs);colorbar;title('Rotated EOFs');
    end
    
    %6. Perform an EOF analysis on the heat waves to see the patterns of spatial variability
    %Need only look at the first 5 as noted above
    %The range of loadings contained within these is approximately -0.5 to 0.5 -- find using e.g. max(max(new_eofs(:,1:5)))
    %The meaning of positive vs negative loadings will only become clear once physical mechanisms/processes are elucidated
    if eofanalyzehws==1
        %Plot EOFs as symbols for each gridpt
        colorstochoosefrom=flipud(varycolor(20)); %different colors for loadings of 0.45-0.50; 0.40-0.45; etc.
        for thiseof=1:5
            plotBlankMap(figc,'usa');figc=figc+1;hold on;
            for gridpt=1:size(gridptlistlatlon,1)
                thisloading=new_eofs(gridpt,thiseof);
                forcolor=20*round2(thisloading,0.05,'ceil')+10;
                gridptcolor=colorstochoosefrom(single(forcolor),:);
                h=geoshow(gridptlistlatlon(gridpt,1),gridptlistlatlon(gridpt,2),'DisplayType','Point','Marker','s',...
                    'MarkerFaceColor',gridptcolor,'MarkerEdgeColor',gridptcolor,'MarkerSize',8);
            end
            phrpart1=sprintf('EOF %0.0f of Summer Heat Waves at NARR Gridpts, 1979-2014',thiseof);
            phrpart2=sprintf('Percent Variance Explained = %0.1f',100*eigenvaluesnorm(thiseof));
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            colormap(colorstochoosefrom);
            caxis([-0.5,0.5]);colorbar;
            figname=sprintf('eofhwanalynarrusa%seof%s.fig',num2str(gridptc),num2str(thiseof));
            fig=gcf;saveas(fig,sprintf('%s%s',figloc,figname));
        end
    end
    
    %7. Plot factors for the previous EOFs, temporally smoothed with a nearest-neighbor approach
    if plottrendsinpcs==1
        knn=400;
        reducsize=size(eccalc,1)-knn;
        for thiseof=1:5
            for i=knn/2:size(allhwdaysarray,1)-knn/2
                yearts(i-knn/2+1)=mean(allhwdaysarray(i-knn/2+1:i+knn/2,2));
                ects(i-knn/2+1)=mean(eccalc(i-knn/2+1:i+knn/2,thiseof));
            end
            if size(ects,1)==1;ects=ects';end
            pcts(:,1)=yearts';
            pcts(:,2)=ects(:,1)/std(ects(:,1));
            figure(figc);clf;figc=figc+1;
            plot(pcts(1:reducsize,1),pcts(1:reducsize,2));
            title(sprintf('Time Series of EOF %0.0f',thiseof),...
                'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('eofhwanalynarrusa%sgridptspc%strends.fig',num2str(gridptc),num2str(thiseof));
        fig=gcf;saveas(fig,sprintf('%s%s',figloc,figname));
        end
    end
end

        
        