%Reads in and analyzes NARR data
%Can only do one set of clusters at a time -- either the original
%bottom-up ones, or the temporal-evolution, seasonality, or diurnality groupings
%If changing scope of analysis to include or exclude May & Sep, need to
%rerun makeheatwaverankingnew and clusterheatwaves loops in analyzenycdata

%Upon starting Matlab:
    %load workspace_analyzenycdata, the five JJA avgs, and cluster-specific arrays
    
%MODIFY SO THAT TOTAL HW AVERAGE IS COMPUTED IN DIURNALITY INSTEAD OF A
%SEPARATE SUPERFLUOUS LOOP CALLED ALLHWDAYS
%JUST NEED TO RUN DIURNALITY OVER ALL HOURS INSTEAD OF <8 HOURSTODO, AND
%SAVE -- THEN CHANGE FIG TITLES ACCORDINGLY


%Load partial or complete workspaces
%load('/Users/colin/Documents/General_Academhics/Research/Exploratory_Plots/workspace_full');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/workspace_readnycdata');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/workspace_analyzenycdata');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/workspace_3hourlyclimoavgs');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjat');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjawbt');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjagh');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjauwnd');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/narravgjjavwnd');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclusterstempevoltwbt');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclusterstempevolghuwndvwnd');
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/computeflexibleclustersseasonality');

%Each matrix of NARR data is comprised of 8x-daily values for a month -- have May-Sep 1979-2014
%Dim 1 is lat; Dim 2 is lon; Dim 3 is pressure (1000, 850, 500, 300, 200); Dim 4 is day of month
preslevels=[1000;850;500;300;200]; %levels that were read and saved

