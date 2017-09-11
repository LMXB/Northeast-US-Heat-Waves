%Compares NARR and observational data for given months
%NARR data right now is once-daily, so have to average station max & min as an approximation

%Must run readnarrdata and readnycdata before running this script

%Current runtime: 
    %computenarrbiases: 1 hour 40 min total
%---------%After next full run, save the following vectors as a .mat file:
%diffavgs/25s/975s, mbvq, monbiasvec..., max/minmonthvecs, narravgts..., 
%narrw outputvec, nwov..., obsmax/min/avgts, sov..., stnoutputvec, totmonvec
    
%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*%`0||3@*
%Runtime options
definevectors=0;          %whether to (re)define vectors like obsavgts
computeoldstats=0;        %whether to compute stats using old-style vectors (these sections will probably be raided & deleted)
computenarrbiases=1;      %whether to compare daily-avg station temps to those of weighted NARR gridpoints
     %this section has its own variables to set
showdiffmap=1;            %whether to show the map of stations with each one's symbol corresponding to the NARR bias there,
     %with a particular focus on this bias on hot days


daysinm=0;prevdaysinm=0;
startyear=1979;stopyear=2014;numyears=stopyear-startyear+1; %range of years available
stniwf=4;stniwl=4; %from prefixes in readnycdata
yeariwf=1;yeariwl=2; %1979=1
monthiwf=1;monthiwl=12;
m1s=1;m2s=32;m3s=61;m4s=92;m5s=122;m6s=153;m7s=183;m8s=214;m9s=245;m10s=275;m11s=306;m12s=336;
pr1={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';...
    'CentralPark';'Brooklyn'}; %A stands for Airport
pr2={'TrentonA';'TrentonCity';'AtlCity';'TomsRiver';'PhiladelphiaA'};
pr3={'TeterboroA';'LittleFalls';'Paterson';'JerseyCity'};
pr4={'IslipA';'Scarsdale';'DobbsFerry';'PortJervis';'Mineola'};
pr=[pr1;pr2;pr3;pr4]; %station sets to use in this run -- JFK, LGA, EWR are 3,4,5 in a standard run
a=size(pr);numstns=a(1);
numstnsiw=stniwl-stniwf+1;numyearsiw=yeariwl-yeariwf+1;
nummonthsiw=monthiwl-monthiwf+1;


%Basically, put all the data in 3D cells
if definevectors==1
    obsmaxts=cell(numstns,numyears,12);obsmints=cell(numstns,numyears,12);
    obsavgts=cell(numstns,numyears,12);narravgts=cell(numstns,numyears,12);
    narravgtsn=cell(numstns,numyears,12);narravgtss=cell(numstns,numyears,12);
    narravgtse=cell(numstns,numyears,12);narravgtsw=cell(numstns,numyears,12);
    diffavgs=zeros(numstnsiw,numyearsiw,12);
    diff975s=zeros(numstnsiw,numyearsiw,12);diff25s=zeros(numstnsiw,numyearsiw,12);
    for stn=stniwf:stniwl
        for year=yeariwf:yeariwl
            adjyear=year+adj;
            if rem(year,4)==5-rem(startyear,4) %a leap year
                monlens=[31;29;31;30;31;30;31;31;30;31;30;31];
            else
                monlens=[31;28;31;30;31;30;31;31;30;31;30;31];
            end
            for month=1:12
                prevdaysinm=daysinm;
                daysinm=monlens(month);
                if year==1 && month==1 %problematic b/c of max shifting
                    obsmaxts{stn,year,month}=...
                        (cleanmonthlymaxes{stn,month}(adjyear*daysinm-(daysinm-1):adjyear*daysinm))+273.15;
                    obsmints{stn,year,month}=...
                        (cleanmonthlymins{stn,month}(adjyear*daysinm-(daysinm-1):adjyear*daysinm))+273.15;
                elseif month==1
                    maxmonthvec=zeros(daysinm,1);minmonthvec=zeros(daysinm,1);
                    maxmonthvec(1)=(cleanmonthlymaxes{stn,12}((adjyear-1)*prevdaysinm))+273.15;
                    maxmonthvec(2:daysinm)=...
                        (cleanmonthlymaxes{stn,month}(adjyear*daysinm-(daysinm-1):adjyear*daysinm-1))+273.15;
                    obsmaxts{stn,year,month}=maxmonthvec(1:daysinm);
                    minmonthvec(1)=(cleanmonthlymins{stn,12}((adjyear-1)*prevdaysinm))+273.15;
                    minmonthvec(2:daysinm)=...
                        (cleanmonthlymins{stn,month}(adjyear*daysinm-(daysinm-1):adjyear*daysinm-1))+273.15;
                    obsmints{stn,year,month}=minmonthvec(1:daysinm);
                else
                    maxmonthvec=zeros(daysinm,1);minmonthvec=zeros(daysinm,1);
                    maxmonthvec(1)=(cleanmonthlymaxes{stn,month-1}(adjyear*prevdaysinm))+273.15;
                    %disp(year*daysinm);disp(year*prevdaysinm);
                    maxmonthvec(2:daysinm)=...
                        (cleanmonthlymaxes{stn,month}(adjyear*daysinm-(daysinm-1):adjyear*daysinm-1))+273.15;
                    obsmaxts{stn,year,month}=maxmonthvec(1:daysinm);
                    minmonthvec(1)=(cleanmonthlymins{stn,month-1}(adjyear*prevdaysinm))+273.15;
                    minmonthvec(2:daysinm)=...
                        (cleanmonthlymins{stn,month}(adjyear*daysinm-(daysinm-1):adjyear*daysinm-1))+273.15;
                    obsmints{stn,year,month}=minmonthvec(1:daysinm);
                end

                %The final result of all this jockeying
                obsavgts{stn,year,month}=(obsmaxts{stn,year,month}+obsmints{stn,year,month})/2;
            end
        end
    end
end

%maxes are offset by a day because of the 8 AM practice
%Compare observational max, min, and avg with NARR avg computed with
%(min+max)/2 and hourly-average formulations
if computeoldstats==1
    stniw=4;yeariw=1;monthiw=7;
    if monthiw==12          
        sd=eval(sprintf('m%us',monthiw));
        ed=366;
    else
        sd=eval(sprintf('m%us',monthiw));
        ed=eval(sprintf('m%us',monthiw+1))-1;
    end

    exist figc;if ans==0;figc=1;end
    figure(figc);figc=figc+1;
    plot(obsavgts{stniw,yeariw,monthiw},'Color',colors('dark green'));hold on; %{4,1,7} is Jul 1979 for JFK

    %Statistics of differences between them
    for stniw=stniwf:stniwl
        for yeariw=yeariwf:yeariwl
            disp(yeariw);
            for monthiw=monthiwf:monthiwl
                diff=narravgts{stniw,yeariw,monthiw}-obsavgts{stniw,yeariw,monthiw};
                diffabs=abs(diff);
                diffavg=sum(diffabs)/daysinm;
                diff975=prctile(diff,97.5); %upper limit of rough confidence bounds
                diff500=prctile(diff,50.0); %median
                diff25=prctile(diff,2.5); %lower limit

                diffavgs(stniw,yeariw,monthiw)=diffavg;
                diff975s(stniw,yeariw,monthiw)=diff975;
                diff50s(stniw,yeariw,monthiw)=diff500;
                diff25s(stniw,yeariw,monthiw)=diff25;
            end
        end
    end
end


cg=wnarrgridpts(40.76,-73.98,1,0);
%Closest gridpoints for each station in readnycdata
%Atlantic City: (125,259) a.k.a. 39.35,-74.61
%Bridgeport: (132,260) a.k.a. 41.05, -73.14
%Islip: (131,260) a.k.a. 40.79, -73.31
%JFK: (130,259) a.k.a. 40.66, -73.82
%LaGuardia: (130,259) a.k.a. 40.66, -73.82
%McGuire AFB: (127,258) a.k.a. 40.00, -74.64
%Newark: (130,258) a.k.a. 40.78, -74.16
%Teterboro: (130,258) a.k.a. 40.78, -74.16
%White Plains: (131,259) a.k.a. 40.92, -73.65



%Compare stations to the weighted avg of their surrounding NARR gridpts for
%warm, avg, and cool days
%Two versions: one runs only over JJA and makes histograms of NARR-stn biases;
%the other runs over the whole year and makes a line graph of the bias
%distribution month-by-month
if computenarrbiases==1
    %Runtime options for this loop
    stniwf=1;stniwl=22;yeariwf=1979;yeariwl=2014;
    dojjaonly=0;domonthlines=1;
    varsdes=[1];           %can only do temp (1) at the moment, as CLIMOD data doesn't include shum or wind
    redefinemainvectors=1; %whether to redefine the monbiasvec family, or keep what has already been stored there
    %#3-)0__+1!%#3-)0__+1!%#3-)0__+1!%#3-)0__+1!%#3-)0__+1!%#3-)0__+1!%#3-)0__+1!
    
    if dojjaonly==1;moniwf=6;moniwl=8;else moniwf=1;moniwl=12;end
    
    adj=273.15; %NARR data are in K, CLIMOD in C
    nummon=(monthiwl-monthiwf+1)*(yeariwl-yeariwf+1);totmonc=0;
    stnoutputmaxes=0;stnoutputmins=0;stnoutputvec=0;narrwoutputvec=0;
    sovcool=0;nwovcool=0;sovavg=0;nwovavg=0;sovwarm=0;nwovwarm=0;
    if redefinemainvectors==1
        if dojjaonly==1
            monbiasvec=cell(stniwl-stniwf+1,size(varsdes,1));monbiasveccool=cell(stniwl-stniwf+1,size(varsdes,1));
            monbiasvecavg=cell(stniwl-stniwf+1,size(varsdes,1));monbiasvecwarm=cell(stniwl-stniwf+1,size(varsdes,1));
        elseif domonthlines==1
            monbiasvec=cell(stniwl-stniwf+1,size(varsdes,1),12);monbiasveccool=cell(stniwl-stniwf+1,size(varsdes,1),12);
            monbiasvecavg=cell(stniwl-stniwf+1,size(varsdes,1),12);monbiasvecwarm=cell(stniwl-stniwf+1,size(varsdes,1),12);
        end
    end

    for stnc=stniwf:stniwl
        closest4=wnarrgridpts(stnlocs(stnc,1),stnlocs(stnc,2),1,0);
        fprintf('Current station is %s\n',prlabels{stnc});
        for variab=1:size(varsdes,1)
            dayc=1;cooldayc=1;avgdayc=1;warmdayc=1;totmonvec=cell(12,1);totmonc=1;coolc2=1;warmc2=1;avgc2=1;
            if dojjaonly==1 && size(varsdes,1)>=2 %if multiple variables, need to clean out vectors between each
                monbiasvec=cell(stniwl-stniwf+1,size(varsdes,1));monbiasveccool=cell(stniwl-stniwf+1,size(varsdes,1));
                monbiasvecavg=cell(stniwl-stniwf+1,size(varsdes,1));monbiasvecwarm=cell(stniwl-stniwf+1,size(varsdes,1));
            end
            for year=yeariwf:yeariwl
                obsyear=yeariwf-1864;narryear=year-yeariwf+1;
                for mon=moniwf:moniwl
                    if redefinemainvectors==1
                        ymmissing=0;
                        missingymdaily=eval(['missingymdaily' char(varlist{varsdes(variab)})]);
                        for row=1:size(missingymdailyair,1)
                            if mon==missingymdailyair(row,1) && year==missingymdailyair(row,2);ymmissing=1;end
                        end
                        if ymmissing==1 %Do nothing, just skip the month
                        else
                            fprintf('Year and month are %d %d\n',year,mon);
                            %Only reset vectors if segregating by month
                            if domonthlines==1;stnoutputvec=0;narrwoutputvec=0;sovcool=0;...
                                    nwovcool=0;sovavg=0;nwovavg=0;sovwarm=0;nwovwarm=0;end
                            %Retrieve station temperatures for this month and plot them
                            if mon==4 || mon==6 || mon==9 || mon==11
                                monlen=30;
                            elseif mon==2
                                %if rem(year,4)==0;monlen=29;else monlen=28;end
                                monlen=28; %eliminated leap-day values in cmmaxwy/cmminwy for simplicity
                            else
                                monlen=31;
                            end
                            for day=1:monlen
                                stnoutputmaxes(dayc)=cmmaxwy{stnc,obsyear,mon}(day);
                                stnoutputmins(dayc)=cmminwy{stnc,obsyear,mon}(day);
                                if stnoutputmaxes(dayc)>-50 && stnoutputmins(dayc)>-50
                                    stnoutputvec(dayc)=(stnoutputmaxes(dayc)+stnoutputmins(dayc))/2;
                                    %Decide if day is cool (<=25th pctile), avg (25th-75th pctile), or warm (>=75th pctile)
                                    if stnoutputvec(dayc)<=monthlyprctileavgs{stnc}(mon,3)
                                        sovcool(cooldayc)=(stnoutputmaxes(dayc)+stnoutputmins(dayc))/2;
                                        daydesc='cool';cooldayc=cooldayc+1;
                                    elseif stnoutputvec(dayc)>=monthlyprctileavgs{stnc}(mon,5)
                                        sovwarm(warmdayc)=(stnoutputmaxes(dayc)+stnoutputmins(dayc))/2;
                                        daydesc='warm';warmdayc=warmdayc+1;
                                    else
                                        sovavg(avgdayc)=(stnoutputmaxes(dayc)+stnoutputmins(dayc))/2;
                                        daydesc='avg';avgdayc=avgdayc+1;
                                    end
                                    %disp('Day and day count');disp(day);disp(dayc);
                                    dayc=dayc+1;validstnday=1;
                                else
                                    validstnday=0;
                                end


                                %Read in NARR temperatures for this day, find 4
                                %gridpoints closest to station, and store the weighted value

                                %fprintf('Current YMD is %d, %d, %d\n',year,mon,day);
                                if day==1 %only need to define curArr once per month (as that's the size of it)
                                    if mon<=9
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                        '_0',num2str(mon),'_01.mat')));
                                        lastpart=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_0',num2str(mon),'_01'));
                                    else 
                                        curFile=load(char(strcat(curDir,'/',varlist(varsdes(variab)),'/',...
                                            num2str(year),'/',varlist(varsdes(variab)),'_',num2str(year),...
                                        '_',num2str(mon),'_01.mat')));
                                        lastpart=char(strcat(varlist(varsdes(variab)),'_',num2str(year),'_',num2str(mon),'_01'));
                                    end
                                    curArr=eval(['curFile.' lastpart]);curArr{3}=curArr{3}-adj;
                                end

                                if validstnday==1 %if station is missing this day, on the other hand, there's nothing to compare to
                                    narrw=closest4(1,3)*curArr{3}(closest4(1,1),closest4(1,2),1,day)+...
                                        closest4(2,3)*curArr{3}(closest4(2,1),closest4(2,2),1,day)+...
                                        closest4(3,3)*curArr{3}(closest4(3,1),closest4(3,2),1,day)+...
                                        closest4(4,3)*curArr{3}(closest4(4,1),closest4(4,2),1,day);
                                    narrwoutputvec(dayc-1)=narrw;
                                    if strcmp(daydesc,'cool')
                                        nwovcool(cooldayc-1)=narrw;coolc2=coolc2+1;
                                    elseif strcmp(daydesc,'warm')
                                        nwovwarm(warmdayc-1)=narrw;warmc2=warmc2+1;
                                    else
                                        nwovavg(avgdayc-1)=narrw;avgc2=avgc2+1;
                                    end
                                    %disp('Day and day count');disp(day);disp(dayc-1);
                                end
                            end
                        end
                    end
                    %If doing, prepare to make line graphs of variation over the course of the year
                    if domonthlines==1
                        if size(totmonvec{mon},2)>1
                            totmonvec{mon}=[totmonvec{mon} narrwoutputvec(dayc-monlen:dayc-1)-stnoutputvec(dayc-monlen:dayc-1)];
                        else
                            totmonvec{mon}=[narrwoutputvec(dayc-monlen:dayc-1)-stnoutputvec(dayc-monlen:dayc-1)];
                        end
                        %disp(size(totmonvec{mon}));disp(max(totmonvec{mon}));disp(min(totmonvec{mon}));disp(mon);
                        monbiasvec{stnc,variab,mon}=totmonvec{mon};
                    end
                    totmonc=totmonc+1;
                end
            end
            %Now that computation for this station is done, compute and analyze difference between stn and weighted 
            %NARR vectors (i.e. bias), a series of daily values in deg C
            %Or, show line graphs of variation in bias distribution over the course of the year
            if dojjaonly==1
                monbiasvec{stnc,variab}=narrwoutputvec-stnoutputvec;
                centers=round(min(monbiasvec{stnc,variab})):round(max(monbiasvec{stnc,variab}));
                figure(figc);clf;figc=figc+1;hold on;xlim([centers(1) centers(size(centers,2))]);
                subplot(2,2,1);hist(monbiasvec{stnc,variab},centers);
                title(sprintf('All-Days Bias (NARR-Stn) for JJA Avg Daily T in %s',...
                    prlabels{stnc}),'FontSize',16,'FontWeight','bold');
                monbiasveccool{stnc,variab}=nwovcool-sovcool;
                subplot(2,2,2);hist(monbiasveccool{stnc,variab},centers);
                title(sprintf('Cool-Days Bias (NARR-Stn) for JJA Avg Daily T in %s',...
                    prlabels{stnc}),'FontSize',16,'FontWeight','bold');
                monbiasvecwarm{stnc,variab}=nwovwarm-sovwarm;
                subplot(2,2,3);hist(monbiasvecwarm{stnc,variab},centers);
                title(sprintf('Warm-Days Bias (NARR-Stn) for JJA Avg Daily T in %s',...
                    prlabels{stnc}),'FontSize',16,'FontWeight','bold');
                monbiasvecavg{stnc,variab}=nwovavg-sovavg;
                subplot(2,2,4);hist(monbiasvecavg{stnc,variab},centers);
                title(sprintf('Average-Days Bias (NARR-Stn) for JJA Avg Daily T in %s',...
                    prlabels{stnc}),'FontSize',16,'FontWeight','bold');
            elseif domonthlines==1
                %Percentiles are 5th, 25th, 50th, 75th, and 95th
                %Graphs are for all-days biases only
                figure(figc);clf;figc=figc+1;hold on;x=1:12;colorchoices=[1;3;5;6;7];
                for prctilenum=1:5
                    for i=1:12
                        %define monbiasvecquantile
                        mbvq(stnc,variab,i,prctilenum)=prctile(monbiasvec{stnc,variab,i},prctilestocompute(prctilenum));
                    end
                    plot(x,squeeze(mbvq(stnc,variab,:,prctilenum)),'LineWidth',2,'Color',colorlist{colorchoices(prctilenum)});
                end
                xlim([1 12]);
                title(sprintf('Month-by-Month Biases (NARR-Stn) of Daily T at %s',...
                    prlabels{stnc}),'FontSize',16,'FontWeight','bold');
                legend('5th percentile','25th percentile','50th percentile','75th percentile','95th percentile',...
                    'Location','NorthEastOutside');
            end
        end
    end
end


%Compute and show station map of NARR-stn biases over various subsets of the data
%Considered interpolating stations to the NARR grid but there are too few
%of them for that to be a plausible approach -- and they are also
%heterogeneous so e.g. combining Central Park & JFK muddles the picture
%of what's going on between them (exactly what I don't want to do!)
%Right now: median diff for the warmest 25%, middle 50%, and coolest 25% of days
if showdiffmap==1
    if dojjaonly==1 %had to have computed the right monbiasvec in above loop
        markerlist={'v';'o';'s'};
        categs={'warm';'avg';'cool'};categlbls={'Warm';'Average';'Cool'};
        for variab=1:size(varsdes,1) 
            for categ=1:3
                plotBlankMap(figc,'nyc-area');figc=figc+1;
                for stnc=stniwf:stniwl
                    temp=eval(['monbiasvec' char(categs(categ))]);
                    valuetoplot=quantile(temp{stnc,variab},0.5); %using just the median for each category
                    if valuetoplot<-2 && ~isnan(valuetoplot) %arbitrarily decide what's small and large (in K)
                        mark=markerlist{3};color=colors('blue');
                    elseif valuetoplot>2 && ~isnan(valuetoplot)
                        mark=markerlist{1};color=colors('red');
                    elseif ~isnan(valuetoplot)
                        mark=markerlist{2};color=colors('green');
                    end
                    if ~isnan(valuetoplot)
                        pt1lat=stnlocs(stnc,1);pt1lon=stnlocs(stnc,2);
                        h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker',mark,...
                    'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',11);
                    end
                end
                title(sprintf('%s-Days Bias (NARR-Stn) for JJA Avg Daily T',categlbls{categ}),'FontSize',16,'FontWeight','bold');
            end
        end
    end
end
