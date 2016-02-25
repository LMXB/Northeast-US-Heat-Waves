%Analyze station data for the NYC region

%Instead of running this, consider...
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/workspace_analyzenycdata');

%readnycdata must have already been run or loaded
%     This script analyzes whichever data source was supplied there via the readxxxdata runtime option
%     Readnycdata determines how many stations are available, periods of record, &c
%     because the options there produce two mutually distinct versions of dailymaxvecs & its associates

%Current total runtime: about 8 min



%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~
%Runtime options
createnewvectors=0;         %whether to redefine some of the key vectors created in this script
displaystnsperyear=0;       %whether to display the chart of the # of available stations over time
computebasicstats=0;        %whether to organize data and compute main stats (6 min)
showdefnplot=0;             %whether to show plot illustrating main heat-wave definition
calculatehourlyprctiles=0;  %whether to calculate the 90th percentile of each hour of the day by month & station (1 min)
makeheatwaverankingold=0;   %whether to compute the heat-wave ranking using the old definition
    %*To define*: >=3 consecutive days where daily Tmax OR Tmin exceeds that station's monthly 90th percentile
    %*To rank*: the heatwave-integrated daily max and min over the 90th-pct threshold
makeheatwaverankingnew=1;   %whether to compute the heat-wave ranking using the new def'n of integrated hourly T/WBT (30 sec)
    monthiwf=6;monthiwl=8;
    stnf=3;stnl=7; %station range to compute things for
    %*To define*: >=3 consecutive days where integrated hourly T/WBT >=97.5th
    %percentile for that station & month, continuing day by day (as long as
    %every day's value is >=81st percentile), until the integrated value falls below the 97.5th-pct threshold
    %*To rank*: no ranking, just place in chronological order
    %*To homogenize*: a regional heat-wave day is one on which all of EWR, JFK, and LGA are experiencing a heat wave 
    %(as CP's record begins in 1995)
calchwseverityscores=0;     %whether to calculate hw-severity scores, with options for T vs WBT, night vs day, etc (10 sec)
    relativescores=0;       %whether to compute scores with absolute thresholds or relative to each stn's climate
    absthreshdayt=32.2;absthreshnightt=22.2;absthreshwbt=23.8; %thresholds for absolute scores, in deg C
makehwseverityscatterplot=0;%whether to make scatterplot of above scores (20 sec)
    score1=1;score2=2;      %compare T and WBT (a relic option); see readmesowestobs for old version
    perday=1;               %whether to show scores calculated per day, or summed over the whole hw regardless of length
    groupbyregion=0;        %whether to split into coastal and inland groups (vs each station individually)
    consolidatestns=0;      %whether to plot the average position of each stn (vs one pt per heatwave)
    colorsbyhwsymbolsbygroup=0;%whether to plot a different color for each hw & symbol for each group (vs all circles)
    colorsbyhwsymbolsbystn=0;  %same as above but for all stations
    colorsbyhw=1;           %whether to plot colors differentiating heat waves (no station identification)
    daytimeonly=0;          %whether to plot scores derived only from max/daytime values (vs all hours)
    nighttimeonly=1;        %same as above, but for min/nighttime values
findhottestdayseachstn=0;   %whether to compute and display hottest stn days (5 sec)
                                %(i.e. those where >=1 stn has a top-10 max temp)
clusterhotdays=0;           %whether to do k-means and hierarchical clustering of the aforementioned hot days
findhottestregdays=0;       %whether to compute hottest reg days > 99.5th pctile (as the EWR-JFK-LGA average)
makedaterankchart=0;        %whether to compute & display chart comparing ranking by Tmax vs by WBTmax
    coloredboxes=0;             %original formulation that's actually a chart, with colors
    linessevscore=0;            %line graphs of severity scores for each hw, showing regional average in bold and individual plots
    linesprctile=1;             %line graphs of percentiles, otherwise same
clusterheatwaves=0;         %whether to k-means cluster T-defined regional heat waves using their hourly traces of T and WBT (10 sec)
    kmin=7;kmax=7;          %minimum and maximum k to search over, to find the best
narrdataforclusters=0;      %whether to display NARR composites for each of those clusters (12 min total)
    desvar=[3;4;5];             %NARR variable(s) to show in those composites -- 1 for T, 2 for WBT, 3 for hgt, 4 & 5 for wind
    preslevel=3;                %for hgt, pressure level to show -- 1-1000, 2-850, 3-500, 4-300, 5-200
    anomfromjjaavg=1;           %whether to do show anomalies or absolute fields
makehottestregdaychart=0;   %whether to display chart of the hottest reg days
displayclimohists=0;        %whether to display basic histograms of station climatologies
    histfixed=0;                %whether to display hists sorted by month; when problems are fixed, change to 1
displaystnboxplots=0;       %whether to display comparative boxplots of JJA temp across stations
displaystnpctiles=0;        %whether to display 5th, 50th, and 95th percentiles of daily max temp for each stn & month

usingdailyclimoddata=0;     %these two important options are set in readnycdata & are included here for transparency
                                %but can't really be changed now
usinghourlynrccdata=1;     
%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~%*&?/,~



%These 22 stations are the set for the CLIMOD daily observations
pr1={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';...
    'CentralPark';'Brooklyn'}; %throughout this script, A stands for Airport
pr2={'TrentonA';'TrentonCity';'AtlCity';'TomsRiver';'PhiladelphiaA'}; %#9-13
pr3={'TeterboroA';'LittleFalls';'Paterson';'JerseyCity'}; %#14-17
pr4={'IslipA';'Scarsdale';'DobbsFerry';'PortJervis';'Mineola'}; %18-22
prd=[pr1;pr2;pr3;pr4]; %station sets to use in this run
a=size(prd);numstnsd=a(1);
prdlabels={'Atlantic City A';'Bridgeport A';'JFK A';'LaGuardia A';'Newark A';'White Plains A';...
    'Central Park';'Brooklyn';'Trenton A';'Trenton';'Atlantic City';'Toms River';'Philadelphia A';...
    'Teterboro A';'Little Falls';'Paterson';'Jersey City';'Islip A';'Scarsdale';'Dobbs Ferry';...
    'Port Jervis';'Mineola'};
marqueecitiesd=['Atl City A';'Bridgeport';'     JFK A';'     LGA A';'  Newark A';...
    '  White Pl';' Central P';'  Brooklyn'];
allcitiesd=['    Atl City A';'    Bridgeport';'         JFK A';'   LaGuardia A';'      Newark A';...
    '    White Pl A';'  Central Park';'      Brooklyn';'     Trenton A';'  Trenton City';' Atlantic City';...
    '    Toms River';'Philadelphia A';'   Teterboro A';'  Little Falls';'      Paterson';'   Jersey City';...
    '       Islip A';'     Scarsdale';'   Dobbs Ferry';'   Port Jervis';'       Mineola'];
%This last comprises cities that don't have too much missing daily data, for correlational purposes
citiesd=['   AtlCityA';'BridgeportA';'        JFK';'        LGA';'    NewarkA';...
        '   WhitePlA';'  Central P';'   Brooklyn';...
        '    AtlCity';'    PhillyA';'     IslipA';' DobbsFerry';' PortJervis';'    Mineola']; 
    
%The following 11 stations are the subset of those above for which hourly obs are available
prh={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';'CentralPark';...
    'TrentonA';'PhiladelphiaA';'TeterboroA';'IslipA'};
ah=size(prh);numstnsh=ah(1);
prhcodes={'acy';'bdr';'jfk';'lga';'ewr';'hpn';'nyc';'ttn';'phl';'teb';'isp'};
nsp={'ACY';'BDR';'JFK';'LGA';'EWR';'HPN';'NYC';'TTN';'PHL';'TEB';'ISP'}; %nice short prefixes
prhlabels={'Atlantic City A';'Bridgeport A';'JFK A';'LaGuardia A';'Newark A';...
    'White Plains A';'Central Park';'Trenton A';'Philadelphia A';'Teterboro A';'Islip A'};
allcitiesh=['    Atl City A';'    Bridgeport';'         JFK A';'   LaGuardia A';'      Newark A';...
    '    White Pl A';'  Central Park';'     Trenton A';'Philadelphia A';'   Teterboro A';'       Islip A'];
citiesh=['   AtlCityA';'BridgeportA';'        JFK';'        LGA';'    NewarkA';...
        '   WhitePlA';'  Central P';'  Trenton A';'    PhillyA';'Teterboro A';'     IslipA'];
symbolsh={'KACY';'KBDR';'KJFK';'KLGA';'KEWR';'KHPN';'KNYC';'KTTN';'KPHL';'KTEB';'KISP'};


%First and last full month & year of record for daily temp at each of the 22 stations (missing values w/in are OK)
stndailyPORs=[7 1958 7 2015;7 1948 7 2015;8 1948 7 2015;7 1940 7 2015;...
    1 1893 7 2015;4 1952 7 2015;1 1876 7 2015;...
    11 1953 4 2007;4 1998 7 2015;4 1913 11 1981;1 1874 7 2015;11 1959 4 2011;...
    7 1940 7 2015;1 1997 7 2015;9 1914 2 2004;...
    1 1893 1 1974;12 1905 6 1996;1 1984 7 2015;1 1904 6 1991;10 1945 6 2012;1 1893 7 2015;1 1938 12 2011];


stnlocs1=zeros(8,3); %lat, lon, and elev for each station in group 1 (marquee)
stnlocs1(:,1)=[39.449;41.158;40.639;40.779;40.683;41.067;40.779;40.594];
stnlocs1(:,2)=[-74.567;-73.129;-73.762;-73.880;-74.169;-73.708;-73.969;-73.981];
stnlocs1(:,3)=[60;5;11;11;7;379;130;20];stnlocs1(:,3)=stnlocs1(:,3)/mf;
stnlocs2=zeros(5,3); %lat, lon, and elev for each station in group 2 (s. & cent. NJ)
stnlocs2(:,1)=[40.277;40.227;39.379;39.95;39.868];
stnlocs2(:,2)=[-74.816;-74.746;-74.424;-74.217;-75.231];
stnlocs2(:,3)=[184;190;10;10;10];stnlocs2(:,3)=stnlocs2(:,3)/mf;
stnlocs3=zeros(4,3); %lat, lon, and elev for each station in group 3 (n. NJ)
stnlocs3(:,1)=[40.85;40.886;40.9;40.742];
stnlocs3(:,2)=[-74.061;-74.226;-74.15;-74.057];
stnlocs3(:,3)=[9;150;102;135];stnlocs3(:,3)=stnlocs3(:,3)/mf;
stnlocs4=zeros(5,3); %lat, lon, and elev for each station in group 4 (suburban NY & CT)
stnlocs4(:,1)=[40.794;40.983;41.007;41.38;40.733];
stnlocs4(:,2)=[-73.102;-73.8;-73.834;-74.685;-73.618];
stnlocs4(:,3)=[84;199;200;470;96];stnlocs4(:,3)=stnlocs4(:,3)/mf;
stnlocs=[stnlocs1;stnlocs2;stnlocs3;stnlocs4];
stnlocsh(:,1)=[39.449;41.158;40.639;40.779;40.683;41.067;40.779;40.277;39.868;40.85;40.794];
stnlocsh(:,2)=[-74.567;-73.129;-73.762;-73.880;-74.169;-73.708;-73.969;-74.816;-75.231;-74.061;-73.102];
stnlocsh(:,3)=[60;5;11;11;7;379;130;184;10;9;84];stnlocsh(:,3)=stnlocsh(:,3)/mf;

colorlistshort={colors('red');colors('light red');colors('light orange');...
    colors('light green');colors('green');colors('blue');colors('light purple');colors('pink')};
fourvariabs={'Temperature';'WBT';'Dewpoint';'Heat Index'};

exist figc;if ans==1;figc=figc+1;else figc=1;end
%Leap-year month starts
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
mpr={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'};
sa=1; %selected airport to compute histograms of differences; number from prefixes list
firstandlast=0; %whether all stns are currently included
maxhwlength=10; %no heat wave can go longer (checked that there aren't any longer)
if relativescores==1;relabs='Relative';else relabs='Absolute';end
if anomfromjjaavg==1;anomorabs='Anomalous';else anomorabs='Avg';end
temp=load('-mat','soilm_narr_01_01');
soilm_narr_01_01=temp(1).soilm_0000_01_01;
lats=soilm_narr_01_01{1};lons=soilm_narr_01_01{2}; %ditto


if usingdailyclimoddata==1
    daycol=2;yrcol=3;numstns=numstnsd;numyears=numyearsd;syear=1865;
    pr=prd;prlabels=prdlabels;marqueecities=marqueecitiesd;allcities=allcitiesd;
    cities=citiesd;
elseif usinghourlynrccdata==1
    daycol=3;yrcol=4;numstns=numstnsh;numyears=numyearsh;syear=1941;
    pr=prh;prcodes=prhcodes;prlabels=prhlabels;marqueecities=marqueecities;allcities=allcitiesh;cities=citiesh;
end

%Internal and external functions, as well as mathematical constants
subindex=@(A,r,c) A(r,c);
vararginnew={'contour';1;'mystep';2;'plotCountries';1;'colormap';'jet'}; %basic starter arguments for plotModelData



%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-
%Start of script

if createnewvectors==1
     monthlymeanmaxes=cell(numstns,1);
     monthlymeanmins=cell(numstns,1);
     monthlymeanavgs=cell(numstns,1);
     monthlyprctilemaxes=cell(numstns,1);
     monthlyprctilemins=cell(numstns,1);
     monthlyprctileavgs=cell(numstns,1);
     
     cleanmonthlymaxes=cell(numstns,12);
     cleanmonthlymins=cell(numstns,12);
     cleanmonthlyavgs=cell(numstns,12);
     cmmaxwy=cell(numstns,numyearsd,12);
     cmminwy=cell(numstns,numyearsd,12);
     cmmaxwy1D=zeros(numyearsd*12,numstns,3); %3 cols, for temp, day of year, year
     cmminwy1D=zeros(numyearsd*12,numstns,3);
end


%First thing is just to graph how many stations there are available for
%each full year (defining 'full' as having at most 5% missing)
%Uses max temps but min is presumably quite similar
if displaystnsperyear==1
    stnsperyear=zeros(numyears,1);
    for yr=1:numyears
        validstns=0;
        for stnc=1:numstns
            nummissing=0;day=1;
            while nummissing<=25 && day<=366 %this allows for shortcuts to save computation time
                curdayval=dailymaxvecs{stnc}(day,yr);
                if curdayval<-50 %missing
                    nummissing=nummissing+1;
                end
                day=day+1;
            end
            if nummissing<=18;validstns=validstns+1;end
        end
        %disp(nummissing);disp(validstns);
        stnsperyear(yr)=validstns;
    end
    figure(figc);clf;figc=figc+1;years=syear:2015;
    plot(years,stnsperyear);xlim([syear 2015]);hold on;
    threshvals=0.5*numstns*ones(numyears,1);plot(years,threshvals,'r');
    title('Number of stations per year that are at least 95% complete','FontSize',16,'FontWeight','bold');
end
                

if computebasicstats==1
    for stnc=1:stnl
        fprintf('Current station is %d\n',stnc);
        prefix=pr(stnc);  
        tempmax=sortrows(dailymaxvecs1D{stnc},-1);totalnumdays=size(tempmax,1);
        format shortG;
        %hottest 5% and 0.5% of daily-T maxima
        eval(['hottest5percmax' char(prefix) '=tempmax(1:round(5*totalnumdays/100),:);']);
        eval(['hottest0point5percmax' char(prefix) '=tempmax(1:round(0.5*totalnumdays/100),:);']);
        eval(['length5perc' char(prefix) '=round(5*totalnumdays/100);']);
        eval(['length0point5perc' char(prefix) '=round(0.5*totalnumdays/100);']);
        %...of minima (CLIMOD daily only)
        tempmin=sortrows(dailyminvecs1D{stnc},-1);
        eval(['hottest5percmin' char(prefix) '=tempmin(1:round(5*totalnumdays/100),:);']);
        eval(['hottest0point5percmin' char(prefix) '=tempmin(1:round(0.5*totalnumdays/100),:);']);

        %All daily data for each month of the year with missing values excluded
        for ct=1:12
            if ct==12          
                sd=eval(sprintf('m%us',ct));
                ed=366;
            else
                sd=eval(sprintf('m%us',ct));
                ed=eval(sprintf('m%us',ct+1))-1;
            end
            cleanmonthlymaxes{stnc,ct}=...
                dailymaxvecs{stnc}(sd:ed,1:size(dailymaxvecs{stnc},2));
            cleanmonthlymaxes{stnc,ct}=...
                cleanmonthlymaxes{stnc,ct}(cleanmonthlymaxes{stnc,ct}>-50);
            cleanmonthlymins{stnc,ct}=...
                dailyminvecs{stnc}(sd:ed,1:size(dailyminvecs{stnc},2));
            cleanmonthlymins{stnc,ct}=...
                cleanmonthlymins{stnc,ct}(cleanmonthlymins{stnc,ct}>-50);
            if usinghourlynrccdata~=1
                cleanmonthlyavgs{stnc,ct}=...
                    dailyavgvecs{stnc}(sd:ed,1:size(dailyavgvecs{stnc},2));
                cleanmonthlyavgs{stnc,ct}=...
                    cleanmonthlyavgs{stnc,ct}(cleanmonthlyavgs{stnc,ct}>-40);
            end
        end
        %Enhanced version of cleanmonthlyxxx with absolute year identified
        yc=1;totdayc=1;
        for yc=1:numyears
            %yc=4,8,etc. are leap years
            for ct=1:12
                if rem(yc,4)==0
                    if ct==12          
                        sd=eval(sprintf('m%usl',ct));
                        ed=366;
                    else
                        sd=eval(sprintf('m%usl',ct));
                        ed=eval(sprintf('m%usl',ct+1))-1;
                    end
                elseif rem(yc,4)~=0
                    if ct==12          
                        sd=eval(sprintf('m%us',ct));
                        ed=365;
                    else
                        sd=eval(sprintf('m%us',ct));
                        ed=eval(sprintf('m%us',ct+1))-1;
                    end
                end
                cmmaxwy{stnc,yc,ct}=dailymaxvecs{stnc}(sd:ed,yc);
                cmminwy{stnc,yc,ct}=dailyminvecs{stnc}(sd:ed,yc);
                cmmaxwy1D(totdayc:totdayc+ed-sd,stnc,1)=dailymaxvecs{stnc}(sd:ed,yc);
                cmminwy1D(totdayc:totdayc+ed-sd,stnc,1)=dailyminvecs{stnc}(sd:ed,yc);
                cmmaxwy1D(totdayc:totdayc+ed-sd,stnc,2)=ct*ones(ed-sd+1,1);
                cmminwy1D(totdayc:totdayc+ed-sd,stnc,2)=ct*ones(ed-sd+1,1);
                cmmaxwy1D(totdayc:totdayc+ed-sd,stnc,3)=(yc+syear-1)*ones(ed-sd+1,1);
                cmminwy1D(totdayc:totdayc+ed-sd,stnc,3)=(yc+syear-1)*ones(ed-sd+1,1);
                totdayc=totdayc+ed-sd+1;
            end
        end

        %Mean monthly maxima, minima, and avg for each station
        for month=1:12
            monthlymeanmaxes{stnc}(month)=...
                mean(mean(cleanmonthlymaxes{stnc,month}));
            monthlymeanmins{stnc}(month)=...
                mean(mean(cleanmonthlymins{stnc,month}));
            monthlymeanavgs{stnc}(month)=...
                mean(mean(cleanmonthlyavgs{stnc,month}));
        end

        %Quick computation of station-specific daily-T percentiles
        prctilestocompute=[5;10;25;50;75;90;95];
        for ii=1:length(prctilestocompute)
            for month=1:12
                monthlyprctilemaxes{stnc}(month,ii)=...
                    prctile(cleanmonthlymaxes{stnc,month},prctilestocompute(ii));
                monthlyprctilemins{stnc}(month,ii)=...
                    prctile(cleanmonthlymins{stnc,month},prctilestocompute(ii));
                monthlyprctileavgs{stnc}(month,ii)=...
                    prctile(cleanmonthlyavgs{stnc,month},prctilestocompute(ii));
            end
        end
        
        %Not-quite-as-quick computation of station-specific hourly integrated T
        %and WBT percentiles for JJA
        %Due to heat-wave definition being used (see DefinitionsNotes), p81
        %and p97.5 are the ones of the most interest
        %If a heat wave crosses month lines, thresholds for continuation
        %change as appropriate, weighting by the # of days in each month
        %Dimensions of integxxxprctiles are station|month|hw length|prctile
        for month=monthiwf:monthiwl
            for potentialhwlength=1:maxhwlength
                validTc=0;validWBTc=0;integTvec=0;integWBTvec=0;
                for i=1:size(hourlytvecs{stnc},1)
                    if hourlytvecs{stnc}(i,3)==month
                        if i+24*potentialhwlength-1<=size(hourlytvecs{stnc},1) %so we know it's not right at the end
                            if hourlytvecs{stnc}(i+24*potentialhwlength-1,3)==month %segregate by month
                                integTvalue=0;integWBTvalue=0;                 %go ahead & calculate hourly average
                                if min(hourlytvecs{stnc}(i:i+24*potentialhwlength-1,5))>-50 %no missing values allowed
                                    integTvalue=sum(hourlytvecs{stnc}(i:i+24*potentialhwlength-1,5));
                                    validTc=validTc+1;if integTvalue==0;disp(i);end
                                    integTvec(validTc)=integTvalue;
                                end
                                if min(hourlytvecs{stnc}(i:i+24*potentialhwlength-1,14))>-50
                                    integWBTvalue=sum(hourlytvecs{stnc}(i:i+24*potentialhwlength-1,14));
                                    validWBTc=validWBTc+1;
                                    integWBTvec(validWBTc)=integWBTvalue;
                                end
                            end
                        end
                    end
                end
                integTvecsaveforlater{stnc,month,potentialhwlength}=integTvec;
                integWBTvecsaveforlater{stnc,month,potentialhwlength}=integWBTvec;
                %disp(validTc);disp(validWBTc);
                %Percentiles for each station
                integTprctiles(stnc,month,potentialhwlength,1)=quantile(integTvec,0.975)/(potentialhwlength*24);
                integTprctiles(stnc,month,potentialhwlength,2)=quantile(integTvec,0.81)/(potentialhwlength*24);
                integWBTprctiles(stnc,month,potentialhwlength,1)=quantile(integWBTvec,0.975)/(potentialhwlength*24);
                integWBTprctiles(stnc,month,potentialhwlength,2)=quantile(integWBTvec,0.81)/(potentialhwlength*24);
            end
        end           
    end
    
    %Climatological percentiles for the regional average (of JFK, LGA, EWR) rather than an indiv stn
    for month=monthiwf:monthiwl
        for potentialhwlength=3:maxhwlength
            regTvecsavedforlater{month,potentialhwlength}=[integTvecsaveforlater{3,month,potentialhwlength}';...
                integTvecsaveforlater{4,month,potentialhwlength}';integTvecsaveforlater{5,month,potentialhwlength}'];
            regTprctiles(month,potentialhwlength,1)=...
                            quantile(regTvecsavedforlater{month,potentialhwlength},0.975)/(potentialhwlength*24);
            regWBTvecsavedforlater{month,potentialhwlength}=[integWBTvecsaveforlater{3,month,potentialhwlength}';...
                integWBTvecsaveforlater{4,month,potentialhwlength}';integWBTvecsaveforlater{5,month,potentialhwlength}'];
            regWBTprctiles(month,potentialhwlength,1)=...
                            quantile(regWBTvecsavedforlater{month,potentialhwlength},0.975)/(potentialhwlength*24);
        end
    end
    
    figure(figc);clf;
    x=1:maxhwlength;
    plot(x,squeeze(integWBTprctiles(7,6,:,1)));hold on; %dims are station;month;hw length;prctiles
    plot(x,squeeze(integWBTprctiles(7,7,:,1)),'r');
    plot(x,squeeze(integWBTprctiles(7,8,:,1)),'g');
    plot(x,squeeze(integWBTprctiles(5,6,:,1)),'bo-');
    plot(x,squeeze(integWBTprctiles(5,7,:,1)),'ro-');
    plot(x,squeeze(integWBTprctiles(5,8,:,1)),'go-');
    title('97.5th Percentile of Hourly-Average WBT by Heat-Wave Length for June, July, and August for Central Park & Newark',...
        'FontSize',16,'FontWeight','bold');
    xlabel('Heat-Wave Length (Days)','FontSize',14);
    ylabel('Deg C','FontSize',14);
    legend('CP Jun','CP Jul','CP Aug','EWR Jun','EWR Jul','EWR Aug');
end


%Show plot illustrating main heat-wave definition, in lieu of a verbose and
%difficult-to-penetrate jumble of a written explanation
if showdefnplot==1
    months=[7;6];starthour=[635857;652537];monthnames={'July';'June'};
    eventnames={'Jul 16-21, 2013';'Jun 11-13, 2015'};
    ylowerlims=[24;18];yupperlims=[33;30];
    for numplot=1:2
        mhere=months(numplot);shhere=starthour(numplot);mherename=monthnames{numplot};
        eherename=eventnames{numplot};ylowerlim=ylowerlims(numplot);yupperlim=yupperlims(numplot);
        figure(figc);clf;figc=figc+1;
        x=1:maxhwlength;
        plot(x,squeeze(integTprctiles(7,mhere,:,1)),':','LineWidth',2);hold on; %Central Park, (month), 97.5th percentile
        plot(x,squeeze(integTprctiles(7,mhere,:,2)),':','Color',colors('light purple'),'LineWidth',2); %81st percentile
        %From already having done this whole script, I know that the second-last Central Park heat
        %wave occurred on Jul 16-21, 2013, corresponding to hours 635857-636000
        %The last one occurred Jun 11-13, 2015, or hours 652537-652608
        integmean(1)=mean(hourlytvecs{7}(shhere:shhere+23,5));integmean(2)=mean(hourlytvecs{7}(shhere:shhere+47,5));
        integmean(3)=mean(hourlytvecs{7}(shhere:shhere+71,5));integmean(4)=mean(hourlytvecs{7}(shhere:shhere+95,5));
        integmean(5)=mean(hourlytvecs{7}(shhere:shhere+119,5));integmean(6)=mean(hourlytvecs{7}(shhere:shhere+143,5));
        integmean(7)=mean(hourlytvecs{7}(shhere:shhere+167,5));integmean(8)=mean(hourlytvecs{7}(shhere:shhere+191,5));
        integmean(9)=mean(hourlytvecs{7}(shhere:shhere+215,5));integmean(10)=mean(hourlytvecs{7}(shhere:shhere+239,5));
        dailyavg(1)=mean(hourlytvecs{7}(shhere:shhere+23,5));dailyavg(2)=mean(hourlytvecs{7}(shhere+24:shhere+47,5));
        dailyavg(3)=mean(hourlytvecs{7}(shhere+48:shhere+71,5));dailyavg(4)=mean(hourlytvecs{7}(shhere+72:shhere+95,5));
        dailyavg(5)=mean(hourlytvecs{7}(shhere+96:shhere+119,5));dailyavg(6)=mean(hourlytvecs{7}(shhere+120:shhere+143,5));
        dailyavg(7)=mean(hourlytvecs{7}(shhere+144:shhere+167,5));dailyavg(8)=mean(hourlytvecs{7}(shhere+168:shhere+191,5));
        dailyavg(9)=mean(hourlytvecs{7}(shhere+192:shhere+215,5));dailyavg(10)=mean(hourlytvecs{7}(shhere+216:shhere+239,5));
        plot(x,integmean,'r','LineWidth',2);
        plot(x,dailyavg,'Color',colors('light brown'),'LineWidth',2);
        ylim([ylowerlim yupperlim]);
        label1=sprintf('%s 97.5th Percentile',mherename);label2=sprintf('%s 81st Percentile',mherename);
        legend(label1,label2,'Cumulative Avg over Event','Individual-Day Avgs');
        %Determine algorithmically what killed heat wave, and mark its end with a nice big |
        endofhwbyindivday=max(polyxpoly(x,dailyavg,x,squeeze(integTprctiles(7,mhere,:,2))));
        endofhwbyintegval=max(polyxpoly(x,integmean,x,squeeze(integTprctiles(7,mhere,:,1))));
        [endofhw,whichresp]=min([endofhwbyindivday endofhwbyintegval]);
        if whichresp==1
            text(round2(endofhw,1,'floor'),dailyavg(round2(endofhw,1,'floor')),'|',...
                'FontSize',40,'FontWeight','bold','FontName','Arial');
        else
            text(round2(endofhw,1,'floor'),integmean(round2(endofhw,1,'floor')),'|',...
                'FontSize',40,'FontWeight','bold','FontName','Arial');
        end
        title(sprintf('Illustration of Heat-Wave Definition, Using Heat Wave of %s at Central Park',eherename),...
            'FontSize',16,'FontWeight','bold','FontName','Arial');
        xlabel('Potential Heat-Wave Length (Days)','FontSize',16,'FontWeight','bold','FontName','Arial');
        ylabel('Temperature (deg C)','FontSize',16,'FontWeight','bold','FontName','Arial');
    end
end


%Calculate the 90th percentile of temp, dewpt, HI, and WBT for each hour of the day by month & station
if usinghourlynrccdata==1
    if calculatehourlyprctiles==1
        hourly90prctiles=cell(numstns,1);
        for stnc=1:numstns
            fprintf('Calculating 90th pctiles for stn %d\n',stnc);
            datatbymonthandhour=zeros(12,24);datadewptbymonthandhour=zeros(12,24);
            datahibymonthandhour=zeros(12,24);datawbtbymonthandhour=zeros(12,24);
            counttobs=ones(12,24);countdewptobs=ones(12,24);
            counthiobs=ones(12,24);countwbtobs=ones(12,24);
            for i=1:size(hourlytvecs{stnc},1)
                curmonth=hourlytvecs{stnc}(i,3);
                curhour=hourlytvecs{stnc}(i,1);
                if hourlytvecs{stnc}(i,5)>-50
                    datatbymonthandhour(curmonth,curhour+1,counttobs)=hourlytvecs{stnc}(i,5);
                    counttobs(curmonth,curhour+1)=counttobs(curmonth,curhour+1)+1;
                end
                if hourlytvecs{stnc}(i,6)>-50
                    datadewptbymonthandhour(curmonth,curhour+1,countdewptobs)=hourlytvecs{stnc}(i,6);
                    countdewptobs(curmonth,curhour+1)=countdewptobs(curmonth,curhour+1)+1;
                end
                if hourlytvecs{stnc}(i,13)>-50 && hourlytvecs{stnc}(i,13)<=100
                    if curmonth==6 || curmonth==7 || curmonth==8
                        %heat indices are only calculated for warm days so
                        %including shoulder seasons is misleading
                        datahibymonthandhour(curmonth,curhour+1,counthiobs)=hourlytvecs{stnc}(i,13);
                        counthiobs(curmonth,curhour+1)=counthiobs(curmonth,curhour+1)+1;
                    end
                end
                if hourlytvecs{stnc}(i,14)>-50
                    datawbtbymonthandhour(curmonth,curhour+1,countwbtobs)=hourlytvecs{stnc}(i,14);
                    countwbtobs(curmonth,curhour+1)=countwbtobs(curmonth,curhour+1)+1;
                end
            end
            %With all the data now sorted, find the desired 90th percentiles for this station
            for month=1:12
                for hour=1:24
                    hourly90prctiles{stnc,1}(month,hour)=...
                        quantile(datatbymonthandhour(month,hour,:),0.9); %temperature
                    hourly90prctiles{stnc,2}(month,hour)=...
                        quantile(datadewptbymonthandhour(month,hour,:),0.9); %dewpoint
                    hourly90prctiles{stnc,3}(month,hour)=...
                        quantile(datahibymonthandhour(month,hour,:),0.9); %heat index
                    hourly90prctiles{stnc,4}(month,hour)=...
                        quantile(datawbtbymonthandhour(month,hour,:),0.9); %WBT
                end
            end
        end
    end
end


%Based on daily percentiles, create station catalogues of JJA heat waves ranked by severity
%Each station is entitled to its own heat waves
%OLD AND WILL BE SCHEDULED FOR DISMANTLEMENT
if makeheatwaverankingold==1
    for stnc=1:numstns
        numhws=0;consechotdayc=0;sotx=0;sotn=0; %last two are sums over threshold of max & min
        for jj=1:size(dailymaxvecs1D{stnc},1)
            if dailymaxvecs1D{stnc}(jj,daycol)>=m6sl && dailymaxvecs1D{stnc}(jj,daycol)<m9s %JJA
                if dailymaxvecs1D{stnc}(jj,daycol)<m7sl %June
                    if dailymaxvecs1D{stnc}(jj,1)>=monthlyprctilemaxes{stnc}(6,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stnc}(jj,1);
                        %a heatwave even though min temp may or may not be above its threshold
                        thishwmins(consechotdayc)=dailyminvecs1D{stnc}(jj,1);
                        if dailymaxvecs1D{stnc}(jj,1)>-50
                            sotx=sotx+dailymaxvecs1D{stnc}(jj,1)-monthlyprctilemaxes{stnc}(6,6);
                        end
                        %disp(jj);disp(dailymaxvecs1D{stnc}(jj,1));
                        %disp(monthlyprctilemaxes{stnc}(6,6));disp(sotx);
                        if dailyminvecs1D{stnc}(jj,1)>-50
                            sotn=sotn+dailyminvecs1D{stnc}(jj,1)-monthlyprctilemins{stnc}(6,6);
                        end
                    elseif dailyminvecs1D{stnc}(jj,1)>=monthlyprctilemins{stnc}(6,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stnc}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stnc}(jj,1);
                        if dailymaxvecs1D{stnc}(jj,1)>-50 %just to ensure it's not missing
                            sotx=sotx+dailymaxvecs1D{stnc}(jj,1)-monthlyprctilemaxes{stnc}(6,6);
                        end
                        if dailyminvecs1D{stnc}(jj,1)>-50
                            sotn=sotn+dailyminvecs1D{stnc}(jj,1)-monthlyprctilemins{stnc}(6,6);
                        end
                    else %a cool day...
                        if consechotdayc>=3 %...that ended a heatwave
                            numhws=numhws+1;
                            hwregisterbyT{stnc}(numhws,1)=dailymaxvecs1D{stnc}(jj,daycol)- ...
                                consechotdayc;
                            hwregisterbyT{stnc}(numhws,2)=dailymaxvecs1D{stnc}(jj,daycol)-1;
                            hwregisterbyT{stnc}(numhws,3)=dailymaxvecs1D{stnc}(jj,yrcol);
                            hwregisterbyT{stnc}(numhws,4)=max(thishwmaxes);
                            hwregisterbyT{stnc}(numhws,5)=max(thishwmins);
                            hwregisterbyT{stnc}(numhws,6)=sotx;
                            hwregisterbyT{stnc}(numhws,7)=sotn;
                            hwregisterbyT{stnc}(numhws,8)=sotx+sotn;
                        end
                        consechotdayc=0;
                        thishwmaxes=0;thishwmins=0;
                        sotx=0;sotn=0;
                    end
                elseif dailymaxvecs1D{stnc}(jj,daycol)>=m7sl && dailymaxvecs1D{stnc}(jj,daycol)<m8s
                    if dailymaxvecs1D{stnc}(jj,1)>=monthlyprctilemaxes{stnc}(7,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stnc}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stnc}(jj,1);
                        if dailymaxvecs1D{stnc}(jj,1)>-50
                            sotx=sotx+dailymaxvecs1D{stnc}(jj,1)-monthlyprctilemaxes{stnc}(7,6);
                        end
                        if dailyminvecs1D{stnc}(jj,1)>-50
                            sotn=sotn+dailyminvecs1D{stnc}(jj,1)-monthlyprctilemins{stnc}(7,6);
                        end
                    elseif dailyminvecs1D{stnc}(jj,1)>=monthlyprctilemins{stnc}(7,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stnc}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stnc}(jj,1);
                        if dailymaxvecs1D{stnc}(jj,1)>-50
                            sotx=sotx+dailymaxvecs1D{stnc}(jj,1)-monthlyprctilemaxes{stnc}(7,6);
                        end
                        if dailyminvecs1D{stnc}(jj,1)>-50
                            sotn=sotn+dailyminvecs1D{stnc}(jj,1)-monthlyprctilemins{stnc}(7,6);
                        end
                    else
                        if consechotdayc>=3 %a heatwave just ended
                            numhws=numhws+1;
                            hwregisterbyT{stnc}(numhws,1)=...
                                dailymaxvecs1D{stnc}(jj,daycol)-consechotdayc;
                            hwregisterbyT{stnc}(numhws,2)=dailymaxvecs1D{stnc}(jj,daycol)-1;
                            hwregisterbyT{stnc}(numhws,3)=dailymaxvecs1D{stnc}(jj,yrcol);
                            hwregisterbyT{stnc}(numhws,4)=max(thishwmaxes);
                            hwregisterbyT{stnc}(numhws,5)=max(thishwmins);
                            hwregisterbyT{stnc}(numhws,6)=sotx;
                            hwregisterbyT{stnc}(numhws,7)=sotn;
                            hwregisterbyT{stnc}(numhws,8)=sotx+sotn;
                        end
                        consechotdayc=0;
                        thishwmaxes=0;thishwmins=0;
                        sotx=0;sotn=0;
                    end
                else %August
                    if dailymaxvecs1D{stnc}(jj,1)>=monthlyprctilemaxes{stnc}(8,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stnc}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stnc}(jj,1);
                        if dailymaxvecs1D{stnc}(jj,1)>-50
                            sotx=sotx+dailymaxvecs1D{stnc}(jj,1)-monthlyprctilemaxes{stnc}(8,6);
                        end
                        if dailyminvecs1D{stnc}(jj,1)>-50
                            sotn=sotn+dailyminvecs1D{stnc}(jj,1)-monthlyprctilemins{stnc}(8,6);
                        end
                    elseif dailyminvecs1D{stnc}(jj,1)>=monthlyprctilemins{stnc}(8,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stnc}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stnc}(jj,1);
                        if dailymaxvecs1D{stnc}(jj,1)>-50
                            sotx=sotx+dailymaxvecs1D{stnc}(jj,1)-monthlyprctilemaxes{stnc}(8,6);
                        end
                        if dailyminvecs1D{stnc}(jj,1)>-50
                            sotn=sotn+dailyminvecs1D{stnc}(jj,1)-monthlyprctilemins{stnc}(8,6);
                        end
                    else
                        if consechotdayc>=3 %a heatwave just ended
                            numhws=numhws+1;
                            hwregisterbyT{stnc}(numhws,1)=...
                                dailymaxvecs1D{stnc}(jj,daycol)-consechotdayc;
                            hwregisterbyT{stnc}(numhws,2)=dailymaxvecs1D{stnc}(jj,daycol)-1;
                            hwregisterbyT{stnc}(numhws,3)=dailymaxvecs1D{stnc}(jj,yrcol);
                            hwregisterbyT{stnc}(numhws,4)=max(thishwmaxes);
                            hwregisterbyT{stnc}(numhws,5)=max(thishwmins);
                            hwregisterbyT{stnc}(numhws,6)=sotx;
                            hwregisterbyT{stnc}(numhws,7)=sotn;
                            hwregisterbyT{stnc}(numhws,8)=sotx+sotn;
                        end
                        consechotdayc=0;
                        thishwmaxes=0;thishwmins=0;
                        sotx=0;sotn=0;
                    end
                end
            elseif dailymaxvecs1D{stnc}(jj,daycol)==m9s %Sep 1, all heat waves must end par def'n
                consechotdayc=0;
            end
        end

        %Sort the result to have an ordered list of heat waves by severity score
        hwsorted{stnc}=sortrows(hwregisterbyT{stnc},-8);
    end