%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\%-=7^][\
%0. Runtime options

%Script-wide settings
allhwdays=0;                        %whether interested in all heat-wave days (the same as diurnality except total avgs are computed, not just for each hour)
tempevol=1;                         %whether interested in temporal evolution (i.e. comparing 3 days prior, first day, & last day)
                                        %in this case, loops through firstday=0:2 in computeflexibleclusters
seasonality=0;                      %whether interested in seasonality (i.e. comparing (May-)Jun, Jul, & Aug(-Sep))
diurnality=0;                       %whether interested in diurnal evolution (i.e. comparing 11 am, 2 pm, 5 pm, and 8 pm)
seasonalitydiurnality=0;            %whether interested in combined seasonality-diurnality criteria (e.g. 11 am in Jun)
                                        %have to plot absolute values since the necessary averages haven't been calculated
firstday=1;                        %for loops that are calculated one at a time, whether to compute
                                        %first day (1), last day (0), both (99), or 3 days prior (2)
    if allhwdays==1 || seasonality==1 || diurnality==1 || seasonalitydiurnality==1;firstday=99;elseif tempevol==1;firstday=0;end
                                         %make sure all days are included for seasonality & diurnality
varsdes=[1;2;3;4;5];                        %variables to compute and plot
                                        %1 for T, 2 for WBT, 3 for GPH, 4 & 5 for u & v wind
    viwf=1;viwl=5;                          %if not computing over all varsdes variables, this is the range to analyze on this run
                                            %numbers refer to the **elements of varsdes**, not necessarily to the absolute variable numbers
seasiwf=1;seasiwl=3;                %for seasonality-related runs, seasons to analyze ((May-)Jun = 1, Jul = 2, Aug(-Sep) = 3)
hourstodo=[1;2;3;4;5;6;7;8];                    %for diurnality-related runs, hours to analyze (8pm = 1, 11pm = 2, etc.)
                                        %if this is changed, be sure to change clustremark{x} below appropriately to eliminate the unincluded hours
vartorankby=1;                      %1 for T, 2 for WBT
compositehotdays=0;                 %whether to analyze hot days (defined by Tmax/WBTmax)
    numd=36;                            %x hottest days to analyze (36 is an avg of once per year when restricting to NARR data)
compositehwdays=1;                  %(mutually exclusive) whether to analyze heat waves (defined by integrated hourly T/WBT values)
redohotdaysfirstc=0;                %whether to reset the count of number of days belonging to each cluster
                                        %this means having to rerun script for both first and last days
redohotdayslastc=0;                 %change in accordance with above
%redohotdaysbothc=0;                %ditto for combined counts
yeariwf=1979;yeariwl=2014;          %years to compute over on this run
monthiwf=6;monthiwl=8;              %months to compute over on this run


%Settings for individual loops (i.e. which to run, and how)
needtoconvert=0;                    %whether to convert from .nc to .mat; target variable is specified within loop (1 min 15 sec/3-hourly data file)
                                        %Accurate data currently exists only for months of heat waves as defined by
                                        %T; for other months, data are off by a vertical level and need to be
                                        %re-downloaded and converted
computeavgfields=0;                 %whether to (re)compute average variable fields (~1 hour/variable)
plotseasonalclimonarrdata=0;        %whether to plot some basic seasonal climo (3 min/variable)
    varsseasclimo=[3];                  %the variables to plot here
organizenarrheatwaves=0;            %whether to re-read and assign to clusters NARR data on heat-wave days (5 sec)
                                    %only one of the below cluster choices & computeusebottomupclusters can be selected at a time

computeflexibleclusters=0;          %whether to compute & plot flexible top-down two/three-cluster anomaly composites 
                                        %for tempevol: 15 min/variable; for seasonality: 30 min/variable; for diurnality: 25 min/variable
computeusebottomupclusters=0;       %whether to get data for days belonging to each bottom-up cluster & plot anomaly composites for them (8 min/variable)
                                        %as long as standard options are used (preslevel=3, compositehwdays=1), then
                                        %everything needed can come from saved workspace
                                        %this must be 0 if tempevol or seasonality options are selected
    k=7;                            %the number of clusters calculated in analyzenycdata; any number b/w 5 and 9 is supported                                 
    preslevel=3;                    %for geopotential height, pressure level of interest (as given by preslevels)
savetotalsintoarrays=0;             %whether to save 'totals' computed in the prior two sections into the arrays needed in the following section (5 sec)
                                        %depending on flexiblecluster selection & what's been computed so far, possible clusters are
                                        %1-8+10, 101-103, 201-203, 301-304, or 401-424 (i.e. 3 seasons and 8 possible hourstodo)
    if allhwdays==1
        clmin=10;clmax=10;
    elseif tempevol==1
        clmin=101;clmax=103;
    elseif seasonality==1
        clmin=201;clmax=203;
    elseif diurnality==1
        clmin=301;clmax=304;
    elseif seasonalitydiurnality==1
        clmin=401;clmax=424;
    end
plotheatwavecomposites=0;           %whether to plot NARR heat-wave data (2 min)
    shownonoverlaycompositeplots=0; %whether to show individual composites of temp, shum, or geopotential (chosen by underlaynum)
    showoverlaycompositeplots=1;    %(mutually exclusive) whether to show composites of wind overlaid with another variable
    clustdes=102;                     %cluster to plot -- 0 (full unclustered data), anything from 1 to k (bottom-up clusters), 
                                      %10 (hours, for all heat-wave days),
                                      %101-103 (days, for temporal evolution), 201-203 (seasons, for seasonality),
                                      %301-304 (hours, for diurnality), 401-424 (combined seasonality-diurnality)
                                      %cluster number must be consistent with tempevol/seasonality/etc choice on this run
    overlay=1;                      %whether to overlay something (wind and possibly something else as well)
        underlaynum=1;              %variable to underlay with shading
        overlaynum=3;               %variable to overlay with lines or contours (4 implies 5 because wind components are inseparable)
        overlaynum2=4;              %second variable to overlay (0 or 4 (implying 5)); i.e. only wind can be 2nd overlay
        anomfromjjaavg=1;           %whether to plot heat-wave composites as anomalies from JJA avg fields
        clusteranomfromavg=0;       %additionally, whether to plot each cluster as an anomaly from the all-cluster avg
    mapregion='us-ne';       %size of map region for plots made on this run (see Section I for sizes)
                                        %only operational for overlaynum of 1 to 3, and overlaynum2~=0
plotcompositeddifferences=0;        %whether to plot difference composites, e.g. of T between first and last days (1 min 30 sec)
showindiveventplots=0;              %whether to show maps of T, WBT, &c for each event w/in the 15 hottest reg days covered by NARR,
                                        %with station observations overlaid (1 min per plot)
showdaterankchart=0;                %whether to show chart comparing hot days ranked by T and WBT
maketriangleplots=1;                %whether to make triangular plots showing *relative* WBT at JFK, LGA, EWR at particular hours & in particular seasons
    v1=2;v2=2;                          %range of variables to plot
makewindarrowplots=0;               %whether to make plots comparing the wind vectors at JFK, LGA, EWR at particular hours & in particular seasons
calcplotwindspeedcorrels=0;         %whether to compute and plot the correl of wind speed with temperature change (~advection) by station, hour, & season



%I. For Science
mapregionsize3='north-america';%larger region to plot over ('north-america', 'na-east','usa-exp', or 'usa')
mapregionsize2='us-ne';       %region to plot over for climatology plots only
mapregionsize1='nyc-area';    %local region to plot over ('nyc-area' or 'us-ne')
fpyear=1979;lpyear=2014;      %first & last possible years
fpmonth=5;lpmonth=9;          %first & last possible months
deslat=41.068;deslon=-73.709; %default location to calculate closest NARR gridpoints for
%%%Times in the netCDF files are UTC, so these hours are EDT and begin the previous day%%%
hours={'8pm';'11pm';'2am';'5am';'8am';'11am';'2pm';'5pm'}; %the 'standard hours'
prefixes={'atlcity';'bridgeport';'islip';'jfk';'lga';'mcguireafb';'newark';'teterboro';'whiteplains'};
varlist={'air';'shum';'hgt';'uwnd';'vwnd'};
varlist2={'t';'wbt';'gh';'uwnd';'vwnd'};varlist3={'t';'wbt';'gp';'wnd';'wnd'};
varlistnames={'1000-hPa Temp.';'1000-hPa Wet-Bulb Temp.';sprintf('%d-hPa Geopot. Height',preslevels(preslevel));
    '1000-hPa Wind';'1000-hPa Wind'};
varargnames={'temperature';'wet-bulb temp';'height';'wind';'wind'};
%examples of vararginnew are in the preamble of plotModelData

%II. For Managing Files
curDir='/Volumes/Mac-Formatted 4TB External Drive/NARR_3-hourly_data_mat';
savingDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
figloc=sprintf('%s/Plots/',savingDir); %where figures will be placed
missingymdailyair=[];missingymdailyshum=[];missingymdailyuwnd=[];missingymdailyvwnd=[];missingymdailyhgt=[];
lsmask=ncread('land.nc','land')';



%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?%+--.?
%Start of script

if needtoconvert==1
    %Converts raw .nc files to .mat ones using handy function courtesy of Ethan
    %rawNcDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Raw_nc_files';
    rawNcDir='/Volumes/Mac-Formatted 4TB External Drive/NARR_3-hourly_raw_activefiles';
    %outputDir='/Users/colin/Documents/General_Academics/Research/Exploratory_Plots';
    outputDir='/Volumes/Mac-Formatted 4TB External Drive/NARR_3-hourly_data_mat';
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

    
%Stuff that always needs to be done
a=size(prefixes);numstns=a(1);
exist figc;if ans==0;figc=1;end
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
mons={'jan';'feb';'mar';'apr';'may';'jun';'jul';'aug';'sep';'oct';'nov';'dec'};
prespr={'';'';sprintf('%d-mb ',preslevels(preslevel));'';''};
overlayvar=varargnames{overlaynum};underlayvar=varargnames{underlaynum};
if overlaynum2~=0;overlayvar2=varargnames{overlaynum2};end
narrsz=[277;349]; %size of lat & lon arrays from NARR
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
if tempevol==1 || seasonality==1;timespanlb=1;elseif diurnality==1 || seasonalitydiurnality==1;timespanlb=2;end
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
for i=401:424
    season=round2(i/8,1,'ceil')+150;hour=rem(i,8)+300;if hour==0;hour=8+300;end
    clustremark{i}=strcat(clustremark{season},clustremark{hour});
end
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
    elseif firstday==2
        dayremark='for 3 Days Prior to'; 
    end
    if tempevol==1 || allhwdays==1
        dayremark='for'; %don't need to specify a day remark in the title in this case
    end
end
if overlay==1;contouropt=0;else contouropt=1;end
if anomfromjjaavg==1;cbsetting='regional10';else cbsetting='regional25';end


%Compute average NARR variable fields for [M]JJA[S] (so anomalies can be defined with respect to them)
%WBT formula is from Stull 2011, with T in C and RH in %
if computeavgfields==1 
    %for variab=1:size(varsdes,1)
    for variab=viwf:viwl
        total=zeros(277,349);totalprev=zeros(277,349);
        for hr=1:8;eval(['total' hours{hr} '=zeros(277,349);']);eval(['totalprev' hours{hr} '=zeros(277,349);']);end
        if strcmp(varlist(varsdes(variab)),'air');adj=273.15;else adj=0;end
        for mon=monthiwf:monthiwl
            validthismonc=0;
            narravgthismont=zeros(277,349);narravgthismonshum=zeros(277,349);
            narravgthismongh=zeros(277,349);narravgthismonuwnd=zeros(277,349);narravgthismonvwnd=zeros(277,349);
            thismonlen=eval(['m' num2str(mon+1) 's-m' num2str(mon) 's']);
            for year=1987:1987
                narrryear=year-1979+1;
                ymmissing=0;
                missingymdaily=eval(['missingymdaily' char(varlist{varsdes(variab)})]);
                for row=1:size(missingymdailyair,1)
                    if mon==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                end
                if ymmissing==1 %Do nothing, just skip the month
                else
                    validthismonc=validthismonc+1;
                    fprintf('Current year and month are %d, %d\n',year,mon);
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
                    if varsdes(variab)==3 %height, where we are most interested in the 500-hPa level
                        for hr=1:8
                            curtotaltoworkon=eval(['total' hours{hr}]);
                            curtotaltoworkon=curtotaltoworkon+sum(curArr{3}(:,:,3,hr:8:size(curArr{3},4)),4);
                            eval(['total' hours{hr} '=curtotaltoworkon;']);
                        end
                    else %1000-hPa level for everything else
                        for hr=1:8
                            curtotaltoworkon=eval(['total' hours{hr}]);
                            curtotaltoworkon=curtotaltoworkon+sum(curArr{3}(:,:,1,hr:8:size(curArr{3},4)),4);
                            eval(['total' hours{hr} '=curtotaltoworkon;']);
                            if varsdes(variab)==2 %also have to include T in this circumstance
                                prevtotaltoworkon=eval(['totalprev' hours{hr}]);
                                prevtotaltoworkon=prevtotaltoworkon+sum(prevArr{3}(:,:,1,hr:8:size(prevArr{3},4)),4);
                                eval(['totalprev' hours{hr} '=prevtotaltoworkon;']);
                            end
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
                %Convert specific humidity to mixing ratio
                narravgthismonmr=narravgthismonshum./(1-narravgthismonshum);
                %Get saturation values from temperature
                narravgthismones=6.11*10.^(7.5*narravgthismont./(237.3+narravgthismont));
                %Convert saturation vp to saturation mr, assuming P=1000
                narravgthismonws=0.622*narravgthismones/1000;
                %RH=w/ws
                narravgthismonrh=100*narravgthismonmr./narravgthismonws;
                %Finally, use T and RH to compute WBT
                narravgthismonwbt=narravgthismont.*atan(0.151977.*(narravgthismonrh+8.313659).^0.5)+...
                    atan(narravgthismont+narravgthismonrh)-atan(narravgthismonrh-1.676331)+...
                    0.00391838.*(narravgthismonrh.^1.5).*atan(0.0231.*narravgthismonrh)-4.686035;

                %Now do these shum->WBT steps for each of the 8 standard hours
                for hr=1:8
                    tarr=eval(['narravgthismont' hours{hr}]);
                    shumarr=eval(['narravgthismonshum' hours{hr}]);
                    narravgthismonmrthishr=shumarr./(1-shumarr);
                    narravgthismonesthishr=6.11*10.^(7.5*tarr./(237.3+tarr));
                    narravgthismonwsthishr=0.622*narravgthismonesthishr/1000;
                    narravgthismonrhthishr=100*narravgthismonmrthishr./narravgthismonwsthishr;
                    narravgthismonwbtthishr=tarr.*atan(0.151977.*(narravgthismonrhthishr+8.313659).^0.5)+...
                        atan(tarr+narravgthismonrhthishr)-atan(narravgthismonrhthishr-1.676331)+...
                        0.00391838.*(narravgthismonrhthishr.^1.5).*atan(0.0231.*narravgthismonrhthishr)-4.686035;
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
        
        matrix1=eval(['narravgjja' varlist2{varsseasclimo(variab)}]);
        data1={lats;lons;matrix1};
        matrix2=eval(['narravgjja' varlist2{varsseasclimo(variab)} '5am']);
        data2={lats;lons;matrix2};
        matrix3=eval(['narravgjja' varlist2{varsseasclimo(variab)} '5pm']);
        data3={lats;lons;matrix3};
        if scalarvar==1
            plotModelData(data1,mapregionsize2,vararginnew,'NARR');figc=figc+1;
            title(sprintf('Average Daily %s for JJA, %d-%d',char(varlistnames{varsseasclimo(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            plotModelData(data2,mapregionsize2,vararginnew,'NARR');figc=figc+1;
            title(sprintf('Average 5AM %s for JJA, %d-%d',char(varlistnames{varsseasclimo(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
            plotModelData(data3,mapregionsize2,vararginnew,'NARR');figc=figc+1;
            title(sprintf('Average 5PM %s for JJA, %d-%d',char(varlistnames{varsseasclimo(variab)}),yeariwf,yeariwl),...
                'FontSize',16,'FontWeight','bold');
        end
        
        if scalarvar==0
            if strcmp(varlist(varsseasclimo(variab)),'uwnd')
                uwndmatrix=matrix; %save uwnd data
            elseif strcmp(varlist(varsseasclimo(variab)),'vwnd')
                vwndmatrix=matrix;
                %Now I can plot because uwnd has already been read in
                data={lats;lons;uwndmatrix;vwndmatrix};
                vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';data};
                plotModelData(data,mapregionsize2,vararginnew,'NARR');
            end
        end  
    end
end
    

%Already have an ordered list of the hottest region-wide days (reghwbyXstarts), so just need
%to analyze the subset that are within the 1979-2014 NARR period of record
%Also, choose subsets of data to analyze on this run according to the
%strictures of tempevol, seasonality, or diurnality

%Select number of hot days to include in this analysis by setting numd
%Temperature is a proxy for availability of the data at all
if organizenarrheatwaves==1
    hoteventsarrs={};heahelper=0;
    plotdays={};
    reghwstarts=eval(['reghw' rankby{vartorankby} 'starts']);
    if compositehotdays==1
        numtodo=numd;vecsize=10000;
    elseif compositehwdays==1
        numtodo=eval(['numreghws' rankby{vartorankby}]);
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
            %Don't include in ranking any months whose NARR data is missing
            for i=1:size(missingymdailyair,1)
                if thismon==missingymdailyair(i,1) && thisyear==missingymdailyair(i,2)
                    thismonmissing=1;
                end
            end
            %if compositehotdays==1 %only interested in heat waves now
            %    if dailymaxXregsorted{categ}(rowtosearch,3)>=1979 && thismonmissing==0 &&...
            %            dailymaxXregsorted{categ}(rowtosearch,2)>=152 && dailymaxXregsorted{categ}(rowtosearch,2)<=243
            %        plotdays{categ,1,firstday+1}(rowtomake,1)=dailymaxXregsorted{categ}(rowtosearch,2);
            %        plotdays{categ,1,firstday+1}(rowtomake,2)=dailymaxXregsorted{categ}(rowtosearch,3);
            %        rowtomake=rowtomake+1;
            %    end
            if compositehwdays==1
                reghwbystarts=eval(['reghw' rankby{categ} 'starts']);
                if reghwbystarts(rowtosearch,2)>=1979 && reghwbystarts(rowtosearch,2)<=2014 && thismonmissing==0
                    if allhwdays==1 %all post-1979 heat-wave days in reghwbystarts will be included
                        plotdays{categ,1}(rowtomake,1)=reghwbystarts(rowtosearch,1);
                        plotdays{categ,1}(rowtomake+1,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1;
                        plotdays{categ,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        plotdays{categ,1}(rowtomake+1,2)=reghwbystarts(rowtosearch,2);
                        rowtomake=rowtomake+2;
                    elseif tempevol==1 || computeusebottomupclusters==1 || diurnality==1 %first-vs-last-days types of analysis
                        plotdays{categ,2,2}(rowtomake,1)=reghwbystarts(rowtosearch,1); %days of first days
                        plotdays{categ,2,1}(rowtomake,1)=reghwbystarts(rowtosearch,1)+reghwbystarts(rowtosearch,3)-1; %last days
                        plotdays{categ,2,3}(rowtomake,1)=reghwbystarts(rowtosearch,1)-3; %3 days prior
                        plotdays{categ,2,2}(rowtomake,2)=reghwbystarts(rowtosearch,2); %years of first days
                        plotdays{categ,2,1}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        plotdays{categ,2,3}(rowtomake,2)=reghwbystarts(rowtosearch,2);
                        rowtomake=rowtomake+1;
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
                        rowtomake=rowtomake+1;
                    end
                end
            end
            rowtosearch=rowtosearch+1;
        end
        %Eliminate zero rows
        if seasonality==1 || seasonalitydiurnality==1;for i=1:3;for j=1:2;plotdays{1,3,i,j}=plotdays{1,3,i,j}(any(plotdays{1,3,i,j},2),:);end;end;end
        %Sort plotdays chronologically to get a nice clean list of what we're going to be looking for
        if computeusebottomupclusters==1;for i=1:3;plotdays{categ,1,i}=sortrows(plotdays{categ,1,i},[2 1]);end;end
        if computeusebottomupclusters==1;plotdays{categ,1}=sortrows(plotdays{categ,1},[2 1]);end
        if tempevol==1;for i=1:3;plotdays{categ,2,i}=sortrows(plotdays{categ,2,i},[2 1]);end;end %i is first & last days
        if seasonality==1 || seasonalitydiurnality==1;for i=1:3;for j=1:2;plotdays{categ,3,i,j}=sortrows(plotdays{categ,3,i,j},[2 1]);end;end;end
             %i is season, j is first & last days
        if diurnality==1;for i=1:2;plotdays{categ,4,i}=plotdays{categ,2,i};end;end %i is first & last days

        %Bottom-up clusters' data is identical to that calculated for tempevol
        if computeusebottomupclusters==1;if tempevol==1;for i=1:3;plotdays{categ,1,i}=plotdays{categ,2,i};end;end;end
    end
end

%Flexible top-down 'cluster' composites (just groupings, not actually k-means-defined)
%Uses plotdays as computed in the previous loop
if computeflexibleclusters==1
    if allhwdays==1
        %avgsallhwdays={};
        for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
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
                        for row=1:size(plotdays{vartorankby,1},1)
                            if plotdays{vartorankby,1}(row,2)==year && plotdays{vartorankby,1}(row,1)>=curmonstart...
                                    && plotdays{vartorankby,1}(row,1)<curmonstart+curmonlen
                                dayinmonth=plotdays{vartorankby,1}(row,1)-curmonstart+1;disp(dayinmonth);
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
                                if lastdayofmonth==1;nextmonArr=eval(['nextmonFile.' lastpartnextmon]);end


                                %if hotdaysc>=1;oldDOI=arrDOI;end %this is sort of outdated (oldDOI only needed for hoteventsarrs)
                                if strcmp(varlist(varsdes(variab)),'hgt')
                                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,preslevel,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,preslevel,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                        else
                                            eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,preslevel,1*8+ ' num2str(hr-8) ')-adj;']);
                                        end
                                    end
                                else
                                    for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                        eval(['arrDOI' hours{hr} '=curArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                        if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                            eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,1,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                        else
                                            eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,1,1*8+ ' num2str(hr-8) ')-adj;']);
                                        end
                                    end
                                    %Compute WBT from T and RH (see average-computation loop above for details)
                                    if strcmp(varlist{varsdes(variab)},'shum')
                                        for hr=1:8
                                            arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                            arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                            mrArr=arrDOIthishr./(1-arrDOIthishr);
                                            esArr=6.11*10.^(7.5*arrDOIprevthishr./(237.3+arrDOIprevthishr));
                                            wsArr=0.622*esArr/1000;
                                            rhArr=100*mrArr./wsArr;
                                            eval(['arrDOIwbt=arrDOIprevthishr.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                                'atan(arrDOIprevthishr+rhArr)-atan(rhArr-1.676331)+'...
                                                '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                                            %Save data
                                            eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;'])
                                        end
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
                avgsallhwdays{varsdes(variab),10}=totalwbt/(hotdaysc*8); %10 is daily avg, 1-8 are standard hours
                %dimensions of avgsallhwdays are variable|cluster#|time(dailyavg,stdhour,&c)
                for hr=1:8
                    eval(['avgsallhwdays{varsdes(variab),' num2str(hr) '}=totalwbt' hours{hr} '/hotdaysc;']);
                end
            else
                avgsallhwdays{varsdes(variab),10}=total/(hotdaysc*8);
                for hr=1:8
                    eval(['avgsallhwdays{varsdes(variab),' num2str(hr) '}=total' hours{hr} '/hotdaysc;']);
                end
            end
        end
    elseif tempevol==1
        %avgstempevol={};
        for firstday=0:2 %full is 0-2
            for hr=1:8;eval(['totalwbt' hours{hr} '=zeros(narrsz(1),narrsz(2));']);end
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
                                    if lastdayofmonth==1;nextmonArr=eval(['nextmonFile.' lastpartnextmon]);end
                                        

                                    %if hotdaysc>=1;oldDOI=arrDOI;end %this is sort of outdated (oldDOI only needed for hoteventsarrs)
                                    if strcmp(varlist(varsdes(variab)),'hgt')
                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,preslevel,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,preslevel,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,preslevel,1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                    else
                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,1,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,1,1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                        %Compute WBT from T and RH (see average-computation loop above for details)
                                        if strcmp(varlist{varsdes(variab)},'shum')
                                            for hr=1:8
                                                arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                                arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                mrArr=arrDOIthishr./(1-arrDOIthishr);
                                                esArr=6.11*10.^(7.5*arrDOIprevthishr./(237.3+arrDOIprevthishr));
                                                wsArr=0.622*esArr/1000;
                                                rhArr=100*mrArr./wsArr;
                                                eval(['arrDOIwbt=arrDOIprevthishr.*atan(0.151977.*(rhArr+8.313659).^0.5)+'...
                                                    'atan(arrDOIprevthishr+rhArr)-atan(rhArr-1.676331)+'...
                                                    '0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;']);
                                                %Save data
                                                eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;'])
                                            end
                                            %for hr=2:8;eval(['totalwbt=totalwbt+arrDOIwbt' hours{hr} ';']);end
                                            %totalwbt=totalwbt+arrDOI2amnextday;
                                        end
                                    end
                                    %Save data
                                    for hr=1:8
                                        eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);
                                    end
                                    %total=total+arrDOI;
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
                    avgstempevol{varsdes(variab),firstday+fdo,10}=totalwbt/(hotdaysc*8); %10 is daily avg, 1-8 are standard hours
                    %dimensions of avgstempevol are variable|cluster#|time(dailyavg,stdhour,&c)
                    for hr=1:8
                        eval(['avgstempevol{varsdes(variab),firstday+fdo,' num2str(hr) '}=totalwbt' hours{hr} '/hotdaysc;']);
                    end
                else
                    avgstempevol{varsdes(variab),firstday+fdo,10}=total/(hotdaysc*8);
                    for hr=1:8
                        eval(['avgstempevol{varsdes(variab),firstday+fdo,' num2str(hr) '}=total' hours{hr} '/hotdaysc;']);
                    end
                end
            end
        end
    end
    if seasonality==1 %here firstday is preset to 99
        avgsseasonality={};
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
                                        if lastdayofmonth==1;nextmonArr=eval(['nextmonFile.' lastpartnextmon]);end


                                        %if hotdaysc>=1;oldDOI=arrDOI;end %this is sort of outdated (oldDOI only needed for hoteventsarrs)
                                        if strcmp(varlist(varsdes(variab)),'hgt')
                                            for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                                eval(['arrDOI' hours{hr} '=curArr{3}(:,:,preslevel,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                                    eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,preslevel,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                                else
                                                    eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,preslevel,1*8+ ' num2str(hr-8) ')-adj;']);
                                                end
                                            end
                                        else
                                            for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                                eval(['arrDOI' hours{hr} '=curArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                    eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,1,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                                else
                                                    eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,1,1*8+ ' num2str(hr-8) ')-adj;']);
                                                end
                                            end
                                            %Compute WBT from T and RH (see average-computation loop above for details)
                                            if strcmp(varlist{varsdes(variab)},'shum')
                                                for hr=1:8
                                                    arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                                    arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                    mrArr=arrDOIthishr./(1-arrDOIthishr);
                                                    esArr=6.11*10.^(7.5*arrDOIprevthishr./(237.3+arrDOIprevthishr));
                                                    wsArr=0.622*esArr/1000;
                                                    rhArr=100*mrArr./wsArr;
                                                    arrDOIwbt=arrDOIprevthishr.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                                        atan(arrDOIprevthishr+rhArr)-atan(rhArr-1.676331)+...
                                                        0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                                    %Save data
                                                    eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;']);
                                                end
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
                %Dimensions of avgsseasonality are variable|season|time(dailyavg or stdhour)
                if varsdes(variab)==2
                    avgsseasonality{varsdes(variab),season,10}=totalwbt/(hotdaysc*8); %10 is daily avg, 1-8 are standard hours
                    for hr=1:8
                        eval(['avgsseasonality{varsdes(variab),season,' num2str(hr) '}=totalwbt' hours{hr} '/hotdaysc;']);
                    end
                else
                    avgsseasonality{varsdes(variab),season,10}=total/(hotdaysc*8);
                    for hr=1:8
                        eval(['avgsseasonality{varsdes(variab),season,' num2str(hr) '}=total' hours{hr} '/hotdaysc;']);
                    end
                end
            end
        end
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
                                    if lastdayofmonth==1;nextmonArr=eval(['nextmonFile.' lastpartnextmon]);end


                                    %if hotdaysc>=1;oldDOI=arrDOI;end %this is sort of outdated (oldDOI only needed for hoteventsarrs)
                                    if strcmp(varlist(varsdes(variab)),'hgt')
                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,preslevel,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,preslevel,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,preslevel,1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                    else
                                        for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                            eval(['arrDOI' hours{hr} '=curArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                            if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,1,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                            else
                                                eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,1,1*8+ ' num2str(hr-8) ')-adj;']);
                                            end
                                        end
                                        %Compute WBT from T and RH (see average-computation loop above for details)
                                        if strcmp(varlist{varsdes(variab)},'shum')
                                            for hr=1:8
                                                arrDOIthishr=eval(['arrDOI' hours{hr} ';']);
                                                arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']);
                                                mrArr=arrDOIthishr./(1-arrDOIthishr);
                                                esArr=6.11*10.^(7.5*arrDOIprevthishr./(237.3+arrDOIprevthishr));
                                                wsArr=0.622*esArr/1000;
                                                rhArr=100*mrArr./wsArr;
                                                arrDOIwbt=arrDOIprevthishr.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                                    atan(arrDOIprevthishr+rhArr)-atan(rhArr-1.676331)+...
                                                    0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                                %Save data, keeping hours separate
                                                eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;']);
                                            end
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
            %Dimensions of avgsdiurnality are variable|stdhour
            if varsdes(variab)==2
                for hr=1:size(hourstodo,1) %not interested in all the hours
                    eval(['avgsdiurnality{varsdes(variab),hourstodo(hr)}=totalwbt' hours{hourstodo(hr)} '/hotdaysc;']);
                end
            else
                for hr=1:size(hourstodo,1)
                    eval(['avgsdiurnality{varsdes(variab),hourstodo(hr)}=total' hours{hourstodo(hr)} '/hotdaysc;']);
                end
            end
        end
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
                                        if lastdayofmonth==1;nextmonArr=eval(['nextmonFile.' lastpartnextmon]);end


                                        %if hotdaysc>=1;oldDOI=arrDOI;end %this is sort of outdated (oldDOI only needed for hoteventsarrs)
                                        if strcmp(varlist(varsdes(variab)),'hgt')
                                            for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                                eval(['arrDOI' hours{hr} '=curArr{3}(:,:,preslevel,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's']) %i.e. ~= last day of month
                                                    eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,preslevel,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                                else
                                                    eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,preslevel,1*8+ ' num2str(hr-8) ')-adj;']);
                                                end
                                            end
                                        else
                                            for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                                                eval(['arrDOI' hours{hr} '=curArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-adj;']);
                                                if dayinmonth~=eval(['m' num2str(month+1) 's-m' num2str(month) 's'])
                                                    eval(['arrDOI' hours{hr} 'nextday=curArr{3}(:,:,1,(dayinmonth+1)*8+ ' num2str(hr-8) ')-adj;']);
                                                else
                                                    eval(['arrDOI' hours{hr} 'nextday=nextmonArr{3}(:,:,1,1*8+ ' num2str(hr-8) ')-adj;']);
                                                end
                                            end
                                            %Compute WBT from T and RH (see average-computation loop above for details)
                                            if strcmp(varlist{varsdes(variab)},'shum')
                                                for hr=1:8
                                                    arrDOIthishr=eval(['arrDOI' hours{hr} ';']); %shum
                                                    arrDOIprevthishr=eval(['prevArr{3}(:,:,1,dayinmonth*8+ ' num2str(hr-8) ')-273.15;']); %T
                                                    mrArr=arrDOIthishr./(1-arrDOIthishr);
                                                    esArr=6.11*10.^(7.5*arrDOIprevthishr./(237.3+arrDOIprevthishr));
                                                    wsArr=0.622*esArr/1000;
                                                    rhArr=100*mrArr./wsArr;
                                                    arrDOIwbt=arrDOIprevthishr.*atan(0.151977.*(rhArr+8.313659).^0.5)+...
                                                        atan(arrDOIprevthishr+rhArr)-atan(rhArr-1.676331)+...
                                                        0.00391838.*(rhArr.^1.5).*atan(0.0231.*rhArr)-4.686035;
                                                    %Save data, keeping hours separate
                                                    eval(['totalwbt' hours{hr} '=totalwbt' hours{hr} '+arrDOIwbt;']);
                                                end
                                            end
                                        end
                                        %Save data, keeping hours separate
                                        %Compute daily average as 2am-11pm,
                                        %with 2am listed as the following day because of UTC time difference
                                        for hr=1:8
                                            eval(['total' hours{hr} '=total' hours{hr} '+arrDOI' hours{hr} ';']);
                                        end

                                        hotdaysc=hotdaysc+1;hoteventsc=hoteventsc+1;
                                    end
                                end
                            end
                        end
                    end
                end
                %Assign hourly sums directly to holding array
                %Dimensions of avgsseasdiurn are variable|season|stdhour
                if varsdes(variab)==2
                    for hr=1:size(hourstodo,1)
                        eval(['avgsseasdiurn{varsdes(variab),season,hourstodo(hr)}=totalwbt' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                else
                    for hr=1:size(hourstodo,1)
                        eval(['avgsseasdiurn{varsdes(variab),season,hourstodo(hr)}=total' hours{hourstodo(hr)} '/hotdaysc;']);
                    end
                end
            end
        end
    end
end


if computeusebottomupclusters==1
    %Create corresponding reghwbyTstarts and cluster-memberships list
    %compressed to include only those heat waves for which I have valid NARR data 
    reghwbyTstartsnarr(1:56,:)=reghwbyTstarts(29:84,:);
    %First column of idxnarr is cluster memberships of first days; second, of last days
    idxnarr(1:56,1)=idx(57:2:167,1);idxnarr(1:56,2)=idx(58:2:168,1);
    if firstday==1;idxnarrtouse=idxnarr(:,1);elseif firstday==0;idxnarrtouse=idxnarr(:,2);end
    
    %Read in & sum data on heat-wave days belonging to particular clusters
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
        total=zeros(narrsz(1),narrsz(2));totalwbt=zeros(narrsz(1),narrsz(2));
        for clust=1:k
            eval(['totalcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
            eval(['totalwbtcl' num2str(clust) '=zeros(narrsz(1),narrsz(2));']);
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
                                    hoteventsarrs{hoteventsc-1,variab}=arrEvent; %the actual NARR data
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
    %for variab=1:size(varsdes,1)
    for variab=viwf:viwl
        if strcmp(varlist(varsdes(variab)),'air')
            eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']); %i.e. all the days (no clustering at all)
            %Data for all first days OR last days in each bottom-up cluster
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsallhwdays{1,10};']);
                end
            %Data for the 3 temporal-evolution 'clusters'
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgstempevol{1,' num2str(cl) ',10};']);
                end
            %Data for the 3 seasonality 'clusters'
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{1,' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{1,' num2str(cl) ',10};']);
            %Data for the 4 diurnality 'clusters'
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsdiurnality{1,' num2str(actualhour) '};']);
                end
            %Data for joint seasonality-diurnality 'clusters'
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr1f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasdiurn{1,' num2str(season) ',' num2str(actualhour) '};']);
                end
            end
            %Also make arrays with data from all days in a specific cluster regardless of whether they are first or last
            %Weight cluster average by its composition of first and last days, rather than a straight average of the averages
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr1f99rb' num2str(vartorankby) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'shum') %uses shum but output is WBT
            eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=totalwbt;']);
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalwbtcl' num2str(cl) ';']);end
                cl=99;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalwbtcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsallhwdays{2,10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgstempevol{2,' num2str(cl) ',10};']);
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{2,' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{2,' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsdiurnality{2,' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    disp('line 1540');disp(season);disp(actualhour);
                    eval(['arr2f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasdiurn{2,' num2str(season) ',' num2str(actualhour) '};']);
                end
            end
            if computeusebottomupclusters==1
                if max(max(totalwbtfirstcl1))~=0 && max(max(totalwbtlastcl1))~=0
                    for cl=1:k
                        eval(['arr2f99rb' num2str(vartorankby) 'cl' num2str(cl) '=(totalwbtfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totalwbtlastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'hgt')
            eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']);
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsallhwdays{3,10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgstempevol{3,' num2str(cl) ',10};']);
                end
            elseif seasonality==1 %all with firstday=99
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{3,' num2str(season) ',10};']);
                end
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsdiurnality{3,' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr3f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasdiurn{3,' num2str(season) ',' num2str(actualhour) '};']);
                end
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr3f99rb' num2str(vartorankby) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'uwnd')
            eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']);
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsallhwdays{4,10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgstempevol{4,' num2str(cl) ',10};']);
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{4,' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{4,' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsdiurnality{4,' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr4f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasdiurn{4,' num2str(season) ',' num2str(actualhour) '};']);
                end
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr4f99rb' num2str(vartorankby) 'cl' num2str(cl) '=(totalfirstcl'...
                            num2str(cl) '*hotdaysfirstccl' num2str(cl) '+totallastcl' num2str(cl) '*hotdayslastccl'...
                            num2str(cl) ')/(hotdaysfirstccl' num2str(cl) '+hotdayslastccl' num2str(cl) ');']);
                    end
                end
            end
        elseif strcmp(varlist(varsdes(variab)),'vwnd')
            eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl0=total;']);
            if computeusebottomupclusters==1
                for cl=1:k;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);end
                cl=99;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=totalcl' num2str(cl) ';']);
            elseif allhwdays==1
                for cl=clmin:clmax
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsallhwdays{5,10};']);
                end
            elseif tempevol==1
                for cl=clmin:clmax
                    firstday=cl-fdo;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgstempevol{5,' num2str(cl) ',10};']);
                end
            elseif seasonality==1
                for cl=clmin:clmax
                    season=cl-fdo;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{5,' num2str(season) ',10};']);
                end
                %cl=299;firstday=99;eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasonality{5,' num2str(cl) ',10};']);
            elseif diurnality==1
                for cl=clmin:clmax
                    hour=cl-fdo;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsdiurnality{5,' num2str(actualhour) '};']);
                end
            elseif seasonalitydiurnality==1
                for cl=clmin:clmax
                    season=round2(cl/8,1,'ceil')-50;
                    hour=rem(cl,8);if hour==0;hour=8;end;actualhour=hourstodo(hour);
                    eval(['arr5f' num2str(firstday) 'rb' num2str(vartorankby) 'cl' num2str(cl) '=avgsseasdiurn{5,' num2str(season) ',' num2str(actualhour) '};']);
                end
            end
            if computeusebottomupclusters==1
                if max(max(totalfirstcl1))~=0 && max(max(totallastcl1))~=0
                    for cl=1:k
                        eval(['arr5f99rb' num2str(vartorankby) 'cl' num2str(cl) '=(totalfirstcl'...
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
            if underlaynum==1 || underlaynum==2
                if strcmp(mapregion,'north-america') || strcmp(mapregion,'usa-exp')
                    caxismin(underlaynum)=-7;caxismax(underlaynum)=7;cstep(underlaynum)=0.5;
                elseif strcmp(mapregion,'us-ne') || strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=-2;caxismax(underlaynum)=6;cstep(underlaynum)=0.3;
                else
                    caxismin(underlaynum)=-2;caxismax(underlaynum)=6;cstep(underlaynum)=0.5;
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
            caxismin(1)=-7;caxismax(1)=7;cstep(1)=0.5; %temperature
            caxismin(2)=-5;caxismax(2)=5;cstep(2)=0.5; %WBT
            caxismin(3)=-50;caxismax(3)=100;cstep(3)=10; %gph
            caxismin(4)=-10;caxismax(4)=10;cstep(4)=1; %uwnd
            caxismin(5)=-10;caxismax(5)=10;cstep(5)=1; %vwnd
        end
    else
        if showoverlaycompositeplots==1
            if underlaynum==1
                if strcmp(mapregion,'us-ne') || strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=10;caxismax(underlaynum)=35;cstep(underlaynum)=1;
                elseif strcmp(mapregion,'usa-exp') || strcmp(mapregion,'north-america')
                    caxismin(underlaynum)=5;caxismax(underlaynum)=40;cstep(underlaynum)=1;
                end
            elseif underlaynum==2
                if strcmp(mapregion,'nyc-area')
                    caxismin(underlaynum)=18;caxismax(underlaynum)=25;cstep(underlaynum)=0.3;
                elseif strcmp(mapregion,'us-ne')
                    caxismin(underlaynum)=10;caxismax(underlaynum)=28;cstep(underlaynum)=0.5;
                elseif strcmp(mapregion,'usa-exp') || strcmp(mapregion,'north-america')
                    caxismin(underlaynum)=5;caxismax(underlaynum)=30;cstep(underlaynum)=1;
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
    if allhwdays==1 || diurnality==1 || seasonality==1 || seasonalitydiurnality==1;fdo=clustdes-99;end %clustdes-fdo must be 99 in these cases (to match firstday)
    
    
    %%Make plots themselves%%
    if shownonoverlaycompositeplots==1
        %for variab=1:size(varsdes,1)
        for variab=viwf:viwl
            if anomfromjjaavg==1
                data={lats;lons;...
                eval(['arr' num2str(varsdes(variab)) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-...
                eval(['narravgjja' char(varlist2(varsdes(variab)))])};
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'mystep';cstep(varsdes(variab));'overlaynow';0};
            else
                data={lats;lons;...
                eval(['arr' num2str(varsdes(variab)) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                vararginnew={'variable';varargnames{varsdes(variab)};'contour';1;'plotCountries';1;...
                'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'mystep';cstep(varsdes(variab));'overlaynow';0};
            end
            %disp(max(max(data{3})));
            plotModelData(data,mapregion,vararginnew,'NARR');
            title(sprintf('%s %s %s %s %d %s in the NYC Area as Defined by %s%s',anomavg{anomfromjjaavg+1},...
                timespanremark{timespanlb},char(varlistnames{varsdes(variab)}),dayremark,hotdaysc,hwremark,categlabel,clustremark{clustdes}),...
                'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarr%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(variab)},...
                    varlist3{vartorankby},clustlb,mapregion);
        end
    end
    if overlay==1 && showoverlaycompositeplots==1 %Make single or double overlay
        if overlaynum==4 %wind
            if strcmp(varlist(varsdes(size(varsdes,1))),'vwnd') %if on uwnd, we don't have enough to plot yet
                if anomfromjjaavg==1
                    overlaydata={lats;lons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgjjauwnd;...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgjjavwnd};
                    underlaydata={lats;lons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])...
                        -eval(['narravgjja' char(varlist2(underlaynum))])};
                else
                    overlaydata={lats;lons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])}; %wind (both components)
                    underlaydata={lats;lons;...
                        eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                end
                vararginnew={'variable';'wind';'contour';contouropt;'mystep';cstep(2);'plotCountries';1;...
                    'caxismin';caxismin(varsdes(variab));'caxismax';caxismax(varsdes(variab));'vectorData';overlaydata;'overlaynow';overlay;'overlayvariable';overlayvar;...
                    'underlayvariable';underlayvar;'datatooverlay';overlaydata;'datatounderlay';underlaydata};
                plotModelData(overlaydata,mapregion,vararginnew,'NARR');figc=figc+1;
                %Add title to newly-made figure
                phrpart1=sprintf('%s %s 1000-hPa Wind and %s%s',anomavg{anomfromjjaavg+1},...
                    timespanremark{timespanlb},prespr{underlaynum},char(varlistnames{underlaynum}));
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s',dayremark,hotdaysc,hwremark,categlabel,clustremark{clustdes});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(1)},varlist3{varsdes(2)},...
                    varlist3{vartorankby},clustlb,mapregion);
            end
        elseif overlaynum==1 || overlaynum==2 || overlaynum==3 %scalars
            if anomfromjjaavg==1
                overlaydata={lats;lons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-...
                    eval(['narravgjja' char(varlist2(overlaynum))])};
                underlaydata={lats;lons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-...
                    eval(['narravgjja' char(varlist2(underlaynum))])};
                if clusteranomfromavg==1 %This cluster's anomalies with respect to both the JJA avg and the all-cluster avg
                    overlaydata{3}=overlaydata{3}-(eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl0'])-...
                        eval(['narravgjja' char(varlist2(overlaynum))]));
                    underlaydata{3}=underlaydata{3}-(eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl0'])-...
                        eval(['narravgjja' char(varlist2(underlaynum))]));
                end
                if overlaynum2~=0 %Double overlay (contours+barbs)
                    overlaydata2={lats;lons;...
                        eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgjjauwnd;...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])-narravgjjavwnd};
                    if clusteranomfromavg==1 
                        overlaydata2{3}=overlaydata2{3}-...
                            (eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl0'])-narravgjjauwnd);
                        overlaydata2{4}=overlaydata2{4}-...
                            (eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl0'])-narravgjjavwnd);
                    end
                end
            else
                overlaydata={lats;lons;...
                    eval(['arr' num2str(overlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                underlaydata={lats;lons;...
                    eval(['arr' num2str(underlaynum) 'f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                if overlaynum2~=0
                    overlaydata2={lats;lons;eval(['arr4f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)]);...
                        eval(['arr5f' num2str(clustdes-fdo) 'rb' num2str(vartorankby) 'cl' num2str(clustdes)])};
                end
            end
            
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
            plotModelData(overlaydata,mapregion,vararginnew,'NARR');figc=figc+1;
            
            
            %Add title to newly-made figure and also create filename for saving
            if overlaynum2==0
                phrpart1=sprintf('%s %s %s and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                    char(varlistnames{overlaynum}),prespr{underlaynum},char(varlistnames{underlaynum}));
                if diurnality==1;hotdayscdiurn=round2(hotdaysc/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s',dayremark,hotdaysc,hwremark,categlabel,clustremark{clustdes});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%sby%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{varsdes(underlaynum)},...
                    varlist3{vartorankby},clustlb,mapregion);
            else
                phrpart1=sprintf('%s %s %s, %s, and %s%s',anomavg{anomfromjjaavg+1},timespanremark{timespanlb},...
                    char(varlistnames{overlaynum}),char(varlistnames{overlaynum2}),prespr{underlaynum},char(varlistnames{underlaynum}));
                if diurnality==1;hotdayscdiurn=round2(hotdaysc/2,1,'floor');end %because # heat waves = 0.5*hotdaysc
                phrpart2=sprintf('%s %d NYC-Area %s as Defined by %s%s%s',dayremark,hotdaysc,hwremark,categlabel,...
                    clustremark{clustdes},clustanom{clusteranomfromavg+1});
                title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
                figname=sprintf('synopnarr%s%s%sby%s%s%s%s.fig',anomavg2{anomfromjjaavg+1},varlist3{underlaynum},...
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
        plotModelData(gpdiffarr,mapregion,vararginnew,'NARR');
        
        %Add title and save figure
        if plotnum==1
            phrpart1=sprintf('1000-hPa Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days vs. First Days of T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==2
            phrpart1=sprintf('1000-hPa Wet-Bulb Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days vs. First Days of WBT-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtrankedlastdaysvsfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==3
            phrpart1=sprintf('1000-hPa Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==4
            phrpart1=sprintf('1000-hPa Wet-Bulb Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on Last Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdiffwbtgpwindwbtvstrankedlastdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==5
            phrpart1=sprintf('1000-hPa Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
            phrpart2=sprintf('on First Days of WBT-Ranked vs. T-Ranked NYC-Area Heat Waves%s',clustremark{clustdes});
            title({phrpart1,phrpart2},'FontSize',16,'FontWeight','bold','FontName','Arial');
            figname=sprintf('synopnarrdifftgpwindwbtvstrankedfirstdays%s.fig',clustlb);
            saveas(gcf,sprintf('%s%s',figloc,figname));
        elseif plotnum==6
            phrpart1=sprintf('1000-hPa Wet-Bulb Temp., 1000-hPa Wind, and 500-hPa Geopot. Height');
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
                data={lats;lons;hoteventsarrs{event,3};hoteventsarrs{event,4}};goplot=1;
                vararginnew={'variable';argname;'contour';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting;'vectorData';data};
            else %i.e. any scalar variable
                data={lats;lons;hoteventsarrs{event}};goplot=1;
                vararginnew={'variable';argname;'contour';1;'plotCountries';1;'colormap';'jet';...
                    'caxismethod';cbsetting};
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
                    wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}=wbtortbyseasonandhour{variab,stnc,correspstdhour,season-5}/numdays{stnc,season-5};
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


            
        
        