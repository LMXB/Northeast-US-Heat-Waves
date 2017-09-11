%Reads in and tidies up obs for the NYC region from several different sources

%Current runtime: for reading in hourly NCDC data (1973-2013), about 4 min per station
%                 for reading in daily CLIMOD data (1874-2015), about 2 min total
%                 for reading in hourly NRCC data (1941-2014), about 3 min total

%Instead of running, consider...
%load('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/readnycdata');



%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?
%Runtime options
createnewvectors=1;         %whether to redefine the main vectors; these are the ones saved in output_readnycdata.mat
readhourlynrccdata=0;       %whether to read NRCC-derived CSV files which include everything at hourly res
interpolatehourlynrccdata=1;%whether to interpolate to fill gaps and from 3-hourly to 1-hourly (25 min)
computedailyfromhourly=0;   %whether to compute daily max/min from hourly data (that may already have been read in)
computedailyfromhourlyreg=0;%whether to compute regional-avg daily max/min from hourly data
usingncdcdata=0;            %these three options specify which of the datasets are being used
usingdailyclimoddata=0;     %(in other words, which was read in last)
usinghourlynrccdata=1;
%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?%^--(|\@#?


%Other variables to set
curDir='/Users/craymon3/General_Academics/Research/Exploratory_Plots/';
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
%in other words, these are the first 7 of pr1, the first and last of pr2, and the first of pr3 & pr4
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
%same as above but for 11 hourly stations only
stnlocsh(:,1)=[39.449;41.158;40.639;40.779;40.683;41.067;40.779;40.277;39.868;40.85;40.794];
stnlocsh(:,2)=[-74.567;-73.129;-73.762;-73.880;-74.169;-73.708;-73.969;-74.816;-75.231;-74.061;-73.102];
stnlocsh(:,3)=[60;5;11;11;7;379;130;184;10;9;84];stnlocsh(:,3)=stnlocsh(:,3)/mf;
save(strcat(curDir,'basicstuff'),'stnlocsh','-append');

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

%NRCC hourly data, 1941-2014
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
        satvpofairtemp=220640*exp((647.1./(airtemp+273.15)).*(-7.86*eta+1.844*eta.^1.5-11.787*eta.^3+...
            22.681*eta.^3.5-15.962*eta.^4+1.801*eta.^7.5)); %in hPa
        dewpttemp=(cursprdata(1:size(cursprdata,1),6)-32)*5/9;
        eta=1-((dewpttemp+273.15)./647.1);
        satvpofdewpttemp=220640*exp((647.1./(dewpttemp+273.15)).*(-7.86*eta+1.844*eta.^1.5-11.787*eta.^3+...
            22.681*eta.^3.5-15.962*eta.^4+1.801*eta.^7.5));
        rh=100*satvpofdewpttemp./satvpofairtemp; %finally, the RH
        hourlytvecs{stnc}(currow:size(sprdata9,1),12)=rh; %relative humidity
        
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
    save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/readnycdata','hourlytvecs');
    disp(clock);
end
        
        
%Interpolate from 3-hourly to 1-hourly for time periods where this is an issue
%For wind direction, assume wind azimuth moved around the compass rose the shorter way, 
%i.e. always through <=180 deg in a 3-hour period
if interpolatehourlynrccdata==1
    disp(clock);
    for stnc=1:size(prhcodes,1)
        for i=3:size(hourlytvecs{stnc},1)-3
        %for i=229950:230050
            for col=5:14
                vecofnumstoroundto=[0;0;0;0;0.1;0.1;0.5;0.1;0.1;0.1;0.5;1;0.01;0.01];
                if hourlytvecs{stnc}(i,col)<=-50 && hourlytvecs{stnc}(i+3,col)<=-50 &&... 
                    hourlytvecs{stnc}(i-1,col)>-50 && hourlytvecs{stnc}(i+2,col)>-50  
                    %i.e. data for this hour & 3 hours later are missing (a highly suspicious pattern), 
                    %but data for other hours exist such that this hour can be interpolated from them
                    %plain english: this hour is the first of two consecutive missing
                    if col~=7 %everything is simple except wind direction
                        newres=0.667*hourlytvecs{stnc}(i-1,col)+0.333*hourlytvecs{stnc}(i+2,col);
                        hourlytvecs{stnc}(i,col)=round2(newres,vecofnumstoroundto(col));
                    else
                        azchange=abs(hourlytvecs{stnc}(i+2,col)-hourlytvecs{stnc}(i-1,col));
                        if azchange>180 %complicated stuff, having to go the other way around the compass rose
                            smalleraz=min(hourlytvecs{stnc}(i+2,col),hourlytvecs{stnc}(i-1,col));
                            biggeraz=max(hourlytvecs{stnc}(i+2,col),hourlytvecs{stnc}(i-1,col));
                            smallerazenlarged=smalleraz+360;
                            if smalleraz==hourlytvecs{stnc}(i-1,col);earlierhourismin=1;else earlierhourismin=0;end
                            if earlierhourismin==1
                                newaz=0.667*smallerazenlarged+0.333*biggeraz;
                            else
                                newaz=0.333*smallerazenlarged+0.667*biggeraz;
                            end
                            if newaz>360;newaz=newaz-360;end
                        else %can just do a straight weighting as with the other variables
                            newaz=0.667*hourlytvecs{stnc}(i-1,col)+0.333*hourlytvecs{stnc}(i+2,col);
                        end
                        hourlytvecs{stnc}(i,col)=round2(newaz,vecofnumstoroundto(col));
                    end
                elseif hourlytvecs{stnc}(i,col)<=-50 && hourlytvecs{stnc}(i+3,col)<=-50 &&...
                    hourlytvecs{stnc}(i-2,col)>-50 && hourlytvecs{stnc}(i+1,col)>-50
                    %this hour is the second of two consecutive missing
                    if col~=7
                        newres=0.333*hourlytvecs{stnc}(i-2,col)+0.667*hourlytvecs{stnc}(i+1,col);
                        hourlytvecs{stnc}(i,col)=round2(newres,vecofnumstoroundto(col));
                    else
                        azchange=abs(hourlytvecs{stnc}(i+1,col)-hourlytvecs{stnc}(i-2,col));
                        if azchange>180
                            smalleraz=min(hourlytvecs{stnc}(i+1,col),hourlytvecs{stnc}(i-2,col));
                            biggeraz=max(hourlytvecs{stnc}(i+1,col),hourlytvecs{stnc}(i-2,col));
                            smallerazenlarged=smalleraz+360;
                            if smalleraz==hourlytvecs{stnc}(i-2,col);earlierhourismin=1;else earlierhourismin=0;end
                            if earlierhourismin==0
                                newaz=0.667*smallerazenlarged+0.333*biggeraz;
                            else
                                newaz=0.333*smallerazenlarged+0.667*biggeraz;
                            end
                            if newaz>360;newaz=newaz-360;end
                        else
                            newaz=0.333*hourlytvecs{stnc}(i-2,col)+0.667*hourlytvecs{stnc}(i+1,col);
                        end
                        hourlytvecs{stnc}(i,col)=round2(newaz,vecofnumstoroundto(col));
                    end
                else
                    %Just round the values that are already there
                    hourlytvecs{stnc}(i,col)=round2(hourlytvecs{stnc}(i,col),vecofnumstoroundto(col));
                end
            end
        end
        for i=2:size(hourlytvecs{stnc},1)-1 %interpolate where only one hour is missing
            for col=5:14
                if hourlytvecs{stnc}(i,col)<=-50 && hourlytvecs{stnc}(i-1,col)>-50 && hourlytvecs{stnc}(i+1,col)>-50
                    if col~=7
                        newres=(hourlytvecs{stnc}(i-1,col)+hourlytvecs{stnc}(i+1,col))/2;
                        hourlytvecs{stnc}(i,col)=round2(newres,vecofnumstoroundto(col));
                    else
                        azchange=abs(hourlytvecs{stnc}(i+1,col)-hourlytvecs{stnc}(i-1,col));
                        if azchange>180
                            smalleraz=min(hourlytvecs{stnc}(i+1,col),hourlytvecs{stnc}(i-1,col));
                            biggeraz=max(hourlytvecs{stnc}(i+1,col),hourlytvecs{stnc}(i-1,col));
                            smallerazenlarged=smalleraz+360;
                            if smalleraz==hourlytvecs{stnc}(i-1,col);earlierhourismin=1;else earlierhourismin=0;end
                            if earlierhourismin==0
                                newaz=0.5*smallerazenlarged+0.5*biggeraz;
                            else
                                newaz=0.5*smallerazenlarged+0.5*biggeraz;
                            end
                            if newaz>360;newaz=newaz-360;end
                        else
                            newaz=0.5*hourlytvecs{stnc}(i-1,col)+0.5*hourlytvecs{stnc}(i+1,col);
                        end
                        hourlytvecs{stnc}(i,col)=round2(newaz,vecofnumstoroundto(col));
                    end
                end
            end
        end
    end
    save('/Users/colin/Documents/General_Academics/Research/Exploratory_Plots/Saved_Variables_etc/readnycdata','hourlytvecs');
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
%regional max is occurs at a particular hour when the desired (regional) index is maximized
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









        
    