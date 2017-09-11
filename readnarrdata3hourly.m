%Reads in and analyzes NARR data
%Can only do one set of clusters at a time -- either the original
%bottom-up ones, or the temporal-evolution, seasonality, or diurnality groupings
%If changing scope of analysis to include or exclude May & Sep, need to
%rerun makeheatwaverankingnew and clusterheatwaves loops in analyzenycdata
    
%MODIFY SO THAT TOTAL HW AVERAGE IS COMPUTED IN DIURNALITY INSTEAD OF A
%SEPARATE SUPERFLUOUS LOOP CALLED ALLHWDAYS
%JUST NEED TO RUN DIURNALITY OVER ALL HOURS INSTEAD OF <8 HOURSTODO, AND
%SAVE -- THEN CHANGE FIG TITLES ACCORDINGLY

%MODIFY TO SAVE HOTDAYSCVEC
%AVGSALLHWDAYS NEEDS TO BE RECOMPUTED

%Each matrix of NARR data is comprised of 8x-daily values for a month -- have May-Sep 1979-2014
%Dim 1 is lat; Dim 2 is lon; Dim 3 is pressure (1000, 850, 500, 300, 200); Dim 4 is day of month
preslevels=[1000;850;500;300;200]; %levels that were read and saved

%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\
%0. Runtime options

%Script-wide settings
highpct=0.925;                      %the percentile cutoff to be looked at on this run (typically 0.975 or 0.925)
bottomupclusters=0;                 %whether interested in (not necessarily computing) bottom-up clusters of first & last days together
allhwdays=0;                        %whether interested in all heat-wave days (the same as diurnality except total avgs are computed, not just for each hour)
                                        %set to 1 if wishing to calculate the most-general arrays possible
tempevol=1;                         %whether interested in temporal evolution (i.e. comparing 3 days prior, first day, last day, & 3 days after)
                                        %in this case, loops through firstday=0:3 in computeflexibleclusters
    tempmoistness=1;                    %a subset where tempevol composites are further divided by moisture category
seasonality=0;                      %whether interested in seasonality (i.e. comparing (May-)Jun, Jul, & Aug(-Sep))
diurnality=0;                       %whether interested in diurnal evolution (i.e. comparing 11 am, 2 pm, 5 pm, and 8 pm)
seasonalitydiurnality=0;            %whether interested in combined seasonality-diurnality criteria (e.g. 11 am in Jun)
                                        %have to plot absolute values since the necessary averages haven't been calculated
moistness=0;                        %whether interested in moistness (i.e. comparing very moist & not-so-moist heat waves, det. by the median WBT prctile) 
    if tempevol==1;firstday=0;else firstday=99;end %make sure all days are included for everything except tempevol (which goes through them one by one)
    
varsdes=[1;2;3;4;5];                        %variables to compute and prepare for plotting
                                        %1 for T, 2 for WBT, 3 for GPH, 4 & 5 for u & v wind
    viwf=1;viwl=1;                          %the range of variables to analyze on this run
                                            %numbers refer to the **elements of varsdes**, not necessarily to the absolute variable numbers
seasiwf=1;seasiwl=3;                %for seasonality-related runs, seasons to analyze ((May-)Jun = 1, Jul = 2, Aug(-Sep) = 3)
hourstodo=[1;2;3;4;5;6;7;8];                    %for diurnality-related runs, hours to analyze (8pm = 1, 11pm = 2, etc.)
                                        %if this is changed, be sure to change clustremark{x} below appropriately to eliminate the unincluded hours
rb=1;                               %varaible to rank by: 1 for T, 2 for WBT
compositehotdays=0;                 %whether to analyze hot days (defined by Tmax/WBTmax)
compositehwdays=1;                  %(mutually exclusive) whether to analyze heat waves (defined by integrated hourly T/WBT values)
redohotdaysfirstc=0;                %whether to reset the count of number of days belonging to each cluster
                                        %this means having to rerun script for both first and last days
redohotdayslastc=0;                 %change in accordance with above

presleveliw=[1;1;4;2;2];            %pressure levels of interest for variables, at least on this run, with indices referring to preslevels

yeariwf=1979;yeariwl=2014;          %years to compute over on this run; if just testing, 1987 is a good year
monthiwf=6;monthiwl=8;              %months to compute over on this run


%Settings for individual loops (i.e. which to run, and how)
needtoconvert=0;                    %whether to convert from .nc to .mat; target variable is specified within loop (1 min 15 sec/3-hourly data file)
computeavgfields=0;                 %whether to (re)compute average variable fields (~1 hour/variable)   
plotseasonalclimonarrdata=0;        %whether to plot some basic seasonal climo (3 min/variable)
    varsseasclimo=[3];                  %the variables to plot here
                                        %uses the pressure lolumesevels in presleveliw
organizenarrheatwaves=0;            %whether to re-read and assign to clusters NARR data on heat-wave days (15 sec)
                                    %only one of the below cluster choices & computeusebottomupclusters can be selected at a time
    moistnessmethod=3;                  %method used to divide heat waves: 1 for halves split by WBT median, 2 for terciles of distance from WBT/T best-fit line,
                                                        %3 for WBT terciles or quartiles (see analyzenycdata)
    cutofflength=5;                     %heat-wave length (in days) at which to divide heat waves into shorter and longer; set to 0 if not using
    shortonly=1;                        %set to 1 if analyzing only short heat waves, 0 if only long heat waves (ignored if cutofflength==0)
                                            %if making composites with these, have to go in manually and change plotdays to plotdayshortonly and
                                            %(separately) plotdayslongonly in computeflexibleclusters
    alldaysstartyear=2007;              %for arrays with all JJA days, years to start and end -- yeariwf and yeariwl must match
    alldaysendyear=2014;
computeflexibleclusters=0;          %whether to compute & plot flexible top-down two/three-cluster anomaly composites 
                                        %for all clusters: about 30 sec per variable per heat-wave day
                                        %(so ~6 hours for the full run of a cluster with all years and variables)
computeusebottomupclusters=0;    %whether to get data for days belonging to each bottom-up cluster computed in analyzenycdata & plot anomaly composites for them (8 min/variable)
    k=6;                            %the number of clusters that were calculated in analyzenycdata; any number b/w 5 and 9 is supported
    stnsused=3;                     %the number of stations analyzed in the clusters (typically 3 (JFK-LGA-EWR) or 9)
    redefineplotdays=1;                 %whether to redefine plotdays for the clusters using reghwbyTstarts (5 sec)
    redefinecomposites=1;               %whether to redefine composites for the clusters (25 min/variable)
savetotalsintoarrays=0;             %whether to save 'totals' computed in the prior two sections into the arrays needed in the following section (5 sec)
                                        %depending on flexiblecluster selection & what's been computed so far, possible clusters are
                                        %1-8+10, 101-104, 201-203, 301-304, 401-424 (3 seasons & 8 possible hourstodo), or 501-516
    if bottomupclusters==1
        clmin=1;clmax=k;
    elseif allhwdays==1
        clmin=10;clmax=10;
    elseif tempevol==1
        clmin=101;clmax=104; %101-last day; 102-first day; 103-3 days prior; 104-3 days after
                             %if tempmoistness=1, instead 131-134 (same days, for very moist heat waves only) and 141-144 (same days, for less-moist heat waves only)
    elseif seasonality==1
        clmin=201;clmax=203;
    elseif diurnality==1
        clmin=301;clmax=304;
    elseif seasonalitydiurnality==1
        clmin=401;clmax=424;
    elseif moistness==1
        clmin=501;clmax=516; %in the saved arrays, 549 and 599 represent average over all hours for the two categories (e.g. 549 is avg of 501-508)
    end
setupdiffplots=0;                   %whether to prepare difference plots for later (manual) execution
plotheatwavecomposites=0;           %whether to plot NARR heat-wave data (2 min)
    shownonoverlaycompositeplots=0; %whether to show individual composites of temp, shum, or geopotential (chosen by underlaynum)
    showoverlaycompositeplots=1;    %(mutually exclusive) whether to show composites of wind overlaid with another variable
    showdifferenceplots=0;          %whether to show difference plots as set up above
    clustdes=132;                     %cluster to plot -- 0 (full unclustered data), anything from 1 to k (bottom-up clusters), 
                                      %10 (hours, for all heat-wave days),
                                      %101-104 (days, for temporal evolution), 
                                      %131-134 (combined tempevol-moistness: very moist), 141-144 (combined tempevol-moistness: less moist),
                                      %201-203 (seasons, for seasonality),
                                      %301-304 (hours, for diurnality), 
                                      %401-424 (combined seasonality-diurnality, with 401 being hour #1 (8 PM) for May-Jun, 409 -> hour #1 for Jul, 417 -> hour #1 for Aug-Sep),
                                      %501-516, 549, 599 (moistness, with 501 (509) being hour #1 of very moist (less-moist) events and 549 & 599 being daily avgs)
                                      %cluster number must be consistent with tempevol/seasonality/etc choice on this run
    overlay=1;                      %whether to overlay something (wind and possibly something else as well)
        underlaynum=2;              %variable to underlay with shading (typically 2, i.e. WBT)
        overlaynum=3;               %variable to overlay with lines or contours (4 implies 5 because wind components are inseparable)
        overlaynum2=4;              %second variable to overlay (0 or 4 (implying 5)); i.e. only wind can be 2nd overlay
        anomfromjjaavg=1;           %whether to plot heat-wave composites as anomalies from JJA avg fields
        clusteranomfromavg=0;       %for bottom-up clusters, whether to plot each cluster as an anomaly from the all-cluster avg
    mapregion='us-ne';            %size of map region for plots made on this run (see Section I for sizes)
                                        %only operational for overlaynum of 1 to 3 (i.e. scalars)
plotcompositeddifferences=0;        %whether to plot difference composites, e.g. of T between first and last days (1 min 30 sec)
showindiveventplots=0;              %whether to show maps of T, WBT, &c for each event w/in the 15 hottest reg days covered by NARR,
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
    createexceedmatrix=0;                   %whether to compute the last arrays (1 min)
    finishandplot=1;                        %whether to display the final figures (10 sec)
calctqadvection=1;                   %whether to calculate T/q advection at gridpt closest to NYC and/or other points of interest (4 min per hw day local, 25 sec express)
                                            %need to have plotdays{x,2,x} run or at least saved
    analyzehws=0;                           %whether to analyze heat waves or all JJA days
    numpoi=2;                               %number of points of interest to examine
    poi1lat=40.78;poi1lon=-73.97;           %lat/lon of the first point of interest
    poi2lat=41.02;poi2lon=-74.85;           %lat/lon of the second point of interest
    poinames={'New York City';'Northwest NJ'};%names of points of interest
    %poinames={'New York City'};
    plottestday=0;                          %whether to plot data for a test day as an example/verification
    testday='01-01-1948';                   %day to plot, in mm-dd-yyyy format
maketqadvplots=1;                     %whether to make and display T/q advection plots and maps
    plotstodo=[0;0;0;0;0;0;1];                    %for each possible plot, a 0 or a 1 according to whether or not it should be done
    dayhere=3;                                  %for some of the plots, the set of days to analyze: 1 for first days, 2 for last days, 3 for all days
                                                %however, the first days/last days stuff tends to suffer from small sample size
calcomegaadvection=0;                 %whether to calculate adiabatic warming/cooling from vertical motion, in analogy to the T/q advection above
comparativehwtimeseries=0;            %whether to make plots of conditions over the heat waves at a selection of NYC-area gridpts (mimicking JFK-LGA-EWR)


%I. For Science
mapregionsize3='north-america';%larger region to plot over ('north-america', 'na-east','usa-exp', or 'usa')
mapregionsize2='us-ne';       %region to plot over for climatology plots only
mapregionsize1='nyc-area';    %local region to plot over ('nyc-area' or 'us-ne')
fpyear=1948;fpyearnarr=1979;lpyear=2014;      %first & last possible years
fpmonth=5;lpmonth=9;          %first & last possible months
deslat=40.78;deslon=-73.97; %default location (Central Park) to calculate closest NARR gridpoints for
%%%Times in the netCDF files are UTC, so these hours are EDT and begin the previous day%%%
hours={'8pm';'11pm';'2am';'5am';'8am';'11am';'2pm';'5pm'}; %the 'standard hours'
prefixes={'atlcity';'bridgeport';'islip';'jfk';'lga';'mcguireafb';'newark';'teterboro';'whiteplains'};
prhcodes={'acy';'bdr';'jfk';'lga';'ewr';'hpn';'nyc';'ttn';'phl';'teb';'isp'}; %the main reference numbering list
varlist={'air';'shum';'hgt';'uwnd';'vwnd'};
varlist2={'t';'wbt';'gh';'uwnd';'vwnd'};varlist3={'t';'wbt';'gp';'wnd';'wnd'};
varlist4={'Temp.';'WBT';'Geopotential Height';'Zonal Wind';'Meridional Wind'};
varlistnames={sprintf('%d-hPa Temp.',preslevels(presleveliw(1)));sprintf('%d-hPa Wet-Bulb Temp.',preslevels(presleveliw(2)));...
    sprintf('%d-hPa Geopot. Height',preslevels(presleveliw(3)));
    sprintf('%d-hPa Wind',preslevels(presleveliw(4)));sprintf('%d-hPa Wind',preslevels(presleveliw(5)))};
varargnames={'temperature';'wet-bulb temp';'height';'wind';'wind'};
%examples of vararginnew are in the preamble of plotModelData

%II. For Running Remotely or Locally
runningremotely=0;runningonworkcomputer=1;
if runningremotely==0 && runningonworkcomputer==0
    savedvardir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/';
    curDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_data_mat';
    savingDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
    loadreadnycdata=0;
    loadanalyzenycdata=1;highpcttoload=925;sutoload=3;
    loadorgnarrhws=0;loadavgs=0;loadcfc=0;loadavgsbottomup=0;
    loadcalcarealextent=0;
elseif runningonworkcomputer==1
    savedvardir='/Users/craymon3/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/';
    curDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_data_mat';
    savingDir='/Users/craymon3/General_Academics/Research/Exploratory_Plots';
    loadreadnycdata=0;
    loadanalyzenycdata=1;highpcttoload=925;sutoload=3;
    loadorgnarrhws=0;loadavgs=0;loadcfc=0;loadavgsbottomup=0;
    loadcalcarealextent=0;
elseif runningremotely==1
    %Load options can also be set using the function runscriptremotely 
    savedvardir='/cr/cr2630/Saved_Variables_etc/';
    curDir='/cr/cr2630/NARR_3-hourly_data_mat';
    savingDir='/cr/cr2630';
    highpcttoload=925;sutoload=3; %925 or 975; 3 or 9
    loadreadnycdata=1;loadanalyzenycdata=1;loadorgnarrhws=0;loadavgs=1;loadcfc=1;loadavgsbottomup=0;
    loadcalcarealextent=0;
    %Add necessary paths
    addpath('/cr/cr2630/Scripts/GeneralPurposeScripts');
end
%disp('Script is successfully running');


%Load partial or complete workspaces using the above choices
if loadavgs==1
    load(strcat(savedvardir,'narravgjjat'));
    load(strcat(savedvardir,'narravgjjawbt'));
    load(strcat(savedvardir,'narravgjjagh500'));narravgjjagh500=narravgjjagh;
    load(strcat(savedvardir,'narravgjjauwnd1000'));narravgjjauwnd1000=narravgjjauwnd;
    load(strcat(savedvardir,'narravgjjavwnd1000'));narravgjjavwnd1000=narravgjjavwnd;
    load(strcat(savedvardir,'narravgjjauwnd850'));narravgjjauwnd850=narravgjjauwnd;
    load(strcat(savedvardir,'narravgjjavwnd850'));narravgjjavwnd850=narravgjjavwnd;
    load(strcat(savedvardir,'narravgsarrays'));
end
if loadcfc==1
    avgsallhwdays=load(strcat(savedvardir,'computeflexibleclustersallhwdays'));
    for i=1:5;eval(['arr' num2str(i) 'f99rb1pl' num2str(preslevels(presleveliw(i))) 'cl10=avgsallhwdays.arr' num2str(i) 'f99rb1cl10;']);end
    load(strcat(savedvardir,'computeflexibleclusterstempevol'));%avgstempevolnormal=temp.avgstempevol;
    if cutofflength~=0
        temp=load(strcat(savedvardir,'computeflexibleclusterstempevolshortonly'));avgstempevolshortonly=temp.avgstempevol;
        %longonly has just shum & gh
        temp=load(strcat(savedvardir,'computeflexibleclusterstempevollongonly'));avgstempevollongonly=temp.avgstempevol;
    end
    temp=load(strcat(savedvardir,'computeflexibleclusterstempmoistness'));avgstempmoistness=temp.combarray;
    load(strcat(savedvardir,'computeflexibleclustersseasonality'));
    load(strcat(savedvardir,'computeflexibleclustersdiurnality'));
    load(strcat(savedvardir,'computeflexibleclustersseasonalitydiurnality'));
    load(strcat(savedvardir,'computeflexibleclustersmoistness'));
end
if loadavgsbottomup==1
    load(strcat(savedvardir,'avgsbottomupk6hp975'));avgsbottomupk6hp975=avgsbottomup;
    load(strcat(savedvardir,'avgsbottomupk6hp925'));avgsbottomupk6hp925=avgsbottomup;
end
if loadcalcarealextent==1
    load(strcat(savedvardir,'calcarealextentfinalresultswbt1000'));
end

%III. Other File Management
figloc=sprintf('%s/Plots/',savingDir); %where figures will be placed
missingymdailyair=[];missingymdailyshum=[];missingymdailyuwnd=[];missingymdailyvwnd=[];missingymdailyhgt=[];
lsmask=ncread('lsmasknarr.nc','land')';



%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?
%%%Start of script%%%

if needtoconvert==1
    %Converts raw .nc files to .mat ones using handy function courtesy of Ethan
    %rawNcDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Raw_nc_files';
    rawNcDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_raw_activefiles';
    %outputDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
    outputDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_data_mat';
    varName='air';
    maxNum=1000; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum);
    varName='hgt';
    maxNum=1000; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum);
    varName='shum';
    maxNum=2000; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum);
    varName='uwnd';
    maxNum=2000; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum); 
    varName='vwnd';
    maxNum=2000; %maximum number of files to transcribe at once
    narrNcToMat(rawNcDir,outputDir,varName,maxNum); 
end

%Make sure the proper versions of the saved arrays are used for this run in fitting with
%the choices made above
k=6;
%if bottomupclusters==1;avgsbottomup=eval(['avgsbottomupk' num2str(k) 'hp' num2str(highpct*1000) ';']);end
%reghwbyTstarts=eval(['reghwbyTstartshp' num2str(highpct*1000) 'su' num2str(stnsused) ';']); 
%scorescomptotalhw=eval(['scorescomptotalhwhp' num2str(highpct*1000) 'su' num2str(stnsused) ';']);
%Xmatrix=eval(['Xmatrixhp' num2str(highpct*1000) 'su' num2str(stnsused) ';']);
%idx=eval(['idxhp' num2str(highpct*1000) 'su' num2str(stnsused) ';']);
%k=3;

%Other stuff that always needs to be done
a=size(prefixes);numstns=a(1);
exist figc;if ans==0;figc=1;end
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
mons={'jan';'feb';'mar';'apr';'may';'jun';'jul';'aug';'sep';'oct';'nov';'dec'};
prespr={'';'';sprintf('%d-mb ',preslevels(presleveliw(3)));'';''};
overlayvar=varargnames{overlaynum};underlayvar=varargnames{underlaynum};
if overlaynum2~=0;overlayvar2=varargnames{overlaynum2};end
temp=load('-mat','soilm_narr_01_01');soilm_narr_01_01=temp(1).soilm_0000_01_01;
narrlats=soilm_narr_01_01{1};narrlons=soilm_narr_01_01{2};
narrsz=[277;349]; %size of these lat & lon arrays from NARR
save(strcat(savingDir,'/basicstuff'),'narrlats','narrlons','narrsz','-append');
%Save flexclustchoice for ease of doing various things on later runs
if allhwdays==1;fcc=1;elseif tempevol==1;fcc=2;elseif seasonality==1;fcc=3;elseif diurnality==1;fcc=4;...
        elseif seasonalitydiurnality==1;fcc=5;elseif moistness==1;fcc=6;elseif bottomupclusters==1;fcc=10;
end
if cutofflength~=0 && shortonly==1
    hwtype='so'; %short only
elseif cutofflength~=0 && shortonly==0
    hwtype='lo'; %long only
else
    hwtype='all'; %heat waves of any length (up to the maximum specified) are allowed
end
    
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
        needtocalcfirstday=1;disp('Recalculating first day');
    else
        needtocalcfirstday=0;disp('NOT recalculating first day');
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
categlabel=labelssh{rb};
firstlast={'lastday';'firstday';'alldays';'3daysp'};
if firstday==99;flarg=3;elseif clustdes-fdo==2;flarg=4;else flarg=clustdes-fdo+1;end
timespanremark={'Daily';''};
if tempevol==1 || seasonality==1;timespanlb=1;else timespanlb=2;end
clustlb=sprintf('cl%d',clustdes);
clustremark={', Cluster 1';', Cluster 2';', Cluster 3';', Cluster 4';...
    ', Cluster 5';', Cluster 6';', Cluster 7';', Cluster 8'};
clustremark{101,2}=', Last Days';clustremark{102,2}=', First Days';clustremark{103,2}=', 3 Days Prior';clustremark{104,2}=', 3 Days After';
for i=131:134;clustremark{i,1}='Very Moist';end
for i=141:144;clustremark{i,1}='Less Moist';end
clustremark{131,2}=', Last Days';clustremark{132,2}=', First Days';clustremark{133,2}=', 3 Days Prior';clustremark{134,2}=', 3 Days After';
clustremark{141,2}=', Last Days';clustremark{142,2}=', First Days';clustremark{143,2}=', 3 Days Prior';clustremark{144,2}=', 3 Days After';
if monthiwf==5
    clustremark{201,2}=', May-Jun';
elseif monthiwf==6
    clustremark{201,2}=', Jun';
elseif monthiwf==7
    clustremark{201,2}=', Jul';
elseif monthiwf==8
    clustremark{201,2}=', Aug';
