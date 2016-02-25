%Reads in and tidies up obs for the NYC region from several different sources

%Current runtime: for reading in hourly NCDC data (1973-2013), about 4 min per station
%                 for reading in daily CLIMOD data (1874-2015), about 2 min total
%                 for reading in hourly NRCC data (1941-2014), about 3 min total

%Instead of running, consider...
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/workspace_readnycdata');



%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?
%Runtime options
createnewvectors=1;         %whether to redefine the main vectors; these are the ones saved in output_readnycdata.mat
readncdcdata=0;             %whether to read NCDC-derived netCDF files which span 1/1/73-12/31/13 at hourly res (SLOW)
readdailyclimoddata=0;      %whether to read CLIMOD-derived CSV files which include temps & precip at daily res
readhourlynrccdata=1;       %whether to read NRCC-derived CSV files which include everything at hourly res
computedailyfromhourly=1;   %whether to compute daily max/min from hourly data (that may already have been read in)
computedailyfromhourlyreg=1;%whether to compute regional-avg daily max/min from hourly data
usingncdcdata=0;            %these three options specify which of the datasets are being used
usingdailyclimoddata=0;     %(in other words, which was read in last)
usinghourlynrccdata=1;
%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?


%Other variables to set
narrnumyears=36; %for NARR records (1979-2014)
obsnumyears=41;startyear=1973; %for NCDC station obs
numyearsd=151; %max possible for daily CLIMOD station obs
numyearsh=75; %max possible for hourly NRCC station obs
mf=3.28; %meter-foot conversion
daystarthour=9; %i.e. an hour after the assumed observation time (for NCDC data)
%These 22 stations are the set for the CLIMOD daily observations
pr1={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';...
    'CentralPark';'Brooklyn'}; %throughout this script, A stands for Airport
pr2={'TrentonA';'TrentonCity';'AtlCity';'TomsRiver';'PhiladelphiaA'}; %#9-13
pr3={'TeterboroA';'LittleFalls';'Paterson';'JerseyCity'}; %#14-17
pr4={'IslipA';'Scarsdale';'DobbsFerry';'PortJervis';'Mineola'}; %18-22
pr=[pr1;pr2;pr3;pr4]; %station sets to use in this run
a=size(pr);numstnsd=a(1);
prlabels={'Atlantic City A';'Bridgeport A';'JFK A';'LaGuardia A';'Newark A';'White Plains A';...
    'Central Park';'Brooklyn';'Trenton A';'Trenton';'Atlantic City';'Toms River';'Philadelphia A';...
    'Teterboro A';'Little Falls';'Paterson';'Jersey City';'Islip A';'Scarsdale';'Dobbs Ferry';...
    'Port Jervis';'Mineola'};
marqueecities=['Atl City A';'Bridgeport';'     JFK A';'     LGA A';'  Newark A';...
    '  White Pl';' Central P';'  Brooklyn'];
allcities=['    Atl City A';'    Bridgeport';'         JFK A';'   LaGuardia A';'      Newark A';...
    '    White Pl A';'  Central Park';'      Brooklyn';'     Trenton A';'  Trenton City';' Atlantic City';...
    '    Toms River';'Philadelphia A';'   Teterboro A';'  Little Falls';'      Paterson';'   Jersey City';...
    '       Islip A';'     Scarsdale';'   Dobbs Ferry';'   Port Jervis';'       Mineola'];
%The following 11 stations are the subset of those above for which hourly obs are available
prh={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';'CentralPark';...
    'TrentonA';'PhiladelphiaA';'TeterboroA';'IslipA'};
ah=size(prh);numstnsh=ah(1);
prhcodes={'acy';'bdr';'jfk';'lga';'ewr';'hpn';'nyc';'ttn';'phl';'teb';'isp'};
prhlabels={'Atlantic City A';'Bridgeport A';'JFK A';'LaGuardia A';'Newark A';...
    'White Plains A';'Central Park';'Trenton A';'Philadelphia A';'Teterboro A';'Islip A'};
allcitiesh=['    Atl City A';'    Bridgeport';'         JFK A';'   LaGuardia A';'      Newark A';...
    '    White Pl A';'  Central Park';'     Trenton A';'Philadelphia A';'   Teterboro A';'       Islip A'];

