%Reads in and analyzes NCEP data
%Can only do one set of clusters at a time -- either the original
%bottom-up ones, or the temporal-evolution, seasonality, or diurnality groupings
%If changing scope of analysis to include or exclude May & Sep, need to
%rerun makeheatwaverankingnew and clusterheatwaves loops in analyzenycdata

    
%MODIFY SO THAT TOTAL HW AVERAGE IS COMPUTED IN DIURNALITY INSTEAD OF A
%SEPARATE SUPERFLUOUS LOOP CALLED ALLHWDAYS
%JUST NEED TO RUN DIURNALITY OVER ALL HOURS INSTEAD OF <8 HOURSTODO, AND
%SAVE -- THEN CHANGE FIG TITLES ACCORDINGLY

%This script was copied from readnarrdata so any references to hours are spurious


%Load partial or complete workspaces
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/workspace_readnycdata');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/workspace_analyzenycdatahighpct925su3');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjat');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjawbt');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjagh500');ncepavgjjagh500=ncepavgjjagh;
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjauwnd1000');ncepavgjjauwnd1000=ncepavgjjauwnd;
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjavwnd1000');ncepavgjjavwnd1000=ncepavgjjavwnd;
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays');%contains output from all flexiblecluster choices
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepindivdayarrays');%ditto
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclustersallhwdays');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclusterstempevol');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclustersseasonality');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclustersdiurnality');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclustersseasonalitydiurnality');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclustersmoistness');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/organizencepheatwavessaufseasonality');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/calcarealextentfinalresultswbt1000');

%Each matrix of ncep data is comprised of 8x-daily values for a month -- have May-Sep 1979-2014
%Dim 1 is lat; Dim 2 is lon; Dim 3 is pressure (1000, 850, 500, 300, 200); Dim 4 is day of month
preslevels=[1000;850;500;300;200]; %levels that were read and saved

%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\
%0. Runtime options

%Script-wide settings
allhwdays=0;                        %whether interested in all heat-wave days (the same as diurnality except total avgs are computed, not just for each hour)
tempevol=0;                         %whether interested in temporal evolution (i.e. comparing 3 days prior, first day, & last day)
                                        %in this case, loops through firstday=0:2 in computeflexibleclusters
seasonality=0;                      %whether interested in seasonality (i.e. comparing (May-)Jun, Jul, & Aug(-Sep))
diurnality=0;                       %whether interested in diurnal evolution (i.e. comparing 11 am, 2 pm, 5 pm, and 8 pm)
seasonalitydiurnality=0;            %whether interested in combined seasonality-diurnality criteria (e.g. 11 am in Jun)
                                        %have to plot absolute values since the necessary averages haven't been calculated
moistness=0;                        %whether interested in moistness (i.e. comparing very moist & not-so-moist heat waves, det. by the median WBT prctile)                                      
    if tempevol==1;firstday=0;else firstday=99;end %make sure all days are included for everything except tempevol (which goes through them one by one)
    
varsdes=[1;2;3;4;5];                        %variables to compute and prepare for plotting
                                        %1 for T, 2 for WBT, 3 for GPH, 4 & 5 for u & v wind
    viwf=3;viwl=3;                          %the range of variables to analyze on this run
                                            %numbers refer to the **elements of varsdes**, not necessarily to the absolute variable numbers
seasiwf=1;seasiwl=3;                %for seasonality-related runs, seasons to analyze ((May-)Jun = 1, Jul = 2, Aug(-Sep) = 3)
hourstodo=[1;2;3;4;5;6;7;8];                    %for diurnality-related runs, hours to analyze (8pm = 1, 11pm = 2, etc.)
                                        %if this is changed, be sure to change clustremark{x} below appropriately to eliminate the unincluded hours
vartorankby=1;                      %1 for T, 2 for WBT
compositehotdays=0;                 %whether to analyze hot days (defined by Tmax/WBTmax)
    numd=36;                            %x hottest days to analyze (36 is an avg of once per year when restricting to ncep data)
compositehwdays=1;                  %(mutually exclusive) whether to analyze heat waves (defined by integrated hourly T/WBT values)
redohotdaysfirstc=0;                %whether to reset the count of number of days belonging to each cluster
                                        %this means having to rerun script for both first and last days
redohotdayslastc=0;                 %change in accordance with above
%redohotdaysbothc=0;                %ditto for combined counts
presleveliw=[1;1;3;1;1];            %pressure levels of interest for variables, at least on this run, with indices referring to preslevels
yeariwf=1948;yeariwl=2014;          %years to compute over on this run, incl. in defining plotdays
                                        %-- if this is changed, computebasicstats, makeheatwaverankingnew, and calchwseverityscores in analyzenycdata must be run
monthiwf=6;monthiwl=8;              %months to compute over on this run


%Settings for individual loops (i.e. which to run, and how)
needtoconvert=0;                    %whether to convert from .nc to .mat; target variable is specified within loop (1 min 15 sec/3-hourly data file)
computeavgfields=0;                 %whether to (re)compute average variable fields (~1 hour/variable)   
plotseasonalclimoncepdata=0;        %whether to plot some basic seasonal climo (3 min/variable)
    varsseasclimo=[3];                  %the variables to plot here
                                        %uses the pressure levels in presleveliw
organizencepheatwaves=1;            %default is 1
                                    %whether to re-read and assign to clusters NCEP data on heat-wave days (5 sec)
                                    %also assigns value to plotdays vector
                                    %(if changes in parameters are desired, analyzenycdata must be rerun -- it only takes a minute to do so)
                                    %only one of the below cluster choices & computeusebottomupclusters can be selected at a time
computeflexibleclusters=0;          %whether to compute & plot flexible top-down two/three-cluster anomaly composites 
                                        %for all clusters: about 10 heat-wave days/sec for each variable
                                        %(so ~6 hours for the full run of a cluster with all years and variables)
computeusebottomupclusters=0;       %whether to get data for days belonging to each bottom-up cluster & plot anomaly composites for them (8 min/variable)
                                        %as long as standard options are used (preslevel=3, compositehwdays=1), then
                                        %everything needed can come from saved workspace
                                        %this must be 0 if tempevol or seasonality options are selected
    k=7;                            %the number of clusters calculated in analyzenycdata; any number b/w 5 and 9 is supported                                  
savetotalsintoarrays=1;             %default=1 to help keep NARR data out of this
                                    %whether to save 'totals' computed in the prior two sections into the arrays needed in the following section (5 sec)
                                        %depending on flexiblecluster selection & what's been computed so far, possible clusters are
                                        %1-8+10, 101-103, 201-203, 301-304, 401-424 (3 seasons & 8 possible hourstodo), or 501-516
    if allhwdays==1
        clmin=10;clmax=10;
    elseif tempevol==1
        clmin=101;clmax=103; %101-last day; 102-first day; 103-3 days prior
    elseif seasonality==1
        clmin=201;clmax=203;
    elseif diurnality==1
        clmin=301;clmax=304;
    elseif seasonalitydiurnality==1
        clmin=401;clmax=424;
    elseif moistness==1
        clmin=501;clmax=516; %in the saved arrays, 549 and 599 represent average over all hours for the two categories (e.g. 549 is avg of 501-508)
    end