end
clustremark{202,2}=', Jul';
if monthiwl==9;clustremark{203,2}=', Aug-Sep';elseif monthiwl==8;clustremark{203,2}=', Aug';elseif monthiwl==7;clustremark{203,2}=', Jul';end
clustremark{301,2}=', 8PM EDT';clustremark{302,2}=', 11PM EDT';clustremark{303,2}=', 2AM EDT';clustremark{304,2}=', 5AM EDT';
clustremark{305,2}=', 8AM EDT';clustremark{306,2}=', 11AM EDT';clustremark{307,2}=', 2PM EDT';clustremark{308,2}=', 5PM EDT';
for i=301:308;clustremark{i,1}='';end
for i=401:424 %401-408 is season 1 hours 1-8
    season=round2(i/8,1,'ceil')+150;hour=rem(i,8)+300;if hour==300;hour=8+300;end
    clustremark{i,2}=strcat(clustremark{season,2},clustremark{hour,2});
    clustremark2{i,2}=[clustremark{season,2}(3:5),' ',clustremark{hour,2}(3:size(clustremark{hour,2},2))];
end
clustremark{551,1}='Very Moist';clustremark{552,1}='Less-Moist';
for i=501:516 %501-508 is moisture category 1 (very moist events) hours 1-8
    moistcateg=round2(i/8+0.5,1,'ceil')+487;hour=rem(i+4,8)+300;if hour==0;hour=8+300;end
    clustremark{i,1}=clustremark{moistcateg,2};clustremark{i,2}=clustremark{hour,2};
end
clustremark{549,1}='Very Moist';clustremark{549,2}=''; %separated for ease of insertion into figure titles
%clustremark{549,2}=', Daily Average';
clustremark{599,1}='Less-Moist';clustremark{599,2}='';
%For plotting: reconvert clustdes into an understandable, referenceable single-digit integer (ursi)
%essentially, its value is an integer roughly in the range 1-10
if allhwdays==1
    ursi=clustdes;
elseif tempevol==1
    ursi=clustdes-100;
elseif seasonality==1
    ursi=clustdes-200;
elseif diurnality==1
    ursi=clustdes-300;
elseif seasonalitydiurnality==1
    ursi=clustdes-400;
elseif moistness==1
    if clustdes==549;ursi=1;else ursi=2;end
elseif bottomupclusters==1
    ursi=clustdes;
end
anomavg={'Average';'Anomalous'};anomavg2={'avg';'anom'};
clustanom={'';' Minus All-Cluster Avg'};
clanomlb=sprintf('clanom%d',clusteranomfromavg);
if compositehwdays==1
    if bottomupclusters==1;hwremark='Heat-Wave Days';else hwremark='Heat Waves';end
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
hwdayslabel={'First';'Last';'All'};
if overlay==1;contouropt=0;else contouropt=1;end
if anomfromjjaavg==1;cbsetting='regional10';else cbsetting='regional25';end