%First and last full month & year of record for daily temp at each of the 22 stations (missing values within are okay)
stnrecordsdates=[7 1958 7 2015;7 1948 7 2015;8 1948 7 2015;7 1940 7 2015;...
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

colorlist={colors('red');colors('light red');colors('light orange');...
    colors('light green');colors('green');colors('blue');colors('light purple');colors('pink')};

exist figc;if ans==1;figc=figc+1;else figc=1;end
%Leap-year month starts
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
mpr={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'};
sa=1; %selected airport to compute histograms of differences; number from prefixes list
saincluded=1; %whether sa is included in current run
first=0;firstandlast=0; %whether all stns are currently included

if usingncdcdata==1
elseif usingdailyclimoddata==1
    numstns=numstnsd;
elseif usinghourlynrccdata==1
    numstns=numstnsh;
end


%Internal and external functions, as well as mathematical constants
subindex=@(A,r,c) A(r,c);
vararginnew={'contour';1;'mystep';2;'plotCountries';1;'colormap';'jet'}; %basic arguments for plotModelData
Kc=0; %compute in C, no need for K




%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-
%Start of script

%Define new arrays
if createnewvectors==1
    dailymaxvecs=cell(numstns,1); %for air temperature
    dailyminvecs=cell(numstns,1);
    dailyavgvecs=cell(numstns,1);
    dailymaxvecs1D=cell(numstns,1);
    dailyminvecs1D=cell(numstns,1);
    dailyavgvecs1D=cell(numstns,1);

    dailymaxwbtvecs=cell(numstns,1); %analogue for WBT
    dailymaxhivecs=cell(numstns,1); %analogue for heat index
    dailymaxwbtvecs1D=cell(numstns,1);
    dailymaxhivecs1D=cell(numstns,1);

    dhavgvecs=cell(numstns,1); %avg of hours for each day (to better compare with NARR)
    dhavgvecs1D=cell(numstns,1);

    maxhourlyjumpvec=zeros(numstns,1);
    numdaysskippedvec=zeros(numstns,1);daysskipped=0;
    numhoursskippedvec=zeros(numstns,1);
    totalhoursineachday=cell(numstns,1);
    dailysumseachday=cell(numstns,1);
end

%Data source option 1: NCDC daily data, 1973-2014
if readncdcdata==1
cd /Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Station_Data/NCDC_Hourly_Obs;
    for stnc=4:4
        prefix=pr(stnc);
        disp(prefix);  
        curfile=sprintf('%s.nc',char(prefix));
        if stnc==sa
            saincluded=1;
        end
        if stnc==1
            first=1;
        elseif first==1
            if stnc==numstns
                firstandlast=1;
            end
        end

        temp=ncread(curfile,'time');
        eval(['time' char(prefix) '=temp;']);

        temp=ncread(curfile,'temperatures');
        temp(temp<=-2*10^30)=-100; %still distinct but without the ridiculous values
        temp(temp<=-1*10^30)=-50;
        eval(['temps2m' char(prefix) '=temp;']);

        temp=ncread(curfile,'dewpoints');
        temp(temp<=-2*10^30)=-100;temp(temp<=-1*10^30)=-50;
        eval(['dewpt2m' char(prefix) '=temp;']);

        temp=ncread(curfile,'winddirs');
        temp(temp<=-888)=-10;
        eval(['winddir' char(prefix) '=temp;']);

        temp=ncread(curfile,'windspeeds');
        temp(temp<=-2*10^30)=-100;temp(temp<=-1*10^30)=-50;
        eval(['windspeed' char(prefix) '=temp;']);

        temp=ncread(curfile,'total_cloud_cover');
        temp(temp<=-888)=-10;
        eval(['tcc' char(prefix) '=temp;']);

        temp=ncread(curfile,'slp');
        temp(temp<=-2*10^30)=850;temp(temp<=-1*10^30)=900;
        eval(['slp' char(prefix) '=temp;']);

        eval(['dailymaxvec' char(prefix) '=zeros(366,obsnumyears);']);
        eval(['dailyminvec' char(prefix) '=zeros(366,obsnumyears);']);
        eval(['dailymaxvec1D' char(prefix) '=zeros(366*obsnumyears,3);']);
        eval(['dailyminvec1D' char(prefix) '=zeros(366*obsnumyears,3);']);
        hourofday=0;dateinyear=1;obsryear=1;totalnumdays=1;
        totalnumdaysasofnextdec31=365;totalnumdaysasoflastdec31=0;
        eval(['dailymax' char(prefix) '=-99;']);
        eval(['dailymin' char(prefix) '=99;']);

        maxhourlyjump=1;curdailysum=0;daysskipped=0;
        discontcount=0;totalnumhours=0;totalhoursincurday=1;

        for i=2:size(eval(['temps2m' char(prefix)]),1) %2 AM on 1/1/73
        %for i=1:1200
            curtime=subindex(eval(['time' char(prefix)]),i,1);
            prevtime=subindex(eval(['time' char(prefix)]),i-1,1);
            hourlyjump=curtime-prevtime;

            oldhourofday=hourofday;
            hourofday=hourofday+hourlyjump;
            totalnumhours=totalnumhours+hourlyjump;
            if hourlyjump~=1
                %disp('Found a discontinuity');
                %disp(i);disp(hourlyjump);
                discontcount=discontcount+hourlyjump-1;
                totalhoursincurday=totalhoursincurday+hourlyjump;
                %disp(hourofday);disp(oldhourofday);
                if hourlyjump>maxhourlyjump
                    maxhourlyjump=hourlyjump;
                end
                if hourlyjump>=24
                    reductioncount=1;
                    hourofdayreduced=hourofday;
                    while hourofdayreduced>=25
                        hourofdayreduced=hourofdayreduced-reductioncount*24;
                        reductioncount=reductioncount+1;
                    end
                    daysskipped=daysskipped+reductioncount-1;
                end

            end

            hourlytemp=subindex(eval(['temps2m' char(prefix)]),i,1)+Kc;
            if hourlytemp>eval(['dailymax' char(prefix)])
                eval(['dailymax' char(prefix) '=hourlytemp;']);
            end
            if hourlytemp<eval(['dailymin' char(prefix)])
                eval(['dailymin' char(prefix) '=hourlytemp;']);
            end

            curdailysum=curdailysum+hourlytemp;

            if hourofday>=25;hourofday=hourofday-24;end
            %disp(hourofday);
            %if rem(hourofday,24)==daystarthour-1 %another day is over
            if hourlyjump<=24
                if rem(curtime,24)==0
                    %disp(hourofday);disp(dateinyear);
                    dailymaxvecs{stnc}(dateinyear,obsryear)=...
                        eval(['dailymax' char(prefix)]);
                    dailyminvecs{stnc}(dateinyear,obsryear)=...
                        eval(['dailymin' char(prefix)]);
                    dailymaxvecs1D{stnc}(totalnumdays,1)=eval(['dailymax' char(prefix)]);
                    dailyminvecs1D{stnc}(totalnumdays,1)=eval(['dailymin' char(prefix)]);
                    dailymaxvecs1D{stnc}(totalnumdays,2)=dateinyear;
                    dailyminvecs1D{stnc}(totalnumdays,2)=dateinyear;
                    dailymaxvecs1D{stnc}(totalnumdays,3)=obsryear+startyear-1;
                    dailyminvecs1D{stnc}(totalnumdays,3)=obsryear+startyear-1;
                    curdailysum=double(curdailysum);totalhoursincurday=double(totalhoursincurday);
                    dhavgvecs{stnc}(dateinyear,obsryear)=curdailysum/totalhoursincurday;
                    dhavgvecs1D{stnc}(totalnumdays,1)=curdailysum/totalhoursincurday;
                    dhavgvecs1D{stnc}(totalnumdays,2)=dateinyear;
                    dhavgvecs1D{stnc}(totalnumdays,3)=obsryear+startyear-1;
                    %disp(273.15+curdailysum/totalhoursincurday);
                    %disp('above is hourly avg; below are daily max & min');
                    %disp(eval(['dailymax' char(prefix)])+273.15);
                    %disp(eval(['dailymin' char(prefix)])+273.15);

                    dateinyear=dateinyear+1;hourofday=daystarthour-1;
                    %disp(dateinyear);
                    eval(['dailymax' char(prefix) '=-99;']);
                    eval(['dailymin' char(prefix) '=99;']);
                    totalnumdays=totalnumdays+1;
                    totalhoursineachday{stnc}(obsryear,dateinyear)=totalhoursincurday;
                    dailysumseachday{stnc}(obsryear,dateinyear)=curdailysum;
                    %disp(totalhoursincurday);
                    totalhoursincurday=0;curdailysum=0;
                    %disp(totalnumdays);    
                end
                %disp(totalhoursincurday);
                totalhoursincurday=totalhoursincurday+1;
            else
                for j=1:daysskipped
                    dailymaxvecs{stnc}(dateinyear,obsryear)=-50;
                    dailyminvecs{stnc}(dateinyear,obsryear)=-50;
                    dailymaxvecs1D{stnc}(totalnumdays,1)=-50;
                    dailyminvecs1D{stnc}(totalnumdays,1)=-50;
                    dailymaxvecs1D{stnc}(totalnumdays,2)=dateinyear;
                    dailyminvecs1D{stnc}(totalnumdays,2)=dateinyear;
                    dailymaxvecs1D{stnc}(totalnumdays,3)=obsryear+startyear-1;
                    dailyminvecs1D{stnc}(totalnumdays,3)=obsryear+startyear-1;
                    dateinyear=dateinyear+1;totalnumdays=totalnumdays+1;
                    curdailysum=0;
                    %disp('A day was skipped');
                end
            end
            %elseif rem(hourofday,24)==0
                %totalnumdays=totalnumdays+1;
                %disp(totalnumdays);
                %hourofday=0;
            %end
            if rem(obsryear,4)==0 && obsryear~=28 %i.e. a leap year
                lengthofyear=366;lengthofnextyear=365;
            elseif rem(obsryear+1,4)==0 && obsryear+1~=28 %year before a leap year
                lengthofyear=365;lengthofnextyear=366;
            else
                lengthofyear=365;lengthofnextyear=365;
            end
            if curtime>=24*(totalnumdaysasofnextdec31)
                %lengthofyearvec(relativeyear)=lengthofyear;
                iisinjan=1;obsryear=obsryear+1;
                totalnumdaysasoflastdec31=totalnumdaysasofnextdec31;
                totalnumdaysasofnextdec31=totalnumdaysasofnextdec31+lengthofnextyear;
                %disp('Year over');disp(curtime);
                %disp(i);disp(dateinyear);
                dateinyear=1;
                %disp(lengthofyear);
            end

        end
        disp(sprintf('Total hours of discontinuities: %n',discontcount));
        disp(discontcount);
        maxhourlyjumpvec(stnc)=maxhourlyjump;
        numdaysskippedvec(stnc)=daysskipped;
        numhoursskippedvec(stnc)=discontcount;
    end
end

%Data source option 2: CLIMOD daily data, 1874-2014
totalstnc=0;
if readdailyclimoddata==1
    cd /Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Station_Data/Climod_Daily_Obs;
    for spreadsheet=1:4
        if spreadsheet==1
            sprdata=csvread('StnDataMarquee.csv','r');numstnshere=8;
        elseif spreadsheet==2
            sprdata=csvread('StnDataSouth&CentralNJ.csv','r');numstnshere=5;
        elseif spreadsheet==3
            sprdata=csvread('StnDataNorthNJ.csv','r');numstnshere=4;
        elseif spreadsheet==4
            sprdata=csvread('StnDataSuburbanNY&CT.csv','r');numstnshere=5;
        end
        for stnc=1:numstnshere    
            dateinyear=1;obsryear=1;totalnumdays=1;totalstnc=totalstnc+1;
            for i=1:size(sprdata,1)
                actualyear=sprdata(i,1);obsryear=actualyear-1864;
                %disp(dateinyear);disp(actualyear);
                dailymaxvecs{totalstnc}(dateinyear,obsryear)=(5/9)*(sprdata(i,6*stnc-2)-32);
                dailyminvecs{totalstnc}(dateinyear,obsryear)=(5/9)*(sprdata(i,6*stnc-1)-32);
                if dailymaxvecs{totalstnc}(dateinyear,obsryear)>-50 &&...
                        dailyminvecs{totalstnc}(dateinyear,obsryear)>-50
                    dailyavgvecs{totalstnc}(dateinyear,obsryear)=...
                    (dailymaxvecs{totalstnc}(dateinyear,obsryear)+dailyminvecs{totalstnc}(dateinyear,obsryear))/2;
                else
                    dailyavgvecs{totalstnc}(dateinyear,obsryear)=-99;
                end
                dailymaxvecs1D{totalstnc}(totalnumdays,1)=(5/9)*(sprdata(i,6*stnc-2)-32);
                dailymaxvecs1D{totalstnc}(totalnumdays,2)=dateinyear;
                dailymaxvecs1D{totalstnc}(totalnumdays,3)=actualyear;
                dailyminvecs1D{totalstnc}(totalnumdays,1)=(5/9)*(sprdata(i,6*stnc-1)-32);
                dailyminvecs1D{totalstnc}(totalnumdays,2)=dateinyear;
                dailyminvecs1D{totalstnc}(totalnumdays,3)=actualyear;
                dailyavgvecs1D{totalstnc}(totalnumdays,1)=...
                    (dailymaxvecs{totalstnc}(dateinyear,obsryear)+dailyminvecs{totalstnc}(dateinyear,obsryear))/2;
                dailyavgvecs1D{totalstnc}(totalnumdays,2)=dateinyear;
                dailyavgvecs1D{totalstnc}(totalnumdays,3)=actualyear;

                %Make sure -99 values stay that way
                if dailymaxvecs{totalstnc}(dateinyear,obsryear)<-72
                    dailymaxvecs{totalstnc}(dateinyear,obsryear)=-99;
                    dailymaxvecs1D{totalstnc}(totalnumdays,1)=-99;
                end
                if dailyminvecs{totalstnc}(dateinyear,obsryear)<-72
                    dailyminvecs{totalstnc}(dateinyear,obsryear)=-99;
                    dailyminvecs1D{totalstnc}(totalnumdays,1)=-99;
                end
                if dailyavgvecs{totalstnc}(dateinyear,obsryear)<-72
                    dailyavgvecs{totalstnc}(dateinyear,obsryear)=-99;
                    dailyavgvecs1D{totalstnc}(totalnumdays,1)=-99;
                end

                dateinyear=dateinyear+1;totalnumdays=totalnumdays+1;
                if i~=size(sprdata,1);yearasoftomorrow=sprdata(i+1,1);end              
                if actualyear~=yearasoftomorrow %i.e. today is Dec 31
                    obsryear=obsryear+1;
                    dateinyear=1;
                end
            end
        end
    end
end

%Data source option 3: NRCC hourly data, 1941-2014
%Order of stations is given by prhcodes
if readhourlynrccdata==1
    disp(clock);
    cd /Users/colin/Documents/General_Academics/Research/Station_Data/NRCC_Hourly_Obs;
    for stnc=1:size(prhcodes,1)
        curprefix=prhcodes{stnc};
        da=csvread(strcat(curprefix,'reduc.csv'));
        eval(['sprdata' num2str(stnc) '=da;']);
    end

    hourlytvecs=cell(size(prhcodes,1),1);
    %Philadelphia (#9) has the longest record (1941-2014); so, use its
    %dates to fill in everything before the start date for each of the other time series with -99's
    %Then, each station's data is put together for its unique period of record
    %Columns of hourlytvecs are
    %hour|day|month|year|T|dewpt|wdir|wspd|wgust|pres|skycov|RH|heatindex|WBT, with units of
    %                    C   C    deg  kts  kts   hPa eighths %      C     C
    %RH calculation is from http://www.vaisala.com/Vaisala%20Documents/Application%20notes...
    %/Humidity_Conversion_Formulas_B210973EN-F.pdf
    %Heat-index formula is from http://www.wpc.ncep.noaa.gov/html/heatindex_equation.shtml
    %WBT formula is from Stull 2011, DOI: 10.1175/JAMC-D-11-0143.1
    for stnc=1:size(prhcodes,1)
    %for stnc=7:7
        cursprdata=eval(['sprdata' num2str(stnc)]);currow=1;donenow=0;
        shortersmon=cursprdata(1,1);shortersday=cursprdata(1,2);shortersyear=cursprdata(1,3);
        phlsmon=sprdata9(1,1);phlsday=sprdata9(1,2);phlsyear=sprdata9(1,3);
        j=DaysApart(phlsmon,phlsday,phlsyear,shortersmon,shortersday,shortersyear);
        j=j*24; %number of hours apart

        %First task is to fill in everything before the start of the shorter time series with -99's
        hourlytvecs{stnc}(1:j,1)=sprdata9(1:j,4);hourlytvecs{stnc}(1:j,2)=sprdata9(1:j,2);
        hourlytvecs{stnc}(1:j,3)=sprdata9(1:j,1);hourlytvecs{stnc}(1:j,4)=sprdata9(1:j,3);
        hourlytvecs{stnc}(1:j,5)=-99;hourlytvecs{stnc}(1:j,6)=-99;hourlytvecs{stnc}(1:j,7)=-99;
        hourlytvecs{stnc}(1:j,8)=-99;hourlytvecs{stnc}(1:j,9)=-99;hourlytvecs{stnc}(1:j,10)=-99;
        hourlytvecs{stnc}(1:j,11)=-99;hourlytvecs{stnc}(1:j,12)=-99;hourlytvecs{stnc}(1:j,13)=-99;
        hourlytvecs{stnc}(1:j,14)=-99;

        %Fill in all desired data, deriving indices and making necessary unit
        %conversions (particularly laborious for RH)
        currow=j+1;disp('starting to fill in data');
        hourlytvecs{stnc}(currow:size(sprdata9,1),1)=cursprdata(1:size(cursprdata,1),4);
        hourlytvecs{stnc}(currow:size(sprdata9,1),2)=cursprdata(1:size(cursprdata,1),2);
        hourlytvecs{stnc}(currow:size(sprdata9,1),3)=cursprdata(1:size(cursprdata,1),1);
        hourlytvecs{stnc}(currow:size(sprdata9,1),4)=cursprdata(1:size(cursprdata,1),3);
        hourlytvecs{stnc}(currow:size(sprdata9,1),5)=(cursprdata(1:size(cursprdata,1),5)-32)*5/9; %air temp
        hourlytvecs{stnc}(currow:size(sprdata9,1),6)=(cursprdata(1:size(cursprdata,1),6)-32)*5/9; %dewpt temp
        hourlytvecs{stnc}(currow:size(sprdata9,1),7)=cursprdata(1:size(cursprdata,1),7); %wind dir
        hourlytvecs{stnc}(currow:size(sprdata9,1),8)=cursprdata(1:size(cursprdata,1),8)*0.86898; %wind speed
        hourlytvecs{stnc}(currow:size(sprdata9,1),9)=cursprdata(1:size(cursprdata,1),9)*0.86898; %wind gust
        hourlytvecs{stnc}(currow:size(sprdata9,1),10)=cursprdata(1:size(cursprdata,1),10)*33.864; %pressure
        hourlytvecs{stnc}(currow:size(sprdata9,1),11)=cursprdata(1:size(cursprdata,1),11)*8; %sky coverage
        airtemp=(cursprdata(1:size(cursprdata,1),5)-32)*5/9;airtempF=cursprdata(1:size(cursprdata,1),5);
        eta=1-((airtemp+273.15)./647.1); %dimensionless ratio
        satvpairtemp=220640*exp((647.1./(airtemp+273.15)).*(-7.86*eta+1.844*eta.^1.5-11.787*eta.^3+...
            22.681*eta.^3.5-15.962*eta.^4+1.801*eta.^7.5)); %in hPa
        dewpttemp=(cursprdata(1:size(cursprdata,1),6)-32)*5/9;
        eta=1-((dewpttemp+273.15)./647.1);
        satvpdewpttemp=220640*exp((647.1./(dewpttemp+273.15)).*(-7.86*eta+1.844*eta.^1.5-11.787*eta.^3+...
            22.681*eta.^3.5-15.962*eta.^4+1.801*eta.^7.5));
        hourlytvecs{stnc}(currow:size(sprdata9,1),12)=100*satvpdewpttemp./satvpairtemp; %finally, the RH
        rh=100*satvpdewpttemp./satvpairtemp;
        airtempF(airtempF<80)=-99; %heat index is only valid for T>=80 F, so anything below is masked to -99
        hourlytvecs{stnc}(currow:size(sprdata9,1),13)=-42.379+2.049*airtempF+...
            10.1433*rh-0.22476*airtempF.*rh-0.00684*airtempF.*airtempF-0.0548*rh.*rh+...
            0.00123*airtempF.*airtempF.*rh+0.000853.*airtempF.*rh.*rh-0.000002*airtempF.*airtempF.*rh.*rh;
        heatindex=(hourlytvecs{stnc}(currow:size(sprdata9,1),13)-32)*5/9;
        heatindex(airtempF==-99)=-99; %nonsensical heat-index values from -99 temps become -99 themselves
        hourlytvecs{stnc}(currow:size(sprdata9,1),13)=heatindex;
        pres=cursprdata(1:size(cursprdata,1),10)*33.864;
        wbt=airtemp.*atan(0.151977.*(rh+8.313659).^0.5)+atan(airtemp+rh)-atan(rh-1.676331)+...
            0.00391838.*(rh.^1.5).*atan(0.0231.*rh)-4.686035;
        wbt(wbt>50)=-99; %unphysical values that come from missing data, etc.
        hourlytvecs{stnc}(currow:size(sprdata9,1),14)=wbt; %WBT
    end
    disp(clock);           
end

if computedailyfromhourly==1
    %Computes daily max/min of T and of indices from hourly vectors defined just above
    maxtimes=cell(size(prhcodes,1),1);mintimes=cell(size(prhcodes,1),1);
    wbtmaxtimes=cell(size(prhcodes,1),1);himaxtimes=cell(size(prhcodes,1),1);
    for stnc=1:size(prhcodes,1)
    %for stnc=7:7
        curday=1;curyear=1941; %all now begin 1/1/1941
        for hour0=0:24:648672 %first hour of the always-24-hour day; 648672 is hour corresponding to 11 PM 12/31/2014
            todaystemps=hourlytvecs{stnc}(hour0+1:hour0+24,5);
            todaystemps(todaystemps<-50)=-99;todaystempscl=todaystemps;
            todayswbt=hourlytvecs{stnc}(hour0+1:hour0+24,14);
            todayswbt(todayswbt<-50)=-99;todayswbtcl=todayswbt;
            todayshi=hourlytvecs{stnc}(hour0+1:hour0+24,13);
            todayshi(todayshi<-50)=-99;todayshicl=todayshi;
            if size(todaystempscl,1)<20 %fewer than 20 valid hours on this day
                dailymaxvecs{stnc}(curday,curyear-1940)=-99;
                dailyminvecs{stnc}(curday,curyear-1940)=-99;
                dailymaxwbtvecs{stnc}(curday,curyear-1940)=-99;
                dailymaxhivecs{stnc}(curday,curyear-1940)=-99;
                maxtimes{stnc}(curday,curyear-1940)=-99;
                mintimes{stnc}(curday,curyear-1940)=-99;
                wbtmaxtimes{stnc}(curday,curyear-1940)=-99;himaxtimes{stnc}(curday,curyear-1940)=-99;
            else
                dailymaxvecs{stnc}(curday,curyear-1940)=max(todaystempscl);[a0,b0]=max(todaystempscl);
                dailyminvecs{stnc}(curday,curyear-1940)=min(todaystempscl);[c0,d0]=min(todaystempscl);
                dailymaxwbtvecs{stnc}(curday,curyear-1940)=max(todayswbtcl);[a1,b1]=max(todayswbtcl);
                if a0>=26.7 %at least one valid heat index on this day
                    dailymaxhivecs{stnc}(curday,curyear-1940)=max(todayshicl);[a2,b2]=max(todayshicl);
                    himaxtimes{stnc}(curday,curyear-1940)=b2-1;
                else
                    dailymaxhivecs{stnc}(curday,curyear-1940)=-99;a2=-99;b2=-99;
                    himaxtimes{stnc}(curday,curyear-1940)=-99;
                end
                maxtimes{stnc}(curday,curyear-1940)=b0-1; %because e.g. 1 AM is hour 2
                wbtmaxtimes{stnc}(curday,curyear-1940)=b1-1;
                mintimes{stnc}(curday,curyear-1940)=d0-1;
            end
            curday=curday+1;
            if rem(curyear,4)==0;yearlen=366;else yearlen=365;end
            if curday==yearlen+1;curyear=curyear+1;curday=1;end
        end
        %Quick way to make '1D' vectors
        categlabels={'Air Temp.';'WBT';'Heat Index'};
        for categ=1:3
            if categ==1
                maxvec=dailymaxvecs;minvec=dailyminvecs;
            elseif categ==2
                maxvec=dailymaxwbtvecs;maxtimes=wbtmaxtimes;
            elseif categ==3
                maxvec=dailymaxhivecs;maxtimes=himaxtimes;
            end
            for year=1:75
                if rem(year,4)==0;yearlen=366;else yearlen=365;end
                if year==1
                    max1Dcol1{stnc}=[maxvec{stnc}(1:yearlen,year)];
                    min1Dcol1{stnc}=[minvec{stnc}(1:yearlen,year)];
                    max1Dcol2{stnc}=maxtimes{stnc}(1:yearlen,year);
                    min1Dcol2{stnc}=mintimes{stnc}(1:yearlen,year);
                    max1Dcol3{stnc}=(1:yearlen)';min1Dcol3{stnc}=(1:yearlen)';
                    max1Dcol4{stnc}=(year+1940)*ones(yearlen,1);
                    min1Dcol4{stnc}=(year+1940)*ones(yearlen,1);
                else
                    max1Dcol1{stnc}=[max1Dcol1{stnc};maxvec{stnc}(1:yearlen,year)];
                    min1Dcol1{stnc}=[min1Dcol1{stnc};minvec{stnc}(1:yearlen,year)];
                    max1Dcol2{stnc}=[max1Dcol2{stnc};maxtimes{stnc}(1:yearlen,year)];
                    min1Dcol2{stnc}=[min1Dcol2{stnc};mintimes{stnc}(1:yearlen,year)];
                    max1Dcol3{stnc}=[max1Dcol3{stnc};(1:yearlen)'];
                    min1Dcol3{stnc}=[min1Dcol3{stnc};(1:yearlen)'];
                    max1Dcol4{stnc}=[max1Dcol4{stnc};(year+1940)*ones(yearlen,1);];
                    min1Dcol4{stnc}=[min1Dcol4{stnc};(year+1940)*ones(yearlen,1);];
                end
            end
            if categ==1
                dailymaxvecs1D{stnc}=[max1Dcol1{stnc},max1Dcol2{stnc},max1Dcol3{stnc},max1Dcol4{stnc}];
                dailyminvecs1D{stnc}=[min1Dcol1{stnc},min1Dcol2{stnc},min1Dcol3{stnc},min1Dcol4{stnc}];
            elseif categ==2
                dailymaxwbtvecs1D{stnc}=[max1Dcol1{stnc},max1Dcol2{stnc},max1Dcol3{stnc},max1Dcol4{stnc}];
            elseif categ==3
                dailymaxhivecs1D{stnc}=[max1Dcol1{stnc},max1Dcol2{stnc},max1Dcol3{stnc},max1Dcol4{stnc}];
            end
        end
    end
end

%Computes regional daily maxes from hourly data, so that the daily
%regional max is the **hour** at which the desired index is maximal across the entire region
if computedailyfromhourlyreg==1
    dailymaxhrreg=cell(3,1);
    for categ=1:3 %max T, WBT, and heat index in that order
        if categ==1;col=5;elseif categ==2;col=14;elseif categ==3;col=13;end
        for day=1:size(hourlytvecs{1},1)/24 %all hourlytvecs cells are the same size
            hour0=(day-1)*24+1;
            hourlyregt=zeros(24,1);
            for hour=1:24
                validstns=0;
                for stnc=1:size(prhcodes,1)
                    if hourlytvecs{stnc}(hour0+(hour-1),col)>-50 %valid
                        hourlyregt(hour)=hourlyregt(hour)+hourlytvecs{stnc}(hour0+(hour-1),col);
                        validstns=validstns+1;
                    end
                end
                if validstns>=0.5*numstns
                    hourlyregt(hour)=hourlyregt(hour)/validstns;
                else
                    hourlyregt(hour)=-99;
                end
            end
            [a,b]=max(hourlyregt);
            dailymaxhrreg{categ}(day,1)=a;
            dailymaxhrreg{categ}(day,2)=b-1; %because e.g. 1 AM is listed as hour 2
            dailymaxhrreg{categ}(day,3)=hourlytvecs{1}(hour0,2); %day
            dailymaxhrreg{categ}(day,4)=hourlytvecs{1}(hour0,3); %month
            dailymaxhrreg{categ}(day,5)=hourlytvecs{1}(hour0,4); %year
        end
        dailymaxhrXregsorted{categ}=sortrows(dailymaxhrreg{categ},-1);
    end
end









        
    