plotheatwavecomposites=0;           %whether to plot various NCEP heat-wave data (2 min)
    shownonoverlaycompositeplots=1; %whether to show individual composites of temp, shum, or geopotential (chosen by underlaynum)
    showoverlaycompositeplots=0;    %(mutually exclusive) whether to show composites of wind overlaid with another variable
    clustdes=549;                     %cluster to plot -- 0 (full unclustered data), anything from 1 to k (bottom-up clusters), 
                                      %10 (hours, for all heat-wave days),
                                      %101-103 (days, for temporal evolution), 201-203 (seasons, for seasonality),
                                      %301-304 (hours, for diurnality), 
                                      %401-424 (combined seasonality-diurnality, with 401 being hour #1 for May-Jun, 409 -> hour #1 for Jul, 417 -> hour #1 for Aug-Sep),
                                      %501-516, 549, 599 (moistness, with 501 (509) being hour #1 of very moist (less-moist) events and 549 & 599 being daily avgs)
                                      %cluster number must be consistent with tempevol/seasonality/etc choice on this run
    overlay=1;                      %whether to overlay something (wind and possibly something else as well)
        underlaynum=3;              %variable to underlay with shading (typically 2, for WBT)
        overlaynum=3;               %variable to overlay with lines or contours (4 implies 5 because wind components are inseparable)
        overlaynum2=4;              %second variable to overlay (0 or 4 (implying 5)); i.e. only wind can be 2nd overlay
        anomfromjjaavg=0;           %whether to plot heat-wave composites as anomalies from JJA avg fields
        clusteranomfromavg=0;       %additionally, whether to plot each cluster as an anomaly from the all-cluster avg
    mapregion='nnh';            %size of map region for plots made on this run (see Section I for sizes)
                                        %only operational for overlaynum of 1 to 3, and overlaynum2~=0
plotcompositeddifferences=0;        %whether to plot difference composites, e.g. of T between first and last days (1 min 30 sec)
showindiveventplots=0;              %whether to show maps of T, WBT, &c for each event w/in the 15 hottest reg days covered by ncep,
                                        %with station observations overlaid (1 min per plot)
showdaterankchart=0;                %whether to show chart comparing hot days ranked by T and WBT
maketriangleplots=0;                %whether to make triangular plots showing *relative* T or WBT at JFK, LGA, EWR at particular hours & in particular seasons
    v1=2;v2=2;                          %range of variables to plot (1-2)
makewindarrowplots=0;               %whether to make plots comparing the wind vectors at JFK, LGA, EWR at particular hours & in particular seasons
calcplotwindspeedcorrels=0;         %whether to compute and plot the correl of wind speed with temperature change (~advection) by station, hour, & season
calcarealextentforscatterplot=0;    %whether to compute & plot scatterplot of spatial extent of 500-hPa anomalies of a variable vs magnitude of NYC T for NYC heat waves
    arealvariab=2;                          %variable whose areal extent to assess
        presleveliw(arealvariab)=1;             %...assess it at this pressure level (selon preslevels)
        adj=0;scalarvar=1;                      %descriptors for this variable
    getvalueseverysingleday=0;              %whether to compile values (height, T, etc) for the entire 1979-2014 period (3 hr)
    remakexpctvaluebygridpt=0;              %whether to compute high percentiles at each gridpoint (6 hr)
        xpct=0.90;                              %percentile for computation
    getvalueseveryhwday=0;                  %whether to look through the list of heat-wave days and get values for every one (7 hr)
    finishoffcalculation=1;                 %whether to compute the last bit and display the resultant scatterplot (1 min)
calcnhwavenumbers=0;                %whether to calculate mean and distributions of wavenumbers associated with various kinds of heat waves in NYC (1 min)
    ghofinterest=5800;                      %geopot height of interest, i.e. the level to calculate anomalous waviness for
    regofinterest='North America';          %longitudinal domain of interest (NH or North America)
trendsin500heights=1;               %whether to compute 500hPa heights at gridpt closest to NYC for every JJA day since 1950 & make boxplot comparing decades (30 sec) 



%I. For Science
mapregionsize3='north-america';%larger region to plot over ('north-america', 'na-east','usa-exp', or 'usa')
mapregionsize2='us-ne';       %region to plot over for climatology plots only
mapregionsize1='nyc-area';    %local region to plot over ('nyc-area' or 'us-ne')
fpyear=1948;lpyear=2014;      %first & last possible years (i.e. bounds of data I have)
fpmonth=5;lpmonth=9;          %first & last possible months
deslat=40.78;deslon=-73.97; %default location (Central Park) to calculate closest ncep gridpoints for
%%%Times in the netCDF files are UTC, so these hours are EDT and begin the previous day%%%
hours={'8pm';'11pm';'2am';'5am';'8am';'11am';'2pm';'5pm'}; %the 'standard hours'
prefixes={'atlcity';'bridgeport';'islip';'jfk';'lga';'mcguireafb';'newark';'teterboro';'whiteplains'};
varlist={'air';'shum';'hgt';'uwnd';'vwnd'};
varlist2={'t';'wbt';'gh';'uwnd';'vwnd'};varlist3={'t';'wbt';'gp';'wnd';'wnd'};
varlist4={'Temp.';'WBT';'Geopotential Height';'Zonal Wind';'Meridional Wind'};
varlistnames={sprintf('%d-hPa Temp.',preslevels(presleveliw(1)));sprintf('%d-hPa Wet-Bulb Temp.',preslevels(presleveliw(2)));...
    sprintf('%d-hPa Geopot. Height',preslevels(presleveliw(3)));
    sprintf('%d-hPa Wind',preslevels(presleveliw(4)));sprintf('%d-hPa Wind',preslevels(presleveliw(5)))};
varargnames={'temperature';'wet-bulb temp';'height';'wind';'wind'};
%examples of vararginnew are in the preamble of plotModelData

%II. For Managing Files
curDir='/Volumes/MacFormatted4TBExternalDrive/NCEP_daily_data_mat';
savingDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
figloc=sprintf('%s/Plots/',savingDir); %where figures will be placed
missingymdailyair=[];missingymdailyshum=[];missingymdailyuwnd=[];missingymdailyvwnd=[];missingymdailyhgt=[];
lsmask=ncread('land.nc','land')';



%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?
%Start of script

if needtoconvert==1
    %Converts raw .nc files to .mat ones using handy function courtesy of Ethan
    %rawNcDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Raw_nc_files';
    rawNcDir='/Volumes/MacFormatted4TBExternalDrive/NCEP_daily_data_raw_activefiles';
    %outputDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
    outputDir='/Volumes/MacFormatted4TBExternalDrive/NCEP_daily_data_mat';
    varName='air';
    maxNum=1000; %maximum number of files to transcribe at once
    ncepNcToMat(rawNcDir,outputDir,varName,maxNum);
    varName='hgt';
    maxNum=1000; %maximum number of files to transcribe at once
    ncepNcToMat(rawNcDir,outputDir,varName,maxNum);
    varName='shum';
    maxNum=2000; %maximum number of files to transcribe at once
    ncepNcToMat(rawNcDir,outputDir,varName,maxNum);
    varName='uwnd';
    maxNum=2000; %maximum number of files to transcribe at once
    ncepNcToMat(rawNcDir,outputDir,varName,maxNum); 
    varName='vwnd';
    maxNum=2000; %maximum number of files to transcribe at once
    ncepNcToMat(rawNcDir,outputDir,varName,maxNum); 
end

    
%Stuff that always needs to be done
a=size(prefixes);numstns=a(1);
exist figc;if ans==0;figc=1;end
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
mons={'jan';'feb';'mar';'apr';'may';'jun';'jul';'aug';'sep';'oct';'nov';'dec'};
prespr={'';'';sprintf('%d-mb ',preslevels(presleveliw(3)));'';''};
overlayvar=varargnames{overlaynum};underlayvar=varargnames{underlaynum};
if overlaynum2~=0;overlayvar2=varargnames{overlaynum2};end
temp=load('-mat','hgt_1979_01_500_ncep');hgt_1979_01_500_ncep=temp(1).hgt_1979_01_500;
lats=double(hgt_1979_01_500_ncep{1});lons=double(hgt_1979_01_500_ncep{2});
ncepsz=[144;73]; %size of these lat & lon arrays of NCEP data
%Save flexclustchoice for ease of doing various things on later runs
if allhwdays==1;fcc=1;elseif tempevol==1;fcc=2;elseif seasonality==1;fcc=3;elseif diurnality==1;fcc=4;...
        elseif seasonalitydiurnality==1;fcc=5;elseif moistness==1;fcc=6;
end
fccnames={'allhwdays';'tempevol';'seasonality';'diurnality';'seasonalitydiurnality';'moistness'};
fccnumcategs=[1;3;3;8;24;2];
fcccategnames{2}={'3 Days Prior';'First Days';'Last Days'};
fcccategnames{3}={'Jun';'Jul';'Aug'};
fcccategnames{6}={'Very Moist';'Less Moist'};
%Set up arrays with first-days data
exist totalfirstcl1;
if ans==0 && (firstday==1 || firstday==99)
    for clust=1:6
        eval(['totalfirstcl' num2str(clust) '=zeros(ncepsz(1),ncepsz(2));']);
        eval(['totalwbtfirstcl' num2str(clust) '=zeros(ncepsz(1),ncepsz(2));']);
        needtocalcfirstday=1;
    end
elseif ans~=0
    if firstday==1 && (max(max(totalfirstcl1))==0 || isnan(max(max(totalfirstcl1))))
        needtocalcfirstday=1;disp('Recalculating first day');
    else
        needtocalcfirstday=0;disp('NOT recalculating first day');
    end
end
%Set up arrays with last-days data
exist totallastcl1;
if ans==0 && (firstday==0 || firstday==99)
    for clust=1:6
        eval(['totallastcl' num2str(clust) '=zeros(ncepsz(1),ncepsz(2));']);
        eval(['totalwbtlastcl' num2str(clust) '=zeros(ncepsz(1),ncepsz(2));']);
        needtocalclastday=1;
    end
elseif ans~=0
    if firstday==0 && (max(max(totallastcl1))==0 || isnan(max(max(totallastcl1))))
        needtocalclastday=1;disp('Recalculating last day');
    else
        needtocalclastday=0;disp('NOT recalculating last day');
    end
end
%Use only data corresponding to the selected cluster option
if allhwdays==1
    if firstday==99;fdo=0;end
elseif tempevol==1
    fdo=101; %firstdayoffset
    if firstday==99;fdo=100;end
elseif seasonality==1
    fdo=201;
    if firstday==99;fdo=200;end
elseif diurnality==1
    fdo=301;
    if firstday==99;fdo=300;end
elseif seasonalitydiurnality==1
    fdo=401;
    if firstday==99;fdo=400;end
elseif moistness==1
    fdo=501;
    if firstday==99;fdo=500;end
elseif computeusebottomupclusters==1
    fdo=0;
    if firstday==99;fdo=0;end
end
%Labels, titles, etc. based on runtime options
rankby={'byT';'byWBT'};
labels={'Daily-Max Air Temp.';'Daily-Max Wet-Bulb Temp.'};
labelssh={'Temp.';'WBT'};
categlabel=labelssh{vartorankby};
firstlast={'lastday';'firstday';'alldays';'3daysp'};
if firstday==99;flarg=3;elseif clustdes-fdo==2;flarg=4;else flarg=clustdes-fdo+1;end
timespanremark={'Daily';''};
if tempevol==1 || seasonality==1;timespanlb=1;else timespanlb=2;end
clustlb=sprintf('cl%d',clustdes);
clustremark={'';', Cluster 1';', Cluster 2';', Cluster 3';', Cluster 4';...
    ', Cluster 5';', Cluster 6'};
clustremark{101}=', Last Days';clustremark{102}=', First Days';clustremark{103}=', 3 Days Prior';
if monthiwf==5;clustremark{201}=', May-Jun';elseif monthiwf==6;clustremark{201}=', Jun';end
clustremark{202}=', Jul';
if monthiwl==9;clustremark{203}=', Aug-Sep';elseif monthiwl==8;clustremark{203}=', Aug';end
clustremark{301}=', 8PM EDT';clustremark{302}=', 11PM EDT';clustremark{303}=', 2AM EDT';clustremark{304}=', 5AM EDT';
clustremark{305}=', 8AM EDT';clustremark{306}=', 11AM EDT';clustremark{307}=', 2PM EDT';clustremark{308}=', 5PM EDT';
%clustremark{301}=', 8PM EDT';clustremark{302}=', 11AM EDT';clustremark{303}=', 2PM EDT';clustremark{304}=', 5PM EDT';
for i=401:424 %401-408 is season 1 hours 1-8
    season=round2(i/8,1,'ceil')+150;hour=rem(i,8)+300;if hour==0;hour=8+300;end
    clustremark{i}=strcat(clustremark{season},clustremark{hour});
end
clustremark{551}=', Very Moist Events';clustremark{552}=', Less-Moist Events';
for i=501:516 %501-508 is moisture category 1 (very moist events) hours 1-8
    moistcateg=round2(i/8+0.5,1,'ceil')+487;hour=rem(i+4,8)+300;if hour==0;hour=8+300;end
    clustremark{i}=strcat(clustremark{moistcateg},clustremark{hour});
end
clustremark{549}=', Very Moist Events, Daily Average';clustremark{599}=', Less-Moist Events, Daily Average';
%For plotting: reconvert clustdes into an understandable, referenceable single-digit integer (ursi)
if tempevol==1
    ursi=clustdes-100;
elseif seasonality==1
    ursi=clustdes-200;
elseif diurnality==1
    ursi=0;
elseif seasonalitydiurnality==1
    ursi=0;
elseif moistness==1
    if clustdes==549;ursi=1;else ursi=2;end
end
anomavg={'Avg';'Anom.'};anomavg2={'avg';'anom'};
clustanom={'';' Minus All-Cluster Avg'};
clanomlb=sprintf('clanom%d',clusteranomfromavg);
if compositehwdays==1
    %hwremark='Heat Waves';
    hwremark='Heat-Wave Days';
    if firstday==1
        dayremark='for the First Day of';
    elseif firstday==0
        dayremark='for the Last Day of';
    elseif firstday==99
        dayremark='for First & Last Days of';
        if moistness==1 %for this one only (so far), updated to include all days
            dayremark='for All Days of';
        end
    elseif firstday==2
        dayremark='for 3 Days Prior to'; 
    end
    if tempevol==1 || allhwdays==1
        dayremark='for'; %don't need to specify a day remark in the title in this case
    end
end
if overlay==1;contouropt=0;else contouropt=1;end
if anomfromjjaavg==1;cbsetting='regional10';else cbsetting='regional25';end


%Compute average ncep variable fields for [M]JJA[S] (so anomalies can be defined with respect to them)
%WBT formula is from Stull 2011, with T in C and RH in %
if computeavgfields==1 
    for variab=viwf:viwl
        total=zeros(277,349);totalprev=zeros(277,349);
        for hr=1:8;eval(['total' hours{hr} '=zeros(277,349);']);eval(['totalprev' hours{hr} '=zeros(277,349);']);end
        if strcmp(varlist(varsdes(variab)),'air');adj=273.15;else adj=0;end
        for mon=monthiwf:monthiwl
            validthismonc=0;
            ncepavgthismont=zeros(277,349);ncepavgthismonshum=zeros(277,349);
            ncepavgthismongh=zeros(277,349);ncepavgthismonuwnd=zeros(277,349);ncepavgthismonvwnd=zeros(277,349);
            thismonlen=eval(['m' num2str(mon+1) 's-m' num2str(mon) 's']);
            for year=yeariwf:yeariwl
                ymmissing=0;
                missingymdaily=eval(['missingymdaily' char(varlist{varsdes(variab)})]);
                for row=1:size(missingymdailyair,1)
                    if mon==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                end
                if ymmissing==1 %Do nothing, just skip the month
                else
                    validthismonc=validthismonc+1;
                    fprintf('Calculating averages for %d, %d\n',year,mon);
                    if mon<=9
                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                        '_0',num2str(mon),'_01.mat')));
                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(mon),'_01'));
                        %For shum, need to get T as well to convert to WBT
                        if varsdes(variab)==2 
                            prevFile=load(char(strcat(curDir,'/air/',...
                                num2str(year),'/air_',num2str(year),'_0',num2str(mon),'_01.mat')));
                            lastpartprev=char(strcat('air_',num2str(year),'_0',num2str(mon),'_01'));
                            prevArr=eval(['prevFile.' lastpartprev]);prevArr{3}=prevArr{3}-273.15;
                        end
                    else 
                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                        '_',num2str(mon),'_01.mat')));
                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(mon),'_01'));
                    end
                    curArr=eval(['curFile.' lastpartcur]);curArr{3}=curArr{3}-adj;
                    %Choose 1-1000hPa,2-850hPa,3-500hPa,4-300hPa,5-200hPa selon preslevels
                    for hr=1:8
                        curtotaltoworkon=eval(['total' hours{hr}]);
                        curtotaltoworkon=curtotaltoworkon+sum(curArr{3}(:,:,presleveliw(varsdes(variab)),hr:8:size(curArr{3},4)),4);
                        eval(['total' hours{hr} '=curtotaltoworkon;']);
                        if varsdes(variab)==2 %also have to include T in this circumstance
                            prevtotaltoworkon=eval(['totalprev' hours{hr}]);
                            prevtotaltoworkon=prevtotaltoworkon+sum(prevArr{3}(:,:,presleveliw(varsdes(variab)),hr:8:size(prevArr{3},4)),4);
                            eval(['totalprev' hours{hr} '=prevtotaltoworkon;']);
                        end
                    end
                end
            end
            for hr=1:8
                curtotaltoworkon=eval(['total' hours{hr}]);
                %disp(hr);disp(curtotaltoworkon(130,258));
                curtotaltoworkon=curtotaltoworkon./(validthismonc*thismonlen);
                eval(['total' hours{hr} '=curtotaltoworkon;']);
                if varsdes(variab)==2 %also T if working on shum/WBT
                    prevtotaltoworkon=eval(['totalprev' hours{hr}]);
                    prevtotaltoworkon=prevtotaltoworkon./(validthismonc*thismonlen);
                    eval(['totalprev' hours{hr} '=prevtotaltoworkon;']);
                end
            end
            %Tally up the averages, both for each standard hour and for all hours combined
            if varsdes(variab)==1
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['ncepavgthismont' hours{hr} '=curtotal;']);
                    eval(['ncepavg' mons{mon} 't' hours{hr} '=ncepavgthismont' hours{hr} ';']);
                    ncepavgthismont=ncepavgthismont+curtotal;
                end
                ncepavgthismont=ncepavgthismont/8;
                eval(['ncepavg' mons{mon} 't=ncepavgthismont;']);
            elseif varsdes(variab)==2
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['ncepavgthismonshum' hours{hr} '=curtotal;']);
                    eval(['ncepavg' mons{mon} 'shum' hours{hr} '=ncepavgthismonshum' hours{hr} ';']);
                    ncepavgthismonshum=ncepavgthismonshum+curtotal;
                    totalprev=eval(['totalprev' hours{hr}]);
                    eval(['ncepavgthismont' hours{hr} '=totalprev;']);
                    eval(['ncepavg' mons{mon} 't' hours{hr} '=ncepavgthismont' hours{hr} ';']);
                    ncepavgthismont=ncepavgthismont+totalprev;
                end
                ncepavgthismonshum=ncepavgthismonshum/8;
                ncepavgthismont=ncepavgthismont/8;
                eval(['ncepavg' mons{mon} 'shum=ncepavgthismonshum;']);
                eval(['ncepavg' mons{mon} 't=ncepavgthismont;']);
            elseif varsdes(variab)==3
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['ncepavgthismongh' hours{hr} '=curtotal;']);
                    eval(['ncepavg' mons{mon} 'gh' hours{hr} '=ncepavgthismongh' hours{hr} ';']);
                    ncepavgthismongh=ncepavgthismongh+curtotal; %daily avg
                end
                ncepavgthismongh=ncepavgthismongh/8; %daily avg
                %disp(ncepavgthismongh(130,258));
                eval(['ncepavg' mons{mon} 'gh=ncepavgthismongh;']);
            elseif varsdes(variab)==4
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['ncepavgthismonuwnd' hours{hr} '=curtotal;']);
                    eval(['ncepavg' mons{mon} 'uwnd' hours{hr} '=ncepavgthismonuwnd' hours{hr} ';']);
                    ncepavgthismonuwnd=ncepavgthismonuwnd+curtotal;
                end
                ncepavgthismonuwnd=ncepavgthismonuwnd/8;
                eval(['ncepavg' mons{mon} 'uwnd=ncepavgthismonuwnd;']);
            elseif varsdes(variab)==5
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['ncepavgthismonvwnd' hours{hr} '=curtotal;']);
                    eval(['ncepavg' mons{mon} 'vwnd' hours{hr} '=ncepavgthismonvwnd' hours{hr} ';']);
                    ncepavgthismonvwnd=ncepavgthismonvwnd+curtotal;
                end
                ncepavgthismonvwnd=ncepavgthismonvwnd/8;
                eval(['ncepavg' mons{mon} 'vwnd=ncepavgthismonvwnd;']);
            end
            
            if varsdes(variab)==2
                %Convert specific humidity to mixing ratio
                ncepavgthismonmr=ncepavgthismonshum./(1-ncepavgthismonshum);
                %Get saturation values from temperature
                ncepavgthismones=6.11*10.^(7.5*ncepavgthismont./(237.3+ncepavgthismont));
                %Convert saturation vp to saturation mr, assuming P=1000
                ncepavgthismonws=0.622*ncepavgthismones/1000;
                %RH=w/ws
                ncepavgthismonrh=100*ncepavgthismonmr./ncepavgthismonws;
                %Finally, use T and RH to compute WBT
                ncepavgthismonwbt=ncepavgthismont.*atan(0.151977.*(ncepavgthismonrh+8.313659).^0.5)+...
                    atan(ncepavgthismont+ncepavgthismonrh)-atan(ncepavgthismonrh-1.676331)+...
                    0.00391838.*(ncepavgthismonrh.^1.5).*atan(0.0231.*ncepavgthismonrh)-4.686035;

                %Now do these shum->WBT steps for each of the 8 standard hours
                for hr=1:8
                    tarr=eval(['ncepavgthismont' hours{hr}]);
                    shumarr=eval(['ncepavgthismonshum' hours{hr}]);
                    ncepavgthismonmrthishr=shumarr./(1-shumarr);
                    ncepavgthismonesthishr=6.11*10.^(7.5*tarr./(237.3+tarr));
                    ncepavgthismonwsthishr=0.622*ncepavgthismonesthishr/1000;
                    ncepavgthismonrhthishr=100*ncepavgthismonmrthishr./ncepavgthismonwsthishr;
                    ncepavgthismonwbtthishr=tarr.*atan(0.151977.*(ncepavgthismonrhthishr+8.313659).^0.5)+...
                        atan(tarr+ncepavgthismonrhthishr)-atan(ncepavgthismonrhthishr-1.676331)+...
                        0.00391838.*(ncepavgthismonrhthishr.^1.5).*atan(0.0231.*ncepavgthismonrhthishr)-4.686035;
                    eval(['ncepavg' mons{mon} 'wbt' hours{hr} '=ncepavgthismonwbtthishr;']);
                end
            end
        end
        %Reconstruct JJA averages from monthly ones
        if monthiwf<=6 && monthiwl>=8
            if varsdes(variab)~=2
                eval(['ncepavgjja' varlist2{varsdes(variab)} '=(ncepavgjun' varlist2{varsdes(variab)} '+ncepavgjul'...
                    varlist2{varsdes(variab)} '+ncepavgaug' varlist2{varsdes(variab)} ')/3;']);
                for hr=1:8;eval(['ncepavgjja' varlist2{varsdes(variab)} hours{hr} '=(ncepavgjun' varlist2{varsdes(variab)} hours{hr} '+ncepavgjul'...
                    varlist2{varsdes(variab)} hours{hr} '+ncepavgaug' varlist2{varsdes(variab)} hours{hr} ')/3;']);end
            else
                sumhere=0;
                for hr=1:8;sumhere=sumhere+eval(['ncepavgjunwbt' hours{hr}]);end
                for hr=1:8;sumhere=sumhere+eval(['ncepavgjulwbt' hours{hr}]);end
                for hr=1:8;sumhere=sumhere+eval(['ncepavgaugwbt' hours{hr}]);end
                ncepavgjjawbt=sumhere/24;
                for hr=1:8;eval(['ncepavgjjawbt' hours{hr} '=(ncepavgjunwbt' hours{hr} '+ncepavgjulwbt'...
                    hours{hr} '+ncepavgaugwbt' hours{hr} ')/3;']);end
            end
        end
        
        %Save JJA average that was just computed in appropriately named file
        if strcmp(varlist2{varsdes(variab)},'t')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjat.mat',...
                char(sprintf('ncepavgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'wbt')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjawbt.mat',...
                char(sprintf('ncepavgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'gh')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjagh.mat',...
                char(sprintf('ncepavgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'uwnd')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjauwnd.mat',...
                char(sprintf('ncepavgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'vwnd')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgjjavwnd.mat',...
                char(sprintf('ncepavgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('ncepavgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('ncepavgjja%s8pm',char(varlist2{varsdes(variab)}))));
        end
    end
end


%Plot some basic seasonal-climo results
if plotseasonalclimoncepdata==1
    disp('Plotting some basic seasonal-climo results');
    for variab=1:size(varsseasclimo,1)
        if strcmp(varlist(varsseasclimo(variab)),'air')
            vararginnew={'variable';'temperature';'contour';1;'mystep';1;'plotCountries';1;
                'caxismethod';'regional10';'overlaynow';0};
            scalarvar=1;
        elseif strcmp(varlist(varsseasclimo(variab)),'shum')
            vararginnew={'variable';'wet-bulb temp';'contour';1;'mystep';1;'plotCountries';1;
                'caxismethod';'regional10';'overlaynow';0};
            adj=0;scalarvar=1;
        elseif strcmp(varlist(varsseasclimo(variab)),'hgt')
            vararginnew={'variable';'height';'contour';1;'mystep';10;'plotCountries';1;
                'caxismethod';'regional10';'overlaynow';0};
            adj=0;scalarvar=1;
        elseif strcmp(varlist(varsseasclimo(variab)),'uwnd') || strcmp(varlist(varsseasclimo(variab)),'vwnd')
            adj=0;scalarvar=0;
        end
        
        matrix1=eval(['ncepavgjja' varlist2{varsseasclimo(variab)} num2str(preslevels(presleveliw(varsseasclimo(variab))))]);
        data1={lats;lons;matrix1};
        matrix2=eval(['ncepavgjja' varlist2{varsseasclimo(variab)} num2str(preslevels(presleveliw(varsseasclimo(variab)))) '5am']);
        data2={lats;lons;matrix2};
        matrix3=eval(['ncepavgjja' varlist2{varsseasclimo(variab)} num2str(preslevels(presleveliw(varsseasclimo(variab)))) '5pm']);
        data3={lats;lons;matrix3};
        if scalarvar==1
            plotModelData(data1,mapregionsize2,vararginnew,'NCEP');figc=figc+1;
            title(sprintf('Average Daily %s for JJA, %d hPa, %d-%d',char(varlistnames{varsseasclimo(variab)}),...
                preslevels(presleveliw(varsseasclimo(variab))),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            plotModelData(data2,mapregionsize2,vararginnew,'NCEP');figc=figc+1;
            title(sprintf('Average 5AM %s for JJA, %d hPa, %d-%d',char(varlistnames{varsseasclimo(variab)}),...
                preslevels(presleveliw(varsseasclimo(variab))),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            plotModelData(data3,mapregionsize2,vararginnew,'NCEP');figc=figc+1;
            title(sprintf('Average 5PM %s for JJA, %d hPa, %d-%d',char(varlistnames{varsseasclimo(variab)}),...
                preslevels(presleveliw(varsseasclimo(variab))),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
        
        if scalarvar==0
            if strcmp(varlist(varsseasclimo(variab)),'uwnd')
                uwndmatrix=matrix; %save uwnd data
            elseif strcmp(varlist(varsseasclimo(variab)),'vwnd')
                vwndmatrix=matrix;
                %Now I can plot because uwnd has already been read in
                data={lats;lons;uwndmatrix;vwndmatrix};
                vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;...
                    'caxismethod';cbsetting;'vectorData';data};
                plotModelData(data,mapregionsize2,vararginnew,'NCEP');
            end
        end  
    end
end
    

%Already have an ordered list of the hottest region-wide days (reghwbyXstarts)
%Also, choose subsets of data to analyze on this run according to the
%strictures of tempevol, seasonality, or diurnality

%Select number of hot days to include in this analysis by setting numd
%Temperature is a proxy for availability of the data at all
%Usually want less-restrictive definition which is why defaults are set to hp925
if organizencepheatwaves==1
    hoteventsarrs={};heahelper=0;
    %plotdays={};
    reghwbyTstarts=eval(['reghw' rankby{vartorankby} 'startshp925su3']);
    reghwstarts=reghwbyTstarts;
    if compositehotdays==1
        numtodo=numd;vecsize=10000;
    elseif compositehwdays==1
        numtodo=size(reghwstarts,1);
    end
    for categ=1:1 %1-heat waves ranked by T; 2-heat waves ranked by WBT
        rowtomake=1;rowtosearch=1;
        vecsize=size(eval(['reghw' rankby{categ} 'starts']),1);
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
            %Don't include in ranking any months whose NCEP data is missing
            for i=1:size(missingymdailyair,1)
                if thismon==missingymdailyair(i,1) && thisyear==missingymdailyair(i,2)
                    thismonmissing=1;
                end
            end
            
            if compositehwdays==1
                reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
                if reghwbystarts(rowtosearch,2)>=yeariwf && reghwbystarts(rowtosearch,2)<=yeariwl && thismonmissing==0
                    %All heat-wave days (in reghwbystarts) in the desired range are included in this part of plotdays,
                    %no matter what other choices may come
                    plotdays{categ,1,2}(rowtomake,1)=reghwbystarts(rowtosearch,1);
                    plotdays{categ,1,1}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1;
                    plotdays{categ,1,2}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                    plotdays{categ,1,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                    rowtomake=rowtomake+1;
                end
            end
            rowtosearch=rowtosearch+1;
        end
    end
    
    %Now that the main plotdays vector has been established, all the specialty ones can follow
    for categ=1:1
        rowtomake=1;rowtosearch=1;
        vecsize=size(eval(['reghw' rankby{categ} 'starts']),1);
        while rowtomake<=numtodo && rowtosearch<=vecsize
            thismonmissing=0;
            
            %Set up vectors to be able to use ALL heat-wave days (not just first and last)
            newplotdays={};hwcount=1;hwdayc=1;rowtomake=1;
            reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
            while hwcount<=size(plotdays{categ,1,1},1)
                lastdaythishw=plotdays{categ,1,1}(hwcount,1);
                firstdaythishw=plotdays{categ,1,2}(hwcount,1);
                newplotdays{categ,1,1}(rowtomake,1)=plotdays{categ,1,2}(hwcount,1)+hwdayc-1;
                newplotdays{categ,1,1}(rowtomake,2)=plotdays{categ,1,2}(hwcount,2);
                if plotdays{categ,1,2}(hwcount,1)+hwdayc-1==lastdaythishw %i.e. we've reached the last day of this heat wave
                    newplotdays{categ,1,1}(rowtomake,1)=plotdays{categ,1,2}(hwcount,1)+hwdayc-1;
                    newplotdays{categ,1,1}(rowtomake,2)=plotdays{categ,1,2}(hwcount,2);
                    hwcount=hwcount+1;hwdayc=1;
                else
                    hwdayc=hwdayc+1;
                end
                rowtomake=rowtomake+1;%disp(hwcount);disp(hwdayc);disp(rowtomake);
            end
            fullhwdaystoplot=newplotdays{1,1,1};
            
            if compositehwdays==1
                reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
                if reghwbystarts(rowtosearch,2)>=1979 && reghwbystarts(rowtosearch,2)<=2014 && thismonmissing==0             
                    if tempevol==1 || computeusebottomupclusters==1 || diurnality==1 %first-vs-last-days types of analysis
                        plotdays{categ,2,2}(rowtomake,1)=reghwbystarts(rowtosearch,1); %days of first days
                        plotdays{categ,2,1}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1; %last days
                        plotdays{categ,2,3}(rowtomake,1)=reghwbystarts(rowtosearch,1)-3; %3 days prior
                        plotdays{categ,2,2}(rowtomake,2)=reghwbystarts(rowtosearch,2); %years of first days
                        plotdays{categ,2,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        plotdays{categ,2,3}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                    elseif seasonality==1 || seasonalitydiurnality==1 %choose dates based on seasons, selecting hours later
                        if thismon==5 || thismon==6
                            plotdays{categ,3,1,1}(rowtomake,1)=reghwbystarts(rowtosearch,1); %first days of (May-)Jun heat waves
                            plotdays{categ,3,1,1}(rowtomake,2)=reghwbystarts(rowtosearch,2); %years of (May-)Jun heat-wave first days
                            plotdays{categ,3,1,2}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1; %last days of (May-)Jun heat waves
                            plotdays{categ,3,1,2}(rowtomake,2)=reghwbystarts(rowtosearch,2); %same years
                        elseif thismon==7
                            plotdays{categ,3,2,1}(rowtomake,1)=reghwbystarts(rowtosearch,1); %first days of Jul heat waves
                            plotdays{categ,3,2,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                            plotdays{categ,3,2,2}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1; %last days of Jul heat waves
                            plotdays{categ,3,2,2}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        elseif thismon==8 || thismon==9
                            plotdays{categ,3,3,1}(rowtomake,1)=reghwbystarts(rowtosearch,1); %first days of Aug(-Sep) heat waves
                            plotdays{categ,3,3,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                            plotdays{categ,3,3,2}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1; %last days of Aug(-Sep) heat waves
                            plotdays{categ,3,3,2}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        end
                    end
                    rowtomake=rowtomake+1;
                end
                
                %Alternative approach that doesn't rely on first & last
                %days, but is inclusive of all days & more elegant to boot
                %Transition the legacy plotdays to this version as appropriate
                if tempevol==1
                    for j=1:size(reghwstarts,1)
                        if reghwstarts(j,2)<=yeariwl
                            threedayspriorthishw(1)=reghwstarts(j,1)-3;threedayspriorthishw(2)=reghwstarts(j,2);
                            firstdaythishw(1)=reghwstarts(j,1);firstdaythishw(2)=reghwstarts(j,2);
                            lastdaythishw(1)=reghwstarts(j,1)+reghwstarts(j,3)-1;lastdaythishw(2)=reghwstarts(j,2);
                            plotdays{1,2,1}(j,1)=lastdaythishw(1);plotdays{1,2,1}(j,2)=lastdaythishw(2);
                            plotdays{1,2,2}(j,1)=firstdaythishw(1);plotdays{1,2,2}(j,2)=firstdaythishw(2);
                            plotdays{1,2,3}(j,1)=threedayspriorthishw(1);plotdays{1,2,3}(j,2)=threedayspriorthishw(2);
                        end
                    end
                end
                newrowtomake1=1;newrowtomake2=1;newrowtomake3=1;curhw=1;
                for j=1:size(fullhwdaystoplot,1)
                    if seasonality==1
                        if DOYtoMonth(fullhwdaystoplot(j,1),fullhwdaystoplot(j,2))==6
                            plotdays{categ,3,1}(newrowtomake1,1)=fullhwdaystoplot(j,1);
                            plotdays{categ,3,1}(newrowtomake1,2)=fullhwdaystoplot(j,2);
                            newrowtomake1=newrowtomake1+1;
                        elseif DOYtoMonth(fullhwdaystoplot(j,1),fullhwdaystoplot(j,2))==7
                            plotdays{categ,3,2}(newrowtomake2,1)=fullhwdaystoplot(j,1);
                            plotdays{categ,3,2}(newrowtomake2,2)=fullhwdaystoplot(j,2);
                            newrowtomake2=newrowtomake2+1;
                        elseif DOYtoMonth(fullhwdaystoplot(j,1),fullhwdaystoplot(j,2))==8
                            plotdays{categ,3,3}(newrowtomake3,1)=fullhwdaystoplot(j,1);
                            plotdays{categ,3,3}(newrowtomake3,2)=fullhwdaystoplot(j,2);
                            newrowtomake3=newrowtomake3+1;
                        end
                    elseif moistness==1
                        medianWBT=quantile(scorescomptotalhwhp925su3(:,2),0.5); %median WBT percentile among heat waves
                        if j>1
                            if fullhwdaystoplot(j,1)~=fullhwdaystoplot(j-1,1)+1 || ...
                                    fullhwdaystoplot(j,2)~=fullhwdaystoplot(j-1,2) %on to a new heat wave
                                curhw=curhw+1;
                            end
                        end
                        %disp('line 719');disp(j);disp(curhw);
                        if scorescomptotalhwhp925su3(curhw,2)>=medianWBT %very moist heat wave
                            plotdays{categ,6,1}(newrowtomake1,1)=fullhwdaystoplot(j,1);
                            plotdays{categ,6,1}(newrowtomake1,2)=fullhwdaystoplot(j,2);
                            newrowtomake1=newrowtomake1+1;
                        else %not-so-moist heat wave
                            plotdays{categ,6,2}(newrowtomake2,1)=fullhwdaystoplot(j,1);
                            plotdays{categ,6,2}(newrowtomake2,2)=fullhwdaystoplot(j,2);
                            newrowtomake2=newrowtomake2+1;
                        end
                    end
                end
            end
            rowtosearch=rowtosearch+1;
        end
        %Eliminate zero rows
        if seasonality==1 || seasonalitydiurnality==1;for i=1:3;plotdays{1,3,i}=plotdays{1,3,i}(any(plotdays{1,3,i},2),:);end;end
        %Sort plotdays chronologically to get a nice clean list of what we're going to be looking for
        if computeusebottomupclusters==1;for i=1:2;plotdays{categ,1,i}=sortrows(plotdays{categ,1,i},[2 1]);end;end
        if computeusebottomupclusters==1;plotdays{categ,1}=sortrows(plotdays{categ,1},[2 1]);end
        if allhwdays==1;plotdays{categ,5}=fullhwdaystoplot;end
        if tempevol==1;for i=1:3;plotdays{categ,2,i}=sortrows(plotdays{categ,2,i},[2 1]);end;end %i is first & last days
        if seasonality==1 || seasonalitydiurnality==1;for i=1:3;plotdays{categ,3,i}=sortrows(plotdays{categ,3,i},[2 1]);end;end
             %i is season, j is first & last days
        if diurnality==1;for i=1:2;plotdays{categ,4,i}=plotdays{categ,2,i};end;end %i is first & last days

        %Bottom-up clusters' data is identical to that calculated for tempevol
        if computeusebottomupclusters==1;if tempevol==1;for i=1:3;plotdays{categ,1,i}=plotdays{categ,2,i};end;end;end
        
        %All heat-wave days (just made by recombining lists of days from very moist and
        %not-so-moist heat waves)
        plotdays{categ,7}=fullhwdaystoplot;
        %plotdays{categ,7}=[plotdays{categ,7};plotdays{categ,6,2}];
        %[trash,idx]=sortrows(plotdays{categ,7},[2 1]);
        %plotdays{categ,7}=plotdays{categ,7}(idx,:);
    end
end

%Flexible top-down 'cluster' composites (just groupings, not actually k-means-defined)
%Uses plotdays as computed in the previous loop
if computeflexibleclusters==1
    if allhwdays==1
        %avgsallhwdays={};
        for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
        for variab=viwf:viwl
            prevArr={};
            if strcmp(varlist{varsdes(variab)},'air')
                vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
                adj=273.15;scalarvar=1;
            elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
                adj=0;scalarvar=1;
            elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;...
                        'caxismethod';cbsetting;'vectorData';data};
                adj=0;scalarvar=0;
            end
            total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
            for hr=1:8;eval(['total' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
            hotdaysc=0;hoteventsc=0;
            for year=yeariwf:yeariwl
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
                        %If it does, get the data for its hours -- compute daily average as the
                        %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                        %because of the EDT-UTC offset
                        for row=1:size(plotdays{vartorankby,5},1)
                            if plotdays{vartorankby,5}(row,2)==year && plotdays{vartorankby,5}(row,1)>=curmonstart...
                                    && plotdays{vartorankby,5}(row,1)<curmonstart+curmonlen
                                dayinmonth=plotdays{vartorankby,5}(row,1)-curmonstart+1;disp(dayinmonth);
                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                    lastdayofmonth=0;
                                else
                                    lastdayofmonth=1;
                                end
                                %Just load in the files needed
                                if month<=9
                                    curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                        varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01.mat')));
                                    lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01'));
                                    if lastdayofmonth==1
                                        nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                            varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                        lastpartnextmon=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_01'));
                                    end
                                    if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                        prevFile=load(char(strcat(curDir,'/','air','/',...
                                        num2str(year),'/','air','_',num2str(year),...
                                        '_0',num2str(month),'_01.mat')));
                                        lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_01'));
                                        prevArr=eval(['prevFile.' lastpartprev]);
                                        if lastdayofmonth==1
                                            nextmonprevFile=load(char(strcat(curDir,'/','air','/',num2str(year),'/',...
                                                'air','_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                            lastpartprevnextmon=char(strcat('air','_',num2str(year),'_0',num2str(month+1),'_01'));
                                            prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                        end
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
                                if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end

                                for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                    eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                    else
                                        eval(['arrDOI' hours{hr} 'nextday=nextmonncep{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                    end
                                end
                                %Compute WBT from T and RH (see average-computation loop above for details)
                                if strcmp(varlist{varsdes(variab)},'shum')
                                    for hr=1:8
                                        arrDOIthisday=eval(['arrDOI' hours{hr} ';']); %shum
                                        arrDOIprevthisday=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                        mrArr=arrDOIthisday./(1-arrDOIthisday);
                                        esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                        wsArr=0.622*esArr/1000;
                                        rhArr=100*mrArr./wsArr;
                                        eval(['arrDOIwbt=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                            'atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+'...
                                            '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                                        %Save data
                                        eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;'])
                                    end
                                end
                                %Save data
                                for hr=1:8
                                    eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);
                                end
                                %Compute daily average as 2am-11pm, with 2am listed as the following day because of UTC
                                for hr=2:8;eval(['total=total+arrDOI' hours{hr} ';']);end
                                total=total+arrDOI2amnextday;
                                hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                            end
                        end
                    end
                end
            end
            if strcmp(varlist{varsdes(variab)},'shum')
                for hr=1:8;eval(['totalwbt=totalwbt+totalwbt' hours{hr} ';']);end
            end
            if varsdes(variab)==2
                avgsallhwdays{varsdes(variab),presleveliw(varsdes(variab)),10}=totalwbt/(hotdaysc*8); %10 is daily avg, 1-8 are standard hours
                %dimensions of avgsallhwdays are variable|pressure level|time(dailyavg,stdhour,&c)
                for hr=1:8
                    eval(['avgsallhwdays{varsdes(variab),presleveliw(varsdes(variab)),' num2str(hr) '}=totalwbt' hours{hr} '/hotdaysc;']);
                end
            else
                avgsallhwdays{varsdes(variab),presleveliw(varsdes(variab)),10}=total/(hotdaysc*8);
                for hr=1:8
                    eval(['avgsallhwdays{varsdes(variab),presleveliw(varsdes(variab)),' num2str(hr) '}=total' hours{hr} '/hotdaysc;']);
                end
            end
        end
        hotdayscvec{1,1}=hotdaysc;
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays','avgsallhwdays','-append');
    end
    if tempevol==1
        %avgstempevol={};
        for firstday=0:2 %full is 0-2
            for variab=viwf:viwl
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
                total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
                for hr=1:8;eval(['total' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
                hotdaysc=0;hoteventsc=0;
                for year=yeariwf:yeariwl
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
                            %If it does, get the data for its hours -- compute daily average as the
                            %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                            %because of the EDT-UTC offset
                            for row=1:size(plotdays{vartorankby,2,firstday+1},1)
                                if plotdays{vartorankby,2,firstday+1}(row,2)==year && plotdays{vartorankby,2,firstday+1}(row,1)>=curmonstart...
                                        && plotdays{vartorankby,2,firstday+1}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{vartorankby,2,firstday+1}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    if month<=9
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                            varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if lastdayofmonth==1
                                            nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                                varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartnextmon=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                        end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/','air','/',...
                                            num2str(year),'/','air','_',num2str(year),...
                                            '_0',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                            if lastdayofmonth==1
                                                nextmonprevFile=load(char(strcat(curDir,'/','air','/',num2str(year),'/',...
                                                    'air','_',num2str(year),'_0',num2str(month+1),'_',...
                                                    num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                                lastpartprevnextmon=char(strcat('air','_',num2str(year),'_0',num2str(month+1),'_',...
                                                    num2str(preslevels(presleveliw(varsdes(variab))))));
                                                prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                            end
                                        end
                                    else 
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                        '_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/','air','/',...
                                            num2str(year),'/','air','_',num2str(year),...
                                            '_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_',num2str(month),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                        end
                                    end
                                    curArr=eval(['curFile.' lastpartcur]);
                                    if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end
                                        

                                    %DOI is day of interest
                                    arrDOI=curArr{3}(:,:,1,dayinmonth)-adj;
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        arrDOInextday=curArr{3}(:,:,1,(dayinmonth+1))-adj;
                                    else
                                        arrDOInextday=nextmonncep{3}(:,:,1,1)-adj;
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        arrDOIthisday=arrDOI; %shum
                                        arrDOIprevthisday=prevArr{3}(:,:,1,dayinmonth)-273.15; %T
                                        mrArr=arrDOIthisday./(1-arrDOIthisday);
                                        esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                        wsArr=0.622*esArr/1000;
                                        rhArr=100*mrArr./wsArr;
                                        arrDOIwbt=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                            atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+...
                                            0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                        %Save data
                                        totalwbt=totalwbt+arrDOIwbt;
                                        indivstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,hotdaysc+1}=arrDOIwbt;
                                    end
                                    
                                    %Save data
                                    total=total+arrDOI;
                                    %Save data for each day individually as well
                                    indivstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,hotdaysc+1}=arrDOI;
                                    
                                    hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                end
                            end
                        end
                    end
                end
                if varsdes(variab)==2
                    avgstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,10}=totalwbt/(hotdaysc); %10 is daily avg
                    %dimensions of avgstempevol are variable|pressure level|cluster#|day
                else
                    avgstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,10}=total/(hotdaysc);
                end
            end
            hotdayscvec{2,firstday+1}=hotdaysc;
        end
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays','avgstempevol','-append');
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepindivdayarrays','indivstempevol','-append');
    end
    if seasonality==1 %here firstday is preset to 99
        %avgsseasonality={};
        for season=seasiwf:seasiwl %(May-)Jun, Jul, Aug(-Sep)
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    vararginnew={'variable';varargnames{varsdes(variab)};'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet';...
                            'caxismethod';cbsetting;'vectorData';data};
                    adj=0;scalarvar=0;
                end
                total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
                hotdaysc=0;hoteventsc=0;
                for year=yeariwf:yeariwl
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
                            %Look at all days of heat waves
                            for row=1:size(plotdays{vartorankby,3,season},1)
                                if plotdays{vartorankby,3,season}(row,2)==year && plotdays{vartorankby,3,season}(row,1)>=curmonstart...
                                        && plotdays{vartorankby,3,season}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{vartorankby,3,season}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    if month<=9
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                            varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if lastdayofmonth==1
                                            nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                            varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartnextmon=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                        end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/air/',...
                                            num2str(year),'/air_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                            if lastdayofmonth==1
                                                nextmonprevFile=load(char(strcat(curDir,'/','air','/',num2str(year),'/',...
                                                    'air','_',num2str(year),'_0',num2str(month+1),'_',...
                                                    num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                                lastpartprevnextmon=char(strcat('air','_',num2str(year),'_0',num2str(month+1),'_',...
                                                    num2str(preslevels(presleveliw(varsdes(variab))))));
                                                prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                            end
                                        end
                                    else 
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                        '_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/','air','/',...
                                            num2str(year),'/','air','_',num2str(year),...
                                            '_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_',num2str(month),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                        end
                                    end
                                    curArr=eval(['curFile.' lastpartcur]);
                                    if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end

                                    arrDOI=curArr{3}(:,:,1,dayinmonth)-adj;
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        arrDOInextday=curArr{3}(:,:,1,dayinmonth+1)-adj;
                                    else
                                        arrDOInextday=nextmonncep{3}(:,:,1,1)-adj;
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        arrDOIthisday=arrDOI; %shum
                                        arrDOIprevthisday=prevArr{3}(:,:,1,dayinmonth)-273.15; %T
                                        mrArr=arrDOIthisday./(1-arrDOIthisday);
                                        esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                        wsArr=0.622*esArr/1000;
                                        rhArr=100*mrArr./wsArr;
                                        arrDOIwbt=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                            atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+...
                                            0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                        %Save data
                                        totalwbt=totalwbt+arrDOIwbt;
                                        indivsseasonality{varsdes(variab),presleveliw(varsdes(variab)),firstday,hotdaysc+1}=arrDOIwbt;
                                    end
                                    %Save data
                                    total=total+arrDOI;
                                    indivsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,hotdaysc+1}=arrDOI;

                                    hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                end
                            end
                        end
                    end
                end
                %Dimensions of avgsseasonality are variable|pressure level|season|time(dailyavg or stdhour)
                if varsdes(variab)==2
                    avgsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,10}=totalwbt/(hotdaysc); %10 is daily avg
                else
                    avgsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,10}=total/(hotdaysc);
                end
            end
            hotdayscvec{3,season}=hotdaysc;
        end
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays','avgsseasonality','-append');
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepindivdayarrays','indivsseasonality','-append');
    end
    if diurnality==1 %here firstday is preset to 99
        avgsdiurnality={};
        %for variab=1:size(varsdes,1)
        for variab=viwf:viwl
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
            total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
            for hr=1:8;eval(['total' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
            for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
            hotdaysc=0;hoteventsc=0;
            for year=yeariwf:yeariwl
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
                        %If it does, get the data for its hours --
                        %noting that 8pm and 11pm are located under the following day's heading because of the EDT-UTC offset
                        for daysofhw=1:2 %look at first & last days both
                            for row=1:size(plotdays{vartorankby,4,daysofhw},1)
                                if plotdays{vartorankby,4,daysofhw}(row,2)==year &&...
                                        plotdays{vartorankby,4,daysofhw}(row,1)>=curmonstart...
                                        && plotdays{vartorankby,4,daysofhw}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{vartorankby,4,daysofhw}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    if month<=9
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                            varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if lastdayofmonth==1
                                            nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                                varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartnextmon=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab))))));
                                        end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/','air','/',...
                                            num2str(year),'/','air','_',num2str(year),...
                                            '_0',num2str(month),'_01.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_01'));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                            if lastdayofmonth==1
                                                nextmonprevFile=load(char(strcat(curDir,'/','air','/',num2str(year),'/',...
                                                    'air','_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                                lastpartprevnextmon=char(strcat('air','_',num2str(year),'_0',num2str(month+1),'_01'));
                                                prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                            end
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
                                    if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end


                                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                        else
                                            eval(['arrDOI' hours{hr} 'nextday=nextmonncep{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                        end
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        for hr=1:8
                                            arrDOIthisday=eval(['arrDOI' hours{hr} ';']);
                                            arrDOIprevthisday=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                                            mrArr=arrDOIthisday./(1-arrDOIthisday);
                                            esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                            wsArr=0.622*esArr/1000;
                                            rhArr=100*mrArr./wsArr;
                                            arrDOIwbt=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                                atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+...
                                                0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                            %Save data, keeping hours separate
                                            eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;']);
                                        end
                                    end
                                    %Save data, keeping hours separate
                                    for hr=1:8
                                        eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);
                                    end
                                    %total=total+arrDOI;
                                    hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                end
                            end
                        end
                    end
                end
            end
            %Assign hourly sums directly to holding array
            %Dimensions of avgsdiurnality are variable|pressure level|stdhour
            if varsdes(variab)==2
                for hr=1:size(hourstodo,1) %not interested in all the hours
                    eval(['avgsdiurnality{varsdes(variab),presleveliw(varsdes(variab)),hourstodo(hr)}=totalwbt' hours{hourstodo(hr)} '/hotdaysc;']);
                end
            else
                for hr=1:size(hourstodo,1)
                    eval(['avgsdiurnality{varsdes(variab),presleveliw(varsdes(variab)),hourstodo(hr)}=total' hours{hourstodo(hr)} '/hotdaysc;']);
                end
            end
        end
        hotdayscvec{4,1}=hotdaysc;
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays','avgsdiurnality','-append');
    end
    if seasonalitydiurnality==1 %here firstday is preset to 99
        %avgsseasdiurn={};
        for season=seasiwf:seasiwl %(May-)Jun, Jul, Aug(-Sep)
            %for variab=1:size(varsdes,1)
            for variab=viwf:viwl
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
                total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
                for hr=1:8;eval(['total' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
                for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(ncepsz(1),ncepsz(2));']);end
                hotdaysc=0;hoteventsc=0;
                for year=yeariwf:yeariwl
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
                            %If it does, get the data for its hours -- compute daily average as the
                            %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                            %because of the EDT-UTC offset
                            for daysofhw=1:2 %look at first & last days both
                                for row=1:size(plotdays{vartorankby,3,season,daysofhw},1)
                                    if plotdays{vartorankby,3,season,daysofhw}(row,2)==year && plotdays{vartorankby,3,season,daysofhw}(row,1)>=curmonstart...
                                            && plotdays{vartorankby,3,season,daysofhw}(row,1)<curmonstart+curmonlen
                                        dayinmonth=plotdays{vartorankby,3,season,daysofhw}(row,1)-curmonstart+1;disp(dayinmonth);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            lastdayofmonth=0;
                                        else
                                            lastdayofmonth=1;
                                        end
                                        %Just load in the files needed
                                        if month<=9
                                            curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                                varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01.mat')));
                                            lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_01'));
                                            if lastdayofmonth==1
                                                nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                                    varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                                lastpartnextmon=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_01'));
                                            end
                                            if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                                prevFile=load(char(strcat(curDir,'/air/',...
                                                num2str(year),'/air_',num2str(year),'_0',num2str(month),'_01.mat')));
                                                lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_01'));
                                                prevArr=eval(['prevFile.' lastpartprev]);
                                                if lastdayofmonth==1
                                                    nextmonprevFile=load(char(strcat(curDir,'/','air','/',num2str(year),'/',...
                                                        'air','_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                                    lastpartprevnextmon=char(strcat('air','_',num2str(year),'_0',num2str(month+1),'_01'));
                                                    prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                                end
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
                                        if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end

                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonncep{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                        %Compute WBT from T and RH (see average-computation loop above for details)
                                        if strcmp(varlist{varsdes(variab)},'shum')
                                            for hr=1:8
                                                arrDOIthisday=eval(['arrDOI' hours{hr} ';']); %shum
                                                arrDOIprevthisday=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                mrArr=arrDOIthisday./(1-arrDOIthisday);
                                                esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                                wsArr=0.622*esArr/1000;
                                                rhArr=100*mrArr./wsArr;
                                                arrDOIwbt=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                                    atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+...
                                                    0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                                %Save data, keeping hours separate
                                                eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;']);
                                            end
                                        end
                                        
                                        %Save data, keeping hours separate
                                        %Compute daily average as 2am-11pm
                                        for hr=1:8;eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);end

                                        hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                    end
                                end
                            end
                        end
                    end
                end
                %Assign hourly sums directly to holding array
                %Dimensions of avgsseasdiurn are variable|pressure level|season|stdhour
                if varsdes(variab)==2
                    for hr=1:size(hourstodo,1)
                        eval(['avgsseasdiurn{varsdes(variab),presleveliw(varsdes(variab)),season,hourstodo(hr)}=totalwbt' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                else
                    for hr=1:size(hourstodo,1)
                        eval(['avgsseasdiurn{varsdes(variab),presleveliw(varsdes(variab)),season,hourstodo(hr)}=total' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                end
            end
            hotdayscvec{5,season}=hotdaysc;
        end
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays','avgsseasdiurn','-append');
    end
    if moistness==1 %here firstday is preset to 99
        avgsmoistness={};
        for relmoist=1:2 %very moist & not-so-moist heat waves
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    vararginnew={'variable';varargnames{varsdes(variab)};'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;...
                            'caxismethod';cbsetting;'vectorData';data};
                    adj=0;scalarvar=0;
                end
                total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
                hotdaysc=0;hoteventsc=0;
                for year=yeariwf:yeariwl
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
                            %If it does, get the data for its hours --
                            %noting that 8pm and 11pm are located under the following day's heading because of the EDT-UTC offset
                            for row=1:size(plotdays{vartorankby,6,relmoist},1)
                                if plotdays{vartorankby,6,relmoist}(row,2)==year &&...
                                        plotdays{vartorankby,6,relmoist}(row,1)>=curmonstart...
                                        && plotdays{vartorankby,6,relmoist}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{vartorankby,6,relmoist}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    if month<=9
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                            varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',...
                                            num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if lastdayofmonth==1
                                            nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',num2str(year),'/',...
                                                varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(month+1),'_',...
                                                num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartnextmon=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',...
                                                num2str(month+1),'_',num2str(preslevels(presleveliw(varsdes(variab))))));
                                        end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/','air','/',...
                                            num2str(year),'/','air','_',num2str(year),...
                                            '_0',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab))))));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                            if lastdayofmonth==1
                                                nextmonprevFile=load(char(strcat(curDir,'/','air','/',num2str(year),'/',...
                                                    'air','_',num2str(year),'_0',num2str(month+1),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                                lastpartprevnextmon=char(strcat('air','_',num2str(year),'_0',num2str(month+1),'_',num2str(preslevels(presleveliw(varsdes(variab))))));
                                                prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                            end
                                        end
                                    else 
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                        '_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                        lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab))))));
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calc. WBT
                                            prevFile=load(char(strcat(curDir,'/','air','/',...
                                            num2str(year),'/','air','_',num2str(year),...
                                            '_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                                            lastpartprev=char(strcat('air','_',num2str(year),'_',num2str(month),'_',num2str(preslevels(presleveliw(varsdes(variab))))));
                                            prevArr=eval(['prevFile.' lastpartprev]);
                                        end
                                    end
                                    curArr=eval(['curFile.' lastpartcur]);
                                    if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end


                                    %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                    arrDOI=curArr{3}(:,:,1,dayinmonth)-adj;
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        arrDOInextday=curArr{3}(:,:,1,(dayinmonth+1))-adj;
                                    else
                                        arrDOInextday=nextmonncep{3}(:,:,1,1)-adj;
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        arrDOIthisday=arrDOI;
                                        arrDOIprevthisday=prevArr{3}(:,:,1,dayinmonth)-273.15;
                                        mrArr=arrDOIthisday./(1-arrDOIthisday);
                                        esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                        wsArr=0.622*esArr/1000;
                                        rhArr=100*mrArr./wsArr;
                                        arrDOIwbt=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                            atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+...
                                            0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                        %Sum up & save data
                                        totalwbt=totalwbt+arrDOIwbt;
                                        indivsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,hotdaysc+1}=arrDOIwbt;
                                    end
                                    %Sum up & save data
                                    indivsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,hotdaysc+1}=arrDOI;
                                    total=total+arrDOI;
                                    hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                end
                            end
                        end
                    end
                end
                %Assign daily sums to holding array
                %Dimensions of avgsmoistness are variable|pressure level|moist category|stdhour
                if varsdes(variab)==2
                    avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,10}=totalwbt/hotdaysc;
                else
                    avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,10}=total/hotdaysc;
                end
            end
            hotdayscvec{6,relmoist}=hotdaysc;
        end
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepavgsarrays','avgsmoistness','-append');
        save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/ncepindivdayarrays','indivsmoistness','-append');
    end
end


if computeusebottomupclusters==1
    %Create corresponding reghwbyTstarts and cluster-memberships list
    %compressed to include only those heat waves for which I have valid ncep data 
    reghwbyTstartsncep(1:56,:)=reghwbyTstarts(29:84,:);
    %First column of idxncep is cluster memberships of first days; second, of last days
    idxncep(1:56,1)=idx(57:2:167,1);idxncep(1:56,2)=idx(58:2:168,1);
    if firstday==1;idxnceptouse=idxncep(:,1);elseif firstday==0;idxnceptouse=idxncep(:,2);end
    
    %Read in & sum data on heat-wave days belonging to particular clusters
    for variab=1:size(varsdes,1)
        prevArr={};
        if strcmp(varlist{varsdes(variab)},'air')
            vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
            adj=273.15;scalarvar=1;
        elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
            vararginnew={'variable';varargnames{varsdes(variab)};'contour';contouropt;'plotCountries';1;'caxismethod';cbsetting};
            adj=0;scalarvar=1;
        elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
            vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;...
                    'caxismethod';cbsetting;'vectorData';data};
            adj=0;scalarvar=0;
        end
        total=zeros(ncepsz(1),ncepsz(2));totalwbt=zeros(ncepsz(1),ncepsz(2));
        for clust=1:k
            eval(['totalcl' num2str(clust) '=zeros(ncepsz(1),ncepsz(2));']);
            eval(['totalwbtcl' num2str(clust) '=zeros(ncepsz(1),ncepsz(2));']);
        end
        hotdaysc=0;hoteventsc=0;
        for clust=1:k;eval(['hotdaysccl' num2str(clust) '=0;']);end
        exist hotdaysfirstccl1;
        if ans==0 || redohotdaysfirstc==1
            for clust=1:k;eval(['hotdaysfirstccl' num2str(clust) '=0;']);end
        end
        if ans==0 || redohotdayslastc==1
            for clust=1:k;eval(['hotdayslastccl' num2str(clust) '=0;']);end
        end
        for year=yeariwf:yeariwl
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
                    for row=1:size(plotdays{vartorankby,firstday+1},1)
                        if plotdays{vartorankby,firstday+1}(row,2)==year && plotdays{vartorankby,firstday+1}(row,1)>=curmonstart...
                                && plotdays{vartorankby,firstday+1}(row,1)<curmonstart+curmonlen
                            dayinmonth=plotdays{vartorankby,firstday+1}(row,1)-curmonstart+1;disp(dayinmonth);
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
                            arrDOI=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth)-adj; %DOI is day of interest
                            %Compute WBT from T and RH (see average-computation loop above for details)
                            if strcmp(varlist{varsdes(variab)},'shum')
                                arrDOIprev=prevArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth)-273.15;
                                mrArr=arrDOI./(1-arrDOI);
                                esArr=6.11*10.^(7.5*arrDOIprev./(237.3+arrDOIprev));
                                wsArr=0.622*esArr/1000;
                                rhArr=100*mrArr./wsArr;
                                arrDOIwbt=arrDOIprev.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                    atan(arrDOIprev+rhArr)-atan(rhArr-1.676331)+...
                                    0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                totalwbt=totalwbt+arrDOIwbt;
                            end
                                
                            %Save data indiscriminately if I don't care about clusters
                            total=total+arrDOI;
                            hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                            %If I do, determine what cluster this day belongs to,
                            %and save its data accordingly
                            curcluster=idxnceptouse(row);
                            totalthisclust=eval(['totalcl' num2str(curcluster)]);
                            totalthisclust=totalthisclust+arrDOI;
                            eval(['totalcl' num2str(curcluster) '=totalthisclust;']);
                            if strcmp(varlist{varsdes(variab)},'shum')
                                totalwbtthisclust=eval(['totalwbtcl' num2str(curcluster)]);
                                totalwbtthisclust=totalwbtthisclust+arrDOIwbt;
                                eval(['totalwbtcl' num2str(curcluster) '=totalwbtthisclust;']);
                            end
                            hotdayscthisclust=eval(['hotdaysccl' num2str(curcluster)]);
                            hotdayscthisclust=hotdayscthisclust+1;
                            eval(['hotdaysccl' num2str(curcluster) '=hotdayscthisclust;']);
                            %To be able to combine data from first & last
                            %days, need to save them between runs
                            if firstday==1
                                if redohotdaysfirstc==1
                                    disp('Redoing hotdaysfirstc');
                                    hotdaysfirstcthisclust=eval(['hotdaysfirstccl' num2str(curcluster)]);
                                    hotdaysfirstcthisclust=hotdaysfirstcthisclust+1;
                                    eval(['hotdaysfirstccl' num2str(curcluster) '=hotdaysfirstcthisclust;']);
                                end
                                if needtocalcfirstday==1
                                    disp('Redoing cluster counts of first days');
                                    totalthisclustfirst=eval(['totalfirstcl' num2str(curcluster)]);
                                    totalthisclustfirst=totalthisclustfirst+arrDOI;
                                    eval(['totalfirstcl' num2str(curcluster) '=totalthisclustfirst;']);
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        totalwbtthisclustfirst=eval(['totalwbtfirstcl' num2str(curcluster)]);
                                        totalwbtthisclustfirst=totalwbtthisclustfirst+arrDOIwbt;
                                        eval(['totalwbtfirstcl' num2str(curcluster) '=totalwbtthisclustfirst;']);
                                    end
                                end
                            elseif firstday==0
                                if redohotdayslastc==1
                                    disp('Redoing hotdayslastc');
                                    hotdayslastcthisclust=eval(['hotdayslastccl' num2str(curcluster)]);
                                    hotdayslastcthisclust=hotdayslastcthisclust+1;
                                    eval(['hotdayslastccl' num2str(curcluster) '=hotdayslastcthisclust;']);
                                end
                                if needtocalclastday==1
                                    disp('Redoing cluster counts of last days');
                                    totalthisclustlast=eval(['totallastcl' num2str(curcluster)]);
                                    totalthisclustlast=totalthisclustlast+arrDOI;
                                    eval(['totallastcl' num2str(curcluster) '=totalthisclustlast;']);
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        totalwbtthisclustlast=eval(['totalwbtlastcl' num2str(curcluster)]);
                                        totalwbtthisclustlast=totalwbtthisclustlast+arrDOIwbt;
                                        eval(['totalwbtlastcl' num2str(curcluster) '=totalwbtthisclustlast;']);
                                    end
                                end
                            end
                            
                            %Save arrays on hot days into a cell matrix to be able to plot & compare them
                            %The beauty of this is that this loop need not be run again as long as the arrays are saved!
                            %Have to decide here if day is part of a multiday event, in which case their synoptic conds are
                            %of course highly correlated -- average the two days
                            if row>=2
                                if plotdays{vartorankby,firstday+1}(row,2)==plotdays{vartorankby,firstday+1}(row-1,2)...
                                        && abs(plotdays{vartorankby,firstday+1}(row,1)-plotdays{vartorankby,firstday+1}(row-1,1))<=7
                                    arrEvent=(oldDOI+arrDOI)./2;
                                    hoteventsarrs{hoteventsc-1,variab}=arrEvent; %the actual ncep data
                                    heahelper(hoteventsc-1,1)=plotdays{vartorankby,firstday+1}(row,1); %includes dates for map-title purposes
                                    heahelper(hoteventsc-1,2)=plotdays{vartorankby,firstday+1}(row-1,1);
                                        %the previous day that's also part of this event
                                    heahelper(hoteventsc-1,3)=plotdays{vartorankby,firstday+1}(row,2); %year of event
                                    hoteventsc=hoteventsc-1;%disp('Multi-day event found');
                                else
                                    arrEvent=arrDOI;
                                    hoteventsarrs{hoteventsc,variab}=arrEvent;
                                    heahelper(hoteventsc,1)=plotdays{vartorankby,firstday+1}(row,1);
                                    heahelper(hoteventsc,2)=0; %so it's clear later that it's a simple one-day event
                                    heahelper(hoteventsc,3)=plotdays{vartorankby,firstday+1}(row,2);
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
        for clust=1:k
            totalclx=eval(['totalcl' num2str(clust)]);totalwbtclx=eval(['totalwbtcl' num2str(clust)]);
            totalclx=totalclx/eval(['hotdaysccl' num2str(clust)]);
            totalwbtclx=totalwbtclx/eval(['hotdaysccl' num2str(clust)]);
            eval(['totalcl' num2str(clust) '=totalclx;']);eval(['totalwbtcl' num2str(clust) '=totalwbtclx;']);
        end
        %Therefore, these explicit arrays are essentially the same, but are
        %saved in between runs
        if firstday==1 && needtocalcfirstday==1
            disp('line 617');disp(hotdaysfirstccl1);disp(hotdaysfirstccl2);disp(hotdayslastccl2);
            for clust=1:k
                totalfirstclx=eval(['totalfirstcl' num2str(clust)]);totalwbtfirstclx=eval(['totalwbtfirstcl' num2str(clust)]);
                totalfirstclx=totalfirstclx/eval(['hotdaysfirstccl' num2str(clust)]);
                totalwbtfirstclx=totalwbtfirstclx/eval(['hotdaysfirstccl' num2str(clust)]);
                eval(['totalfirstcl' num2str(clust) '=totalfirstclx;']);eval(['totalwbtfirstcl' num2str(clust) '=totalwbtfirstclx;']);
            end
        end
        if firstday==0 && needtocalclastday==1
            disp('line 626');disp(hotdaysfirstccl1);disp(hotdaysfirstccl2);disp(hotdayslastccl2);
            for clust=1:k
                totallastclx=eval(['totallastcl' num2str(clust)]);totalwbtlastclx=eval(['totalwbtlastcl' num2str(clust)]);
                totallastclx=totallastclx/eval(['hotdayslastccl' num2str(clust)]);
                totalwbtlastclx=totalwbtlastclx/eval(['hotdayslastccl' num2str(clust)]);
                eval(['totallastcl' num2str(clust) '=totallastclx;']);eval(['totalwbtlastcl' num2str(clust) '=totalwbtlastclx;']);
            end
        end
    end
end

%Save cluster composites that were just calculated into arrays for semi-permanent storage
%These all use daily-avg data unless otherwise specified
if savetotalsintoarrays==1
    for variab=viwf:viwl
        if strcmp(varlist(varsdes(variab)),'air')
            %Data for all first days OR last days in each bottom-up cluster
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1 %cluster composed of all the days (effectively no clustering at all)
                for cl=clmin:clmax
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=avgsallhwdays{1,presleveliw(1),10};']);
                end
            %Data for the 3 temporal-evolution 'clusters'
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgstempevol{1,presleveliw(1),' num2str(cl) ',10};']);
                end
            %Data for the 3 seasonality 'clusters'
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsseasonality{1,presleveliw(1),' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                %'avgsseasonality{1,presleveliw(1),' num2str(cl) ',10};']);
            %Data for the 4 diurnality 'clusters'
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{1,presleveliw(1),' num2str(actualhour) '};']);
                end
            %Data for joint seasonality-diurnality 'clusters'
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{1,presleveliw(1),' num2str(season) ',' num2str(actualhour) '};']);
                end
            %Data for the 2 moistness 'clusters'
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsmoistness{1,presleveliw(1),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                %Also compute & save daily averages for the 2 clusters
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr1f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr1f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl599=tempdailyavg;']);
            end
            %Also make arrays with data from all days in a specific cluster regardless of whether they are first or last
            %Weight cluster average by its composition of first and last days, rather than a straight average of the averages
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr1f99rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'shum') %uses shum but output is WBT
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=totalwbtcl' num2str(cl) ';']);end
                cl=99;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=totalwbtcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=avgsallhwdays{2,presleveliw(2),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgstempevol{2,presleveliw(2),' num2str(cl) ',10};']);
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsseasonality{2,presleveliw(2),' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                %'avgsseasonality{2,presleveliw(2),' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{2,presleveliw(2),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    disp('line 1540');disp(season);disp(actualhour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{2,presleveliw(2),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsmoistness{2,presleveliw(2),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr2f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr2f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalwbtfirstcl1))~=0 && max(max(totalwbtlastcl1))~=0
                    for cl=1:k
                        eval(['arr2f99rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=(totalwbtfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totalwbtlastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'hgt')
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=avgsallhwdays{3,presleveliw(3),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgstempevol{3,presleveliw(3),' num2str(cl) ',10};']);
                end
            elseif seasonality==1 %all with firstday=99
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsseasonality{3,presleveliw(3),' num2str(season) ',10};']);
                end
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{3,presleveliw(3),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{3,presleveliw(3),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3)))...
                    'cl549=avgsmoistness{3,presleveliw(3),1,10};']);
                eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3)))...
                    'cl599=avgsmoistness{3,presleveliw(3),2,10};']);
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr3f99rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'uwnd')
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=avgsallhwdays{4,presleveliw(4),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgstempevol{4,presleveliw(4),' num2str(cl) ',10};']);
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsseasonality{4,presleveliw(4),' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                %'avgsseasonality{4,presleveliw(4),' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{4,presleveliw(4),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{4,presleveliw(4),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsmoistness{4,presleveliw(4),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr4f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr4f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr4f99rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'vwnd')
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=avgsallhwdays{5,presleveliw(5),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgstempevol{5,presleveliw(5),' num2str(cl) ',10};']);
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsseasonality{5,presleveliw(5),' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                %'avgsseasonality{5,presleveliw(5),' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{5,presleveliw(5),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{5,presleveliw(5),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsmoistness{5,presleveliw(5),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr5f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr5f99rb1cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr5f99rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        end
    end
    if firstday==1
        redohotdaysfirstc=0;
    elseif firstday==0
        redohotdayslastc=0;
    end
end

%Main plotting loop
%Calculate fields of interest and display resulting composite maps of heat-wave days
if plotheatwavecomposites==1
    exist scalarvar;if ans==0;scalarvar=1;end %assume scalar if not yet given
    %Set ranges for color axis
    if anomfromjjaavg==1
        if showoverlaycompositeplots==1
            if underlaynum==1
                if strcmp(mapregion,'north-america') || strcmp(mapregion,'usa-exp')
                    caxismin(underlaynum)=-8;caxismax(underlaynum)=8;cstep(underlaynum)=0.5;
                elseif strcmp(mapregion,'us-ne') || strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=-2;caxismax(underlaynum)=8;cstep(underlaynum)=0.3;
                else
                    caxismin(underlaynum)=-2;caxismax(underlaynum)=8;cstep(underlaynum)=0.3;
                end
            elseif underlaynum==2
                if strcmp(mapregion,'north-america') || strcmp(mapregion,'usa-exp')
                    caxismin(underlaynum)=-7;caxismax(underlaynum)=7;cstep(underlaynum)=0.5;
                elseif strcmp(mapregion,'us-ne') || strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=-2;caxismax(underlaynum)=6;cstep(underlaynum)=0.3;
                else
                    caxismin(underlaynum)=-2;caxismax(underlaynum)=6;cstep(underlaynum)=0.3;
                end
            elseif underlaynum==3
                caxismin(underlaynum)=-100;caxismax(underlaynum)=100;cstep(underlaynum)=10;
            elseif underlaynum==4
                if strcmp(mapregion,'north-america')
                    caxismin(underlaynum)=-7;caxismax(underlaynum)=7;cstep(underlaynum)=0.5;
                else
                    caxismin(underlaynum)=-3;caxismax(underlaynum)=3;cstep(underlaynum)=0.5;
                end
            end
        elseif shownonoverlaycompositeplots==1
            caxismin(1)=-8;caxismax(1)=8;cstep(1)=0.5; %temperature
            caxismin(2)=-6;caxismax(2)=6;cstep(2)=0.5; %WBT
            caxismin(3)=-50;caxismax(3)=100;cstep(3)=10; %gph
            caxismin(4)=-10;caxismax(4)=10;cstep(4)=1; %uwnd
            caxismin(5)=-10;caxismax(5)=10;cstep(5)=1; %vwnd
        end
    else
        if showoverlaycompositeplots==1
            if underlaynum==1
                if strcmp(mapregion,'us-ne') || strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=10;caxismax(underlaynum)=35;cstep(underlaynum)=1;
                elseif strcmp(mapregion,'usa-exp')
                    caxismin(underlaynum)=5;caxismax(underlaynum)=40;cstep(underlaynum)=1;
                elseif strcmp(mapregion,'north-america')
                    caxismin(underlaynum)=5;caxismax(underlaynum)=40;cstep(underlaynum)=1;
                end
            elseif underlaynum==2
                if strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=18;caxismax(underlaynum)=25;cstep(underlaynum)=0.3;
                elseif strcmp(mapregion,'us-ne')
                    caxismin(underlaynum)=10;caxismax(underlaynum)=28;cstep(underlaynum)=0.5;
                elseif strcmp(mapregion,'usa-exp')
                    caxismin(underlaynum)=5;caxismax(underlaynum)=30;cstep(underlaynum)=1;
                elseif strcmp(mapregion,'north-america')
                    caxismin(underlaynum)=0;caxismax(underlaynum)=30;cstep(underlaynum)=1;
                end
            elseif underlaynum==3
                caxismin(underlaynum)=5750;caxismax(underlaynum)=6000;cstep(underlaynum)=20;
            elseif underlaynum==4
                if strcmp(mapregion,'mapregionsize3')
                    caxismin(underlaynum)=-7;caxismax(underlaynum)=7;cstep(underlaynum)=0.5;
                else
                    caxismin(underlaynum)=-3;caxismax(underlaynum)=3;cstep(underlaynum)=0.5;
                end
            end
        elseif shownonoverlaycompositeplots==1
            %Temperature
            if strcmp(mapregion,'us-ne') || strcmp(mapregion,'nyc-area')
                caxismin(1)=10;caxismax(1)=40;cstep(1)=1.5;
            elseif strcmp(mapregion,'usa-exp') || strcmp(mapregion,'north-america')
                caxismin(1)=5;caxismax(1)=45;cstep(1)=2;
            end
            caxismin(2)=0;caxismax(2)=30;cstep(2)=2; %WBT
            caxismin(3)=5400;caxismax(3)=6000;cstep(3)=40; %gph
            caxismin(4)=0;caxismax(4)=15;cstep(4)=2; %uwnd
            caxismin(5)=0;caxismax(5)=15;cstep(5)=2; %vwnd
        end
    end
    if tempevol~=1;fdo=clustdes-99;end %clustdes-fdo must be 99 in these cases (to match firstday)
    
    
    %%Make plots themselves%%
    if shownonoverlaycompositeplots==1
        for variab=viwf:viwl
            if anomfromjjaavg==1
                data={lats;lons;...
                double(eval(['arr' num2str(varsdes(variab)) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby)...
                'pl' num2str(preslevels(presleveliw(varsdes(variab)))) 'cl' num2str(clustdes)])-...
                eval(['ncepavgjja' char(varlist2(varsdes(variab)))]))};
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'mystep';cstep(varsdes(variab));'overlaynow';0};
            else
                data={lats;lons;...
                double(eval(['arr' num2str(varsdes(variab)) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby)...
                'pl' num2str(preslevels(presleveliw(varsdes(variab)))) 'cl' num2str(clustdes)]))};
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'mystep';cstep(varsdes(variab));'overlaynow';0};
            end
            %disp(max(max(data{3})));
            plotModelData(data,mapregion,vararginnew,'NCEP');
            if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
            title(sprintf('%s %s %s %s %d %s in the NYC Area as Defined by %s%s',anomavg{anomfromjjaavg+1},...
                timespanremark{timespanlb},char(varlistnames{varsdes(variab)}),dayremark,hotdayscvec{fcc,ursi},hwremark,categlabel,clustremark{clustdes}),...
                'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncep%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(variab)},...
                    varlist3{vartorankby},clustlb,mapregion);
        end
    end
    if overlay==1 && showoverlaycompositeplots==1 %Make single or double overlay
        if overlaynum==4 %wind
            if strcmp(varlist(varsdes(size(varsdes,1))),'vwnd') %if on uwnd, we don't have enough to plot yet
                if anomfromjjaavg==1
                    overlaydata={lats;lons;...
                        double(eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)]))-ncepavgjjauwnd;...
                        double(eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)]))-ncepavgjjavwnd};
                    underlaydata={lats;lons;...
                        double(eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])...
                        -eval(['ncepavgjja' char(varlist2(underlaynum))]))};
                else
                    overlaydata={lats;lons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])}; %wind (both components)
                    underlaydata={lats;lons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])};
                end
                vararginnew={'variable';'wind';'contour';contouropt;'mystep';cstep(2);'plotCountries';1;...
                    'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));...
                    'vectorData';overlaydata;'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                plotModelData(overlaydata,mapregion,vararginnew,'NCEP');figc=figc+1;
                %Add title to newly-made figure
                phrpart1=sprintf('%s %s%d-hPa Wind and %s%s',anomavg{anomfromjjaavg+1},...
                    timespanremark{timespanlb},preslevels(presleveliw(4)),prespr{underlaynum},char(varlistnames{underlaynum}));
                if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s',dayremark,hotdayscvec{fcc,ursi},hwremark,categlabel,clustremark{clustdes});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopncep%s%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},varlist3{varsdes(2)},...
                    varlist3{vartorankby},clustlb,mapregion);
            end
        elseif overlaynum==1 || overlaynum==2 || overlaynum==3 %scalar overlays
            if anomfromjjaavg==1 %Plot anomalies
                overlaydata={lats;lons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(overlaynum))) 'cl' num2str(clustdes)])-...
                    eval(['ncepavgjja' char(varlist2(overlaynum))])};
                underlaydata={lats;lons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])-...
                    eval(['ncepavgjja' char(varlist2(underlaynum))])};
                if clusteranomfromavg==1 %This cluster's anomalies with respect to both the JJA avg and the all-cluster avg
                    overlaydata{3}=overlaydata{3}-(eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(overlaynum))) 'cl0'])-...
                        eval(['ncepavgjja' char(varlist2(overlaynum))]));
                    underlaydata{3}=underlaydata{3}-(eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl0'])-...
                        eval(['ncepavgjja' char(varlist2(underlaynum))]));
                end
                if overlaynum2~=0 %Double overlay (contours+barbs)
                    overlaydata2={lats;lons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)])-ncepavgjjauwnd;...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])-ncepavgjjavwnd};
                    if clusteranomfromavg==1 
                        overlaydata2{3}=overlaydata2{3}-...
                            (eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl0'])-ncepavgjjauwnd);
                        overlaydata2{4}=overlaydata2{4}-...
                            (eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl0'])-ncepavgjjavwnd);
                    end
                end
            else %Plot actual values
                overlaydata={lats;lons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(overlaynum))) 'cl' num2str(clustdes)])};
                underlaydata={lats;lons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])};
                if overlaynum2~=0
                    overlaydata2={lats;lons;eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])};
                end
            end
            
            %underlaydata={lats;lons;(arr2f99rb1cl513-ncepavgjjawbt)-(arr2f99rb1cl505-ncepavgjjawbt)};
            %overlaydata={lats;lons;(arr3f99rb1cl513-ncepavgjjagh)-(arr3f99rb1cl505-ncepavgjjagh)};
            %overlaydata2={lats;lons;(arr4f99rb1cl513-ncepavgjjauwnd)-(arr4f99rb1cl505-ncepavgjjauwnd);(arr5f99rb1cl513-ncepavgjjavwnd)-(arr5f99rb1cl505-ncepavgjjavwnd)};
            
            if overlaynum2~=0 %Double overlay, with one overlayvariable as contours and then wind as barbs
                %Both of these assume that underlaynum is T or WBT
                if anomfromjjaavg==1
                    vararginnew={'variable';'temperature';'contour';1;'mystep';cstep(underlaynum);'plotCountries';1;'caxismin';caxismin(underlaynum);...
                    'caxismax';caxismax(underlaynum);'vectorData';overlaydata2;'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                else
                    vararginnew={'variable';'temperature';'contour';1;'mystep';cstep(underlaynum);'plotCountries';1;'caxismin';caxismin(underlaynum);...
                    'caxismax';caxismax(underlaynum);'vectorData';overlaydata2;'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                end
            else %Single overlay
                if anomfromjjaavg==1
                    vararginnew={'variable';'temperature';'contour';1;'mystep';1;'plotCountries';1;...
                    'caxismin';caxismin(underlaynum);'caxismax';caxismax(underlaynum);'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                else
                    vararginnew={'variable';'temperature';'contour';1;'mystep';1;'plotCountries';1;'caxismin';caxismin(underlaynum);...
                    'caxismax';caxismax(underlaynum);'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                end
            end
            %Actually do the plotting
            plotModelData(overlaydata,mapregion,vararginnew,'NCEP');figc=figc+1;
            
            
            %Add title to newly-made figure and also create filename for saving
            if overlaynum2==0
                phrpart1=sprintf('%s %s %s and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                    char(varlistnames{overlaynum}),prespr{underlaynum},char(varlistnames{underlaynum}));
                if diurnality==1;hotdayscdiurn=round2(hotdayscvec{fcc,ursi}/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
                if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s',dayremark,hotdayscvec{fcc,ursi},hwremark,categlabel,clustremark{clustdes});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopncep%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(underlaynum)},...
                    varlist3{vartorankby},clustlb,mapregion);
            else
                phrpart1=sprintf('%s %s %s, %s, and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                    char(varlistnames{overlaynum}),char(varlistnames{overlaynum2}),prespr{underlaynum},char(varlistnames{underlaynum}));
                if diurnality==1;hotdayscdiurn=round2(hotdayscvec{fcc,ursi}/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
                if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s%s',dayremark,hotdayscvec{fcc,ursi},hwremark,categlabel,...
                    clustremark{clustdes},clustanom{clusteranomfromavg+1});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopncep%s%s%sby%s%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{underlaynum},...
                    varlist3{3},varlist3{vartorankby},clustlb,clanomlb,mapregion);
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
        plotModelData(gpdiffarr,mapregion,vararginnew,'NCEP');
        
        %Add title and save figure
        if plotnum==1
            phrpart1=sprintf('%s, %s, and %s',varlistnames{1},varlistnames{2},varlistnames{3});
            phrpart2=sprintf('on Last Days vs. First Days of T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncepdifftgpwindtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==2
            phrpart1=sprintf('%s, %s, and %s',varlistnames{2},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on Last Days vs. First Days of WBT-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncepdiffwbtgpwindwbtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==3
            phrpart1=sprintf('%s, %s, and %s',varlistnames{1},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncepdifftgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==4
            phrpart1=sprintf('%s, %s, and %s',varlistnames{2},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncepdiffwbtgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==5
            phrpart1=sprintf('%s, %s, and %s',varlistnames{1},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncepdifftgpwindwbtvstrankedfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==6
            phrpart1=sprintf('%s, %s, and %s',varlistnames{2},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopncepdiffwbtgpwindwbtvstrankedfirstdays%s.fig',clustlb);
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
                [caxisrange,step,mycolormap]=plotModelData(data,mapregionsize1,vararginnew,'NCEP');figc=figc+1;

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
                                if sums{stn}<caxisrange(1)+step && colorset==0 %station falls in first decile of ncep color range
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
                    if allreghotdays(j,1)==plotdays{categ,firstday+1}(i,1) && allreghotdays(j,2)==plotdays{categ,firstday+1}(i,2)
                        alreadyhavethisday=1;
                    end
                end
            end
            if alreadyhavethisday==0
                allreghotdays(rowtomake,1)=plotdays{categ,firstday+1}(i,1);
                allreghotdays(rowtomake,2)=plotdays{categ,firstday+1}(i,2);
                rowtomake=rowtomake+1;
            end
        end
    end
    allreghotdays=sortrows(allreghotdays,[2 1]);

    %Now that the list exists, make an auxiliary matrix with shadings for the dates' rankings by Tmax and WBTmax
    for i=1:size(allreghotdays,1)
        for categ=1:2
            rankfound=0;
            for row=1:size(plotdays{categ,firstday+1},1)
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
    text(1.15,-3,'Hot Days Ranked by Regional-Avg...','FontSize',16,'FontWeight','bold');
    text(0.72,-1,'Maximum Temperature','FontSize',16,'FontWeight','bold');
    text(1.75,-1,'Wet-Bulb Temperature','FontSize',16,'FontWeight','bold');
    text(1.14,65,'Colors represent ranking (with white >=36)','FontSize',16,'FontWeight','bold');
end


%Make triangular plots showing *relative* magnitude of WBT anomalies at
%JFK, EWR, LGA during Jun vs Aug heat waves
%i.e. there will be 8 plots for each month, each plot corresponding to a
%set of anomalies for that hour
if maketriangleplots==1
    bracketinghours={};numdays={};
    %wbtortbyseasonandhour={};
    for variab=v1:v2
        if variab==1
            col=5; %column of hourlytvecs containing this variable
        elseif variab==2
            col=14;
        end
        
        %Get data from the relevant days
        for season=6:8
            maxhere=0;minhere=1000;
            for stnc=3:5
                %Hours bracketing heat waves occurring in this season
                rowtomake=1;
                for i=1:size(reghwstartendhours,1)
                    if reghwstartendhours(i,3)==season
                        bracketinghours{season-5}(rowtomake,1)=reghwstartendhours(i,1);
                        bracketinghours{season-5}(rowtomake,2)=reghwstartendhours(i,2);
                        rowtomake=rowtomake+1;
                    end
                end

                %For each heat wave, get the Ts or WBTs, keeping them separated by hour of day
                for i=1:size(bracketinghours{season-5},1)
                    curstarthour=bracketinghours{season-5}(i,1);
                    curendhour=bracketinghours{season-5}(i,2);
                    if i==1 && hourlytvecs{stnc}(curstarthour-4,col)>0 %i.e. if nonzero data exists on the hours we need
                        numdays{stnc,season-5}=(curendhour-curstarthour+1)/24;
                    elseif hourlytvecs{stnc}(curstarthour-4,col)>0
                        numdays{stnc,season-5}=numdays{stnc,season-5}+(curendhour-curstarthour+1)/24;
                    else %skip this heat wave b/c missing essential data
                        %disp('Skipping this heat wave for this station');disp(curstarthour);disp(stnc);
                    end
                    for hour=curstarthour-4:3:curendhour-4 %8 PM, 11 PM, etc.
                        %Because hours don't start on multiples of 8, the
                        %conversion to stdhours is predictable but odd
                        conversiontable=[5 1;0 2;3 3;6 4;1 5;4 6;7 7;2 8];
                        for j=1:8;if rem(hour,8)==conversiontable(j,1);correspstdhour=conversiontable(j,2);end;end

                        if i==1 && hour<=curstarthour+19
                            wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}=hourlytvecs{stnc}(hour,col);
                        elseif hourlytvecs{stnc}(curstarthour-4,col)>0 %again, skip heat waves with missing data
                            wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}=...
                                wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}+hourlytvecs{stnc}(hour,col);
                        end
                    end
                end

                %Compute station-season averages by dividing by numdays
                for correspstdhour=1:8
                    wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}=...
                        wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}/numdays{stnc,season-5};
                    if wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}<minhere
                        minhere=wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5};
                    end
                    if wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}>maxhere
                        maxhere=wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5};
                    end
                end
            end
            maxsaved{season-5}=maxhere;
            minsaved{season-5}=minhere;
        end

        %Actually make plot -- for Jun & first hour only to start
        %Center of triangle is at (0.5,0.5), and vertices are at (0,0), (1,0), and (0.5,1)
        %therefore, scale points by distance with max plotted at ~= 0.9*sqrt(0.5) and min plotted at ~= 0.1*sqrt(0.5)
        for season=6:8
            for correspstdhour=1:8
                for stnc=1:3
                    datahere=wbtortbyseasonandhour{variab,stnc+2,correspstdhour,season-5};
                    distofdatahere=sqrt(0.5)*(datahere-minsaved{season-5})/(maxsaved{season-5}-minsaved{season-5});
                    if stnc==1 %JFK
                        dataxvalue(1)=0.5+sqrt(distofdatahere.^2/2);
                        datayvalue(1)=0.5-sqrt(distofdatahere.^2/2);
                    elseif stnc==2 %LGA
                        dataxvalue(2)=0.5;
                        datayvalue(2)=0.5+distofdatahere;
                    elseif stnc==3 %EWR
                        dataxvalue(3)=0.5-sqrt(distofdatahere.^2/2);
                        datayvalue(3)=0.5-sqrt(distofdatahere.^2/2);
                    end
                end
                dataxvalue=dataxvalue';datayvalue=datayvalue';
                combos=[1 2 3]; %order in which points are plotted? at any rate, doesn't seem to matter too much

                %Make a dark outline triangle and then plot seasonal hourly triangles inside
                figure(figc);clf;figc=figc+1;
                xvalues=[0;0.5;1];yvalues=[0;0.5+sqrt(0.5);0];
                triplot(combos,xvalues,yvalues,'k','LineWidth',3);hold on; %dark outer triangle
                triplot(combos,dataxvalue,datayvalue,'LineWidth',2);
                x=0.5;y=0.5;plot(x,y,'o','LineWidth',5,'MarkerEdgeColor','k','MarkerFaceColor','k');
                text(1,-0.05,'JFK','FontName','Arial','FontSize',16,'FontWeight','bold');
                text(0.48,1.26,'LGA','FontName','Arial','FontSize',16,'FontWeight','bold');
                text(-0.05,-0.05,'EWR','FontName','Arial','FontSize',16,'FontWeight','bold');
                text(0.05,1.10,clustremark{season-5+200}(3:5),'FontName','Arial','FontSize',16,'FontWeight','bold');
                lengthofremark=size(clustremark{correspstdhour+300},2);
                text(0.13,1.10,clustremark{correspstdhour+300}(3:lengthofremark),'FontName','Arial','FontSize',16,'FontWeight','bold');
                text(0.05,1.16,labelssh{variab},'FontName','Arial','FontSize',16,'FontWeight','bold');
                text(0.7,1.16,sprintf('Vertices: %0.1f C',maxsaved{season-5}),'FontName','Arial','FontSize',16,'FontWeight','bold');
                text(0.7,1.10,sprintf('Center: %0.1f C',minsaved{season-5}),'FontName','Arial','FontSize',16,'FontWeight','bold');
                ylim([0 0.5+sqrt(0.5)]);
                set(gca,'xtick',[]);set(gca,'ytick',[]); %don't need these numbers & ticks on the axes
            end
        end
    end
end

%Similar-spirited station-comparison plots for wind
if makewindarrowplots==1
    col1=7; %wind direction, in deg
    col2=8; %wind speed, in kt
    windbyseasonandhour={};

    for season=6:8
        %Hours bracketing heat waves occurring in this season
        rowtomake=1;
        for i=1:size(reghwstartendhours,1)
            if reghwstartendhours(i,3)==season
                bracketinghours{season-5}(rowtomake,1)=reghwstartendhours(i,1);
                bracketinghours{season-5}(rowtomake,2)=reghwstartendhours(i,2);
                rowtomake=rowtomake+1;
            end
        end
        
        for stnc=3:5 %JFK, LGA, EWR
            %For each heat wave, get the wind direction & speed, keeping them separated by hour of day
            for i=1:size(bracketinghours{season-5},1)
                curstarthour=bracketinghours{season-5}(i,1);
                curendhour=bracketinghours{season-5}(i,2);
                if i==1 && hourlytvecs{stnc}(curstarthour-4,14)>0 %i.e. if nonzero data exists on the hours we need
                    numdays{stnc,season-5}=(curendhour-curstarthour+1)/24;
                elseif hourlytvecs{stnc}(curstarthour-4,14)>0
                    numdays{stnc,season-5}=numdays{stnc,season-5}+(curendhour-curstarthour+1)/24;
                else %skip this heat wave b/c missing essential data
                    %disp('Skipping this heat wave for this station');disp(curstarthour);disp(stnc);
                end
                for hour=curstarthour-4:3:curendhour-4 %8 PM, 11 PM, etc.
                    %Because hours don't start on multiples of 8, the conversion to stdhours is predictable but odd
                    conversiontable=[5 1;0 2;3 3;6 4;1 5;4 6;7 7;2 8];
                    for j=1:8;if rem(hour,8)==conversiontable(j,1);correspstdhour=conversiontable(j,2);end;end

                    if i==1 && hour<=curstarthour+19
                        winddirbyseasonandhour{stnc,correspstdhour,season-5}=hourlytvecs{stnc}(hour,7);
                        windspeedbyseasonandhour{stnc,correspstdhour,season-5}=hourlytvecs{stnc}(hour,8);
                    elseif hourlytvecs{stnc}(curstarthour-4,14)>0 %again, skip heat waves with missing data
                        winddirbyseasonandhour{stnc,correspstdhour,season-5}=...
                            winddirbyseasonandhour{stnc,correspstdhour,season-5}+hourlytvecs{stnc}(hour,7);
                        windspeedbyseasonandhour{stnc,correspstdhour,season-5}=...
                            windspeedbyseasonandhour{stnc,correspstdhour,season-5}+hourlytvecs{stnc}(hour,8);
                    end
                end
            end

            %Compute station-season averages by dividing by numdays
            for correspstdhour=1:8
                winddirbyseasonandhour{stnc,correspstdhour,season-5}=...
                    winddirbyseasonandhour{stnc,correspstdhour,season-5}/numdays{stnc,season-5};
                windspeedbyseasonandhour{stnc,correspstdhour,season-5}=...
                    windspeedbyseasonandhour{stnc,correspstdhour,season-5}/numdays{stnc,season-5};
            end
        end
                
        %Make plots
        for correspstdhour=1:8
            figure(figc);clf;figc=figc+1;
            point{1}=[1 0];plot(point{1}(1),point{1}(2),'o','LineWidth',5,'MarkerEdgeColor','k','MarkerFaceColor','k');hold on;
            point{2}=[3 0];plot(point{2}(1),point{2}(2),'o','LineWidth',5,'MarkerEdgeColor','k','MarkerFaceColor','k');
            point{3}=[5 0];plot(point{3}(1),point{3}(2),'o','LineWidth',5,'MarkerEdgeColor','k','MarkerFaceColor','k');
            colorlist={colors('orange');colors('blue');colors('purple')};
            for stnc=3:5
                windspeed=windspeedbyseasonandhour{stnc,correspstdhour,season-5};
                winddir=winddirbyseasonandhour{stnc,correspstdhour,season-5};
                [a,b,c]=speed2feathers(windspeed); 
                    %a-number of 50-kt flags; b-number of 10-kt full barbs; c-number of 5-kt half barbs
                arrowscaling=windspeed/12; %in the absence of implementing wind barbs, 
                    %scale to a 'maximum' of 12 kts (it's a long-term average after all)
                arrowxcomponent=arrowscaling*(sin(winddir*pi/180));
                arrowycomponent=arrowscaling*(sqrt(1-arrowxcomponent.^2));
                if winddir<270 && winddir>90 %wind has a southerly component
                    yvalue=point{stnc-2}(2)+arrowycomponent;
                else
                    yvalue=point{stnc-2}(2)-arrowycomponent;
                end
                if winddir<180 %wind has an easterly component
                    xvalue=point{stnc-2}(1)-arrowxcomponent;
                else
                    xvalue=point{stnc-2}(1)+arrowxcomponent;
                end
                point2=[xvalue yvalue];
                plot_arrow(point{stnc-2}(1),point{stnc-2}(2),point2(1),point2(2),'linewidth',3,'Color',colorlist{stnc-2},...
                    'facecolor',colorlist{stnc-2},'edgecolor',colorlist{stnc-2},'headwidth',.13,'headheight',0.2);
                text(0.9,3.1,'JFK','FontName','Arial','FontSize',20,'FontWeight','bold');
                text(2.9,3.1,'LGA','FontName','Arial','FontSize',20,'FontWeight','bold');
                text(4.9,3.1,'EWR','FontName','Arial','FontSize',20,'FontWeight','bold');
                lengthofremark=size(clustremark{correspstdhour+300},2);
                text(1.1,3.4,sprintf('Avg Heat-Wave Wind Speed, %s, %s',clustremark{season-5+200}(3:5),...
                    clustremark{correspstdhour+300}(3:lengthofremark)),'FontName','Arial','FontSize',24,'FontWeight','bold');
                xlim([0 6]);ylim([-3 3]);
            end
        end
    end
end


%Try to get at advection by calculating the correlation of wind speed from
%various sectors with subsequent-3-hr temp change accounting for the
%average change (during heat waves) between those hours
if calcplotwindspeedcorrels==1
    winddirbyseason={};windspeedbyseason={};
    nnewinddirbyseason={};nnewindspeedbyseason={};enewinddirbyseason={};enewindspeedbyseason={};
    esewinddirbyseason={};esewindspeedbyseason={};ssewinddirbyseason={};ssewindspeedbyseason={};
    sswwinddirbyseason={};sswwindspeedbyseason={};wswwinddirbyseason={};wswwindspeedbyseason={};
    wnwwinddirbyseason={};wnwwindspeedbyseason={};nnwwinddirbyseason={};nnwwindspeedbyseason={};
    %First, need to explicitly find the average temperature during a heat
    %wave over the course of a day
    %For this, can make use of wbtortbyseasonandhour (variab|stnc|stdhour|season)
    %originally calculated for the triangle plots
    avghwt={};
    for season=6:8
        for stdhour=1:8
            avgtthishour=0;
            for stnc=3:5
                 avgtthishour=avgtthishour+wbtortbyseasonandhour{1,stnc,stdhour,season-5};
            end
            avghwt{stdhour,season-5}=avgtthishour/3;
        end
    end
    
    %Get all the wind speeds for particular seasons (don't split up by
    %hours, at least not yet -- particularly since I'm already accounting for the average diurnal cycle)
    for season=6:8
        %Hours bracketing heat waves occurring in this season
        rowtomake=1;
        for i=1:size(reghwstartendhours,1)
            if reghwstartendhours(i,3)==season
                bracketinghours{season-5}(rowtomake,1)=reghwstartendhours(i,1);
                bracketinghours{season-5}(rowtomake,2)=reghwstartendhours(i,2);
                rowtomake=rowtomake+1;
            end
        end
        
        for stnc=3:5 %JFK, LGA, EWR
            rowtomake=1;
            %For each heat wave, get the wind direction & speed, keeping them separated by hour of day
            for i=1:size(bracketinghours{season-5},1)
                curstarthour=bracketinghours{season-5}(i,1);
                curendhour=bracketinghours{season-5}(i,2);
                for hour=curstarthour-4:3:curendhour-4 %8 PM, 11 PM, etc.
                    %Because hours don't start on multiples of 8, the conversion to stdhours is predictable but odd
                    conversiontable=[5 1;0 2;3 3;6 4;1 5;4 6;7 7;2 8];
                    for j=1:8;if rem(hour,8)==conversiontable(j,1);correspstdhour=conversiontable(j,2);end;end

                    winddirbyseason{stnc,season-5}(rowtomake,1)=hourlytvecs{stnc}(hour,7);
                    winddirbyseason{stnc,season-5}(rowtomake,2)=hour;
                    windspeedbyseason{stnc,season-5}(rowtomake,1)=hourlytvecs{stnc}(hour,8);
                    windspeedbyseason{stnc,season-5}(rowtomake,2)=hour;
                    tchangenext3hr{stnc,season-5}(rowtomake,1)=hourlytvecs{stnc}(hour+3,5)-hourlytvecs{stnc}(hour,5);
                    tchangenext3hr{stnc,season-5}(rowtomake,2)=correspstdhour;
                    %Expected temp change in next 3 hours (remembering that standard hours are 3 hours apart)
                    if correspstdhour<=7
                        exptchange=avghwt{correspstdhour+1,season-5}-avghwt{correspstdhour,season-5};
                    elseif correspstdhour==8
                        exptchange=avghwt{1,season-5}-avghwt{correspstdhour,season-5};
                    end
                    unexptchange{stnc,season-5}(rowtomake,1)=tchangenext3hr{stnc,season-5}(rowtomake,1)-exptchange;
                    rowtomake=rowtomake+1;
                end
            end
            
            %Segregate hours based on the wind direction (by eighths of the compass)
            nnerow=1;enerow=1;eserow=1;sserow=1;sswrow=1;wswrow=1;wnwrow=1;nnwrow=1;
            for i=1:size(winddirbyseason{stnc,season-5})
                if winddirbyseason{stnc,season-5}(i,1)==360 || ...
                        winddirbyseason{stnc,season-5}(i,1)>=0 && winddirbyseason{stnc,season-5}(i,1)<45 %NNE
                    nnewinddirbyseason{stnc,season-5}(nnerow,1)=winddirbyseason{stnc,season-5}(i,1);
                    nnewindspeedbyseason{stnc,season-5}(nnerow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    nneunexptchange{stnc,season-5}(nnerow,1)=unexptchange{stnc,season-5}(i,1);
                    nnerow=nnerow+1;
                elseif winddirbyseason{stnc,season-5}(i,1)>=45 && winddirbyseason{stnc,season-5}(i,1)<90 %ENE
                    enewinddirbyseason{stnc,season-5}(enerow,1)=winddirbyseason{stnc,season-5}(i,1);
                    enewindspeedbyseason{stnc,season-5}(enerow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    eneunexptchange{stnc,season-5}(enerow,1)=unexptchange{stnc,season-5}(i,1);
                    enerow=enerow+1;
                elseif winddirbyseason{stnc,season-5}(i,1)>=90 && winddirbyseason{stnc,season-5}(i,1)<135 %ESE
                    esewinddirbyseason{stnc,season-5}(eserow,1)=winddirbyseason{stnc,season-5}(i,1);
                    esewindspeedbyseason{stnc,season-5}(eserow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    eseunexptchange{stnc,season-5}(eserow,1)=unexptchange{stnc,season-5}(i,1);
                    eserow=eserow+1;
                elseif winddirbyseason{stnc,season-5}(i,1)>=135 && winddirbyseason{stnc,season-5}(i,1)<180 %SSE
                    ssewinddirbyseason{stnc,season-5}(sserow,1)=winddirbyseason{stnc,season-5}(i,1);
                    ssewindspeedbyseason{stnc,season-5}(sserow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    sseunexptchange{stnc,season-5}(sserow,1)=unexptchange{stnc,season-5}(i,1);
                    sserow=sserow+1;
               elseif winddirbyseason{stnc,season-5}(i,1)>=180 && winddirbyseason{stnc,season-5}(i,1)<225 %SSW
                    sswwinddirbyseason{stnc,season-5}(sswrow,1)=winddirbyseason{stnc,season-5}(i,1);
                    sswwindspeedbyseason{stnc,season-5}(sswrow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    sswunexptchange{stnc,season-5}(sswrow,1)=unexptchange{stnc,season-5}(i,1);
                    sswrow=sswrow+1;
                elseif winddirbyseason{stnc,season-5}(i,1)>=225 && winddirbyseason{stnc,season-5}(i,1)<270 %WSW
                    wswwinddirbyseason{stnc,season-5}(wswrow,1)=winddirbyseason{stnc,season-5}(i,1);
                    wswwindspeedbyseason{stnc,season-5}(wswrow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    wswunexptchange{stnc,season-5}(wswrow,1)=unexptchange{stnc,season-5}(i,1);
                    wswrow=wswrow+1;
                elseif winddirbyseason{stnc,season-5}(i,1)>=270 && winddirbyseason{stnc,season-5}(i,1)<315 %WNW
                    wnwwinddirbyseason{stnc,season-5}(wnwrow,1)=winddirbyseason{stnc,season-5}(i,1);
                    wnwwindspeedbyseason{stnc,season-5}(wnwrow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    wnwunexptchange{stnc,season-5}(wnwrow,1)=unexptchange{stnc,season-5}(i,1);
                    wnwrow=wnwrow+1;
                elseif winddirbyseason{stnc,season-5}(i,1)>=315 && winddirbyseason{stnc,season-5}(i,1)<360 %NNW
                    nnwwinddirbyseason{stnc,season-5}(nnwrow,1)=winddirbyseason{stnc,season-5}(i,1);
                    nnwwindspeedbyseason{stnc,season-5}(nnwrow,1)=windspeedbyseason{stnc,season-5}(i,1);
                    nnwunexptchange{stnc,season-5}(nnwrow,1)=unexptchange{stnc,season-5}(i,1);
                    nnwrow=nnwrow+1;
                end
            end
            
            %Now, for this station and season, correlate wind speed and
            %'unexpected' T change for winds from each direction category
            correltws{stnc,season-5,1}=corr(nneunexptchange{stnc,season-5},nnewindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,2}=corr(eneunexptchange{stnc,season-5},enewindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,3}=corr(eseunexptchange{stnc,season-5},esewindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,4}=corr(sseunexptchange{stnc,season-5},ssewindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,5}=corr(sswunexptchange{stnc,season-5},sswwindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,6}=corr(wswunexptchange{stnc,season-5},wswwindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,7}=corr(wnwunexptchange{stnc,season-5},wnwwindspeedbyseason{stnc,season-5}(:,1));
            correltws{stnc,season-5,8}=corr(nnwunexptchange{stnc,season-5},nnwwindspeedbyseason{stnc,season-5}(:,1));
            
            figure('Color',[1 1 1]);
            X=[1 1 1 1 1 1 1 1]; %for a pie chart with eight even sections
            %possiblecolors=varycolor(200); %a color for every .01 increment of correlation -- doesn't have blue and red like I
            %want though -- somewhat too sensitive for my purposes here
            possiblecolors=[colors('lilac');colors('purple');colors('warm purple');colors('dark magenta');colors('fuchsia');...
                colors('indigo');colors('blue');colors('sky blue');colors('dark turquoise');...
                colors('jade');colors('green');colors('light green');colors('mint');colors('yellow');colors('light orange');...
                colors('orange');colors('light red');colors('red');colors('crimson')];
            %colormap(possiblecolors);
            %mycolormap=possiblecolors;
            labels={'','','','','','','',''};
            p=pie(X,labels);
            hp=findobj(p,'Type','patch');
            for dir=1:8
                correlhere=correltws{stnc,season-5,dir};
                roundedcorrel=round2(correlhere*10,1)+10;
                set(hp(dir),'FaceColor',possiblecolors(roundedcorrel,:));
            end
            %cbh=colorbar('YGrid','on');
            %for i=1:15;mycolormap(i)=-.75+.1*i;end
            %set(cbh,'ytick',possiblecolors);
            %set(cbh,'ytick',-.65:.1:.65);
            %set(cbh,'yticklabel',linspace(-.65:.1:.65));
            %set(cbh,'yticklabel',arrayfun(@num2str,[minval -crange crange maxval],'uni',false));
            set(gcf,'ColorMap',possiblecolors);
            cb=colorbar;
            set(cb,'YTickLabel',{'-0.9','-0.64','-0.38','-0.12','0.14','0.38','0.64','0.9'});
            title(sprintf('Corr. of Wind Speed with Anom. Next-3-Hour Temp. Changes, By Wind Direction: %s, %s',...
                nsp{stnc},clustremark{season-5+200}(3:5)),'FontSize',16,'FontName','Arial','FontWeight','bold');
            figc=figc+1;
        end
    end
end


%Compute & plot scatterplot of spatial extent of 500-hPa variable anomalies vs NYC T for NYC heat waves
%This was originally written with height in mind, but actually any variable can be used
if calcarealextentforscatterplot==1
    
    %First, need empirical pdf of JJA 500-hPa values at every gridpoint
    %Use a stripped-down version of this loop without all the baggage and generalizations it's accumulated
    if getvalueseverysingleday==1
        %everydayvals=cell(5,12); %5 possible areal variables, 12 months
        dayc{5}=0;dayc{6}=0;dayc{7}=0;dayc{8}=0;dayc{9}=0; %day counts for each summer month
        for year=yeariwf:yeariwl
            if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
            for month=monthiwf:monthiwl
                fprintf('Pulling all available ncep data; current year and month are %d, %d\n',year,month);
                curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);

                curFile=load(char(strcat(curDir,'/',varlist(varsdes(arealvariab)),'/',num2str(year),'/',...
                                    varlist(varsdes(arealvariab)),'_',num2str(year),'_0',num2str(month),'_01.mat')));
                lastpartcur=char(strcat(varlist(varsdes(arealvariab)),'_',num2str(year),'_0',num2str(month),'_01'));
                curArr=eval(['curFile.' lastpartcur]);
                if strcmp(varlist{varsdes(arealvariab)},'shum') %need to get T as well to be able to calc. WBT
                    %therefore 'prev' refers to variable ordering and not month ordering
                    prevFile=load(char(strcat(curDir,'/air/',...
                    num2str(year),'/air_',num2str(year),'_0',num2str(month),'_01.mat')));
                    lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_01'));
                    prevArr=eval(['prevFile.' lastpartprev]);
                end

                for dayinmonth=1:curmonlen
                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                        else
                            eval(['arrDOI' hours{hr} 'nextday=nextmonncep{3}(:,:,presleveliw(varsdes(arealvariab)),1*8+ ' num2str(hr-8) ')-adj;']);
                        end
                    end
                    %Compute WBT from T and RH (see average-computation loop above for details)
                    if strcmp(varlist{varsdes(arealvariab)},'shum')
                        for hr=1:8
                            arrDOIthisday=eval(['arrDOI' hours{hr} ';']); %shum
                            arrDOIprevthisday=eval(['prevArr{3}(:,:,presleveliw(varsdes(arealvariab)),dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                            mrArr=arrDOIthisday./(1-arrDOIthisday);
                            esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                            wsArr=0.622*esArr/1000;
                            rhArr=100*mrArr./wsArr;
                            eval(['arrDOI' hours{hr} '=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                'atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+'...
                                '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                arrDOIprevthisday=eval(['prevArr{3}(:,:,presleveliw(varsdes(arealvariab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-273.15;']); %T
                                eval(['arrDOI' hours{hr} 'nextday=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                'atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+'...
                                '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                            else
                                arrDOIprevthisday=eval(['prevArr{3}(:,:,presleveliw(varsdes(arealvariab)),1*8+ ' num2str(hr-8) ')-273.15;']); %T
                                eval(['arrDOI' hours{hr} 'nextday=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                'atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+'...
                                '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                            end
                        end
                    end
                    %Compute daily average as 2am-11pm
                    %Then, put daily avg into an array for safekeeping so that empirical pdf can later be calculated
                    dailysum=0;
                    for hr=1:8;eval(['dailysum=dailysum+arrDOI' hours{hr} ';']);end
                    everydayvals{arealvariab,presleveliw(varsdes(arealvariab)),month}(dayc{month}+1,:,:)=dailysum/8;
                    dayc{month}=dayc{month}+1;
                end
            end
        end
    end
    
    %Next, use everydayvals to get the xth percentile of this variable at each gridpoint into a single
    %array for each month
    if remakexpctvaluebygridpt==1
        %xpctvalbygridpt={};
        for i=1:ncepsz(1)
            for j=1:ncepsz(2)
                for month=monthiwf:monthiwl
                    xpctvalbygridpt{arealvariab,presleveliw(varsdes(arealvariab)),xpct*100}(i,j,month)=...
                        quantile(everydayvalsnew{arealvariab,presleveliw(varsdes(arealvariab)),month}(:,i,j),xpct);
                end
            end
            disp('line 2983');disp(i);
        end
    end
    
    %Then, get variable values at every gridpoint on NYC heat-wave days
    if getvalueseveryhwday==1
        %avgdailyhwvals={};hwmonthslist={};
        hoteventsc=0;hwsum=0;curhwlen=0;hwmonthsum=0;

        for year=yeariwf:yeariwl
            if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
            for month=monthiwf:monthiwl
                fprintf('Current year and month are %d, %d\n',year,month);
                curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);
                %Search through listing of region-wide heat-wave days to see if this month contains one of them
                %If it does, get the data for its hours -- compute daily average as the
                %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading because of the EDT-UTC offset
                for row=1:size(plotdays{vartorankby,7},1)
                    if plotdays{vartorankby,7}(row,2)==year && plotdays{vartorankby,7}(row,1)>=curmonstart &&...
                            plotdays{vartorankby,7}(row,1)<curmonstart+curmonlen
                        dayinmonth=plotdays{vartorankby,7}(row,1)-curmonstart+1;disp(dayinmonth);
                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                            lastdayofmonth=0;
                        else
                            lastdayofmonth=1;
                        end
                        %Just load in the files needed
                        if month<=9
                            curFile=load(char(strcat(curDir,'/',varlist(varsdes(arealvariab)),'/',num2str(year),'/',...
                                varlist(varsdes(arealvariab)),'_',num2str(year),'_0',num2str(month),'_01.mat')));
                            lastpartcur=char(strcat(varlist(varsdes(arealvariab)),'_',num2str(year),'_0',num2str(month),'_01'));
                            if lastdayofmonth==1
                                nextmonFile=load(char(strcat(curDir,'/',varlist(varsdes(arealvariab)),'/',num2str(year),'/',...
                                    varlist(varsdes(arealvariab)),'_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                lastpartnextmon=char(strcat(varlist(varsdes(arealvariab)),'_',num2str(year),'_0',num2str(month+1),'_01'));
                            end
                            if strcmp(varlist{varsdes(arealvariab)},'shum') %need to get T as well to be able to calc. WBT
                                prevFile=load(char(strcat(curDir,'/air/',...
                                num2str(year),'/air_',num2str(year),'_0',num2str(month),'_01.mat')));
                                lastpartprev=char(strcat('air_',num2str(year),'_0',num2str(month),'_01'));
                                prevArr=eval(['prevFile.' lastpartprev]);
                                if lastdayofmonth==1
                                    nextmonprevFile=load(char(strcat(curDir,'/air/',num2str(year),'/',...
                                        'air_',num2str(year),'_0',num2str(month+1),'_01.mat')));
                                    lastpartprevnextmon=char(strcat('air_',num2str(year),'_0',num2str(month+1),'_01'));
                                    prevArrnextmon=eval(['nextmonprevFile.' lastpartprevnextmon]);
                                end
                            end
                        else 
                            curFile=load(char(strcat(curDir,'/',varlist(varsdes(arealvariab)),'/',...
                                num2str(year),'/',varlist(varsdes(arealvariab)),'_',num2str(year),...
                            '_',num2str(month),'_01.mat')));
                            lastpartcur=char(strcat(varlist(varsdes(arealvariab)),'_',num2str(year),'_',num2str(month),'_01'));
                            if strcmp(varlist{varsdes(arealvariab)},'shum') %need to get T as well to be able to calc. WBT
                                prevFile=load(char(strcat(curDir,'/','air','/',...
                                num2str(year),'/','air','_',num2str(year),...
                                '_',num2str(month),'_01.mat')));
                                lastpartprev=char(strcat('air','_',num2str(year),'_',num2str(month),'_01'));
                                prevArr=eval(['prevFile.' lastpartprev]);
                            end
                        end
                        curArr=eval(['curFile.' lastpartcur]);
                        if lastdayofmonth==1;nextmonncep=eval(['nextmonFile.' lastpartnextmon]);end


                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                            else
                                eval(['arrDOI' hours{hr} 'nextday=nextmonncep{3}(:,:,presleveliw(varsdes(arealvariab)),1*8+ ' num2str(hr-8) ')-adj;']);
                            end
                        end
                        %Compute WBT from T and RH (see average-computation loop above for details)
                        if strcmp(varlist{varsdes(arealvariab)},'shum')
                            for hr=1:8
                                arrDOIthisday=eval(['arrDOI' hours{hr} ';']); %shum
                                arrDOIprevthisday=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                mrArr=arrDOIthisday./(1-arrDOIthisday);
                                esArr=6.11*10.^(7.5*arrDOIprevthisday./(237.3+arrDOIprevthisday));
                                wsArr=0.622*esArr/1000;
                                rhArr=100*mrArr./wsArr;
                                eval(['arrDOI' hours{hr} '=arrDOIprevthisday.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                'atan(arrDOIprevthisday+rhArr)-atan(rhArr-1.676331)+'...
                                '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                            end
                        end
                            
                        %Compute daily average
                        %Then, put daily avg into an array for safekeeping
                        %so that empirical pdf can later be calculated
                        dailysum=0;
                        for hr=1:8;eval(['dailysum=dailysum+arrDOI' hours{hr} ';']);end


                        %Determine if this is the last day of a heat wave,
                        %and thus if the hw avg should be computed & stored
                        if row~=size(plotdays{vartorankby,7},1)
                            if plotdays{vartorankby,7}(row,1)~=plotdays{vartorankby,7}(row+1,1)-1 ||...
                                plotdays{vartorankby,7}(row,2)~=plotdays{vartorankby,7}(row+1,2)
                                lastdayofhw=1;curhwlen=curhwlen+1;
                                hwsum=hwsum+dailysum/8;
                                hwmonthsum=hwmonthsum+month;
                                avgdailyhwvals{arealvariab,presleveliw(varsdes(arealvariab)),hoteventsc+1}=hwsum/curhwlen;
                                hwmonthslist{arealvariab}(hoteventsc+1)=hwmonthsum/curhwlen; %weighted hw month (not an integer if hw is split b/w months)
                                disp('line 3140');disp(curhwlen);
                                hwsum=0;curhwlen=0;hwmonthsum=0;
                                hoteventsc=hoteventsc+1;
                                disp('line 3134');disp(row);disp(hoteventsc);
                            else
                                lastdayofhw=0;curhwlen=curhwlen+1;
                                hwsum=hwsum+dailysum/8;
                                hwmonthsum=hwmonthsum+month;
                                %disp('line 3138');disp(hoteventsc);disp(curhwlen);
                            end
                        else
                            lastdayofhw=1;curhwlen=curhwlen+1; %the last day of the last hw
                            hwsum=hwsum+dailysum/8;
                            hwmonthsum=hwmonthsum+month;
                            avgdailyhwvals{arealvariab,presleveliw(varsdes(arealvariab)),hoteventsc+1}=hwsum/curhwlen;
                            hwmonthslist{arealvariab}(hoteventsc+1)=hwmonthsum/curhwlen;
                            hoteventsc=hoteventsc+1;
                            %disp('line 3145');disp(row);disp(hoteventsc);
                        end
                    end
                end
            end
        end
        %save('/Users/colin/Desktop/temp.mat','avgdailyhwvals');
    end
    
    %Next, create a matrix of 1's (0's) for each heat wave representing
    %gridpoints where the variable of interest did (did not) exceed the local xth percentile
    if finishoffcalculation==1
        %exceedmatrix={};
        for eventc=1:hoteventsc %loop over the heat waves
            for i=1:ncepsz(1)
                for j=1:ncepsz(2)
                    monthofhwfirstday=round2(hwmonthslist{arealvariab}(eventc),1,'floor');
                    monthofhwlastday=round2(hwmonthslist{arealvariab}(eventc),1,'ceil');
                    proplastmonth=hwmonthslist{arealvariab}(eventc)-monthofhwfirstday;
                    propfirstmonth=1-proplastmonth;
                    if avgdailyhwvals{arealvariab,presleveliw(varsdes(arealvariab)),eventc}(i,j)>=...
                            propfirstmonth*xpctvalbygridpt{arealvariab,presleveliw(varsdes(arealvariab))}(i,j,monthofhwfirstday)+...
                            proplastmonth*xpctvalbygridpt{arealvariab,presleveliw(varsdes(arealvariab))}(i,j,monthofhwlastday);
                        exceedmatrix{arealvariab,presleveliw(varsdes(arealvariab)),eventc}(i,j)=1;
                    else
                        exceedmatrix{arealvariab,presleveliw(varsdes(arealvariab)),eventc}(i,j)=0;
                    end
                end
            end
        end

        %Getting close to the end...
        %Calculate the % of land gridpoints within 1000 km of NYC experiencing
        %>=xth pct variable anomaly
        %First, this requires a list of those land gridpts
        %Need to modify wncepgridpts directly if a radius change is desired (e.g. to 500 km)
        [junk,landgridptlist]=wncepgridpts(40.78,-73.97,0,1);

        %pctexceeding={};
        for eventc=1:hoteventsc %loop over the heat waves
            exceedcount=0;
            for i=1:size(landgridptlist,1)
                curlandgridptx=landgridptlist(i,3);curlandgridpty=landgridptlist(i,4);
                if exceedmatrix{arealvariab,presleveliw(varsdes(arealvariab)),eventc}(curlandgridptx,curlandgridpty)==1
                    exceedcount=exceedcount+1;
                end
            end
            pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(eventc)=100*exceedcount/size(landgridptlist,1);
        end
        
        
        %Plot WBT percentile for each event vs % of nearby gridpoints
        %exceeding the xth pct
        figure(figc);clf;figc=figc+1;
        %Against Observations
        %Could be valid if changed, but scorescomptotalhw is outdated and I
        %can't even remember exactly what it's measuring
        %scatter(scorescomptotalhw(16:46,2),pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(:),'fill');
        %Against Closest ncep Gridpoint
        for i=1:hoteventsc;nycdata(i)=avgdailyhwvals{2,1,i}(130,258);end
        scatter(nycdata,pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(:),'fill');
        
        %Titles, honorifics, etc.
        titlepart1=sprintf('%s at Closest Gridpoint to NYC vs Percent of ncep Land Gridpoints Within 1000 km of NYC',varlist4{varsdes(arealvariab)});
        titlepart2=sprintf('Experiencing %s>=%0.0fth Percentile, for %d Heat Waves, %d-%d',...
            varlistnames{varsdes(arealvariab)},xpct*100,hoteventsc,yeariwf,yeariwl);
        title({titlepart1,titlepart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
        %xlabel('Heat-wave WBT Percentile at NYC, Calculated Using All JJA Periods of Equivalent Length',...
        %    'FontSize',14,'FontWeight','bold','FontName','Arial');
        xlabel(sprintf('NYC-Gridpoint Heat-Wave-Average %s Value',varlist4{varsdes(arealvariab)}),'FontSize',14,'FontWeight','bold','FontName','Arial');
        ylabel(sprintf('Percent of Nearby Land Gridpoints With %s>=%0.0fth Pct',...
            varlistnames{varsdes(arealvariab)},xpct*100),'FontSize',14,'FontWeight','bold','FontName','Arial');
        
        
        %Scatterplot of heat-wave length vs % of nearby gridpoints exceeding the xth pct
        figure(figc);clf;figc=figc+1;
        scatter(reghwbyTstarts(16:46,3),pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(:),'fill');
        %Titles, honorifics, etc.
        titlepart1=sprintf('Heat-Wave Length vs Percent of NCEP Land Gridpoints Within 1000 km of NYC');
        titlepart2=sprintf('Experiencing %s>=%0.0fth Percentile, for %d Heat Waves, %d-%d',...
            varlistnames{varsdes(arealvariab)},xpct*100,hoteventsc,yeariwf,yeariwl);
        title({titlepart1,titlepart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
        xlabel(sprintf('Heat-Wave Length'),'FontSize',14,'FontWeight','bold','FontName','Arial');
        ylabel(sprintf('Percent of Nearby Land Gridpoints With %s>=%0.0fth Pct',...
            varlistnames{varsdes(arealvariab)},xpct*100),'FontSize',14,'FontWeight','bold','FontName','Arial');
        xlim([2 10]);
    end
end


if calcnhwavenumbers==1
    %First, note that we want to focus attention on (1-144,1-32), as this contains all the NCEP points near or north of 15 N
    %Goal is to calculate: in this range, how many points are below 5900 m?
    %From this an estimated area and length (or an equivalent latitude) can be found
    %Do this for every heat-wave day I have
    variab=3; %height
    if strcmp(regofinterest,'NH')
        numlongitpts=144;imin=1;imax=144;longitfrac=1; %i.e. the whole 360-deg circle
    elseif strcmp(regofinterest,'North America')
        numlongitpts=33;imin=93;imax=125;longitfrac=0.22; %roughly 130W-50W
    end
    numhwsfound={};
    if fcc==2 || fcc==3 || fcc==6 %only flexible-cluster choices for which it makes sense to do this
        cursetofarrays=eval(['indivs' char(fccnames{fcc})]);

        for categ=1:fccnumcategs(fcc)
            %Determine which days are effectively independent:
            %use only
            %the middle day from each event so as to preserve sample
            %independence for the purposes of statistical significance
            hwc=1;middleday{categ}=0;
            firstdayofthisevent(1)=plotdays{1,fcc,categ}(1,1);firstdayofthisevent(2)=plotdays{1,fcc,categ}(1,2);
            for i=1:size(plotdays{1,fcc,categ},1)-1
                thisday(1)=plotdays{1,fcc,categ}(i,1);thisday(2)=plotdays{1,fcc,categ}(i,2);
                nextday(1)=plotdays{1,fcc,categ}(i+1,1);nextday(2)=plotdays{1,fcc,categ}(i+1,2);
                %disp(thisday);disp(nextday);
                if (nextday(1)~=thisday(1)+1 && nextday(2)==thisday(2)) || (nextday(1)==thisday(1)+1 && nextday(2)~=thisday(2)) ||...
                        (nextday(1)~=thisday(1)+1 && nextday(2)~=thisday(2)) %have reached the last day of a heat wave
                    lastdayofthisevent(1)=thisday(1);lastdayofthisevent(2)=thisday(2);
                    middleday{categ}(hwc,1)=round((firstdayofthisevent(1)+lastdayofthisevent(1))/2); %day of date
                    middleday{categ}(hwc,2)=round((firstdayofthisevent(2)+lastdayofthisevent(2))/2); %year of date
                    %disp('line 3270');disp(middleday{categ}(hwc,:));
                    %Now set up for the next event
                    firstdayofthisevent(1)=nextday(1);firstdayofthisevent(2)=nextday(2);
                    hwc=hwc+1;
                end
            end
            i=size(plotdays{1,fcc,categ},1);
            thisday(1)=plotdays{1,fcc,categ}(i,1);thisday(2)=plotdays{1,fcc,categ}(i,2);
            lastdayofthisevent(1)=thisday(1);lastdayofthisevent(2)=thisday(2);
            middleday{categ}(hwc,1)=round((firstdayofthisevent(1)+lastdayofthisevent(1))/2);
            middleday{categ}(hwc,2)=round((firstdayofthisevent(2)+lastdayofthisevent(2))/2);
            
            sinuosity{categ}=0;isoheightperimeter{categ}=0;circumf{categ}=0;
            
            numhwsfound{categ}=0;
            for dayc=1:hotdayscvec{fcc,categ}
                if size(middleday{categ},1)==numhwsfound{categ} %all hws are now accounted for
                    break;
                end
                if plotdays{vartorankby,fcc,categ}(dayc,1)==middleday{categ}(numhwsfound{categ}+1,1) &&...
                        plotdays{vartorankby,fcc,categ}(dayc,2)==middleday{categ}(numhwsfound{categ}+1,2)
                    %disp('line3289');disp(dayc);disp(numhwsfound);
                    numhwsfound{categ}=numhwsfound{categ}+1;
                    if tempevol==1;necoffset=100;else necoffset=0;end
                    curdayarray=cursetofarrays{varsdes(variab),presleveliw(varsdes(variab)),categ+necoffset,dayc};
                    %For ghofinterest, ascertain the latitude of cutoff for
                    %each discrete longitude (first step toward getting the perimeter)
                    %To (imperfectly) deal with possible cutoff lows, chooses the northernmost value that exceeds ghofinterest
                    %numptsnorthofcutoff={};
                    for i=imin:imax
                        alreadyfoundlatcutoff=0;
                        while alreadyfoundlatcutoff==0
                            for j=2:32
                                if curdayarray(i,j)>ghofinterest
                                    latofcutoff{categ}(i)=(lats(i,j)+lats(i,j-1))/2;
                                    lonofcutoff{categ}(i)=(lons(i,j)+lons(i,j-1))/2;
                                    alreadyfoundlatcutoff=1;
                                    numptsnorthofcutoff{categ}(i)=j-1;
                                    break;
                                end
                            end
                            if j==32
                                latofcutoff{categ}(i)=(lats(i,j)+lats(i,j-1))/2;
                                lonofcutoff{categ}(i)=(lons(i,j)+lons(i,j-1))/2;
                                alreadyfoundlatcutoff=1;
                                numptsnorthofcutoff{categ}(i)=j-1;
                            end
                        end
                    end

                    %Now that I have this piecewise-defined line with 144
                    %points, I can obtain the perimeter by calculating the
                    %distance between two points in succession all the way
                    %around the globe
                    isoheightperimetertemp=0;
                    for i=imin:imax
                        isoheightperimetertemp=isoheightperimetertemp+...
                            distance('gc',[latofcutoff{categ}(i),lonofcutoff{categ}(i)],...
                            [latofcutoff{categ}(i+1),lonofcutoff{categ}(i+1)])*111; %dist in km
                    end
                    isoheightperimeter{categ}(numhwsfound{categ})=isoheightperimetertemp+distance('gc',[latofcutoff{categ}(1),lonofcutoff{categ}(1)],...
                        [latofcutoff{categ}(ncepsz(1)),lonofcutoff{categ}(ncepsz(1))])*111; %dist b/w first and last point to close the loop

                    %Also calculate the equivalent latitude, so as to get the
                    %shortest possible perimeter for purposes of comparison
                    %First, sum number of points within the isoheight as computed above
                    pointsum=0;
                    for i=imin:imax;pointsum=pointsum+numptsnorthofcutoff{categ}(i);end

                    %Conceptualize the NCEP grid as a series of dots comprising concentric circles
                    %This next part finds how many 'circles out' we are from the center (at
                    %the pole) and converts this to a latitude
                    %Each circle of course is separated from its neighbors by 2.5 deg on either side
                    %Then, subtract 1.25 because the proper estimated
                    %latitude is halfway by doing only points to the north
                    %the estimate is too far poleward by half a gridbox
                    %Same result can also be obtained by simply averaging latofcutoff around the globe
                    circlesout=(pointsum-numlongitpts)/numlongitpts; %have to subtract numlongitpts as that's how many there are right at the pole
                    estlat=(90-2.5*circlesout)-1.25;

                    %Calculate the area (km^2) contained within (poleward of) the
                    %circle delineated by estlat
                    %Also calculate the circumference (km), multiplying by
                    %a longitudinal fraction if necessary
                    areawithin=2*pi*6371^2*(1-sin(estlat*pi/180)); %area isn't really meaningful except for whole NH
                    circumf{categ}(numhwsfound{categ})=longitfrac*2*pi*6371*(cos(estlat*pi/180));


                    %Now, compare this perfectly circular circumference to the isoheightperimeter as a measure of sinuosity!
                    sinuosity{categ}(numhwsfound{categ})=isoheightperimeter{categ}(numhwsfound{categ})/circumf{categ}(numhwsfound{categ});
                end
            end
        end
        
        %Compare sinuosity of the categories using a boxplot
        sinuositytouse1=0;sinuositytouse2=0;sinuositytouse3=0;
        for categ=1:fccnumcategs(fcc)
            eval(['sinuositytouse' num2str(categ) '=sinuosity{categ}(:);']);
        end
        figure(figc);clf;figc=figc+1;
        %Only set up for 2 or 3 categories at present -- can add more options for
        %flexibility if needed
        if fccnumcategs(fcc)==2
            C=[sinuositytouse1;sinuositytouse2];grp=[zeros(size(sinuositytouse1,1),1);ones(size(sinuositytouse2,1),1)];
        elseif fccnumcategs(fcc)==3
            C=[sinuositytouse1;sinuositytouse2;sinuositytouse3];
            grp=[zeros(size(sinuositytouse1,1),1);ones(size(sinuositytouse2,1),1);2*ones(size(sinuositytouse3,1),1)];
        end
        boxplot(C,grp,'Notch','on');
        labeltemp={};
        for categ=1:fccnumcategs(fcc)
            labeltemp{categ}=sprintf('%s, n=%d',char(fcccategnames{fcc}(categ)),size(eval(['sinuositytouse' num2str(categ) ';']),1));
        end
        
        if fccnumcategs(fcc)==2
            set(gca,'XTick',1:fccnumcategs(fcc),'XTickLabel',{char(labeltemp{1});char(labeltemp{2})},...
                'FontName','Arial','FontSize',16,'FontWeight','bold');
        elseif fccnumcategs(fcc)==3
            set(gca,'XTick',1:fccnumcategs(fcc),'XTickLabel',{char(labeltemp{1});char(labeltemp{2});char(labeltemp{3})},...
                'FontName','Arial','FontSize',16,'FontWeight','bold');
        end
        if fcc==2
            phr='3 Days Prior to, First Day of, and Last Day of';
        elseif fcc==3
            phr='Jun, Jul, and Aug';
        elseif fcc==6
            phr='Very Moist and Less Moist';
        end
        title(sprintf('NH Sinuosity Comparison Between %s NYC Heat Waves',phr),'FontName','Arial','FontSize',16,'FontWeight','bold');
        ylim([1 2.2]);
        %Save figure
        figname=sprintf('wavenumbersinuosity%s.fig',fccnames{fcc});
        fig=gcf;saveas(fig,sprintf('%s%s',figloc,figname));
    end
end


%Analyze for trends in JJA 500hPa heights over NYC
if trendsin500heights==1
    variab=3;adj=0;
    allhgts195059=0;allhgts196069=0;allhgts197079=0;allhgts198089=0;allhgts199099=0;allhgts200009=0;allhgts201014=0;
    decadenames={'195059';'196069';'197079';'198089';'199099';'200009';'201014'};
    decadenames2={'1950-59';'1960-69';'1970-79';'1980-89';'1990-99';'2000-09';'2010-14'};
    nycncepcoords=wncepgridpts(40.8,-74,1);
    nyclatpt=nycncepcoords(1,2);nyclonpt=nycncepcoords(1,1);
    for mon=monthiwf:monthiwl
        validthismonc=0;indexofdays=1;
        thismonlen=eval(['m' num2str(mon+1) 's-m' num2str(mon) 's']);
        for year=1950:yeariwl
            if year>=1950 && year<=1959
                decadecat=1;
            elseif year>=1960 && year<=1969
                decadecat=2;
            elseif year>=1970 && year<=1979
                decadecat=3;
            elseif year>=1980 && year<=1989
                decadecat=4;
            elseif year>=1990 && year<=1999
                decadecat=5;
            elseif year>=2000 && year<=2009
                decadecat=6;
            elseif year>=2010 && year<=2014
                decadecat=7;
            end
            ymmissing=0;
            missingymdaily=eval(['missingymdaily' char(varlist{varsdes(variab)})]);
            for row=1:size(missingymdailyair,1)
                if mon==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
            end
            if ymmissing==1 %Do nothing, just skip the month
            else
                validthismonc=validthismonc+1;
                fprintf('Summing up heights at NYC gridpt for %d, %d\n',year,mon);
                if mon<=9
                    curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                        num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                    '_0',num2str(mon),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                    lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(mon),'_',...
                        num2str(preslevels(presleveliw(varsdes(variab))))));
                else 
                    curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                        num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                    '_',num2str(mon),'_',num2str(preslevels(presleveliw(varsdes(variab)))),'.mat')));
                    lastpartcur=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(mon),'_',...
                        num2str(preslevels(presleveliw(varsdes(variab))))));
                end
                curArr=eval(['curFile.' lastpartcur]);
                curarraytoworkon=eval(['allhgts' decadenames{decadecat}]);
                curarraytoworkon(indexofdays:indexofdays+thismonlen-1)=curArr{3}(nyclonpt,nyclatpt,1,:);
                eval(['allhgts' decadenames{decadecat} '=curarraytoworkon;']);
                indexofdays=indexofdays+thismonlen;
            end
            %Save everything in appropriate places
            if rem(year,10)==9 || year==2014
                curarray=eval(['allhgts' decadenames{decadecat}]);
                eval(['allhgtsmon' num2str(mon) 'dec' decadenames{decadecat} '=allhgts' decadenames{decadecat} ';']);
                curarraytoworkon=0;
                indexofdays=1;
            end
        end
    end
    %Reconstruct full JJA arrays from monthly ones
    arrdec=0;
    for decadecat=1:6
        junflipped=eval(['allhgtsmon6dec' decadenames{decadecat}])';
        julflipped=eval(['allhgtsmon7dec' decadenames{decadecat}])';
        augflipped=eval(['allhgtsmon8dec' decadenames{decadecat}])';
        arrdec(1:920,decadecat)=[junflipped;julflipped;augflipped];
    end
    %Have to treat 2010-14 specially because it has only half the data
    decadecat=7;
    junflipped=eval(['allhgtsmon6dec' decadenames{decadecat}])';
    julflipped=eval(['allhgtsmon7dec' decadenames{decadecat}])';
    augflipped=eval(['allhgtsmon8dec' decadenames{decadecat}])';
    arrdec201014(:,1)=[junflipped;julflipped;augflipped];
    
    %Make boxplot comparing decades
    figure(figc);clf;figc=figc+1;
    C=[arrdec(:,1);arrdec(:,2);arrdec(:,3);arrdec(:,4);arrdec(:,5);arrdec(:,6);arrdec201014(:,1)];
    grp=[zeros(size(arrdec(:,1),1),1);ones(size(arrdec(:,2),1),1);2*ones(size(arrdec(:,3),1),1);...
        3*ones(size(arrdec(:,4),1),1);4*ones(size(arrdec(:,5),1),1);5*ones(size(arrdec(:,6),1),1);...
        6*ones(size(arrdec201014(:,1),1),1)];
    boxplot(C,grp,'Notch','on');
    set(gca,'XTick',1:7,'XTickLabel',{char(decadenames2{1});char(decadenames2{2});char(decadenames2{3});...
        char(decadenames2{4});char(decadenames2{5});char(decadenames2{6});char(decadenames2{7})},...
                'FontName','Arial','FontSize',16,'FontWeight','bold');
    title(sprintf('Interdecadal Comparison of Daily JJA 500-hPa Heights over NYC'),'FontName','Arial','FontSize',16,'FontWeight','bold');
    figname=sprintf('hwdefns500hgttrend.fig');
    fig=gcf;saveas(fig,sprintf('%s%s',figloc,figname));
end