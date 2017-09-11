%Reads in MesoWest station data that has hourly T, RH, winds, etc
%THIS HAS ALL BEEN SUPERSEDED BY THE NRCC HOURLY DATASET & ANALYZENYCDATA
%Because of the laboriousness of obtaining it, data cover only heatwaves at
%Central Park in the period 2002-14 (see below)
%Primary aim is to compare these point humidity and wind values with NARR
%ones, to establish biases before using the NARR to analyze synoptic conditions 
%(as it not only is spatially continuous but has a longer temporal record, 1979-pres vs 2002-pres)

%***Readnarrdata and readnycdata need to have been run***

%Data are for the severest heatwaves at KNYC (Central Park) contained within the
%MesoWest record, which begins Aug 15, 2002:
%(12) Aug 15-19, 2002 (truncated from Aug 10) -- NOW EXCLUDED
%(15) Jul 18-24, 2011
%(21) Jul 14-22, 2013
%(23) Jul 4-9, 2010
%(24) Aug 2-5, 2005
%(50) Jul 27-Aug 4, 2006
%(51) Jun 24-27, 2003
%(70) Jun 20-22, 2012
%(78) Aug 7-14, 2005
%(82) Jun 20-29, 2010
%(83) Jun 7-11, 2008
%(96) Aug 8-11, 2010
%---of 311 total heatwaves 1876-2014 there---


%Current runtime: several min


%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^
%Runtime options
excludeaug2002=1;       %whether to exclude the Aug 2002 heatwave that's only partially covered by the MW data
rereaddata=0;           %whether to reread the data from the source CSV files
redefinevectors=0;      %whether to redefine the main vectors
checkformissingtimes=0; %whether to do the initial-preparatory step of checking for missing hours in the MW data
recalcwetdryscores=0;   %whether to recalculate hw-severity scores based on temp, dewpt, heat index, WBT
    relativescores=0;       %whether to compute scores with absolute thresholds or relative to each stn's climate
makescatterplot=1;      %whether to show the scatterplot of these scores
    score1=1;score2=4;      %the two scores to compare (of the four options, in the same order as just above)
    groupbyregion=0;        %whether to split into coastal and inland groups (vs each station individually)
    consolidatestns=0;      %whether to plot the average position of each stn (vs one pt per heatwave)
    symbolsbyhw=1;          %whether to plot a different symbol for each heatwave (vs all circles)
    daytimeonly=0;          %whether to plot scores derived only from max/daytime values (vs all hours)
    nighttimeonly=1;        %same as above, but for min/nighttime values