end

%Chronological catalogue of heat waves with new hourly-integrated definition
%This means heat waves are equally likely in each month (but this is good,
%because from an analysis standpoint circulation anomalies matter more than
%the absolute temperature achieved at the surface)
%Each station is again entitled to its own heat waves (but homogenized regional heat
%waves are defined according to what's going on at JFK, LGA, and Newark)
%Look for 3-day heat waves, then add one day at a time and see if heat wave continues or ends
if makeheatwaverankingnew==1
    %hwregisterbyT={};hwregisterbyWBT={};hwregister={};
    %reghwbyTstarts=0;reghwbyWBTstarts=0;hwbyTstarthours=0;hwbyWBTstarthours=0;
    hoursofhws={}; %preserve the hours of heat waves within hourlytvecs for later retrieval
    for variab=1:1 %T and WBT rankings are separate
        numreghws=0;reghwdays=0;reghwstarts=0;hwstarthours=0;
        reghwstartendhours=0;
        if variab==1;integXprctiles=integTprctiles;col=5;suffix1={'byT'};end
        if variab==2;integXprctiles=integWBTprctiles;col=14;suffix1={'byWBT'};end
        for stnc=1:stnl
            numhws=0;consechotdayc=0;i=1;
            while i<=size(hourlytvecs{stnc},1)-10*24
                if min(hourlytvecs{stnc}(i:i+71,col))>-50 %no missing data allowed
                    month=hourlytvecs{stnc}(i,3);
                    if month>=monthiwf && month<=monthiwl %search either in JJA or in MJJAS
                        integX=sum(hourlytvecs{stnc}(i:i+71,col))/72;
                        if integX>=integXprctiles(stnc,month,3,1) %meets the minimum reqts for a heat wave by T
                            hwlength=3;%fprintf('Starting heat wave # %d',numhws);
                            hwregister{stnc}(numhws+1,1)=...
                                DatetoDOY(hourlytvecs{stnc}(i,3),hourlytvecs{stnc}(i,2),hourlytvecs{stnc}(i,4));
                            hoursofhws{stnc}(numhws+1,1)=i; %heat wave's already 2 days old
                            %testing if we can take it to the next level
                            integXtest=sum(hourlytvecs{stnc}(i:i+(hwlength+1)*24-1,col))/((hwlength+1)*24);
                            potentialnewdaysum=sum(hourlytvecs{stnc}(i+(hwlength*24):i+(hwlength+1)*24-1,col))/24;
                            hwgoeson=1;
                            while hwlength<=maxhwlength && hwgoeson==1 %now, see about extending the heat wave beyond 3 days
                                %disp('line 607');disp(integXtest);disp(potentialnewdaysum);
                                %if hwlength<maxhwlength && curmonth<=8
                                %    disp(integXprctiles(stnc,curmonth,hwlength+1,1));
                                %    disp(integXprctiles(stnc,curmonth,1,2));
                                %end
                                if hwlength<maxhwlength;curmonth=hourlytvecs{stnc}(i+(hwlength+1)*24,3);end
                                if hwlength==maxhwlength || curmonth==monthiwl+1 %%%heat wave needs to end%%%
                                    hwgoeson=0;numhws=numhws+1;
                                    hwregister{stnc}(numhws,2)=...
                                        DatetoDOY(hourlytvecs{stnc}(i+hwlength*24-1,3),hourlytvecs{stnc}(i+hwlength*24-1,2),...
                                        hourlytvecs{stnc}(i+hwlength*24-1,4));
                                    hwregister{stnc}(numhws,3)=hourlytvecs{stnc}(i+hwlength*24-1,4);
                                    hoursofhws{stnc}(numhws,2)=i+hwlength*24-1;
                                elseif integXtest>integXprctiles(stnc,curmonth,hwlength+1,1) && ...
                                    potentialnewdaysum>integXprctiles(stnc,curmonth,1,2) %%%heat wave is extended%%%
                                    %disp(potentialnewdaysum);disp('here i am');disp(integTprctiles(stnc,curmonth,1,1));
                                    hwlength=hwlength+1;%disp(hwlength);
                                    integXtest=sum(hourlytvecs{stnc}(i:i+(hwlength+1)*24-1,col))/((hwlength+1)*24);
                                    potentialnewdaysum=sum(hourlytvecs{stnc}(i+(hwlength*24):i+(hwlength+1)*24-1,col))/24;
                                else %%%heat wave is no longer extended%%%
                                    hwgoeson=0;numhws=numhws+1;
                                    hwregister{stnc}(numhws,2)=...
                                        DatetoDOY(hourlytvecs{stnc}(i+hwlength*24-1,3),hourlytvecs{stnc}(i+hwlength*24-1,2),...
                                        hourlytvecs{stnc}(i+hwlength*24-1,4));
                                    hwregister{stnc}(numhws,3)=hourlytvecs{stnc}(i+hwlength*24-1,4);
                                    hoursofhws{stnc}(numhws,2)=i+hwlength*24-1;
                                end
                            end
                            i=i+hwlength*24;
                        else
                            i=i+24;
                        end
                    else
                        i=i+24;
                    end
                else
                    i=i+24; %on to the next day (and thus 3-day period)
                end
            end
        end
        if variab==1;hwregisterbyT=hwregister;end
        if variab==2;hwregisterbyWBT=hwregister;end
        
        
        %Calculate dates for homogenized regional heat waves (i.e. days when
        %2 out of 3 of LGA, JFK, and Newark are experiencing a heat wave)
        register=eval(['hwregister' char(suffix1)]);c=1;
        hwchere=0;stnthatstartedit=0;stninthemiddle=0;stnthatfinishedit=0;
        for row=1:100;thishwhasbeennoted(row,3)=0;thishwhasbeennoted(row,4)=0;end
        for stnc=3:4 %all possible heat-wave days must show up in at least one of these
            for row=1:size(register{stnc},1)
                for potentialhwday=register{stnc}(row,1):register{stnc}(row,2)
                    totalstnshwc=1; %how many stations are experiencing a heat wave on this day
                    potentialhwyear=register{stnc}(row,3);
                    potentialhwstarthour=hoursofhws{stnc}(row,1);
                    %disp(potentialhwday);disp(potentialhwyear);
                    for otherstns=3:5
                        if otherstns~=stnc
                        %if otherstns~=6 %only if Central Park is one of the definers
                            for i=1:size(register{otherstns},1)
                                otherstartday=register{otherstns}(i,1);otherendday=register{otherstns}(i,2);
                                otherstarthour=hoursofhws{otherstns}(i,1);otherendhour=hoursofhws{otherstns}(i,2);
                                year=register{otherstns}(i,3);
                                if year==potentialhwyear
                                    if otherstartday<=potentialhwday && otherendday>=potentialhwday
                                        if thishwhasbeennoted(row,3)==0 && thishwhasbeennoted(row,4)==0
                                            hwchere=hwchere+1;
                                            thishwhasbeennoted(row,stnc)=1;
                                        end
                                        stnthatstartedit(hwchere)=stnc;
                                        stnthatstarteditfirsthour{hwchere}=hourlytvecs{stnc};
                                        if otherstns==4
                                            stnthatfinishedit(hwchere)=4;
                                        elseif otherstns==5 %need to consider both stn 4 & stn 5 in determining the hours of this hw
                                            stninthemiddle(hwchere)=4;
                                            stnthatfinishedit(hwchere)=5;
                                        end
                                        totalstnshwc=totalstnshwc+1;
                                    end
                                end
                            end
                        end
                    end
                    if totalstnshwc>=2
                        %disp('regional hw day');
                        %disp(potentialhwday);disp(potentialhwyear);
                        reghwdays(c,1)=potentialhwday;
                        reghwdays(c,2)=potentialhwyear;
                        reghwstartendhours(c,1)=potentialhwstarthour; %start hour of this heat wave, referenced to hourlytvecs
                        reghwstartendhours(c,2)=potentialhwstarthour+24*(otherendday-otherstartday+1); %end hour
                        c=c+1;
                    end
                end
            end
        end
        %disp(reghwdays);
        %Remove duplicate rows
        reghwdays=sortrows(unique(reghwdays,'rows'),2);
        
    
    
        %The resulting homogenized regional heat-wave days almost entirely fall
        %into 3-or-more-day chunks, qualifying them as heat waves themselves by the
        %original definition; thus, it is reasonable to enforce the 3-day rule for
        %these heat waves, in the process weeding out the stray heat-wave days here 
        %and there not part of a long-enough event for enough stations simultaneously

        %New loop for weeding out stray hot days that aren't part of >=3-day
        %events, creating the array reghwdayscl, a 'clean' register of
        %regional heat waves
        rowon=1;withinvalidheatwave=0;rowtocreate=1;curhwlength=0;
        while rowon<=size(reghwdays,1)-2
            if withinvalidheatwave==1
                if rowon>=2
                    currowday=reghwdays(rowon,1);currowyear=reghwdays(rowon,2);
                    prevrowday=reghwdays(rowon-1,1);prevrowyear=reghwdays(rowon-1,2);
                    %Within a heat wave and it goes on, so inch along day by day
                    if currowday==prevrowday+1
                        reghwdayscl(rowtocreate,:)=reghwdays(rowon,:);
                        rowon=rowon+1;rowtocreate=rowtocreate+1;
                        curhwlength=curhwlength+1;
                    else
                        %Ok that heat wave's over, but are we at the start of another one?
                        currowday=reghwdays(rowon,1);currowyear=reghwdays(rowon,2);
                        nextrowday=reghwdays(rowon+1,1);nextrowyear=reghwdays(rowon+1,2);
                        tworowsdownday=reghwdays(rowon+2,1);tworowsdownyear=reghwdays(rowon+2,2);
                        if tworowsdownyear==currowyear && tworowsdownday==currowday+2
                            withinvalidheatwave=1;
                            reghwdayscl(rowtocreate:rowtocreate+2,:)=reghwdays(rowon:rowon+2,:);
                            rowon=rowon+3;rowtocreate=rowtocreate+3;%rowtocreate2=rowtocreate2+1;
                            curhwlength=3;
                        else
                            %Heat wave is over, get back up and look for the next one
                            withinvalidheatwave=0;
                            rowon=rowon+1;curhwlength=0;
                        end
                    end
                end
            else
                currowday=reghwdays(rowon,1);currowyear=reghwdays(rowon,2);
                nextrowday=reghwdays(rowon+1,1);nextrowyear=reghwdays(rowon+1,2);
                tworowsdownday=reghwdays(rowon+2,1);tworowsdownyear=reghwdays(rowon+2,2);
                if tworowsdownyear==currowyear && tworowsdownday==currowday+2
                    withinvalidheatwave=1;
                    reghwdayscl(rowtocreate:rowtocreate+2,:)=reghwdays(rowon:rowon+2,:);
                    rowon=rowon+3;rowtocreate=rowtocreate+3;
                    curhwlength=3;
                else
                    withinvalidheatwave=0;
                    rowon=rowon+1;curhwlength=0;
                end
            end
        end
        
        %Turn around and use reghwdayscl to create a new improved version of 
        %reghwstarts, as the old one seemed to have some bugs
        rowon=1;withinvalidheatwave=0;rowtocreate2=1;curhwlength=0;reghwstarts=0;
        while rowon<=size(reghwdayscl,1)
            if withinvalidheatwave==1
                if rowon>=2
                    currowday=reghwdayscl(rowon,1);currowyear=reghwdayscl(rowon,2);
                    prevrowday=reghwdayscl(rowon-1,1);prevrowyear=reghwdayscl(rowon-1,2);
                    %Within a heat wave and it goes on, so inch along day by day
                    if currowday==prevrowday+1
                        rowon=rowon+1;
                        curhwlength=curhwlength+1;
                        if rowon==size(reghwdayscl,1)
                            reghwstarts(rowtocreate2,3)=curhwlength;
                            rowtocreate2=rowtocreate2+1;
                        end
                    else
                        reghwstarts(rowtocreate2,1:2)=reghwdayscl(rowon-curhwlength,1:2);
                        reghwstarts(rowtocreate2,3)=curhwlength;
                        rowtocreate2=rowtocreate2+1;
                        %Ok that heat wave's over, but are we at the start of another one?
                        currowday=reghwdayscl(rowon,1);currowyear=reghwdayscl(rowon,2);
                        nextrowday=reghwdayscl(rowon+1,1);nextrowyear=reghwdayscl(rowon+1,2);
                        tworowsdownday=reghwdayscl(rowon+2,1);tworowsdownyear=reghwdayscl(rowon+2,2);
                        if tworowsdownyear==currowyear && tworowsdownday==currowday+2
                            %we are
                            withinvalidheatwave=1;
                            reghwstarts(rowtocreate2,1:2)=reghwdayscl(rowon,1:2);
                            curhwlength=3;
                            reghwstarts(rowtocreate2,3)=curhwlength;
                            rowon=rowon+3;
                        else
                            %we still are not...
                            withinvalidheatwave=0;
                            reghwstarts(rowtocreate2,3)=curhwlength;
                            rowon=rowon+1;rowtocreate2=rowtocreate2+1;
                            curhwlength=0;
                        end
                    end
                end
            else
                currowday=reghwdayscl(rowon,1);currowyear=reghwdayscl(rowon,2);
                nextrowday=reghwdayscl(rowon+1,1);nextrowyear=reghwdayscl(rowon+1,2);
                tworowsdownday=reghwdayscl(rowon+2,1);tworowsdownyear=reghwdayscl(rowon+2,2);
                if tworowsdownyear==currowyear && tworowsdownday==currowday+2
                    withinvalidheatwave=1;
                    rowon=rowon+3;curhwlength=3;
                    if rowon==size(reghwdayscl,1)+1
                        reghwstarts(rowtocreate2,3)=curhwlength;
                    end
                else
                    withinvalidheatwave=0;
                    reghwstarts(rowtocreate2,3)=curhwlength;
                    rowon=rowon+1;rowtocreate2=rowtocreate2+1;
                    curhwlength=0;
                end
            end
        end
        
        %Actually, scratch all that and do it by hand since I need to get
        %this done expeditiously before the Master's paper deadline
        %531169-531240 seems to be one by hand, but it wasn't included in
        %the main reg-hw register (reghwstarts)
        reghwstarthours=[67033;74329;75121;75385;100609;109897;110905;127801;135385;...
            144217;161569;188089;197041;197161;205945;286249;303121;347089;355129;380713;...
            398929;415921;416089;417313;425929;442537;443041;460321;477385;477985;478465;...
            539089;539737;540073;547657;564913;566137;566353;574489;574825;591121;609001;609097;...
            609265;609553;610009;610633;618409;635833;653449];
        reghwendhours=[67176;74400;75216;75480;100704;109968;111072;127968;135504;...
            144336;161640;188160;197136;197232;206016;286320;303192;347184;355296;380832;...
            399000;416016;416184;417528;426000;442608;443136;460488;477456;478056;478560;...
            539160;539928;540264;547752;564984;566232;566448;574560;574992;591240;609072;609168;...
            609408;609720;610080;610704;618480;635976;653520];
        for ii=1:size(reghwstarthours,1);monthsofstarts(ii)=DOYtoMonth(reghwstarts(ii,1),reghwstarts(ii,2));end
        reghwstartendhours=zeros(size(reghwstarthours,1),1);
        reghwstartendhours(:,1)=reghwstarthours;
        reghwstartendhours(:,2)=reghwendhours;
        reghwstartendhours(:,3)=monthsofstarts';
        
        %Unnecessary
        %reghwstartendhours=sortrows(unique(reghwstartendhours,'rows'),2);
        
        %Similar, older, and more-elegant way of getting much the same information
        %Find rows corresponding to start hours of these heat waves in the NRCC hourly data, for
        %purposes of efficiency
        firstmatchfound=0;
        startday=reghwstarts(1,1);startyear=reghwstarts(1,2);
        row=1;
        while row<=size(hourlytvecs{1},1) && firstmatchfound==0
            htvday=DatetoDOY(hourlytvecs{1}(row,3),hourlytvecs{1}(row,2),hourlytvecs{1}(row,4));
            htvyear=hourlytvecs{1}(row,4);
            if htvday==startday && htvyear==startyear
                %disp('Match found');
                firstmatchfound=1;%disp(htvday);disp(htvyear);
                hwstarthours(1,1)=row;hwstarthours(1,2)=htvday;hwstarthours(1,3)=htvyear;
            end
            row=row+1;
        end
        row=row-1;
        %Now, use DaysApart function to calculate the other rows
        %Date 1--what I already have; Date 2--the next one
        for i=2:size(reghwstarts,1)
            mon1=DOYtoMonth(reghwstarts(i-1,1),reghwstarts(i-1,2));
            day1=DOYtoDOM(reghwstarts(i-1,1),reghwstarts(i-1,2));
            year1=reghwstarts(i-1,2);
            mon2=DOYtoMonth(reghwstarts(i,1),reghwstarts(i,2));
            day2=DOYtoDOM(reghwstarts(i,1),reghwstarts(i,2));
            year2=reghwstarts(i,2);
            date2=DatetoDOY(mon2,day2,year2);
            daystojump=DaysApart(mon1,day1,year1,mon2,day2,year2);
            row=row+(daystojump)*24;
            hwstarthours(i,1)=row;hwstarthours(i,2)=date2;hwstarthours(i,3)=year2;
            %disp(row);
        end
        
        if variab==1
            reghwdaysbyT=reghwdayscl;reghwbyTstarts=reghwstarts;numreghwsbyT=size(reghwstarts,1);
            hwbyTstarthours=hwstarthours;
        elseif variab==2
            reghwdaysbyWBT=reghwdayscl;reghwbyWBTstarts=reghwstarts;numreghwsbyWBT=size(reghwstarts,1);
            hwbyWBTstarthours=hwstarthours;
        end
    end
end



%T- and WBT-based severity scores for *stations* during **homogenized (regional) heat waves**
%***as defined by temperature*** (can't do it all -- calculating these stats for two
%separate sets of heat waves would just be introducing too much complexity with little benefit)
%Calculates heat-wave-severity scores as sums over all the hours of the
%heat wave, subtracting off the 90th pctile for that hour (in the appropriate month, at the appropriate station)
%-----Add an option to sum values over an absolute threshold:
%[based on previous studies, these are typically 90 F for daytime temp ("hot days"), 
%72 F for nighttime temp ("tropical nights"), and 75 F for WBT
%Daytime is, as before, 9 AM-8 PM, with nighttime 9 PM-8 AM
%For day/night comparison, slight difference/bias in doing percents vs absolute is probably made up for 
%by the fact that max temps are more impactful simply by virtue of being higher
%One thing that aids in efficiency is that all stations have the same # of rows of data

%Also calculates percentiles of T and WBT for each heat wave, based on its
%length and relative to the distribution calculated in computebasicstats
if calchwseverityscores==1
    scorescompb=zeros(numstns,numreghwsbyT,2); %b stands for 'both', i.e. day & night
    scorescompx=zeros(numstns,numreghwsbyT,2);scorescompn=zeros(numstns,numreghwsbyT,2);
    for i=1:numstns
        fprintf('Calculating hw-severity scores for stn %d\n',i);
        c=1;tscore=zeros(numreghwsbyT,3);wbtscore=zeros(numreghwsbyT,3);
        tscoreper=zeros(numreghwsbyT,3);wbtscoreper=zeros(numreghwsbyT,3); %per-day scores, vs hw sums
        validthrs=zeros(numreghwsbyT,1);validwbthrs=zeros(numreghwsbyT,1);
        validthrsx=zeros(numreghwsbyT,1);validwbthrsx=zeros(numreghwsbyT,1);
        validthrsn=zeros(numreghwsbyT,1);validwbthrsn=zeros(numreghwsbyT,1);
        tscorex=zeros(numreghwsbyT,3);tscoren=zeros(numreghwsbyT,3); %for max/day only, & min/night only respectively
        tscorexper=zeros(numreghwsbyT,3);tscorenper=zeros(numreghwsbyT,3);
        wbtscorex=zeros(numreghwsbyT,3);wbtscoren=zeros(numreghwsbyT,3);
        wbtscorexper=zeros(numreghwsbyT,3);wbtscorenper=zeros(numreghwsbyT,3);
        validhrsperhw=24*reghwbyTstarts(1:numreghwsbyT,3);
        row=hwbyTstarthours(1);
        while row<size(hourlytvecs{i},1) %row counter for all data
            for hwc=1:numreghwsbyT %heat-wave counter
                curDOY=DatetoDOY(hourlytvecs{i}(row,3),hourlytvecs{i}(row,2),hourlytvecs{i}(row,4));
                sumt=0;sumwbt=0;
                if curDOY==hwbyTstarthours(hwc,2) && hourlytvecs{i}(row,1)==0 &&...
                        hourlytvecs{i}(row,4)==hwbyTstarthours(hwc,3) %first hour of a regional heat wave
                    %disp('first hour of a regional heat wave');
                    curmon=hourlytvecs{i}(row,3);curhour=hourlytvecs{i}(row,1);
                    tprctile90thishr=hourly90prctiles{i,1}(curmon,curhour+1);
                    wbtprctile90thishr=hourly90prctiles{i,4}(curmon,curhour+1);
                    %disp(row);disp(i);
                    for k=1:reghwbyTstarts(hwc,3)*24 %loop through the duration of the heat wave, hour by hour
                        curhour=hourlytvecs{i}(row+k-1,1);
                        %1. Sum up temperature
                        if hourlytvecs{i}(row+k-1,5)>-50
                            sumt=sumt+hourlytvecs{i}(row+k-1,5);
                            if relativescores==1
                                tscore(c,1)=tscore(c,1)+hourlytvecs{i}(row+k-1,5)-tprctile90thishr;
                                validthrs(c)=validthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    tscorex(c,1)=tscorex(c,1)+hourlytvecs{i}(row+k-1,5)-tprctile90thishr;
                                    validthrsx(c)=validthrsx(c)+1;
                                else %nighttime
                                    tscoren(c,1)=tscoren(c,1)+hourlytvecs{i}(row+k-1,5)-tprctile90thishr;
                                    validthrsn(c)=validthrsn(c)+1;
                                end
                            else
                                validthrs(c)=validthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    if hourlytvecs{i}(row+k-1,5)>absthreshdayt
                                        tscorex(c,1)=tscorex(c,1)+hourlytvecs{i}(row+k-1,5);
                                        validthrsx(c)=validthrsx(c)+1;
                                        tscore(c,1)=tscore(c,1)+hourlytvecs{i}(row+k-1,5);
                                    end
                                else
                                    if hourlytvecs{i}(row+k-1,5)>absthreshnightt
                                        tscoren(c,1)=tscoren(c,1)+hourlytvecs{i}(row+k-1,5);
                                        validthrsn(c)=validthrsn(c)+1;
                                        tscore(c,1)=tscore(c,1)+hourlytvecs{i}(row+k-1,5);
                                    end
                                end
                            end
                        end
                        %2. Sum up wet-bulb temperature
                        if hourlytvecs{i}(row+k-1,14)>-50
                            sumwbt=sumwbt+hourlytvecs{i}(row+k-1,14);
                            if relativescores==1
                                wbtscore(c,1)=wbtscore(c,1)+hourlytvecs{i}(row+k-1,14)-wbtprctile90thishr;
                                validwbthrs(c)=validwbthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    wbtscorex(c,1)=wbtscorex(c,1)+hourlytvecs{i}(row+k-1,14)-wbtprctile90thishr;
                                    validwbthrsx(c)=validwbthrsx(c)+1;
                                else
                                    wbtscoren(c,1)=wbtscoren(c,1)+hourlytvecs{i}(row+k-1,14)-wbtprctile90thishr;
                                    validwbthrsn(c)=validwbthrsn(c)+1;
                                end
                            else
                                validwbthrs(c)=validwbthrs(c)+1;
                                if curhour>=9 && curhour<=20 %daytime
                                    if hourlytvecs{i}(row+k-1,14)>absthreshwbt
                                        wbtscorex(c,1)=wbtscorex(c,1)+hourlytvecs{i}(row+k-1,14);
                                        validwbthrsx(c)=validwbthrsx(c)+1;
                                        wbtscore(c,1)=wbtscore(c,1)+hourlytvecs{i}(row+k-1,14);
                                    end
                                else
                                    if hourlytvecs{i}(row+k-1,14)>absthreshwbt
                                        wbtscoren(c,1)=wbtscoren(c,1)+hourlytvecs{i}(row+k-1,14);
                                        validwbthrsn(c)=validwbthrsn(c)+1;
                                        wbtscore(c,1)=wbtscore(c,1)+hourlytvecs{i}(row+k-1,14);
                                    end
                                end
                            end
                        end

                    end
                    
                    %Just catalogue the summed T and WBT values (already knowing the heat-wave length)
                    tsums{i}(c,1)=sumt;wbtsums{i}(c,1)=sumwbt;
                    tsums{i}(c,2)=reghwbyTstarts(hwc,1);tsums{i}(c,3)=reghwbyTstarts(hwc,2);
                    tsums{i}(c,4)=reghwbyTstarts(hwc,3);
                    wbtsums{i}(c,2)=reghwbyTstarts(hwc,1);wbtsums{i}(c,3)=reghwbyTstarts(hwc,2);
                    wbtsums{i}(c,4)=reghwbyTstarts(hwc,3);
                    
                    %For severity scores, normalize to take into account non-valid hours, and
                    %then divide again to get per-day values
                    tscore(c,1)=tscore(c,1)*validthrs(c)/validhrsperhw(c);tscoreper(c,1)=tscore(c,1)/(validhrsperhw(c)/24);
                    wbtscore(c,1)=wbtscore(c,1)*validwbthrs(c)/validhrsperhw(c);wbtscoreper(c,1)=wbtscore(c,1)/(validhrsperhw(c)/24);
                    tscore(c,2)=reghwbyTstarts(hwc,1);tscoreper(c,2)=tscore(c,2);
                    wbtscore(c,2)=reghwbyTstarts(hwc,1);wbtscoreper(c,2)=wbtscore(c,2);
                    tscore(c,3)=reghwbyTstarts(hwc,2);tscoreper(c,3)=tscore(c,3);
                    wbtscore(c,3)=reghwbyTstarts(hwc,2);wbtscoreper(c,3)=wbtscore(c,3);
                    tscorex(c,1)=tscorex(c,1)*validthrsx(c)/(validhrsperhw(c)/2);tscorexper(c,1)=tscorex(c,1)/(validhrsperhw(c)/24);
                    wbtscorex(c,1)=wbtscorex(c,1)*validwbthrsx(c)/(validhrsperhw(c)/2);
                    wbtscorexper(c,1)=wbtscorex(c,1)/(validhrsperhw(c)/24);
                    tscorex(c,2)=reghwbyTstarts(hwc,1);tscorexper(c,2)=tscorex(c,2);
                    wbtscorex(c,2)=reghwbyTstarts(hwc,1);wbtscorexper(c,2)=wbtscorex(c,2);
                    tscorex(c,3)=reghwbyTstarts(hwc,2);tscorexper(c,3)=tscorex(c,3);
                    wbtscorex(c,3)=reghwbyTstarts(hwc,2);wbtscorexper(c,3)=wbtscorex(c,3);
                    tscoren(c,1)=tscoren(c,1)*validthrsn(c)/(validhrsperhw(c)/2);tscorenper(c,1)=tscoren(c,1)/(validhrsperhw(c)/24);
                    wbtscoren(c,1)=wbtscoren(c,1)*validwbthrsn(c)/(validhrsperhw(c)/2);
                    wbtscorenper(c,1)=wbtscoren(c,1)/(validhrsperhw(c)/24);
                    tscoren(c,2)=reghwbyTstarts(hwc,1);tscorenper(c,2)=tscoren(c,2);
                    wbtscoren(c,2)=reghwbyTstarts(hwc,1);wbtscorenper(c,2)=wbtscoren(c,2);
                    tscoren(c,3)=reghwbyTstarts(hwc,2);tscorenper(c,3)=tscoren(c,3);
                    wbtscoren(c,3)=reghwbyTstarts(hwc,2);wbtscorenper(c,3)=wbtscoren(c,3);
                    c=c+1;if c<=size(hwbyTstarthours,1);row=hwbyTstarthours(c);else row=size(hourlytvecs{i},1);end
                end
            end
        end

        %Put into chronological order
        tscore=sortrows(tscore,3);wbtscore=sortrows(wbtscore,3);
        tscorex=sortrows(tscorex,3);wbtscorex=sortrows(wbtscorex,3);
        tscoren=sortrows(tscoren,3);wbtscoren=sortrows(wbtscoren,3);
        tscoreper=sortrows(tscoreper,3);wbtscoreper=sortrows(wbtscoreper,3);
        tscorexper=sortrows(tscorexper,3);wbtscorexper=sortrows(wbtscorexper,3);
        tscorenper=sortrows(tscorenper,3);wbtscorenper=sortrows(wbtscorenper,3);

        scorescompb(i,:,1)=tscore(:,1);scorescompb(i,:,2)=wbtscore(:,1);
        scorescompx(i,:,1)=tscorex(:,1);scorescompx(i,:,2)=wbtscorex(:,1);
        scorescompn(i,:,1)=tscoren(:,1);scorescompn(i,:,2)=wbtscoren(:,1);
        scorescompbper(i,:,1)=tscoreper(:,1);scorescompbper(i,:,2)=wbtscoreper(:,1);
        scorescompxper(i,:,1)=tscorexper(:,1);scorescompxper(i,:,2)=wbtscorexper(:,1);
        scorescompnper(i,:,1)=tscorenper(:,1);scorescompnper(i,:,2)=wbtscorenper(:,1);
    end
    %Heat-wave scores across heat waves consolidated into averages for each station
    %1 for T, 2 for WBT
    for i=1:numstns
        scorescompbstnavg(i,1)=sum(scorescompb(i,:,1))/(numreghwsbyT);
        scorescompxstnavg(i,1)=sum(scorescompx(i,:,1))/(numreghwsbyT);
        scorescompnstnavg(i,1)=sum(scorescompn(i,:,1))/(numreghwsbyT);
        scorescompbstnavg(i,2)=sum(scorescompb(i,:,2))/(numreghwsbyT);
        scorescompxstnavg(i,2)=sum(scorescompx(i,:,2))/(numreghwsbyT);
        scorescompnstnavg(i,2)=sum(scorescompn(i,:,2))/(numreghwsbyT);
    end
    %Per-day heat-wave scores across stations consolidated into averages for each heat wave
    %This is done across all NRCC-hourly stations (could do for Big Three as well)
    for i=1:numreghwsbyT
        scorescompbperhwavg(i,1)=sum(scorescompbper(:,i,1))/(numstns);
        scorescompxperhwavg(i,1)=sum(scorescompxper(:,i,1))/(numstns);
        scorescompnperhwavg(i,1)=sum(scorescompnper(:,i,1))/(numstns);
        scorescompbperhwavg(i,2)=sum(scorescompbper(:,i,2))/(numstns);
        scorescompxperhwavg(i,2)=sum(scorescompxper(:,i,2))/(numstns);
        scorescompnperhwavg(i,2)=sum(scorescompnper(:,i,2))/(numstns);
    end
    %Regional heat-wave percentiles from the Big Three stations
    vecplus1t=0;vecplus2t=0; vecplus1wbt=0;vecplus2wbt=0;
    for i=1:numreghwsbyT
        curmon=DOYtoMonth(reghwbyTstarts(i,1),reghwbyTstarts(i,2));
        curhwlength=reghwbyTstarts(i,3)*24; %in hours
        if i==14 || i==15 %1973 and 1975 heat waves in which LGA only has 3-hourly data
            totalt=tsums{3}(i,1)+3*tsums{4}(i,1)+tsums{5}(i,1);
            totalwbt=wbtsums{3}(i,1)+3*wbtsums{4}(i,1)+wbtsums{5}(i,1);
        else
            totalt=tsums{3}(i,1)+tsums{4}(i,1)+tsums{5}(i,1);
            totalwbt=wbtsums{3}(i,1)+wbtsums{4}(i,1)+wbtsums{5}(i,1);
        end
        avgt=totalt/(3*curhwlength); %across the 3 stns & all hours of this hw
        avgwbt=totalwbt/(3*curhwlength);
        %Find percentile of this avgT by calculating its rank within the vector of
        %all values for this month and length
        vecplus1t=[regTvecsavedforlater{curmon,curhwlength/24}/(curhwlength);avgt];
        vecplus2t=1:size(vecplus1t,1);
        vecplusnewt=zeros(size(vecplus1t,1),2);
        vecplusnewt(:,1)=vecplus1t;vecplusnewt(:,2)=vecplus2t';
        sortedvpnt=sortrows(vecplusnewt);
        [aat,bbt]=max(sortedvpnt(:,2));
        prctilerankofthisavgT=100*bbt/size(vecplus1t,1);
        scorescomptotalhw(i,1)=prctilerankofthisavgT;
        vecplus1wbt=[regWBTvecsavedforlater{curmon,curhwlength/24}/(curhwlength);avgwbt];
        vecplus2wbt=1:size(vecplus1wbt,1);
        vecplusnewwbt=zeros(size(vecplus1wbt,1),2);
        vecplusnewwbt(:,1)=vecplus1wbt;vecplusnewwbt(:,2)=vecplus2wbt';
        sortedvpnwbt=sortrows(vecplusnewwbt);
        [aawbt,bbwbt]=max(sortedvpnwbt(:,2));
        prctilerankofthisavgWBT=100*bbwbt/size(vecplus1wbt,1);
        scorescomptotalhw(i,2)=prctilerankofthisavgWBT;
    end
end

if makehwseverityscatterplot==1
    %Create scatterplot of one kind of score vs another for all stns over these recent heat waves
    %Recall that rows of scorescompZ are stations and columns are heatwaves
    if daytimeonly==1
        if perday==1
            suffix1=['x'];suffix2=['per'];phr=', Per-Day Average';
        else
            phr=', Daytime-Only Sum';
        end
    elseif nighttimeonly==1
        if perday==1
            suffix1=['n'];suffix2=['per'];phr=', Per-Night Average';
        else
            phr=', Nighttime-Only Sum';
        end
    else
        if perday==1
            suffix1=['b'];phr=', Per-Full-Day Average';
        else
            phr='';
        end
    end
    sc=eval(['scorescomp' suffix1 suffix2]);sc2=eval(['scorescomp' suffix1 'stnavg']);
    scper=eval(['scorescomp' suffix1 suffix2]);
    %colors for the different stations
    colorlistshort={colors('red');colors('light red');colors('orange');colors('green');colors('teal');...
        colors('light blue');colors('blue');colors('light purple');colors('pink');colors('brown');colors('grey')};
    %colors for the different heat waves
    colorlisthws=varycolor(numreghwsbyT/3); %too hard to differentiate so many colors, so need to use symbols also
    markerlisthws={'d';'s';'o'};
    colorlistlong=varycolor(numreghwsbyT);
    grouplist=[2,2,2,2,1,1,2,2,1,2,1]; %inland/coastal stations
    colorlistg={colors('red');colors('green')};
    markerlistg={'s';'+'};
    markerlist={'s';'d';'h';'v';'o';'+';'*';'x';'>';'p';'^'};
    figure(figc);figc=figc+1;
    noonesyet=1;notwosyet=1;h=0;hc=1;
    for i=1:numstns
        if consolidatestns==0
            for j=1:numreghwsbyT
                %disp(colorlist{i});
                if groupbyregion==1
                    if colorsbyhwsymbolsbygroup==1
                        scatter(sc(i,j,score1),sc(i,j,score2),markerlistg{grouplist(i)},'MarkerFaceColor',colorlistlong(j,:),...
                                'MarkerEdgeColor',colorlistlong(j,:),'LineWidth',3);
                        if grouplist(i)==1 && noonesyet==1 %only do once for each group
                            h(hc)=scatter(sc(i,j,score1),sc(i,j,score2),markerlistg{grouplist(i)},...
                                'MarkerFaceColor',colorlistlong(j,:),'MarkerEdgeColor',colorlistlong(j,:),'LineWidth',3);
                            hc=hc+1;noonesyet=0;
                        elseif grouplist(i)==2 && notwosyet==1
                            h(hc)=scatter(sc(i,j,score1),sc(i,j,score2),markerlistg{grouplist(i)},...
                                'MarkerFaceColor',colorlistlong(j,:),'MarkerEdgeColor',colorlistlong(j,:),'LineWidth',3);
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
                    if colorsbyhwsymbolsbystn==1
                        scatter(sc(i,j,score1),sc(i,j,score2),markerlist{i},'MarkerFaceColor',colorlistlong(j,:),...
                                'MarkerEdgeColor',colorlistlong(j,:),'LineWidth',3);
                        if j==1 %only do once for each stn, to give plot handles the info they need
                            h(i)=scatter(sc(i,j,score1),sc(i,j,score2),markerlist{i},'MarkerFaceColor',colors('light brown'),...
                                'MarkerEdgeColor',colors('light brown'),'LineWidth',3);
                        end
                    else
                        if colorsbyhw==1
                            scatter(sc(i,j,score1),sc(i,j,score2),markerlisthws{round2(j/16,1,'ceil')},...
                                'MarkerFaceColor',colorlisthws(round2(j/3,1,'ceil'),:),...
                                    'MarkerEdgeColor',colorlisthws(round2(j/3,1,'ceil'),:),'LineWidth',3);
                            if j==1 %only do once for each stn, to give plot handles the info they need
                                h(i)=scatter(sc(i,j,score1),sc(i,j,score2),markerlisthws{round2(j/16,1,'ceil')},...
                                'MarkerFaceColor',colorlisthws(round2(j/3,1,'ceil'),:),...
                                    'MarkerEdgeColor',colorlisthws(round2(j/3,1,'ceil'),:),'LineWidth',3);
                            end
                        else %colors by station
                            scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlistshort{i},...
                                    'MarkerEdgeColor',colorlistshort{i},'LineWidth',3);
                            if j==1 %only do once for each stn, to give plot handles the info they need
                                h(i)=scatter(sc(i,j,score1),sc(i,j,score2),'MarkerFaceColor',colorlistshort{i},...
                                    'MarkerEdgeColor',colorlistshort{i},'LineWidth',3);
                            end
                        end
                    end
                end
                hold on;
            end
        else
            scatter(sc2(i,score1),sc2(i,score2),'MarkerFaceColor',colorlistshort{i},...
                            'MarkerEdgeColor',colorlistshort{i},'LineWidth',3);hold on;
            h(i)=scatter(sc2(i,score1),sc2(i,score2),'MarkerFaceColor',colorlistshort{i},...
                            'MarkerEdgeColor',colorlistshort{i},'LineWidth',3);        
        end
    end
    if groupbyregion==1
        groups={'Inland';'Coastal'};
        legend(h,groups,'Location','Southeast');
    elseif colorsbyhw~=1
        legend(h,symbolsh,'Location','Southeast');
    end
    if symbolsbyhw==1
        for j=1:numreghwsbyT
            tempx=xlim;tempy=ylim;scatter(0.85*tempx(2),(0.95-(0.025*j))*tempy(2),markerlist{j},...
                            'MarkerFaceColor',colors('light brown'),'MarkerEdgeColor',colors('light brown'),'LineWidth',3);
            phr2=sprintf('%s-%s, %d',DOYtoDate(reghwbyTstarts(j+1,1),reghwbyTstarts(j+1,2)),...
                DOYtoDate(reghwbyTstarts(j+1,1)+reghwbyTstarts(j+1,3)-1,reghwbyTstarts(j+1,2)),reghwbyTstarts(j+1,2));
            text(0.87*tempx(2),(0.95-(0.025*j))*tempy(2),phr2);
        end
    end
    xlabel(sprintf('Heatwave Severity Score based on %s',fourvariabs{score1}),'FontSize',14);
    ylabel(sprintf('Heatwave Severity Score based on %s',fourvariabs{score2}),'FontSize',14);
    title(sprintf('%s Severity Scores of %d Regional Heatwaves (1948-2013), for Each of %d Stations%s',...
        relabs,numreghwsbyT,numstns,phr),'FontSize',16,'FontWeight','bold');
end



%Find the dates on which each of the stations had their 10 highest max
%temps (any date on which a station had a top-10 Tmax counts)
%Then, make a correlation matrix comparing the temps across stations on those dates
if findhottestdayseachstn==1
    hotdates=0;
    if stnf==1
        hotdates(1:10,1)=hottest0point5percmaxAtlCityA(1:10,2); %to start off with
        hotdates(1:10,2)=hottest0point5percmaxAtlCityA(1:10,3);
    elseif stnf==3
        hotdates(1:10,1)=hottest0point5percmaxJFK(1:10,2); %to start off with
        hotdates(1:10,2)=hottest0point5percmaxJFK(1:10,3);
    end  
    lastsize=size(hotdates,1);cursize=lastsize;
    for stnc=stnf:stnl
        prefix=pr(stnc);
        tempor=eval(['hottest0point5percmax' char(prefix)]);
        for i=1:10
            testday=tempor(i,3);testyear=tempor(i,4);
            tick=0;
            for ii=1:lastsize
                if testday==hotdates(ii,1) && testyear==hotdates(ii,2) %already have
                else
                    tick=tick+1;
                end
            end
            %disp(tick);
            if tick==lastsize
                hotdates(cursize+1,1)=testday;
                hotdates(cursize+1,2)=testyear;
            end
            tick=0;
            cursize=cursize+1;
        end
        lastsize=size(hotdates,1);
        %disp('New station');disp(lastsize);
    end

    %Remove dates before 1950, as many of the stations only came online then
    for i=1:size(hotdates,1)
        if hotdates(i,2)<1950;hotdates(i,:)=0;end
    end

    %Remove resulting all-zero rows
    hotdates(all(hotdates==0,2),:)=[];

    %Create correlation matrix with stations' obs on this suite of dates
    stnobshotdays=0;ssa=1; %stationstartingat
    %disp(size(hotdates,1));
    for i=1:size(hotdates,1)
        for stnc=ssa:9
            thishotday=hotdates(i,1);thishotyear=hotdates(i,2);
            val=dailymaxvecs{stnc}(thishotday,thishotyear-syear-1);
            stnobshotdays(stnc,i)=val;
        end
        %disp(val);disp(i);
    end
    %disp(stnobshotdays);

    %Transpose compares stations across dates (numcitiesxnumcities); untransposed compares dates
    %across stations (size(hotdates,1)xsize(hotdates,1))
    stnobshotdays(stnobshotdays==-99)=NaN;
    if size(stnobshotdays,1)<size(hotdates,1);stnobshotdays=stnobshotdays';end

    %Find & remove stations that are missing values on more than half of the dates, as
    %they create unreliable correlation values
    citiestoskip=0;
    for col=1:9
        missingc=0;
        for row=1:size(stnobshotdays,1)
            if isnan(stnobshotdays(row,col));missingc=missingc+1;end
        end
        if missingc>=size(stnobshotdays,1)/2
            stnobshotdays(:,col)=0;
            citiestoskip=[citiestoskip col];
        end
        %disp(col);disp(missingc);
    end
    citiestoskip=citiestoskip(2:size(citiestoskip,2));
    %Also remove Toms River (#12) and Little Falls (#15), whose data quality appears suspect on these days
    %stnobshotdays(:,12)=0;citiestoskip=[citiestoskip 12];citiestoskip=sort(citiestoskip);
    %stnobshotdays(:,15)=0;citiestoskip=[citiestoskip 15];citiestoskip=sort(citiestoskip);

    %Remove resulting all-zero cols
    stnobshotdays(:,all(stnobshotdays==0,1))=[];

    outputmatrix=corrcoef(stnobshotdays,'rows','pairwise'); 
        %or 'all' to exclude rows with any NaNs when comparing dates
    figure(figc);clf;figc=figc+1;
    imagesc(outputmatrix);colorbar;
    citiesfull=['   AtlCityA';'BridgeportA';'        JFK';'        LGA';'    NewarkA';...
        '   WhitePlA';'  Central P';'   Brooklyn';'   TrentonA';'TrentonCity';...
        '    AtlCity';'  TomsRiver';'    PhillyA';' TeterboroA';'LittleFalls';'   Paterson';...
        ' JerseyCity';'     IslipA';'  Scarsdale';' DobbsFerry';' PortJervis';'    Mineola'];
    %Exclude cities that had too much missing data by hand
    citiesexcl=['   AtlCityA';'BridgeportA';'        JFK';'        LGA';'    NewarkA';...
        '   WhitePlA';'  Central P';'   Brooklyn';...
        '    AtlCity';'    PhillyA';'     IslipA';' DobbsFerry';' PortJervis';'    Mineola'];         
    Xt=1:size(cities,1);ax=axis;
    t=text(Xt,ax(2)*ones(1,length(Xt))+0.5,cities(1:size(cities,1),:));
    set(t,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
        'Rotation',45,'FontSize',11);
    t=text(ones(1,length(Xt))*(ax(1)-1.2),Xt+0.5,cities(1:size(cities,1),:));
    set(t,'HorizontalAlignment','left','VerticalAlignment','top', ...
        'Rotation',45,'FontSize',11);
    title(sprintf('Stn MaxT Correl Matrix for %d Hot Days',size(stnobshotdays,1)),'FontSize',16,'FontWeight','bold');
end

%Do k-means clustering of cities to quantify the patterns visible by eyeball in the above correlation matrix
%First, further reduce stnobshotdays to just the nearly-complete marquee stations, to minimize the number of NaN's
%Again, this is done by hand
if clusterhotdays==1
    if size(stnobshotdays,2)>=10
        stnobshotdaysreduc=stnobshotdays(:,1:10);stnobshotdaysreduc(:,8)=0;
        stnobshotdaysreduc(:,all(stnobshotdaysreduc==0,1))=[];
        %Remove days (rows) with any missing data, so that the kmeans function is happy
        for row=1:size(stnobshotdaysreduc,1)
            for col=1:9
                if isnan(stnobshotdaysreduc(row,col));stnobshotdaysreduc(row,:)=0;end
            end
        end
        stnobshotdaysreduc(all(stnobshotdaysreduc==0,2),:)=[];
        citiesreduc=['   AtlCityA';'BridgeportA';'        JFK';'        LGA';'    NewarkA';'   WhitePlA';'  Central P';...
            '    AtlCity';'    PhillyA'];
        [idx,C,sumd]=kmeans(stnobshotdaysreduc',4);

        %Alternative: hierarchial clustering based on the correlation matrix itself
        %outputmatrix=outputmatrix-eye(size(outputmatrix));
        %dissimmatrix=1-outputmatrix(find(outputmatrix))';
        dissimmatrix=pdist(outputmatrix);
        cutoff=1;
        Z=linkage(dissimmatrix,'complete');
        groups=cluster(Z,'cutoff',cutoff,'criterion','distance');

        %The main conclusion is that immediately-coastal stations fall into one group, and
        %everyone else into the other
    end
end
                



%Compute the regional hottest days, defined simply by daily Tmax or WBTmax for each station
%Two options (set previously): either the Newark/JFK/LGA average, or
%all valid stations
%Cutoff can vary but is typically at the 99.5th pctile
%For the hottest hours,  see the computedailyfromhourly2 loop in readnycdata
categlabels={'Daily-Max Air Temp.';'Daily-Max Wet-Bulb Temp.'};
if findhottestregdays==1
    dailymaxXregsorted=cell(1,2); %within each cell, columns are data|hour|DOY|year
                                    %cellular columns are bymaxt|bymaxwbt
    for categ=1:2
        dailyvec=dailymaxvecs1D{1};sz=size(dailyvec,1); %all stations have the same-size vectors anyway
        for i=1:sz-3 %for a couple-day cushion when approaching the last day
            validstns=0;validmainstns=0;dailysum=0;dailymainsum=0;
            for stnc=1:numstns
                if categ==1
                    dailyvec=dailymaxvecs1D{stnc};
                elseif categ==2
                    dailyvec=dailymaxwbtvecs1D{stnc};
                end

                if isnan(dailyvec(i,1))==0
                    if dailyvec(i,1)>-50
                        validstns=validstns+1;
                        if stnc==3 || stnc==4 || stnc==5
                            dailymainsum=dailymainsum+dailyvec(i,1);
                            validmainstns=validmainstns+1;
                        end
                        dailysum=dailysum+dailyvec(i,1);
                    end
                end
            end
                
            if validmainstns==3 && validstns>=0.5*numstns %all 3 main stns have data, & at least some others do also
                dailymaxXregsorted{categ}(i,1)=dailymainsum./validmainstns;
            else
                dailymaxXregsorted{categ}(i,1)=-99;
            end

            dailymaxXregsorted{categ}(i,2)=dailyvec(i,3);
            dailymaxXregsorted{categ}(i,3)=dailyvec(i,4);
        end
        dailymaxXregsorted{categ}=sortrows(dailymaxXregsorted{categ},-1);
        
    end
end

%Make date-rank chart comparing ranking by Tmax vs by WBTmax
%(directly analogous to showdaterankchart in readnarrdata, but not
%restricted to 1979-2014)
%Include only dates above the 99.5th prctile of each (there are about 6500
%valid JJA days based on reqts in previous loop, so take top 32 from each ranking)
validdays=6500;
if makedaterankchart==1
    if coloredboxes==1 %Original chart with colored boxes
        rowtomake=1;allreghotdays=0;
        %First, make a list of all the dates that show up in the top 99th pctile in either one
        for categ=1:2
            for i=1:round(validdays/1000*5)
                alreadyhavethisday=0;
                if size(allreghotdays,2)>1
                    for j=1:size(allreghotdays,1)
                        if allreghotdays(j,1)==dailymaxXregsorted{categ}(i,2) && ...
                                allreghotdays(j,2)==dailymaxXregsorted{categ}(i,3)
                            alreadyhavethisday=1;
                        end
                    end
                end
                if alreadyhavethisday==0
                    allreghotdays(rowtomake,1)=dailymaxXregsorted{categ}(i,2);
                    allreghotdays(rowtomake,2)=dailymaxXregsorted{categ}(i,3);
                    rowtomake=rowtomake+1;
                end
            end
        end
        allreghotdays=sortrows(allreghotdays,[2 1]);

        %Now that the list exists, make an auxiliary matrix with shadings for the dates' rankings by Tmax and WBTmax
        rankmatrix=zeros(size(allreghotdays,1),2);
        for i=1:size(allreghotdays,1) %search through listing that was just made
            for categ=1:2
                for row=1:round(validdays/1000*5) 
                    if allreghotdays(i,1)==dailymaxXregsorted{categ}(row,2) &&...
                            allreghotdays(i,2)==dailymaxXregsorted{categ}(row,3)
                        rankmatrix(i,categ)=row;
                    end
                end
                if rankmatrix(i,categ)==0 %no matches found, so need to go find the percentile for this day instead
                    daylookingfor=allreghotdays(i,1);yearlookingfor=allreghotdays(i,2);
                    for j=1:size(dailymaxXregsorted{categ},1)
                        if daylookingfor==dailymaxXregsorted{categ}(j,2) && ...
                                yearlookingfor==dailymaxXregsorted{categ}(j,3)
                            prctile=100-round(j*100/validdays);
                        end
                    end
                end
            end       
        end

        %Display list together with shadings dictated by the rankings
        rankmatrix(rankmatrix==0)=NaN;
        figure(figc);clf;figc=figc+1;
        imagescnan(rankmatrix);

        for i=1:size(allreghotdays,1)
            allregmonthdays{i}=strcat(strtrim(DOYtoDate(allreghotdays(i,1),allreghotdays(i,2))));
            allregyears{i}=num2str(allreghotdays(i,2));
        end
        for i=1:size(allreghotdays,1);text(0.22,i,allregmonthdays{i});text(0.34,i,allregyears{i});end
        colormap(flipud(colormap));colorbar;
        text(1.15,-3,'Hot Days Ranked by Regional-Avg...','FontSize',16,'FontWeight','bold');
        text(0.72,-1,'Maximum Temperature','FontSize',16,'FontWeight','bold');
        text(1.75,-1,'Wet-Bulb Temperature','FontSize',16,'FontWeight','bold');
        text(1.14,65,'Colors represent ranking (with white >=36)','FontSize',16,'FontWeight','bold');
    elseif linessevscore==1 %Colored lines with hw-severity scores on y-axis
        figure(figc);clf;figc=figc+1;
        %Averages for all 11 stations for each heat wave
        %Compute scaling factors
        sf1=100/mean(scorescompbperhwavg(:,1));sf2=100/mean(scorescompbperhwavg(:,2));
        plot(scorescompbperhwavg(:,1)*sf1,'r','LineWidth',5);hold on;
        plot(scorescompbperhwavg(:,2)*sf2,'LineWidth',5);
        xlim([1 numreghwsbyT]);set(gca,'xticklabel',{[]});
        %Include individual stations' rankings as thinner lines
        plot(scorescompbper(3,:,1)*sf1,'r--');plot(scorescompbper(4,:,1)*sf1,'rx-');
        plot(scorescompbper(5,:,1)*sf1,'ro-');
        plot(scorescompbper(3,:,2)*sf2,'b--');plot(scorescompbper(4,:,2)*sf2,'bx-');
        plot(scorescompbper(5,:,2)*sf2,'bo-');
        legend({'Score by T','Score by WBT','JFK','LGA','EWR'},'FontSize',16,'FontName','Arial');
        title('Normalized Regional-Average and Individual-Station Per-Day Heat-Wave Severity Scores for T and for WBT',...
            'FontSize',16,'FontWeight','bold');
        %Make strings of heat-wave dates
        for i=1:numreghwsbyT
            allregmonthdays{i}=strcat(strtrim(DOYtoDate(reghwbyTstarts(i,1),reghwbyTstarts(i,2))),'-',...
                strtrim(DOYtoDate(reghwbyTstarts(i,1)+reghwbyTstarts(i,3)-1,reghwbyTstarts(i,2))));
            allregyears{i}=num2str(reghwbyTstarts(i,2));
            datestringg{i}=strcat(allregmonthdays{i},',   ',allregyears{i});
            h1=text(i-2.5,-88,datestringg{i},'FontSize',8);
            set(h1,'Rotation',45);
        end
    elseif linesprctile==1 %Colored lines with prctile ranks on y-axis
        figure(figc);clf;figc=figc+1;
        %Averages for the Big Three stations for each heat wave
        plot(scorescomptotalhw(:,1),'r','LineWidth',5);hold on; %T prctiles
        plot(scorescomptotalhw(:,2),'LineWidth',5); %WBT prctiles
        xlim([1 numreghwsbyT]);set(gca,'xticklabel',{[]});
        legend({'Score by T','Score by WBT'},'FontSize',16,'FontName','Arial','Location','NorthEastOutside');
        title('Regional-Average Heat-Wave Percentiles of T and WBT, for T-Defined Heat Waves','FontSize',16,'FontWeight','bold');
        %Make strings of heat-wave dates
        for i=1:numreghwsbyT
            allregmonthdays{i}=strcat(strtrim(DOYtoDate(reghwbyTstarts(i,1),reghwbyTstarts(i,2))),'-',...
                strtrim(DOYtoDate(reghwbyTstarts(i,1)+reghwbyTstarts(i,3)-1,reghwbyTstarts(i,2))));
            allregyears{i}=num2str(reghwbyTstarts(i,2));
            datestringg{i}=strcat(allregmonthdays{i},',   ',allregyears{i});
            h1=text(i-2.5,66.5,datestringg{i},'FontSize',8);
            set(h1,'Rotation',45);
        end
    end
end


%K-means-cluster the T-defined heat waves by their hourly obs of T and WBT
%at the Big Three stations
%May do this for full lengths of heat waves, but to start, will do it
%separately for first and last days (with the aim of comparing to results
%shown in synopnarr figures)
if clusterheatwaves==1
    %Make chart where rows are first and last days of heat waves, and
    %columns are hourly T and WBT observations on those days at LGA, EWR, *and* JFK
    Xmatrix=zeros(numreghwsbyT*2,24*6);
    for i=1:2:numreghwsbyT*2-1
        rowfirstday=hwbyTstarthours(round2(i/2,1,'ceil'),1);
        hwlength=reghwbyTstarts(round2(i/2,1,'ceil'),3);
        hrsbwfirstlast=(hwlength-1)*24;
        rowlastday=rowfirstday+hrsbwfirstlast;
        %all the first-day data
        Xmatrix(i,1:24)=hourlytvecs{3}(rowfirstday:rowfirstday+23,5);
        Xmatrix(i,25:48)=hourlytvecs{4}(rowfirstday:rowfirstday+23,5);
        Xmatrix(i,49:72)=hourlytvecs{5}(rowfirstday:rowfirstday+23,5);
        Xmatrix(i,73:96)=hourlytvecs{3}(rowfirstday:rowfirstday+23,14);
        Xmatrix(i,97:120)=hourlytvecs{4}(rowfirstday:rowfirstday+23,14);
        Xmatrix(i,121:144)=hourlytvecs{5}(rowfirstday:rowfirstday+23,14);
        %all the last-day data
        Xmatrix(i+1,1:24)=hourlytvecs{3}(rowlastday:rowlastday+23,5);
        Xmatrix(i+1,25:48)=hourlytvecs{4}(rowlastday:rowlastday+23,5);
        Xmatrix(i+1,49:72)=hourlytvecs{5}(rowlastday:rowlastday+23,5);
        Xmatrix(i+1,73:96)=hourlytvecs{3}(rowlastday:rowlastday+23,14);
        Xmatrix(i+1,97:120)=hourlytvecs{4}(rowlastday:rowlastday+23,14);
        Xmatrix(i+1,121:144)=hourlytvecs{5}(rowlastday:rowlastday+23,14);
    end
    %Do the clustering on 96 days (first & last days of 48 heat waves),
    %finding the best k
    %First days are odd, last days are even
    for numclust=kmin:kmax
        opts=statset('Display','final');
        [idx,c]=kmeans(Xmatrix,numclust,'Replicates',20,'Options',opts);
    end
    figure(figc);figc=figc+1;
    silhouette(Xmatrix,idx);
    title('Silhouette Plot for Heat-Wave-Day K-Means-Clustering of Hourly T and WBT Values',...
        'FontSize',16,'FontWeight','bold','FontName','Arial');
    xlabel('Silhouette Value (possible range -1 to +1)','FontSize',16,'FontWeight','bold');
    ylabel('Cluster Number','FontSize',16);
    %Based on the silhouette plots, 6 clusters seems best
    
    %What percent of each cluster consists of first and last days? Do
    %certain clusters disproportionately represent first or last days?
    clusterdays=zeros(numclust,2);clusterdayspct=zeros(numclust,2);
    for i=1:size(idx,1)
        if rem(i,2)==1 %first day
            clusterdays(idx(i),1)=clusterdays(idx(i),1)+1;
        else %last day
            clusterdays(idx(i),2)=clusterdays(idx(i),2)+1;
        end
    end
    for i=1:numclust
        clusterdayspct(i,1)=100*clusterdays(i,1)/sum(clusterdays(i,1)+clusterdays(i,2));
        clusterdayspct(i,2)=100*clusterdays(i,2)/sum(clusterdays(i,1)+clusterdays(i,2));
    end
    %Three clusters have strong predilections for either first or last
    %days, whereas two are pretty evenly split (and one is spurious)
    
    %Now, calculate and plot average T and WBT traces for each cluster to visualize what
    %'kind' of days these are at the Big Three stations
    avgjfkt=zeros(numclust,24);avglgat=zeros(numclust,24);avgewrt=zeros(numclust,24);
    avgjfkwbt=zeros(numclust,24);avglgawbt=zeros(numclust,24);avgewrwbt=zeros(numclust,24);
    daycbyclust=zeros(numclust,1);
    for clust=1:numclust
        for i=1:size(idx,1)
            if idx(i)==clust
                daycbyclust(clust)=daycbyclust(clust)+1;
                avgjfkt(clust,:)=avgjfkt(clust,:)+Xmatrix(i,1:24);
                avglgat(clust,:)=avglgat(clust,:)+Xmatrix(i,25:48);
                avgewrt(clust,:)=avgewrt(clust,:)+Xmatrix(i,49:72);
                avgjfkwbt(clust,:)=avgjfkwbt(clust,:)+Xmatrix(i,73:96);
                avglgawbt(clust,:)=avglgawbt(clust,:)+Xmatrix(i,97:120);
                avgewrwbt(clust,:)=avgewrwbt(clust,:)+Xmatrix(i,121:144);
            end
        end
        avgjfkt(clust,:)=avgjfkt(clust,:)/daycbyclust(clust);
        avglgat(clust,:)=avglgat(clust,:)/daycbyclust(clust);
        avgewrt(clust,:)=avgewrt(clust,:)/daycbyclust(clust);
        avgjfkwbt(clust,:)=avgjfkwbt(clust,:)/daycbyclust(clust);
        avglgawbt(clust,:)=avglgawbt(clust,:)/daycbyclust(clust);
        avgewrwbt(clust,:)=avgewrwbt(clust,:)/daycbyclust(clust);
        
        figure(figc);figc=figc+1;
        plot(avgjfkt(clust,:));hold on;plot(avglgat(clust,:),'k');plot(avgewrt(clust,:),'r');
        plot(avgjfkwbt(clust,:),'o');plot(avglgawbt(clust,:),'ko');plot(avgewrwbt(clust,:),'ro');
        ylim([14 42]);
        title(sprintf('Average Traces of T and WBT at JFK, LGA, and EWR for Cluster %d, Which Is %0.0f Percent Last Days',...
            clust,clusterdayspct(clust,2)),'FontSize',16,'FontWeight','bold','FontName','Arial');
        xlabel('Hour of the Day','FontSize',16,'FontWeight','bold');
        ylabel('Deg C','FontSize',16,'FontWeight','bold');
    end
end
    
    
%Plot NARR data separately on each cluster's days to compare amongst them (1979-2014 data only at this point)
if narrdataforclusters==1
    total={};
    for clusternumber=1:6
        for variab=1:size(desvar,1)
            desvarname=varlist{desvar(variab)};
            totaltemp=zeros(narrarrsz(1),narrarrsz(2));
            hwdaysfound=0;prevArr={};
            for year=1979:2014
                narrryear=year-1979+1;
                if rem(year,4)==0;suffix=['l'];else suffix=[''];end %consider leap years
                for month=monthiwf:monthiwl
                    ymmissing=0;
                    missingymdaily=eval(['missingymdaily' char(desvarname)]);
                    for row=1:size(missingymdailyair,1)
                        if month==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                    end
                    if ymmissing==1 %Do nothing, just skip the month
                    else
                        fprintf('Current year and month are %d, %d\n',year,month);
                        curmonstart=eval(['m' num2str(month) 's' char(suffix)]);
                        curmonlen=eval(['m' num2str(month+1) 's' char(suffix)])-eval(['m' num2str(month) 's' char(suffix)]);
                        %Search through listing of days belonging to each cluster to see
                        %if this month contains one of them, and if so, get the
                        %NARR array corresponding to it
                        for row=1:size(reghwbyTstarts,1)*2
                            adjrow=round2(row/2,1,'ceil');
                            if rem(row,2)==0
                                thisisalastday=1;offsetfromfirstday=reghwbyTstarts(adjrow,3)-1;
                            else
                                thisisalastday=0;offsetfromfirstday=0;
                            end
                            if reghwbyTstarts(adjrow,2)==year && reghwbyTstarts(adjrow,1)+offsetfromfirstday>=curmonstart...
                                    && reghwbyTstarts(adjrow,1)+offsetfromfirstday<curmonstart+curmonlen...
                                    && idx(row)==clusternumber
                                %disp(row);
                                dayinmonth=reghwbyTstarts(adjrow,1)+offsetfromfirstday-curmonstart+1;disp(dayinmonth);
                                hwdaysfound=hwdaysfound+1;
                                curFile=load(char(strcat(curDir,'/',desvarname,'/',...
                                    num2str(year),'/',desvarname,'_',num2str(year),...
                                    '_0',num2str(month),'_01.mat')));
                                lastpartcur=char(strcat(desvarname,'_',num2str(year),'_0',num2str(month),'_01'));
                                if strcmp(desvarname,'shum') %need to get T as well, to be able to calculate WBT
                                    prevFile=load(char(strcat(curDir,'/','air','/',...
                                    num2str(year),'/','air','_',num2str(year),...
                                    '_0',num2str(month),'_01.mat')));
                                    lastpartprev=char(strcat('air','_',num2str(year),'_0',num2str(month),'_01'));
                                    prevArr=eval(['prevFile.' lastpartprev]);
                                end
                                curArr=eval(['curFile.' lastpartcur]);
                                
                                %Make necessary adjustments to current array
                                %depending on which variable it represents
                                if strcmp(desvarname,'hgt') %500-hPa level for height
                                    arrDOI=curArr{3}(:,:,preslevel,dayinmonth); %DOI is day of interest
                                else %1000-hPa level for everything else
                                    arrDOI=curArr{3}(:,:,1,dayinmonth)-adj;
                                    %Compute WBT from T and RH
                                    if strcmp(desvarname,'shum')
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
                                totaltemp=totaltemp+arrDOI;
                                %disp(max(max(total)));
                            end
                        end
                    end
                end
            end
            total{clusternumber,desvar(variab)}=totaltemp/hwdaysfound;
        end
        %Make plots of these cluster-specific fields just found
        %Standard thing is to plot anomalies since absolute fields all look
        %kind of similar
        
        cantgraph=0;havewinddata=0;
        for i=1:size(desvar,1)
            if isnan(max(max(total{clusternumber,desvar(i)})));cantgraph=1;end
            if desvar(i)==4;havewinddata=1;end
        end
        if cantgraph==0
            if havewinddata==1
                disp('line 1583');
                overlayvar=varargnames{4};underlayvar=varargnames{desvar(1)};
                if anomfromjjaavg==1
                    jjaavguwind=eval(['narravgjja' varlist2{4}]);
                    jjaavgvwind=eval(['narravgjja' varlist2{5}]);
                    vecdata={lats;lons;total{clusternumber,4}-jjaavguwind;...
                        total{clusternumber,5}-jjaavgvwind};
                    jjaavgunderlay=eval(['narravgjja' varlist2{desvar(1)}]);
                    underlaydata={lats;lons;total{clusternumber,desvar(1)}-jjaavgunderlay};
                else
                    vecdata={lats;lons;total{clusternumber,4};total{clusternumber,5}};
                    underlaydata={lats;lons;total{clusternumber,desvar(1)}};
                end
                vararginnew={'variable';varargnames{4};'contour';1;'plotCountries';1;...
                        'vectorData';vecdata;'colormap';'jet';'caxismethod';'regional25';'overlaynow';0;...
                        'datatooverlay';vecdata;'overlayvariable';overlayvar;'datatounderlay';underlaydata;...
                        'underlayvariable';underlayvar};
                plotModelData(underlaydata,mapregionsynop,vararginnew);
                title(sprintf('%s Daily %s and %s for %d Heat-Wave Days in the NYC Area as Defined by %s -- Cluster %d',...
                    char(anomorabs),char(varlistnames{4}),char(varlistnames{desvar(1)}),hwdaysfound,...
                    categlabel,clusternumber),'FontSize',16,'FontWeight','bold','FontName','Arial');
            end
        end
    end
end


%Make chart comparing stations on the hottest reg days
%(e.g. the 11 NRCC-hourly stations only, all 22 daily CLIMOD stations, etc)
%categ=1; %for temp
if makehottestregdaychart==1
    dmrcc=zeros(numd,numstns); %dailymaxregcitychart
    dmrccnotes=zeros(numd,numstns); %matching matrix with numerical coloring instructions
    for i=1:numd
        %Each stn's temps day by day
        for stnc=1:numstns
            day=dailymaxXregsorted{categ}(i,2);
            ryear=dailymaxXregsorted{categ}(i,3)-(syear-1);
            if dailymaxvecs{stnc}(day,ryear)>-50
                dmrcc(i,stnc)=dailymaxvecs{stnc}(day,ryear);
            else
                dmrcc(i,stnc)=NaN;
            end
        end
        %Calculate median & st dev across stns for each day
        a=dmrcc(i,:);a=a(a>-50); %across non-missing stations
        med=median(a);
        stdev=std(a);
        %Make notes for shading if a stn exceeds 1 st dev in either direction
        for stnc=1:numstns
            if dmrcc(i,stnc)<med-stdev
                dmrccnotes(i,stnc)=-1; %with -'s
            elseif dmrcc(i,stnc)>med+stdev
                dmrccnotes(i,stnc)=1; %with +'s
            else
                dmrccnotes(i,stnc)=0; %blank
            end
        end
    end
    %Can't shown 22 stns though, so only show subset
    figure(figc);clf;figc=figc+1;ssa=1;
    imagescnan(dmrcc(:,ssa:11));colorbar;
    Xt=1:11;
    t=text(Xt,numd*ones(1,length(Xt))+1.5,cities(ssa:11,:));
    set(t,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
        'Rotation',45,'FontSize',11);
    title(sprintf('Stn Max Temps on the %d Regional Hottest Days',numd),'FontSize',16,'FontWeight','bold');
    %Add text according to dmrccnotes
    for row=1:24
        for stnc=ssa:11
            if dmrccnotes(row,stnc)==1
                text(stnc-0.25-(ssa-1),row,'+++++++');
            elseif dmrccnotes(row,stnc)==-1
                text(stnc-0.25-(ssa-1),row,'------------');
            end
        end
    end
end
    



%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$
%Climo plots
%Most of these comparison plots do assume stationarity over the timeseries,
%at least so far...

if displayclimohists==1
    %Histogram of summer JFK maxes
    figure(figc);clf;figc=figc+1;
    centers=[15:1:42];
    totaldays=size(cleanmonthlymaxes{4,6},1)+size(cleanmonthlymaxes{4,7},1)+...
        size(cleanmonthlymaxes{4,8},1);
    c=hist([cleanmonthlymaxes{4,6}-Kc;cleanmonthlymaxes{4,7}-Kc;cleanmonthlymaxes{4,8}-Kc],centers);
    c=c./totaldays;
    bar(centers,c);


    %Here is where I will note that the Atl Cities overlap and differ considerably (as can
    %be seen simply from their histograms or medians, or from comparing with the loop below),
    %whereas the Trentons do not overlap and therefore should be treated 'in
    %serial'; also, their medians are similar as can be seen in the following example snippet
    %of code expanded to stations 9 and 10
    a=dailyminvecs1D{9}(:,1);a=a(a>-50);median(a);

    %Histogram of difference b/w JJA daily maxes at airport selected above (sa) and
    %another selected here (selpr)
    %Naturally the comparison is restricted to the overlap of the two timeseries
    selpr=11;
    variab1='max'; %cmmaxwy or cmminwy are the choices at present
    centers=[-12:1:12];

    validc=0;monthrange=6:8;
    for y=1:numyears-1
        mon=monthrange(1);
        %disp(y);
        while mon<monthrange(3)+1
            sd=eval(sprintf('m%us',mon));
            ed=eval(sprintf('m%us',mon+1))-1;
            for d=sd-sd+1:ed-sd+1
                arr=eval(['cm' char(variab1) 'wy']);
                if arr{selpr,y,mon}(d)>-50 && arr{sa,y,mon}(d)>-50
                    validc=validc+1;
                    diffmat(validc)=arr{sa,y,mon}(d)-arr{selpr,y,mon}(d);
                end
            end
            if d==ed-sd+1;mon=mon+1;end
        end
    end

    c=hist(diffmat,centers);
    c=c./totaldays;
    figure(figc);clf;figc=figc+1;
    bar(centers,c);title(sprintf('%s-%s JJA %s',char(pr(sa)),char(pr(selpr)),...
        char(variab1)),'FontSize',16);
    xlim([min(centers) max(centers)]);

    if histfixed==1
        sm=7; %selected month (for histograms)
        %Histograms of differences broken down by quartile of sm JFK max
        if sm==6
            sz=szjn;sz2=szjn2;
        elseif sm==7
            sz=szjl;sz2=szjl2;
        elseif sm==8
            sz=szau;sz2=szau2;
        else
            disp('Please enter a month in JJA');
        end

        c25b=1;c2550=1;c5075=1;c75a=1;
        for i=1:length(diffmat)
            if cleanmonthlymaxes{pr,sm}(i)<=monthlyprctilemaxes{pr}(sm,2) %sm JFK 25th percentile
                diff25b(c25b)=diffmat(i);c25b=c25b+1;
            elseif cleanmonthlymaxes{pr,sm}(i)<=monthlyprctilemaxes{pr}(sm,3) %"" 50th
                diff2550(c2550)=diffmat(i);c2550=c2550+1;
            elseif cleanmonthlymaxes{pr,sm}(i)<=monthlyprctilemaxes{pr}(sm,4)
                diff5075(c5075)=diffmat(i);c5075=c5075+1;
            else
                diff75a(c75a)=diffmat(i);c75a=c75a+1;
            end
        end
        figure(figc);clf;figc=figc+1;
        fourw={'Cold';'Cool';'Warm';'Hot'};
        phrase=sprintf('Difference on %s Days in %s, %s - JFK',fourw{1},mpr{sm},pr1{sa});
        hist(diff25b,centers);title(phrase,'FontSize',16);
        figure(figc);clf;figc=figc+1;
        phrase=sprintf('Difference on %s Days in %s, %s - JFK',fourw{2},mpr{sm},pr1{sa});
        hist(diff2550,centers);title(phrase,'FontSize',16);
        figure(figc);clf;figc=figc+1;
        phrase=sprintf('Difference on %s Days in %s, %s - JFK',fourw{3},mpr{sm},pr1{sa});
        hist(diff5075,centers);title(phrase,'FontSize',16);
        figure(figc);clf;figc=figc+1;
        phrase=sprintf('Difference on %s Days in %s, %s - JFK',fourw{4},mpr{sm},pr1{sa});
        hist(diff75a,centers);title(phrase,'FontSize',16);
    end
end


%Display boxplots of JJA maxes or mins for all stations, to get a quick
%all-encompassing advisor-pleasing visual
if displaystnboxplots==1
    variab2='min';
    arr=eval(['cm' char(variab2) 'wy1D']);
    for stnc=1:numstns
        jjac=1;arrjjaonly=0;
        for i=1:size(arr,1)
            if arr(i,stnc,2)==6 && arr(i,stnc,1)>0 || arr(i,stnc,2)==7 && arr(i,stnc,1)>0 || ...
                    arr(i,stnc,2)==8 && arr(i,stnc,1)>0 %JJA
                %disp('Nice summer day');
                if arr(i,stnc,1)<0
                    disp(arr(i,stnc,1));disp(i);disp(stnc);
                end
                arrjjaonly(jjac,1)=arr(i,stnc,1);
                arrjjaonly(jjac,2)=arr(i,stnc,2);
                arrjjaonly(jjac,3)=arr(i,stnc,3);
                jjac=jjac+1;

            end
        end
        %disp(jjac);
        eval(['x' num2str(stnc) '=arrjjaonly(:,1);']);
    end

    figure(figc);clf;figc=figc+1;
    %As tiled subplots
    for i=1:numstns
        curx=eval(['x' num2str(i)]);
        eval(['g' num2str(i) '=ones(size(curx));']);
        %subplot(6,4,i);boxplot(eval(['x' num2str(i)]),eval(['g' num2str(i)]));
    end
    %As side-by-side boxplots (for 1st/marquee 8 only)
    shortx=[x1;x2;x3;x4;x5;x6;x7;x8];
    shortg=[ones(size(x1,1),1);2*ones(size(x2,1),1);3*ones(size(x3,1),1);4*ones(size(x4,1),1);...
        5*ones(size(x5,1),1);6*ones(size(x6,1),1);7*ones(size(x7,1),1);8*ones(size(x8,1),1);];
    longx=[x1;x2;x3;x4;x5;x6;x7;x8;x9;x10;x11;x12;x13;x14;x15;x16;x17;x18;x19;x20;x21;x22];
    longg=ones(size(x1,1),1);
    for j=2:numcities;longg=[longg;j*ones(size(eval(['x' num2str(j)]),1),1)];end
    boxplot(longx,longg,'notch','on');
    Xt=1:numcities;
    t=text(Xt,min(x2)*ones(1,length(Xt))-7,allcities(1:numcities,:));
    set(t,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
        'Rotation',45,'FontSize',11);
    title(sprintf('Box Plots Comparing Stations for JJA %s',variab2),'FontSize',16,'FontWeight','bold');
    ylabel('Temperature (C)','FontSize',14);


    %Building off of the previous boxplot comparison, make density plot of tail for
    %each city and overlay them to directly compare the relative fatness of tails
    %Tails are the subset of JJA maxes/mins above a selected threshold
    if strcmp(variab2,'max');thresh=35;elseif strcmp(variab2,'min');thresh=25;end

    figure(figc);clf;figc=figc+1;hold on;xlim([thresh thresh+8]);
    [f,xi]=ksdensity(x1);plot(xi,f,'Color',colorlistshort{1},'LineWidth',2);
    [f,xi]=ksdensity(x2);plot(xi,f,'Color',colorlistshort{2},'LineWidth',2);
    [f,xi]=ksdensity(x3);plot(xi,f,'Color',colorlistshort{3},'LineWidth',2);
    [f,xi]=ksdensity(x4);plot(xi,f,'Color',colorlistshort{4},'LineWidth',2);
    [f,xi]=ksdensity(x5);plot(xi,f,'Color',colorlistshort{5},'LineWidth',2);
    [f,xi]=ksdensity(x6);plot(xi,f,'Color',colorlistshort{6},'LineWidth',2);
    [f,xi]=ksdensity(x7);plot(xi,f,'Color',colorlistshort{7},'LineWidth',2);
    [f,xi]=ksdensity(x8);plot(xi,f,'Color',colorlistshort{8},'LineWidth',2);
    legend(marqueecities);
    xlabel('Daily Temperature (C)','FontSize',14);ylabel('Relative Frequency','FontSize',14);
    title(sprintf('Kernel Density Plot for Tails of JJA %s',variab2),'FontSize',16,'FontWeight','bold');
    %Add X's on tails to indicate the maximum observed temperature for each city, 
    %and consequently the point beyond which it's all smoothed extrapolation
    a=double(max(eval(['daily' char(variab2) 'vecs1D{1}(:,1)'])));
    text(a-0.1,-0.0011,'X','Color',colors('red'),'FontSize',16);
    arec=0;arec(1)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{2}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('light red'),'FontSize',16);arec(2)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{3}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('light orange'),'FontSize',16);arec(3)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{4}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('light green'),'FontSize',16);arec(4)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{5}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('green'),'FontSize',16);arec(5)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{6}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('blue'),'FontSize',16);arec(6)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{7}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('light purple'),'FontSize',16);arec(7)=a;
    a=double(max(eval(['daily' char(variab2) 'vecs1D{8}(:,1)'])));
    i=1;offset=0;while i<=size(arec,2);if a==arec(i);offset=0.1;i=99;end;i=i+1;end
    text(a-0.1+offset,-0.0011,'X','Color',colors('pink'),'FontSize',16);arec(8)=a;
    text(thresh+2.6,0.0295,'Xs mark the highest observed value for each station');