%Compute average NARR variable fields for [M]JJA[S] (so anomalies can be defined with respect to them)
%WBT formula is from Stull 2011, with T in C and RH in %
if computeavgfields==1 
    for variab=viwf:viwl
        total=zeros(277,349);totalprev=zeros(277,349);
        for hr=1:8;eval(['total' hours{hr} '=zeros(277,349);']);eval(['totalprev' hours{hr} '=zeros(277,349);']);end
        if strcmp(varlist(varsdes(variab)),'air');adj=273.15;else adj=0;end
        for mon=monthiwf:monthiwl
            validthismonc=0;
            narravgthismont=zeros(277,349);narravgthismonshum=zeros(277,349);
            narravgthismongh=zeros(277,349);narravgthismonuwnd=zeros(277,349);narravgthismonvwnd=zeros(277,349);
            thismonlen=eval(['m' num2str(mon+1) 's-m' num2str(mon) 's']);
            for year=yeariwf:yeariwl
                narrryear=year-1979+1;
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
                    eval(['narravgthismont' hours{hr} '=curtotal;']);
                    eval(['narravg' mons{mon} 't' hours{hr} '=narravgthismont' hours{hr} ';']);
                    narravgthismont=narravgthismont+curtotal;
                end
                narravgthismont=narravgthismont/8;
                eval(['narravg' mons{mon} 't=narravgthismont;']);
            elseif varsdes(variab)==2
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['narravgthismonshum' hours{hr} '=curtotal;']);
                    eval(['narravg' mons{mon} 'shum' hours{hr} '=narravgthismonshum' hours{hr} ';']);
                    narravgthismonshum=narravgthismonshum+curtotal;
                    totalprev=eval(['totalprev' hours{hr}]);
                    eval(['narravgthismont' hours{hr} '=totalprev;']);
                    eval(['narravg' mons{mon} 't' hours{hr} '=narravgthismont' hours{hr} ';']);
                    narravgthismont=narravgthismont+totalprev;
                end
                narravgthismonshum=narravgthismonshum/8;
                narravgthismont=narravgthismont/8;
                eval(['narravg' mons{mon} 'shum=narravgthismonshum;']);
                eval(['narravg' mons{mon} 't=narravgthismont;']);
            elseif varsdes(variab)==3
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['narravgthismongh' hours{hr} '=curtotal;']);
                    eval(['narravg' mons{mon} 'gh' hours{hr} '=narravgthismongh' hours{hr} ';']);
                    narravgthismongh=narravgthismongh+curtotal; %daily avg
                end
                narravgthismongh=narravgthismongh/8; %daily avg
                %disp(narravgthismongh(130,258));
                eval(['narravg' mons{mon} 'gh=narravgthismongh;']);
            elseif varsdes(variab)==4
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['narravgthismonuwnd' hours{hr} '=curtotal;']);
                    eval(['narravg' mons{mon} 'uwnd' hours{hr} '=narravgthismonuwnd' hours{hr} ';']);
                    narravgthismonuwnd=narravgthismonuwnd+curtotal;
                end
                narravgthismonuwnd=narravgthismonuwnd/8;
                eval(['narravg' mons{mon} 'uwnd=narravgthismonuwnd;']);
            elseif varsdes(variab)==5
                for hr=1:8
                    curtotal=eval(['total' hours{hr}]);
                    eval(['narravgthismonvwnd' hours{hr} '=curtotal;']);
                    eval(['narravg' mons{mon} 'vwnd' hours{hr} '=narravgthismonvwnd' hours{hr} ';']);
                    narravgthismonvwnd=narravgthismonvwnd+curtotal;
                end
                narravgthismonvwnd=narravgthismonvwnd/8;
                eval(['narravg' mons{mon} 'vwnd=narravgthismonvwnd;']);
            end
            
            if varsdes(variab)==2
                narravgthismonwbt=calcwbtfromTandshum(narravgthismont,narravgthismonshum,1);
                %Now do these shum->WBT steps for each of the 8 standard hours
                for hr=1:8
                    tarr=eval(['narravgthismont' hours{hr}]);
                    shumarr=eval(['narravgthismonshum' hours{hr}]);
                    narravgthismonwbtthishr=calcwbtfromTandshum(tarr,shumarr,1);
                    eval(['narravg' mons{mon} 'wbt' hours{hr} '=narravgthismonwbtthishr;']);
                end
            end
        end
        %Reconstruct JJA averages from monthly ones
        if monthiwf<=6 && monthiwl>=8
            if varsdes(variab)~=2
                eval(['narravgjja' varlist2{varsdes(variab)} '=(narravgjun' varlist2{varsdes(variab)} '+narravgjul'...
                    varlist2{varsdes(variab)} '+narravgaug' varlist2{varsdes(variab)} ')/3;']);
                for hr=1:8;eval(['narravgjja' varlist2{varsdes(variab)} hours{hr} '=(narravgjun' varlist2{varsdes(variab)} hours{hr} '+narravgjul'...
                    varlist2{varsdes(variab)} hours{hr} '+narravgaug' varlist2{varsdes(variab)} hours{hr} ')/3;']);end
            else
                sumhere=0;
                for hr=1:8;sumhere=sumhere+eval(['narravgjunwbt' hours{hr}]);end
                for hr=1:8;sumhere=sumhere+eval(['narravgjulwbt' hours{hr}]);end
                for hr=1:8;sumhere=sumhere+eval(['narravgaugwbt' hours{hr}]);end
                narravgjjawbt=sumhere/24;
                for hr=1:8;eval(['narravgjjawbt' hours{hr} '=(narravgjunwbt' hours{hr} '+narravgjulwbt'...
                    hours{hr} '+narravgaugwbt' hours{hr} ')/3;']);end
            end
        end
        
        %Save JJA average that was just computed in appropriately named file
        if strcmp(varlist2{varsdes(variab)},'t')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjat.mat',...
                char(sprintf('narravgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'wbt')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjawbt.mat',...
                char(sprintf('narravgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'gh')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjagh.mat',...
                char(sprintf('narravgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'uwnd')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjauwnd.mat',...
                char(sprintf('narravgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s8pm',char(varlist2{varsdes(variab)}))));
        elseif strcmp(varlist2{varsdes(variab)},'vwnd')
            save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjavwnd.mat',...
                char(sprintf('narravgjja%s',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s11am',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s2pm',char(varlist2{varsdes(variab)}))),char(sprintf('narravgjja%s5pm',char(varlist2{varsdes(variab)}))),...
                char(sprintf('narravgjja%s8pm',char(varlist2{varsdes(variab)}))));
        end
    end
end


%Plot some basic seasonal-climo results
if plotseasonalclimonarrdata==1
    disp('Plotting some basic seasonal-climo results');
    for variab=1:size(varsseasclimo,1)
        if strcmp(varlist(varsseasclimo(variab)),'air')
            vararginnew={'variable';'temperature';'contour';1;'mystep';1;'plotCountries';1;
                'caxismethod';'regional10';'overlaynow';0;'anomavg';anomavg2{anomfromjjaavg+1}};
            scalarvar=1;
        elseif strcmp(varlist(varsseasclimo(variab)),'shum')
            vararginnew={'variable';'wet-bulb temp';'contour';1;'mystep';1;'plotCountries';1;
                'caxismethod';'regional10';'overlaynow';0;'anomavg';anomavg2{anomfromjjaavg+1}};
            adj=0;scalarvar=1;
        elseif strcmp(varlist(varsseasclimo(variab)),'hgt')
            vararginnew={'variable';'height';'contour';1;'mystep';10;'plotCountries';1;
                'caxismethod';'regional10';'overlaynow';0;'anomavg';anomavg2{anomfromjjaavg+1}};
            adj=0;scalarvar=1;
        elseif strcmp(varlist(varsseasclimo(variab)),'uwnd') || strcmp(varlist(varsseasclimo(variab)),'vwnd')
            adj=0;scalarvar=0;
        end
        
        matrix1=eval(['narravgjja' varlist2{varsseasclimo(variab)} num2str(preslevels(presleveliw(varsseasclimo(variab))))]);
        data1={narrlats;narrlons;matrix1};
        matrix2=eval(['narravgjja' varlist2{varsseasclimo(variab)} num2str(preslevels(presleveliw(varsseasclimo(variab)))) '5am']);
        data2={narrlats;narrlons;matrix2};
        matrix3=eval(['narravgjja' varlist2{varsseasclimo(variab)} num2str(preslevels(presleveliw(varsseasclimo(variab)))) '5pm']);
        data3={narrlats;narrlons;matrix3};
        if scalarvar==1
            plotModelData(data1,mapregionsize2,vararginnew,'NARR');figc=figc+1;
            title(sprintf('Average Daily %s for JJA, %d hPa, %d-%d',char(varlistnames{varsseasclimo(variab)}),...
                preslevels(presleveliw(varsseasclimo(variab))),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            plotModelData(data2,mapregionsize2,vararginnew,'NARR');figc=figc+1;
            title(sprintf('Average 5AM %s for JJA, %d hPa, %d-%d',char(varlistnames{varsseasclimo(variab)}),...
                preslevels(presleveliw(varsseasclimo(variab))),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            plotModelData(data3,mapregionsize2,vararginnew,'NARR');figc=figc+1;
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
                data={narrlats;narrlons;uwndmatrix;vwndmatrix};
                vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;...
                    'caxismethod';cbsetting;'vectorData';data;'anomavg';anomavg2{anomfromjjaavg+1}};
                plotModelData(data,mapregionsize2,vararginnew,'NARR');
            end
        end  
    end
end
    

%Already have an ordered list of the hottest region-wide days (reghwbyXstarts), so just need
%to analyze the subset that are within the 1979-2014 NARR period of record
%Also, choose subsets of data to analyze on this run according to the
%strictures of tempevol, seasonality, diurnality, moisture, etc

%Temperature is a proxy for availability of the data at all
if organizenarrheatwaves==1
    hoteventsarrs={};heahelper=0;
    plotdays={};
    plotdays{1,1,1}=0;plotdays{1,1,2}=0;
    reghwstarts=eval(['reghw' rankby{rb} 'starts']);
    if compositehotdays==1
        numtodo=1000;vecsize=10000;
    elseif compositehwdays==1
        numtodo=eval(['numreghws' rankby{rb}]);
    end
    for categ=1:1 %1-heat waves ranked by T; 2-heat waves ranked by WBT
        rowtomake=1;rowtosearch=1;
        vecsize=size(eval(['reghw' rankby{categ} 'starts']),1);
        while rowtomake<=numtodo && rowtosearch<=vecsize
            thismonmissing=0;
            if compositehotdays==1
                %thismon=DOYtoMonth(dailymaxXregsorted{categ}(rowtosearch,2),dailymaxXregsorted{categ}(rowtosearch,3));
                %thisyear=dailymaxXregsorted{categ}(rowtosearch,3);
                thismon=DOYtoMonth(reghwbyTstarts(rowtosearch,1),reghwbyTstarts(rowtosearch,2));
                thisyear=reghwbyTstarts(rowtosearch,2);
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
            
            if compositehwdays==1
                reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
                if reghwbystarts(rowtosearch,2)>=fpyearnarr && reghwbystarts(rowtosearch,2)<=lpyear && thismonmissing==0
                    %disp('line 668');
                    %All post-1979 heat-wave days in reghwbystarts are included in this part of plotdays that will be created no matter what
                    %third dimension=1 is last days, =2 is first days
                    plotdays{categ,1,2}(rowtomake,1)=reghwbystarts(rowtosearch,1);
                    plotdays{categ,1,1}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1;
                    plotdays{categ,1,2}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                    plotdays{categ,1,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                    plotdays{categ,1,2}(rowtomake,3)=reghwbystarts(rowtosearch,3);
                    plotdays{categ,1,1}(rowtomake,3)=reghwbystarts(rowtosearch,3);
                    %disp(plotdays{1,1,1});
                    rowtomake=rowtomake+1;
                end
            end
            rowtosearch=rowtosearch+1;
        end
    end
    %disp('line 679');disp(rowtomake);
    
    %Set up vectors to be able to use ALL heat-wave days (not just first and last)
    newplotdays={};hwcount=1;hwdayc=1;
    reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
    newrowtomake=1;
    while hwcount<=size(plotdays{categ,1,1},1)
        lastdaythishw=plotdays{categ,1,1}(hwcount,1);
        firstdaythisthw=plotdays{categ,1,2}(hwcount,1);
        newplotdays{categ,1,1}(newrowtomake,1)=plotdays{categ,1,2}(hwcount,1)+hwdayc-1;
        newplotdays{categ,1,1}(newrowtomake,2)=plotdays{categ,1,2}(hwcount,2);
        newplotdays{categ,1,1}(newrowtomake,3)=plotdays{categ,1,2}(hwcount,3);
        if plotdays{categ,1,2}(hwcount,1)+hwdayc-1==lastdaythishw %i.e. we've reached the last day of this heat wave
            newplotdays{categ,1,1}(newrowtomake,1)=plotdays{categ,1,2}(hwcount,1)+hwdayc-1;
            newplotdays{categ,1,1}(newrowtomake,2)=plotdays{categ,1,2}(hwcount,2);
            newplotdays{categ,1,1}(newrowtomake,3)=plotdays{categ,1,2}(hwcount,3);
            hwcount=hwcount+1;hwdayc=1;
        else
            hwdayc=hwdayc+1;
        end
        newrowtomake=newrowtomake+1;
        %disp(hwcount);disp(hwdayc);disp(rowtomake);
    end
    fullhwdaystoplot=newplotdays{1,1,1};
    %disp('line 708');disp(rowtomake);
    
    %Now that the main plotdays vector has been established, all the specialty ones can follow
    for categ=1:1
        rowtomake=1;rowtosearch=1;
        vecsize=size(eval(['reghw' rankby{categ} 'starts']),1);
        while rowtomake<=numtodo && rowtosearch<=vecsize
            thismon=DOYtoMonth(reghwbyTstarts(rowtosearch,1),reghwbyTstarts(rowtosearch,2));
            thisyear=reghwbyTstarts(rowtosearch,2);
            thismonmissing=0;
            if compositehwdays==1
                reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
                if reghwbystarts(rowtosearch,2)>=fpyearnarr && reghwbystarts(rowtosearch,2)<=lpyear && thismonmissing==0             
                    %if tempevol==1 || computeusebottomupclustersnew==1 || diurnality==1 %first-vs-last-days types of analysis
                        %disp('line 717');
                        plotdays{categ,2,2}(rowtomake,1)=reghwbystarts(rowtosearch,1); %days of first days
                        plotdays{categ,2,1}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1; %last days
                        plotdays{categ,2,3}(rowtomake,1)=reghwbystarts(rowtosearch,1)-3; %3 days prior
                        plotdays{categ,2,4}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)+2; %3 days after
                        plotdays{categ,2,2}(rowtomake,2)=reghwbystarts(rowtosearch,2); %years of first days
                        plotdays{categ,2,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        plotdays{categ,2,3}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        plotdays{categ,2,4}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                    %elseif seasonality==1 || seasonalitydiurnality==1 %choose dates based on seasons, selecting hours later
                        %disp('line 732');
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
                    %end
                    rowtomake=rowtomake+1;
                end
                %disp('line 740');disp(rowtomake);
                
                %Alternative approach that doesn't rely on first & last
                %days, but is inclusive of all days & more elegant to boot
                newrowtomake1=1;newrowtomake2=1;newrowtomake3=1;curhw=1;
                for j=1:size(fullhwdaystoplot,1)
                    medianWBT=quantile(scorescomptotalhw(:,2),0.5); %median WBT percentile among heat waves
                    if j>1
                        if fullhwdaystoplot(j,1)~=fullhwdaystoplot(j-1,1)+1 || fullhwdaystoplot(j,2)~=fullhwdaystoplot(j-1,2) %on to a new heat wave
                            curhw=curhw+1;
                        end
                    end
                    %Perhaps need to have a little offset in case we need to exclude pre-1979 heat waves
                    if highpct==0.975;offsethere=15;elseif highpct==0.925;offsethere=39;end
                    offsethere=0;
                    %Now, create vector in which heat-wave days are assigned to categories
                    if moistnessmethod==1 %halves based on WBT median
                        if scorescomptotalhw(curhw+offsethere,2)>=medianWBT %very moist heat wave (the first 15 in scorescomptotalhw are pre-1979)
                            plotdays{categ,6,1}(newrowtomake1,:)=fullhwdaystoplot(j,:);
                            newrowtomake1=newrowtomake1+1;
                        else %not-so-moist heat wave
                            plotdays{categ,6,2}(newrowtomake2,:)=fullhwdaystoplot(j,:);
                            newrowtomake2=newrowtomake2+1;
                        end
                    elseif moistnessmethod==2 %terciles based on best-fit line
                        if listofhws(curhw+offsethere)==3 %very moist heat wave (with highpct=0.975, the first 15 in scorescomptotalhw are pre-1979)
                            plotdays{categ,6,1}(newrowtomake1,:)=fullhwdaystoplot(j,:);
                            newrowtomake1=newrowtomake1+1;
                        elseif listofhws(curhw+offsethere)==1 %less-moist heat wave
                            plotdays{categ,6,2}(newrowtomake2,:)=fullhwdaystoplot(j,:);
                            newrowtomake2=newrowtomake2+1;
                        end
                    elseif moistnessmethod==3 %terciles/quartiles based on WBT median
                        if listofhws(curhw+offsethere)==3 %very moist heat wave (with highpct=0.925, the first 15 in scorescomptotalhw are pre-1979)
                            plotdays{categ,6,1}(newrowtomake1,:)=fullhwdaystoplot(j,:);
                            newrowtomake1=newrowtomake1+1;
                        elseif listofhws(curhw+offsethere)==1 %less-moist heat wave
                            plotdays{categ,6,2}(newrowtomake2,:)=fullhwdaystoplot(j,:);
                            newrowtomake2=newrowtomake2+1;
                        else %moderately moist heat wave
                            plotdays{categ,6,3}(newrowtomake3,:)=fullhwdaystoplot(j,:);
                            newrowtomake3=newrowtomake3+1;
                        end
                    end
                    if DOYtoMonth(fullhwdaystoplot(j,1),fullhwdaystoplot(j,2))==6
                        plotdays{categ,3,1}(newrowtomake1,:)=fullhwdaystoplot(j,:);newrowtomake1=newrowtomake1+1;
                    elseif DOYtoMonth(fullhwdaystoplot(j,1),fullhwdaystoplot(j,2))==7
                        plotdays{categ,3,2}(newrowtomake2,:)=fullhwdaystoplot(j,:);newrowtomake2=newrowtomake2+1;
                    elseif DOYtoMonth(fullhwdaystoplot(j,1),fullhwdaystoplot(j,2))==8
                        plotdays{categ,3,3}(newrowtomake3,:)=fullhwdaystoplot(j,:);newrowtomake3=newrowtomake3+1;
                    end
                end
            end
            rowtosearch=rowtosearch+1;
        end
        %disp('line 773');disp(rowtomake);
        %Sort plotdays chronologically to get a nice clean list of what we're going to be looking for
        %Moisture-sorted plotdays array is already chronological
        for i=1:2;plotdays{categ,1,i}=sortrows(plotdays{categ,1,i},[2 1]);end %for computeusebottomupclusternew
        for i=1:4;plotdays{categ,2,i}=sortrows(plotdays{categ,2,i},[2 1]);end %for tempevol; i is first & last days
        for i=1:3;for j=1:2;plotdays{categ,3,i,j}=sortrows(plotdays{categ,3,i,j},[2 1]);end;end
             %for seasonality; i is season, j is first & last days
        for i=1:2;plotdays{categ,4,i}=plotdays{categ,2,i};end %for diurnality -- identical to tempevol, but separate for historical reasons
        
        %All heat-wave days (just made by recombining lists of days from very moist and
        %not-so-moist heat waves)
        plotdays{categ,5}=fullhwdaystoplot; %for allhwdays
        %plotdays{categ,7}=[plotdays{categ,7};plotdays{categ,6,2}];
        %[trash,idx]=sortrows(plotdays{categ,7},[2 1]);
        %plotdays{categ,7}=plotdays{categ,7}(idx,:);
        
        %Eliminate zero rows
        for i=1:2;plotdays{categ,1,i}(all(plotdays{categ,1,2}==0,i),:)=[];end
        for i=1:4;plotdays{categ,2,i}(all(plotdays{categ,2,i}==0,2),:)=[];end %i is first & last days
        for i=1:3;for j=1:2;plotdays{categ,3,i,j}(all(plotdays{categ,3,i,j}==0,2),:)=[];end;end %i is season, j is first & last days
        for i=1:2;plotdays{categ,4,i}(all(plotdays{categ,4,i}==0,2),:)=[];end %i is first & last days
        plotdays{categ,5}(all(plotdays{categ,5}==0,2),:)=[];
        for i=1:2;plotdays{categ,6,i}(all(plotdays{categ,6,i}==0,2),:)=[];end
        
        %Define derivative arrays with plotdays data only for heat waves of a specified length
        if cutofflength~=0
            plotdaysshortonly={};plotdayslongonly={};
            if tempevol==1 || computeusebottomupclusters==1 || diurnality==1 || calctqadvection==1
                if tempmoistness~=1 %regular temporal-evolution splitting, no moisture involved
                    for i=1:4
                        shortc=1;longc=1;validhwc=0;
                        for j=1:size(reghwstarts,1)
                            if reghwstarts(j,2)>=fpyearnarr && reghwstarts(j,2)<=lpyear
                                validhwc=validhwc+1;
                                if reghwstarts(j,3)<=cutofflength
                                    plotdaysshortonly{categ,2,i}(shortc,:)=plotdays{categ,2,i}(validhwc,:);
                                    shortc=shortc+1;
                                elseif reghwstarts(j,3)>cutofflength
                                    plotdayslongonly{categ,2,i}(longc,:)=plotdays{categ,2,i}(validhwc,:);
                                    longc=longc+1;
                                end
                            end
                        end
                    end
                else %split not only by temporal evolution but also by moisture (vm, mm, and lm)
                    %however this may not be necessary because tempmoistness loop in computeflexibleclusters already checks both tempevol & moistness
                    %disp('line 932');
                    for i=1:4
                        shortvmc=1;shortmmc=1;shortlmc=1;longvmc=1;longmmc=1;longlmc=0;validhwc=0;
                        for j=1:size(reghwstarts,1)
                            if reghwstarts(j,2)>=fpyearnarr && reghwstarts(j,2)<=lpyear
                                validhwc=validhwc+1;
                                if reghwstarts(j,3)<=cutofflength && listofhws(j)==3 %short & very moist
                                    plotdaysshortonly{categ,2,i,1}(shortvmc,:)=plotdays{categ,2,i}(validhwc,:);
                                    shortvmc=shortvmc+1;
                                elseif reghwstarts(j,3)<=cutofflength && listofhws(j)==1 %short & less moist
                                    plotdaysshortonly{categ,2,i,2}(shortlmc,:)=plotdays{categ,2,i}(validhwc,:);
                                    shortlmc=shortlmc+1;
                                elseif reghwstarts(j,3)<=cutofflength %short & moderately moist
                                    plotdaysshortonly{categ,2,i,3}(shortmmc,:)=plotdays{categ,2,i}(validhwc,:);
                                    shortmmc=shortmmc+1;
                                end
                            end
                        end
                    end
                end
            elseif seasonality==1 || seasonalitydiurnality==1
                for i=1:3
                    for j=1:2
                        shortc=1;longc=1;
                        for k=1:size(reghwstarts,1)
                            if reghwstarts(k,2)>=fpyearnarr && reghwstarts(k,2)<=lpyear
                                if reghwstarts(k,3)<=cutofflength
                                plotdaysshortonly{categ,3,i,j}(shortc,:)=plotdays{categ,3,i,j}(k,:);
                                shortc=shortc+1;
                                elseif reghwstarts(k,3)>cutofflength
                                    plotdayslongonly{categ,3,i,j}(longc,:)=plotdays{categ,3,i,j}(k,:);
                                    longc=longc+1;
                                end
                            end
                        end
                    end
                end
            end
            if allhwdays==1 || calctqadvection==1 %Might as well use allhwdays since it has all the heat waves
                shortc=1;longc=1;hwrow=1;totalhwdays=0;startj=0;endj=0;
                for hwrow=1:size(reghwstarts,1)
                    if reghwstarts(hwrow,2)>=fpyearnarr && reghwstarts(hwrow,2)<=lpyear
                        thishwlength=reghwstarts(hwrow,3);

                        %Assign short and long heat waves into two different arrays that contain all the days (not just first & last)
                        if thishwlength<=cutofflength
                            startj=endj+1;endj=startj+thishwlength-1;
                            %disp(hwrow);disp(startj);disp(endj);disp('that is all for now');
                            plotdaysshortonly{categ,5}(shortc:shortc+thishwlength-1,:)=...
                                plotdays{categ,5}(startj:endj,:);
                            shortc=shortc+thishwlength;
                        elseif thishwlength>cutofflength
                            startj=endj+1;endj=startj+thishwlength-1;
                            plotdayslongonly{categ,5}(longc:longc+thishwlength-1,:)=...
                                plotdays{categ,5}(startj:endj,:);
                            longc=longc+thishwlength;
                        end
                    end
                end
            end
        end
        
        %Arrays that contain only heat waves rather than all hw days, mainly for the purposes of 
        %calculating hw counts under various definitions of tempmoistness
        for i=1:2
            hwc=0;
            for j=1:size(plotdays{categ,6,i},1)-1
                curday=plotdays{categ,6,i}(j,1);curyear=plotdays{categ,6,i}(j,2);
                nextday=plotdays{categ,6,i}(j+1,1);nextyear=plotdays{categ,6,i}(j+1,2);
                if (nextday~=curday+1 && nextyear~=curyear) || (nextday==curday+1 && nextyear~=curyear) ||...
                        (nextday~=curday+1 && nextyear~=curyear) %this is the last day of a hw
                    hwc=hwc+1;
                end
            end
            hwcounts{categ,6,i}=hwc;
        end
    end
    %It's not about heat waves, but this loop creates analogous arrays for all JJA days
    plotalldays=0;c=1;
    for iyear=alldaysstartyear:alldaysendyear
        if rem(iyear,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
        for imonth=monthiwf:monthiwl
            mondoystart=eval(['m' num2str(imonth) 's' char(suffix)]);
            mondoyend=eval(['m' num2str(imonth+1) 's' char(suffix)])-1;
            monlen=mondoyend+1-mondoystart;
            plotalldays(c:c+monlen-1,1)=mondoystart:mondoyend;
            plotalldays(c:c+monlen-1,2)=iyear*ones(monlen,1);
            c=c+monlen;
        end
    end
    %Save arrays
    save(strcat(savedvardir,'organizenarrheatwaves'),'plotdays','fullhwdaystoplot','plotalldays','-append');
    if cutofflength~=0;save(strcat(savedvardir,'organizenarrheatwaves'),'plotdaysshortonly','plotdayslongonly','-append');end
end

%Flexible top-down 'cluster' composites (just groupings, not actually k-means-defined)
%Uses plotdays as computed in the previous loop
if computeflexibleclusters==1
    if allhwdays==1
        disp(clock);%avgsallhwdays={};
        for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
        for variab=viwf:viwl
            prevArr={};
            if strcmp(varlist{varsdes(variab)},'air')
                adj=273.15;scalarvar=1;
            elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                adj=0;scalarvar=1;
            elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                adj=0;scalarvar=0;
            end
            total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
            for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
            hotdaysc=0;hoteventsc=0;
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
                        %If it does, get the data for its hours -- compute daily average as the
                        %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                        %because of the EDT-UTC offset
                        for row=1:size(plotdays{rb,5},1)
                            if plotdays{rb,5}(row,2)==year && plotdays{rb,5}(row,1)>=curmonstart...
                                    && plotdays{rb,5}(row,1)<curmonstart+curmonlen
                                dayinmonth=plotdays{rb,5}(row,1)-curmonstart+1;disp(dayinmonth);
                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                    lastdayofmonth=0;
                                else
                                    lastdayofmonth=1;
                                end
                                %Just load in the files needed
                                curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                    prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                    if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                end

                                for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                    eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                    else
                                        eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                    end
                                end
                                %Compute WBT from T and shum
                                if strcmp(varlist{varsdes(variab)},'shum')
                                    for hr=1:8
                                        arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                        arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                        arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
                                        %Save data
                                        eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;'])
                                    end
                                end
                                %Save data
                                for hr=1:8;eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);end
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
            hotdayscvec{1,1}=hotdaysc;
        end
        disp(clock);save(strcat(savedvardir,'computeflexibleclustersallhwdays'),'avgsallhwdays');
    end
    if tempevol==1
        disp(clock);%avgstempevol={};avgstempmoistness={};
        for i=1:4;for j=1:2;eval(['hotdaysf' num2str(i-1) 'm' num2str(j) '=0;']);end;end
        for firstday=0:3 %full is 0-3: 0-last day, 1-first day, 2-3 days prior, 3-3 days after
            for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
            for hr=1:8;for d=1:4;eval(['totalwbt' hours{hr} '1f' num2str(d) '=zeros(narrsz(1),narrsz(2));']);end;end
            for hr=1:8;for d=1:4;eval(['totalwbt' hours{hr} '2f' num2str(d) '=zeros(narrsz(1),narrsz(2));']);end;end
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    adj=0;scalarvar=0;
                end
                total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2)); %daily avgs
                for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                for hr=1:8;for d=1:4;eval(['total' hours{hr} '1f' num2str(d) '=zeros(narrsz(1),narrsz(2));']);end;end
                for hr=1:8;for d=1:4;eval(['total' hours{hr} '2f' num2str(d) '=zeros(narrsz(1),narrsz(2));']);end;end
                hotdaysc=0;hoteventsc=0;hotdaysc1=0;hotdaysc2=0;
                
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
                            %If it does, get the data for its hours -- compute daily average as the
                            %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                            %because of the EDT-UTC offset
                            if tempmoistness==1 %Split further into moisture categories
                                for relmoist=1:2 %Search for days in this month within both upper & lower tercile listings
                                    for rowofvec=1:size(plotdaysshortonly{rb,2,firstday+1,relmoist},1)
                                        doylookingfor=plotdaysshortonly{rb,2,firstday+1,relmoist}(rowofvec,1);
                                        yearlookingfor=plotdaysshortonly{rb,2,firstday+1,relmoist}(rowofvec,2);
                                        if year==yearlookingfor && doylookingfor>=curmonstart && doylookingfor<=curmonstart+curmonlen-1
                                            fprintf('Relmoist is %d\n',relmoist);fprintf('Firstday is %d\n',firstday);
                                            dayinmonth=plotdaysshortonly{rb,2,firstday+1,relmoist}(rowofvec,1)-curmonstart+1;
                                            fprintf('Year, month, and day are %d, %d, %d\n',year,month,dayinmonth);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                lastdayofmonth=0;
                                            else
                                                lastdayofmonth=1;
                                            end
                                            %Just load in the files needed
                                            curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                            if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                            if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                                prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                                if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                            end

                                            for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                                eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                    eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                                else
                                                    eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                                end
                                            end
                                            %Compute WBT from T and RH (see average-computation loop above for details)
                                            if strcmp(varlist{varsdes(variab)},'shum')
                                                for hr=1:8
                                                    arrDOIthishr=eval(['arrDOI' hours{hr} ';']);
                                                    arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                                                    arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
                                                    %Save data, keeping hours separate
                                                    eval(['totalwbt' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) '=totalwbt' hours{hr} num2str(relmoist)...
                                                        'f' num2str(firstday+1) '+arrDOIwbt;']);
                                                    totalwbt=totalwbt+arrDOIwbt;
                                                end
                                            end
                                            %Save data, keeping hours, days, and moisture categories separate
                                            for hr=1:8
                                                eval(['total' hours{hr} num2str(relmoist) 'f' num2str(firstday+1)...
                                                    '=total' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) '+arrDOI' hours{hr} ';']);
                                                %disp('line 1093');disp(max(max(eval(['total' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) ';']))));
                                                total=total+eval(['arrDOI' hours{hr} ';']);
                                            end
                                            eval(['hotdaysf' num2str(firstday) 'm' num2str(relmoist) '=hotdaysf' num2str(firstday) 'm' num2str(relmoist) '+1;']);
                                        end
                                    end
                                end
                            else %Regular tempevol, no splitting into moisture categories
                                for row=1:size(plotdaysshortonly{rb,2,firstday+1},1)
                                    if plotdaysshortonly{rb,2,firstday+1}(row,2)==year && plotdaysshortonly{rb,2,firstday+1}(row,1)>=curmonstart...
                                            && plotdaysshortonly{rb,2,firstday+1}(row,1)<curmonstart+curmonlen
                                        dayinmonth=plotdaysshortonly{rb,2,firstday+1}(row,1)-curmonstart+1;disp(dayinmonth);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            lastdayofmonth=0;
                                        else
                                            lastdayofmonth=1;
                                        end
                                        %Just load in the files needed
                                        curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                        if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                            prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                            if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                        end


                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                        %Compute WBT from T and RH (see average-computation loop above for details)
                                        if strcmp(varlist{varsdes(variab)},'shum')
                                            for hr=1:8
                                                arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                                arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
                                                %Save data
                                                eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;'])
                                            end
                                        end

                                        %Save data
                                        for hr=1:8;eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);end

                                        %Compute daily average as 2am-11pm, with 2am listed as the following day because of UTC
                                        for hr=2:8;eval(['total=total+arrDOI' hours{hr} ';']);end
                                        total=total+arrDOI2amnextday;
                                        hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                    end
                                end
                            end
                        end
                    end
                end
                if strcmp(varlist{varsdes(variab)},'shum') %really only applicable for tempmoistness=0
                    for hr=1:8;eval(['totalwbt=totalwbt+totalwbt' hours{hr} ';']);end
                end
                if tempmoistness==0 %Regular tempevol
                    if varsdes(variab)==2
                        avgstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,10}=totalwbt/(hotdaysc*8); %10 is daily avg, 1-8 are standard hours
                        %dimensions of avgstempevol are variable|pressure level|cluster#|time(dailyavg,stdhour,&c)
                        for hr=1:8
                            eval(['avgstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,' num2str(hr) '}=totalwbt' hours{hr} '/hotdaysc;']);
                        end
                    else
                        avgstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,10}=total/(hotdaysc*8);
                        for hr=1:8
                            eval(['avgstempevol{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,' num2str(hr) '}=total' hours{hr} '/hotdaysc;']);
                        end
                    end
                    hotdayscvec{2,firstday+1}=hotdaysc;
                else %Splitting into moisture categories
                    for relmoist=1:2 %1 is very moist, 2 is less moist
                        hotdaysctu=eval(['hotdaysf' num2str(firstday) 'm' num2str(relmoist) ';']);
                        if varsdes(variab)==2
                            %dimensions of avgstempmoistness are variable|pressure level|cluster#|time(dailyavg,stdhour,&c)|moistcateg
                            tempsum=0;
                            for hr=1:8
                                eval(['avgstempmoistness{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,' num2str(hr) ',' num2str(relmoist)...
                                    '}=totalwbt' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) '/hotdaysctu;']);
                                tempsum=tempsum+eval(['totalwbt' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) '/hotdaysctu;']);
                            end
                            avgstempmoistness{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,10,relmoist}=tempsum/8;
                        else
                            tempsum=0;
                            for hr=1:8
                                eval(['avgstempmoistness{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,' num2str(hr) ',' num2str(relmoist)...
                                    '}=total' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) '/hotdaysctu;']);
                                tempsum=tempsum+eval(['total' hours{hr} num2str(relmoist) 'f' num2str(firstday+1) '/hotdaysctu;']);
                            end
                            avgstempmoistness{varsdes(variab),presleveliw(varsdes(variab)),firstday+fdo,10,relmoist}=tempsum/8;
                        end
                    end
                    hotdayscvec{2,firstday+1}=hotdaysc;
                end
            end
            if cutofflength~=0 && shortonly==1
                if tempmoistness==1
                    avgstempmoistnessso=avgstempmoistness;
                    save(strcat(savedvardir,'computeflexibleclusterstempmoistness'),'avgstempmoistnessso','-append');
                else
                    avgstempevolso=avgstempevol;
                    save(strcat(savedvardir,'computeflexibleclusterstempevol'),'avgstempevolso','-append');
                    
                end
            elseif cutofflength~=0 && shortonly==0
                if tempmoistness==1
                    avgstempmoistnesslo=avgstempmoistness;
                    save(strcat(savedvardir,'computeflexibleclusterstempmoistness'),'avgstempmoistnesslo','-append');
                else
                    avgstempevollo=avgstempevol;
                    save(strcat(savedvardir,'computeflexibleclusterstempevol'),'avgstempevollo','-append');
                end
            else
                if tempmoistness==1
                    avgstempmoistnessall=avgstempmoistness;
                    save(strcat(savedvardir,'computeflexibleclusterstempmoistness'),'avgstempmoistnessall','-append');
                else
                    avgstempevolall=avgstempevol;
                    save(strcat(savedvardir,'computeflexibleclusterstempevol'),'avgstempevolall','-append');
                end
            end
            disp(clock);
        end
    end
    if seasonality==1 %here firstday is preset to 99
        disp(clock);avgsseasonality={};
        for season=seasiwf:seasiwl %(May-)Jun, Jul, Aug(-Sep)
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    adj=0;scalarvar=0;
                end
                total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
                for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                hotdaysc=0;hoteventsc=0;
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
                            %If it does, get the data for its hours -- compute daily average as the
                            %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                            %because of the EDT-UTC offset
                            for daysofhw=1:2 %look at first & last days both
                                for row=1:size(plotdays{rb,3,season,daysofhw},1)
                                    if plotdays{rb,3,season,daysofhw}(row,2)==year && plotdays{rb,3,season,daysofhw}(row,1)>=curmonstart...
                                            && plotdays{rb,3,season,daysofhw}(row,1)<curmonstart+curmonlen
                                        dayinmonth=plotdays{rb,3,season,daysofhw}(row,1)-curmonstart+1;disp(dayinmonth);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            lastdayofmonth=0;
                                        else
                                            lastdayofmonth=1;
                                        end
                                        %Just load in the files needed
                                        curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                        if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                            prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                            if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                        end

                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                        %Compute WBT from T and RH (see average-computation loop above for details)
                                        if strcmp(varlist{varsdes(variab)},'shum')
                                            for hr=1:8
                                                arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                                arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
                                                %Save data
                                                eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;']);
                                            end
                                        end
                                        %Save data
                                        %Compute daily average as 2am-11pm,
                                        %with 2am listed as the following day because of UTC time difference
                                        for hr=1:8
                                            eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);
                                        end
                                        for hr=2:8;eval(['total=total+arrDOI' hours{hr} ';']);end
                                        total=total+arrDOI2amnextday;

                                        hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                    end
                                end
                            end
                        end
                    end
                end
                if strcmp(varlist{varsdes(variab)},'shum')
                    for hr=1:8;eval(['totalwbt=totalwbt+totalwbt' hours{hr} ';']);end
                end
                %Dimensions of avgsseasonality are variable|pressure level|season|time(dailyavg or stdhour)
                if varsdes(variab)==2
                    avgsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,10}=totalwbt/(hotdaysc*8); %10 is daily avg, 1-8 are standard hours
                    for hr=1:8
                        eval(['avgsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,' num2str(hr) '}=totalwbt' hours{hr} '/hotdaysc;']);
                    end
                else
                    avgsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,10}=total/(hotdaysc*8);
                    for hr=1:8
                        eval(['avgsseasonality{varsdes(variab),presleveliw(varsdes(variab)),season,' num2str(hr) '}=total' hours{hr} '/hotdaysc;']);
                    end
                end
                hotdayscvec{3,season}=hotdaysc;
            end
        end
        disp(clock);save(strcat(savedvardir,'computeflexibleclustersseasonality'),'avgsseasonality');
    end
    if diurnality==1 %here firstday is preset to 99
        disp(clock);%avgsdiurnality={};
        for variab=viwf:viwl
            prevArr={};
            if strcmp(varlist{varsdes(variab)},'air')
                adj=273.15;scalarvar=1;
            elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                adj=0;scalarvar=1;
            elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                adj=0;scalarvar=0;
            end
            total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
            for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
            for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
            hotdaysc=0;hoteventsc=0;
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
                        %If it does, get the data for its hours --
                        %noting that 8pm and 11pm are located under the following day's heading because of the EDT-UTC offset
                        for daysofhw=1:2 %look at first & last days both
                            for row=1:size(plotdays{rb,4,daysofhw},1)
                                if plotdays{rb,4,daysofhw}(row,2)==year &&...
                                        plotdays{rb,4,daysofhw}(row,1)>=curmonstart...
                                        && plotdays{rb,4,daysofhw}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{rb,4,daysofhw}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                    if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                    if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                        prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                        if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                    end

                                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                        else
                                            eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                        end
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        for hr=1:8
                                            arrDOIthishr=eval(['arrDOI' hours{hr} ';']);
                                            arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                                            arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
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
            hotdayscvec{4,1}=hotdaysc;
        end
        disp(clock);save(strcat(savedvardir,'computeflexibleclustersdiurnality'),'avgsdiurnality');
    end
    if seasonalitydiurnality==1 %here firstday is preset to 99
        disp(clock);%avgsseasdiurn={};
        for season=seasiwf:seasiwl %(May-)Jun, Jul, Aug(-Sep)
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    adj=0;scalarvar=0;
                end
                total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
                for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                hotdaysc=0;hoteventsc=0;
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
                            %If it does, get the data for its hours -- compute daily average as the
                            %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                            %because of the EDT-UTC offset
                            %for daysofhw=1:2 %look at first & last days both
                                for row=1:size(plotdays{rb,3,season},1)
                                    if plotdays{rb,3,season}(row,2)==year && plotdays{rb,3,season}(row,1)>=curmonstart...
                                            && plotdays{rb,3,season}(row,1)<curmonstart+curmonlen
                                        dayinmonth=plotdays{rb,3,season}(row,1)-curmonstart+1;disp(dayinmonth);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            lastdayofmonth=0;
                                        else
                                            lastdayofmonth=1;
                                        end
                                        %Just load in the files needed
                                        curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                        if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                            prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                            if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                        end

                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                        %Compute WBT from T and RH (see average-computation loop above for details)
                                        if strcmp(varlist{varsdes(variab)},'shum')
                                            for hr=1:8
                                                arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                                arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
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
                            %end
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
                hotdayscvec{5,season}=hotdaysc;
            end
        end
        disp(clock);save(strcat(savedvardir,'computeflexibleclustersseasdiurn'),'avgsseasdiurn');
    end
    if moistness==1 %here firstday is preset to 99
        disp(clock);avgsmoistness={};
        for relmoist=1:2 %very moist & not-so-moist heat waves
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    adj=0;scalarvar=0;
                end
                total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
                for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                hotdaysc=0;hoteventsc=0;
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
                            %If it does, get the data for its hours --
                            %noting that 8pm and 11pm are located under the following day's heading because of the EDT-UTC offset
                            for row=1:size(plotdays{rb,6,relmoist},1)
                                if plotdays{rb,6,relmoist}(row,2)==year &&...
                                        plotdays{rb,6,relmoist}(row,1)>=curmonstart...
                                        && plotdays{rb,6,relmoist}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{rb,6,relmoist}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                    if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                    if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                        prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                        if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                    end

                                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                        else
                                            eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                        end
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        for hr=1:8
                                            arrDOIthishr=eval(['arrDOI' hours{hr} ';']);
                                            arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                                            arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
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
                %Assign hourly sums directly to holding array
                %Dimensions of avgsmoistness are variable|pressure level|moist category|stdhour
                if varsdes(variab)==2
                    for hr=1:size(hourstodo,1) %not interested in all the hours
                        eval(['avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,hourstodo(hr)}=totalwbt' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                else
                    for hr=1:size(hourstodo,1)
                        eval(['avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,hourstodo(hr)}=total' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                end
                %Daily average from hours
                tempsum=0;
                for i=1:size(hourstodo,1)
                    tempsum=tempsum+eval('avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,hourstodo(i)}');
                end
                avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,10}=tempsum/8;
                disp('line 1670');disp(max(max(avgsmoistness{varsdes(variab),presleveliw(varsdes(variab)),relmoist,10})));
                hotdayscvec{6,relmoist}=hotdaysc;
            end
        end
        disp(clock);save(strcat(savedvardir,'computeflexibleclustersmoistness'),'avgsmoistness');
    end
end

%Essentially like the flexibleclusters loops but specialized for the
%bottom-up clusters (based on local conditions rather than e.g. large-scale pressure patterns)
if computeusebottomupclusters==1
    disp(clock);
    %First, need to define a plotdays with the heat-wave days broken out by cluster
    if redefineplotdays==1
        cl1c=1;cl2c=1;cl3c=1;cl4c=1;cl5c=1;cl6c=1;cl7c=1;
        for i=1:size(idx,1) %i=1 is first day 1, i=2 is last day 1, i=3 is first day 2, etc
            numhw=round(i/2);
            if idx(i)==1 %this day belongs to cluster 1
                if rem(i,2)==1 %a first day
                    plotdays{10,1}(cl1c,1)=reghwbyTstarts(numhw,1);plotdays{10,1}(cl1c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,1}(cl1c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,1}(cl1c,2)=reghwbyTstarts(numhw,2);
                end
                cl1c=cl1c+1;
            elseif idx(i)==2 %cluster 2
                if rem(i,2)==1 %a first day
                    plotdays{10,2}(cl2c,1)=reghwbyTstarts(numhw,1);plotdays{10,2}(cl2c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,2}(cl2c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,2}(cl2c,2)=reghwbyTstarts(numhw,2);
                end
                cl2c=cl2c+1;
            elseif idx(i)==3 %cluster 3
                if rem(i,2)==1 %a first day
                    plotdays{10,3}(cl3c,1)=reghwbyTstarts(numhw,1);plotdays{10,3}(cl3c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,3}(cl3c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,3}(cl3c,2)=reghwbyTstarts(numhw,2);
                end
                cl3c=cl3c+1;
           elseif idx(i)==4 %cluster 4
                if rem(i,2)==1 %a first day
                    plotdays{10,4}(cl4c,1)=reghwbyTstarts(numhw,1);plotdays{10,4}(cl4c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,4}(cl4c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,4}(cl4c,2)=reghwbyTstarts(numhw,2);
                end
                cl4c=cl4c+1;
            elseif idx(i)==5 %cluster 5
                if rem(i,2)==1 %a first day
                    plotdays{10,5}(cl5c,1)=reghwbyTstarts(numhw,1);plotdays{10,5}(cl5c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,5}(cl5c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,5}(cl5c,2)=reghwbyTstarts(numhw,2);
                end
                cl5c=cl5c+1;
            elseif idx(i)==6 %cluster 6
                if rem(i,2)==1 %a first day
                    plotdays{10,6}(cl6c,1)=reghwbyTstarts(numhw,1);plotdays{10,6}(cl6c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,6}(cl6c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,6}(cl6c,2)=reghwbyTstarts(numhw,2);
                end
                cl6c=cl6c+1;
            elseif idx(i)==7 %cluster 7
                if rem(i,2)==1 %a first day
                    plotdays{10,7}(cl7c,1)=reghwbyTstarts(numhw,1);plotdays{10,7}(cl7c,2)=reghwbyTstarts(numhw,2);
                else %a last day
                    plotdays{10,7}(cl7c,1)=reghwbyTstarts(numhw,1)+reghwbyTstarts(numhw,3)-1;
                    plotdays{10,7}(cl7c,2)=reghwbyTstarts(numhw,2);
                end
                cl7c=cl7c+1;
            end
        end
    end
    
    %Now, actually read in the data to make the composites
    if redefinecomposites==1
        avgsbottomup={};
        %for clustc=1:numclust %composites for numclust (typically =7) heat waves
        for clustc=4:5
            for variab=viwf:viwl
                prevArr={};
                if strcmp(varlist{varsdes(variab)},'air')
                    adj=273.15;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'shum') || strcmp(varlist{varsdes(variab)},'hgt')
                    adj=0;scalarvar=1;
                elseif strcmp(varlist{varsdes(variab)},'uwnd') || strcmp(varlist{varsdes(variab)},'vwnd')
                    adj=0;scalarvar=0;
                end
                total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
                for hr=1:8;eval(['total' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
                hotdaysc=0;hoteventsc=0;
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
                            for row=1:size(plotdays{10,clustc},1)
                                if plotdays{10,clustc}(row,2)==year &&...
                                        plotdays{10,clustc}(row,1)>=curmonstart...
                                        && plotdays{10,clustc}(row,1)<curmonstart+curmonlen
                                    dayinmonth=plotdays{10,clustc}(row,1)-curmonstart+1;disp(dayinmonth);
                                    if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                        lastdayofmonth=0;
                                    else
                                        lastdayofmonth=1;
                                    end
                                    %Just load in the files needed
                                    curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                                    if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                                    if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                                        prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                                        if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                                    end

                                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(variab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(variab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                        else
                                            eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(variab)),1*8+ ' num2str(hr-8) ')-adj;']);
                                        end
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        for hr=1:8
                                            arrDOIthishr=eval(['arrDOI' hours{hr} ';']);
                                            arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                                            arrDOIwbt=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);
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
                %Assign hourly sums directly to holding array
                %Dimensions of avgsbottomup are variable|pressure level|cluster number|stdhour
                if varsdes(variab)==2
                    for hr=1:size(hourstodo,1) %not interested in all the hours, just some of them
                        eval(['avgsbottomup{varsdes(variab),presleveliw(varsdes(variab)),clustc,hourstodo(hr)}=totalwbt' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                else
                    for hr=1:size(hourstodo,1)
                        eval(['avgsbottomup{varsdes(variab),presleveliw(varsdes(variab)),clustc,hourstodo(hr)}=total' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                end
                %Daily average from hours
                tempsum=0;
                for i=1:size(hourstodo,1)
                    tempsum=tempsum+eval('avgsbottomup{varsdes(variab),presleveliw(varsdes(variab)),clustc,hourstodo(i)}');
                end
                avgsbottomup{varsdes(variab),presleveliw(varsdes(variab)),clustc,10}=tempsum/8;
                hotdayscvec{10,clustc}=hotdaysc;
            end
        end
        str=sprintf('avgsbottomupk%dhp%0.0f2',k,highpct*1000);
        save(sprintf(strcat(savedvardir,'%s',str)),'avgsbottomup');
    end
    disp(clock);
end
if bottomupclusters==1;for cl=1:k;hotdayscvec{10,cl}=size(plotdays{10,cl},1);end;end


%Save cluster composites that were just calculated into arrays for semi-permanent storage
%These all use daily-avg data unless otherwise specified
%First, decide what version of tempevol to use, according to whether heat waves of all lengths, short lengths, or long lengths are being analyzed
if shortonly==1 && cutofflength~=0 %analyze short heat waves only
    exist avgstempevolshortonly;
    if ans==1;avgstempevol=avgstempevolshortonly;end
elseif shortonly==0 && cutofflength~=0 %analyze long heat waves only
    exist avgstempevollongonly;
    if ans==1;avgstempevol=avgstempevollongonly;end
else %analyze heat waves of all lengths
    %avgstempevol=avgstempevolnormal; %arrays are already computed & saved for these
end
if savetotalsintoarrays==1
    for variab=viwf:viwl
        if strcmp(varlist(varsdes(variab)),'air')
            %Data for all days in each bottom-up cluster
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif bottomupclusters==1
                for cl=1:k;eval(['arr1f99rb1pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) 'su' num2str(stnsused) '=avgsbottomup{1,presleveliw(1),cl,10};']);end
                %Effectively hide the stnsused part for the purposes of fitting the
                %bottomupclusters arrays nicely into the plotting loop along with the others
                for cl=1:k;eval(['arr1f99rb1pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl)...
                    '=arr1f99rb1pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) 'su' num2str(stnsused) ';']);end
            elseif allhwdays==1 %a cluster composed of all the days (i.e. effectively no clustering at all)
                for cl=clmin:clmax
                    eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=avgsallhwdays{1,presleveliw(1),10};']);
                end
            %Data for the 4 temporal-evolution 'clusters'
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;
                    if tempmoistness==0
                        eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgstempevol{1,presleveliw(1),' num2str(cl) ',10};']);
                    elseif tempmoistness==1
                        for moistcateg=1:2
                            eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1)))...
                                'cl' num2str(cl+30+(moistcateg-1)*10) '='...
                            'avgstempmoistness{1,presleveliw(1),' num2str(cl) ',10,moistcateg};']);
                        end
                    end
                end
            %Data for the 3 seasonality 'clusters'
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsseasonality{1,presleveliw(1),' num2str(season) ',10};']);
                end
            %Data for the 4 diurnality 'clusters'
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{1,presleveliw(1),' num2str(actualhour) '};']);
                end
            %Data for joint seasonality-diurnality 'clusters'
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{1,presleveliw(1),' num2str(season) ',' num2str(actualhour) '};']);
                end
            %Data for the 2 moistness 'clusters'
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63; %moistcateg 1 is very moist, 2 is less moist
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '='...
                        'avgsmoistness{1,presleveliw(1),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                %Also compute & save daily averages for the 2 clusters
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr1f99rb1pl1000cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr1f99rb1pl1000cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr1f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl599=tempdailyavg;']);
            end
            %Also make arrays with data from all days in a specific cluster regardless of whether they are first or last
            %Weight cluster average by its composition of first and last days, rather than a straight average of the averages
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr1f99rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(1))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'shum') %uses shum but output is WBT
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=totalwbtcl' num2str(cl) ';']);end
                cl=99;eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=totalwbtcl' num2str(cl) ';']);
            elseif bottomupclusters==1
                for cl=1:k;eval(['arr2f99rb1pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) 'su' num2str(stnsused) '=avgsbottomup{2,presleveliw(2),cl,10};']);end
                for cl=1:k;eval(['arr2f99rb1pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl)...
                    '=arr2f99rb1pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) 'su' num2str(stnsused) ';']);end
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=avgsallhwdays{2,presleveliw(2),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;
                    if tempmoistness==0
                        eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgstempevol{2,presleveliw(2),' num2str(cl) ',10};']);
                    elseif tempmoistness==1
                        for moistcateg=1:2
                            eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl+30+(moistcateg-1)*10) '='...
                            'avgstempmoistness{2,presleveliw(2),' num2str(cl) ',10,moistcateg};']);
                        end
                    end
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsseasonality{2,presleveliw(2),' num2str(season) ',10};']);
                end
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{2,presleveliw(2),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    disp('line 1540');disp(season);disp(actualhour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{2,presleveliw(2),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '='...
                        'avgsmoistness{2,presleveliw(2),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr2f99rb1pl1000cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr2f99rb1pl1000cl' num2str(i)]);end;tempdailyavg=tempdailyavg/8;
                eval(['arr2f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalwbtfirstcl1))~=0 && max(max(totalwbtlastcl1))~=0
                    for cl=1:k
                        eval(['arr2f99rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(2))) 'cl' num2str(cl) '=(totalwbtfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totalwbtlastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'hgt')
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif bottomupclusters==1
                for cl=1:k;eval(['arr3f99rb1pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) 'su' num2str(stnsused) '=avgsbottomup{3,presleveliw(3),cl,10};']);end
                for cl=1:k;eval(['arr3f99rb1pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl)...
                    '=arr3f99rb1pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) 'su' num2str(stnsused) ';']);end
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=avgsallhwdays{3,presleveliw(3),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;
                    if tempmoistness==0
                        eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgstempevol{3,presleveliw(3),' num2str(cl) ',10};']);
                    elseif tempmoistness==1
                        for moistcateg=1:2
                            eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl+30+(moistcateg-1)*10) '='...
                            'avgstempmoistness{3,presleveliw(3),' num2str(cl) ',10,moistcateg};']);
                        end
                    end
                end
            elseif seasonality==1 %all with firstday=99
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsseasonality{3,presleveliw(3),' num2str(season) ',10};']);
                end
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{3,presleveliw(3),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{3,presleveliw(3),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '='...
                        'avgsmoistness{3,presleveliw(3),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr3f99rb1pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(i)]);end;
                tempdailyavg=tempdailyavg/8;
                eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr3f99rb1pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(i)]);end;
                tempdailyavg=tempdailyavg/8;
                eval(['arr3f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr3f99rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(3))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'uwnd')
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif bottomupclusters==1
                for cl=1:k;eval(['arr4f99rb1pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) 'su' num2str(stnsused) '=avgsbottomup{4,presleveliw(4),cl,10};']);end
                for cl=1:k;eval(['arr4f99rb1pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl)...
                    '=arr4f99rb1pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) 'su' num2str(stnsused) ';']);end
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=avgsallhwdays{4,presleveliw(4),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;
                    if tempmoistness==0
                        eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgstempevol{4,presleveliw(4),' num2str(cl) ',10};']);
                    elseif tempmoistness==1
                        for moistcateg=1:2
                            eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl+30+(moistcateg-1)*10) '='...
                            'avgstempmoistness{4,presleveliw(4),' num2str(cl) ',10,moistcateg};']);
                        end
                    end
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsseasonality{4,presleveliw(4),' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                %'avgsseasonality{4,presleveliw(4),' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{4,presleveliw(4),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{4,presleveliw(4),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '='...
                        'avgsmoistness{4,presleveliw(4),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr4f99rb1pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(i)]);end;
                tempdailyavg=tempdailyavg/8;
                eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr4f99rb1pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(i)]);end;
                tempdailyavg=tempdailyavg/8;
                eval(['arr4f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr4f99rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'vwnd')
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif bottomupclusters==1
                for cl=1:k;eval(['arr5f99rb1pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) 'su' num2str(stnsused) '=avgsbottomup{5,presleveliw(5),cl,10};']);end
                for cl=1:k;eval(['arr5f99rb1pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl)...
                    '=arr5f99rb1pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) 'su' num2str(stnsused) ';']);end
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=avgsallhwdays{5,presleveliw(5),10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;
                    if tempmoistness==0
                        eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgstempevol{5,presleveliw(5),' num2str(cl) ',10};']);
                    elseif tempmoistness==1
                        for moistcateg=1:2
                            eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl+30+(moistcateg-1)*10) '='...
                            'avgstempmoistness{5,presleveliw(5),' num2str(cl) ',10,moistcateg};']);
                        end
                    end
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsseasonality{5,presleveliw(5),' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                %'avgsseasonality{5,presleveliw(5),' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsdiurnality{5,presleveliw(5),' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsseasdiurn{5,presleveliw(5),' num2str(season) ',' num2str(actualhour) '};']);
                end
            elseif moistness==1
                for cl=clmin:clmax
                    moistcateg=round2(cl/8+0.5,1,'ceil')-63;
                    hour=rem(cl+4,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '='...
                        'avgsmoistness{5,presleveliw(5),' num2str(moistcateg) ',' num2str(actualhour) '};']);
                end
                tempdailyavg=0;for i=501:508;tempdailyavg=tempdailyavg+eval(['arr5f99rb1pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(i)]);end;
                tempdailyavg=tempdailyavg/8;
                eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl549=tempdailyavg;']);
                tempdailyavg=0;for i=509:516;tempdailyavg=tempdailyavg+eval(['arr5f99rb1pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(i)]);end;
                tempdailyavg=tempdailyavg/8;
                eval(['arr5f' num2str(firstday) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl599=tempdailyavg;']);
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr5f99rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(cl) '=(totalfirstcl'...
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


%Set up desired difference plots here (then have to manually select the
%appropriate code from the plotting loop below)
if setupdiffplots==1
    dojunseasdiurn=0;doaugseasdiurn=1;
    if seasonalitydiurnality==1
        if dojunseasdiurn==1 %Jun 8PM - Jun 11AM
            diffarrvar2=arr2f99rb1pl1000cl401-arr2f99rb1pl1000cl406; 
            diffarrvar3=arr3f99rb1pl1000cl401-arr3f99rb1pl1000cl406;
            diffarrvar4=arr4f99rb1pl1000cl401-arr4f99rb1pl1000cl406;
            diffarrvar5=arr5f99rb1pl1000cl401-arr5f99rb1pl1000cl406;
            overlay=1;overlaynum=3;underlaynum=2;overlaynum2=4;
            caxisminfordiff=round(min(min(diffarrvar2)));
            caxismaxfordiff=round(max(max(diffarrvar2)));
            showoverlaycompositeplots=1;anomfromjjaavg=0;
            clust1=401;clust2=406;
        elseif doaugseasdiurn==1 %Aug 8PM - Aug 11AM
            diffarrvar2=arr2f99rb1pl1000cl417-arr2f99rb1pl1000cl422; 
            diffarrvar3=arr3f99rb1pl1000cl417-arr3f99rb1pl1000cl422;
            diffarrvar4=arr4f99rb1pl1000cl417-arr4f99rb1pl1000cl422;
            diffarrvar5=arr5f99rb1pl1000cl417-arr5f99rb1pl1000cl422;
            overlay=1;overlaynum=3;underlaynum=2;overlaynum2=4;
            caxisminfordiff=round(min(min(diffarrvar2)));
            caxismaxfordiff=round(max(max(diffarrvar2)));
            showoverlaycompositeplots=1;anomfromjjaavg=0;
            clust1=417;clust2=422;
        end
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
    
    %Make a couple necessary corrections
    if tempevol~=1;fdo=clustdes-99;end %clustdes-fdo must be 99 in these cases (to match firstday)
    %If desired part of hotdayscvec does not exist, assume that stricter definition of heat waves is being referred to
    exist hotdayscvec;
    reducsizereghwbyTstarts=0;
    for i=1:size(reghwbyTstarts,1) %the number of heat waves within the time period currently being analyzed
        if reghwbyTstarts(i,2)>=yeariwf && reghwbyTstarts(i,2)<=yeariwl
            reducsizereghwbyTstarts=reducsizereghwbyTstarts+1;
        end
    end
    if ans==0
        hotdayscvec{fcc,ursi}=reducsizereghwbyTstarts;
    elseif ans==1
        %if hotdayscvec{fcc,ursi}==0
            hotdayscvec{fcc,ursi}=reducsizereghwbyTstarts;
        %end
    end
    %For tempmoistness, use hwcounts instad of hotdayscvec
    if tempmoistness==1
        if ursi>=31 && ursi<=34 %very moist heat wave
            hotdayscvec{fcc,ursi}=hwcounts{1,6,1};
        elseif ursi>=41 && ursi<=44 %less-moist heat wave
            hotdayscvec{fcc,ursi}=hwcounts{1,6,2};
        end
    end
    
    %Since clustdes numbers referring to tempmoistness clusters are
    %non-sequential, adjust fdo appropriately
    if clustdes>=131 && clustdes<=134
        fdo=131;
    elseif clustdes>=141 && clustdes<=144
        fdo=141;
    end
    
    
    %%Make plots themselves%%
    if shownonoverlaycompositeplots==1
        for variab=viwf:viwl
            if anomfromjjaavg==1
                data={narrlats;narrlons;...
                eval(['arr' num2str(varsdes(variab)) 'f' num2str(clustdes-fdo) 'rb' num2str(rb)...
                'pl' num2str(preslevels(presleveliw(varsdes(variab)))) 'cl' num2str(clustdes)])-...
                eval(['narravgjja' char(varlist2(varsdes(variab)))])};
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'mystep';cstep(varsdes(variab));...
                'overlaynow';0;'anomavg';anomavg2{anomfromjjaavg+1}};
            else
                data={narrlats;narrlons;...
                eval(['arr' num2str(varsdes(variab)) 'f' num2str(clustdes-fdo) 'rb' num2str(rb)...
                'pl' num2str(preslevels(presleveliw(varsdes(variab)))) 'cl' num2str(clustdes)])};
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'mystep';cstep(varsdes(variab));...
                'overlaynow';0;'anomavg';anomavg2{anomfromjjaavg+1}};
            end
            %disp(max(max(data{3})));
            plotModelData(data,mapregion,vararginnew,'NARR');
            if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
            title(sprintf('%s %s %s %s %d %s %s in the NYC Area%s',anomavg{anomfromjjaavg+1},...
                timespanremark{timespanlb},char(varlistnames{varsdes(variab)}),dayremark,hotdayscvec{fcc,ursi},...
                clustremark{clustdes,1},hwremark,clustremark{clustdes,2}),'FontSize',18,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarr%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(variab)},...
                    varlist3{rb},clustlb,mapregion);
        end
    end
    if overlay==1 && showoverlaycompositeplots==1 %Make single or double overlay
        if overlaynum==4 %wind
            if strcmp(varlist(varsdes(size(varsdes,1))),'vwnd') %if only going to uwnd, don't have enough to plot
                if anomfromjjaavg==1
                    overlaydata={narrlats;narrlons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)])-...
                        eval(['narravgjjauwnd' num2str(preslevels(presleveliw(4)))]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])-...
                        eval(['narravgjjavwnd' num2str(preslevels(presleveliw(5)))])};
                    underlaydata={narrlats;narrlons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb)...
                        'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])...
                        -eval(['narravgjja' char(varlist2(underlaynum))])};
                else
                    overlaydata={narrlats;narrlons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])}; %wind
                    underlaydata={narrlats;narrlons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb)...
                        'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])};
                end
                vararginnew={'variable';'wind';'contour';contouropt;'mystep';cstep(2);'plotCountries';1;...
                    'caxismin';caxismin(underlaynum);'caxismax';caxismax(underlaynum);...
                    'vectorData';overlaydata;'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata;'anomavg';anomavg2{anomfromjjaavg+1}};
                plotModelData(overlaydata,mapregion,vararginnew,'NARR');figc=figc+1;
                %Add title to newly-made figure
                phrpart1=sprintf('%s %s%d-hPa Wind and %s%s   .',anomavg{anomfromjjaavg+1},...
                    timespanremark{timespanlb},preslevels(presleveliw(4)),prespr{underlaynum},char(varlistnames{underlaynum}));
                if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
                phrpart2=sprintf('%s %d%s NYC-Area %s%s   .',dayremark,hotdayscvec{fcc,ursi},clustremark{clustdes,1},hwremark,clustremark{clustdes,2});
                title({phrpart1,phrpart2},'FontSize',18,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},varlist3{varsdes(2)},...
                    varlist3{rb},clustlb,mapregion);
            end
        elseif overlaynum==1 || overlaynum==2 || overlaynum==3 %scalar overlays
            if anomfromjjaavg==1 %Plot anomalies
                overlaydata={narrlats;narrlons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(overlaynum))) 'cl' num2str(clustdes)])-...
                    eval(['narravgjja' char(varlist2(overlaynum))])};
                underlaydata={narrlats;narrlons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])-...
                    eval(['narravgjja' char(varlist2(underlaynum))])};
                if clusteranomfromavg==1 %This cluster's anomalies with respect to both the JJA avg and the all-cluster avg
                    overlaydata{3}=overlaydata{3}-(eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb)...
                        'pl' num2str(preslevels(presleveliw(overlaynum))) 'cl0'])-eval(['narravgjja' char(varlist2(overlaynum))]));
                    underlaydata{3}=underlaydata{3}-(eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb)...
                        'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl0'])-eval(['narravgjja' char(varlist2(underlaynum))]));
                end
                if overlaynum2~=0 %Double overlay (contours+barbs)
                    overlaydata2={narrlats;narrlons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)])-...
                        eval(['narravgjjauwnd' num2str(preslevels(presleveliw(4)))]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])-...
                        eval(['narravgjjavwnd' num2str(preslevels(presleveliw(5)))])};
                    if clusteranomfromavg==1 
                        overlaydata2{3}=overlaydata2{3}-...
                            (eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl0'])-...
                            eval(['narravgjjauwnd' num2str(preslevels(presleveliw(4)))]));
                        overlaydata2{4}=overlaydata2{4}-...
                            (eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl0'])-...
                            eval(['narravgjjavwnd' num2str(preslevels(presleveliw(5)))]));
                    end
                end
            else %Plot actual values
                overlaydata={narrlats;narrlons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(overlaynum))) 'cl' num2str(clustdes)])};
                underlaydata={narrlats;narrlons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(underlaynum))) 'cl' num2str(clustdes)])};
                if overlaynum2~=0
                    overlaydata2={narrlats;narrlons;eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(4))) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(rb) 'pl' num2str(preslevels(presleveliw(5))) 'cl' num2str(clustdes)])};
                end
            end
            
            %underlaydata={lats;lons;(arr2f99rb1cl513-narravgjjawbt)-(arr2f99rb1cl505-narravgjjawbt)};
            %overlaydata={lats;lons;(arr3f99rb1cl513-narravgjjagh)-(arr3f99rb1cl505-narravgjjagh)};
            %overlaydata2={lats;lons;(arr4f99rb1cl513-narravgjjauwnd850)-(arr4f99rb1cl505-narravgjjauwnd850);...
            %(arr5f99rb1cl513-narravgjjavwnd850)-(arr5f99rb1cl505-narravgjjavwnd850)};
            
            if overlaynum2~=0 %Double overlay, with one overlayvariable as contours and then wind as barbs
                %Assuming that underlaynum is T or WBT
                vararginnew={'variable';'temperature';'contour';1;'mystep';cstep(underlaynum);'plotCountries';1;'caxismin';caxismin(underlaynum);...
                'caxismax';caxismax(underlaynum);'vectorData';overlaydata2;'overlaynow';overlay;'overlayvariable';overlayvar;...
                'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata;'anomavg';anomavg2{anomfromjjaavg+1}};
            else %Single overlay
                vararginnew={'variable';'temperature';'contour';1;'mystep';cstep(underlaynum);'plotCountries';1;...
                'caxismin';caxismin(underlaynum);'caxismax';caxismax(underlaynum);'overlaynow';overlay;'overlayvariable';overlayvar;...
                'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata;'anomavg';anomavg2{anomfromjjaavg+1}};
            end
            %Actually do the plotting
            plotModelData(overlaydata,mapregion,vararginnew,'NARR');figc=figc+1;
            
            
            %Add title to newly-made figure and also create filename for saving
            if overlaynum2==0
                if diurnality==1;hotdayscdiurn=round2(hotdayscvec{fcc,ursi}/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
                if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
                if strcmp(mapregion,'north-america')
                    phrpart1=sprintf('%s %s %s and %s%s   .',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                        char(varlistnames{overlaynum}),prespr{underlaynum},char(varlistnames{underlaynum}));
                    phrpart2=sprintf('%s %d %s NYC-Area %s%s   .',dayremark,hotdayscvec{fcc,ursi},clustremark{clustdes,1},hwremark,clustremark{clustdes,2});
                else
                    phrpart1=sprintf('%s %s %s and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                        char(varlistnames{overlaynum}),prespr{underlaynum},char(varlistnames{underlaynum}));
                    phrpart2=sprintf('%s %d %s NYC-Area %s%s',dayremark,hotdayscvec{fcc,ursi},clustremark{clustdes,1},hwremark,clustremark{clustdes,2});
                end
                title({phrpart1,phrpart2},'FontSize',18,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(underlaynum)},...
                    varlist3{rb},clustlb,mapregion);
            else
                if diurnality==1;hotdayscdiurn=round2(hotdayscvec{fcc,ursi}/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
                if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
                if strcmp(mapregion,'north-america')
                    phrpart1=sprintf('%s %s %s, %s, and %s%s   .',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                        char(varlistnames{overlaynum}),char(varlistnames{overlaynum2}),prespr{underlaynum},char(varlistnames{underlaynum}));
                    phrpart2=sprintf('%s %d %s NYC-Area %s%s%s   .',dayremark,hotdayscvec{fcc,ursi},clustremark{clustdes,1},hwremark,...
                        clustremark{clustdes,2},clustanom{clusteranomfromavg+1});
                else
                    phrpart1=sprintf('%s %s %s, %s, and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                        char(varlistnames{overlaynum}),char(varlistnames{overlaynum2}),prespr{underlaynum},char(varlistnames{underlaynum}));
                    phrpart2=sprintf('%s %d %s NYC-Area %s%s%s',dayremark,hotdayscvec{fcc,ursi},clustremark{clustdes,1},hwremark,...
                        clustremark{clustdes,2},clustanom{clusteranomfromavg+1});
                end
                title({phrpart1,phrpart2},'FontSize',18,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%sby%s%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{underlaynum},...
                    varlist3{3},varlist3{rb},clustlb,clanomlb,mapregion);
            end
        end
    end
    
    %Make difference plots if desired
    if showdifferenceplots==1
        underlaydata={narrlats;narrlons;eval(['diffarrvar' num2str(underlaynum)])};
        overlaydata={narrlats;narrlons;eval(['diffarrvar' num2str(overlaynum)])};
        if overlaynum2~=0;overlaydata2={narrlats;narrlons;diffarrvar4;diffarrvar5};end
        if overlaynum2~=0 %Double overlay, with one overlayvariable as contours and then wind as barbs
            %Assuming that underlaynum is T or WBT
            vararginnew={'variable';'temperature';'contour';1;'mystep';cstep(underlaynum);'plotCountries';1;'caxismin';caxisminfordiff;...
            'caxismax';caxismaxfordiff;'vectorData';overlaydata2;'overlaynow';overlay;'overlayvariable';overlayvar;...
            'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata;'anomavg';anomavg2{anomfromjjaavg+1}};
        else %Single overlay
            vararginnew={'variable';'temperature';'contour';1;'mystep';1;'plotCountries';1;...
            'caxismin';caxisminfordiff;'caxismax';caxismaxfordiff;'overlaynow';overlay;'overlayvariable';overlayvar;...
            'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata;'anomavg';anomavg2{anomfromjjaavg+1}};
        end
        clustlb=strcat('clust',num2str(clust1),'-',num2str(clust2));
        %Actually do the plotting
        plotModelData(overlaydata,mapregion,vararginnew,'NARR');figc=figc+1;
        if overlaynum2==0
            phrpart1=sprintf('%s %s %s and %s%s   .',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                char(varlistnames{overlaynum}),prespr{underlaynum},char(varlistnames{underlaynum}));
            if diurnality==1;hotdayscdiurn=round2(hotdayscvec{fcc,ursi}/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
            if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
            phrpart2=sprintf('%s %d NYC-Area %s, %s Minus %s   .',dayremark,hotdayscvec{fcc,ursi},hwremark,clustremark2{clust1},clustremark2{clust2});
            title({phrpart1,phrpart2},'FontSize',18,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiff%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(underlaynum)},...
                varlist3{rb},clustlb,mapregion);
        else
            phrpart1=sprintf('%s %s %s, %s, and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                char(varlistnames{overlaynum}),char(varlistnames{overlaynum2}),prespr{underlaynum},char(varlistnames{underlaynum}));
            if diurnality==1;hotdayscdiurn=round2(hotdayscvec{fcc,ursi}/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
            if strcmp(hwremark,'Heat Waves');elseif strcmp(hwremark,'Heat-Wave Days');dayremark='for';end
            phrpart2=sprintf('%s %d NYC-Area %s, %s Minus %s%s',dayremark,hotdayscvec{fcc,ursi},hwremark,...
                clustremark2{clust1},clustremark2{clust2},clustanom{clusteranomfromavg+1});
            title({phrpart1,phrpart2},'FontSize',18,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiff%s%s%sby%s%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{underlaynum},...
                varlist3{3},varlist3{rb},clustlb,clanomlb,mapregion);
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
        torwbtdiffarr={narrlats;narrlons;torwbtdiff};gpdiffarr={narrlats;narrlons;gpdiff};wnddiffarr={narrlats;narrlons;uwnddiff;vwnddiff};
        vararginnew={'variable';'temperature';'contour';contouropt;'plotCountries';1;'caxismethod';'regional10';...
            'vectorData';wnddiffarr;'overlaynow';1;'overlayvariable';'height';'underlayvariable';'temperature';...
            'datatooverlay';gpdiffarr;'datatounderlay';torwbtdiffarr;'anomavg';anomavg2{anomfromjjaavg+1}};
        plotModelData(gpdiffarr,mapregion,vararginnew,'NARR');
        
        %Add title and save figure
        if plotnum==1
            phrpart1=sprintf('%s, %s, and %s',varlistnames{1},varlistnames{2},varlistnames{3});
            phrpart2=sprintf('on Last Days vs. First Days of T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==2
            phrpart1=sprintf('%s, %s, and %s',varlistnames{2},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on Last Days vs. First Days of WBT-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==3
            phrpart1=sprintf('%s, %s, and %s',varlistnames{1},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==4
            phrpart1=sprintf('%s, %s, and %s',varlistnames{2},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==5
            phrpart1=sprintf('%s, %s, and %s',varlistnames{1},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindwbtvstrankedfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==6
            phrpart1=sprintf('%s, %s, and %s',varlistnames{2},varlistnames{4},varlistnames{3});
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
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
                data={narrlats;narrlons;hoteventsarrs{event,3};hoteventsarrs{event,4}};goplot=1;
                vararginnew={'variable';argname;'contour';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';data;'anomavg';anomavg2{anomfromjjaavg+1}};
            else %i.e. any scalar variable
                data={narrlats;narrlons;hoteventsarrs{event}};goplot=1;
                vararginnew={'variable';argname;'contour';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'anomavg';anomavg2{anomfromjjaavg+1}};
            end

            if goplot==1 
                [caxisrange,step,mycolormap]=plotModelData(data,mapregionsize1,vararginnew,'NARR');figc=figc+1;

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
                        winddirbyseason{stnc,season-5}(i,1)>0 && winddirbyseason{stnc,season-5}(i,1)<45 %NNE
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
            narrryear=year-yeariwf+1;
            if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
            for month=monthiwf:monthiwl
                fprintf('Pulling all available NARR data; current year and month are %d, %d\n',year,month);
                curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);

                curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(arealvariab)),year,month);
                if strcmp(varlist{varsdes(arealvariab)},'shum') %need to get T as well to be able to calc. WBT
                    %therefore 'prev' refers to variable ordering and not month ordering
                    prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                end

                for dayinmonth=1:curmonlen
                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                        else
                            eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(arealvariab)),1*8+ ' num2str(hr-8) ')-adj;']);
                        end
                    end
                    %Compute WBT from T and RH (see average-computation loop above for details)
                    if strcmp(varlist{varsdes(arealvariab)},'shum')
                        for hr=1:8
                            arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                            arrDOIprevthishr=eval(['prevArr{3}(:,:,presleveliw(varsdes(arealvariab)),dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                            eval(['arrDOI' hours{hr} '=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);']);
                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                arrDOIprevthishr=eval(['prevArr{3}(:,:,presleveliw(varsdes(arealvariab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-273.15;']); %T
                                eval(['arrDOI' hours{hr} 'nextday=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);']);
                            else
                                arrDOIprevthishr=eval(['prevArr{3}(:,:,presleveliw(varsdes(arealvariab)),1*8+ ' num2str(hr-8) ')-273.15;']); %T
                                eval(['arrDOI' hours{hr} 'nextday=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);']);
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
        for i=1:narrsz(1)
            for j=1:narrsz(2)
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
            narrryear=year-yeariwf+1;
            if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
            for month=monthiwf:monthiwl
                fprintf('Current year and month are %d, %d\n',year,month);
                curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);
                %Search through listing of region-wide heat-wave days to see if this month contains one of them
                %If it does, get the data for its hours -- compute daily average as the
                %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading because of the EDT-UTC offset
                for row=1:size(plotdays{rb,7},1)
                    if plotdays{rb,7}(row,2)==year && plotdays{rb,7}(row,1)>=curmonstart &&...
                            plotdays{rb,7}(row,1)<curmonstart+curmonlen
                        dayinmonth=plotdays{rb,7}(row,1)-curmonstart+1;disp(dayinmonth);
                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                            lastdayofmonth=0;
                        else
                            lastdayofmonth=1;
                        end
                        %Just load in the files needed
                        curArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month);
                        if lastdayofmonth==1;nextmonArr=getnarrdatabymonth(runningremotely,varlist(varsdes(variab)),year,month+1);end
                        if strcmp(varlist{varsdes(variab)},'shum') %need to get T as well to be able to calculate WBT
                            prevArr=getnarrdatabymonth(runningremotely,'air',year,month);
                            if lastdayofmonth==1;prevArrnextmon=getnarrdatabymonth(runningremotely,'air',year,month+1);end
                        end

                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,presleveliw(varsdes(arealvariab)),(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                            else
                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,presleveliw(varsdes(arealvariab)),1*8+ ' num2str(hr-8) ')-adj;']);
                            end
                        end
                        %Compute WBT from T and RH (see average-computation loop above for details)
                        if strcmp(varlist{varsdes(arealvariab)},'shum')
                            for hr=1:8
                                arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                eval(['arrDOI' hours{hr} '=calcwbtfromTandshum(arrDOIprevthishr,arrDOIthishr,1);']);
                            end
                        end
                            
                        %Compute daily average
                        %Then, put daily avg into an array for safekeeping
                        %so that empirical pdf can later be calculated
                        dailysum=0;
                        for hr=1:8;eval(['dailysum=dailysum+arrDOI' hours{hr} ';']);end


                        %Determine if this is the last day of a heat wave,
                        %and thus if the hw avg should be computed & stored
                        if row~=size(plotdays{rb,7},1)
                            if plotdays{rb,7}(row,1)~=plotdays{rb,7}(row+1,1)-1 ||...
                                plotdays{rb,7}(row,2)~=plotdays{rb,7}(row+1,2)
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
        save(strcat(savedvardir,'tqadvavgdailyhwvals.mat'),'avgdailyhwvals');
    end
    
    %Next, create a matrix of 1's (0's) for each heat wave representing
    %gridpoints where the variable of interest did (did not) exceed the local xth percentile
    if createexceedmatrix==1
        %exceedmatrix={};
        for eventc=1:hoteventsc %loop over the heat waves
            for i=1:narrsz(1)
                for j=1:narrsz(2)
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
        %Need to modify wnarrgridpts directly if a radius change is desired (e.g. to 500 km)
        [junk,landgridptlist]=wnarrgridpts(40.78,-73.97,0,1);

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
    end
    
    %Make plots
    if finishandplot==1
        %Plot WBT percentile for each event vs % of nearby gridpoints
        %exceeding the xth pct
        figure(figc);clf;figc=figc+1;
        %Against Observations
        %Could be valid if changed, but scorescomptotalhw is outdated and I
        %can't even remember exactly what it's measuring
        %scatter(scorescomptotalhw(16:46,2),pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(:),'fill');
        %Against Closest NARR Gridpoint
        for i=1:size(avgdailyhwvals,3);nycdata(i)=avgdailyhwvals{2,1,i}(130,258);end
        %Add fitted quadratic and r^2 value
        p=polyfit(nycdata',pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(:),2);y1=polyval(p,nycdata);
        %Get original data & fitted cubic in the same array so that a scatterplot & a sensical line graph can be produced from the same data
        a=[nycdata'  pctexceeding{arealvariab,presleveliw(varsdes(arealvariab))}(:) y1'];
        b=sortrows(a);
        scatter(b(:,1),b(:,2),'fill');hold on;
        plot(b(:,1),b(:,3),'k-','LineWidth',2);
        %Calculate r^2 of fit
        [r2 rmse]=rsquare(b(:,2),b(:,3));
        
        %Titles, labels, honorifics, etc.
        text(21,70,sprintf('r^{2}=%0.2f',r2),'FontName','Arial','FontSize',20);
        titlepart1=sprintf('%s at Closest Gridpoint to NYC vs Percent of NARR Land Gridpoints Within 1000 km of NYC',varlist4{varsdes(arealvariab)});
        titlepart2=sprintf('Experiencing %s>=%0.0fth Percentile, for %d Heat Waves, %d-%d',...
            varlistnames{varsdes(arealvariab)},xpct*100,size(avgdailyhwvals,3),yeariwf,yeariwl);
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
        titlepart1=sprintf('Heat-Wave Length vs Percent of NARR Land Gridpoints Within 1000 km of NYC');
        titlepart2=sprintf('Experiencing %s>=%0.0fth Percentile, for %d Heat Waves, %d-%d',...
            varlistnames{varsdes(arealvariab)},xpct*100,size(avgdailyhwvals,3),yeariwf,yeariwl);
        title({titlepart1,titlepart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
        xlabel(sprintf('Heat-Wave Length'),'FontSize',14,'FontWeight','bold','FontName','Arial');
        ylabel(sprintf('Percent of Nearby Land Gridpoints With %s>=%0.0fth Pct',...
            varlistnames{varsdes(arealvariab)},xpct*100),'FontSize',14,'FontWeight','bold','FontName','Arial');
        xlim([2 10]);
    end
end

%Calculate 3-hourly advection of T and q at gridpt closest to POI, which is usually but not always NYC (130,258)
%Separate calculations for tempevol and moistness categories
%Can analyze heat waves (short, long, or any-duration, default: short) or all JJA days
%Daily differences are the difference between 8 PM one day and 8 PM the next, NOT the total daily difference
%(this is done so direct comparison can be made with the advective contributions)
if calctqadvection==1
    disp(clock);
    
    if analyzehws==1
        vtuh=plotdaysshortonly{rb,5}; %this is the vector to use here
    else
        vtuh=plotalldays; %ditto
    end
    datasavedupdaily={};
    aztadvarray={};azqadvarray={};azwbtadvarray={};simplecountarray={};
    
    for poi=1:numpoi
        %First, get gridpts closest to POI, their weights, and their azimuths relative to the POI
        poilat=eval(['poi' num2str(poi) 'lat']);poilon=eval(['poi' num2str(poi) 'lon']);
        closestpts=wnarrgridpts(poilat,poilon,1,1,0);
        poilatpt=closestpts(1,1);poilonpt=closestpts(1,2);
        for i=1:size(closestpts,1)
            azimuthtopts(i)=azimuthfromnarrgridpts(closestpts(1,1),closestpts(1,2),...
                closestpts(i,1),closestpts(i,2));
        end
        if size(azimuthtopts,1)==1;azimuthtopts=azimuthtopts';end


        %Next, get data for each heat wave and calculate advection using
        %standard formula of -u*dT/dx-v*dT/dy, giving a result in K/s
        %Keep results separate (for purposes of comparison) according to upper tercile/lower tercile of moisture, and first days/last days
        curFile={};lastpartcur={};
        hotdaysc=0;hwhalf=0;dayc=0;
        
        %Separate counts for different moisture categs & hw halves, and for daily avgs vs hours
        for i=1:3 %moist categs
            for j=1:3 %hw halves
                eval(['nnecm' num2str(i) 'h' num2str(j) '=1;']);eval(['enecm' num2str(i) 'h' num2str(j) '=1;']);eval(['esecm' num2str(i) 'h' num2str(j) '=1;']);
                eval(['ssecm' num2str(i) 'h' num2str(j) '=1;']);eval(['sswcm' num2str(i) 'h' num2str(j) '=1;']);eval(['wswcm' num2str(i) 'h' num2str(j) '=1;']);
                eval(['wnwcm' num2str(i) 'h' num2str(j) '=1;']);eval(['nnwcm' num2str(i) 'h' num2str(j) '=1;']);
                eval(['nnecm' num2str(i) 'h' num2str(j) 'daily=1;']);eval(['enecm' num2str(i) 'h' num2str(j) 'daily=1;']);
                eval(['esecm' num2str(i) 'h' num2str(j) 'daily=1;']);eval(['ssecm' num2str(i) 'h' num2str(j) 'daily=1;']);
                eval(['sswcm' num2str(i) 'h' num2str(j) 'daily=1;']);eval(['wswcm' num2str(i) 'h' num2str(j) 'daily=1;']);
                eval(['wnwcm' num2str(i) 'h' num2str(j) 'daily=1;']);eval(['nnwcm' num2str(i) 'h' num2str(j) 'daily=1;']);
                aztadvarray{poi,i,j}=zeros(1,8);azqadvarray{poi,i,j}=zeros(1,8);azwbtadvarray{poi,i,j}=zeros(1,8);simplecountarray{poi,i,j}=zeros(1,8);
                eval(['daycm' num2str(i) 'h' num2str(j) '=1;']);
            end
        end

        for year=yeariwf:yeariwl
            narrryear=year-yeariwf+1;
            if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
            for month=monthiwf:monthiwl
                fprintf('Current year and month are %d, %d\n',year,month);
                curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);
                dailysumtprev=0;
                %Search through listing of region-wide heat-wave days to see if this month contains one of them
                %If it does, get the data for its hours -- compute daily average as the
                %2am-11pm average, noting that 8pm and 11pm are located under the following day's heading
                %because of the EDT-UTC offset
                for row=1:size(vtuh,1)
                    if vtuh(row,2)==year && vtuh(row,1)>=curmonstart && vtuh(row,1)<curmonstart+curmonlen
                        dayinmonth=vtuh(row,1)-curmonstart+1;fprintf('Day in month is %d\n',dayinmonth);
                        curdoy=DatetoDOY(month,dayinmonth,year);
                        
                        %Decide where temporally in the heat wave this day goes
                        if analyzehws==1
                            curhwlength=plotdaysshortonly{rb,5}(row,3);
                            thisisfirstday=0;thisisfirsttwodays=0;thisislasttwodays=0;thisispenultimateday=0;thisislastday=0;
                            for i=1:size(plotdays{1,2,2})
                                if curdoy==plotdays{1,2,2}(i,1) && year==plotdays{1,2,2}(i,2)
                                    %disp('This is a first day');
                                    thisisfirstday=1;
                                end
                            end
                            for i=1:size(plotdays{1,2,1})
                                if curdoy+1==plotdays{1,2,1}(i,1) && year==plotdays{1,2,1}(i,2)
                                    %disp('This is a penultimate day');
                                    thisispenultimateday=1;
                                elseif curdoy==plotdays{1,2,1}(i,1) && year==plotdays{1,2,1}(i,2)
                                    %disp('This is a last day');
                                    thisislastday=1;
                                end
                            end
                            %Determine if it's also a day where the today->tomorrow transition is fully in the first half of a heat wave
                            if thisisfirstday==1 && curhwlength>=4
                                thisisfirsttwodays=1;hwhalf=1;
                            elseif thisispenultimateday==1 && curhwlength>=4 %ditto for second half
                                thisislasttwodays=1;hwhalf=2;
                            else
                                hwhalf=3; %neither fully in the first half nor the second half
                            end

                            %Decide if this day belongs to a very moist, moderately moist, or less moist heat wave
                            mctd=0; %moistcategthisday
                            for relmoist=1:2 %Search for this day within both upper & lower tercile listings
                                plotdaystu=plotdays{rb,6,relmoist};
                                for i=1:size(plotdaystu,1)
                                    if plotdaystu(i,1)==curdoy && plotdaystu(i,2)==year
                                        mctd=relmoist;
                                        %disp('Found the moisture category!');fprintf('Relmoist is %d\n',relmoist);
                                    end
                                end
                            end
                            if mctd==0;mctd=3;end %moderately moist
                                %So moistcategthisday is 1 for very moist, 2 for less moist, and 3 for moderately moist
                        else
                            hwhalf=3;mctd=3; %just lump everything all together
                        end
                            
                        if dayinmonth~=eval(['m' num2str(month+1) 's' char(suffix) '-m' num2str(month) 's' char(suffix)])
                            lastdayofmonth=0;
                        else
                            lastdayofmonth=1;
                        end
                        %Load in all the files needed
                        curArr{1}=getnarrdatabymonth(runningremotely,'air',year,month);curArr{2}=getnarrdatabymonth(runningremotely,'shum',year,month);
                        curArr{3}=getnarrdatabymonth(runningremotely,'hgt',year,month);curArr{4}=getnarrdatabymonth(runningremotely,'uwnd',year,month);
                        curArr{5}=getnarrdatabymonth(runningremotely,'vwnd',year,month);
                        if lastdayofmonth==1
                            nextmonArr{1}=getnarrdatabymonth(runningremotely,'air',year,month+1);
                            nextmonArr{2}=getnarrdatabymonth(runningremotely,'shum',year,month+1);
                            nextmonArr{3}=getnarrdatabymonth(runningremotely,'hgt',year,month+1);
                            nextmonArr{4}=getnarrdatabymonth(runningremotely,'uwnd',year,month+1);
                            nextmonArr{5}=getnarrdatabymonth(runningremotely,'vwnd',year,month+1);
                        end

                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                            eval(['tarrDOI' hours{hr} '=curArr{1}{3}(:,:,presleveliw(1),dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                            eval(['shumarrDOI' hours{hr} '=curArr{2}{3}(:,:,presleveliw(2),dayinmonth*8+ ' num2str(hr-8) ');']);
                            eval(['hgtarrDOI' hours{hr} '=curArr{3}{3}(:,:,presleveliw(3),dayinmonth*8+ ' num2str(hr-8) ');']);
                            eval(['uwndarrDOI' hours{hr} '=curArr{4}{3}(:,:,presleveliw(4),dayinmonth*8+ ' num2str(hr-8) ');']);
                            eval(['vwndarrDOI' hours{hr} '=curArr{5}{3}(:,:,presleveliw(5),dayinmonth*8+ ' num2str(hr-8) ');']);
                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %not the last day of the month
                                eval(['tarrDOI' hours{hr} 'nextday=curArr{1}{3}(:,:,presleveliw(1),(dayinmonth+1)*8+ ' num2str(hr-8) ')-273.15;']);
                                eval(['shumarrDOI' hours{hr} 'nextday=curArr{2}{3}(:,:,presleveliw(2),(dayinmonth+1)*8+ ' num2str(hr-8) ');']);
                                eval(['hgtarrDOI' hours{hr} 'nextday=curArr{3}{3}(:,:,presleveliw(3),(dayinmonth+1)*8+ ' num2str(hr-8) ');']);
                                eval(['uwndarrDOI' hours{hr} 'nextday=curArr{4}{3}(:,:,presleveliw(4),(dayinmonth+1)*8+ ' num2str(hr-8) ');']);
                                eval(['vwndarrDOI' hours{hr} 'nextday=curArr{5}{3}(:,:,presleveliw(5),(dayinmonth+1)*8+ ' num2str(hr-8) ');']);
                            else %the last day of the month
                                eval(['tarrDOI' hours{hr} 'nextday=nextmonArr{1}{3}(:,:,presleveliw(1),1*8+ ' num2str(hr-8) ')-273.15;']);
                                eval(['shumarrDOI' hours{hr} 'nextday=nextmonArr{2}{3}(:,:,presleveliw(2),1*8+ ' num2str(hr-8) ');']);
                                eval(['hgtarrDOI' hours{hr} 'nextday=nextmonArr{3}{3}(:,:,presleveliw(3),1*8+ ' num2str(hr-8) ');']);
                                eval(['uwndarrDOI' hours{hr} 'nextday=nextmonArr{4}{3}(:,:,presleveliw(4),1*8+ ' num2str(hr-8) ');']);
                                eval(['vwndarrDOI' hours{hr} 'nextday=nextmonArr{5}{3}(:,:,presleveliw(5),1*8+ ' num2str(hr-8) ');']);
                            end
                        end
                        %Compute WBT from T and RH (see average-computation loop above for details)
                        for hr=1:8
                            %For current hour
                            shumarrDOIthishr=eval(['shumarrDOI' hours{hr} ';']);
                            tarrDOIthishr=eval(['tarrDOI' hours{hr} ';']);
                            mrArr=shumarrDOIthishr./(1-shumarrDOIthishr);
                            esArr=6.11*10.^(7.5*tarrDOIthishr./(237.3+tarrDOIthishr));
                            wsArr=0.622*esArr/1000;
                            rhArr=100*mrArr./wsArr;
                            eval(['wbtarrDOI' hours{hr} '=tarrDOIthishr.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                'atan(tarrDOIthishr+rhArr)-atan(rhArr-1.676331)+'...
                                '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                            %For next hour (i.e. 3 hours later)
                            if hr==8 %last hour of day
                                shumarrDOInexthr=eval(['shumarrDOI' hours{1} 'nextday;']);
                                tarrDOInexthr=eval(['tarrDOI' hours{1} 'nextday;']);
                            else
                                shumarrDOInexthr=eval(['shumarrDOI' hours{hr+1} ';']);
                                tarrDOInexthr=eval(['tarrDOI' hours{hr+1} ';']);
                            end
                            eval(['wbtarrDOI' hours{hr} 'nexthr=calcwbtfromTandshum(tarrDOInexthr,shumarrDOInexthr,1);']);
                        end

                        %For verification: if today is a testday, plot temperature & wind fields at 11AM and 5PM
                        if plottestday==1
                            if str2num(testday(7:10))==year && str2num(testday(1:2))==month && str2num(testday(4:5))==dayinmonth
                                hourstodo=[6;8];
                                for i=1:size(hourstodo,1)
                                    overlaydata={narrlats;narrlons;eval(['hgtarrDOI' hours{hourstodo(i)} ';'])};
                                    underlaydata={narrlats;narrlons;eval(['tarrDOI' hours{hourstodo(i)} ';'])};
                                    overlaydata2={narrlats;narrlons;eval(['uwndarrDOI' hours{hourstodo(i)} ';']);eval(['vwndarrDOI' hours{hourstodo(i)} ';'])};
                                    caxismin(underlaynum)=10;caxismax(underlaynum)=35;cstep(underlaynum)=1;
                                    vararginnew={'variable';'temperature';'contour';1;'mystep';cstep(underlaynum);...
                                        'plotCountries';1;'caxismin';caxismin(underlaynum);...
                                        'caxismax';caxismax(underlaynum);'vectorData';overlaydata2;'overlaynow';overlay;'overlayvariable';overlayvar;...
                                        'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata;'anomavg';anomavg2{anomfromjjaavg+1}};
                                    plotModelData(overlaydata,'us-ne',vararginnew,'NARR');figc=figc+1;
                                    title(sprintf('Temperature, Geopot. Height, and Winds at %s on %d/%d/%d',hours{hourstodo(i)},month,dayinmonth,year),...
                                        'FontName','Arial','FontSize',20,'FontWeight','bold');
                                end
                            end
                        end

                        %Now that all the variables for this day are in here, calculate advection for gridpoint of interest
                        dailysumtadv=0;dailysumqadv=0;dailysumwbtadv=0;
                        dailysumwbtcontribtadv=0;dailysumwbtcontribqadv=0;
                        dailysumobstchange=0;dailysumobsqchange=0;dailysumobswbtchange=0;
                        dailysumwbtcontribobstchange=0;dailysumwbtcontribobsqchange=0;
                        dailysumt=0;dailysumq=0;dailysumwbt=0;
                        for hr=1:8
                            %Part I. Winds at gridpt of interest
                            uwndarr=eval(['uwndarrDOI' hours{hr}]);uwndthishr=uwndarr(poilatpt,poilonpt);
                            vwndarr=eval(['vwndarrDOI' hours{hr}]);vwndthishr=vwndarr(poilatpt,poilonpt);
                            wndmag=sqrt(uwndthishr.^2+vwndthishr.^2);
                            %Calculate degree wind is coming from (0-360)
                            if uwndthishr>0 && vwndthishr>0
                                wndaz=270-(atan(vwndthishr/uwndthishr)*180/pi);
                            elseif uwndthishr>0 && vwndthishr<0
                                wndaz=270-(atan(vwndthishr/uwndthishr)*180/pi);
                            elseif uwndthishr<0 && vwndthishr>0
                                wndaz=90-(atan(vwndthishr/uwndthishr)*180/pi);
                            elseif uwndthishr<0 && vwndthishr<0
                                wndaz=90-(atan(vwndthishr/uwndthishr)*180/pi);
                            end
                            %fprintf('Hour is %d\n',hr);fprintf('Azimuth is %d\n',wndaz);

                            %Part II. Which stations to use, and the weights therefor
                            %Example: roughly going clockwise starting at N, the stations surrounding NYC are (131,258),
                            %(131,259), (130,259), (130,260), (129,259), (129,258), (130,257)
                            %These are all 30-50 km away
                            %A good inland (and also rural) point to use is (130,256) in northwest NJ
                            for i=1:size(azimuthtopts,1)
                               azdifftopts(i)=abs(wndaz-azimuthtopts(i));
                               if abs(azdifftopts(i))>180
                                   azdifftopts(i)=abs(360-abs(azdifftopts(i))); %so we can go both ways around the circle 
                               end
                            end

                            %Dimensions of alltheptsdata{poi} are NARRx|NARRy|fractional weight|azimuth to pt|(azimuth to pt)-(wind azimuth)
                            alltheptsdata{poi}(:,1:3)=closestpts(2:8,1:3); %don't include the point of interest itself
                            alltheptsdata{poi}(:,4)=azimuthtopts(2:8);
                            alltheptsdata{poi}(:,5)=azdifftopts(2:8);
                            %Sort to find the two stations that bracket the direction the wind is coming from
                            %Now, the top 2 pts are the ones to use for advection
                            %Weights are based on angular difference between azimuth to them and wind azimuth, and not on distance from POI
                            alltheptsdata{poi}=sortrows(alltheptsdata{poi},5); 
                            totalangulardiff=alltheptsdata{poi}(1,5)+alltheptsdata{poi}(2,5);
                            weightpt1=(totalangulardiff-alltheptsdata{poi}(1,5))/totalangulardiff;
                            weightpt2=(totalangulardiff-alltheptsdata{poi}(2,5))/totalangulardiff;

                            %Part III. This hr's T, q, & WBT at POI
                            %gridpt as well as at ones that wind is advecting from
                            tarrthishr=eval(['tarrDOI' hours{hr} ';']);qarrthishr=eval(['shumarrDOI' hours{hr} ';']);
                            wbtarrthishr=eval(['wbtarrDOI' hours{hr} ';']);
                            tptpoi=tarrthishr(poilatpt,poilonpt);qptpoi=qarrthishr(poilatpt,poilonpt);
                            wbtptpoi=wbtarrthishr(poilatpt,poilonpt);
                            %disp('At this hour, T, q, & WBT at POI, plus wind mag & azimuth:');
                            %disp(tptpoi);disp(qptpoi);disp(wbtptpoi);disp(wndmag);disp(wndaz);
                            for k=2:8;
                                %fprintf('At this hour, T, q, & WBT at (%d,%d) are %d, %d, %d\n',closestpts(k,1),closestpts(k,2),...
                                %    tarrthishr(closestpts(k,1),closestpts(k,2)),qarrthishr(closestpts(k,1),closestpts(k,2)),...
                                %    wbtarrthishr(closestpts(k,1),closestpts(k,2)));
                            end
                            tpt1=tarrthishr(alltheptsdata{poi}(1,1),alltheptsdata{poi}(1,2));
                            qpt1=qarrthishr(alltheptsdata{poi}(1,1),alltheptsdata{poi}(1,2));
                            wbtpt1=wbtarrthishr(alltheptsdata{poi}(1,1),alltheptsdata{poi}(1,2));
                            tpt2=tarrthishr(alltheptsdata{poi}(2,1),alltheptsdata{poi}(2,2));
                            qpt2=qarrthishr(alltheptsdata{poi}(2,1),alltheptsdata{poi}(2,2));
                            wbtpt2=wbtarrthishr(alltheptsdata{poi}(2,1),alltheptsdata{poi}(2,2));

                            %Part IV. Calculation of advection using this hour's temps and winds
                            %Changes are calculated forward, i.e. from this hour to the next
                            %Also, compare these values with the observed T and q/WBT change
                            distpoipt1=distance('gc',[narrlats(poilatpt,poilonpt),narrlons(poilatpt,poilonpt)],...
                    [narrlats(alltheptsdata{poi}(1,1),alltheptsdata{poi}(1,2)),narrlons(alltheptsdata{poi}(1,1),alltheptsdata{poi}(1,2))])*111; %in km
                            distpoipt2=distance('gc',[narrlats(poilatpt,poilonpt),narrlons(poilatpt,poilonpt)],...
                    [narrlats(alltheptsdata{poi}(2,1),alltheptsdata{poi}(2,2)),narrlons(alltheptsdata{poi}(2,1),alltheptsdata{poi}(2,2))])*111; %in km
                            tgradtopt1=(tpt1-tptpoi)/(distpoipt1*1000);tgradtopt2=(tpt2-tptpoi)/(distpoipt1*1000); %in K/m
                            qgradtopt1=(qpt1-qptpoi)/(distpoipt1*1000);qgradtopt2=(qpt2-qptpoi)/(distpoipt1*1000); %in (kg/kg)/m
                            wbtgradtopt1=(wbtpt1-wbtptpoi)/(distpoipt1*1000);wbtgradtopt2=(wbtpt2-wbtptpoi)/(distpoipt1*1000); %in K/m

                            tadv=wndmag*tgradtopt1*weightpt1+wndmag*tgradtopt2*weightpt2; %in K/s
                            qadv=wndmag*qgradtopt1*weightpt1+wndmag*qgradtopt2*weightpt2; %in (kg/kg)/s
                            wbtadv=wndmag*wbtgradtopt1*weightpt1+wndmag*wbtgradtopt2*weightpt2; %in K/s
                            [wbttslope,wbtqslope,wbtarray]=calcWBTslopes(tptpoi,1000*qptpoi); %WBT slopes in the current conditions
                            wbtcontribtadv=wbttslope*tadv*10800; %tadv is the total advection-induced T change over 3 hours, in K;
                                %wbttslope is the deltaWBT/deltaT slope at the current T, so that the product gives the WBT change that this T change is responsible for
                            wbtcontribqadv=wbtqslope*qadv*10800; %ditto for q
                            dailysumtadv=dailysumtadv+tadv;dailysumqadv=dailysumqadv+qadv;dailysumwbtadv=dailysumwbtadv+wbtadv;
                            dailysumwbtcontribtadv=dailysumwbtcontribtadv+wbtcontribtadv;dailysumwbtcontribqadv=dailysumwbtcontribqadv+wbtcontribqadv;
                            %fprintf('T advectio0.00n, q advection, and WBT advection at this hour are %d K/hr, %d (kg/kg)/hr, & %d K/hr\n',...
                            %    tadv*3600,qadv*3600,wbtadv*3600);
                            %fprintf('qslope is %d; qadv*10800 is %d;wbtcontribqadv is %d\n',wbtqslope,qadv*10800,wbtcontribqadv);

                            if hr==8 %nexthr is on the next day
                                tarrnexthr=eval(['tarrDOI' hours{1} 'nextday;']);qarrnexthr=eval(['shumarrDOI' hours{1} 'nextday;']);
                                wbtarrnexthr=eval(['wbtarrDOI' hours{hr} 'nexthr;']); %i.e. the next hour from this hour
                            else
                                tarrnexthr=eval(['tarrDOI' hours{hr+1} ';']);qarrnexthr=eval(['shumarrDOI' hours{hr+1} ';']);
                                wbtarrnexthr=eval(['wbtarrDOI' hours{hr} 'nexthr;']); %i.e. the next hour from this hour
                            end
                            tptpoinexthr=tarrnexthr(poilatpt,poilonpt);qptpoinexthr=qarrnexthr(poilatpt,poilonpt);
                            wbtptpoinexthr=wbtarrnexthr(poilatpt,poilonpt);
                            obstchange=tptpoinexthr-tptpoi;obsqchange=qptpoinexthr-qptpoi;
                            obswbtchange=wbtptpoinexthr-wbtptpoi;
                            wbtcontribobstchange=wbttslope*obstchange; %same as above wbtcontrib but for observed changes
                            wbtcontribobsqchange=wbtqslope*obsqchange;
                            dailysumobstchange=dailysumobstchange+obstchange;dailysumobsqchange=dailysumobsqchange+obsqchange;
                            dailysumobswbtchange=dailysumobswbtchange+obswbtchange;
                            dailysumwbtcontribobstchange=dailysumwbtcontribobstchange+wbtcontribobstchange;
                            dailysumwbtcontribobsqchange=dailysumwbtcontribobsqchange+wbtcontribobsqchange;
                            %dailysumt=dailysumt+tptpoi;dailysumq=dailysumq+qptpoi;dailysumwbt=dailysumwbt+wbtptpoi;
                            %fprintf('Observed T, q, and WBT change at this hour are %d K/hr, %d (kg/kg)/hr, & %d K/hr\n',...
                            %    obstchange/3,obsqchange/3,obswbtchange/3);
                            %fprintf('WBT contrib at this hour is %d from obs T change and %d from obs q change\n',...
                            %    wbtcontribobstchange,wbtcontribobsqchange);

                            %If at the end of a day, calculate daily averages in units of (units)/per day
                            if hr==8
                                dailysumtadv=24*3600*dailysumtadv/8;dailysumqadv=24*3600*dailysumqadv/8;dailysumwbtadv=24*3600*dailysumwbtadv/8;
                                fprintf('Total T adv on this day is %d; total obs T change is %d\n',dailysumtadv,dailysumobstchange);
                                fprintf('Total q adv on this day is %d; total obs q change is %d\n',dailysumqadv,dailysumobsqchange);
                                fprintf('Today: wbtcontrib from tadv is %d, wbtcontrib from qadv is %d\n',dailysumwbtcontribtadv,dailysumwbtcontribqadv);
                                fprintf('Today: wbtcontrib from obstchange is %d, wbtcontrib from obsqchange is %d\n',dailysumwbtcontribobstchange,dailysumwbtcontribobsqchange);
                                %if ~thisislastday;dailysumtchange=dailysumt-dailysumtprev;end
                                %fprintf('Today and previous day avg T are %d, %d\n',dailysumt,dailysumtprev);
                            end
                            %dailysumtprev=dailysumt;

                            %Part V. Partitioning into eighths for saving and compiling purposes
                            %Dimensions of these arrays are compass eighth|firsthalf/secondhalf/allhwdays|uppertercile/lowertercile|variable or date
                            %obs change is over 3-hour NARR time interval, adv change is multiplied so it is in K/3 hr as well
                            %Also calculate change over a full 24-hour period so as to avoid the complications of the daily cycle
                            %Daily changes are between hour 1 (8 PM) of day 1 and hour 1 of day 2
                            %Recall that all changes are calculated forward, i.e. from this hour or day to the next
                            fa=10800; %factor to convert from s to 3 hr
                            tadv=tadv*fa;qadv=qadv*fa;wbtadv=wbtadv*fa;

                            %Dimensions of datasavedupdaily and azarraydaily are hw half|moist categ,
                            %and are also separated into different cells by point of interest
                            %i.e. for each moisture & tempevol category this creates an array whose rows are the constituent sets of days
                            %and whose columns are all the data we are interested in
                            %e.g. datasavedupdaily{poi}{3,x} shows data for all the days of moist categ x using poi
                            if hr==8
                                for i=1:3
                                    if (i<=2 && i==hwhalf) || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                        c=eval(['daycm' num2str(mctd) 'h' num2str(i) ';']);
                                        fprintf('relevant dayc is %d; i is %d; mctd is %d\n',c,i,mctd);
                                        datasavedupdaily{poi}{i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{i,mctd}(c,2)=dailysumobstchange;
                                        datasavedupdaily{poi}{i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{i,mctd}(c,4)=dailysumobsqchange;
                                        datasavedupdaily{poi}{i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{i,mctd}(c,6)=dailysumobswbtchange;
                                        datasavedupdaily{poi}{i,mctd}(c,7)=dailysumwbtcontribtadv;datasavedupdaily{poi}{i,mctd}(c,8)=dailysumwbtcontribqadv;
                                        datasavedupdaily{poi}{i,mctd}(c,9)=dailysumwbtcontribobstchange;datasavedupdaily{poi}{i,mctd}(c,10)=dailysumwbtcontribobsqchange;
                                        datasavedupdaily{poi}{i,mctd}(c,11)=year;datasavedupdaily{poi}{i,mctd}(c,12)=month;
                                        datasavedupdaily{poi}{i,mctd}(c,13)=dayinmonth;
                                        %eval(['cm' num2str(mctd) 'h' num2str(i) 'daily=c;']); %don't advance since it will advance in the next such loop (for the azimuths)
                                    end
                                end
                            end

                            %Category of wind azimuth at this hour
                            wndazhere=wndaz;if wndazhere==360;wndazhere=0;end
                            azcat=round2(wndazhere/45,1,'ceil'); %category of wind azimuth, an integer from 1 to 8, where NNE=1 and NNW=8
                            %fprintf('The wind azimuth category at this hour is %d\n',azcat);

                            %Make array whose rows are days and whose columns are (# hours)*(Tadv)
                            %Aim to break down advection by wind azimuth e.g. to see if T & moisture preferentially come from different azimuths
                            %Therefore, sum across the rows of azXadvarray is the total advective contrib for variable X for that day,
                            %and the sum across the rows of simplecountarray is always 8
                            %Last row is always a row of zeros which can then be eliminated
                            %Corresponding dates are found in the identically structured datasavedupdaily arrays
                            for i=1:3
                                if (i<=2 && i==hwhalf) || i==3
                                    dayc=eval(['daycm' num2str(mctd) 'h' num2str(i) ';']);
                                    %fprintf('Relevant dayc is %d\n',dayc);
                                    aztadvarray{poi,i,mctd}(dayc,azcat)=aztadvarray{poi,i,mctd}(dayc,azcat)+tadv;
                                    azqadvarray{poi,i,mctd}(dayc,azcat)=azqadvarray{poi,i,mctd}(dayc,azcat)+qadv;
                                    azwbtadvarray{poi,i,mctd}(dayc,azcat)=azwbtadvarray{poi,i,mctd}(dayc,azcat)+wbtadv;
                                    simplecountarray{poi,i,mctd}(dayc,azcat)=simplecountarray{poi,i,mctd}(dayc,azcat)+1; %# of hours in each day in each of the azimuth categories
                                    aztadvarray{poi,i,mctd}(dayc+1,:)=zeros(1,8);azqadvarray{poi,i,mctd}(dayc+1,:)=zeros(1,8);
                                    azwbtadvarray{poi,i,mctd}(dayc+1,:)=zeros(1,8);simplecountarray{poi,i,mctd}(dayc+1,:)=zeros(1,8);
                                    if hr==8;dayc=dayc+1;end %only if it's actually the end of a day do we move on to the next
                                    eval(['daycm' num2str(mctd) 'h' num2str(i) '=dayc;']);
                                end
                            end

                            oldhours=0;
                            if oldhours==1 %go back to  pre-May 11, 10 PM if the old hourly version is desired
                                %The point of this loop was to compare T & q advection from different parts of the compass
                                %e.g. what percent of the warm-air advection comes from the SW?
                            if wndaz>=0 && wndaz<45 %NNE
                                if hr==8
                                    for i=1:3
                                        if (i<=2 && i==hwhalf) || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['nnecm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{1,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{1,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{1,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{1,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{1,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{1,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{1,i,mctd}(c,7)=year;datasavedupdaily{poi}{1,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{1,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['nnecm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=45 && wndaz<90 %ENE
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['enecm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{2,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{2,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{2,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{2,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{2,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{2,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{2,i,mctd}(c,7)=year;datasavedupdaily{poi}{2,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{2,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['enecm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=90 && wndaz<135 %ESE
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['esecm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{3,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{3,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{3,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{3,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{3,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{3,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{3,i,mctd}(c,7)=year;datasavedupdaily{poi}{3,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{3,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['esecm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=135 && wndaz<180 %SSE
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['ssecm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{4,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{4,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{4,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{4,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{4,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{4,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{4,i,mctd}(c,7)=year;datasavedupdaily{poi}{4,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{4,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['ssecm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=180 && wndaz<225 %SSW
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['sswcm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{5,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{5,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{5,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{5,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{5,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{5,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{5,i,mctd}(c,7)=year;datasavedupdaily{poi}{5,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{5,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['sswcm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=225 && wndaz<270 %WSW
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['wswcm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{6,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{6,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{6,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{6,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{6,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{6,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{6,i,mctd}(c,7)=year;datasavedupdaily{poi}{6,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{6,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['wswcm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=270 && wndaz<315 %WNW
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['wnwcm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{7,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{7,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{7,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{7,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{7,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{7,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{7,i,mctd}(c,7)=year;datasavedupdaily{poi}{7,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{7,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['wnwcm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            elseif wndaz>=315 && wndaz<=360 %NNW
                                %The new look of this loop
                                if hr==8
                                    for i=1:3
                                        if i<=2 && i==hwhalf || i==3 %if a first day or penultimate day, include in that tally; no matter what, include in all-hw-days one
                                            c=eval(['nnwcm' num2str(mctd) 'h' num2str(i) 'daily;']); %the relevant count to increase for this day
                                            datasavedupdaily{poi}{8,i,mctd}(c,1)=dailysumtadv;datasavedupdaily{poi}{8,i,mctd}(c,2)=obstchange;
                                            datasavedupdaily{poi}{8,i,mctd}(c,3)=dailysumqadv;datasavedupdaily{poi}{8,i,mctd}(c,4)=obsqchange;
                                            datasavedupdaily{poi}{8,i,mctd}(c,5)=dailysumwbtadv;datasavedupdaily{poi}{8,i,mctd}(c,6)=obswbtchange;
                                            datasavedupdaily{poi}{8,i,mctd}(c,7)=year;datasavedupdaily{poi}{8,i,mctd}(c,8)=month;
                                            datasavedupdaily{poi}{8,i,mctd}(c,9)=dayinmonth;c=c+1;eval(['nnwcm' num2str(mctd) 'h' num2str(i) 'daily=c;']);
                                        end
                                    end
                                end
                            end
                            end
                        end
                        hotdaysc=hotdaysc+1;
                    end
                end
            end
        end
        %Array that has advective data converted to total K/day from each azimuth
        %Or perhaps this wouldn't actually add anything useful
        %if analyzehws==0
        %aztadvperday{poi,3,3}=(aztadvarray{poi,3,3}./simplecountarray{poi,3,3})*8;
    end
    hotdayscvec{7,firstday+1}=hotdaysc;
    disp(clock);save(strcat(savedvardir,'calctqadvection'),...
        'alltheptsdata','datasavedupdaily','aztadvarray','azqadvarray','azwbtadvarray','simplecountarray');
end


%Make plots using the T/q advection arrays calculated above
if maketqadvplots==1
    %Comparison of advective to total change for T, for (all days of) very moist vs less moist heat waves,
    %advectivechange for very moist heat waves is in top left, for less moist bottom left, and total observed changes are on the right
    %Compare these using four histograms
    %Make the limits of the histograms in each column the same, for purposes of comparison
    %Note: with plotdaysshortonly heat waves for NYC as POI, a null result is obtained
    if plotstodo(1)==1
        figure(figc);clf;figc=figc+1;hold on;
        tadvvm=datasavedupdaily{poi}{3,1}(:,1);
        mincenters1=roundsd(min(tadvvm),2);maxcenters1=roundsd(max(tadvvm),2);
        obstchangevm=datasavedupdaily{poi}{3,1}(:,2);
        mincenters2=roundsd(min(obstchangevm),2);maxcenters2=roundsd(max(obstchangevm),2);
        tadvlm=datasavedupdaily{poi}{3,2}(:,1);
        mincenters3=roundsd(min(tadvlm),2);maxcenters3=roundsd(max(tadvlm),2);
        obstchangelm=datasavedupdaily{poi}{3,2}(:,2);
        mincenters4=round2(min(obstchangelm),centerstep,'floor');maxcenters4=round2(max(obstchangelm),centerstep,'ceil');

        mincenterscol1=min(mincenters1,mincenters3);mincenterscol2=min(mincenters2,mincenters4);
        maxcenterscol1=max(maxcenters1,maxcenters3);maxcenterscol2=max(maxcenters2,maxcenters4);
        rangecenterscol1=maxcenterscol1-mincenterscol1;rangecenterscol2=maxcenterscol2-mincenterscol2;
        if rangecenterscol1<=20;centerstepcol1=1;elseif rangecenterscol1<=40;centerstepcol1=2;else centerstepcol1=5;end
        if rangecenterscol2<=20;centerstepcol2=1;elseif rangecenterscol2<=40;centerstepcol2=2;else centerstepcol2=5;end
        centerscol1=mincenterscol1:centerstepcol1:maxcenters1;centerscol2=mincenterscol2:centerstepcol2:maxcenters2;

        subplot(2,2,1);h=hist(tadvvm,centerscol1);h=h./sum(h);bar(centerscol1,h,'style','histc');
        title('Advective Daily Change in T, Very Moist Heat Waves','FontName','Arial','FontSize',20,'FontWeight','bold');

        subplot(2,2,2);h=hist(obstchangevm,centerscol2);h=h./sum(h);bar(centerscol2,h,'style','histc');
        title('Observed Daily Change in T, Very Moist Heat Waves','FontName','Arial','FontSize',20,'FontWeight','bold');

        subplot(2,2,3);h=hist(tadvlm,centerscol1);h=h./sum(h);bar(centerscol1,h,'style','histc');
        title('Advective Daily Change in T, Less-Moist Heat Waves','FontName','Arial','FontSize',20,'FontWeight','bold');

        subplot(2,2,4);h=hist(obstchangelm,centerscol2);h=h./sum(h);bar(centerscol2,h,'style','histc');
        title('Observed Daily Change in T, Less-Moist Heat Waves','FontName','Arial','FontSize',20,'FontWeight','bold');
        %if rangecenters<=0.01;centerstep=0.01/20;elseif rangecenters<=0.05;centerstep=0.05/20;else centerstep=0.005;end %for q
    end
    
    
    %Histogram of contributions of T to WBT for different days of very moist and less-moist heat waves
    if plotstodo(2)==1
        figure(figc);clf;figc=figc+1;hold on;
        wbtcontribtadvvm=datasavedupdaily{poi}{3,1}(:,7);
        mincenters1=roundsd(min(wbtcontribtadvvm),2);maxcenters1=roundsd(max(wbtcontribtadvvm),2);
        wbtcontribobstchangevm=datasavedupdaily{poi}{3,1}(:,9);
        mincenters2=roundsd(min(wbtcontribobstchangevm),2);maxcenters2=roundsd(max(wbtcontribobstchangevm),2);
        wbtcontribtadvlm=datasavedupdaily{poi}{3,2}(:,7);
        mincenters3=roundsd(min(wbtcontribtadvlm),2);maxcenters3=roundsd(max(wbtcontribtadvlm),2);
        wbtcontribobstchangelm=datasavedupdaily{poi}{3,2}(:,9);
        mincenters4=roundsd(min(wbtcontribobstchangelm),2);maxcenters4=roundsd(max(wbtcontribobstchangelm),2);

        mincenterscol1=min(mincenters1,mincenters3);mincenterscol2=min(mincenters2,mincenters4);
        maxcenterscol1=max(maxcenters1,maxcenters3);maxcenterscol2=max(maxcenters2,maxcenters4);
        rangecenterscol1=maxcenterscol1-mincenterscol1;rangecenterscol2=maxcenterscol2-mincenterscol2;
        if rangecenterscol1<=20;centerstepcol1=1;elseif rangecenterscol1<=40;centerstepcol1=2;else centerstepcol1=5;end
        if rangecenterscol2<=20;centerstepcol2=1;elseif rangecenterscol2<=40;centerstepcol2=2;else centerstepcol2=5;end
        centerscol1=mincenterscol1:centerstepcol1:maxcenters1;centerscol2=mincenterscol2:centerstepcol2:maxcenters2;

        subplot(2,2,1);h=hist(wbtcontribtadvvm,centerscol1);h=h./sum(h);bar(centerscol1,h,'style','histc');
        phrpart1='Contribution of Advective T Change to WBT Change';phrpart2='Very Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');

        subplot(2,2,2);h=hist(wbtcontribobstchangevm,centerscol2);h=h./sum(h);bar(centerscol2,h,'style','histc');
        phrpart1='Contribution of Observed T Change to WBT Change';phrpart2='Very Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');

        subplot(2,2,3);h=hist(wbtcontribtadvlm,centerscol1);h=h./sum(h);bar(centerscol1,h,'style','histc');
        phrpart1='Contribution of Advective T Change to WBT Change';phrpart2='Less-Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');

        subplot(2,2,4);h=hist(wbtcontribobstchangelm,centerscol2);h=h./sum(h);bar(centerscol2,h,'style','histc');
        phrpart1='Contribution of Observed T Change to WBT Change';phrpart2='Less-Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');
    end
    
    %Histogram of contributions of q to WBT for different days of very moist and less-moist heat waves
    if plotstodo(3)==1
        figure(figc);clf;figc=figc+1;hold on;
        wbtcontribqadvvm=datasavedupdaily{poi}{3,1}(:,8);
        mincenters1=roundsd(min(wbtcontribqadvvm),2);maxcenters1=roundsd(max(wbtcontribqadvvm),2);
        wbtcontribobsqchangevm=datasavedupdaily{poi}{3,1}(:,10);
        mincenters2=roundsd(min(wbtcontribobsqchangevm),2);maxcenters2=roundsd(max(wbtcontribobsqchangevm),2);
        wbtcontribqadvlm=datasavedupdaily{poi}{3,2}(:,8);
        mincenters3=roundsd(min(wbtcontribqadvlm),2);maxcenters3=roundsd(max(wbtcontribqadvlm),2);
        wbtcontribobsqchangelm=datasavedupdaily{poi}{3,2}(:,10);
        mincenters4=roundsd(min(wbtcontribobsqchangelm),2);maxcenters4=roundsd(max(wbtcontribobsqchangelm),2);

        mincenterscol1=min(mincenters1,mincenters3);mincenterscol2=min(mincenters2,mincenters4);
        maxcenterscol1=max(maxcenters1,maxcenters3);maxcenterscol2=max(maxcenters2,maxcenters4);
        rangecenterscol1=maxcenterscol1-mincenterscol1;rangecenterscol2=maxcenterscol2-mincenterscol2;
        if rangecenterscol1<=20;centerstepcol1=1;elseif rangecenterscol1<=40;centerstepcol1=2;else centerstepcol1=5;end
        if rangecenterscol2<=20;centerstepcol2=1;elseif rangecenterscol2<=40;centerstepcol2=2;else centerstepcol2=5;end
        centerscol1=mincenterscol1:centerstepcol1:maxcenters1;centerscol2=mincenterscol2:centerstepcol2:maxcenters2;

        subplot(2,2,1);h=hist(wbtcontribqadvvm,centerscol1);h=h./sum(h);bar(centerscol1,h,'style','histc');
        phrpart1='Contribution of Advective q Change to WBT Change';phrpart2='Very Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');set(gca,'FontName','Arial','FontSize',15,'FontWeight','bold');

        subplot(2,2,2);h=hist(wbtcontribobsqchangevm,centerscol2);h=h./sum(h);bar(centerscol2,h,'style','histc');
        phrpart1='Contribution of Observed q Change to WBT Change';phrpart2='Very Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');set(gca,'FontName','Arial','FontSize',15,'FontWeight','bold');

        subplot(2,2,3);h=hist(wbtcontribqadvlm,centerscol1);h=h./sum(h);bar(centerscol1,h,'style','histc');
        phrpart1='Contribution of Advective q Change to WBT Change';phrpart2='Less-Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');set(gca,'FontName','Arial','FontSize',15,'FontWeight','bold');
        
        subplot(2,2,4);h=hist(wbtcontribobsqchangelm,centerscol2);h=h./sum(h);bar(centerscol2,h,'style','histc');
        phrpart1='Contribution of Observed q Change to WBT Change';phrpart2='Less-Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');set(gca,'FontName','Arial','FontSize',15,'FontWeight','bold');
    end
    
    %Pie-chart plots of T advection by azimuth on first days of very moist vs less-moist heat waves
    %Range for daily Tadv is such that cutoffs every 0.5 K/day are appropriate
    if plotstodo(4)==1
        desrange=9; %number of possible colors to have in these pie plots -- options are 9 or 19
        for poi=1:numpoi
            lowestavgfound=1000;highestavgfound=-1000;

            for relmoist=1:2
                %Have to go through the eighths thrice -- twice to calculate things, then once more to plot them
                for dir=1:8
                    temp=aztadvarray{poi,dayhere,relmoist}(:,dir);
                    avghere(relmoist,dir)=mean(temp(abs(temp)>0));
                    if avghere(relmoist,dir)>highestavgfound;highestavgfound=avghere(relmoist,dir);end
                    if avghere(relmoist,dir)<lowestavgfound;lowestavgfound=avghere(relmoist,dir);end
                end
            end
            %Now we know the ranges of the variables for this day, so we can multiply them by the appropriate factors to get a range of 1-20
            rangenow=highestavgfound-lowestavgfound;factor=rangenow/desrange;
            rangenew=rangenow/factor;highestavgnew=highestavgfound/factor;lowestavgnew=lowestavgfound/factor;
            numtoaddorsubtr=1-lowestavgnew;highestavgnew=highestavgnew+numtoaddorsubtr;lowestavgnew=lowestavgnew+numtoaddorsubtr;
            for relmoist=1:2
                for dir=1:8
                    roundedavg(relmoist,dir)=round2((avghere(relmoist,dir)/factor+numtoaddorsubtr),1);
                    if roundedavg(relmoist,dir)<1;roundedavg(relmoist,dir)=1;end %coldest possible color
                    if roundedavg(relmoist,dir)>desrange+1;roundedavg(relmoist,dir)=desrange+1;end %warmest possible color
                    if isnan(avghere(relmoist,dir));roundedavg(relmoist,dir)=desrange+2;end %no winds from this azimuth so plot in gray
                end
            end
            if abs(rangenow)<10;roundprec=0.5;else roundprec=1;end
            roundedlowestavgfound=(round2(lowestavgfound,roundprec));
            roundedhighestavgfound=(round2(highestavgfound,roundprec));
            if abs(factor)<10;roundprec=1;else roundprec=2;end
            stephere=roundsd(factor,roundprec);
            rangehere=roundedlowestavgfound:stephere:roundedhighestavgfound;
            rangehere2={};for i=1:size(rangehere,2);rangehere2{i}=num2str(rangehere(i));end
            %Repeat because the above is acting temperamental in the plots
            longerstep=(roundedhighestavgfound-roundedlowestavgfound)/7.5; %to get 8 numbers spanning the observed range
            if abs(longerstep)<5;roundprec=0.1;elseif abs(longerstep)<10;roundprec=0.5;else roundprec=1;end
            longerstep=round2(longerstep,roundprec);
            rangehere=roundedlowestavgfound:longerstep:roundedhighestavgfound;
            rangehere2={};for i=1:size(rangehere,2);rangehere2{i}=num2str(rangehere(i));end
            %disp(rangehere2);disp(class(rangehere2));

            %Time to make the plots        
            figure('Color',[1 1 1]);
            X=[1 1 1 1 1 1 1 1]; %for a pie chart with eight even sections
            if desrange==19
                possiblecolors=[colors('dark magenta');colors('lilac');colors('purple');colors('warm purple');colors('fuchsia');...
                    colors('indigo');colors('blue');colors('light blue');colors('sky blue');colors('dark turquoise');...
                    colors('jade');colors('green');colors('light green');colors('mint');colors('yellow');colors('light orange');...
                    colors('orange');colors('light red');colors('red');colors('crimson')]; %20 possible colors
            elseif desrange==9
                possiblecolors=[colors('dark magenta');colors('purple');colors('blue');colors('light blue');colors('jade');colors('green');
                    colors('light green');colors('yellow');colors('light orange');colors('red')]; %10 possible colors
            end
            nancolor=colors('gray');
            labels={'','','','','','','',''};

            for relmoist=1:2
                subplot(2,1,relmoist);
                p=pie(X,labels);hold on;
                for dir=1:8
                    actualdir=9-dir; %pie function and my wind conventions both start in N but go in opposite directions, so need to account for that
                    hp=findobj(p,'Type','patch');
                    if roundedavg(relmoist,actualdir)==desrange+2 %average NaN
                        set(hp(dir),'FaceColor',nancolor(roundedavg(relmoist,actualdir)-(desrange+1),:));
                    else
                        set(hp(dir),'FaceColor',possiblecolors(roundedavg(relmoist,actualdir),:));
                    end
                end
                if relmoist==1
                    phrpart1='Advective Contribution to Daily Changes in T by Wind-Azimuth Direction';
                    phrpart2=sprintf('During %s Days of Very Moist Heat Waves For %s Gridpoint',char(hwdayslabel{dayhere}),poinames{poi});
                    title({phrpart1,phrpart2},'FontSize',20,'FontName','Arial','FontWeight','bold');
                elseif relmoist==2
                    phrpart2=sprintf('During %s Days of Less-Moist Heat Waves For %s Gridpoint',char(hwdayslabel{dayhere}),poinames{poi});
                    title({phrpart2},'FontSize',20,'FontName','Arial','FontWeight','bold');
                end
                set(gcf,'ColorMap',possiblecolors(lowestavgnew:highestavgnew,:)); %moved the limits around such the data span all 20 colors
                cb=colorbar;
                set(cb,'YTickLabel',rangehere2);%disp(rangehere2);
                set(gca,'FontName','Arial','FontSize',12,'FontWeight','bold');
            end
            text(2,0.3,'K/day','FontSize',15,'FontName','Arial','FontWeight','bold');
            text(2,3.8,'K/day','FontSize',15,'FontName','Arial','FontWeight','bold');
            figc=figc+1;
        end
    end
    
    
    %Pie-chart plots of q advection by azimuth on first days of very moist vs less-moist heat waves
    %Range for daily qadv is approximately 0 to 0.005, so cutoffs are every 0.00025 (kg/kg)/day
    if plotstodo(5)==1
        desrange=9; %number of possible colors to have in these pie plots -- options are 9 or 19
        for poi=1:numpoi
            lowestavgfound=1000;highestavgfound=-1000;

            for relmoist=1:2
                %Have to go through the eighths thrice -- twice to calculate things, then once more to plot them
                for dir=1:8
                    temp=azqadvarray{poi,dayhere,relmoist}(:,dir);
                    avghere(relmoist,dir)=mean(temp(abs(temp)>0));
                    if avghere(relmoist,dir)>highestavgfound;highestavgfound=avghere(relmoist,dir);end
                    if avghere(relmoist,dir)<lowestavgfound;lowestavgfound=avghere(relmoist,dir);end
                end
            end
            %Now we know the ranges of the variables for this day, so we can multiply them by the appropriate factors to get a range of 1-20
            rangenow=highestavgfound-lowestavgfound;factor=rangenow/desrange;
            rangenew=rangenow/factor;highestavgnew=highestavgfound/factor;lowestavgnew=lowestavgfound/factor;
            numtoaddorsubtr=1-lowestavgnew;highestavgnew=highestavgnew+numtoaddorsubtr;lowestavgnew=lowestavgnew+numtoaddorsubtr;
            for relmoist=1:2
                for dir=1:8
                    roundedavg(relmoist,dir)=round2((avghere(relmoist,dir)/factor+numtoaddorsubtr),1);
                    if roundedavg(relmoist,dir)<1;roundedavg(relmoist,dir)=1;end %coldest possible color
                    if roundedavg(relmoist,dir)>desrange+1;roundedavg(relmoist,dir)=desrange+1;end %warmest possible color
                    if isnan(avghere(relmoist,dir));roundedavg(relmoist,dir)=desrange+2;end %no winds from this azimuth so plot in gray
                end
            end
            if abs(rangenow)>0.001;roundprec=2;else roundprec=2;end %2 should be good
            roundedlowestavgfound=roundsd(lowestavgfound,roundprec);
            roundedhighestavgfound=(roundsd(highestavgfound,roundprec));
            if abs(factor)<10;roundprec=2;else roundprec=2;end
            stephere=roundsd(factor,roundprec);
            rangehere=roundedlowestavgfound:stephere:roundedhighestavgfound;
            rangehere2={};for i=1:size(rangehere,2);rangehere2{i}=num2str(1000*rangehere(i));end
            %Repeat because the above is acting temperamental in the plots
            longerstep=(roundedhighestavgfound-roundedlowestavgfound)/7.5; %to get 8 numbers spanning the observed range
            roundprec=1;
            longerstep=roundsd(longerstep,roundprec);
            rangehere=roundedlowestavgfound:longerstep:roundedhighestavgfound;
            rangehere2={};for i=1:size(rangehere,2);rangehere2{i}=num2str(1000*rangehere(i));end
            %disp(rangehere2);disp(class(rangehere2));

            %Time to make the plots        
            figure('Color',[1 1 1]);
            X=[1 1 1 1 1 1 1 1]; %for a pie chart with eight even sections
            if desrange==19
                possiblecolors=[colors('dark magenta');colors('lilac');colors('purple');colors('warm purple');colors('fuchsia');...
                    colors('indigo');colors('blue');colors('light blue');colors('sky blue');colors('dark turquoise');...
                    colors('jade');colors('green');colors('light green');colors('mint');colors('yellow');colors('light orange');...
                    colors('orange');colors('light red');colors('red');colors('crimson')]; %20 possible colors
            elseif desrange==9
                possiblecolors=[colors('dark magenta');colors('purple');colors('blue');colors('light blue');colors('jade');colors('green');
                    colors('light green');colors('yellow');colors('light orange');colors('red')]; %10 possible colors
            end
            nancolor=colors('gray');
            labels={'','','','','','','',''};

            for relmoist=1:2
                subplot(2,1,relmoist);
                p=pie(X,labels);hold on;
                for dir=1:8
                    actualdir=9-dir; %pie function and my wind conventions both start in N but go in opposite directions, so need to account for that
                    hp=findobj(p,'Type','patch');
                    if roundedavg(relmoist,actualdir)==desrange+2 %average NaN
                        set(hp(dir),'FaceColor',nancolor(roundedavg(relmoist,actualdir)-(desrange+1),:));
                    else
                        set(hp(dir),'FaceColor',possiblecolors(roundedavg(relmoist,actualdir),:));
                    end
                end
                if relmoist==1
                    phrpart1='Advective Contribution to Daily Changes in q by Wind-Azimuth Direction';
                    phrpart2=sprintf('During %s Days of Very Moist Heat Waves For %s Gridpoint',char(hwdayslabel{dayhere}),poinames{poi});
                    title({phrpart1,phrpart2},'FontSize',20,'FontName','Arial','FontWeight','bold');
                elseif relmoist==2
                    phrpart2=sprintf('During %s Days of Less-Moist Heat Waves For %s Gridpoint',char(hwdayslabel{dayhere}),poinames{poi});
                    title({phrpart2},'FontSize',20,'FontName','Arial','FontWeight','bold');
                end
                set(gcf,'ColorMap',possiblecolors(lowestavgnew:highestavgnew,:)); %moved the limits around such the data span all 20 colors
                cb=colorbar;
                set(cb,'YTickLabel',rangehere2);%disp(rangehere2);
                set(gca,'FontName','Arial','FontSize',12,'FontWeight','bold')
            end
            text(2,0.3,'(g/kg)/day','FontSize',15,'FontName','Arial','FontWeight','bold');
            text(2,3.8,'(g/kg)/day','FontSize',15,'FontName','Arial','FontWeight','bold');
            figc=figc+1;
        end
    end
    
    
    %Pie-chart plots of T and q advection by azimuth on all JJA days
    %Range for daily Tadv is such that cutoffs every 0.5 K/day are appropriate
    %Range for daily qadv is approximately 0 to 0.005, so cutoffs are every 0.00025 (kg/kg)/day
    if plotstodo(6)==1
        destrange=9; %number of possible colors to have in the T pie plots -- options are 9 or 19
        desqrange=9; %number of possible colors to have in the q pie plots -- options are 9 or 19
        for poi=1:numpoi
            lowestavgtfound=1000;highestavgtfound=-1000;
            lowestavgqfound=1000;highestavgqfound=-1000;
            for dir=1:8
                tempt=aztadvarray{poi,3,3}(:,dir);
                avgthere(dir)=mean(tempt(abs(tempt)>0));
                tempq=azqadvarray{poi,3,3}(:,dir);
                avgqhere(dir)=mean(tempq(abs(tempq)>0));
                if avgthere(dir)>highestavgtfound;highestavgtfound=avgthere(dir);end
                if avgthere(dir)<lowestavgtfound;lowestavgtfound=avgthere(dir);end
                if avgqhere(dir)>highestavgqfound;highestavgqfound=avgqhere(dir);end
                if avgqhere(dir)<lowestavgqfound;lowestavgqfound=avgqhere(dir);end
            end
            %Now we know the ranges of the variables for this day, so we can multiply them by the appropriate factors to get a range of 1-20
            rangetnow=highestavgtfound-lowestavgtfound;factort=rangetnow/destrange;
            rangetnew=rangetnow/factort;highestavgtnew=highestavgtfound/factort;lowestavgtnew=lowestavgtfound/factort;
            numtoaddorsubtrt=1-lowestavgtnew;highestavgtnew=highestavgtnew+numtoaddorsubtrt;lowestavgtnew=lowestavgtnew+numtoaddorsubtrt;
            rangeqnow=highestavgqfound-lowestavgqfound;factorq=rangeqnow/desqrange;
            rangeqnew=rangeqnow/factorq;highestavgqnew=highestavgqfound/factorq;lowestavgqnew=lowestavgqfound/factorq;
            numtoaddorsubtrq=1-lowestavgqnew;highestavgqnew=highestavgqnew+numtoaddorsubtrq;lowestavgqnew=lowestavgqnew+numtoaddorsubtrq;
            for dir=1:8
                roundedavgt(dir)=round2((avgthere(dir)/factort+numtoaddorsubtrt),1);
                if roundedavgt(dir)<1;roundedavgt(dir)=1;end %coldest possible color
                if roundedavgt(dir)>destrange+1;roundedavgt(dir)=destrange+1;end %warmest possible color
                if isnan(avgthere(dir));roundedavgt(dir)=destrange+2;end %no winds from this azimuth so plot in gray
                roundedavgq(dir)=round2((avgqhere(dir)/factorq+numtoaddorsubtrq),1);
                if roundedavgq(dir)<1;roundedavgq(dir)=1;end %coldest possible color
                if roundedavgq(dir)>desqrange+1;roundedavgq(dir)=desqrange+1;end %warmest possible color
                if isnan(avgqhere(dir));roundedavgq(dir)=desqrange+2;end %no winds from this azimuth so plot in gray
            end
            if abs(rangetnow)<10;roundtprec=2;else roundtprec=2;end
            roundedlowestavgtfound=roundsd(lowestavgtfound,roundtprec);
            roundedhighestavgtfound=(roundsd(highestavgtfound,roundtprec));
            if abs(rangeqnow)>0.001;roundqprec=2;else roundqprec=2;end %2 should be good for all
            roundedlowestavgqfound=roundsd(lowestavgqfound,roundqprec);
            roundedhighestavgqfound=(roundsd(highestavgqfound,roundqprec));
            
            %Calculate appropriate steps for each variable based on its range
            if abs(factort)<10;roundtprec=2;else roundtprec=2;end
            stepthere=roundsd(factort,roundtprec);
            rangethere=roundedlowestavgtfound:stepthere:roundedhighestavgtfound;
            rangethere2={};for i=1:size(rangethere,2);rangethere2{i}=num2str(rangethere(i));end
            %Repeat because the above is acting temperamental in the plots
            longerstept=(roundedhighestavgtfound-roundedlowestavgtfound)/7.5; %to get 8 numbers spanning the observed range
            roundtprec=1;
            longerstept=roundsd(longerstept,roundtprec);
            rangethere=roundedlowestavgtfound:longerstept:roundedhighestavgtfound;
            rangethere2={};for i=1:size(rangethere,2);rangethere2{i}=num2str(rangethere(i));end
            
            longerstepq=(roundedhighestavgqfound-roundedlowestavgqfound)/7.5; %to get 8 numbers spanning (or slightly less than spanning) the observed range
            roundqprec=2;
            longerstepq=roundsd(longerstepq,roundqprec);
            rangeqhere=roundedlowestavgqfound:longerstepq:roundedhighestavgqfound;
            rangeqhere2={};for i=1:size(rangeqhere,2);rangeqhere2{i}=num2str(1000*rangeqhere(i));end
            %disp(rangehere2);disp(class(rangehere2));
            %convlowestvaluefound=round2((avghere(relmoist,dir)/factor+numtoaddorsubtr),1);
            %convhighestvaluefound=round2((avghere(relmoist,dir)/factor+numtoaddorsubtr),1);
            %if convhighestvaluefound>20;convhighestvaluefound=20;end %can't go higher than 20 by diktat
            %if convlowestvaluefound<-20;convlowestvaluefound=-20;end

            %Time to make the plots        
            figure('Color',[1 1 1]);
            X=[1 1 1 1 1 1 1 1]; %for a pie chart with eight even sections
            if destrange==19
                possiblecolors=[colors('dark magenta');colors('lilac');colors('purple');colors('warm purple');colors('fuchsia');...
                    colors('indigo');colors('blue');colors('light blue');colors('sky blue');colors('dark turquoise');...
                    colors('jade');colors('green');colors('light green');colors('mint');colors('yellow');colors('light orange');...
                    colors('orange');colors('light red');colors('red');colors('crimson')]; %20 possible colors
            elseif destrange==9
                possiblecolors=[colors('dark magenta');colors('purple');colors('blue');colors('light blue');colors('jade');colors('green');
                    colors('light green');colors('yellow');colors('light orange');colors('red')]; %10 possible colors
            end
            nancolor=colors('gray');
            labels={'','','','','','','',''};

            %First show pie plot for T
            subplot(2,1,1);
            p=pie(X,labels);hold on;
            for dir=1:8
                actualdir=9-dir; %pie function and my wind conventions both start in N but go in opposite directions, so need to account for that
                hp=findobj(p,'Type','patch');
                if roundedavgt(actualdir)==destrange+2 %average NaN
                    set(hp(dir),'FaceColor',nancolor(roundedavgt(actualdir)-(destrange+1),:));
                else
                    set(hp(dir),'FaceColor',possiblecolors(roundedavgt(actualdir),:));
                end
            end
            phrpart1='Advective Contribution to Daily Changes in T by Wind-Azimuth Direction';
            phrpart2=sprintf('All JJA Days, For %s Gridpoint',poinames{poi});
            title({phrpart1,phrpart2},'FontSize',20,'FontName','Arial','FontWeight','bold');
            set(gcf,'ColorMap',possiblecolors(lowestavgtnew:highestavgtnew,:)); %moved the limits around such the data span all 20 colors
            cb=colorbar;
            set(cb,'YTickLabel',rangethere2);%disp(rangethere2);
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','bold');
            text(2,0.3,'K/day','FontSize',15,'FontName','Arial','FontWeight','bold');
            %Now plot q
            subplot(2,1,2);
            p=pie(X,labels);hold on;
            for dir=1:8
                actualdir=9-dir; %pie function and my wind conventions both start in N but go in opposite directions, so need to account for that
                hp=findobj(p,'Type','patch');
                if roundedavgq(actualdir)==desqrange+2 %average NaN
                    set(hp(dir),'FaceColor',nancolor(roundedavgq(actualdir)-(desqrange+1),:));
                else
                    set(hp(dir),'FaceColor',possiblecolors(roundedavgq(actualdir),:));
                end
            end
            phrpart1='Advective Contribution to Daily Changes in q by Wind-Azimuth Direction';
            phrpart2=sprintf('All JJA Days, For %s Gridpoint',poinames{poi});
            title({phrpart1,phrpart2},'FontSize',20,'FontName','Arial','FontWeight','bold');
            set(gcf,'ColorMap',possiblecolors(lowestavgqnew:highestavgqnew,:)); %moved the limits around such the data span all 20 colors
            cb=colorbar;
            set(cb,'YTickLabel',rangeqhere2);%disp(rangeqhere2);
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','bold');
            text(2,0.3,'(g/kg)/day','FontSize',15,'FontName','Arial','FontWeight','bold');
            figc=figc+1;
        end
    end
    
    %Histogram of azimuths during very moist and less-moist heat waves, and for all JJA days
    if plotstodo(7)==1
        %Arrange the data better
        %Once it's in...
        for i=1:8;vmpercents(i)=sum(histogramvmdata(:,i))/sum(sum(histogramvmdata));end
        for i=1:8;lmpercents(i)=sum(histogramlmdata(:,i))/sum(sum(histogramlmdata));end
        for i=1:8;alljjapercents(i)=sum(histogramalljja(:,i))/sum(sum(histogramalljja));end
        figure(figc);clf;figc=figc+1;
        centers=1:8;
        subplot(1,3,1);h=bar(centers,vmpercents);
        set(gca,'FontName','Arial','FontSize',15,'FontWeight','bold');
        set(gca,'xticklabel',str2mat('NNE','ENE','ESE','SSE','SSW','WSW','WNW','NNW'),'FontName','Arial','FontSize',11,'FontWeight','bold');
        phrpart2='Very Moist Heat Waves';
        title({phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');
        

        subplot(1,3,2);h=bar(centers,lmpercents);
        set(gca,'xticklabel',str2mat('NNE','ENE','ESE','SSE','SSW','WSW','WNW','NNW'));
        phrpart1='Relative Frequency of Azimuths at NYC Gridpoint';phrpart2='Less-Moist Heat Waves';
        title({phrpart1,phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');set(gca,'FontName','Arial','FontSize',11,'FontWeight','bold');

        subplot(1,3,3);h=bar(centers,alljjapercents);
        set(gca,'xticklabel',str2mat('NNE','ENE','ESE','SSE','SSW','WSW','WNW','NNW'));
        phrpart2='All JJA Days';
        title({phrpart2},'FontName','Arial','FontSize',20,'FontWeight','bold');set(gca,'FontName','Arial','FontSize',11,'FontWeight','bold');
    end
end


%Calculate rates of 'advection' (adiabatic warming/cooling) from vertical motion
if calcomegaadvection==1
    
end

%Make heat-wave-time-series plots of T, WBT, wind azimuth, and wind magnitude over the 120 hours of short-only
%heat waves for a selection of NARR gridpoints nearest JFK, LGA, and EWR in direct analogy to the
%comparative station-data plots produced just above
if comparativehwtimeseries==1
    %First, find gridpts closest to JFK (40.64 N, 73.79 W), LGA (40.775 N, 73.87 W), and EWR (40.69 N, 74.18 W)
    %Because they are between NARR gridpts, and the NARR gridpts are far apart relative to the interstation distance,
    %JFK/LGA/EWR are represented here by a unique combination of weighted NARR gridpts and not just the single closest
    jfkgridpt=wnarrgridpts(40.64,-73.79,1,0);
    lgagridpt=wnarrgridpts(40.775,-73.87,1,0);
    ewrgridpt=wnarrgridpts(40.69,-74.18,1,0);
    tempvec={};wbtvec={};windazvec={};windmagvec={};
    tempvecavg={};wbtvecavg={};windazvecavg={};windmagvecavg={};
    for stn=3:5 %JFK,LGA,EWR approximations from NARR gridpts
        fprintf('Current station is %s\n',prhcodes{stn});
        for j=1:8
            eval(['latpt(j)=' prhcodes{stn} 'gridpt(j,1);']);
            eval(['lonpt(j)=' prhcodes{stn} 'gridpt(j,2);']);
            eval(['weight(j)=' prhcodes{stn} 'gridpt(j,3);']);
        end
        %for i=1:size(reghwbyTstartsshortonly,1) %i is heat-wave count
        for i=50:50
            year=reghwbyTstartsshortonly(i,2);doyfd=reghwbyTstartsshortonly(i,1);doyld=doyfd+reghwbyTstartsshortonly(i,3)-1;
            monthbefore=0;
            if year>=fpyearnarr && year<=lpyear
                if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
                for doy=doyfd:doyld
                    month=DOYtoMonth(doy,year);
                    if month~=monthbefore %this heat-wave day is in a different month than the previous one
                        %Load in the necessary data
                        curArrt=getnarrdatabymonth(runningremotely,'air',year,month);
                        curArruwnd=getnarrdatabymonth(runningremotely,'uwnd',year,month);
                        curArrvwnd=getnarrdatabymonth(runningremotely,'vwnd',year,month);
                    end
                    monthbefore=month;
                    dayinmonth=DOYtoDOM(doy,year);
                    dayofhw=doy-doyfd+1;
                    fprintf('Current year, month, day of month, and day of heat wave are %d, %d, %d, %d\n',year,month,dayinmonth,dayofhw);
                    curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                    curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);

                    %Save data for the 8 3-hourly readings corresponding to this day at the NARR locations corr to JFK, LGA, and EWR
                    for hr=1:8 %DOI is day of interest; offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                        for varhere=4:5
                            if varhere==1;adj=273.15;else adj=0;end
                            vhn=char(varlist{varhere}); %varherename
                            eval(['arrDOI' hours{hr} vhn '=curArr' vhn '{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                            eval(['thisvec{stn}(i,varhere,(dayofhw-1)*8+hr)=arrDOI' hours{hr} vhn '(latpt(1),lonpt(1))*weight(1)+arrDOI' hours{hr} vhn ...
                                '(latpt(2),lonpt(2))*weight(2)+arrDOI' hours{hr} vhn '(latpt(3),lonpt(3))*weight(3)+arrDOI' hours{hr} vhn ...
                                '(latpt(4),lonpt(4))*weight(4)+arrDOI' hours{hr} vhn '(latpt(5),lonpt(5))*weight(5)+arrDOI' hours{hr} vhn ...
                                '(latpt(6),lonpt(6))*weight(6)+arrDOI' hours{hr} vhn '(latpt(7),lonpt(7))*weight(7)+arrDOI' hours{hr} vhn ...
                                '(latpt(8),lonpt(8))*weight(8);']);
                        end
                    end
                end
            end
        end
    end
end
        
        