findstnhotevents=0;     %whether to calculate stations' daily-avg temps on predefined regional hot days 1979-2014
comparehourlymaxmin=0;  %whether to go through and compare the (max+min)/2 daily-avg method with the hourly-avg one
%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^%@}[=^

%Other variables to set
numstnsmw=11;
stnprmw={'KEWR';'KTEB';'KNYC';'KLGA';'KJFK';'KACY';'KPHL';'KTTN';'KBDR';'KHPN';'KISP'};
stnpr2mw={'kewr';'kteb';'knyc';'klga';'kjfk';'kacy';'kphl';'kttn';'kbdr';'khpn';'kisp'};
mwstnlocs(:,1)=[40.683;40.85;40.779;40.779;40.639;39.449;39.868;40.277;41.158;41.067;40.794]; %a subset of what's in stnlocs
mwstnlocs(:,2)=[-74.169;-74.061;-73.969;-73.88;-73.762;-74.567;-75.231;-74.816;-73.129;-73.708;-73.102];
mwstnlocs(:,3)=[7;9;130;11;11;60;10;184;5;379;84];mwstnlocs(:,3)=mwstnlocs(:,3)/mf;
%Same data but with hourly-NRCC ordering
stnprhn={'KACY';'KBDR';'KJFK';'KLGA';'KEWR';'KHPN';'KNYC';'KTTN';'KPHL';'KTEB';'KISP'}; 
stnpr2hn={'kacy';'kbdr';'kjfk';'klga';'kewr';'khpn';'knyc';'kttn';'kteb';'kphl';'kisp'};
hnstnlocs(:,1)=[39.449;41.158;40.639;40.779;40.683;41.067;40.779;40.277;39.868;40.85;40.794]; %a subset of what's in stnlocs
hnstnlocs(:,2)=[-74.567;-73.129;-73.762;-73.88;-74.169;-73.708;-73.969;-74.816;-75.231;-74.061;-73.102];
hnstnlocs(:,3)=[60;5;11;11;7;379;130;184;10;9;84];hnstnlocs(:,3)=hnstnlocs(:,3)/mf;

fourvariabs={'Temperature';'Dewpoint';'Heat Index';'WBT'};

acceptt=[49;50;51;52;53;54;55;56]; %acceptable/standard obs times, in min after the hour
%third column in hwstarts is hw length (again, as defined at Central Park)
hwstarts=[223 2002 5;199 2011 7;195 2013 9;185 2010 6;214 2005 4;208 2006 9;175 2003 4;172 2012 3;...
    219 2005 8;171 2010 10;158 2008 5;220 2010 4];

if usingdailyclimoddata==1
    daycol=2;yrcol=3;numstns=numstnsmw;colofncv=2;stnpr=stnprmw;stnpr2=stnpr2mw; %ncv=numberingconvvec
elseif usinghourlynrccdata==1
    daycol=3;yrcol=4;colofncv=3;stnpr=stnprhn;stnpr2=stnpr2hn;
end
if relativescores==1;relabs='Relative';else relabs='Absolute';end


%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\%$--"\
%Start of script

%First, read in csv files and clean them up, by doing unit conversions,
%eliminating intra-hourly special readings, etc
%Strangely, some use 24-hr time and others 12-hr
%Patriotically, the resulting total number of hours in these heatwaves is 1776!
if rereaddata==1
    cd /Users/colin/Desktop/General_Academics/Research/Station_Data/MesoWest_Hourly_Obs
    kewr=csvread('KEWR-data.csv');kteb=csvread('KTEB-data.csv');
    knyc=csvread('KNYC-data.csv');klga=csvread('KLGA-data.csv');
    kjfk=csvread('KJFK-data.csv');kacy=csvread('KACY-data.csv');
    kphl=csvread('KPHL-data.csv');kttn=csvread('KTTN-data.csv');
    kbdr=csvread('KBDR-data.csv');khpn=csvread('KHPN-data.csv');
    kisp=csvread('KISP-data.csv');
end


%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+%&<,!$+
%Beginning of script

%First, a little housekeeping
hwstarts=sortrows(hwstarts,2); %chronological order
numhws=size(hwstarts,1);
if excludeaug2002==1;r=-1;else r=0;end  %r is for reduction

%Organize data fresh from the csv files into nice arrays
if redefinevectors==1
    hwlengths=zeros(numstns,numhws);hwintegindb=zeros(numstns,numhws);
    cleandata={};
    for i=1:numstns
        curstn=stnpr2mw{i};
        cleandata{i}=eval(char(curstn));sz=size(cleandata{i},1);
        for row=2:sz
            if cleandata{i}(row,5)~=acceptt(1) && cleandata{i}(row,5)~=acceptt(2) &&...
                    cleandata{i}(row,5)~=acceptt(3) && cleandata{i}(row,5)~=acceptt(4) &&...
                    cleandata{i}(row,5)~=acceptt(5) && cleandata{i}(row,5)~=acceptt(6) &&...
                    cleandata{i}(row,5)~=acceptt(7) && cleandata{i}(row,5)~=acceptt(8) %i.e. this is a special non-hourly obs
                cleandata{i}(row,:)=0;
            elseif cleandata{i}(row,4)==cleandata{i}(row-1,4) %i.e. there is already an obs for this hour
                cleandata{i}(row,:)=0;
            end
        end
        %Eliminate the resulting zero rows & then sort the whole thing chronologically
        cleandata{i}(all(~cleandata{i},2),:)=[];
        cleandata{i}=sortrows(cleandata{i},3);
        sz=size(cleandata{i},1);


        %The elseif in the above loop can automatically delete duplicates, but
        %can't deal with missing hours so easily; that's where the code below comes in
        %Code for finding hourly jumps (that then need to be manually remedied, typically, as each is idiosyncratic)
        %Once the data is read in, touch-ups can be done more easily by looking at the matrix hwlengths
        %An example plot to aid visually scanning for the exact location is plot(cleandata{10}(1:120,4))
        if checkformissingtimes==1
            disp(i);
            for k=2:690
                if cleandata{i}(k,4)~=cleandata{i}(k-1,4)+1 && ...
                        cleandata{i}(k,4)~=cleandata{i}(k-1,4)-11 && ...
                        cleandata{i}(k,4)~=cleandata{i}(k-1,4)-23
                    disp('Something is up');disp(cleandata{i}(k,1:4));
                end
            end
        end


        %Add in heat index as add'l column
        %Use method of Rothfusz 1990 described in http://www.wpc.ncep.noaa.gov/html/heatindex_equation.shtml
        cleandata{i}(:,30)=-42.379+2.049*cleandata{i}(:,6)+10.1433*cleandata{i}(:,7)-...
            0.22476*cleandata{i}(:,6).*cleandata{i}(:,7)-0.00684*cleandata{i}(:,6).*cleandata{i}(:,6)-...
            0.0548*cleandata{i}(:,7).*cleandata{i}(:,7)+0.00123*cleandata{i}(:,6).*cleandata{i}(:,6).*...
            cleandata{i}(:,7)+0.000853.*cleandata{i}(:,6).*cleandata{i}(:,7).*cleandata{i}(:,7)-...
            0.000002*cleandata{i}(:,6).*cleandata{i}(:,6).*cleandata{i}(:,7).*cleandata{i}(:,7);
        cleandata{i}(:,30)=(cleandata{i}(:,30)-32)*5/9;


        %See notes on heat-index summation below this loop
        hwc=1;hourc=1;hindsum=0;hindsumx=0;hindsumn=0; %heat-index sum (total, max/day only, min/night only)
        q=quantile(cleandata{i}(:,30),0.7); %approx overall 90th pctile
        for row=1:sz
            if row==1
                hourofday=1;
            else
                if cleandata{i}(row,2)~=cleandata{i}(row-1,2) %first hour of a day
                    hourofday=1;
                end
            end
            if cleandata{i}(row,30)>=q
                hindsum=hindsum+cleandata{i}(row,30);
                %For night & day scores, need to separate out the hours (9 PM-9 AM is considered night)
                if hourofday<=8 %nighttime
                    hindsumn=hindsumn+cleandata{i}(row,30);
                elseif hourofday<=20 %daytime
                    hindsumx=hindsumx+cleandata{i}(row,30);
                else %nighttime (evening)
                    hindsumn=hindsumn+cleandata{i}(row,30);
                end
            end
            if row~=sz
                if cleandata{i}(row,2)~=cleandata{i}(row+1,2) && cleandata{i}(row,2)~=cleandata{i}(row+1,2)-1 &&...
                        cleandata{i}(row,2)~=cleandata{i}(row+1,2)+30 && cleandata{i}(row,2)~=cleandata{i}(row+1,2)+29
                    %since cleandata only contains Central Park heatwaves, this is the last obs of a heatwave
                    hwlengths(i,hwc)=hourc;
                    hwintegindb(i,hwc)=hindsum;hwintegindx(i,hwc)=hindsumx;hwintegindn(i,hwc)=hindsumn;
                    hwc=hwc+1;hindsum=0;hindsumx=0;hindsumn=0;hourc=0;
                    %fprintf('Wet-score heatwave #%d end dates',hwc-1);disp(cleandata{i}(row,1:3));
                end
            else
                hwlengths(i,hwc)=hourc;
                hwintegindb(i,hwc)=hindsum;hwintegindx(i,hwc)=hindsumx;hwintegindn(i,hwc)=hindsumn;
                %fprintf('Wet-score heatwave #%d dates',hwc);disp(cleandata{i}(row,1:3));
            end
            hourc=hourc+1;hourofday=hourofday+1;
        end


        %Make metric conversions: T to C, wind speed to m/s, SLP/altimeter to
        %hPa, visibility to km, precip to mm, cloud heights to m
        cleandata{i}(:,6)=(cleandata{i}(:,6)-32)*5/9;
        cleandata{i}(:,8)=cleandata{i}(:,8)*0.44704;cleandata{i}(:,9)=cleandata{i}(:,9)*0.44704;
        cleandata{i}(:,11)=cleandata{i}(:,11)*33.864;cleandata{i}(:,12)=cleandata{i}(:,12)*33.864;
        cleandata{i}(:,14)=cleandata{i}(:,14)*1.6093;cleandata{i}(:,15)=cleandata{i}(:,15)*25.4;
        cleandata{i}(:,16)=cleandata{i}(:,16)*25.4;cleandata{i}(:,17)=cleandata{i}(:,17)*25.4;
        cleandata{i}(:,18)=cleandata{i}(:,18)*25.4;cleandata{i}(:,19)=cleandata{i}(:,19)/3.28;
        cleandata{i}(:,20)=cleandata{i}(:,20)/3.28;cleandata{i}(:,21)=cleandata{i}(:,21)/3.28;
        cleandata{i}(:,22)=cleandata{i}(:,22)/3.28;cleandata{i}(:,23)=(cleandata{i}(:,23)-32)*5/9;
        cleandata{i}(:,24)=(cleandata{i}(:,24)-32)*5/9;cleandata{i}(:,25)=cleandata{i}(:,25)*0.44704;
        cleandata{i}(:,26)=(cleandata{i}(:,26)-32)*5/9;cleandata{i}(:,27)=(cleandata{i}(:,27)-32)*5/9;
        cleandata{i}(:,29)=(cleandata{i}(:,29)-32)*5/9;

        %Vapor pressure (no longer needed)
        %cleandata{i}(:,31)=6.11*10.^((7.5*cleandata{i}(:,29))./(237.3+cleandata{i}(:,29)));

    end
end


%Compare heatwave-severity scores from hwsorted (using daily max & min alone)
%to those computed above (using the full heat index and hourly data)
%For hourly data, summing above the 90th percentile over the heatwave
%as was done for daily data perhaps is not the best strategy, as it
%tends to lessen the differences between heatwaves
%Since these hourly obs solely consist of heatwave days, I estimated above
%that the 70th hourly pctile here is roughly equal to the 90th overall 
%(for each stn separately of course)

%Numbering is different than in readnycdata, so account for that here
%Also, in hwintegind, hw's are in chronological order -- need to wrangle
%the others into that as well, for the dual purposes of sanity and organization
%first column  -- numbering for MesoWest data
%second column -- numbering for daily CLIMOD data
%third column  -- numbering for hourly NRCC data (the same relative ordering as CLIMOD,
%but half as many stations available)
%See preamble to readnycdata to dispel any confusion
numberingconvvec(1,:)=[1 5 5]; %Newark
numberingconvvec(2,:)=[2 14 10]; %Teterboro
numberingconvvec(3,:)=[3 7 7]; %Central Park
numberingconvvec(4,:)=[4 4 4]; %LGA
numberingconvvec(5,:)=[5 3 3]; %JFK
numberingconvvec(6,:)=[6 1 1]; %AtlCityA
numberingconvvec(7,:)=[7 13 9]; %PhiladelphiaA
numberingconvvec(8,:)=[8 9 8]; %TrentonA
numberingconvvec(9,:)=[9 2 2]; %BridgeportA
numberingconvvec(10,:)=[10 6 6]; %WhitePlainsA
numberingconvvec(11,:)=[11 18 11]; %IslipA

%NRCC-hourly hours corresponding to MW hw starts (for efficiency in below loop)
hwstarthours=[547657;566137;566257;574753;591073;608929;609265;610105;618361;626473;635809];

if recalcwetdryscores==1
    scorescompb=zeros(numstns,numhws+r,4); %b stands for 'both', i.e. day & night
    scorescompx=zeros(numstns,numhws+r,4);scorescompn=zeros(numstns,numhws+r,4);
    %Calculates heatwave-severity scores as sums over all the hours of the
    %heatwave, subtracting off the 90th percentile for that hour (in the
    %appropriate month, at the appropriate station)
    %Creates separate scores for temp, dewpt, heat index, and WBT
    %-----Add an option to sum values over an absolute threshold:
    %based on previous studies, these are typically 90 F for daytime temp ("hot days"), 
    %72 F for nighttime temp ("tropical nights"), 68 F for dewpt
    %I will also then use 100 F for heat index and 75 F for WBT
    %Daytime is, as defined elsewhere, 9 AM-8 PM, and nighttime 9 PM-8 AM
    %Slight difference/bias vis-à-vis the percents is probably made up for by the fact
    %that max temps are more impactful simply by virtue of being higher
    %One thing that aids in efficiency is that all stations have the same # of rows of data
    %Also, as currently written the first heatwave (due to MesoWest legacy) is not until 2003 (see hwstarts)
    for i=1:numstns
        absthreshdayt=32.2;absthreshnightt=22.2;
        absthreshdewpt=20;absthreshhi=37.7;absthreshwbt=23.8;
        c=1;tscore=zeros(numhws+r,3);dewptscore=zeros(numhws+r,3);hiscore=zeros(numhws+r,3);wbtscore=zeros(numhws+r,3);
        validthrs=zeros(numhws+r,1);validdewpthrs=zeros(numhws+r,1);validhihrs=zeros(numhws+r,1);validwbthrs=zeros(numhws+r,1);
        validthrsx=zeros(numhws+r,1);validdewpthrsx=zeros(numhws+r,1);validhihrsx=zeros(numhws+r,1);validwbthrsx=zeros(numhws+r,1);
        validthrsn=zeros(numhws+r,1);validdewpthrsn=zeros(numhws+r,1);validhihrsn=zeros(numhws+r,1);validwbthrsn=zeros(numhws+r,1);
        tscorex=zeros(numhws+r,3);tscoren=zeros(numhws+r,3); %for max/day only, & min/night only respectively
        dewptscorex=zeros(numhws+r,3);dewptscoren=zeros(numhws+r,3);
        hiscorex=zeros(numhws+r,3);hiscoren=zeros(numhws+r,3);
        wbtscorex=zeros(numhws+r,3);wbtscoren=zeros(numhws+r,3);
        validhrsperhw=24*hwstarts(2:numhws,3);
        jj1=547657;
        while jj1<size(hourlytvecs{i},1) %row counter for all data
            for jj1b=2:numhws %heatwave counter, skipping Aug 2002
                curDOY=DatetoDOY(hourlytvecs{i}(jj1,3),hourlytvecs{i}(jj1,2),hourlytvecs{i}(jj1,4));
                if curDOY==hwstarts(jj1b,1) && hourlytvecs{i}(jj1,1)==0 &&...
                        hourlytvecs{i}(jj1,4)==hwstarts(jj1b,2) %first hour of a Central Park heatwave
                    curmon=hourlytvecs{i}(jj1,3);curhour=hourlytvecs{i}(jj1,1);
                    tprctile90thishr=hourly90prctiles{i,1}(curmon,curhour+1);
                    dewptprctile90thishr=hourly90prctiles{i,2}(curmon,curhour+1);
                    hiprctile90thishr=hourly90prctiles{i,3}(curmon,curhour+1);
                    wbtprctile90thishr=hourly90prctiles{i,4}(curmon,curhour+1);
                    %disp(jj1);disp(i);
                    for k=1:hwstarts(jj1b,3)*24 %loop through the duration of the heatwave, hour by hour
                        curhour=hourlytvecs{i}(jj1+k-1,1);
                        %1. Temperature
                        if hourlytvecs{i}(jj1+k-1,5)>-50
                            if relativescores==1
                                tscore(c,1)=tscore(c,1)+hourlytvecs{i}(jj1+k-1,5)-tprctile90thishr;
                                validthrs(c)=validthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    tscorex(c,1)=tscorex(c,1)+hourlytvecs{i}(jj1+k-1,5)-tprctile90thishr;
                                    validthrsx(c)=validthrsx(c)+1;
                                else
                                    tscoren(c,1)=tscoren(c,1)+hourlytvecs{i}(jj1+k-1,5)-tprctile90thishr;
                                    validthrsn(c)=validthrsn(c)+1;
                                end
                            else
                                if curhour>=9 && curhour<=20 %daytime
                                    if hourlytvecs{i}(jj1+k-1,5)>absthreshdayt
                                        tscorex(c,1)=tscorex(c,1)+hourlytvecs{i}(jj1+k-1,5);
                                        validthrsx(c)=validthrsx(c)+1;
                                        tscore(c,1)=tscore(c,1)+hourlytvecs{i}(jj1+k-1,5);
                                        validthrs(c)=validthrs(c)+1;
                                    end
                                else
                                    if hourlytvecs{i}(jj1+k-1,5)>absthreshnightt
                                        tscoren(c,1)=tscoren(c,1)+hourlytvecs{i}(jj1+k-1,5);
                                        validthrsn(c)=validthrsn(c)+1;
                                        tscore(c,1)=tscore(c,1)+hourlytvecs{i}(jj1+k-1,5);
                                        validthrs(c)=validthrs(c)+1;
                                    end
                                end
                            end
                        end
                        %2. Dewpoint
                        if hourlytvecs{i}(jj1+k-1,6)>-50
                            if relativescores==1
                                dewptscore(c,1)=dewptscore(c,1)+hourlytvecs{i}(jj1+k-1,6)-dewptprctile90thishr;
                                validdewpthrs(c)=validdewpthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    dewptscorex(c,1)=dewptscorex(c,1)+hourlytvecs{i}(jj1+k-1,6)-dewptprctile90thishr;
                                    validdewpthrsx(c)=validdewpthrsx(c)+1;
                                else
                                    dewptscoren(c,1)=dewptscoren(c,1)+hourlytvecs{i}(jj1+k-1,6)-dewptprctile90thishr;
                                    validdewpthrsn(c)=validdewpthrsn(c)+1;
                                end
                            else
                                if curhour>=9 && curhour<=20 %daytime
                                    if hourlytvecs{i}(jj1+k-1,6)>absthreshdewpt
                                        dewptscorex(c,1)=dewptscorex(c,1)+hourlytvecs{i}(jj1+k-1,6);
                                        validdewpthrsx(c)=validdewpthrsx(c)+1;
                                        dewptscore(c,1)=dewptscore(c,1)+hourlytvecs{i}(jj1+k-1,6);
                                        validdewpthrs(c)=validdewpthrs(c)+1;
                                    end
                                else
                                    if hourlytvecs{i}(jj1+k-1,6)>absthreshdewpt
                                        dewptscoren(c,1)=dewptscoren(c,1)+hourlytvecs{i}(jj1+k-1,6);
                                        validdewpthrsn(c)=validdewpthrsn(c)+1;
                                        dewptscore(c,1)=dewptscore(c,1)+hourlytvecs{i}(jj1+k-1,6);
                                        validdewpthrs(c)=validdewpthrs(c)+1;
                                    end
                                end
                            end
                        end
                        %3. Heat index
                        if hourlytvecs{i}(jj1+k-1,13)>-50 && hourlytvecs{i}(jj1+k-1,13)<100
                            if relativescores==1
                                hiscore(c,1)=hiscore(c,1)+hourlytvecs{i}(jj1+k-1,13)-hiprctile90thishr;
                                validhihrs(c)=validhihrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    hiscorex(c,1)=hiscorex(c,1)+hourlytvecs{i}(jj1+k-1,13)-hiprctile90thishr;
                                    validhihrsx(c)=validhihrsx(c)+1;
                                else
                                    hiscoren(c,1)=hiscoren(c,1)+hourlytvecs{i}(jj1+k-1,13)-hiprctile90thishr;
                                    validhihrsn(c)=validhihrsn(c)+1;
                                end
                            else
                                if curhour>=9 && curhour<=20 %daytime
                                    if hourlytvecs{i}(jj1+k-1,13)>absthreshhi
                                        hiscorex(c,1)=hiscorex(c,1)+hourlytvecs{i}(jj1+k-1,13);
                                        validhihrsx(c)=validhihrsx(c)+1;
                                        hiscore(c,1)=hiscore(c,1)+hourlytvecs{i}(jj1+k-1,13);
                                        validhihrs(c)=validhihrs(c)+1;
                                    end
                                else
                                    if hourlytvecs{i}(jj1+k-1,13)>absthreshhi
                                        hiscoren(c,1)=hiscoren(c,1)+hourlytvecs{i}(jj1+k-1,13);
                                        validhihrsn(c)=validhihrsn(c)+1;
                                        hiscore(c,1)=hiscore(c,1)+hourlytvecs{i}(jj1+k-1,13);
                                        validhihrs(c)=validhihrs(c)+1;
                                    end
                                end
                            end
                        end
                        %4. Wet-bulb temperature
                        if hourlytvecs{i}(jj1+k-1,14)>-50
                            if relativescores==1
                                wbtscore(c,1)=wbtscore(c,1)+hourlytvecs{i}(jj1+k-1,14)-wbtprctile90thishr;
                                validwbthrs(c)=validwbthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    wbtscorex(c,1)=wbtscorex(c,1)+hourlytvecs{i}(jj1+k-1,14)-wbtprctile90thishr;
                                    validwbthrsx(c)=validwbthrsx(c)+1;
                                else
                                    wbtscoren(c,1)=wbtscoren(c,1)+hourlytvecs{i}(jj1+k-1,14)-wbtprctile90thishr;
                                    validwbthrsn(c)=validwbthrsn(c)+1;
                                end
                            else
                                if curhour>=9 && curhour<=20 %daytime
                                    if hourlytvecs{i}(jj1+k-1,14)>absthreshwbt
                                        wbtscorex(c,1)=wbtscorex(c,1)+hourlytvecs{i}(jj1+k-1,14);
                                        validwbthrsx(c)=validwbthrsx(c)+1;
                                        wbtscore(c,1)=wbtscore(c,1)+hourlytvecs{i}(jj1+k-1,14);
                                        validwbthrs(c)=validwbthrs(c)+1;
                                    end
                                else
                                    if hourlytvecs{i}(jj1+k-1,14)>absthreshwbt
                                        wbtscoren(c,1)=wbtscoren(c,1)+hourlytvecs{i}(jj1+k-1,14);
                                        validwbthrsn(c)=validwbthrsn(c)+1;
                                        wbtscore(c,1)=wbtscore(c,1)+hourlytvecs{i}(jj1+k-1,14);
                                        validwbthrs(c)=validwbthrs(c)+1;
                                    end
                                end
                            end
                        end

                    end
                    
                    tscore(c,1)=tscore(c,1)*validthrs(c)/validhrsperhw(c);
                    dewptscore(c,1)=dewptscore(c,1)*validdewpthrs(c)/validhrsperhw(c);
                    hiscore(c,1)=hiscore(c,1)*validhihrs(c)/validhrsperhw(c);
                    wbtscore(c,1)=wbtscore(c,1)*validwbthrs(c)/validhrsperhw(c);
                    tscore(c,2)=hwstarts(jj1b,1);dewptscore(c,2)=hwstarts(jj1b,1);
                    hiscore(c,2)=hwstarts(jj1b,1);wbtscore(c,2)=hwstarts(jj1b,1);
                    tscore(c,3)=hwstarts(jj1b,2);dewptscore(c,3)=hwstarts(jj1b,2);
                    hiscore(c,3)=hwstarts(jj1b,2);wbtscore(c,3)=hwstarts(jj1b,2);
                    tscorex(c,1)=tscorex(c,1)*validthrsx(c)/(validhrsperhw(c)/2);
                    dewptscorex(c,1)=dewptscorex(c,1)*validdewpthrsx(c)/(validhrsperhw(c)/2);
                    hiscorex(c,1)=hiscorex(c,1)*validhihrsx(c)/(validhrsperhw(c)/2);
                    wbtscorex(c,1)=wbtscorex(c,1)*validwbthrsx(c)/(validhrsperhw(c)/2);
                    tscorex(c,2)=hwstarts(jj1b,1);dewptscorex(c,2)=hwstarts(jj1b,1);
                    hiscorex(c,2)=hwstarts(jj1b,1);wbtscorex(c,2)=hwstarts(jj1b,1);
                    tscorex(c,3)=hwstarts(jj1b,2);dewptscorex(c,3)=hwstarts(jj1b,2);
                    hiscorex(c,3)=hwstarts(jj1b,2);wbtscorex(c,3)=hwstarts(jj1b,2);
                    tscoren(c,1)=tscoren(c,1)*validthrsn(c)/(validhrsperhw(c)/2);
                    dewptscoren(c,1)=dewptscoren(c,1)*validdewpthrsn(c)/(validhrsperhw(c)/2);
                    hiscoren(c,1)=hiscoren(c,1)*validhihrsn(c)/(validhrsperhw(c)/2);
                    wbtscoren(c,1)=wbtscoren(c,1)*validwbthrsn(c)/(validhrsperhw(c)/2);
                    tscoren(c,2)=hwstarts(jj1b,1);dewptscoren(c,2)=hwstarts(jj1b,1);
                    hiscoren(c,2)=hwstarts(jj1b,1);wbtscoren(c,2)=hwstarts(jj1b,1);
                    tscoren(c,3)=hwstarts(jj1b,2);dewptscoren(c,3)=hwstarts(jj1b,2);
                    hiscoren(c,3)=hwstarts(jj1b,2);wbtscoren(c,3)=hwstarts(jj1b,2);
                    c=c+1;if c<=size(hwstarthours,1);jj1=hwstarthours(c);else jj1=size(hourlytvecs{i},1);end
                end
            end
        end

        %Put into chronological order
        tscore=sortrows(tscore,3);dewptscore=sortrows(dewptscore,3);hiscore=sortrows(hiscore,3);wbtscore=sortrows(wbtscore,3);
        tscorex=sortrows(tscorex,3);dewptscorex=sortrows(dewptscorex,3);
        hiscorex=sortrows(hiscorex,3);wbtscorex=sortrows(wbtscorex,3);
        tscoren=sortrows(tscoren,3);dewptscoren=sortrows(dewptscoren,3);
        hiscoren=sortrows(hiscoren,3);wbtscoren=sortrows(wbtscoren,3);

        scorescompb(i,:,1)=tscore(:,1);scorescompb(i,:,2)=dewptscore(:,1);
        scorescompb(i,:,3)=hiscore(:,1);scorescompb(i,:,4)=wbtscore(:,1);
        scorescompx(i,:,1)=tscorex(:,1);scorescompx(i,:,2)=dewptscorex(:,1);
        scorescompx(i,:,3)=hiscorex(:,1);scorescompx(i,:,4)=wbtscorex(:,1);
        scorescompn(i,:,1)=tscoren(:,1);scorescompn(i,:,2)=dewptscoren(:,1);
        scorescompn(i,:,3)=hiscoren(:,1);scorescompn(i,:,4)=wbtscoren(:,1);
    end
    %Heatwave scores consolidated into average for each station
    for i=1:numstns
        scorescomp2b(i,1)=sum(scorescompb(i,:,1))/(numhws+r);
        scorescomp2x(i,1)=sum(scorescompx(i,:,1))/(numhws+r);scorescomp2n(i,1)=sum(scorescompn(i,:,1))/(numhws+r);
        scorescomp2b(i,2)=sum(scorescompb(i,:,2))/(numhws+r);
        scorescomp2x(i,2)=sum(scorescompx(i,:,2))/(numhws+r);scorescomp2n(i,2)=sum(scorescompn(i,:,2))/(numhws+r);
        scorescomp2b(i,3)=sum(scorescompb(i,:,3))/(numhws+r);
        scorescomp2x(i,3)=sum(scorescompx(i,:,3))/(numhws+r);scorescomp2n(i,3)=sum(scorescompn(i,:,3))/(numhws+r);
        scorescomp2b(i,4)=sum(scorescompb(i,:,4))/(numhws+r);
        scorescomp2x(i,4)=sum(scorescompx(i,:,4))/(numhws+r);scorescomp2n(i,4)=sum(scorescompn(i,:,4))/(numhws+r);
    end
end

%Create scatterplot of one kind of score vs another for all stns over these recent heatwaves
%Recall that rows of scorescompZ are stations and columns are heatwaves
if makescatterplot==1
    if daytimeonly==1;suffix=['x'];phr=', Daytime Only';elseif nighttimeonly==1;suffix=['n'];phr=', Nighttime Only';else suffix=['b'];phr='';end
    sc=eval(['scorescomp' suffix]);sc2=eval(['scorescomp2' suffix]);
    colorlist={colors('red');colors('light red');colors('orange');colors('green');colors('teal');...
        colors('light blue');colors('blue');colors('light purple');colors('pink');colors('brown');colors('grey')}; %one for each stn
    grouplist=[2,2,2,2,1,1,2,2,1,2,1];
    colorlistg={colors('red');colors('green')};
    markerlist={'s';'d';'h';'v';'o';'+';'*';'x';'>';'p';'^'}; %one for each heatwave
    figure(figc);figc=figc+1;
    noonesyet=1;notwosyet=1;h=0;hc=1;
    for i=1:numstns
        if consolidatestns==0
            for j=1:numhws+r
                %disp(colorlist{i});
                if groupbyregion==1
                    if symbolsbyhw==1
                        scatter(sc(i,j,score1),sc(i,j,score2),markerlist{j},'MarkerFaceColor',colorlistg{grouplist(i)},...
                                'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                        if grouplist(i)==1 && noonesyet==1 %only do once for each group
                            h(hc)=scatter(sc(i,j,score1),sc(i,j,score2),markerlist{j},'MarkerFaceColor',colorlistg{grouplist(i)},...
                                'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                            hc=hc+1;noonesyet=0;
                        elseif grouplist(i)==2 && notwosyet==1
                            h(hc)=scatter(sc(i,j,score1),sc(i,j,score2),markerlist{j},'MarkerFaceColor',colorlistg{grouplist(i)},...
                                'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                            hc=hc+1;notwosyet=0;
                        end
                    else
                        scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlistg{grouplist(i)},...
                                'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                        if grouplist(i)==1 && noonesyet==1 %only do once for each group
                            h(hc)=scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlistg{grouplist(i)},...
                                'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                            hc=hc+1;noonesyet=0;
                        elseif grouplist(i)==2 && notwosyet==1
                            h(hc)=scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlistg{grouplist(i)},...
                                'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                            hc=hc+1;notwosyet=0;
                        end
                    end
                else
                    if symbolsbyhw==1
                        scatter(sc(i,j,score1),sc(i,j,score2),markerlist{j},'MarkerFaceColor',colorlist{i},...
                                'MarkerEdgeColor',colorlist{i},'LineWidth',3);
                        if j==1 %only do once for each stn, to give plot handles the info they need
                            h(i)=scatter(sc(i,j,score1),sc(i,j,score2),markerlist{j},'MarkerFaceColor',colorlist{i},...
                                'MarkerEdgeColor',colorlist{i},'LineWidth',3);
                        end
                    else
                        scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlist{i},...
                                'MarkerEdgeColor',colorlist{i},'LineWidth',3);
                        if j==1 %only do once for each stn, to give plot handles the info they need
                            h(i)=scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlist{i},...
                                'MarkerEdgeColor',colorlist{i},'LineWidth',3);
                        end
                    end
                end
                hold on;
            end
        else
            scatter(sc2(i,score1),sc2(i,score2),'MarkerFaceColor',colorlist{i},...
                            'MarkerEdgeColor',colorlist{i},'LineWidth',3);hold on;
            h(i)=scatter(sc2(i,score1),sc2(i,score2),'MarkerFaceColor',colorlist{i},...
                            'MarkerEdgeColor',colorlist{i},'LineWidth',3);        
        end
    end
    if groupbyregion==1
        groups={'Inland';'Coastal'};
        legend(h,groups,'Location','Southeast');
    else
        legend(h,stnpr,'Location','Southeast');
    end
    if symbolsbyhw==1
        for j=1:numhws+r
            tempx=xlim;tempy=ylim;scatter(0.85*tempx(2),(0.95-(0.025*j))*tempy(2),markerlist{j},...
                            'MarkerFaceColor',colors('light brown'),'MarkerEdgeColor',colors('light brown'),'LineWidth',3);
            phr2=sprintf('%s-%s, %d',DOYtoDate(hwstarts(j+1,1),hwstarts(j+1,2)),...
                DOYtoDate(hwstarts(j+1,1)+hwstarts(j+1,3)-1,hwstarts(j+1,2)),hwstarts(j+1,2));
            text(0.87*tempx(2),(0.95-(0.025*j))*tempy(2),phr2);
        end
    end
    xlabel(sprintf('Heatwave Severity Score based on %s',fourvariabs{score1}),'FontSize',14);
    ylabel(sprintf('Heatwave Severity Score based on %s',fourvariabs{score2}),'FontSize',14);
    title(sprintf('Comparative %s Severity Scores of %d Central Park Heatwaves (2003-2013)%s',relabs,numhws+r,phr),...
        'FontSize',16,'FontWeight','bold');
end


%Average temperatures on regional hot days (the ones analyzed in
%readnarrdata) that occurred after 2002 (as this is of course using MesoWest station data)
%Daily-average temps are calculated from hourly obs
if findstnhotevents==1
    hoteventsstns={};
    for i=1:numstns
        eventc=0;hour=1;
        while hour<=size(cleandata{i},1)
            match=0;
            for hotday=1:size(dmrsstarts,1) %the regional hot days between 1979 and 2014, as constrained by NARR
                if hotday>=2 && eventc>=2
                    %Two days in the same event coming up
                    if dmrsstarts(hotday,2)==dmrsstarts(hotday-1,2) && abs(dmrsstarts(hotday,1)-dmrsstarts(hotday-1,1))<=7 
                        %dailyavg=0;
                        %Only do something if there's a match!
                        if cleandata{i}(hour,1)==DOYtoMonth(dmrsstarts(hotday,1),dmrsstarts(hotday,2)) &&...
                                cleandata{i}(hour,2)==DOYtoDOM(dmrsstarts(hotday,1),dmrsstarts(hotday,2)) &&...
                                cleandata{i}(hour,3)==dmrsstarts(hotday,2) %month, day, and year all match
                            dailyavg=sum(cleandata{i}(hour:hour+47,6));
                            hourincr=48;match=1;
                            if eventc>=1;prevdailyavg=dailyavg;end
                            dailyavg=dailyavg/48;
                            hoteventsstns{i,eventc-1}=dailyavg;
                        end
                    %Looking for a singleton day
                    else
                        dailyavg=0;
                        %If there's a match...
                        if cleandata{i}(hour,1)==DOYtoMonth(dmrsstarts(hotday,1),dmrsstarts(hotday,2)) &&...
                                cleandata{i}(hour,2)==DOYtoDOM(dmrsstarts(hotday,1),dmrsstarts(hotday,2)) &&...
                                cleandata{i}(hour,3)==dmrsstarts(hotday,2) %month, day, and year all match
                            dailyavg=sum(cleandata{i}(hour:hour+23,6));
                            hourincr=24;match=1;
                            if eventc>=1;prevdailyavg=dailyavg;end
                            dailyavg=dailyavg/24;
                            eventc=eventc+1;
                            hoteventsstns{i,eventc}=dailyavg;
                        end
                    end
                else
                    dailyavg=0;
                    if cleandata{i}(hour,1)==DOYtoMonth(dmrsstarts(hotday,1),dmrsstarts(hotday,2)) &&...
                            cleandata{i}(hour,2)==DOYtoDOM(dmrsstarts(hotday,1),dmrsstarts(hotday,2)) &&...
                            cleandata{i}(hour,3)==dmrsstarts(hotday,2) %month, day, and year all match
                        dailyavg=sum(cleandata{i}(hour:hour+23,6));
                        hourincr=24;match=1;
                        if eventc>=1;prevdailyavg=dailyavg;end
                        dailyavg=dailyavg/24;
                        eventc=eventc+1;
                        hoteventsstns{i,eventc}=dailyavg;
                    end
                end
            end
            if match==0;hourincr=1;end
            hour=hour+hourincr;
        end
    end
end


%Compare (max+min)/2 and hourly-avg methods of calculating daily avgs of variables
%This is only done during heatwaves because that's all the data I have, but that's also
%all the data I'm interested in
if comparehourlymaxmin==1
    for i=1:3
        if i~=8 && i~=9 %Trenton & Bridgeport have a couple chunks of missing hourly data that makes them unsuitable
            dailysum=0;
            numdays=size(cleandata{i},1)/24;
            dailyavgcomp=zeros(numdays,2);
            for hour=1:24:size(cleandata{i},1)
                dailydata=cleandata{i}(hour:hour+23,6);
                dailyavgh=sum(cleandata{i}(hour:hour+23,6))/24; %avg of hourly temperature readings
                dailymax=max(dailydata);dailymin=min(dailydata);
                %if dailymin<-17 %not valid, probably a zero
                dailyavgmm=(dailymax+dailymin)/2;
                dailyavgcomp(ceil(hour/24),1)=dailyavgh;
                dailyavgcomp(ceil(hour/24),2)=dailyavgmm;
            end
        end
        diff=dailyavgcomp(:,2)-dailyavgcomp(:,1);
        mindiff=round(min(diff(:,1)));maxdiff=round(max(diff(:,1)));spacing=(maxdiff-mindiff)/10;
        centers=mindiff:spacing:maxdiff;
        figure(figc);clf;figc=figc+1;
        [a,b]=hist(diff,centers);hist(diff,centers);
        title(sprintf('[(Max+Min)/2] Minus [Hourly-Avg] Daily Avg, for Method Comparison, in %s',prlabels{i}),...
            'FontSize',16,'FontWeight','bold');
        phr=sprintf('Data for heatwaves only');
        uicontrol('Style','text','String',phr,'Units','normalized','Position',[0.4 0.85 0.2 0.05],'BackgroundColor','w');
        ylim([0 1.2*max(a)]);
    end
end
    