end


%Display 5th, 50th, and 95th percentiles of maxes for each station in each month
%Naturally, only works if all stns have been computed
if displaystnpctiles==1
    if firstandlast==1
        numpoints=12;
        years=2015*ones(1,numpoints);
        months=1:numpoints;
        days=15*ones(1,numpoints);
        for k=1:numpoints
            xData(k)=datenum(years(k),months(k),days(k));
        end
        figure(figc);clf;figc=figc+1;
        colorstouse=[colors('red');colors('orange');colors('green');colors('dark green');...
            colors('teal');colors('light blue');colors('pink');colors('purple');colors('gray')];
        h=cell(numstns,3);
        for i=1:numstns
            h{i,1}=plot(xData,monthlyprctilemaxes{i}(:,1),'LineStyle','-','Color',colorstouse(i,:));
            hold on;
            h{i,2}=plot(xData,monthlyprctilemaxes{i}(:,2),...
                'LineWidth',2,'LineStyle','--','Color',colorstouse(i,:));
            h{i,3}=plot(xData,monthlyprctilemaxes{i}(:,3),'LineStyle','-','Color',colorstouse(i,:));
        end
        h=cell2mat(h);

        legend(h(:,1),'atlcity','bridgeport','islip','jfk','laguardia','mcguireafb',...
            'newark','teterboro','whiteplains');
        ax=gca;
        datetick('x','mmm');
        labels=datestr(xData,numpoints);
        set(gca,'XTick',xData);
    end
end
    