%Reads netcdf files containing hourly obs for NYC region and make plots therefrom
%Explore values, variable names, etc. using Panoply
%Even if files change, general script methodologies will be the same

%Current suite of files starts Jan 1, 1973 and ends Dec 31, 2013
%All stations are airports unless otherwise indicated
%Stewart data is improperly-lined-up so is being omitted for the time being

%Current runtime: for NARR data, about 4 min per station
%                 for CLIMOD data, about 2 min total
%                 for statistics excluding NARR plotting, about 1 min

%`={%`={%`={%`={%`={%`={%`={%`={%`={%`={%`={%`={%`={%`={%`={
%Glossary of some major vectors created in this script
%hwregister -- all heatwaves meeting the intensity/duration definition, 
%   for each station, in chronological order
%hwsorted -- hwregister sorted by heatwave severity score
%dailymaxregsorted -- sorted region-avg max temps, with dates
%dmrcc -- matrix of max temps for all stations on the 32 days when the region-avg
%   max temp exceeded 36.5 C
%hotdates -- the day and year when at least one station had a max temp in its top 10
%stnobshotdays -- matrix of max temps for 7 marquee stations on dates in hotdates

%Variables to set
obsnumyears=41;narrnumyears=21;startyear=1973; %for NARR records
numtotyrs=151; %for station-obs records
daystarthour=9; %i.e. an hour after the assumed observation time
pr1={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';...
    'CentralPark';'Brooklyn'}; %A stands for Airport
pr2={'TrentonA';'TrentonCity';'AtlCity';'TomsRiver';'PhiladelphiaA'};
pr3={'TeterboroA';'LittleFalls';'Paterson';'JerseyCity'};
pr4={'IslipA';'Scarsdale';'DobbsFerry';'PortJervis';'Mineola'};
pr=[pr1;pr2;pr3;pr4]; %station sets to use in this run -- JFK, LGA, EWR are typically 3,4,5
a=size(pr);numstns=a(1);
mf=3.28;

stnlocs1=zeros(8,3); %lat, lon, and elev for each station in group 1 (marquee)
stnlocs1(:,1)=[39.379;41.158;40.639;40.779;40.683;41.067;40.779;40.594];
stnlocs1(:,2)=[-74.424;-73.129;-73.762;-73.880;-74.169;-73.708;-73.969;-73.981];
stnlocs1(:,3)=[10;5;11;11;7;379;130;20];stnlocs1(:,3)=stnlocs1(:,3)/mf;
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

exist figc;
if ans==1;figc=figc+1;else figc=1;end
%Leap-year month starts
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;
mpr={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'};
sa=1; %selected airport to compute histograms of differences; number from prefixes list
saincluded=1; %tracks if sa is included in current run
first=0;firstandlast=0; %tracks if all stns are currently included
createnewvectors=0;
readdataatall=0; %whether data needs to be read again into arrays, or if they're complete
readnetcdfdata=0; %whether to read NCDC-derived netCDF files which span 1/1/73-12/31/13 at hourly res
readfullobsdata=0; %whether to read CLIMOD-derived CSV files which include everything at daily res
computemainstats=1; %whether to compute main stats (e.g. ranking of heat waves), or move to secondary ones

%Internal and external functions, as well as directories & mathematical constants
subindex=@(A,r,c) A(r,c);
vararginnew={'contour';1;'mystep';2;'plotCountries';1;'colormap';'jet'}; %for plotModelData
cd /Users/colin/Desktop/General_Academics/Research/Exploratory_Plots
%Kc=273.15;
Kc=0; %compute in C, no need for K


%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-%&-
%Start of script

if readdataatall==1
    %Define new arrays
    if createnewvectors==1
        dailymaxvecs=cell(numstns,1); %a magical box that contains everything
        dailyminvecs=cell(numstns,1);
        dailymaxvecs1D=cell(numstns,3);
        dailyminvecs1D=cell(numstns,3);

        dhavgvecs=cell(numstns,1); %avg of hours for each day (to better compare with NARR)
        dhavgvecs1D=cell(numstns,3);

        maxhourlyjumpvec=zeros(numstns,1);
        numdaysskippedvec=zeros(numstns,1);daysskipped=0;
        numhoursskippedvec=zeros(numstns,1);
        totalhoursineachday=cell(numstns,1);
        dailysumseachday=cell(numstns,1);

        monthlymeanmaxes=cell(numstns,1);
        monthlymeanmins=cell(numstns,1);
        monthlyprctilemaxes=cell(numstns,1);
        monthlyprctilemins=cell(numstns,1);
        cleanmonthlymaxes=cell(numstns,12);
        cleanmonthlymins=cell(numstns,12);
        cmmaxwy=cell(numstns,numtotyrs,12);
        cmminwy=cell(numstns,numtotyrs,12);
        cmmaxwy1D=zeros(numtotyrs*12,numstns,3); %3 cols, for temp, day of year, year
        cmminwy1D=zeros(numtotyrs*12,numstns,3);
    end

    if readnetcdfdata==1
    %for stncounter=1:numstns
        for stncounter=4:4
            prefix=pr(stncounter);
            disp(prefix);  
            curfile=sprintf('%s.nc',char(prefix));
            if stncounter==sa
                saincluded=1;
            end
            if stncounter==1
                first=1;
            elseif first==1
                if stncounter==numstns
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
                        dailymaxvecs{stncounter}(dateinyear,obsryear)=...
                            eval(['dailymax' char(prefix)]);
                        dailyminvecs{stncounter}(dateinyear,obsryear)=...
                            eval(['dailymin' char(prefix)]);
                        dailymaxvecs1D{stncounter}(totalnumdays,1)=eval(['dailymax' char(prefix)]);
                        dailyminvecs1D{stncounter}(totalnumdays,1)=eval(['dailymin' char(prefix)]);
                        dailymaxvecs1D{stncounter}(totalnumdays,2)=dateinyear;
                        dailyminvecs1D{stncounter}(totalnumdays,2)=dateinyear;
                        dailymaxvecs1D{stncounter}(totalnumdays,3)=obsryear+startyear-1;
                        dailyminvecs1D{stncounter}(totalnumdays,3)=obsryear+startyear-1;
                        curdailysum=double(curdailysum);totalhoursincurday=double(totalhoursincurday);
                        dhavgvecs{stncounter}(dateinyear,obsryear)=curdailysum/totalhoursincurday;
                        dhavgvecs1D{stncounter}(totalnumdays,1)=curdailysum/totalhoursincurday;
                        dhavgvecs1D{stncounter}(totalnumdays,2)=dateinyear;
                        dhavgvecs1D{stncounter}(totalnumdays,3)=obsryear+startyear-1;
                        %disp(273.15+curdailysum/totalhoursincurday);
                        %disp('above is hourly avg; below are daily max & min');
                        %disp(eval(['dailymax' char(prefix)])+273.15);
                        %disp(eval(['dailymin' char(prefix)])+273.15);

                        dateinyear=dateinyear+1;hourofday=daystarthour-1;
                        %disp(dateinyear);
                        eval(['dailymax' char(prefix) '=-99;']);
                        eval(['dailymin' char(prefix) '=99;']);
                        totalnumdays=totalnumdays+1;
                        totalhoursineachday{stncounter}(obsryear,dateinyear)=totalhoursincurday;
                        dailysumseachday{stncounter}(obsryear,dateinyear)=curdailysum;
                        %disp(totalhoursincurday);
                        totalhoursincurday=0;curdailysum=0;
                        %disp(totalnumdays);    
                    end
                    %disp(totalhoursincurday);
                    totalhoursincurday=totalhoursincurday+1;
                else
                    for j=1:daysskipped
                        dailymaxvecs{stncounter}(dateinyear,obsryear)=-50;
                        dailyminvecs{stncounter}(dateinyear,obsryear)=-50;
                        dailymaxvecs1D{stncounter}(totalnumdays,1)=-50;
                        dailyminvecs1D{stncounter}(totalnumdays,1)=-50;
                        dailymaxvecs1D{stncounter}(totalnumdays,2)=dateinyear;
                        dailyminvecs1D{stncounter}(totalnumdays,2)=dateinyear;
                        dailymaxvecs1D{stncounter}(totalnumdays,3)=obsryear+startyear-1;
                        dailyminvecs1D{stncounter}(totalnumdays,3)=obsryear+startyear-1;
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
            maxhourlyjumpvec(stncounter)=maxhourlyjump;
            numdaysskippedvec(stncounter)=daysskipped;
            numhoursskippedvec(stncounter)=discontcount;
        end
    end

    totalstnc=0;
    if readfullobsdata==1
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
            for stncounter=1:numstnshere    
                dateinyear=1;obsryear=1;totalnumdays=1;totalstnc=totalstnc+1;
                for i=1:size(sprdata,1)
                    actualyear=sprdata(i,1);obsryear=actualyear-1864;
                    %disp(dateinyear);disp(actualyear);
                    dailymaxvecs{totalstnc}(dateinyear,obsryear)=(5/9)*(sprdata(i,6*stncounter-2)-32);
                    dailyminvecs{totalstnc}(dateinyear,obsryear)=(5/9)*(sprdata(i,6*stncounter-1)-32);
                    dailymaxvecs1D{totalstnc}(totalnumdays,1)=(5/9)*(sprdata(i,6*stncounter-2)-32);
                    dailymaxvecs1D{totalstnc}(totalnumdays,2)=dateinyear;
                    dailymaxvecs1D{totalstnc}(totalnumdays,3)=actualyear;
                    dailyminvecs1D{totalstnc}(totalnumdays,1)=(5/9)*(sprdata(i,6*stncounter-1)-32);
                    dailyminvecs1D{totalstnc}(totalnumdays,2)=dateinyear;
                    dailyminvecs1D{totalstnc}(totalnumdays,3)=actualyear;

                    %Make sure -99 values stay that way
                    if dailymaxvecs{totalstnc}(dateinyear,obsryear)<-72
                        dailymaxvecs{totalstnc}(dateinyear,obsryear)=-99;
                        dailymaxvecs1D{totalstnc}(totalnumdays,1)=-99;
                    end
                    if dailyminvecs{totalstnc}(dateinyear,obsryear)<-72
                        dailyminvecs{totalstnc}(dateinyear,obsryear)=-99;
                        dailyminvecs1D{totalstnc}(totalnumdays,1)=-99;
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
end




%#*)%#*)%#*)%#*)%#*)%#*)%#*)%#*)%#*)%#*)
%Compute statistics

%First thing is just to graph how many stations there are available for
%each full year (at most 18, or 5%, missing)
%Uses max temps but min and others are presumably quite similar
stnsperyear=zeros(numtotyrs,1);
for yr=1:numtotyrs
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
figure(figc);clf;figc=figc+1;years=1865:2015;
plot(years,stnsperyear);xlim([1865 2015]);hold on;
threshvals=0.5*numstns*ones(numtotyrs,1);plot(years,threshvals,'r');
title('Number of stations per year that are at least 95% complete','FontSize',16,'FontWeight','bold');
                

if computemainstats==1
    for stncounter=1:numstns
        prefix=pr(stncounter);  
        tempmax=sortrows(dailymaxvecs1D{stncounter},-1);
        format shortG;
        %hottest 5% and 0.5% of maxima
        eval(['hottest5percmax' char(prefix) '=tempmax(1:round(5*totalnumdays/100),:);']);
        eval(['hottest0point5percmax' char(prefix) '=tempmax(1:round(0.5*totalnumdays/100),:);']);
        eval(['length5perc' char(prefix) '=round(5*totalnumdays/100);']);
        eval(['length0point5perc' char(prefix) '=round(0.5*totalnumdays/100);']);
        %...of minima
        tempmin=sortrows(dailyminvecs1D{stncounter},-1);
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
            cleanmonthlymaxes{stncounter,ct}=...
                dailymaxvecs{stncounter}(sd:ed,1:size(dailymaxvecs{stncounter},2));
            cleanmonthlymaxes{stncounter,ct}=...
                cleanmonthlymaxes{stncounter,ct}(cleanmonthlymaxes{stncounter,ct}>-50);
            cleanmonthlymins{stncounter,ct}=...
                dailyminvecs{stncounter}(sd:ed,1:size(dailyminvecs{stncounter},2));
            cleanmonthlymins{stncounter,ct}=...
                cleanmonthlymins{stncounter,ct}(cleanmonthlymins{stncounter,ct}>-50);
        end
        %Enhanced version of cleanmonthlyxxx with absolute year identified
        yc=1;totdayc=1;
        for yc=1:numtotyrs
            %yc=4,8,etc. are leap years, with the exception of yc=36 (1900)
            for ct=1:12
                if rem(yc,4)==0 && yc~=36
                    if ct==12          
                        sd=eval(sprintf('m%usl',ct));
                        ed=366;
                    else
                        sd=eval(sprintf('m%usl',ct));
                        ed=eval(sprintf('m%usl',ct+1))-1;
                    end
                elseif rem(yc,4)~=0 || yc==36
                    if ct==12          
                        sd=eval(sprintf('m%us',ct));
                        ed=365;
                    else
                        sd=eval(sprintf('m%us',ct));
                        ed=eval(sprintf('m%us',ct+1))-1;
                    end
                end
                cmmaxwy{stncounter,yc,ct}=...
                    dailymaxvecs{stncounter}(sd:ed,yc);
                cmminwy{stncounter,yc,ct}=...
                    dailyminvecs{stncounter}(sd:ed,yc);
                cmmaxwy1D(totdayc:totdayc+ed-sd,stncounter,1)=dailymaxvecs{stncounter}(sd:ed,yc);
                cmminwy1D(totdayc:totdayc+ed-sd,stncounter,1)=dailyminvecs{stncounter}(sd:ed,yc);
                cmmaxwy1D(totdayc:totdayc+ed-sd,stncounter,2)=ct*ones(ed-sd+1,1);
                cmminwy1D(totdayc:totdayc+ed-sd,stncounter,2)=ct*ones(ed-sd+1,1);
                cmmaxwy1D(totdayc:totdayc+ed-sd,stncounter,3)=(yc+1864)*ones(ed-sd+1,1);
                cmminwy1D(totdayc:totdayc+ed-sd,stncounter,3)=(yc+1864)*ones(ed-sd+1,1);
                totdayc=totdayc+ed-sd+1;
            end
        end

        %Mean monthly maxima and minima for each station
        for month=1:12
            monthlymeanmaxes{stncounter}(month)=...
                mean(mean(cleanmonthlymaxes{stncounter,month}));
            monthlymeanmins{stncounter}(month)=...
                mean(mean(cleanmonthlymins{stncounter,month}));
        end

        %Quick computation of station-specific percentiles
        prctilestocompute=[5;10;25;50;75;90;95];
        for ii=1:length(prctilestocompute)
            for month=1:12
                monthlyprctilemaxes{stncounter}(month,ii)=...
                    prctile(cleanmonthlymaxes{stncounter,month},prctilestocompute(ii));
                monthlyprctilemins{stncounter}(month,ii)=...
                    prctile(cleanmonthlymins{stncounter,month},prctilestocompute(ii));
            end
        end

        %Based on these percentiles, create station catalogues of JJA heatwaves [1] ranked by
        %intensity [2] -- thus taking into account incidence, length, and severity
        %[1] Defined as 3 consecutive days whose max OR min temp exceeds that
        %station's monthly 90th percentile
        %[2] Defined as the heatwave-integrated daily max and min over the threshold
        numhws=0;consechotdayc=0;sotx=0;sotn=0; %last two are sums over threshold of max & min
        for jj=1:size(dailymaxvecs1D{stncounter},1)
            if dailymaxvecs1D{stncounter}(jj,2)>=m6sl && dailymaxvecs1D{stncounter}(jj,2)<m9s %JJA
                if dailymaxvecs1D{stncounter}(jj,2)<m7sl %June
                    if dailymaxvecs1D{stncounter}(jj,1)>=monthlyprctilemaxes{stncounter}(6,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stncounter}(jj,1);
                        %a heatwave even though min temp may or may not be above its threshold
                        thishwmins(consechotdayc)=dailyminvecs1D{stncounter}(jj,1);
                        sotx=sotx+dailymaxvecs1D{stncounter}(jj,1)-monthlyprctilemaxes{stncounter}(6,6);
                        %disp(jj);disp(dailymaxvecs1D{stncounter}(jj,1));
                        %disp(monthlyprctilemaxes{stncounter}(6,6));disp(sotx);
                        sotn=sotn+dailyminvecs1D{stncounter}(jj,1)-monthlyprctilemins{stncounter}(6,6);
                    elseif dailyminvecs1D{stncounter}(jj,1)>=monthlyprctilemins{stncounter}(6,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stncounter}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stncounter}(jj,1);
                        sotx=sotx+dailymaxvecs1D{stncounter}(jj,1)-monthlyprctilemaxes{stncounter}(6,6);
                        sotn=sotn+dailyminvecs1D{stncounter}(jj,1)-monthlyprctilemins{stncounter}(6,6);
                    else %a cool day...
                        if consechotdayc>=3 %...that ended a heatwave
                            %disp(thishwmaxes);disp(thishwmins);disp(sotx);
                            %disp(max(thishwmaxes));
                            numhws=numhws+1;%disp(numhws);
                            hwregister{stncounter}(numhws,1)=dailymaxvecs1D{stncounter}(jj,2)- ...
                                consechotdayc;
                            hwregister{stncounter}(numhws,2)=dailymaxvecs1D{stncounter}(jj,2)-1;
                            hwregister{stncounter}(numhws,3)=dailymaxvecs1D{stncounter}(jj,3);
                            hwregister{stncounter}(numhws,4)=max(thishwmaxes);
                            hwregister{stncounter}(numhws,5)=max(thishwmins);
                            hwregister{stncounter}(numhws,6)=sotx;
                            hwregister{stncounter}(numhws,7)=sotn;
                            hwregister{stncounter}(numhws,8)=sotx+sotn;
                        end
                        consechotdayc=0;
                        thishwmaxes=0;thishwmins=0;
                        sotx=0;sotn=0;
                    end
                elseif dailymaxvecs1D{stncounter}(jj,2)>=m7sl && dailymaxvecs1D{stncounter}(jj,2)<m8s
                    if dailymaxvecs1D{stncounter}(jj,1)>=monthlyprctilemaxes{stncounter}(7,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stncounter}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stncounter}(jj,1);
                        sotx=sotx+dailymaxvecs1D{stncounter}(jj,1)-monthlyprctilemaxes{stncounter}(7,6);
                        sotn=sotn+dailyminvecs1D{stncounter}(jj,1)-monthlyprctilemins{stncounter}(7,6);
                    elseif dailyminvecs1D{stncounter}(jj,1)>=monthlyprctilemins{stncounter}(7,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stncounter}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stncounter}(jj,1);
                        sotx=sotx+dailymaxvecs1D{stncounter}(jj,1)-monthlyprctilemaxes{stncounter}(7,6);
                        sotn=sotn+dailyminvecs1D{stncounter}(jj,1)-monthlyprctilemins{stncounter}(7,6);
                    else
                        if consechotdayc>=3 %a heatwave just ended
                            numhws=numhws+1;
                            hwregister{stncounter}(numhws,1)=...
                                dailymaxvecs1D{stncounter}(jj,2)-consechotdayc;
                            hwregister{stncounter}(numhws,2)=dailymaxvecs1D{stncounter}(jj,2)-1;
                            hwregister{stncounter}(numhws,3)=dailymaxvecs1D{stncounter}(jj,3);
                            hwregister{stncounter}(numhws,4)=max(thishwmaxes);
                            hwregister{stncounter}(numhws,5)=max(thishwmins);
                            hwregister{stncounter}(numhws,6)=sotx;
                            hwregister{stncounter}(numhws,7)=sotn;
                            hwregister{stncounter}(numhws,8)=sotx+sotn;
                        end
                        consechotdayc=0;
                        thishwmaxes=0;thishwmins=0;
                        sotx=0;sotn=0;
                    end
                else %August
                    if dailymaxvecs1D{stncounter}(jj,1)>=monthlyprctilemaxes{stncounter}(8,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stncounter}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stncounter}(jj,1);
                        sotx=sotx+dailymaxvecs1D{stncounter}(jj,1)-monthlyprctilemaxes{stncounter}(8,6);
                        sotn=sotn+dailyminvecs1D{stncounter}(jj,1)-monthlyprctilemins{stncounter}(8,6);
                    elseif dailyminvecs1D{stncounter}(jj,1)>=monthlyprctilemins{stncounter}(8,6)
                        consechotdayc=consechotdayc+1;
                        thishwmaxes(consechotdayc)=dailymaxvecs1D{stncounter}(jj,1);
                        thishwmins(consechotdayc)=dailyminvecs1D{stncounter}(jj,1);
                        sotx=sotx+dailymaxvecs1D{stncounter}(jj,1)-monthlyprctilemaxes{stncounter}(8,6);
                        sotn=sotn+dailyminvecs1D{stncounter}(jj,1)-monthlyprctilemins{stncounter}(8,6);
                    else
                        if consechotdayc>=3 %a heatwave just ended
                            numhws=numhws+1;
                            hwregister{stncounter}(numhws,1)=...
                                dailymaxvecs1D{stncounter}(jj,2)-consechotdayc;
                            hwregister{stncounter}(numhws,2)=dailymaxvecs1D{stncounter}(jj,2)-1;
                            hwregister{stncounter}(numhws,3)=dailymaxvecs1D{stncounter}(jj,3);
                            hwregister{stncounter}(numhws,4)=max(thishwmaxes);
                            hwregister{stncounter}(numhws,5)=max(thishwmins);
                            hwregister{stncounter}(numhws,6)=sotx;
                            hwregister{stncounter}(numhws,7)=sotn;
                            hwregister{stncounter}(numhws,8)=sotx+sotn;
                        end
                        consechotdayc=0;
                        thishwmaxes=0;thishwmins=0;
                        sotx=0;sotn=0;
                    end
                end
            elseif dailymaxvecs1D{stncounter}(jj,2)==m9s %Sep 1, all heatwaves must end par def'n
                consechotdayc=0;
            end
        end

        %Sort the result to have an ordered list of heatwaves by intensity
        hwsorted{stncounter}=sortrows(hwregister{stncounter},-8);
    end
end


%Find the dates on which the marquee stations (except AtlCityA) had their 10 highest max
%temps, compile them, and make a correlation matrix comparing the temps on
%those dates (to get a preliminary sense of which stations tend to be in
%line on the very hottest days)
hotdates=0;
hotdates(1:10,1)=hottest0point5percmaxBridgeportA(1:10,2);
hotdates(1:10,2)=hottest0point5percmaxBridgeportA(1:10,3);
lastsize=size(hotdates,1);cursize=lastsize;
for stncounter=3:8
    prefix=pr(stncounter);
    tempor=eval(['hottest0point5percmax' char(prefix)]);
    for i=1:10
        testday=tempor(i,2);testyear=tempor(i,3);
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
%Remove extraneous all-zero rows
hotdates(all(hotdates==0,2),:)=[];

%Create correlation matrix with 7 stations' obs on this suite of dates
stnobshotdays=0;numcities=7;ssa=2; %stationstartingat
for i=1:size(hotdates,1)
    for stncounter=ssa:ssa+numcities-1
        thishotday=hotdates(i,1);thishotyear=hotdates(i,2);
        val=dailymaxvecs{stncounter}(thishotday,thishotyear-1864);
        stnobshotdays(stncounter-1,i)=val;
    end
end
%Transpose compares stations across dates (6x6); untransposed compares dates
%across stations (36x36)
stnobshotdays(stnobshotdays==-99)=NaN;
if size(stnobshotdays,1)<size(hotdates,1);stnobshotdays=stnobshotdays';end %to get 6x6 output
outputmatrix=corrcoef(stnobshotdays,'rows','pairwise'); 
    %or 'all' to exclude rows with any NaNs when doing 36x36
figure(figc);clf;figc=figc+1;
imagesc(outputmatrix);colorbar;
cities=['Bridgeport';'       JFK';'       LGA';'    Newark';'  White Pl';' Central P';'  Brooklyn'];
pos=get(gca,'Position');
set(gca,'Position',[pos(1),.2,pos(3) .65]);
Xt=1:numcities;
Xl=[1 numcities];
set(gca,'XTick',Xt,'XLim',Xl);
ax=axis;
axis(axis);
Yl=ax(3:4);
t=text(Xt,Yl(2)*ones(1,length(Xt))+0.5,cities(1:numcities,:));
set(t,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
    'Rotation',45,'FontSize',11);
title('Comparison of Station Max Temps on 36 Hot Days','FontSize',14,'FontWeight','bold');

%Most-similar dates: 25, 33, and 35; 13, 16, and 24; 19 and 27
%    187, 1999; 196, 1995; and 189, 1993
%    185, 2010; 203, 2011; and 187, 2010
%    221, 2001 and 141, 1996
%Most-dissimilar: 30 and 28; 15 and 28; 26 and 28
%    204, 2011 and 199, 1999 (Jul 18, 1999, with Atl City at 83 and others
%    in 90s)
%    190, 1993 and 199, 1999
%    191, 1993 and 199, 1999
                


%Compute the hottest region-wide days, then create charts comparing
%the stations' max and min temps on those days
%Several options: either include if any station has data (too permissive), 
%or if all of them do (too restrictive), or if a set percentage do
%This percentage can vary but is set at 50% by default
sz=size(dailymaxvecs1D{1},1);dailymaxvecs1D=dailymaxvecs1D';
dailymaxregsorted=zeros(sz,3);
for i=1:sz-3 %for a couple-day cushion
    validstns=0;dailysum=0;
    for stncounter=1:numstns
        if isnan(dailymaxvecs1D{stncounter}(i,1))==0
            if dailymaxvecs1D{stncounter}(i,1)>-99
                %disp(dailymaxvecs1D{stncounter}(i,1));
                validstns=validstns+1;
                dailysum=dailysum+dailymaxvecs1D{stncounter}(i,1);
            end
        end
    end
    %if validstns==0
    if validstns<0.5*numstns
        dailymaxregsorted(i,1)=-99;
    else
        dailymaxregsorted(i,1)=dailysum/validstns;
    end
    dailymaxregsorted(i,2)=dailymaxvecs1D{1}(i,2);
    dailymaxregsorted(i,3)=dailymaxvecs1D{1}(i,3);
end
dailymaxregsorted=sortrows(dailymaxregsorted,-1);

%Top 32 days have average max temp >=36.5 C
dmrcc=zeros(32,numstns); %dailymaxregcitychart
dmrccnotes=zeros(32,numstns); %matching matrix with numerical coloring instructions
for i=1:32
    %Each stn's temps day by day
    for stncounter=1:numstns
        day=dailymaxregsorted(i,2);
        ryear=dailymaxregsorted(i,3)-1865+1;
        if dailymaxvecs{stncounter}(day,ryear)>-50
            dmrcc(i,stncounter)=dailymaxvecs{stncounter}(day,ryear);
        else
            dmrcc(i,stncounter)=NaN;
        end
    end
    %Calculate median & st dev across stns for each day
    a=dmrcc(i,:);a=a(a>-50); %across non-missing stations
    med=median(a);
    stdev=std(a);
    %Make notes for shading if a stn exceeds 1 st dev in either direction
    for stncounter=1:numstns
        if dmrcc(i,stncounter)<med-stdev
            dmrccnotes(i,stncounter)=-1; %with -'s
        elseif dmrcc(i,stncounter)>med+stdev
            dmrccnotes(i,stncounter)=1; %with +'s
        else
            dmrccnotes(i,stncounter)=0; %blank
        end
    end
end
%Can't shown 22 stns though, so only show 7 marquee ones minus AtlCityA
figure(figc);clf;figc=figc+1;
imagescnan(dmrcc(:,2:numcities+1));colorbar;
pos=get(gca,'Position');
set(gca,'Position',[pos(1),.2,pos(3) .65]);
Xt=1:numcities;
Xl=[1 numcities];
set(gca,'XTick',Xt,'XLim',Xl);
ax=axis;
axis(axis);
Yl=ax(3:4);
t=text(Xt,Yl(2)*ones(1,length(Xt))+1,cities(1:numcities,:));
set(t,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
    'Rotation',45,'FontSize',11);
title('Stn Max Temps on Days with Regional Avg >=36 C','FontSize',16,'FontWeight','bold');
%Add text according to dmrccnotes
for row=1:24
    for stnc=ssa:numcities+1
        if dmrccnotes(row,stnc)==1
            if stnc~=2 && stnc~=numcities+1
                text(stnc-0.25-(ssa-1),row,'+++++++');
            elseif stnc==numcities+1
                text(stnc-0.25-(ssa-1),row,'+++');
            else
                text(stnc+0.25-(ssa-1),row,'+++');
            end
        elseif dmrccnotes(row,stnc)==-1
            if stnc~=2 && stnc~=numcities+1
                text(stnc-0.25-(ssa-1),row,'------------');
            elseif stnc==numcities+1
                text(stnc-0.25-(ssa-1),row,'------');
            else
                text(stnc+0.25-(ssa-1),row,'------');
            end
        end
    end
end
    

%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$%~@$
%Climo plots
%Most of these comparison plots do assume stationarity over the timeseries,
%at least so far...

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
if saincluded==1
    selpr=10;
    variab1='max'; %cmmaxwy or cmminwy are the choices at present
    centers=[-12:1:12];
    
    validc=0;monthrange=6:8;
    for y=1:numtotyrs-1
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


%Display boxplots of JJA maxes or mins for all stations, to get a quick
%all-encompassing advisor-pleasing visual
variab2='max';
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
x=[x1;x2;x3;x4;x5;x6;x7;x8];g=[ones(size(x1,1),1);2*ones(size(x2,1),1);3*ones(size(x3,1),1);...
    4*ones(size(x4,1),1);5*ones(size(x5,1),1);6*ones(size(x6,1),1);7*ones(size(x7,1),1);...
    8*ones(size(x8,1),1);];
boxplot(x,g,'notch','on');
marqueecities=['Atl City A';'Bridgeport';'       JFK';'       LGA';'    Newark';...
    '  White Pl';' Central P';'  Brooklyn'];
Xt=1:numcities+1;
t=text(Xt,min(x1)*ones(1,length(Xt))-5,marqueecities(1:numcities+1,:));
set(t,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
    'Rotation',45,'FontSize',11);
title(sprintf('Box Plots Comparing Marquee Stations for JJA %s',variab2),'FontSize',16);
ylabel('Temperature (C)','FontSize',14);


%Building off of the previous boxplot comparison, make density plot of tail for
%each city and overlay them to directly compare the relative fatness of tails
%Tails are the subset of JJA maxes/mins above a selected threshold
if strcmp(variab2,'max');thresh=35;elseif strcmp(variab2,'min');thresh=25;end

figure(figc);clf;figc=figc+1;hold on;xlim([thresh thresh+8]);
[f,xi]=ksdensity(x1);plot(xi,f,'Color',colors('red'),'LineWidth',2);
[f,xi]=ksdensity(x2);plot(xi,f,'Color',colors('light red'),'LineWidth',2);
[f,xi]=ksdensity(x3);plot(xi,f,'Color',colors('light orange'),'LineWidth',2);
[f,xi]=ksdensity(x4);plot(xi,f,'Color',colors('light green'),'LineWidth',2);
[f,xi]=ksdensity(x5);plot(xi,f,'Color',colors('green'),'LineWidth',2);
[f,xi]=ksdensity(x6);plot(xi,f,'Color',colors('blue'),'LineWidth',2);
[f,xi]=ksdensity(x7);plot(xi,f,'Color',colors('light purple'),'LineWidth',2);
[f,xi]=ksdensity(x8);plot(xi,f,'Color',colors('pink'),'LineWidth',2);
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


%Display 5th, 50th, and 95th percentiles of maxes for each station in each month
%Naturally, only works if all stns have been computed
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




        
    