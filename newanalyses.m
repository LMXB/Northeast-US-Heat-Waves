%Various analyses as part of the re-imagining of the Master's paper
%Nov & Dec, 2016

%This script builds primarily off of arrays calculated in readnortheastdata, analyzenycdata, and findmaxtwbt
%In other words, it attempts to blend the best of the Master's and overlap papers to get something truly profound (ha!)

%This script requires arrays calculated in readnortheastdata, findmaxtwbt, etc,
%so run loadsavedarrays and loadsavedvariables before proceeding

%First task is to get data for regional heat waves, which are a slightly different set of days than
    %in e.g. reghwdayscl, but which I already calculated in findmaxtwbt

%Runtime options
runningremotely=0;
newsimplenychotdaydefn=0;
stationhws=0; %1 sec
calcstationhwanoms=0; %1 sec -- must be run if plotstnhwanoms is
plotstnhwanoms=0; %10 sec
    plot33daytraces=0;
    plot9daytraces=1;
        actualoranom='stananom';
        plotindivpairs=0;
        plottraditionalway=0;
donarrcompositebydayofhw=0; 
    needtoreload=1; %about 3 min per heat wave, or 1 hr 30 min total
    sstdataonly=1; %15 min
        %both estimates are 3x longer when using SST avg data (and computing anoms) vs using SST anom data to start with
        %however the former is preferred since the latter are suspicious in some areas, e.g. off the coast of Nova Scotia
plotnarrcompositebydayofhw=0;
    plotsst=0; %1 min for non-SST plots, 3 min for SST plots
    regiontoplot='us-ne'; %'globe' or 'us-ne'
calcseabasedcooling=0; %10 min total
    inlandstn=94; %common choices would be 94 (EWR), 71 (PHL), 137 (Concord NH (CON))
    coastalstn=179; %common choices would be 179 (JFK), 70 (ACY), 138 (Portland ME (POR))
    coastalstnposwithinnestns=21; %position of coastal stn within nestns vector
    stnnames='ewrjfk'; %controls both what's calculated in this loop, and what's plotted in the next
sbcanalysis=1; 
    makeboxplot=0; %1 sec
    plotpctofdays=0; %1 sec
    plotinlandstnminussst=0; %1 sec
    plotpctofhours=0; %1 sec
    plotpcthourshwssbc=0; %hourly trace; 10 sec
    donarrcompositehotsbcvshotnonsbc=1; %45 sec per hot day, so about 22 min for May
    plotnarrcompositehotsbcvshotnonsbc=1;
    donarrcompositebysomcateg=0;
    plotnarrcompositebysomcateg=0;
somclusteranalysis=0;
    dosomebasicstats=0; %1 sec
    plotbasicsomstats=0;
    plotbasicsompatterns=0; %30 sec
    computecompositeseachsom=0; %20 sec per month, about 2.5 hr total
    plotcompositeseachsom=0; %15 sec
        vartoplot='gh500';    
ghwbtscatterplot=0; %4 min total for most loops, 45 min for complete section
    dostns=0;
    regtoplot=8;
calctqadvectionacrossaregion=0; %5 min per hw day, about 11 hr total
    %Bottom line on this stuff is that it was a decent idea, but at least with the current
    %NARR definition of advection, it is not defensible enough for inclusion in presentations or posters
    %minlat=38;maxlat=46;minlon=-80;maxlon=-68; %Northeast US
    minlat=31;maxlat=39;minlon=-121;maxlon=-109; %Southwest US
createtqavgs=0; %1 sec
    desreg='sw'; %also controls which region is plotted in plottqadvection
plottqadvection=0; %10 sec
    regtoplot=strcat('us-',desreg,'-small');
    deshw=4;
    desdayofhwiwf=5;desdayofhwiwl=5;
    deshr=7;
coastalcoolingindex=0;
computesstcompositehws=0; %both global and zoomed in to the coast; 5 min total for heat waves, 35 min for hot days
plotsstcompositehws=0; 
    plotusingplotmodeldata=0; %about 8 min using plotModelData, 10 sec otherwise
computeupdatedazrelship=0; %about 1.5 hours
plotupdatedazrelship=0; %actual plotting time: 5 sec
    recomputehwavgs=1; %15 sec
    recomputeclimoavgs=0; %10 min
scatterplottanomwinddir=0; %5 sec
freqofsbcbysomcateg=0; %2 sec
wbtanombysomcateghotdays=0; %1 sec
    repeatcalc=1;
plotneavgmaxandhour=0; %10 sec
    plotavghours=1;
calcseabreezefromdailytracedeviations=0; %abortive
    dostep1=0; %20 sec
    dostep2=1;
sbcstats=0; %10 sec
timeseriessstwbtcompare=0; %5 min
uhimetric=0; %5 sec
annualheatstress=0; %10 sec; at each stn, average annual number of hours with WBT >=25 C
    whattoplot=''; %'','shoulder',or 'peak'
wbtexceed25ssthistogram=0; %10 min
diurnalcycleexamination=0; %1 sec
msaratioanalysis=0; %5 sec



%Other things to set up
yeariwf=1981;yeariwl=2015;
monthiwf=5;monthiwl=9;
monthlengthsdays=[31;30;31;31;30;31];
subplotletters={'a';'b';'c';'d';'e';'f';'g';'h';'i'};
exist figc;if ans==0;figc=1;end
presleveliw=[2;2;4;2;2]; %1-1000 hPa, 4-500 hPa, 2-850 hPa
hours={'8pm';'11pm';'2am';'5am';'8am';'11am';'2pm';'5pm'}; %the 'standard hours'
dailysstfileloc='/Volumes/MacFormatted4TBExternalDrive/NOAA_OISST_Daily_Data/';
dailyanomsstfileloc='/Volumes/MacFormatted4TBExternalDrive/NOAA_OISST_Daily_Anoms/';
curDir='/Users/craymon3/General_Academics/Research/Exploratory_Plots/';
narrmatDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_data_mat/';
narrncDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_data_raw/';


%%%%%Copied over from cluster_code_hgt%%%%
southlatord=40;northlatord=220;
westlonord=55;eastlonord=320;
%Approximate actual limits, as lat/lon -- just used for title and naming purposes, not for any actual calculations
southlat=23;northlat=60;
westlon=-135;eastlon=-55;
%1D vectors of lat & lon, and shrunken 2D arrays that are primarily used when plotting with plotModelData
datalat=0;datalon=0;
datalat=narrlats(southlatord:northlatord,175);
datalon=narrlons(140,westlonord:eastlonord);
narrlatsreduc=narrlats(southlatord:northlatord,westlonord:eastlonord);
narrlonsreduc=narrlons(southlatord:northlatord,westlonord:eastlonord);


%Implement new, simple definition for NYC hot days -- just the ranked top a. 100 and b. 250 days by daily-avg T, WBT, and q
%Use straight avg of EWR, LGA, and JFK
if newsimplenychotdaydefn==1
    nycstns=[94;95;179];nycdailyavgvec=zeros(1,4);
    for var=1:3
        if var==1;finaldata=finaldatat;elseif var==2;finaldata=finaldatawbt;else finaldata=finaldataq;end
        totaldayc=1;
        for relyear=1:35
            dayc=1;
            while 24*dayc+5<=3696 %May 1-Sep 30
                if rem(relyear,4)==0;ly=1;apr30doy=121;else ly=0;apr30doy=120;end
                thisdoy=apr30doy+dayc;
                ewrdailyavg=nanmean(finaldata{relyear,nycstns(1)}(24*dayc-18:24*dayc+5)); %5 adjusts for EST-UTC difference
                lgadailyavg=nanmean(finaldata{relyear,nycstns(2)}(24*dayc-18:24*dayc+5));
                jfkdailyavg=nanmean(finaldata{relyear,nycstns(3)}(24*dayc-18:24*dayc+5));
                nycdailyavg=(ewrdailyavg+lgadailyavg+jfkdailyavg)./3;
                nycdailyavgvec(totaldayc,1)=nycdailyavg;
                nycdailyavgvec(totaldayc,2)=relyear+yeariwf-1;
                nycdailyavgvec(totaldayc,3)=DOYtoMonth(thisdoy,relyear);
                nycdailyavgvec(totaldayc,4)=DOYtoDOM(thisdoy,relyear);
                dayc=dayc+1;totaldayc=totaldayc+1;
            end
        end
        temp=isnan(nycdailyavgvec);nycdailyavgvec(temp)=-99;
        nycdailyavgvec=sortrows(nycdailyavgvec,-1);
        if var==1
            nycdailyavgvect=nycdailyavgvec;
        elseif var==2
            nycdailyavgvecwbt=nycdailyavgvec;
        else
            nycdailyavgvecq=nycdailyavgvec;
        end
    end
    save(strcat(curDir,'newanalyses3'),'nycdailyavgvect','nycdailyavgvecwbt','nycdailyavgvecq','-append');
    
    %Plot some illustrative/motivational figures
    figure(figc);figc=figc+1;
    curpart=1;highqualityfiguresetup;
    plot(squeeze(nycdailyavgvect(1:5247,1)),'r','linewidth',2);hold on;
    plot(squeeze(nycdailyavgvecwbt(1:5247,1)),'g','linewidth',2);
    plot(squeeze(nycdailyavgvecq(1:5247,1)),'b','linewidth',2);
    legend('T','WBT','q');
    xlim([-50 5500]);
    set(gca,'fontsize',16,'fontweight','bold','fontname','arial');
    xlabel('Rank','fontsize',16,'fontweight','bold','fontname','arial');
    ylabel('Value (deg C or g/kg)','fontsize',16,'fontweight','bold','fontname','arial');
    title('Rank vs Value for T, q, and WBT in New York City','fontsize',20,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='newanalysesrankvsvalueall';highqualityfiguresetup;
    
    figure(figc);figc=figc+1;
    curpart=1;highqualityfiguresetup;
    plot(squeeze(nycdailyavgvect(1:200,1)),'r','linewidth',2);hold on;
    plot(squeeze(nycdailyavgvecwbt(1:200,1)),'g','linewidth',2);
    plot(squeeze(nycdailyavgvecq(1:200,1)),'b','linewidth',2);
    legend('T','WBT','q');
    xlim([-5 200]);
    set(gca,'fontsize',16,'fontweight','bold','fontname','arial');
    xlabel('Rank','fontsize',16,'fontweight','bold','fontname','arial');
    ylabel('Value (deg C or g/kg)','fontsize',16,'fontweight','bold','fontname','arial');
    title('Rank vs Value for T, q, and WBT in New York City','fontsize',20,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='newanalysesrankvsvaluetop200';highqualityfiguresetup;
end

%Organize data for (3-to-5-day) station heat waves, which were computed in
    %the findheatwaves loop of readnortheastdata
%The reason this is necessary is that some long heat waves were created when
    %adjacent short heat waves were merged in readnortheastdata
if stationhws==1
    hwregisterbyTshortonly={};
    for stn=1:size(nestns,1)
        newrow=1;
        for row=1:size(hwregisterbyT{stn},1)
            if hwregisterbyT{stn}(row,2)-hwregisterbyT{stn}(row,1)<=4 %i.e. the heat wave is 5 days or shorter
                hwregisterbyTshortonly{stn}(newrow,:)=hwregisterbyT{stn}(row,:);
                newrow=newrow+1;
            end
        end
    end
    save(strcat(curDir,'newanalyses'),'hwregisterbyTshortonly','-append');
end

%Now that this is done, use the pre-calculated station- and month-specific climatologies to get station data for
    %each of these *station-specific* heat waves, and to turn these into anomalies
%Anomalies are relative to each station's climatology for that hour and month
%'Extended' version of tthishw is an hourly trace that goes out to 14 days on either side of hw, principally to see how T and q anoms evolve
%Here, index 1 corresponds to 12 AM LDT on the first day of the heat wave
%All stations are on the East Coast so stntz=5
if calcstationhwanoms==1
    stntz=5;
    tthishw={};qthishw={};tthishwhouranoms={};qthishwhouranoms={};tthishwhourstananoms={};qthishwhourstananoms={};
    ttotalhwavganom={};qtotalhwavganom={};
    for stn=1:size(nestns,1)
    %for stn=6:6
        for hw=1:size(hwregisterbyTshortonly{stn},1)
        %for hw=1:1
            relevanttclimo=0;relevantqclimo=0;
            year=hwregisterbyTshortonly{stn}(hw,3);
            if rem(year,4)==0;may1doy=122;else may1doy=121;end %consider leap years
            hwstartdoy=hwregisterbyTshortonly{stn}(hw,1);
            hwenddoy=hwregisterbyTshortonly{stn}(hw,2);
            hwlength=hwenddoy-hwstartdoy+1;
            if hwlength<=4 % middle day is considered to be day 2
                hwmiddoy=hwstartdoy+1;
            else %middle day is day 3
                hwmiddoy=hwstartdoy+2;
            end
            monthofhw=DOYtoMonth(hwmiddoy,year);relmon=monthofhw-monthiwf+1;
            monlen=monthlengthsdays(monthofhw-monthiwf+1);
            domofhw=DOYtoDOM(hwmiddoy,year);
            if hwlength==3
                tthishw{stn,hw}=finaldatat{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy)*24+stntz-23:(hwenddoy-may1doy+2)*24+stntz);
                qthishw{stn,hw}=finaldataq{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy)*24+stntz-23:(hwenddoy-may1doy+2)*24+stntz);
            elseif hwlength==4
                tthishw{stn,hw}=finaldatat{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+2)*24+stntz);
                qthishw{stn,hw}=finaldataq{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+2)*24+stntz);
            elseif hwlength==5
                tthishw{stn,hw}=finaldatat{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+1)*24+stntz);
                qthishw{stn,hw}=finaldataq{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+1)*24+stntz);
            end

            tthishwextended{stn,hw}=...
                finaldatat{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1-14)*24+stntz-23:(hwenddoy-may1doy+1+14)*24+stntz);
            qthishwextended{stn,hw}=...
                finaldataq{year-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1-14)*24+stntz-23:(hwenddoy-may1doy+1+14)*24+stntz);
            
            %Compute the relevant climatology using the monthly climatologies, but weight-adjusted for the exact
                %date of the heat wave
            %For example, a heat wave at the end of June would be assessed relative to a climatology consisting of
                %approximately 60% June and 40% July
            ratio=domofhw/monlen;
            if ratio<0.5
                othermonthweight=0.5-ratio;othermon=relmon-1;
            elseif ratio>0.5
                othermonthweight=ratio-0.5;othermon=relmon+1;
            end
            thismonthweight=1-othermonthweight;
            relevanttclimounit=thismonthweight.*squeeze(avgthishourofdayandmonth{1}(nestns(stn),relmon,:))+...
                othermonthweight.*squeeze(avgthishourofdayandmonth{1}(nestns(stn),othermon,:));
            relevantqclimounit=thismonthweight.*squeeze(avgthishourofdayandmonth{3}(nestns(stn),relmon,:))+...
                othermonthweight.*squeeze(avgthishourofdayandmonth{3}(nestns(stn),othermon,:));
            relevanttstdevunit=thismonthweight.*squeeze(stdevthishourofdayandmonth{1}(nestns(stn),relmon,:))+...
                othermonthweight.*squeeze(stdevthishourofdayandmonth{1}(nestns(stn),othermon,:));
            relevantqstdevunit=thismonthweight.*squeeze(stdevthishourofdayandmonth{3}(nestns(stn),relmon,:))+...
                othermonthweight.*squeeze(stdevthishourofdayandmonth{3}(nestns(stn),othermon,:));
            relevanttclimo=relevanttclimounit;relevanttclimoextended=relevanttclimounit;
            relevantqclimo=relevantqclimounit;relevantqclimoextended=relevantqclimounit;
            relevanttstdev=relevanttstdevunit;relevanttstdevextended=relevanttstdevunit;
            relevantqstdev=relevantqstdevunit;relevantqstdevextended=relevantqstdevunit;
            for day=2:5
                relevanttclimo=[relevanttclimo;relevanttclimounit];
                relevantqclimo=[relevantqclimo;relevantqclimounit];
                relevanttstdev=[relevanttstdev;relevanttstdevunit];
                relevantqstdev=[relevantqstdev;relevantqstdevunit];
            end
            for day=2:hwlength+28
                relevanttclimoextended=[relevanttclimoextended;relevanttclimounit];
                relevantqclimoextended=[relevantqclimoextended;relevantqclimounit];
                relevanttstdevextended=[relevanttstdevextended;relevanttstdevunit];
                relevantqstdevextended=[relevantqstdevextended;relevantqstdevunit];
            end
            tthishwhouranoms{stn,hw}=tthishw{stn,hw}-relevanttclimo;
            qthishwhouranoms{stn,hw}=qthishw{stn,hw}-relevantqclimo;
            tthishwhourstananoms{stn,hw}=tthishwhouranoms{stn,hw}./relevanttstdev;
            qthishwhourstananoms{stn,hw}=qthishwhouranoms{stn,hw}./relevantqstdev;
            tthishwextendedhouranoms{stn,hw}=tthishwextended{stn,hw}-relevanttclimoextended;
            qthishwextendedhouranoms{stn,hw}=qthishwextended{stn,hw}-relevantqclimoextended;
            tthishwextendedhourstananoms{stn,hw}=tthishwextendedhouranoms{stn,hw}./relevanttstdevextended;
            qthishwextendedhourstananoms{stn,hw}=qthishwextendedhouranoms{stn,hw}./relevantqstdevextended;
        end
        
        %Now, create an average of these hourly traces (both average and anomaly versions) for each station
        dn={'minus2';'minus1';'zero';'plus1';'plus2'}; %day names
        vn={'t';'q'}; %var names
        dhstart=[1;25;49;73;97]; %day start hours
        dhstop=[24;48;72;96;120]; %day stop hours
        for day=1:5
            for var=1:2
                eval(['day' dn{day} 'actualsum' vn{var} '=0;']);
                eval(['day' dn{day} 'anomsum' vn{var} '=0;']);
                eval(['day' dn{day} 'stananomsum' vn{var} '=0;']);
            end
        end
        daysminus14throughminus3anomsumt=0;days3through14anomsumt=0;
        daysminus14throughminus3anomsumq=0;days3through14anomsumq=0;
        daysminus14throughminus3actualsumt=0;days3through14actualsumt=0;
        daysminus14throughminus3actualsumq=0;days3through14actualsumq=0;
        daysminus14throughminus3stananomsumt=0;days3through14stananomsumt=0;
        daysminus14throughminus3stananomsumq=0;days3through14stananomsumq=0;
        
        newhwc=0;
        for hw=1:size(hwregisterbyTshortonly{stn},1)
            hwstartdoy=hwregisterbyTshortonly{stn}(hw,1);
            hwenddoy=hwregisterbyTshortonly{stn}(hw,2);
            hwlength=hwenddoy-hwstartdoy+1;
            for day=1:5
                for var=1:2
                    eval(['day' dn{day} 'anomsum' vn{var} '=day' dn{day} 'anomsum' vn{var} '+'...
                        vn{var} 'thishwhouranoms{stn,hw}(dhstart(day):dhstop(day));']);
                    eval(['day' dn{day} 'actualsum' vn{var} '=day' dn{day} 'actualsum' vn{var} '+'...
                        vn{var} 'thishw{stn,hw}(dhstart(day):dhstop(day));']);
                    eval(['day' dn{day} 'stananomsum' vn{var} '=day' dn{day} 'stananomsum' vn{var} '+'...
                        vn{var} 'thishwhourstananoms{stn,hw}(dhstart(day):dhstop(day));']);
                end
            end
            newhwc=newhwc+1;
            
            %Extended part can just be added up in one big chunk
            daysminus14throughminus3anomsumt=daysminus14throughminus3anomsumt+...
                tthishwextendedhouranoms{stn,hw}(1:14*24);
            days3through14anomsumt=days3through14anomsumt+...
                tthishwextendedhouranoms{stn,hw}((14+hwlength)*24+1:(28+hwlength)*24);
            daysminus14throughminus3actualsumt=daysminus14throughminus3actualsumt+...
                tthishwextended{stn,hw}(1:14*24);
            days3through14actualsumt=days3through14actualsumt+...
                tthishwextended{stn,hw}((14+hwlength)*24+1:(28+hwlength)*24);
            daysminus14throughminus3stananomsumt=daysminus14throughminus3stananomsumt+...
                tthishwextendedhourstananoms{stn,hw}(1:14*24);
            days3through14stananomsumt=days3through14stananomsumt+...
                tthishwextendedhourstananoms{stn,hw}((14+hwlength)*24+1:(28+hwlength)*24);
            daysminus14throughminus3anomsumq=daysminus14throughminus3anomsumq+...
                qthishwextendedhouranoms{stn,hw}(1:14*24);
            days3through14anomsumq=days3through14anomsumq+...
                qthishwextendedhouranoms{stn,hw}((14+hwlength)*24+1:(28+hwlength)*24);
            daysminus14throughminus3actualsumq=daysminus14throughminus3actualsumq+...
                qthishwextended{stn,hw}(1:14*24);
            days3through14actualsumq=days3through14actualsumq+...
                qthishwextended{stn,hw}((14+hwlength)*24+1:(28+hwlength)*24);
            daysminus14throughminus3stananomsumq=daysminus14throughminus3stananomsumq+...
                qthishwextendedhourstananoms{stn,hw}(1:14*24);
            days3through14stananomsumq=days3through14stananomsumq+...
                qthishwextendedhourstananoms{stn,hw}((14+hwlength)*24+1:(28+hwlength)*24);
        end
        for day=1:5
            for var=1:2
                eval(['day' dn{day} 'avganom' vn{var} '=day' dn{day} 'anomsum' vn{var}...
                    './(newhwc);']);
                eval(['day' dn{day} 'avgactual' vn{var} '=day' dn{day} 'actualsum' vn{var}...
                    './(newhwc);']);
                eval(['day' dn{day} 'avgstananom' vn{var} '=day' dn{day} 'stananomsum' vn{var}...
                    './(newhwc);']);
            end
        end     

        daysminus14throughminus3avganomt=daysminus14throughminus3anomsumt./(size(hwregisterbyTshortonly{stn},1));
        days3through14avganomt=days3through14anomsumt./(size(hwregisterbyTshortonly{stn},1));
        daysminus14throughminus3avgactualt=daysminus14throughminus3actualsumt./(size(hwregisterbyTshortonly{stn},1));
        days3through14avgactualt=days3through14actualsumt./(size(hwregisterbyTshortonly{stn},1));
        daysminus14throughminus3avgstananomt=daysminus14throughminus3stananomsumt./(size(hwregisterbyTshortonly{stn},1));
        days3through14avgstananomt=days3through14stananomsumt./(size(hwregisterbyTshortonly{stn},1));
        daysminus14throughminus3avganomq=daysminus14throughminus3anomsumq./(size(hwregisterbyTshortonly{stn},1));
        days3through14avganomq=days3through14anomsumq./(size(hwregisterbyTshortonly{stn},1));
        daysminus14throughminus3avgactualq=daysminus14throughminus3actualsumq./(size(hwregisterbyTshortonly{stn},1));
        days3through14avgactualq=days3through14actualsumq./(size(hwregisterbyTshortonly{stn},1));
        daysminus14throughminus3avgstananomq=daysminus14throughminus3stananomsumq./(size(hwregisterbyTshortonly{stn},1));
        days3through14avgstananomq=days3through14stananomsumq./(size(hwregisterbyTshortonly{stn},1));
        
        ttotalhwavganom{stn}=[dayminus2avganomt;dayminus1avganomt;dayzeroavganomt;dayplus1avganomt;dayplus2avganomt];
        qtotalhwavganom{stn}=[dayminus2avganomq;dayminus1avganomq;dayzeroavganomq;dayplus1avganomq;dayplus2avganomq];
        ttotalhwavgactual{stn}=[dayminus2avgactualt;dayminus1avgactualt;dayzeroavgactualt;dayplus1avgactualt;dayplus2avgactualt];
        qtotalhwavgactual{stn}=[dayminus2avgactualq;dayminus1avgactualq;dayzeroavgactualq;dayplus1avgactualq;dayplus2avgactualq];
        ttotalhwavgstananom{stn}=[dayminus2avgstananomt;dayminus1avgstananomt;...
            dayzeroavgstananomt;dayplus1avgstananomt;dayplus2avgstananomt];
        qtotalhwavgstananom{stn}=[dayminus2avgstananomq;dayminus1avgstananomq;...
            dayzeroavgstananomq;dayplus1avgstananomq;dayplus2avgstananomq];
        
        %Extended version of the arrays grafts on data up to 14 days before and after the heat wave itself
        ttotalhwextendedavganom{stn}=[daysminus14throughminus3avganomt;ttotalhwavganom{stn};days3through14avganomt];
        qtotalhwextendedavganom{stn}=[daysminus14throughminus3avganomq;qtotalhwavganom{stn};days3through14avganomq];
        ttotalhwextendedavgactual{stn}=[daysminus14throughminus3avgactualt;ttotalhwavgactual{stn};days3through14avgactualt];
        qtotalhwextendedavgactual{stn}=[daysminus14throughminus3avgactualq;qtotalhwavgactual{stn};days3through14avgactualq];
        ttotalhwextendedavgstananom{stn}=[daysminus14throughminus3avgstananomt;ttotalhwavgstananom{stn};days3through14avgstananomt];
        qtotalhwextendedavgstananom{stn}=[daysminus14throughminus3avgstananomq;qtotalhwavgstananom{stn};days3through14avgstananomq];
    end
    
    %For the extended anomalies, compute standard deviation at each hour
    doextendedanoms=0;
    if doextendedanoms==1
        temp=zeros(792,1);
        for stn=1:size(nestns,1)
            numhwsthisstn=size(hwregisterbyTshortonly{stn},1);
            holder=NaN.*ones(numhwsthisstn,792);
            for hw=1:numhwsthisstn
                thishwlen=size(tthishwextendedhouranoms{stn,hw},1);
                if thishwlen==792 %5-day heat wave
                    holder(hw,:)=tthishwextendedhouranoms{stn,hw};
                elseif thishwlen==768 %4-day heat wave
                    holder(hw,25:792)=tthishwextendedhouranoms{stn,hw};
                else %3-day heat wave
                    holder(hw,25:768)=tthishwextendedhouranoms{stn,hw};
                end
            end
            for hour=1:792
                temp(hour)=std(holder(:,hour));
            end
            for hour=1:792
                if hour<12
                    thwextendedstdevanom{stn}(hour)=NaN;
                elseif hour<=781
                    thwextendedstdevanom{stn}(hour)=0.01*temp(hour-9)+0.02*temp(hour-8)+0.03*temp(hour-7)+...
                        0.04*temp(hour-6)+0.05*temp(hour-5)+0.06*temp(hour-4)+0.07*temp(hour-3)+...
                        0.08*temp(hour-2)+0.09*temp(hour-1)+0.1*temp(hour)+0.09*temp(hour+1)+...
                        0.08*temp(hour+2)+0.07*temp(hour+3)+0.06*temp(hour+4)+0.05*temp(hour+5)+...
                        0.04*temp(hour+6)+0.03*temp(hour+7)+0.02*temp(hour+8)+0.01*temp(hour+9);
                else
                    thwextendedstdevanom{stn}(hour)=NaN;
                end
            end
        end
        save(strcat(curDir,'newanalyses'),'thwextendedstdevanom','-append');
    end
    
    %Also combine hourly traces into aggregates by coastal and inland stations
    coastagganomt=zeros(120,1);nearcoastagganomt=zeros(120,1);inlandagganomt=zeros(120,1);
    coastagganomq=zeros(120,1);nearcoastagganomq=zeros(120,1);inlandagganomq=zeros(120,1);
    coastaggactualt=zeros(120,1);nearcoastaggactualt=zeros(120,1);inlandaggactualt=zeros(120,1);
    coastaggactualq=zeros(120,1);nearcoastaggactualq=zeros(120,1);inlandaggactualq=zeros(120,1);
    tcoastc=zeros(120,1);tnearcoastc=zeros(120,1);tinlandc=zeros(120,1);
    qcoastc=zeros(120,1);qnearcoastc=zeros(120,1);qinlandc=zeros(120,1);
    for stn=1:size(nestns,1)
        if closetocoast(stn)==1 %immediately on the coast
            for hour=1:120
                if ~isnan(ttotalhwavganom{stn}(hour))
                    coastagganomt(hour)=coastagganomt(hour)+ttotalhwavganom{stn}(hour);
                    tcoastc(hour)=tcoastc(hour)+1;
                end
                if ~isnan(qtotalhwavganom{stn}(hour))
                    coastagganomq(hour)=coastagganomq(hour)+qtotalhwavganom{stn}(hour);
                    qcoastc(hour)=qcoastc(hour)+1;
                end
                if ~isnan(ttotalhwavgactual{stn}(hour))
                    coastaggactualt(hour)=coastaggactualt(hour)+ttotalhwavgactual{stn}(hour);
                    tcoastc(hour)=tcoastc(hour)+1;
                end
                if ~isnan(qtotalhwavgactual{stn}(hour))
                    coastaggactualq(hour)=coastaggactualq(hour)+qtotalhwavgactual{stn}(hour);
                    qcoastc(hour)=qcoastc(hour)+1;
                end
            end
        elseif closetocoast(stn)==0 %relatively close to coast
            for hour=1:120
                if ~isnan(ttotalhwavganom{stn}(hour))
                    nearcoastagganomt(hour)=nearcoastagganomt(hour)+ttotalhwavganom{stn}(hour);
                    tnearcoastc(hour)=tnearcoastc(hour)+1;
                end
                if ~isnan(qtotalhwavganom{stn}(hour))
                    nearcoastagganomq(hour)=nearcoastagganomq(hour)+qtotalhwavganom{stn}(hour);
                    qnearcoastc(hour)=qnearcoastc(hour)+1;
                end
                if ~isnan(ttotalhwavgactual{stn}(hour))
                    nearcoastaggactualt(hour)=nearcoastaggactualt(hour)+ttotalhwavgactual{stn}(hour);
                    tnearcoastc(hour)=tnearcoastc(hour)+1;
                end
                if ~isnan(qtotalhwavgactual{stn}(hour))
                    nearcoastaggactualq(hour)=nearcoastaggactualq(hour)+qtotalhwavgactual{stn}(hour);
                    qnearcoastc(hour)=qnearcoastc(hour)+1;
                end
            end
        elseif closetocoast(stn)==-1 %far inland (>100 km)
            for hour=1:120
                if ~isnan(ttotalhwavganom{stn}(hour))
                    inlandagganomt(hour)=inlandagganomt(hour)+ttotalhwavganom{stn}(hour);
                    tinlandc(hour)=tinlandc(hour)+1;
                end
                if ~isnan(qtotalhwavganom{stn}(hour))
                    inlandagganomq(hour)=inlandagganomq(hour)+qtotalhwavganom{stn}(hour);
                    qinlandc(hour)=qinlandc(hour)+1;
                end
                if ~isnan(ttotalhwavgactual{stn}(hour))
                    inlandaggactualt(hour)=inlandaggactualt(hour)+ttotalhwavgactual{stn}(hour);
                    tinlandc(hour)=tinlandc(hour)+1;
                end
                if ~isnan(qtotalhwavgactual{stn}(hour))
                    inlandaggactualq(hour)=inlandaggactualq(hour)+qtotalhwavgactual{stn}(hour);
                    qinlandc(hour)=qinlandc(hour)+1;
                end
            end
        end
    end
    coastagganomt=coastagganomt./tcoastc;coastagganomq=coastagganomq./qcoastc;
    nearcoastagganomt=nearcoastagganomt./tnearcoastc;nearcoastagganomq=nearcoastagganomq./qnearcoastc;
    inlandagganomt=inlandagganomt./tinlandc;inlandagganomq=inlandagganomq./qinlandc;
    coastaggactualt=coastaggactualt./tcoastc;coastaggactualq=coastaggactualq./qcoastc;
    nearcoastaggactualt=nearcoastaggactualt./tnearcoastc;nearcoastaggactualq=nearcoastaggactualq./qnearcoastc;
    inlandaggactualt=inlandaggactualt./tinlandc;inlandaggactualq=inlandaggactualq./qinlandc;
end


if plotstnhwanoms==1
    %5 days only (i.e. just the heat waves themselves)
    figure(figc);figc=figc+1;hold on;
    for stn=1:size(nestns,1)
        colorholder=varycolor(size(nestns,1));
        plot(ttotalhwavgstananom{stn},'color',colorholder(stn,:));
    end
    
    %33-day period surrounding each heat wave (5 days + 14 days before + 14 days after)
    if plot33daytraces==1
        %1. Plot T
        figure(figc);figc=figc+1;hold on;
        curpart=1;highqualityfiguresetup;
        for stn=1:size(nestns,1)
            plot(ttotalhwextendedavganom{stn},'color',colorholder(stn,:),'linewidth',1.5);
        end
        %Add dashed lines marking the edge of the 5-day heat waves
        %midpoint (noon of day 0) is hour 396
        hwstartlinex=(396-2.5*24)*ones(50,1);hwstartliney=-5:15/49:10;
        scatter(hwstartlinex,hwstartliney,'filled','r');
        hwendlinex=(396+2.5*24)*ones(50,1);hwendliney=-5:15/49:10;
        scatter(hwendlinex,hwendliney,'filled','r');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        set(gca,'xtick',12:96:33*24);
        set(gca,'xticklabel',{'Day -16';'Day -12';'Day -8';'Day -4';'Day 0';'Day 4';'Day 8';'Day 12';'Day 16'},...
            'fontsize',14,'fontweight','bold','fontname','arial');
        ylabel('Temperature Anomaly (deg C)','fontsize',16,'fontweight','bold','fontname','arial');
        xlabel('Date, Centered on Heat Wave','fontsize',16,'fontweight','bold','fontname','arial');
        title('Hourly Temperatures Two Weeks Before and After Heat Waves',...
            'fontsize',20,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname='hourlyttrace33days';highqualityfiguresetup;

        %2. Plot q
        figure(figc);figc=figc+1;hold on;
        curpart=1;highqualityfiguresetup;
        for stn=1:size(nestns,1)
            plot(qtotalhwextendedavganom{stn},'color',colorholder(stn,:),'linewidth',1.5);
        end
        %Add dashed lines marking the edge of the 5-day heat waves
        %midpoint (noon of day 0) is hour 396
        hwstartlinex=(396-2.5*24)*ones(50,1);hwstartliney=-5:15/49:10;
        scatter(hwstartlinex,hwstartliney,'filled','r');
        hwendlinex=(396+2.5*24)*ones(50,1);hwendliney=-5:15/49:10;
        scatter(hwendlinex,hwendliney,'filled','r');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        set(gca,'xtick',12:96:33*24);
        set(gca,'xticklabel',{'Day -16';'Day -12';'Day -8';'Day -4';'Day 0';'Day 4';'Day 8';'Day 12';'Day 16'},...
            'fontsize',14,'fontweight','bold','fontname','arial');
        ylabel('Specific-Humidity Anomaly (g/kg)','fontsize',16,'fontweight','bold','fontname','arial');
        xlabel('Date, Centered on Heat Wave','fontsize',16,'fontweight','bold','fontname','arial');
        title('Hourly Specific Humidity Two Weeks Before and After Heat Waves',...
            'fontsize',20,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname='hourlyqtrace33days';highqualityfiguresetup;
    end
    
    %Plot a shorter version of these traces for some coastal-inland pairs of stations, to better
    %capture differences between individual stations
    if plot9daytraces==1
        tsumstn1=zeros(216,1);tsumstn2=zeros(216,1);
        qsumstn1=zeros(216,1);qsumstn2=zeros(216,1);
        if strcmp(actualoranom,'anom')
            titlepart='Anomalies';labelpart='Anomaly';fignamepart='anom';tunits='(deg C)';qunits='(g/kg)';
            ttotalextended=ttotalhwextendedavganom;
            qtotalextended=qtotalhwextendedavganom;
        elseif strcmp(actualoranom,'actual')
            titlepart='Values';labelpart='Value';fignamepart='actual';tunits='(deg C)';qunits='(g/kg)';
            ttotalextended=ttotalhwextendedavgactual;
            qtotalextended=qtotalhwextendedavgactual;
        elseif strcmp(actualoranom,'stananom')
            titlepart='Standardized Anomalies';labelpart='Standardized Anomaly';fignamepart='stananom';tunits='';qunits='';
            ttotalextended=ttotalhwextendedavgstananom;
            qtotalextended=qtotalhwextendedavgstananom;
        end
        %Get data for selected coastal/near-coastal pairs, and average to compare coastal vs near-coastal
        for pair=1:3
            if plotindivpairs==1
                figure(figc);clf;figc=figc+1;hold on;
                curpart=1;highqualityfiguresetup;
                if pair==1
                    stn1=6;stn2=21;fignamepart='ewrjfk'; %Newark & JFK
                elseif pair==2
                    stn1=3;stn2=2;fignamepart='phlacy'; %Philadelphia & Atlantic City
                elseif pair==3
                    stn=18;stn2=19;fignamepart='conpor'; %Concord & Portland
                end
            
                plot(ttotalextended{stn1}(288:503),'color','r','linewidth',1.5);
                tsumstn1=tsumstn1+ttotalextended{stn1}(288:503);
                plot(ttotalextended{stn2}(288:503),'color','b','linewidth',1.5);
                tsumstn2=tsumstn2+ttotalextended{stn2}(288:503);
                qsumstn1=qsumstn1+qtotalextended{stn1}(288:503);
                qsumstn2=qsumstn2+qtotalextended{stn2}(288:503);
                curpart=2;figloc=curDir;figname=strcat('9daytraces',fignamepart);highqualityfiguresetup;
                clf;
            end
        end
        tavgstnset1=tsumstn1./3;tavgstnset2=tsumstn2./3;
        qavgstn1=qsumstn1./3;qavgstn2=qsumstn2./3;
        
        %Get data for all other stations, to have a third thing to compare to
        tsumallother=zeros(216,1);qsumallother=zeros(216,1);
        for stn=1:size(nestns,1)
            if stn~=2 && stn~=3 && stn~=6 && stn~=18 && stn~=19 && stn~=21
                tsumallother=tsumallother+ttotalextended{stn}(288:503);
                qsumallother=qsumallother+qtotalextended{stn}(288:503);
            end
        end
        tavgallother=tsumallother./15;
        qavgallother=qsumallother./15;
        
        %Also save and smooth data for each station, in case it's wanted
        for stn=1:size(nestns,1)
            tavgbystn{stn}=ttotalextended{stn}(288:503);
            qavgbystn{stn}=qtotalextended{stn}(288:503);
        end
        
        %Smooth the traces
        for i=3:214
            tavgstnset1(i)=0.1*tavgstnset1(i-2)+0.2*tavgstnset1(i-1)+0.4*tavgstnset1(i)+0.2*tavgstnset1(i+1)+0.1*tavgstnset1(i+2);
            tavgstnset2(i)=0.1*tavgstnset2(i-2)+0.2*tavgstnset2(i-1)+0.4*tavgstnset2(i)+0.2*tavgstnset2(i+1)+0.1*tavgstnset2(i+2);
            tavgallother(i)=0.1*tavgallother(i-2)+0.2*tavgallother(i-1)+0.4*tavgallother(i)+0.2*tavgallother(i+1)+0.1*tavgallother(i+2);
            qavgstn1(i)=0.1*qavgstn1(i-2)+0.2*qavgstn1(i-1)+0.4*qavgstn1(i)+0.2*qavgstn1(i+1)+0.1*qavgstn1(i+2);
            qavgstn2(i)=0.1*qavgstn2(i-2)+0.2*qavgstn2(i-1)+0.4*qavgstn2(i)+0.2*qavgstn2(i+1)+0.1*qavgstn2(i+2); 
            qavgallother(i)=0.1*qavgallother(i-2)+0.2*qavgallother(i-1)+0.4*qavgallother(i)+0.2*qavgallother(i+1)+0.1*qavgallother(i+2);
            for stn=1:size(nestns,1)
                tavgbystn{stn}(i)=0.1*tavgbystn{stn}(i-2)+0.2*tavgbystn{stn}(i-1)+0.4*tavgbystn{stn}(i)+...
                    0.2*tavgbystn{stn}(i+1)+0.1*tavgbystn{stn}(i+2);
                qavgbystn{stn}(i)=0.1*qavgbystn{stn}(i-2)+0.2*qavgbystn{stn}(i-1)+0.4*qavgbystn{stn}(i)+...
                    0.2*qavgbystn{stn}(i+1)+0.1*qavgbystn{stn}(i+2);
            end
        end
        tavgstnset1(1:2)=NaN.*ones(2,1);tavgstnset2(1:2)=NaN.*ones(2,1);
        tavgstnset1(215:216)=NaN.*ones(2,1);tavgstnset2(215:216)=NaN.*ones(2,1);
        tavgallother(215:216)=NaN.*ones(2,1);tavgallother(215:216)=NaN.*ones(2,1);
        qavgstn1(1:2)=NaN.*ones(2,1);qavgstn2(1:2)=NaN.*ones(2,1);
        qavgstn1(215:216)=NaN.*ones(2,1);qavgstn2(215:216)=NaN.*ones(2,1);
        qavgallother(215:216)=NaN.*ones(2,1);qavgallother(215:216)=NaN.*ones(2,1);
        for stn=1:size(nestns,1)
            tavgbystn{stn}(1:2)=NaN.*ones(2,1);tavgbystn{stn}(215:216)=NaN.*ones(2,1);
            qavgbystn{stn}(1:2)=NaN.*ones(2,1);qavgbystn{stn}(215:216)=NaN.*ones(2,1);
        end
        
        %Plot either T or q
        if plottraditionalway==1 %straight-up lines
            figure(figc);figc=figc+1;hold on;
            curpart=1;highqualityfiguresetup;
            plot(qavgstn1,'color','r','linewidth',1.5);
            plot(qavgstn2,'color','b','linewidth',1.5);
            xlim([1 216]);
            for xval=24:24:192
                X=[xval xval];Y=[-0.5 2];line(X,Y,'color','k','linestyle',':');
            end
            timesforlabels={'12 AM, Day -4';'12 PM, Day -4';'12 AM, Day -3';'12 PM, Day -3';'12 AM, Day -2';'12 PM, Day -2';'12 AM, Day -1';...
                '12 PM, Day -1';'12 AM, Day 0';'12 PM, Day 0';'12 AM, Day 1';'12 PM, Day 1';'12 AM, Day 2';...
                '12 PM, Day 2';'12 AM, Day 3';'12 PM, Day 3';'12 AM, Day 4';'12 PM, Day 4';'12 AM, Day 5'};
            set(gca,'xtick',0:12:216);set(gca,'XTickLabel',timesforlabels,'fontname','arial','fontweight','bold','fontsize',14);
            xticklabel_rotate([],45,[],'fontsize',12,'fontname','arial','fontweight','bold');
            title(strcat(['Specific-Humidity ',titlepart,' Surrounding Heat Waves, Coastal vs Inland Stations']),...
                'fontsize',18,'fontweight','bold','fontname','arial');
            ylabel(strcat(['Hourly ',labelpart,' ',qunits]),'fontsize',14,'fontweight','bold','fontname','arial');
            curpart=2;figloc=curDir;figname=strcat('9dayqtraces3pairs',fignamepart);highqualityfiguresetup;
        else %shaded areas for the 3 regions: coastal, near-coastal, and inland
            %Min & max value for each hour among each set of stations
            mintvalthishourinland=1000.*ones(216,1);maxtvalthishourinland=zeros(216,1);
            minqvalthishourinland=1000.*ones(216,1);maxqvalthishourinland=zeros(216,1);
            for hour=1:216
                mintvalthishourcoastal(hour)=min([tavgbystn{2}(hour),tavgbystn{19}(hour),tavgbystn{21}(hour)]);
                maxtvalthishourcoastal(hour)=max([tavgbystn{2}(hour),tavgbystn{19}(hour),tavgbystn{21}(hour)]);
                mintvalthishournearcoastal(hour)=min([tavgbystn{3}(hour),tavgbystn{6}(hour),tavgbystn{18}(hour)]);
                maxtvalthishournearcoastal(hour)=max([tavgbystn{3}(hour),tavgbystn{6}(hour),tavgbystn{18}(hour)]);
                minqvalthishourcoastal(hour)=min([qavgbystn{2}(hour),qavgbystn{19}(hour),qavgbystn{21}(hour)]);
                maxqvalthishourcoastal(hour)=max([qavgbystn{2}(hour),qavgbystn{19}(hour),qavgbystn{21}(hour)]);
                minqvalthishournearcoastal(hour)=min([qavgbystn{3}(hour),qavgbystn{6}(hour),qavgbystn{18}(hour)]);
                maxqvalthishournearcoastal(hour)=max([qavgbystn{3}(hour),qavgbystn{6}(hour),qavgbystn{18}(hour)]);
                for stn=1:size(nestns,1)
                    if stn~=2 && stn~=3 && stn~=6 && stn~=18 && stn~=19 && stn~=21
                        if ~isnan(tavgbystn{stn}(hour))
                            %disp(mintvalthishourinland(hour));
                            mintvalthishourinland(hour)=min(mintvalthishourinland(hour),tavgbystn{stn}(hour));
                            maxtvalthishourinland(hour)=max(maxtvalthishourinland(hour),tavgbystn{stn}(hour));
                        end
                        if ~isnan(qavgbystn{stn}(hour))
                            minqvalthishourinland(hour)=min(minqvalthishourinland(hour),qavgbystn{stn}(hour));
                            maxqvalthishourinland(hour)=max(maxqvalthishourinland(hour),qavgbystn{stn}(hour));
                        end
                    end
                end
            end
            temp=abs(mintvalthishourinland)>100;mintvalthishourinland(temp)=NaN;
            temp=abs(minqvalthishourinland)>100;minqvalthishourinland(temp)=NaN;  
   
            %Plot shaded areas for the 3 regions
            figure(figc);figc=figc+1;hold on;
            curpart=1;highqualityfiguresetup;
            x=3:214;
            y1=mintvalthishourcoastal(3:214);
            y2=maxtvalthishourcoastal(3:214);
            shadebetweencurves(x,y1,y2,'b');hold on;
            y1=mintvalthishournearcoastal(3:214);
            y2=maxtvalthishournearcoastal(3:214);
            shadebetweencurves(x,y1,y2,colors('bright red'));
            for xval=24:24:192
                X=[xval xval];Y=[-0.5 2.5];line(X,Y,'color','k','linestyle',':','linewidth',2);
            end
            title(strcat(['Range of Average Temperature ',titlepart,' Surrounding Heat Waves']),...
                'fontsize',20,'fontweight','bold','fontname','arial');
            set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
            xlim([1 216]);
            timesforlabels={'12 AM, Day -4';'12 PM, Day -4';'12 AM, Day -3';'12 PM, Day -3';'12 AM, Day -2';'12 PM, Day -2';'12 AM, Day -1';...
                '12 PM, Day -1';'12 AM, Day 0';'12 PM, Day 0';'12 AM, Day 1';'12 PM, Day 1';'12 AM, Day 2';...
                '12 PM, Day 2';'12 AM, Day 3';'12 PM, Day 3';'12 AM, Day 4';'12 PM, Day 4';'12 AM, Day 5'};
            set(gca,'xtick',0:12:216);set(gca,'XTickLabel',timesforlabels,'fontname','arial','fontweight','bold','fontsize',14);
            xticklabel_rotate([],45,[],'fontsize',12,'fontname','arial','fontweight','bold');
            ylabel(strcat([labelpart,' ',tunits]),'fontsize',14,'fontweight','bold','fontname','arial');
            legend({'Coastal (3 stns)';'Nearby Inland (3 stns)'});
            curpart=2;figloc=curDir;figname=strcat('9daysttracespairsspread',fignamepart);highqualityfiguresetup;
            
            figure(figc);figc=figc+1;hold on;
            curpart=1;highqualityfiguresetup;
            x=3:214;
            y1=minqvalthishourcoastal(3:214);
            y2=maxqvalthishourcoastal(3:214);
            shadebetweencurves(x,y1,y2,'b');hold on;
            y1=minqvalthishournearcoastal(3:214);
            y2=maxqvalthishournearcoastal(3:214);
            shadebetweencurves(x,y1,y2,colors('bright red'));
            for xval=24:24:192
                X=[xval xval];Y=[-0.5 2];line(X,Y,'color','k','linestyle',':','linewidth',2);
            end
            title(strcat(['Range of Average Specific-Humidity ',titlepart,' Surrounding Heat Waves']),...
                'fontsize',20,'fontweight','bold','fontname','arial');
            set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
            xlim([1 216]);
            timesforlabels={'12 AM, Day -4';'12 PM, Day -4';'12 AM, Day -3';'12 PM, Day -3';'12 AM, Day -2';'12 PM, Day -2';'12 AM, Day -1';...
                '12 PM, Day -1';'12 AM, Day 0';'12 PM, Day 0';'12 AM, Day 1';'12 PM, Day 1';'12 AM, Day 2';...
                '12 PM, Day 2';'12 AM, Day 3';'12 PM, Day 3';'12 AM, Day 4';'12 PM, Day 4';'12 AM, Day 5'};
            set(gca,'xtick',0:12:216);set(gca,'XTickLabel',timesforlabels,'fontname','arial','fontweight','bold','fontsize',14);
            xticklabel_rotate([],45,[],'fontsize',12,'fontname','arial','fontweight','bold');
            ylabel(strcat([labelpart,' ',qunits]),'fontsize',14,'fontweight','bold','fontname','arial');
            legend({'Coastal (3 stns)';'Nearby Inland (3 stns)'});
            curpart=2;figloc=curDir;figname=strcat('9daysqtracespairsspread',fignamepart);highqualityfiguresetup;
            
        end
    end
end

%Using the heat waves defined by reghwdoys **OR** NYC hot days, compute NARR composites of major variables for first, middle, and last days of heat waves
%Unlike in some other subsections, refine the definition of middle vs last to have e.g. the third day be a last day if hwlen==3, 
    %but a middle day if hwlen==5
%%%% If it is desired to compute only one or two variables, use the script "temporary" that consists of
    %copy-and-pasted selected lines from this loop, and is therefore the same but nice and lean
%%%% %hw comments are those that are necessary to run this script using heat waves, rather than NYC hot days 
if donarrcompositebydayofhw==1
    %hwdayposcategc=zeros(3,1);
    dayposcategc=0;
    narrt850arrayanomhwdays={};narrq850arrayanomhwdays={};narrwbt850arrayanomhwdays={};
    narrgh500arrayanomhwdays={};narruwnd850arrayanomhwdays={};narrvwnd850arrayanomhwdays={};
    oisstarrayanomhwdays={};narrwinddir850arrayavganomhwdays={};narrwindspeed850arrayavganomhwdays={};
    %hwfor hw=1:size(reghwdoys,2)-1
    for hw=1:100 %not actually a heat wave, but rather a list of NYC hot days
        fprintf('current hw is %d\n',hw);
        %hwhwlen=size(reghwdoys{hw},1);
        %hwfor day=1:hwlen
            %hwfprintf('current day within hw is %d\n',day);
            %hwif hwlen==3
            %hw    if day==1;daypos='first';elseif day==2;daypos='middle';else daypos='last';end
            %hwelseif hwlen==4
            %hw    if day==1;daypos='first';elseif day==2 || day==3;daypos='middle';else daypos='last';end
            %hwelseif hwlen==5
            %hw    if day==1;daypos='first';elseif day==2 || day==3 || day==4;daypos='middle';else daypos='last';end
            %hwend
            %hwdoy=reghwdoys{hw}(day,1);
            %hwyear=reghwdoys{hw}(day,2);
            %hwmonth=DOYtoMonth(doy,year);
            day=1; %when running with NYC hot days only, this is a meaningless index
            doy=DatetoDOY(nycdailyavgvect(hw,3),nycdailyavgvect(hw,4),nycdailyavgvect(hw,2));
            year=nycdailyavgvect(hw,2);
            month=nycdailyavgvect(hw,3);
            dom=DOYtoDOM(doy,year);
            if rem(year,4)==0;ly=1;else ly=0;end
            if year>=1982 && year<=2014
                fprintf('Current year,month,dom are %d,%d,%d\n',year,month,dom);
                %hwfprintf('Daypos is %s\n',daypos);

                doyminus2=doy-2;monthminus2=DOYtoMonth(doyminus2,year);domminus2=DOYtoDOM(doyminus2,year);
                doyplus2=doy-2;monthplus2=DOYtoMonth(doyplus2,year);domplus2=DOYtoDOM(doyplus2,year);
                %hwif day==1 %if it's the first day of a hw, also get data for 20, 10, and 5 days before
                    doyminus5=doy-5;monthminus5=DOYtoMonth(doyminus5,year);domminus5=DOYtoDOM(doyminus5,year);
                    doyminus10=doy-10;monthminus10=DOYtoMonth(doyminus10,year);domminus10=DOYtoDOM(doyminus10,year);
                    doyminus20=doy-20;monthminus20=DOYtoMonth(doyminus20,year);domminus20=DOYtoDOM(doyminus20,year);
                %hwelseif day==hwlen %if it's the last day of a hw, also get data for 5, 10, and 20 days after
                    doyplus5=doy+5;monthplus5=DOYtoMonth(doyplus5,year);domplus5=DOYtoDOM(doyplus5,year);
                    doyplus10=doy+10;monthplus10=DOYtoMonth(doyplus10,year);domplus10=DOYtoDOM(doyplus10,year);
                    doyplus20=doy+20;monthplus20=DOYtoMonth(doyplus20,year);domplus20=DOYtoDOM(doyplus20,year);
                %hwend

                %hwif day~=1 && day~=hwlen && month==prevmonth && year==prevyear;needtoreload=0;else needtoreload=1;end
                needtoreload=1;
                %fprintf('needtoreload is %d\n',needtoreload);
                if needtoreload==1
                    %dailyanomsstfile=ncread(strcat(dailyanomsstfileloc,'sst.day.anom.',num2str(year),'.v2.nc'),'anom');
                    %daystosubtract=0;
                    dailyavgsstfilehalf1=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',...
                        num2str(year),'0101-',num2str(year),'0630.nc'),'tos');
                    dailyavgsstfilehalf2=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',...
                        num2str(year),'0701-',num2str(year),'1231.nc'),'tos');
                    if rem(year,4)==0;ly=1;else ly=0;end
                    dailyanomsstfilehalf1=dailyavgsstfilehalf1(:,:,1:181)-273.15-fullyearavgdailysst(:,:,1:181);
                    dailyanomsstfilehalf2=dailyavgsstfilehalf2-273.15-fullyearavgdailysst(:,:,182:365);
                    
                    if ~sstdataonly==1
                        tfile=load(strcat(narrmatDir,'air/',num2str(year),'/air_',num2str(year),'_0',num2str(month),'_01.mat'));
                        tdata=eval(['tfile.air_' num2str(year) '_0' num2str(month) '_01;']);
                        tdata=squeeze(tdata{3}(:,:,2,:));clear tfile;
                        shumfile=load(strcat(narrmatDir,'shum/',num2str(year),'/shum_',num2str(year),'_0',num2str(month),'_01.mat'));
                        shumdata=eval(['shumfile.shum_' num2str(year) '_0' num2str(month) '_01;']);
                        shumdata=squeeze(shumdata{3}(:,:,2,:));clear shumfile;
                        ghfile=load(strcat(narrmatDir,'hgt/',num2str(year),'/hgt_',num2str(year),'_0',num2str(month),'_01.mat'));
                        ghdata=eval(['ghfile.hgt_' num2str(year) '_0' num2str(month) '_01;']);
                        ghdata=squeeze(ghdata{3}(:,:,4,:));clear ghfile;
                        uwndfile=load(strcat(narrmatDir,'uwnd/',num2str(year),'/uwnd_',num2str(year),'_0',num2str(month),'_01.mat'));
                        uwnddata=eval(['uwndfile.uwnd_' num2str(year) '_0' num2str(month) '_01;']);
                        uwnddata=squeeze(uwnddata{3}(:,:,2,:));clear uwndfile;
                        vwndfile=load(strcat(narrmatDir,'vwnd/',num2str(year),'/vwnd_',num2str(year),'_0',num2str(month),'_01.mat'));
                        vwnddata=eval(['vwndfile.vwnd_' num2str(year) '_0' num2str(month) '_01;']);
                        vwnddata=squeeze(vwnddata{3}(:,:,2,:));clear vwndfile;
                    end
                    if ~sstdataonly==1
                        if day==1 && monthminus20~=month %have to load arrays for previous month too
                            tfile=load(strcat(narrmatDir,'air/',num2str(year),'/air_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                            tdataprevmon=eval(['tfile.air_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                            tdataprevmon=squeeze(tdataprevmon{3}(:,:,2,:));clear tfile;
                            shumfile=load(strcat(narrmatDir,'shum/',num2str(year),'/shum_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                            shumdataprevmon=eval(['shumfile.shum_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                            shumdataprevmon=squeeze(shumdataprevmon{3}(:,:,2,:));clear shumfile;
                            ghfile=load(strcat(narrmatDir,'hgt/',num2str(year),'/hgt_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                            ghdataprevmon=eval(['ghfile.hgt_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                            ghdataprevmon=squeeze(ghdataprevmon{3}(:,:,4,:));clear ghfile;
                            uwndfile=load(strcat(narrmatDir,'uwnd/',num2str(year),'/uwnd_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                            uwnddataprevmon=eval(['uwndfile.uwnd_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                            uwnddataprevmon=squeeze(uwnddataprevmon{3}(:,:,2,:));clear uwndfile;
                            vwndfile=load(strcat(narrmatDir,'vwnd/',num2str(year),'/vwnd_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                            vwnddataprevmon=eval(['vwndfile.vwnd_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                            vwnddataprevmon=squeeze(vwnddataprevmon{3}(:,:,2,:));clear vwndfile;
                        end
                        if day==hwlen && monthplus20~=month %have to load arrays for subsequent month too
                            tfile=load(strcat(narrmatDir,'air/',num2str(year),'/air_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                            tdatanextmon=eval(['tfile.air_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                            tdatanextmon=squeeze(tdatanextmon{3}(:,:,2,:));clear tfile;
                            shumfile=load(strcat(narrmatDir,'shum/',num2str(year),'/shum_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                            shumdatanextmon=eval(['shumfile.shum_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                            shumdatanextmon=squeeze(shumdatanextmon{3}(:,:,2,:));clear shumfile;
                            ghfile=load(strcat(narrmatDir,'hgt/',num2str(year),'/hgt_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                            ghdatanextmon=eval(['ghfile.hgt_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                            ghdatanextmon=squeeze(ghdatanextmon{3}(:,:,4,:));clear ghfile;
                            uwndfile=load(strcat(narrmatDir,'uwnd/',num2str(year),'/uwnd_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                            uwnddatanextmon=eval(['uwndfile.uwnd_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                            uwnddatanextmon=squeeze(uwnddatanextmon{3}(:,:,2,:));clear uwndfile;
                            vwndfile=load(strcat(narrmatDir,'vwnd/',num2str(year),'/vwnd_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                            vwnddatanextmon=eval(['vwndfile.vwnd_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                            vwnddatanextmon=squeeze(vwnddatanextmon{3}(:,:,2,:));clear vwndfile;
                        end
                    end
                end

                %hwif strcmp(daypos,'first');dayposcateg=1;elseif strcmp(daypos,'middle');dayposcateg=2;else dayposcateg=3;end
                %hwdayposcategc(dayposcateg)=dayposcategc(dayposcateg)+1;
                dayposcategc=dayposcategc+1;
                %hwif ~sstdataonly==1
                %hw    narrt850arrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=mean(tdata(:,:,dom*8-7:dom*8),3)-273.15-tclimo850{doy};
                %hw    narrq850arrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=mean(shumdata(:,:,dom*8-7:dom*8),3)-shumclimo850{doy};
                %hw    narrwbt850arrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=...
                %hw        squeeze(calcwbtfromTandshum(squeeze(mean(tdata(:,:,dom*8-7:dom*8),3)-273.15),...
                %hw        squeeze(mean(shumdata(:,:,dom*8-7:dom*8),3)),1))-wbtclimo850{doy};
                %hw    narrgh500arrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=mean(ghdata(:,:,dom*8-7:dom*8),3)-ghclimo500{doy};
                %hw    narruwnd850arrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=mean(uwnddata(:,:,dom*8-7:dom*8),3)-uwndclimo850{doy};
                %hw    narrvwnd850arrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=mean(vwnddata(:,:,dom*8-7:dom*8),3)-vwndclimo850{doy};
                %hwend
                %Same day
                if doy<=181
                    dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                else
                    dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                end
                thisdayobs=dailyanomsstfile(:,:,doy-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                %hwoisstarrayanomhwdays{dayposcateg}(dayposcategc(dayposcateg),:,:)=flipud(thisdayobs');clear thisdayobs;
                oisstarrayanomhwdays{2}(dayposcategc,:,:)=flipud(thisdayobs');clear thisdayobs;
                
                %2 days before
                if doyminus2<=181
                    dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                else
                    dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                end
                thisdayobs=dailyanomsstfile(:,:,doyminus2-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                oisstarrayanomhwdays{1}(dayposcategc,:,:)=flipud(thisdayobs');
                
                %2 days after
                if doyplus2<=181
                    dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                else
                    dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                end
                thisdayobs=dailyanomsstfile(:,:,doyplus2-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                oisstarrayanomhwdays{3}(dayposcategc,:,:)=flipud(thisdayobs');
                
                if day==1
                    %20 days before
                    if ~sstdataonly==1
                        if monthminus20~=month
                            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;ghdatatouse=ghdataprevmon;
                            uwnddatatouse=uwnddataprevmon;vwnddatatouse=vwnddataprevmon;
                        else
                            tdatatouse=tdata;shumdatatouse=shumdata;ghdatatouse=ghdata;
                            uwnddatatouse=uwnddata;vwnddatatouse=vwnddata;
                        end
                        narrt850arrayanomhwdays{4}(dayposcategc(1),:,:)=mean(tdatatouse(:,:,domminus20*8-7:domminus20*8),3)-273.15-tclimo850{doyminus20};
                        narrq850arrayanomhwdays{4}(dayposcategc(1),:,:)=mean(shumdatatouse(:,:,domminus20*8-7:domminus20*8),3)-shumclimo850{doyminus20};
                        narrwbt850arrayanomhwdays{4}(dayposcategc(1),:,:)=...
                            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus20*8-7:domminus20*8),3)-273.15),...
                            squeeze(mean(shumdatatouse(:,:,domminus20*8-7:domminus20*8),3)),1))-wbtclimo850{doyminus20};
                        narrgh500arrayanomhwdays{4}(dayposcategc(1),:,:)=mean(ghdatatouse(:,:,domminus20*8-7:domminus20*8),3)-ghclimo500{doyminus20};
                        narruwnd850arrayanomhwdays{4}(dayposcategc(1),:,:)=mean(uwnddatatouse(:,:,domminus20*8-7:domminus20*8),3)-uwndclimo850{doyminus20};
                        narrvwnd850arrayanomhwdays{4}(dayposcategc(1),:,:)=mean(vwnddatatouse(:,:,domminus20*8-7:domminus20*8),3)-vwndclimo850{doyminus20};
                    end
                    if doyminus20<=181
                        dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                    else
                        dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                    end
                    thisdayobs=dailyanomsstfile(:,:,doyminus20-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                    %hwoisstarrayanomhwdays{4}(dayposcategc(1),:,:)=flipud(thisdayobs');
                    oisstarrayanomhwdays{4}(dayposcategc,:,:)=flipud(thisdayobs');
                    %10 days before
                    if ~sstdataonly==1
                        if monthminus10~=month
                            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;ghdatatouse=ghdataprevmon;
                            uwnddatatouse=uwnddataprevmon;vwnddatatouse=vwnddataprevmon;
                        else
                            tdatatouse=tdata;shumdatatouse=shumdata;ghdatatouse=ghdata;
                            uwnddatatouse=uwnddata;vwnddatatouse=vwnddata;
                        end
                        narrt850arrayanomhwdays{5}(dayposcategc(1),:,:)=mean(tdatatouse(:,:,domminus10*8-7:domminus10*8),3)-273.15-tclimo850{doyminus10};
                        narrq850arrayanomhwdays{5}(dayposcategc(1),:,:)=mean(shumdatatouse(:,:,domminus10*8-7:domminus10*8),3)-shumclimo850{doyminus10};
                        narrwbt850arrayanomhwdays{5}(dayposcategc(1),:,:)=...
                            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus10*8-7:domminus10*8),3)-273.15),...
                            squeeze(mean(shumdatatouse(:,:,domminus10*8-7:domminus10*8),3)),1))-wbtclimo850{doyminus10};
                        narrgh500arrayanomhwdays{5}(dayposcategc(1),:,:)=mean(ghdatatouse(:,:,domminus10*8-7:domminus10*8),3)-ghclimo500{doyminus10};
                        narruwnd850arrayanomhwdays{5}(dayposcategc(1),:,:)=mean(uwnddatatouse(:,:,domminus10*8-7:domminus10*8),3)-uwndclimo850{doyminus10};
                        narrvwnd850arrayanomhwdays{5}(dayposcategc(1),:,:)=mean(vwnddatatouse(:,:,domminus10*8-7:domminus10*8),3)-vwndclimo850{doyminus10};
                    end
                    if doyminus10<=181
                        dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                    else
                        dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                    end
                    thisdayobs=dailyanomsstfile(:,:,doyminus10-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                    %hwoisstarrayanomhwdays{5}(dayposcategc(1),:,:)=flipud(thisdayobs');
                    oisstarrayanomhwdays{5}(dayposcategc,:,:)=flipud(thisdayobs');
                    %5 days before
                    if ~sstdataonly==1
                        if monthminus5~=month
                            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;ghdatatouse=ghdataprevmon;
                            uwnddatatouse=uwnddataprevmon;vwnddatatouse=vwnddataprevmon;
                        else
                            tdatatouse=tdata;shumdatatouse=shumdata;ghdatatouse=ghdata;
                            uwnddatatouse=uwnddata;vwnddatatouse=vwnddata;
                        end
                        narrt850arrayanomhwdays{6}(dayposcategc(1),:,:)=mean(tdatatouse(:,:,domminus5*8-7:domminus5*8),3)-273.15-tclimo850{doyminus5};
                        narrq850arrayanomhwdays{6}(dayposcategc(1),:,:)=mean(shumdatatouse(:,:,domminus5*8-7:domminus5*8),3)-shumclimo850{doyminus5};
                        narrwbt850arrayanomhwdays{6}(dayposcategc(1),:,:)=...
                            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus5*8-7:domminus5*8),3)-273.15),...
                            squeeze(mean(shumdatatouse(:,:,domminus5*8-7:domminus5*8),3)),1))-wbtclimo850{doyminus5};
                        narrgh500arrayanomhwdays{6}(dayposcategc(1),:,:)=mean(ghdatatouse(:,:,domminus5*8-7:domminus5*8),3)-ghclimo500{doyminus5};
                        narruwnd850arrayanomhwdays{6}(dayposcategc(1),:,:)=mean(uwnddatatouse(:,:,domminus5*8-7:domminus5*8),3)-uwndclimo850{doyminus5};
                        narrvwnd850arrayanomhwdays{6}(dayposcategc(1),:,:)=mean(vwnddatatouse(:,:,domminus5*8-7:domminus5*8),3)-vwndclimo850{doyminus5};
                    end
                    if doyminus5<=181
                        dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                    else
                        dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                    end
                    if doyminus5-daystosubtract==182 && ly==1;daystosubtract=6;end
                    thisdayobs=dailyanomsstfile(:,:,doyminus5-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                    %hwoisstarrayanomhwdays{6}(dayposcategc(1),:,:)=flipud(thisdayobs');
                    oisstarrayanomhwdays{6}(dayposcategc,:,:)=flipud(thisdayobs');

                    clear tdataprevmon;clear shumdataprevmon;clear ghdataprevmon;clear uwnddataprevmon;clear vwnddataprevmon;
                %hwelseif day==hwlen
                    %5 days after
                    if ~sstdataonly==1
                        if monthplus5~=month
                            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;ghdatatouse=ghdatanextmon;
                            uwnddatatouse=uwnddatanextmon;vwnddatatouse=vwnddatanextmon;
                        else
                            tdatatouse=tdata;shumdatatouse=shumdata;ghdatatouse=ghdata;
                            uwnddatatouse=uwnddata;vwnddatatouse=vwnddata;
                        end
                        narrt850arrayanomhwdays{7}(dayposcategc(3),:,:)=mean(tdatatouse(:,:,domplus5*8-7:domplus5*8),3)-273.15-tclimo850{doyplus5};
                        narrq850arrayanomhwdays{7}(dayposcategc(3),:,:)=mean(shumdatatouse(:,:,domplus5*8-7:domplus5*8),3)-shumclimo850{doyplus5};
                        narrwbt850arrayanomhwdays{7}(dayposcategc(3),:,:)=...
                            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus5*8-7:domplus5*8),3)-273.15),...
                            squeeze(mean(shumdatatouse(:,:,domplus5*8-7:domplus5*8),3)),1))-wbtclimo850{doyplus5};
                        narrgh500arrayanomhwdays{7}(dayposcategc(3),:,:)=mean(ghdatatouse(:,:,domplus5*8-7:domplus5*8),3)-ghclimo500{doyplus5};
                        narruwnd850arrayanomhwdays{7}(dayposcategc(3),:,:)=mean(uwnddatatouse(:,:,domplus5*8-7:domplus5*8),3)-uwndclimo850{doyplus5};
                        narrvwnd850arrayanomhwdays{7}(dayposcategc(3),:,:)=mean(vwnddatatouse(:,:,domplus5*8-7:domplus5*8),3)-vwndclimo850{doyplus5};
                    end
                    if doyplus5<=181
                        dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                    else
                        dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                    end
                    thisdayobs=dailyanomsstfile(:,:,doyplus5-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                    %hwoisstarrayanomhwdays{7}(dayposcategc(3),:,:)=flipud(thisdayobs');
                    oisstarrayanomhwdays{7}(dayposcategc,:,:)=flipud(thisdayobs');
                    %10 days after
                    if ~sstdataonly==1
                        if monthplus10~=month
                            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;ghdatatouse=ghdatanextmon;
                            uwnddatatouse=uwnddatanextmon;vwnddatatouse=vwnddatanextmon;
                        else
                            tdatatouse=tdata;shumdatatouse=shumdata;ghdatatouse=ghdata;
                            uwnddatatouse=uwnddata;vwnddatatouse=vwnddata;
                        end
                        narrt850arrayanomhwdays{8}(dayposcategc(3),:,:)=mean(tdatatouse(:,:,domplus10*8-7:domplus10*8),3)-273.15-tclimo850{doyplus10};
                        narrq850arrayanomhwdays{8}(dayposcategc(3),:,:)=mean(shumdatatouse(:,:,domplus10*8-7:domplus10*8),3)-shumclimo850{doyplus10};
                        narrwbt850arrayanomhwdays{8}(dayposcategc(3),:,:)=...
                            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus10*8-7:domplus10*8),3)-273.15),...
                            squeeze(mean(shumdatatouse(:,:,domplus10*8-7:domplus10*8),3)),1))-wbtclimo850{doyplus10};
                        narrgh500arrayanomhwdays{8}(dayposcategc(3),:,:)=mean(ghdatatouse(:,:,domplus10*8-7:domplus10*8),3)-ghclimo500{doyplus10};
                        narruwnd850arrayanomhwdays{8}(dayposcategc(3),:,:)=mean(uwnddatatouse(:,:,domplus10*8-7:domplus10*8),3)-uwndclimo850{doyplus10};
                        narrvwnd850arrayanomhwdays{8}(dayposcategc(3),:,:)=mean(vwnddatatouse(:,:,domplus10*8-7:domplus10*8),3)-vwndclimo850{doyplus10};
                    end
                    if doyplus10<=181
                        dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                    else
                        dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                    end
                    thisdayobs=dailyanomsstfile(:,:,doyplus10-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                    %hwoisstarrayanomhwdays{8}(dayposcategc(3),:,:)=flipud(thisdayobs');
                    oisstarrayanomhwdays{8}(dayposcategc,:,:)=flipud(thisdayobs');
                    %20 days after
                    if ~sstdataonly==1
                        if monthplus20~=month
                            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;ghdatatouse=ghdatanextmon;
                            uwnddatatouse=uwnddatanextmon;vwnddatatouse=vwnddatanextmon;
                        else
                            tdatatouse=tdata;shumdatatouse=shumdata;ghdatatouse=ghdata;
                            uwnddatatouse=uwnddata;vwnddatatouse=vwnddata;
                        end
                        narrt850arrayanomhwdays{9}(dayposcategc(3),:,:)=mean(tdatatouse(:,:,domplus20*8-7:domplus20*8),3)-273.15-tclimo850{doyplus20};
                        narrq850arrayanomhwdays{9}(dayposcategc(3),:,:)=mean(shumdatatouse(:,:,domplus20*8-7:domplus20*8),3)-shumclimo850{doyplus20};
                        narrwbt850arrayanomhwdays{9}(dayposcategc(3),:,:)=...
                            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus20*8-7:domplus20*8),3)-273.15),...
                            squeeze(mean(shumdatatouse(:,:,domplus20*8-7:domplus20*8),3)),1))-wbtclimo850{doyplus20};
                        narrgh500arrayanomhwdays{9}(dayposcategc(3),:,:)=mean(ghdatatouse(:,:,domplus20*8-7:domplus20*8),3)-ghclimo500{doyplus20};
                        narruwnd850arrayanomhwdays{9}(dayposcategc(3),:,:)=mean(uwnddatatouse(:,:,domplus20*8-7:domplus20*8),3)-uwndclimo850{doyplus20};
                        narrvwnd850arrayanomhwdays{9}(dayposcategc(3),:,:)=mean(vwnddatatouse(:,:,domplus20*8-7:domplus20*8),3)-vwndclimo850{doyplus20};
                    end
                    if doyplus20<=181
                        dailyanomsstfile=dailyanomsstfilehalf1;daystosubtract=0;
                    else
                        dailyanomsstfile=dailyanomsstfilehalf2;daystosubtract=181;
                    end
                    thisdayobs=dailyanomsstfile(:,:,doyplus20-daystosubtract);temp=abs(thisdayobs)>10^3;thisdayobs(temp)=NaN;
                    %hwoisstarrayanomhwdays{9}(dayposcategc(3),:,:)=flipud(thisdayobs');
                    oisstarrayanomhwdays{9}(dayposcategc,:,:)=flipud(thisdayobs');

                    clear tdatanextmon;clear shumdatanextmon;clear ghdatanextmon;clear uwnddatanextmon;clear vwnddatanextmon;
                end
                fclose('all');
                prevmonth=month;prevyear=year;
            end
        %end
        clear dailyanomsstfile;fclose('all');
    end
    %hwsave(strcat(curDir,'newanalyses2'),'narrt850arrayanomhwdays','narrq850arrayanomhwdays','narrwbt850arrayanomhwdays',...
    %hw    'narrgh500arrayanomhwdays','narruwnd850arrayanomhwdays','narrvwnd850arrayanomhwdays','oisstarrayanomhwdays','-append');

    if ~sstdataonly==1
        for i=1:9;narrt850arrayavganomhwdays{i}=squeeze(mean(narrt850arrayanomhwdays{i},1));end;clear narrt850arrayanomhwdays;
        for i=1:9;narrq850arrayavganomhwdays{i}=squeeze(mean(narrq850arrayanomhwdays{i},1));end;clear narrq850arrayanomhwdays;
        for i=1:9;narrwbt850arrayavganomhwdays{i}=squeeze(mean(narrwbt850arrayanomhwdays{i},1));end;clear narrwbt850arrayanomhwdays;
        for i=1:9;narrgh500arrayavganomhwdays{i}=squeeze(mean(narrgh500arrayanomhwdays{i},1));end;clear narrgh500arrayanomhwdays;
        for i=1:9;narruwnd850arrayavganomhwdays{i}=squeeze(mean(narruwnd850arrayanomhwdays{i},1));end;clear narruwnd850arrayanomhwdays;
        for i=1:9;narrvwnd850arrayavganomhwdays{i}=squeeze(mean(narrvwnd850arrayanomhwdays{i},1));end;clear narrvwnd850arrayanomhwdays;
    end
    for i=1:9;oisstarrayavganomhwdays{i}=double(squeeze(mean(oisstarrayanomhwdays{i},1)));end
    for i=1:9;oisstarraystdevanomhwdays{i}=double(squeeze(std(oisstarrayanomhwdays{i},1)));end
    for i=1:9;for j=1:720;for k=1:1440;if oisstarrayavganomhwdays{i}(j,k)-2*oisstarraystdevanomhwdays{i}(j,k)>0
                    signifarray{i}(j,k)=1;else signifarray{i}(j,k)=0;end;end;end;end
    if ~sstdataonly==1;clear oisstarrayanomhwdays;end
    if ~sstdataonly==1
        for i=1:9
            for j=1:277
                for k=1:349
                    if ~isnan(narruwnd850arrayavganomhwdays{i}(j,k)) && ~isnan(narrvwnd850arrayavganomhwdays{i}(j,k))
                        [narrwinddir850arrayavganomhwdays{i}(j,k),narrwindspeed850arrayavganomhwdays{i}(j,k)]=...
                        cart2compass(narruwnd850arrayavganomhwdays{i}(j,k),narrvwnd850arrayavganomhwdays{i}(j,k));
                    else
                        narrwinddir850arrayavganomhwdays{i}(j,k)=NaN;
                        narrwindspeed850arrayavganomhwdays{i}(j,k)=NaN;
                    end
                end
            end
        end
    end
    save(strcat(curDir,'newanalyses3'),'narrt850arrayavganomhwdays','narrq850arrayavganomhwdays','narrwbt850arrayavganomhwdays',...
        'narrgh500arrayavganomhwdays','narruwnd850arrayavganomhwdays','narrvwnd850arrayavganomhwdays','oisstarrayavganomhwdays',...
        'narrwinddir850arrayavganomhwdays','narrwindspeed850arrayavganomhwdays','-append');
end


%Nice multipanel plots of the above-mentioned arrays
%Manually modify the code below to make the different multipanel figures
if plotnarrcompositebydayofhw==1
    if plotsst==0
        data{1}=narrlats;data{2}=narrlons;
        overlaydata{1}=narrlats;overlaydata{2}=narrlons;
        region='us-ne';
        datatype='NARR';
        figure(figc);figc=figc+1;
        iorder=[4;5;6;1;2;3;7;8;9]; %chronological order, based on how the arrays were defined in the previous loop
        for dummy=1:9
            i=iorder(dummy);
            subplot(3,3,dummy);
            data{3}=narruwnd850arrayavganomhwdays{i};data{4}=narrvwnd850arrayavganomhwdays{i};
            overlaydata{3}=narrwbt850arrayavganomhwdays{i};
            %Wind plots
            %vararginnew={'variable';'wind';'contour';1;'mystep';1;'plotCountries';1;'vectorData';data;...
            %    'caxismin';-4;'caxismax';4;'overlaynow';1;'overlayvariable';'wet-bulb temp';...
            %    'datatooverlay';overlaydata;'anomavg';'anom'};
            %%All other plots
            vararginnew={'variable';'wbt';'contour';1;'plotCountries';1;...
                'caxismin';-4;'caxismax';4;'anomavg';'anom';'overlaynow';1;'vectorData';data;...
                'datatooverlay';overlaydata;'overlayvariable';'temperature'}; %add mystep of 7.5 for gh500
            %    %caxis range -70 to 70 for gh anom, -4.5 to 4.5 for T anom, -4 to 4 for WBT anom
            %data{3}=narrwbt850arrayavganomhwdays{i};
            vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=1;
            [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
                plotModelData(data,region,vararginnew,datatype);
            curpart=1;highqualityfiguresetup;
            colormap(colormaps('wbt','more'));
            text(-0.08,1,strcat(subplotletters{dummy},')'),'units','normalized',...
                'fontsize',14,'fontweight','bold','fontname','arial');
            if dummy<=3;rownow=1;elseif dummy<=6;rownow=2;else rownow=3;end
            if rem(dummy,3)==1;colnow=1;elseif rem(dummy,3)==2;colnow=2;else colnow=3;end
            fprintf('dummy: %d, rownow: %d, colnow: %d\n',dummy,rownow,colnow);
            if colnow==1;colnowpos=0.03;elseif colnow==2;colnowpos=0.32;else colnowpos=0.61;end
            if rownow==1;rownowpos=0.34;elseif rownow==2;rownowpos=0.66;else rownowpos=0.98;end
            set(gca,'Position',[colnowpos 1-rownowpos 0.27 0.27]);
        end
        %title('Composite of 850-hPa WBT Anomalies on Hot T Days, by SOM Category',...
        %    'fontsize',18,'fontweight','bold','fontname','arial');
        cbar=colorbar;
        set(get(cbar,'Ylabel'),'String','Anomaly (m)','FontSize',20,'FontWeight','bold','FontName','Arial');
        set(cbar,'FontSize',20,'FontWeight','bold','FontName','Arial');
        cpos=get(cbar,'Position');cpos(1)=0.9;cpos(2)=0.05;cpos(3)=0.017;cpos(4)=0.9;
        set(cbar,'Position',cpos);
        fignamepart='tempevolcompwbtanomhwdays';
        curpart=2;figloc=curDir;figname=fignamepart;highqualityfiguresetup;

    else
        data{1}=oisstlats;data{2}=oisstlons;
        figure(figc);figc=figc+1;
        iorder=[4;5;6;1;2;3;7;8;9]; %chronological order, based on how the arrays were defined in the previous loop
        curpart=1;highqualityfiguresetup;
        for dummy=1:9
            i=iorder(dummy);
            subplot(3,3,dummy);
            %vararginnew={'variable';'generic scalar';'mystep';1;'contour';1;'plotCountries';1;...
            %    'caxismin';-4;'caxismax';4;'overlaynow';0;'anomavg';'avg'};
            %vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=1;
            %[caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
            %    plotModelData(data,region,vararginnew,datatype);
            if strcmp(regiontoplot,'globe')
                h=imagescnan(oisstarrayavganomhwdays{i}(100:450,:),'NanColor',colors('gray'));
            elseif strcmp(regiontoplot,'us-ne')
                h=imagescnan(oisstarrayavganomhwdays{i}(165:215,1050:1250),'NanColor',colors('gray'));
            else
                disp('Please enter a valid region to plot');return;
            end
            for j=165:215 %only need to do for NE if that's all that's plotted
                for k=1050:1250
                    if signifarray{dummy}(j,k)==1
                        line([j-164 j-164+1],[k-1049 k-1049+1],'linewidth',3,'color','k');
                    end
                end
            end
            caxis([-2 2]);
            colormap(colormaps('sst','more'));
            text(-0.07,1,strcat(subplotletters{dummy},')'),'units','normalized',...
                'fontsize',14,'fontweight','bold','fontname','arial');
            set(gca,'xtick',[]);set(gca,'ytick',[]);
            if dummy<=3;rownow=1;elseif dummy<=6;rownow=2;else rownow=3;end
            if rem(dummy,3)==1;colnow=1;elseif rem(dummy,3)==2;colnow=2;else colnow=3;end
            fprintf('dummy: %d, rownow: %d, colnow: %d\n',dummy,rownow,colnow);
            if colnow==1;colnowpos=0.03;elseif colnow==2;colnowpos=0.32;else colnowpos=0.61;end
            if rownow==1;rownowpos=0.34;elseif rownow==2;rownowpos=0.62;else rownowpos=0.9;end
            set(gca,'Position',[colnowpos 1-rownowpos 0.27 0.22]);
        end
        cbar=colorbar;
        set(get(cbar,'Ylabel'),'String','Anomaly (deg C)','FontSize',20,'FontWeight','bold','FontName','Arial');
        set(cbar,'FontSize',20,'FontWeight','bold','FontName','Arial');
        cpos=get(cbar,'Position');cpos(1)=0.9;cpos(2)=0.05;cpos(3)=0.017;cpos(4)=0.9;
        set(cbar,'Position',cpos);
        fignamepart=strcat('tempevolcompsstanomhwdays',regiontoplot);
        curpart=2;figloc=curDir;figname=fignamepart;highqualityfiguresetup;
        pbaspect([1.4 0.7 1]);
    end
end


%Alternative to the exhaustive sea-breeze calculation in findseabreezes
%Note: Originally written for EWR & JFK, but is now completely generalizable to any pair of stns
    %The stations are chosen in the options settings at the beginning of the script
%Namely, a parameterized 'sea-based-cooling index' that defines NYC sea-based-cooling days as those for which
    %--T at EWR >= T at JFK + 5 for >=3 hours, and
    %--Tmax at EWR >= SST+3
%Then, I added two more conditions:
    %--avg(EWR, JFK wind speed)<10 kt over 8am-11am LST
    %--1-hr increase in q of >=0.001 kg/kg, or decrease in T of >=1 C, at JFK within 11am-7pm LST, 
        %accompanied within an hour by a wind-dir change of >=30 deg
%This is motivated by the apparent unsuitability of the Scandinavian definition for the NE US, as evidenced
    %by its inability to find many sea breezes at all, which may be partially related to the fact that
    %esp. b/c NYC is situated such that sea breezes come from the south, they are hard to detect vis-à-vis the
    %prevailing warm-advecting south/southwesterly winds
if calcseabasedcooling==1
    inlandstntmaxes=NaN.*ones(yeariwl-yeariwf,366);
    inlandstnalltdata=NaN.*ones(yeariwl-yeariwf,366,24);
    coastalstnalltdata=NaN.*ones(yeariwl-yeariwf,366,24);
    coastalstnallqdata=NaN.*ones(yeariwl-yeariwf,366,24);
    dayswithsbcbydoy=NaN.*ones(yeariwl-yeariwf,366);
    nearcoastsst=NaN.*ones(yeariwl-yeariwf,366);
    numhours5ormore=zeros(yeariwl-yeariwf,366);
    inlandstnsstdiffbydoy=NaN.*ones(yeariwl-yeariwf,366);
    hourswithsbcbydoyandhourofday=NaN.*ones(yeariwl-yeariwf,366,24);
    inlandstnsstdiffbydoyandhourofday=NaN.*ones(yeariwl-yeariwf,366,24);
    for year=2:34
        fprintf('Analyzing sea-based cooling for year %d\n',year+yeariwf-1);
        inlandstntdatathisyear=finaldatat{year,inlandstn};
        coastalstntdatathisyear=finaldatat{year,coastalstn};
        coastalstnqdatathisyear=finaldataq{year,coastalstn};
        coastalstnwinddirdatathisyear=finaldatawinddir{year,coastalstn};
        coastalstnwindspeeddatathisyear=finaldatawindspeed{year,coastalstn};
        dayc=1;relevantdoy=121;doy=dayc+relevantdoy-1;
        for midnighthours=6:24:4416-23
            prevdoy=relevantdoy;relevantdoy=round(midnighthours/24)+121;
            %Get hourly data, and also calculate daily maxes, for inland stn for each day May 1-Oct 31
            if sum(isnan(inlandstntdatathisyear(midnighthours:midnighthours+23)))==0 && ...
                   sum(inlandstntdatathisyear(midnighthours:midnighthours+23))~=0 
                inlandstntmaxes(year,doy)=max(inlandstntdatathisyear(midnighthours:midnighthours+23));
                inlandstnalltdata(year,doy,:)=inlandstntdatathisyear(midnighthours:midnighthours+23);
            else
                inlandstntmaxes(year,doy)=NaN;
                inlandstnalltdata(year,doy,:)=NaN.*ones(24,1);
            end
            %Also get hourly data for coastal stn
            if sum(isnan(coastalstntdatathisyear(midnighthours:midnighthours+23)))==0 && ...
                   sum(coastalstntdatathisyear(midnighthours:midnighthours+23))~=0 
                coastalstnalltdata(year,doy,:)=coastalstntdatathisyear(midnighthours:midnighthours+23);
                coastalstnallqdata(year,doy,:)=coastalstnqdatathisyear(midnighthours:midnighthours+23);
                coastalstnallwinddirdata(year,doy,:)=coastalstnwinddirdatathisyear(midnighthours:midnighthours+23);
                coastalstnallwindspeeddata(year,doy,:)=coastalstnwindspeeddatathisyear(midnighthours:midnighthours+23);
            else
                coastalstnalltdata(year,doy,:)=NaN.*ones(24,1);
            end
            
            %Finally, get daily SST value off of the coast for the same set of days
            %Only load files again if it's necessary to do so
            if relevantdoy==121
                dailysstfile=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(year+yeariwf-1),'0101-',...
                    num2str(year+yeariwf-1),'0630.nc'),'tos'); %daily data from Jan 1 to Jun 30
                temp=0;
            elseif relevantdoy>181 && prevdoy<=181
                dailysstfile=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(year+yeariwf-1),'0701-',...
                    num2str(year+yeariwf-1),'1231.nc'),'tos'); %daily data from Jul 1 to Dec 31
                temp=181;
            end
            thisdayobs=dailysstfile(:,:,relevantdoy-temp)-273.15;fclose('all');
            thisdayobs=flipud(thisdayobs');
            
            %daily near-coast SST (gridpt closest to JFK), in C
            nearcoastsst(year,doy)=convlatlontoordforsst(newstnNumListlats(nestns(coastalstnposwithinnestns)),...
                newstnNumListlons(nestns(coastalstnposwithinnestns)),thisdayobs);
            
            dayc=dayc+1;
            doy=dayc+121-1;
        end
        
        %For each day, see if it has "significant sea-based cooling" according to the definition promulgated above
        reqsharptorqchange=0;reqwinddirchange=0;
        for dayc=1:184
            doy=dayc+121-1;
            %reqsharptorqchange=0; %don't reset at midnight, but rather at 7am the next day (as is done just below)
            %reqwinddirchange=0;
            %First: at each hour, is there SBC?
            %Same requirements as a day having SBC, except for the number-of-hours requirement (of course)
            for hour=1:24
                if hour==7;reqsharptorqchange=0;reqwinddirchange=0;end %reset fresh for each day
                if hour>=11 && hour<=18
                    if coastalstnallqdata(year,doy,hour)-coastalstnallqdata(year,doy,hour-1)>=2 ||...
                           coastalstnalltdata(year,doy,hour)-coastalstnalltdata(year,doy,hour-1)<=-2 %we have the required T or q change
                       reqsharptorqchange=1;
                       for hourhelper=hour-1:hour+1
                           if abs(coastalstnallwinddirdata(year,doy,hourhelper)-coastalstnallwinddirdata(year,doy,hourhelper-1))>=30
                               reqwinddirchange=1;
                           end
                       end
                    end
                end
                %Once true for an hour in the 12PM-8PM window, all subsequent hours until
                    %7am the next day are considered to pass these tests
                if reqsharptorqchange==1
                    sharptorqtest(year,doy,hour)=1;
                    if reqwinddirchange==1 
                        sharptorqtestpluswind(year,doy,hour)=1;
                    else
                        sharptorqtestpluswind(year,doy,hour)=0;
                    end
                else
                    sharptorqtest(year,doy,hour)=0;
                    sharptorqtestpluswind(year,doy,hour)=0;
                end
                
                if inlandstnalltdata(year,doy,hour)>=coastalstnalltdata(year,doy,hour)+3 && ...
                        inlandstntmaxes(year,doy)>=nearcoastsst(year,doy)+3 &&...
                        mean(coastalstnallwindspeeddata(year,doy,8:11))<=6 &&...
                        sharptorqtest(year,doy,hour)==1
                    numhours5ormore(year,doy)=numhours5ormore(year,doy)+1;
                    hourswithsbcbydoyandhourofday(year,doy,hour)=1;
                else
                    hourswithsbcbydoyandhourofday(year,doy,hour)=0;
                end
            end

            %Next: are there enough hours with SBC to classify this day as having SBC?
            if numhours5ormore(year,doy)>=3
                dayswithsbcbydoy(year,doy)=1;
            else
                dayswithsbcbydoy(year,doy)=0;
            end
            inlandstnsstdiffbydoy(year,doy)=inlandstntmaxes(year,doy)-nearcoastsst(year,doy);
            %Assume that SSTs are constant throughout the day
            for hour=1:24
                inlandstnsstdiffbydoyandhourofday(year,doy,hour)=inlandstnalltdata(year,doy,hour)-nearcoastsst(year,doy);
            end
        end
    end
    hourswithsbcbydoyandhourofday(1,1:366,1:24)=NaN.*ones(1,366,24); %1981
    hourswithsbcbydoyandhourofday(35,1:366,1:24)=NaN.*ones(1,366,24);%2015
    dayswithsbcbydoy(1,1:366)=NaN.*ones(1,366); %1981
    dayswithsbcbydoy(35,1:366)=NaN.*ones(1,366); %2015
    inlandstnsstdiffbydoy(1,1:366)=NaN.*ones(1,366); %1981
    inlandstnsstdiffbydoy(35,1:366)=NaN.*ones(1,366); %2015
    inlandstnsstdiffbydoyandhourofday(1,1:366,1:24)=NaN.*ones(1,366,24); %1981
    inlandstnsstdiffbydoyandhourofday(35,1:366,1:24)=NaN.*ones(1,366,24);%2015
    
    if strcmp(stnnames,'ewrjfk')
        dayswithsbcbydoyewrjfk=dayswithsbcbydoy;
        hourswithsbcbydoyandhourofdayewrjfk=hourswithsbcbydoyandhourofday;
        inlandstntmaxesewrjfk=inlandstntmaxes;
        inlandstnsstdiffbydoyewrjfk=inlandstnsstdiffbydoy;
        inlandstnsstdiffbydoyandhourofdayewrjfk=inlandstnsstdiffbydoyandhourofday;
        coastalstnalltdataewrjfk=coastalstnalltdata;
        numhours5ormoreewrjfk=numhours5ormore;
        save(strcat(curDir,'newanalyses'),'dayswithsbcbydoyewrjfk','hourswithsbcbydoyandhourofdayewrjfk',...
            'inlandstntmaxesewrjfk','inlandstnsstdiffbydoyewrjfk','inlandstnsstdiffbydoyandhourofdayewrjfk',...
            'coastalstnalltdataewrjfk','numhours5ormoreewrjfk','-append');
    elseif strcmp(stnnames,'phlacy')
        dayswithsbcbydoyphlacy=dayswithsbcbydoy;
        hourswithsbcbydoyandhourofdayphlacy=hourswithsbcbydoyandhourofday;
        inlandstntmaxesphlacy=inlandstntmaxes;
        inlandstnsstdiffbydoyphlacy=inlandstnsstdiffbydoy;
        inlandstnsstdiffbydoyandhourofdayphlacy=inlandstnsstdiffbydoyandhourofday;
        coastalstnalltdataphlacy=coastalstnalltdata;
        numhours5ormorephlacy=numhours5ormore;
        save(strcat(curDir,'newanalyses'),'dayswithsbcbydoyphlacy','hourswithsbcbydoyandhourofdayphlacy',...
            'inlandstntmaxesphlacy','inlandstnsstdiffbydoyphlacy','inlandstnsstdiffbydoyandhourofdayphlacy',...
            'coastalstnalltdataphlacy','numhours5ormorephlacy','-append');
    elseif strcmp(stnnames,'conpor')
        dayswithsbcbydoyconpor=dayswithsbcbydoy;
        hourswithsbcbydoyandhourofdayconpor=hourswithsbcbydoyandhourofday;
        inlandstntmaxesconpor=inlandstntmaxes;
        inlandstnsstdiffbydoyconpor=inlandstnsstdiffbydoy;
        inlandstnsstdiffbydoyandhourofdayconpor=inlandstnsstdiffbydoyandhourofday;
        coastalstnalltdataconpor=coastalstnalltdata;
        numhours5ormoreconpor=numhours5ormore;
        save(strcat(curDir,'newanalyses'),'dayswithsbcbydoyconpor','hourswithsbcbydoyandhourofdayconpor',...
            'inlandstntmaxesconpor','inlandstnsstdiffbydoyconpor','inlandstnsstdiffbydoyandhourofdayconpor',...
            'coastalstnalltdataconpor','numhours5ormoreconpor','-append');
    else
        disp('Please add this pair of stations to stnnames!');
    end
end


%Analysis of sea-based cooling
if sbcanalysis==1
    %Create lists of days that do and don't have SBC, to be able to compare Tmax at inland stn between the two sets
    dayswithsbcbydoy=eval(['dayswithsbcbydoy' stnnames ';']);
    hourswithsbcbydoyandhourofday=eval(['hourswithsbcbydoyandhourofday' stnnames ';']);
    inlandstntmaxes=eval(['inlandstntmaxes' stnnames ';']);
    inlandstnsstdiffbydoy=eval(['inlandstnsstdiffbydoy' stnnames ';']);
    inlandstnsstdiffbydoyandhourofday=eval(['inlandstnsstdiffbydoyandhourofday' stnnames ';']);
    coastalstnalltdata=eval(['coastalstnalltdata' stnnames ';']);
    numhours5ormore=eval(['numhours5ormore' stnnames ';']);
    
    for i=1:6;eval(['month' num2str(i) 'dayswithsbcc=0;month' num2str(i) 'dayswithnosbcc=0;']);end
    inlandstntmaxbysbcandmonth={};
    avginlandstnsstdiffbymonthandhourofday=zeros(6,24);
    validdayc=zeros(6,1);
    for doy=121:303
        if doy<=151
            month=1;monthdayswithsbcc=month1dayswithsbcc;monthdayswithnosbcc=month1dayswithnosbcc; %i.e. May
        elseif doy<=181
            month=2;monthdayswithsbcc=month2dayswithsbcc;monthdayswithnosbcc=month2dayswithnosbcc;
        elseif doy<=212
            month=3;monthdayswithsbcc=month3dayswithsbcc;monthdayswithnosbcc=month3dayswithnosbcc;
        elseif doy<=243
            month=4;monthdayswithsbcc=month4dayswithsbcc;monthdayswithnosbcc=month4dayswithnosbcc;
        elseif doy<=273;
            month=5;monthdayswithsbcc=month5dayswithsbcc;monthdayswithnosbcc=month5dayswithnosbcc;
        else
            month=6;monthdayswithsbcc=month6dayswithsbcc;monthdayswithnosbcc=month6dayswithnosbcc; %i.e. Oct
        end
        for year=2:yeariwl-yeariwf %1981-2014
            if dayswithsbcbydoy(year,doy)==1
                monthdayswithsbcc=monthdayswithsbcc+1;
                inlandstntmaxbysbcandmonth{1,month}(monthdayswithsbcc)=inlandstntmaxes(year,doy); %yes, sbc this day
                doyofdaysbysbc{1,month}(monthdayswithsbcc)=doy;
                yearofdaysbysbc{1,month}(monthdayswithsbcc)=year;
            else
                monthdayswithnosbcc=monthdayswithnosbcc+1;
                inlandstntmaxbysbcandmonth{2,month}(monthdayswithnosbcc)=inlandstntmaxes(year,doy); %no, no sbc this day
                doyofdaysbysbc{2,month}(monthdayswithnosbcc)=doy;
                yearofdaysbysbc{2,month}(monthdayswithnosbcc)=year;
            end
            if ~isnan(inlandstnsstdiffbydoyandhourofday(year,doy,1))
                %if month==1;disp(squeeze(inlandstnsstdiffbydoyandhourofday(year,doy,:)));disp(validdayc(month));end
                avginlandstnsstdiffbymonthandhourofday(month,:)=avginlandstnsstdiffbymonthandhourofday(month,:)+squeeze(inlandstnsstdiffbydoyandhourofday(year,doy,:))';
                %if month==1;disp(avginlandstnsstdiffbymonthandhourofday(month,:));end
                validdayc(month)=validdayc(month)+1;
            end
        end
        eval(['month' num2str(month) 'dayswithsbcc=monthdayswithsbcc;month' num2str(month) 'dayswithnosbcc=monthdayswithnosbcc;']);
    end
    
    for mon=1:6;avginlandstnsstdiffbymonthandhourofday(mon,:)=avginlandstnsstdiffbymonthandhourofday(mon,:)./(validdayc(mon));end
    
    %Analogously, create lists of hours that do and don't have SBC
    monthhourswithsbcc=zeros(6,24);monthhourswithnosbcc=zeros(6,24);
    for doy=121:303
        if doy<=151;month=1;elseif doy<=181;month=2;elseif doy<=212;month=3;elseif doy<=243;month=4;
        elseif doy<=273;month=5;else month=6;end
        for year=2:yeariwl-yeariwf %1981-2014
            for hour=1:24
                if hourswithsbcbydoyandhourofday(year,doy,hour)==1
                    monthhourswithsbcc(month,hour)=monthhourswithsbcc(month,hour)+1; %yes, sbc this hour
                else
                    monthhourswithnosbcc(month,hour)=monthhourswithnosbcc(month,hour)+1; %no, no sbc this hour
                end
            end
        end
    end
    
    
    %Make boxplots comparing Tmax on sbc and non-sbc days for each month
    if makeboxplot==1
        figc=100;figure(figc);figc=figc+1;
        curpart=1;highqualityfiguresetup;
        for month=1:6
            subplot(3,2,month);hold on;
            x1=inlandstntmaxbysbcandmonth{1,month};
            x2=inlandstntmaxbysbcandmonth{2,month};
            X=[x1 x2];
            grp=[zeros(1,size(x1,2)),ones(1,size(x2,2))];
            boxplot(X,grp,'Notch','on','Labels',{'SBC','Non-SBC'});
            ylim([5 45]);
            ylabel('Daily Tmax (C)','fontsize',14,'fontweight','bold','fontname','arial');
            set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
            h=findobj(gca,'type','text');
            set(h,'fontsize',14,'fontweight','bold','fontname','arial');
        end
        curpart=2;figloc=curDir;figname='boxplotsbc';highqualityfiguresetup;
    end
    
    %Percentage of days in each month with SBC
    if plotpctofdays==1
        for month=1:6
            pctofdayswithsbc(month)=100.*...
                eval(['month' num2str(month) 'dayswithsbcc./(month' num2str(month) 'dayswithsbcc+month' num2str(month) 'dayswithnosbcc);']);
        end
        figure(figc);figc=figc+1;
        curpart=1;highqualityfiguresetup;
        xaxislabels={'May','Jun','Jul','Aug','Sep','Oct'};
        plot(pctofdayswithsbc,'linewidth',2);
        ax=gca;set(ax,'XTick',[1 2 3 4 5 6]);
        set(gca,'XTickLabel',xaxislabels,'fontsize',14,'fontweight','bold','fontname','arial');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        xlabel('Month','fontsize',16,'fontweight','bold','fontname','arial');
        ylabel('Percent','fontsize',16,'fontweight','bold','fontname','arial');
        title('Percent of Days with Sea-Based Cooling, by Month','fontsize',20,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname=strcat('pctdayswithsbcbymonth',stnnames);highqualityfiguresetup;
    end
    
    %Average (EWR Tmax minus SST) for each hour of each month
    if plotinlandstnminussst==1
        figure(figc);figc=figc+1;
        curpart=1;highqualityfiguresetup;
        imagescnan(avginlandstnsstdiffbymonthandhourofday);
        set(gca,'XTick',1:24);
        set(gca,'XTickLabels',1:24,'fontsize',14,'fontweight','bold','fontname','arial');
        yaxislabels={'May','Jun','Jul','Aug','Sep','Oct'};
        set(gca,'YTickLabel',yaxislabels,'fontsize',14,'fontweight','bold','fontname','arial');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        ylabel('Month','fontsize',16,'fontweight','bold','fontname','arial');
        xlabel('Hour of the Day','fontsize',16,'fontweight','bold','fontname','arial');
        h=colorbar;
        ylabel(h,'Difference (deg C)','fontsize',16,'fontweight','bold','fontname','arial');
        set(h,'fontsize',16,'fontweight','bold','fontname','arial');
        title('Newark-SST Average Temperature Difference, by Month and Hour of Day','fontsize',20,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname='ewrsstdiff';highqualityfiguresetup;
    end
    
    %Percentage of hours of day in each month with SBC
    if plotpctofhours==1
        for month=1:6
            pctofhourswithsbc(month,:)=100.*monthhourswithsbcc(month,:)./(monthhourswithsbcc(month,:)+monthhourswithnosbcc(month,:));
        end
        %Plot this as a heat map, which is a nice format as it clearly shows the bull's-eye around May, 6 PM
        figure(figc);figc=figc+1;
        curpart=1;highqualityfiguresetup;
        imagescnan(pctofhourswithsbc);
        set(gca,'XTick',1:24);
        set(gca,'XTickLabels',1:24,'fontsize',14,'fontweight','bold','fontname','arial');
        yaxislabels={'May','Jun','Jul','Aug','Sep','Oct'};
        set(gca,'YTickLabel',yaxislabels,'fontsize',14,'fontweight','bold','fontname','arial');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        ylabel('Month','fontsize',16,'fontweight','bold','fontname','arial');
        xlabel('Hour of the Day','fontsize',16,'fontweight','bold','fontname','arial');
        h=colorbar;
        ylabel(h,'Percent','fontsize',16,'fontweight','bold','fontname','arial');
        set(h,'fontsize',16,'fontweight','bold','fontname','arial');
        title('Percent of Hours of Day with Sea-Based Cooling, by Month','fontsize',20,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname='pcthourswithsbcbymonth';highqualityfiguresetup;
    end
    
    %Percentage of hours during heat waves with SBC
    %IF USING, REDUCE TO 5 DAYS BEFORE/AFTER FROM 14
    if plotpcthourshwssbc==1
        subsetofhourswithsbcthishw={};avgpctssbchourshws={};avgpctssbchourshws1d=0;
        c=1;
        %for stn=1:size(nestns,1)
        %numhws=size(hwregisterbyTshortonly{stn},1); %station-specific hws
        numhws=size(reghwdoys,2); %regional hws -- then just one output array is necessary b/c all stns have the same hws
            %and JFK & EWR are both already wrapped into the definition of SBC
        hourswithsbcallhws=zeros(numhws-1,29,24); %numhws-1 is because 1 hw is in 2015, outside the 1982-2014 window used here
        hourswithsbcallhws9days=zeros(numhws-1,9,24);

        for hw=1:numhws
            %hwlen=hwregisterbyTshortonly{stn}(hw,2)-hwregisterbyTshortonly{stn}(hw,1)+1;
            hwlen=size(reghwdoys{hw},1);
            if hwlen==3
                %doyminus14=hwregisterbyTshortonly{stn}(hw,1)-13; %14 days before the middle of this heat wave
                %doyplus14=hwregisterbyTshortonly{stn}(hw,2)+13; %14 days after the middle of this heat wave
                doyminus14=reghwdoys{hw}(1,1)-13;
                doyplus14=reghwdoys{hw}(3,1)+13;
            elseif hwlen==4
                %doyminus14=hwregisterbyTshortonly{stn}(hw,1)-13; %14 days before the middle of this heat wave
                %doyplus14=hwregisterbyTshortonly{stn}(hw,2)+12; %14 days after the middle of this heat wave
                doyminus14=reghwdoys{hw}(1,1)-13;
                doyplus14=reghwdoys{hw}(4,1)+12;
            elseif hwlen==5
                %doyminus14=hwregisterbyTshortonly{stn}(hw,1)-12; %14 days before the middle of this heat wave
                %doyplus14=hwregisterbyTshortonly{stn}(hw,2)+12; %14 days after the middle of this heat wave
                doyminus14=reghwdoys{hw}(1,1)-12;
                doyplus14=reghwdoys{hw}(5,1)+12;
            end
            %year=hwregisterbyTshortonly{stn}(hw,3);relyear=year-yeariwf+1;
            year=reghwdoys{hw}(1,2);relyear=year-yeariwf+1;
            %Check: DOYminus14 to DOYplus14 should always span a total of 29 days

            if year>=1982 && year<=2014 %imposed by OISST data availability from the SBC calc
                %subsetofhourswithsbcthishw{stn,hw}=squeeze(hourswithsbcbydoyandhourofday(relyear,doyminus14:doyplus14,:));
                    %dims are days surrounding hw x hours of day
                hourswithsbcallhws(c,:,:)=squeeze(hourswithsbcbydoyandhourofday(relyear,doyminus14:doyplus14,:));
                hourswithsbcallhws9days(c,:,:)=squeeze(hourswithsbcbydoyandhourofday(relyear,doyminus14+10:doyplus14-10,:));
                c=c+1;
            end
        end         
        %end
        %Make 2d instead of 3d
        hourswithsbcallhws9days1d=zeros(size(hourswithsbcallhws9days,1),216);
        for c=1:size(hourswithsbcallhws9days,1)
            count=1;
            for day=1:9
                hourswithsbcallhws9days1d(c,count:count+23)=hourswithsbcallhws9days(c,day,:);
                count=count+24;
            end
        end

        %Get average
        newcount=1;
        sumpctssbchourshws=zeros(216,1);avgpctssbchourshws=zeros(216,1);
        for c=1:28
            for hour=1:216
                sumpctssbchourshws(hour)=sumpctssbchourshws(hour)+hourswithsbcallhws9days1d(c,hour);
            end
        end
        avgpctssbchourshws=100.*sumpctssbchourshws./c;
        
        %Get st dev to go along with the average
        stdevpctssbchourshws=zeros(216,1);
        for hour=1:216
            stdevpctssbchourshws(hour)=100.*std(hourswithsbcallhws9days1d(:,hour));
        end
        %Pad with 48 zeros on either end, to match some of the earlier arrays
        %avgpctssbchourshws1d=[zeros(48,1);avgpctssbchourshws1d;zeros(48,1)];
        %stdevpctssbchourshws1d=[zeros(48,1);stdevpctssbchourshws1d;zeros(48,1)];
       
        
        %To assess statistical significance of this peak, randomly select 100 9-day periods in the May-Sep window
        %and compute sbc for those as well
        %Compare these sbc traces to the average sbc trace of the heat waves that was just plotted
        
        %1.Get 10000 random DOYs corresponding to the start of the 9-day periods, and so in the window 121-295
        doys=randi([121 295],10000,1);
        years=randi([2 34],10000,1);
        sumsubsetsrand=zeros(9,24);
        hourswithsbcallperiods=zeros(100,9,24);
        for i=1:10000
            hourswithsbcallperiods(i,:,:)=squeeze(hourswithsbcbydoyandhourofday(years(i),doys(i):doys(i)+8,:));
            sumsubsetsrand=sumsubsetsrand+squeeze(hourswithsbcallperiods(i,:,:));
        end
        %2. Divide to get average of percent-sbc for each hour of the 9-day period
        avgpctssbchoursrand=100.*sumsubsetsrand./10000;
        %Convert this 2D array to a 1D vector arranged in chronological order
        count=1;
        for row=1:size(avgpctssbchoursrand,1)
            avgpctssbchoursrand1d(count:count+23)=avgpctssbchoursrand(row,:);
            count=count+24;
        end
        %3. Get st dev to go along with the average
        count=1;stdevpctssbchoursrand1d=zeros(216,1);
        for day=1:9
            stdevpctssbchoursrand1d(count:count+23)=std(hourswithsbcallperiods(:,day,:));
            count=count+24;
        end
        
        %Now, make the improved plot of this percent-SBC data
        %Plot 9-day average and spread for heat waves, and 9-day average and spread of the 10000 random days
        figure(figc);figc=figc+1;
        curpart=1;highqualityfiguresetup;
        x=(1:216)';
        %shadederrorbar(x,avgpctssbchourshws,stdevpctssbchourshws,'r');hold on; %not enough hws for this
        %Smooth the heat-wave plot with a 0.1-0.2-0.4-0.2-0.1 scheme
        temp=zeros(216,1);temp2=zeros(216,1);
        for hour=3:214
            temp(hour)=0.1*avgpctssbchourshws(hour-2)+0.2*avgpctssbchourshws(hour-1)+...
                0.4*avgpctssbchourshws(hour)+0.2*avgpctssbchourshws(hour+1)+0.1*avgpctssbchourshws(hour+2);
            temp2(hour)=0.1*avgpctssbchoursrand1d(hour-2)+0.2*avgpctssbchoursrand1d(hour-1)+...
                0.4*avgpctssbchoursrand1d(hour)+0.2*avgpctssbchoursrand1d(hour+1)+0.1*avgpctssbchoursrand1d(hour+2);
        end
        temp(1)=NaN;temp(2)=NaN;temp(215)=NaN;temp(216)=NaN;
        avgpctssbchourshws=temp;
        plot(x,avgpctssbchourshws,'r','linewidth',1.5);hold on;
        shadederrorbar(x,avgpctssbchoursrand1d,stdevpctssbchoursrand1d,{'linewidth',1.5},'b');
        xlim([1 216]);
        timesforlabels={'12 AM, Day -4';'12 PM, Day -4';'12 AM, Day -3';'12 PM, Day -3';'12 AM, Day -2';'12 PM, Day -2';'12 AM, Day -1';...
            '12 PM, Day -1';'12 AM, Day 0';'12 PM, Day 0';'12 AM, Day 1';'12 PM, Day 1';'12 AM, Day 2';...
            '12 PM, Day 2';'12 AM, Day 3';'12 PM, Day 3';'12 AM, Day 4';'12 PM, Day 4';'12 AM, Day 5'};
        set(gca,'xtick',0:12:216);set(gca,'XTickLabel',timesforlabels,'fontname','arial','fontweight','bold','fontsize',14);
        xticklabel_rotate([],45,[],'fontsize',12,'fontname','arial','fontweight','bold');
        ylabel('Percent of Hours','fontsize',14,'fontweight','bold','fontname','arial');
        title('Sea-Breeze Cooling: Heat Waves vs 1000 Random Sets of Days',...
            'fontsize',20,'fontweight','bold','fontname','arial');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname=strcat('sbchourlytraces9dayswithsignif',stnnames);highqualityfiguresetup;
        
        save(strcat(curDir,'newanalyses'),'avgpctssbchourshws','avgpctssbchourshws1d','-append');
    end
    
    %Composite of 500 gh anom and 850 winds anom for hot non-SBC days vs hot SBC days
    %Do this one month at a time
    if donarrcompositehotsbcvshotnonsbc==1
        bigmatrix=0;disp(clock);
        gh500dailyarray={};uwnd850dailyarray={};vwnd850dailyarray={};uwnd300dailyarray={};vwnd300dailyarray={};
        for monthc=monthiwf:monthiwf
            numdaystocompositeover=min(size(inlandstntmaxbysbcandmonth{1,monthc},2),size(inlandstntmaxbysbcandmonth{2,monthc},2));
                %i.e. whichever set of days is smaller, SBC or non-SBC (so equal number of days in each composite)
            for j=1:2
                %j=1 -- composite SBC days, j=2 -- composite non-SBC days
                %Find the hottest numdaystocompositeover SBC or non-SBC days in this month
                bigmatrix=[inlandstntmaxbysbcandmonth{j,monthc}' yearofdaysbysbc{j,monthc}' doyofdaysbysbc{j,monthc}'];
                bigmatrix=sortrows(bigmatrix,-1);
                numdayscomposited=1;row=1; %counts for this month only
                while numdayscomposited<=numdaystocompositeover
                    if ~isnan(bigmatrix(row,1))
                        fprintf('Working on compositing for day %d of day %d\n',numdayscomposited,numdaystocompositeover);
                        year=bigmatrix(row,2)+yeariwf-1;
                        month=DOYtoMonth(bigmatrix(row,3),year);
                        dom=DOYtoDOM(bigmatrix(row,3),year);
                        doy=DatetoDOY(month,dom,year);

                        ghfile=load(strcat(narrDir,'hgt/',num2str(year),'/hgt_',num2str(year),'_0',num2str(month),'_01.mat'));
                        ghdata=eval(['ghfile.hgt_' num2str(year) '_0' num2str(month) '_01;']);ghdata=ghdata{3};clear ghfile;
                        uwndfile=load(strcat(narrDir,'uwnd/',num2str(year),'/uwnd_',num2str(year),'_0',num2str(month),'_01.mat'));
                        uwnddata=eval(['uwndfile.uwnd_' num2str(year) '_0' num2str(month) '_01;']);uwnddata=uwnddata{3};clear uwndfile;
                        vwndfile=load(strcat(narrDir,'vwnd/',num2str(year),'/vwnd_',num2str(year),'_0',num2str(month),'_01.mat'));
                        vwnddata=eval(['vwndfile.vwnd_' num2str(year) '_0' num2str(month) '_01;']);vwnddata=vwnddata{3};clear vwndfile;
                        %ghfile=ncread(strcat(narrncDir,'hgt.',num2str(year),'0',num2str(month),'.nc'),'hgt',...
                        %    [1 1 13 1],[Inf Inf 17 Inf]); %so now 500hPa is level 5
                        %ghdata=permute(ghfile,[2 1 3 4]);ghdata=ghdata(:,:,5,:);clear ghfile;fclose('all');
                        %uwndfile=ncread(strcat(narrncDir,'uwnd.',num2str(year),'0',num2str(month),'.nc'),'uwnd',...
                        %    [1 1 3 1],[Inf Inf 7 Inf]); %850hPa is also level 5
                        %uwnddata=permute(uwndfile,[2 1 3 4]);uwnddata=uwnddata(:,:,5,:);fclose('all');
                        %vwndfile=ncread(strcat(narrncDir,'vwnd.',num2str(year),'0',num2str(month),'.nc'),'vwnd',...
                        %    [1 1 3 1],[Inf Inf 7 Inf]);
                        %vwnddata=permute(vwndfile,[2 1 3 4]);vwnddata=vwnddata(:,:,5,:);fclose('all');

                        %gh500dailyarray{monthc}(numdayscomposited,:,:)=mean(ghdata(:,:,17,dom*8-7:dom*8),4);
                        %uwnd850dailyarray{monthc}(numdayscomposited,:,:)=mean(uwnddata(:,:,7,dom*8-7:dom*8),4);
                        %vwnd850dailyarray{monthc}(numdayscomposited,:,:)=mean(vwnddata(:,:,7,dom*8-7:dom*8),4);
                        gh500dailyarray{monthc}(numdayscomposited,:,:)=mean(ghdata(:,:,4,dom*8-7:dom*8),4);
                        uwnd850dailyarray{monthc}(numdayscomposited,:,:)=mean(uwnddata(:,:,2,dom*8-7:dom*8),4);
                        vwnd850dailyarray{monthc}(numdayscomposited,:,:)=mean(vwnddata(:,:,2,dom*8-7:dom*8),4);
                        uwnd300dailyarray{monthc}(numdayscomposited,:,:)=mean(uwnddata(:,:,5,dom*8-7:dom*8),4);
                        vwnd300dailyarray{monthc}(numdayscomposited,:,:)=mean(vwnddata(:,:,5,dom*8-7:dom*8),4);
                        temp=gh500dailyarray{monthc}>10000;gh500dailyarray{monthc}(temp)=NaN;
                        temp=uwnd850dailyarray{monthc}>100;uwnd850dailyarray{monthc}(temp)=NaN;
                        temp=vwnd850dailyarray{monthc}>100;vwnd850dailyarray{monthc}(temp)=NaN;
                        temp=uwnd300dailyarray{monthc}>200;uwnd300dailyarray{monthc}(temp)=NaN;
                        temp=vwnd300dailyarray{monthc}>200;vwnd300dailyarray{monthc}(temp)=NaN;

                        relevantgh500avg=ghclimo500{doy};
                        relevantuwnd850avg=uwndclimo850{doy};
                        relevantvwnd850avg=vwndclimo850{doy};
                        relevantuwnd300avg=uwndclimo300{doy};
                        relevantvwnd300avg=vwndclimo300{doy};

                        gh500dailyanomarray{monthc}(numdayscomposited,:,:)=...
                            squeeze(gh500dailyarray{monthc}(numdayscomposited,:,:))-relevantgh500avg;
                        uwnd850dailyanomarray{monthc}(numdayscomposited,:,:)=...
                            squeeze(uwnd850dailyarray{monthc}(numdayscomposited,:,:))-relevantuwnd850avg;
                        vwnd850dailyanomarray{monthc}(numdayscomposited,:,:)=...
                            squeeze(vwnd850dailyarray{monthc}(numdayscomposited,:,:))-relevantvwnd850avg;
                        uwnd300dailyanomarray{monthc}(numdayscomposited,:,:)=...
                            squeeze(uwnd300dailyarray{monthc}(numdayscomposited,:,:))-relevantuwnd300avg;
                        vwnd300dailyanomarray{monthc}(numdayscomposited,:,:)=...
                            squeeze(vwnd300dailyarray{monthc}(numdayscomposited,:,:))-relevantvwnd300avg;

                        numdayscomposited=numdayscomposited+1;
                    end
                    row=row+1;
                end
                if j==1
                    gh500dailyanomarraysbc=gh500dailyanomarray;
                    uwnd850dailyanomarraysbc=uwnd850dailyanomarray;
                    vwnd850dailyanomarraysbc=vwnd850dailyanomarray;
                    uwnd300dailyanomarraysbc=uwnd300dailyanomarray;
                    vwnd300dailyanomarraysbc=vwnd300dailyanomarray;
                else
                    gh500dailyanomarraynonsbc=gh500dailyanomarray;
                    uwnd850dailyanomarraynonsbc=uwnd850dailyanomarray;
                    vwnd850dailyanomarraynonsbc=vwnd850dailyanomarray;
                    uwnd300dailyanomarraynonsbc=uwnd300dailyanomarray;
                    vwnd300dailyanomarraynonsbc=vwnd300dailyanomarray;
                end
            end
            %Averages for this month
            gh500anomarraysbc{monthc}=squeeze(mean(gh500dailyanomarraysbc{monthc},1));
            gh500anomarraynonsbc{monthc}=squeeze(mean(gh500dailyanomarraynonsbc{monthc},1));
            uwnd850anomarraysbc{monthc}=squeeze(mean(uwnd850dailyanomarraysbc{monthc},1));
            uwnd850anomarraynonsbc{monthc}=squeeze(mean(uwnd850dailyanomarraynonsbc{monthc},1));
            vwnd850anomarraysbc{monthc}=squeeze(mean(vwnd850dailyanomarraysbc{monthc},1));
            vwnd850anomarraynonsbc{monthc}=squeeze(mean(vwnd850dailyanomarraynonsbc{monthc},1));
            uwnd300anomarraysbc{monthc}=squeeze(mean(uwnd300dailyanomarraysbc{monthc},1));
            uwnd300anomarraynonsbc{monthc}=squeeze(mean(uwnd300dailyanomarraynonsbc{monthc},1));
            vwnd300anomarraysbc{monthc}=squeeze(mean(vwnd300dailyanomarraysbc{monthc},1));
            vwnd300anomarraynonsbc{monthc}=squeeze(mean(vwnd300dailyanomarraynonsbc{monthc},1));
            
            save(strcat(curDir,'newanalyses'),'gh500dailyanomarraysbc','uwnd850dailyanomarraysbc',...
                'vwnd850dailyanomarraysbc','gh500dailyanomarraynonsbc','uwnd850dailyanomarraynonsbc',...
                'vwnd850dailyanomarraynonsbc','gh500anomarraysbc','gh500anomarraynonsbc',...
                'uwnd850anomarraysbc','uwnd850anomarraynonsbc','vwnd850anomarraysbc',...
                'vwnd850anomarraynonsbc','uwnd300anomarraysbc','uwnd300anomarraynonsbc','vwnd300anomarraysbc',...
                'vwnd300anomarraynonsbc','-append');
        end
        disp(clock);
    end
    
    %Code for plotting the above-calculated composite arrays
    if plotnarrcompositehotsbcvshotnonsbc==1
        data{1}=narrlats;
        data{2}=narrlons;
        region='usaminushawaii-tight3';
        %vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=1;
        datatype='NARR';
        
        for j=1:2
            if j==1
                %data{3}=gh500anomarraysbc{5};
                %vararginnew={'variable';'height';'contour';1;'plotCountries';1;...
                %    'caxismin';-80;'caxismax';80;'overlaynow';0;'anomavg';'avg'};
                %sbcornotfigname='sbcgh500';
                data{3}=uwnd850anomarraysbc{5};
                vararginnew={'variable';'wind';'contour';1;'plotCountries';1;...
                    'caxismin';-6;'caxismax';6;'overlaynow';0;'anomavg';'avg'};
                sbcornotfigname='sbcuwnd850';
                
                sbcornot='SBC';
            elseif j==2
                %data{3}=gh500anomarraynonsbc{5};
                %vararginnew={'variable';'height';'contour';1;'plotCountries';1;...
                %    'caxismin';-80;'caxismax';80;'overlaynow';0;'anomavg';'avg'};
                %sbcornotfigname='sbcnongh500';
                data{3}=uwnd850anomarraynonsbc{5};
                vararginnew={'variable';'wind';'contour';1;'plotCountries';1;...
                    'caxismin';-6;'caxismax';6;'overlaynow';0;'anomavg';'avg'};
                sbcornotfigname='sbcnonuwnd850';
                
                sbcornot='Non-SBC';
            end
            %figure(figc);figc=figc+1;hold on;
            curpart=1;highqualityfiguresetup;
            [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
                plotModelData(data,region,vararginnew,datatype);
            %colormap(colormaps('gh','more'));
            colormap(colormaps('sst','more'));
            %title(strcat(['Composite of 500-hPa Height Anomalies for Hot ',sbcornot,' Days: May']),...
            %    'fontsize',18,'fontweight','bold','fontname','arial');
            title(strcat(['Composite of 850-hPa Westerly-Wind Anomalies for Hot ',sbcornot,' Days: May']),...
                'fontsize',18,'fontweight','bold','fontname','arial');
            cbar=colorbar;
            set(get(cbar,'Ylabel'),'String','Anomaly (m/s)','FontSize',20,'FontWeight','bold','FontName','Arial');
            set(cbar,'FontSize',20,'FontWeight','bold','FontName','Arial');
            cpos=get(cbar,'Position');cpos(1)=0.9;cpos(2)=0.05;cpos(3)=0.017;cpos(4)=0.9;
            set(cbar,'Position',cpos);
            curpart=2;figloc=curDir;figname=sbcornotfigname;highqualityfiguresetup;
        end
    end
    
    %Uses arrays calculated further down
    %calculated for 1000 hPa
    if donarrcompositebysomcateg==1
        top250daysjfk=tanomandwinddirjfksorteddailybyhottest(1:250,1:2);
        somcategc=zeros(6,1);
        tdatathisday={};shumdatathisday={};wbtdatathisday={};tanomthisday={};shumanomthisday={};wbtanomthisday={};
        for i=1:250
            fprintf('i is %d\n',i);
            thisdoy=top250daysjfk(i,1);thisyear=top250daysjfk(i,2);
            thismon=DOYtoMonth(thisdoy,thisyear);
            thisdom=DOYtoDOM(thisdoy,thisyear);
            if rem(thisyear,4)==0;ly=1;else ly=0;end
            if thisdoy<=273;daycforsomtimeseries=((thisyear-yeariwf+1)-1)*153+thisdoy-120-ly;end
            
            thissomcateg=timeseries(daycforsomtimeseries,3);
            
            %Load NARR data for this day
            if thismon~=10 && thisdom~=monthlengthsdays(thismon-monthiwf+1)
                somcategc(thissomcateg)=somcategc(thissomcateg)+1;
                
                tdata=getnarrdatabymonth(runningremotely,'air',thisyear,thismon);tdata=tdata{3};
                shumdata=getnarrdatabymonth(runningremotely,'shum',thisyear,thismon);shumdata=shumdata{3};
                tdatathisday{thissomcateg,somcategc(thissomcateg)}=mean(tdata(:,:,1,thisdom*8-7:thisdom*8),4)-273.15;
                shumdatathisday{thissomcateg,somcategc(thissomcateg)}=mean(shumdata(:,:,1,thisdom*8-7:thisdom*8),4);
                wbtdatathisday{thissomcateg,somcategc(thissomcateg)}=...
                    calcwbtfromTandshum(tdatathisday{thissomcateg,somcategc(thissomcateg)},...
                    shumdatathisday{thissomcateg,somcategc(thissomcateg)},1);
                tanomthisday{thissomcateg,somcategc(thissomcateg)}=...
                    tdatathisday{thissomcateg,somcategc(thissomcateg)}-tclimo1000{thisdoy};
                shumanomthisday{thissomcateg,somcategc(thissomcateg)}=...
                    shumdatathisday{thissomcateg,somcategc(thissomcateg)}-shumclimo1000{thisdoy};
                wbtanomthisday{thissomcateg,somcategc(thissomcateg)}=...
                    wbtdatathisday{thissomcateg,somcategc(thissomcateg)}-wbtclimo1000{thisdoy};
            end
        end
        save(strcat(curDir,'newanalyses2'),'tdatathisday','shumdatathisday','wbtdatathisday','wbtanomthisday','-append');
        %Get SOM-category average by averaging across days
        for i=1:6
            temp=zeros(277,349);
            for j=1:somcategc(i)
                temp=temp+wbtanomthisday{i,j};
            end
            wbtanomhwdays{i}=temp./somcategc(i);
        end
        save(strcat(curDir,'newanalyses2'),'wbtanomhwdays','-append');
    end
    
    if plotnarrcompositebysomcateg==1
        data{1}=narrlats;
        data{2}=narrlons;
        region='usaminushawaii-tight3';
        datatype='NARR';
        %figure(figc);figc=figc+1;
        for i=1:6
            subplot(3,2,i);
            data{3}=wbtanomhwdays{i};
            vararginnew={'variable';'wbt';'contour';1;'plotCountries';1;...
                'caxismin';-4;'caxismax';4;'overlaynow';0;'anomavg';'avg'};
            vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=1;
            [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
                plotModelData(data,region,vararginnew,datatype);
            curpart=1;highqualityfiguresetup;
            colormap(colormaps('wbt','more'));
            text(-0.08,1,strcat(subplotletters{i},')'),'units','normalized',...
                'fontsize',14,'fontweight','bold','fontname','arial');
            perchotdaysthissomcateg=round(100*somcategc(i)./sum(somcategc));
            text(0.92,1,strcat(num2str(perchotdaysthissomcateg),'%'),'units','normalized',...
                'fontsize',14,'fontweight','bold','fontname','arial');
            if i<=2;rownow=1;elseif i<=4;rownow=2;else rownow=3;end
            if rem(i,2)==1;colnow=1;else colnow=2;end
            %fprintf('somcategtoplot: %d, rownow: %d, colnow: %d\n',i,rownow,colnow);
            if colnow==1;colnowpos=0.03;else colnowpos=0.47;end
            if rownow==1;rownowpos=0.34;elseif rownow==2;rownowpos=0.66;else rownowpos=0.98;end
            set(gca,'Position',[colnowpos 1-rownowpos 0.4 0.3]);
        end
        %title('Composite of 850-hPa WBT Anomalies on Hot T Days, by SOM Category',...
        %    'fontsize',18,'fontweight','bold','fontname','arial');
        cbar=colorbar;
        set(get(cbar,'Ylabel'),'String','Anomaly (deg C)','FontSize',20,'FontWeight','bold','FontName','Arial');
        set(cbar,'FontSize',20,'FontWeight','bold','FontName','Arial');
        cpos=get(cbar,'Position');cpos(1)=0.9;cpos(2)=0.05;cpos(3)=0.017;cpos(4)=0.9;
        set(cbar,'Position',cpos);
        fignamepart='somcompwbtanomhotdaysonly';
        curpart=2;figloc=curDir;figname=fignamepart;highqualityfiguresetup;
    end
end


%Analysis of SOM clustering, conducted in cluster_code_hgt and accessible via loadsavedarrays
if somclusteranalysis==1
    if dosomebasicstats==1
        %Calculate what percent of e.g. first days fall into each of the 6 SOM patterns
        somcfirstdays=zeros(6,1);somclastdays=zeros(6,1);
        somcday1=zeros(6,1);somcday2=zeros(6,1);somcday3=zeros(6,1);somcday4=zeros(6,1);somcday5=zeros(6,1);
        somc5daysprior=zeros(6,1);somc10daysprior=zeros(6,1);somc20daysprior=zeros(6,1);
        
        %ADD IN 5, 10, AND 20 DAYS BEFORE TO HELP GET AT PREDICTABILITY
        for hwc=1:size(reghwdoys,2)
            somcategvector{hwc}=zeros(6,1);
            somcategvectorprior{hwc}=NaN.*ones(20,1);
                %used to temporarily store SOM categories for days prior to the start of the heat waves
            thishwlen=size(reghwdoys{hwc},1);
            doyfirstdaythishw=reghwdoys{hwc}(1,1);
            doylastdaythishw=reghwdoys{hwc}(thishwlen,1);
            doy5dayspriorthishw=reghwdoys{hwc}(1,1)-5;
            doy10dayspriorthishw=reghwdoys{hwc}(1,1)-10;
            doy20dayspriorthishw=reghwdoys{hwc}(1,1)-20;
            if thishwlen==3
                doyday2thishw=reghwdoys{hwc}(1,1);
                doyday3thishw=reghwdoys{hwc}(2,1);
                doyday4thishw=reghwdoys{hwc}(3,1);
            elseif thishwlen==4
                doyday2thishw=reghwdoys{hwc}(1,1);
                doyday3thishw=reghwdoys{hwc}(2,1);
                doyday4thishw=reghwdoys{hwc}(3,1);
                doyday5thishw=reghwdoys{hwc}(4,1);
            elseif thishwlen==5
                doyday1thishw=reghwdoys{hwc}(1,1);
                doyday2thishw=reghwdoys{hwc}(2,1);
                doyday3thishw=reghwdoys{hwc}(3,1);
                doyday4thishw=reghwdoys{hwc}(4,1);
                doyday5thishw=reghwdoys{hwc}(5,1);
            end
            yearthishw=reghwdoys{hwc}(1,2);
            if rem(yearthishw,4)==0;apr30doy=121;else apr30doy=120;end
            
            indexfirstday=(yearthishw-yeariwf)*153+(doyfirstdaythishw-apr30doy);
            somcateg=timeseries(indexfirstday,3);
            somcfirstdays(somcateg)=somcfirstdays(somcateg)+1;
            indexlastday=(yearthishw-yeariwf)*153+(doylastdaythishw-apr30doy);
            somcateg=timeseries(indexlastday,3);
            somclastdays(somcateg)=somclastdays(somcateg)+1;
            index5daysprior=(yearthishw-yeariwf)*153+(doy5dayspriorthishw-apr30doy);
            somcateg=timeseries(index5daysprior,3);
            somc5daysprior(somcateg)=somc5daysprior(somcateg)+1;
            somcategvectorprior{hwc}(16)=somcateg;
            index10daysprior=(yearthishw-yeariwf)*153+(doy10dayspriorthishw-apr30doy);
            somcateg=timeseries(index10daysprior,3);
            somc10daysprior(somcateg)=somc10daysprior(somcateg)+1;
            somcategvectorprior{hwc}(11)=somcateg;
            index20daysprior=(yearthishw-yeariwf)*153+(doy20dayspriorthishw-apr30doy);
            somcateg=timeseries(index20daysprior,3);
            somc20daysprior(somcateg)=somc20daysprior(somcateg)+1;
            somcategvectorprior{hwc}(1)=somcateg;
            if thishwlen==3
                for j=2:4
                    eval(['indexday' num2str(j) '=(yearthishw-yeariwf)*153+(doyday'...
                        num2str(j) 'thishw-apr30doy);']);
                    somcateg=eval(['timeseries(indexday' num2str(j) ',3);']);
                    eval(['somcday' num2str(j) '(somcateg)=somcday' num2str(j) '(somcateg)+1;']);
                    somcategvector{hwc}(j)=somcateg;
                end
                somcategvectorfirstandlastonly{hwc}=[somcategvector{hwc}(2);NaN;NaN;somcategvector{hwc}(4)];
            elseif thishwlen==4
                for j=2:5
                    eval(['indexday' num2str(j) '=(yearthishw-yeariwf)*153+(doyday'...
                        num2str(j) 'thishw-apr30doy);']);
                    somcateg=eval(['timeseries(indexday' num2str(j) ',3);']);
                    eval(['somcday' num2str(j) '(somcateg)=somcday' num2str(j) '(somcateg)+1;']);
                    somcategvector{hwc}(j)=somcateg;
                end
                somcategvectorfirstandlastonly{hwc}=[somcategvector{hwc}(2);NaN;NaN;somcategvector{hwc}(5)];
            elseif thishwlen==5
                for j=1:5
                    eval(['indexday' num2str(j) '=(yearthishw-yeariwf)*153+(doyday'...
                        num2str(j) 'thishw-apr30doy);']);
                    somcateg=eval(['timeseries(indexday' num2str(j) ',3);']);
                    eval(['somcday' num2str(j) '(somcateg)=somcday' num2str(j) '(somcateg)+1;']);
                    somcategvector{hwc}(j)=somcateg;
                end
                somcategvectorfirstandlastonly{hwc}=[somcategvector{hwc}(1);NaN;NaN;somcategvector{hwc}(5)];
            end
            somcategvectorinclprior{hwc}=[somcategvectorprior{hwc};somcategvectorfirstandlastonly{hwc}];
            temp=somcategvector{hwc}==0;somcategvector{hwc}(temp)=NaN;
        end
    end
    
    if plotbasicsomstats==1
        %Sum up how many heat waves go from each type of SOM pattern to every other for each successive heat-wave day
        %figure(figc);figc=figc+1;hold on;
        %colorstouse=varycolor(size(reghwdoys,2));
        %for hwc=1:size(reghwdoys,2)
            %plot(somcategvector{hwc},'color',colorstouse(hwc,:));
        %end
        %1. Calculate percent frequencies of each kind of transition for days prior to each heat wave,
            %as well as from the first to last day of the heat wave
        countbyijinclpriordayset1=zeros(6,6); %day -20 to day -10
        countbyijinclpriordayset2=zeros(6,6); %day -10 to day -5
        countbyijinclpriordayset3=zeros(6,6); %day -5 to day 1
        countbyijinclpriordayset4=zeros(6,6); %day 1 to last day
        countbyijday1day2=zeros(6,6);countbyijday2day3=zeros(6,6);
        countbyijday3day4=zeros(6,6);countbyijday4day5=zeros(6,6);
        for setofdays=1:4
            if setofdays==1
                firstdayinfullvec=1;seconddayinfullvec=11; %i.e. looking at the transition from 20 days prior to 10 days prior
            elseif setofdays==2
                firstdayinfullvec=11;seconddayinfullvec=16;
            elseif setofdays==3
                firstdayinfullvec=16;seconddayinfullvec=21;
            else
                firstdayinfullvec=21;seconddayinfullvec=24; %first day to last day of heat wave, irrespective of its length
            end
            for hwc=1:size(reghwdoys,2)
                for i=1:6 %possible first-day patterns
                    for j=1:6 %possible second-day patterns
                        if somcategvectorinclprior{hwc}(firstdayinfullvec)==i &&...
                                somcategvectorinclprior{hwc}(seconddayinfullvec)==j
                            eval(['countbyijinclpriordayset' num2str(setofdays) '(i,j)=countbyijinclpriordayset'...
                                num2str(setofdays) '(i,j)+1;']);
                        end
                    end
                end
            end
            %Divide to get frequencies as percentages for each kind of SOM pattern transition, 
                %for each day->subsequent day period
            totalnumvalidtransitions=sum(sum(eval(['countbyijinclpriordayset' num2str(setofdays) ';'])));
            eval(['percfreqbyijinclpriordayset' num2str(setofdays) '=round(100.*countbyijinclpriordayset' ...
                num2str(setofdays) './totalnumvalidtransitions);']);
        end
        %2. Calculate percent frequencies of each kind of transition for each pair of day within each heat wave
        for firstday=1:4 %so second days go from 2 to 5
            for hwc=1:size(reghwdoys,2)
                thishwlen=size(reghwdoys{hwc},1);
                for i=1:6 %possible first-day patterns
                    for j=1:6 %possible second-day patterns
                        if somcategvector{hwc}(firstday)==i && somcategvector{hwc}(firstday+1)==j
                            eval(['countbyijday' num2str(firstday) 'day' num2str(firstday+1)...
                                '(i,j)=countbyijday' num2str(firstday) 'day' num2str(firstday+1) '(i,j)+1;']);
                        end
                    end
                end
            end
            %Divide to get frequencies as percentages for each kind of SOM pattern transition, 
                %for each day->subsequent day period
            totalnumvalidtransitions=sum(sum(eval(['countbyijday' num2str(firstday) 'day' num2str(firstday+1) ';'])));
            eval(['percfreqbyijday' num2str(firstday) 'day' num2str(firstday+1) '=round(100.*countbyijday' ...
                num2str(firstday) 'day' num2str(firstday+1) './totalnumvalidtransitions);']);
        end
        
        %Make plot where line thickness corresponds to percent-frequency category for each heat-wave-day transition
        figure(figc);figc=figc+1;hold on;
        for firstday=1:4
            for i=1:6
                for j=1:6
                    thislinefreq=eval(['percfreqbyijday' num2str(firstday) 'day' num2str(firstday+1) '(i,j);']);
                    if thislinefreq>=25
                        thickness=5;
                    elseif thislinefreq>=15
                        thickness=3;
                    elseif thislinefreq>=5
                        thickness=2;
                    elseif thislinefreq>0
                        thickness=1;
                    else
                        thickness=0;
                    end
                    if thickness~=0 %i.e. if there are any such SOM-pattern transitions at all
                        x=[firstday firstday+1];y=[i j];
                        plot(x,y,'linewidth',thickness);
                    end
                end
            end
        end
        ylim([0 7]);
        
        %Make similar plot, but extending back to before the start of the heat waves, and
            %including only the heat waves' first and last days
        figure(figc);figc=figc+1;hold on;
        curpart=1;highqualityfiguresetup;
        for setofdays=1:4
            if setofdays==1
                firstdayinfullvec=1;seconddayinfullvec=11; %i.e. looking at the transition from 20 days prior to 10 days prior
            elseif setofdays==2
                firstdayinfullvec=11;seconddayinfullvec=16;
            elseif setofdays==3
                firstdayinfullvec=16;seconddayinfullvec=21;
            else
                firstdayinfullvec=21;seconddayinfullvec=24; %first day to last day of heat wave, irrespective of its length
            end
            for i=1:6
                for j=1:6
                    thislinefreq=eval(['percfreqbyijinclpriordayset' num2str(setofdays) '(i,j);']);
                    if thislinefreq>=25
                        thickness=5;
                    elseif thislinefreq>=15
                        thickness=3;
                    elseif thislinefreq>=5
                        thickness=2;
                    elseif thislinefreq>0
                        thickness=1;
                    else
                        thickness=0;
                    end
                    if thickness~=0 %i.e. if there are any such SOM-pattern transitions at all
                        x=[firstdayinfullvec seconddayinfullvec];y=[i j];
                        plot(x,y,'linewidth',thickness);
                    end
                end
            end
        end
        ylim([0 7]);
        set(gca,'xtick',[1 11 16 21 24]);
        datesforlabels={'Day -20';'Day -10';'Day -5';'First Day';'Last Day'};
        set(gca,'XTickLabel',datesforlabels,'fontname','arial','fontweight','bold','fontsize',14);
        %xticklabel_rotate([],45,[],'fontsize',12,'fontname','arial','fontweight','bold');
        ylabel('SOM Cluster','fontsize',14,'fontweight','bold','fontname','arial');
        title('Evolution of 500-hPa SOM-Cluster Frequency Prior to & During Northeast Heat Waves',...
            'fontsize',20,'fontweight','bold','fontname','arial');
        set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname='somclusterfreqinclprior';highqualityfiguresetup;
    end
    
    if plotbasicsompatterns==1
        data{1}=narrlatsreduc;
        data{2}=narrlonsreduc;
        region='usaminushawaii-tight3';
        vararginnew={'variable';'height';'contour';1;'plotCountries';1;...
            'caxismax';200;'caxismin';-200;'overlaynow';0;'anomavg';'avg'};
        vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=1;
        datatype='NARR';
        figure(figc);figc=figc+1;hold on;
        curpart=1;highqualityfiguresetup;
        for clusternum=1:6
            disp(clusternum);
            subplot(3,2,clusternum);
            data{3}=squeeze(Map_som(:,1:size(data{2},2),clusternum));
            [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
            plotModelData(data,region,vararginnew,datatype);
            
            colormap(colormaps('gh','more'));
            %title('SOM Clusters','fontsize',20,'fontname','arial','fontweight','bold');
            %h=colorbar;
            %set(h,'fontsize',14,'fontweight','bold','fontname','arial');
            %ylabel(h,'Anomaly (m)','fontsize',14,'fontweight','bold','fontname','arial');
            text(-0.08,1,strcat(subplotletters{clusternum},')'),'units','normalized',...
                'fontsize',14,'fontweight','bold','fontname','arial');
            if clusternum<=2;rownow=1;elseif clusternum<=4;rownow=2;else rownow=3;end
            if rem(clusternum,2)==1;colnow=1;else colnow=2;end
            fprintf('clusternum: %d, rownow: %d, colnow: %d\n',clusternum,rownow,colnow);
            if colnow==1;colnowpos=0.03;else colnowpos=0.47;end
            if rownow==1;rownowpos=0.34;elseif rownow==2;rownowpos=0.66;else rownowpos=0.98;end
            set(gca,'Position',[colnowpos 1-rownowpos 0.4 0.3]);
        end
        %Make one large colorbar for all subplots
        cbar=colorbar;
        set(get(cbar,'Ylabel'),'String','Anomaly (m)','FontSize',20,'FontWeight','bold','FontName','Arial');
        set(cbar,'FontSize',20,'FontWeight','bold','FontName','Arial');
        cpos=get(cbar,'Position');cpos(1)=0.9;cpos(2)=0.05;cpos(3)=0.017;cpos(4)=0.9;
        set(cbar,'Position',cpos);
        highqualityfiguresetup;
        curpart=2;figloc=curDir;figname='somclustersall';highqualityfiguresetup;
    end
    
    %Daily anomalies composited for each SOM category
    if computecompositeseachsom==1
        disp(clock);
        overalldayindex=0; %day index of all MJJAS days, starting 5/1/81 and continuing until 9/30/15
        for i=1:6
            narrwbt850anomcomposite{i}=zeros(277,349);
            narrt850anomcomposite{i}=zeros(277,349);
            narrshum850anomcomposite{i}=zeros(277,349);
            narrgh500anomcomposite{i}=zeros(277,349);
            narruwnd850anomcomposite{i}=zeros(277,349);
            narrvwnd850anomcomposite{i}=zeros(277,349);
            narruwnd300anomcomposite{i}=zeros(277,349);
            narrvwnd300anomcomposite{i}=zeros(277,349);
        end
        somcategc=zeros(6,1);
        for year=yeariwf:yeariwl
            relyear=year-yeariwf+1;
            for month=monthiwf:monthiwl
                fprintf('Doing NARR composites for SOM patterns in year %d, month %d\n',year,month);
                relmonth=month-monthiwf+1;
                thismontdata=getnarrdatabymonth(runningremotely,'air',year,month);
                thismonshumdata=getnarrdatabymonth(runningremotely,'shum',year,month);
                thismonghdata=getnarrdatabymonth(runningremotely,'hgt',year,month);
                thismonuwnddata=getnarrdatabymonth(runningremotely,'uwnd',year,month);
                thismonvwnddata=getnarrdatabymonth(runningremotely,'vwnd',year,month);
                
                for day=1:monthlengthsdays(relmonth)
                    overalldayindex=overalldayindex+1;
                    thisdaydoy=DatetoDOY(month,day,year);
                    somcateg=timeseries(overalldayindex,3);
                    %fprintf('somcateg for this day is %d\n',somcateg);
                    
                    tarrDOI850dailyavg=mean(thismontdata{3}(:,:,2,day*8-7:day*8),4)-273.15;
                    shumarrDOI850dailyavg=mean(thismonshumdata{3}(:,:,2,day*8-7:day*8),4);
                    wbtarrDOI850dailyavg=calcwbtfromTandshum(tarrDOI850dailyavg,shumarrDOI850dailyavg,1);
                    gharrDOI500dailyavg=mean(thismonghdata{3}(:,:,4,day*8-7:day*8),4);
                    uwndarrDOI850dailyavg=mean(thismonuwnddata{3}(:,:,2,day*8-7:day*8),4);
                    vwndarrDOI850dailyavg=mean(thismonvwnddata{3}(:,:,2,day*8-7:day*8),4);
                    uwndarrDOI300dailyavg=mean(thismonuwnddata{3}(:,:,5,day*8-7:day*8),4);
                    vwndarrDOI300dailyavg=mean(thismonvwnddata{3}(:,:,5,day*8-7:day*8),4);
                    %Also get arrays of this day's averages
                    wbtclim850=wbtclimo850{thisdaydoy};tclim850=tclimo850{thisdaydoy};shumclim850=shumclimo850{thisdaydoy};
                    ghclim500=ghclimo500{thisdaydoy};
                    uwndclim850=uwndclimo850{thisdaydoy};vwndclim850=vwndclimo850{thisdaydoy};
                    uwndclim300=uwndclimo300{thisdaydoy};vwndclim300=vwndclimo300{thisdaydoy};
                    %Anomaly arrays
                    narrwbt850anomcomposite{somcateg}=narrwbt850anomcomposite{somcateg}+(wbtarrDOI850dailyavg-wbtclim850);
                    narrt850anomcomposite{somcateg}=narrt850anomcomposite{somcateg}+(tarrDOI850dailyavg-tclim850);
                    narrshum850anomcomposite{somcateg}=narrshum850anomcomposite{somcateg}+(shumarrDOI850dailyavg-shumclim850);
                    narrgh500anomcomposite{somcateg}=narrgh500anomcomposite{somcateg}+(gharrDOI500dailyavg-ghclim500);
                    narruwnd850anomcomposite{somcateg}=narruwnd850anomcomposite{somcateg}+(uwndarrDOI850dailyavg-uwndclim850);
                    narrvwnd850anomcomposite{somcateg}=narrvwnd850anomcomposite{somcateg}+(vwndarrDOI850dailyavg-vwndclim850);
                    narruwnd300anomcomposite{somcateg}=narruwnd300anomcomposite{somcateg}+(uwndarrDOI300dailyavg-uwndclim300);
                    narrvwnd300anomcomposite{somcateg}=narrvwnd300anomcomposite{somcateg}+(vwndarrDOI300dailyavg-vwndclim300);
                    somcategc(somcateg)=somcategc(somcateg)+1;
                end
                clear thismontdata;clear thismonshumdata;fclose('all');
            end
            save(strcat(curDir,'newanalyses'),'narrwbt850anomcomposite','narrt850anomcomposite',...
                'narrshum850anomcomposite','narrgh500anomcomposite','narruwnd850anomcomposite',...
                'narrvwnd850anomcomposite','narruwnd300anomcomposite','narrvwnd300anomcomposite','-append');
        end
        %Divide to turn sums into composites
        for i=1:6
            narrwbt850anomcomposite{i}=narrwbt850anomcomposite{i}./somcategc(i);
            narrt850anomcomposite{i}=narrt850anomcomposite{i}./somcategc(i);
            narrshum850anomcomposite{i}=narrshum850anomcomposite{i}./somcategc(i);
            narrgh500anomcomposite{i}=narrgh500anomcomposite{i}./somcategc(i);
            narruwnd850anomcomposite{i}=narruwnd850anomcomposite{i}./somcategc(i);
            narrvwnd850anomcomposite{i}=narrvwnd850anomcomposite{i}./somcategc(i);
            narruwnd300anomcomposite{i}=narruwnd300anomcomposite{i}./somcategc(i);
            narrvwnd300anomcomposite{i}=narrvwnd300anomcomposite{i}./somcategc(i);
        end
        save(strcat(curDir,'newanalyses'),'narrwbt850anomcomposite','narrt850anomcomposite',...
            'narrshum850anomcomposite','narrgh500anomcomposite','narruwnd850anomcomposite',...
            'narrvwnd850anomcomposite','narruwnd300anomcomposite','narrvwnd300anomcomposite','-append');
        disp(clock); 
    end
    
    %Plot the above-calculated composites
    if plotcompositeseachsom==1
        if strcmp(vartoplot,'wbt850')
            caxmin=-3;caxmax=3;temp=narrwbt850anomcomposite;kindofvar='wbt';kindofvarshort='wbt';
            unitstouse='(deg C)';fignametouse='wbt850';
        elseif strcmp(vartoplot,'t850')
            caxmin=-3;caxmax=3;temp=narrt850anomcomposite;kindofvar='t';kindofvarshort='t';
            unitstouse='(deg C)';fignametouse='t850';
        elseif strcmp(vartoplot,'gh500')
            caxmin=-120;caxmax=120;temp=narrgh500anomcomposite;kindofvar='hgt';kindofvarshort='gh';
            unitstouse='(m)';fignametouse='gh500';
        end
        data{1}=narrlats;
        data{2}=narrlons;
        region='usaminushawaii-tight3';
        datatype='NARR';
        figure(figc);figc=figc+1;hold on;
        curpart=1;highqualityfiguresetup;
        for somcategtoplot=1:6
            subplot(3,2,somcategtoplot);
            data{3}=temp{somcategtoplot};
            vararginnew={'variable';kindofvar;'contour';1;'plotCountries';1;...
                'caxismin';caxmin;'caxismax';caxmax;'overlaynow';0;'anomavg';'avg'};
            vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=1; 
            [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
                plotModelData(data,region,vararginnew,datatype);
            %title(strcat(['Composite of 850-hPa WBT Anomalies for SOM Cluster',' ',num2str(somcategtoplot)]),...
            %    'fontsize',18,'fontweight','bold','fontname','arial');
            colormap(colormaps(kindofvarshort,'more'));
            text(-0.08,1,strcat(subplotletters{somcategtoplot},')'),'units','normalized',...
                'fontsize',14,'fontweight','bold','fontname','arial');
            if somcategtoplot<=2;rownow=1;elseif somcategtoplot<=4;rownow=2;else rownow=3;end
            if rem(somcategtoplot,2)==1;colnow=1;else colnow=2;end
            fprintf('somcategtoplot: %d, rownow: %d, colnow: %d\n',somcategtoplot,rownow,colnow);
            if colnow==1;colnowpos=0.03;else colnowpos=0.47;end
            if rownow==1;rownowpos=0.34;elseif rownow==2;rownowpos=0.66;else rownowpos=0.98;end
            set(gca,'Position',[colnowpos 1-rownowpos 0.4 0.3]);
            
        end
        %Make one large colorbar for all subplots
        cbar=colorbar;
        set(get(cbar,'Ylabel'),'String',strcat(['Anomaly',' ',unitstouse]),...
            'FontSize',20,'FontWeight','bold','FontName','Arial');
        set(cbar,'FontSize',20,'FontWeight','bold','FontName','Arial');
        cpos=get(cbar,'Position');cpos(1)=0.9;cpos(2)=0.05;cpos(3)=0.017;cpos(4)=0.9;
        set(cbar,'Position',cpos);
        
        %Finalize figure
        curpart=2;figloc=curDir;figname=strcat('somcompall',fignametouse);
        highqualityfiguresetup;
    end
end


%Scatterplot of WBT vs gh500 at EWR and at JFK, to see 1. how strong the correlations are, and
    %2. if there are differences between the two stations
%gh500 data is contained in the array Z500alldays
    %Currently, non-NaN data are in DOY 121-273, i.e. May 1-Sep 30 (153 days per year)
%WBT data is contained in the array finaldatawbt

%ANSWER: for all days at EWR & JFK, relationship is actually quite weak, making things interesting
if ghwbtscatterplot==1
    if dostns==1
        for stn=1:2
            if stn==1 %EWR
                stnnum=94;stntz=5;
            elseif stn==2 %JFK
                stnnum=179;stntz=5;
            end
            stnlat=newstnNumListlats(stnnum);stnlon=newstnNumListlons(stnnum);
            temp=wnarrgridpts(stnlat,stnlon,1,0,0);
            stnlatordnarr=temp(1,1);stnlonordnarr=temp(1,2);

            c=1;
            for year=2:yeariwl-yeariwf %1982-2014
                for day=121:273
                    thismon=DOYtoMonth(day,year+yeariwf-1);
                    if thismon==4;thismon=5;end
                    z500thisday(stn,c)=Z500alldays(day,year,stnlatordnarr,stnlonordnarr);
                    wbtthisdayeachhour=finaldatawbt{year,stnnum}((day-120)*24-23+stntz:(day-120)*24+stntz);
                    wbtthisday(stn,c)=max(wbtthisdayeachhour);
                    tthisdayeachhour=finaldatat{year,stnnum}((day-120)*24-23+stntz:(day-120)*24+stntz);
                    tthisday(stn,c)=max(tthisdayeachhour);
                    z500anomthisday(stn,c)=Z500_anom(((year-1)*153)+day,((stnlatordnarr-1)*nlon)+stnlonordnarr);
                    wbtanomthisday(stn,c)=wbtthisday(stn,c)-avgdailymaxthismonth{2}(stnnum,thismon-monthiwf+1);
                    tanomjfkthisday(stn,c)=tthisday(stn,c)-avgdailymaxthismonth{1}(stnnum,thismon-monthiwf+1);
                    c=c+1;
                end
            end
        end
    end
    
    %Region averages of daily-avg WBT anom vs daily gh500 anom, for top-100 days only
    %First, have to recompute regional averages from station data, as none of the existing arrays are
    %precisely what's needed here
    %1. Compute daily avgs for each station
    for var=1:2
        if var==1;topXXarray=finaldatat;else topXXarray=finaldatawbt;end
        for stn=1:190
            fprintf('stn is %d\n',stn);
            dailyavg{stn}=ones.*NaN(35,366);
            for year=1:35
                if rem(year,4)==0;apr30doy=121;else apr30doy=120;end
                temp=topXXarray{year,stn}<=-50;topXXarray{year,stn}(temp)=NaN;
                [~,~,~,thisstntz]=stationinfofromnumber(newstnNumList(stn));
                day=apr30doy+1;
                for hourmidnightofday=thisstntz+1:24:4416-23
                    dailyavg{stn}(year,day)=nanmean(topXXarray{year,stn}(hourmidnightofday:hourmidnightofday+23));
                    day=day+1;
                end
            end
        end
        if var==1;dailyavgt=dailyavg;else dailyavgwbt=dailyavg;end
    end
    
    %2. Combine these into daily values & DOY avgs for each region
    for var=1:2
        if var==1;dailyavg=dailyavgt;else dailyavg=dailyavgwbt;end
        mysum=zeros(366,8);mycount=zeros(366,8);myvalstemp=zeros(35,366,8);
        
        for day=1:366
            for year=1:35
                stnceachregion=zeros(8,1);
                for stn=1:190
                    thisregion=ncaregionnum{stn};
                    if ~isnan(dailyavg{stn}(year,day)) && dailyavg{stn}(year,day)>=0 && dailyavg{stn}(year,day)<50
                        myvalstemp(year,day,thisregion)=myvalstemp(year,day,thisregion)+dailyavg{stn}(year,day);
                        mysum(day,thisregion)=mysum(day,thisregion)+dailyavg{stn}(year,day);
                        mycount(day,thisregion)=mycount(day,thisregion)+1;
                        stnceachregion(thisregion)=stnceachregion(thisregion)+1;
                        if var==1 && thisregion==6 && year==26 && day==190;disp(dailyavg{stn}(year,day));disp(stn);end
                    end
                end
                for reg=1:8
                    myvals{var}(year,day,reg)=myvalstemp(year,day,reg)./stnceachregion(reg);
                    %if day==190;disp(myvalstemp(year,day,reg));disp(stnceachregion(thisregion));end
                end
                
            end
            for reg=1:8;myavg{var}(day,reg)=mysum(day,reg)./mycount(day,reg);end
        end
    end
    save(strcat(curDir,'newanalyses2'),'myavg','myvals','-append');
    
    %3. Get NARR Z500 arrays for every MJJAS day in 1981-2015, and put it all in a big array
    %(this is similar to what's done in cluster_code_hgt, but here we care about complete spatial coverage)
    narrdir='/Volumes/MacFormatted4TBExternalDrive/NARR_daily_data_raw/';
    varname='hgt';invalidval=3*10^4;
    Z500alldays=NaN.*ones(35,184,277,349);
    for y=yeariwf:yeariwl
        fprintf('Getting data for year %d\n',y);
        relyear=y-yeariwf+1;
        if rem(y,4) == 0 % leap year
            season_length=184;
            index_days = (122:274)'; %May 1 - Sep 30
        else % all other years
            season_length=184;
            index_days = (121:273)'; %May 1 - Sep 30
        end
        
        daycthisyear=0;
        for m=monthiwf:monthiwl
            filename=strcat(narrdir,varname,'.',num2str(y),'0',num2str(m),'.nc');
            %Get the 500-hPa geopotential-height data for this day for the whole region of interest
            Z500_dummy = ncread(filename, 'hgt');
            thismonlen=size(Z500_dummy,4);
            dayctostartat=daycthisyear+1;daycthisyear=daycthisyear+thismonlen;
            doytostartat=dayctostartat+index_days(1)-1; %DOY of first day of this month
            doytostopat=doytostartat+thismonlen-1; %DOY of last day of this month
            
            temp=abs(Z500_dummy)>=invalidval;Z500_dummy(temp)=NaN;
            Z500_dummy=squeeze(permute(Z500_dummy(:,:,17,:),[3 4 2 1]));%disp(size(Z500_dummy));
            Z500_dummy2(1,:,:,:)=Z500_dummy;
            Z500alldays(relyear,daycthisyear:daycthisyear+thismonlen-1,:,:) = Z500_dummy2;
            %Z500alldays(121:304,1,1:181,1:266) = Z500_dummy;
            clear Z500_dummy;clear Z500_dummy2;
        end
    end
    %save(strcat(curDir,'newanalyses2'),'Z500alldays','-append'); %needs to be saved as -v7.3
    
    %Compute anomalies for extreme-T and extreme-WBT days (40 min)
    for var=1:2
        if var==1;topXXarray=topXXtbyregionsorted;else topXXarray=topXXwbtbyregionsorted;end
        anomz500thisday{var}=zeros(100,8,277,349);clear Z500_dummy;clear Z500_dummy2;
        for region=1:8
            fprintf('Region is %d\n',region);
            for i=1:100
                thisyear=topXXarray{region}(i,1);
                thismonth=topXXarray{region}(i,2);
                thisday=topXXarray{region}(i,3);
                thisdoy=DatetoDOY(thismonth,thisday,thisyear);
                
                %T and WBT anoms on top-100 days
                actualregionaltorwbtthisday=myvals{var}(thisyear-yeariwf+1,thisdoy,region);
                if abs(mean(myvals{var}(30,122:303,5))-mean(myavg{var}(122:303,5)))>=3 %vals are off this year, probably b/c a missing stn
                    if thisdoy>=152 && thisdoy<=240
                        avgregionaltorwbtthisday=mean(myvals{var}(thisyear-yeariwf+1,thisdoy-30:thisdoy+30,region));
                    else
                        avgregionaltorwbtthisday=NaN;
                    end
                else
                    avgregionaltorwbtthisday=myavg{var}(thisdoy,region);
                end
                anomregionaltorwbtthisday{var}(i,region)=actualregionaltorwbtthisday-avgregionaltorwbtthisday;
                
                %Z500 anoms on top-100 days
                filename=strcat(narrdir,varname,'.',num2str(thisyear),'0',num2str(thismonth),'.nc');
                Z500_dummy = ncread(filename, 'hgt');
                temp=abs(Z500_dummy)>=invalidval;Z500_dummy(temp)=NaN;
                Z500_dummy=squeeze(permute(Z500_dummy(:,:,17,:),[3 4 2 1]));%disp(size(Z500_dummy));
                Z500_dummy2(1,:,:,:)=Z500_dummy;clear Z500_dummy;
                actualz500thisday=Z500_dummy2(1,thisday,:,:);clear Z500_dummy2;
                regfilter=ncalist==region;
                temp=regfilter.*squeeze(squeeze(actualz500thisday));temp2=temp==0;temp(temp2)=NaN;
                anomz500thisday{var}(i,region,:,:)=temp;
            end
        end
        for reg=1:8;anomz500thisdaybyreg{var}(reg,:)=nanmean(squeeze(nanmean(anomz500thisday{var}(:,reg,:,:),3)),2);end
    end
    save(strcat(curDir,'newanalyses2'),'anomz500thisday','anomz500thisdaybyreg','-append');
    
    %Finally, scatterplot of anom z500 vs anom T, and anom z500 vs anom WBT, for each region
    for regtoplot=1:8
    for var=1:2
        figure(figc);clf;figc=figc+1;
        z500pts=anomz500thisdaybyreg{var}(regtoplot,:)';
        varpts=anomregionaltorwbtthisday{var}(:,regtoplot);
        scatter(z500pts,varpts);
    end
    end
    %Within the extreme days, there's not much going on in these scatterplots...
end

%Uses 3-hourly NARR data to calculate 850-hPa T and q advection at each gridpt in
    %a region at each hour during certain heat waves
if calctqadvectionacrossaregion==1
    
    validpts=narrgridptsparallelogram(minlat,minlon,minlat,maxlon,maxlat,maxlon,maxlat,minlon);
        %points within the defined parallelogram are indicated by 1's in the validpts array
        %Pts that I want to calculate this stuff for are in the Northeast, basically (land and ocean both OK)
    
    for hw=1:size(reghwdoys,2)
    %for hw=21:21
        fprintf('Heat wave #%d\n',hw);
        daystoplot=reghwdoys{hw};
        aztadvarray={};azqadvarray={};azwbtadvarray={};simplecountarray={};
        
        for day=1:size(daystoplot,1)
        %for day=2:2
            fprintf('Day of hw is %d\n',day);
            thisdaydoy=daystoplot(day,1);
            year=daystoplot(day,2);
            month=DOYtoMonth(thisdaydoy,year);
            thisdaydom=DOYtoDOM(thisdaydoy,year);
            
            tadvarray{hw,day}=NaN.*ones(277,349,8);
            qadvarray{hw,day}=NaN.*ones(277,349,8);
            wbtcontribtadvarray{hw,day}=NaN.*ones(277,349,8);
            wbtcontribqadvarray{hw,day}=NaN.*ones(277,349,8);
            obstchangearray{hw,day}=NaN.*ones(277,349,8);
            obsqchangearray{hw,day}=NaN.*ones(277,349,8);
            obswbtchangearray{hw,day}=NaN.*ones(277,349,8);
            wbtcontribobstchangearray{hw,day}=NaN.*ones(277,349,8);
            wbtcontribobsqchangearray{hw,day}=NaN.*ones(277,349,8);
            dailysumtadvarray{hw,day}=NaN.*ones(277,349);
            dailysumqadvarray{hw,day}=NaN.*ones(277,349);
            dailysumwbtadvarray{hw,day}=NaN.*ones(277,349);
            dailysumwbtcontribtadvarray{hw,day}=NaN.*ones(277,349);
            dailysumwbtcontribqadvarray{hw,day}=NaN.*ones(277,349);
            dailysumobstchangearray{hw,day}=NaN.*ones(277,349);
            dailysumobsqchangearray{hw,day}=NaN.*ones(277,349);
            dailysumobswbtchangearray{hw,day}=NaN.*ones(277,349);
            dailysumwbtcontribobstchangearray{hw,day}=NaN.*ones(277,349);
            dailysumwbtcontribobsqchangearray{hw,day}=NaN.*ones(277,349);
            
            %Load in data for this month
            curArr{1}=getnarrdatabymonth(runningremotely,'air',year,month);curArr{2}=getnarrdatabymonth(runningremotely,'shum',year,month);
            curArr{3}=getnarrdatabymonth(runningremotely,'hgt',year,month);curArr{4}=getnarrdatabymonth(runningremotely,'uwnd',year,month);
            curArr{5}=getnarrdatabymonth(runningremotely,'vwnd',year,month);
            if thisdaydom==monthlengthsdays(month-monthiwf+1) %last day of month
                nextmonArr{1}=getnarrdatabymonth(runningremotely,'air',year,month+1);
                nextmonArr{2}=getnarrdatabymonth(runningremotely,'shum',year,month+1);
                nextmonArr{3}=getnarrdatabymonth(runningremotely,'hgt',year,month+1);
                nextmonArr{4}=getnarrdatabymonth(runningremotely,'uwnd',year,month+1);
                nextmonArr{5}=getnarrdatabymonth(runningremotely,'vwnd',year,month+1);
            end
            
            %Extract data from these arrays
            for hr=1:8 %DOI is day of interest, offsets to obtain hours are needed because dim(curArr{3})~277x349x5x240
                eval(['tarrDOI' hours{hr} '=curArr{1}{3}(:,:,presleveliw(1),thisdaydom*8+ ' num2str(hr-8) ')-273.15;']);
                eval(['shumarrDOI' hours{hr} '=curArr{2}{3}(:,:,presleveliw(2),thisdaydom*8+ ' num2str(hr-8) ');']);
                eval(['hgtarrDOI' hours{hr} '=curArr{3}{3}(:,:,presleveliw(3),thisdaydom*8+ ' num2str(hr-8) ');']);
                eval(['uwndarrDOI' hours{hr} '=curArr{4}{3}(:,:,presleveliw(4),thisdaydom*8+ ' num2str(hr-8) ');']);
                eval(['vwndarrDOI' hours{hr} '=curArr{5}{3}(:,:,presleveliw(5),thisdaydom*8+ ' num2str(hr-8) ');']);
                if thisdaydom~=monthlengthsdays(month-monthiwf+1) %not the last day of the month
                    eval(['tarrDOI' hours{hr} 'nextday=curArr{1}{3}(:,:,presleveliw(1),(thisdaydom+1)*8+ ' num2str(hr-8) ')-273.15;']);
                    eval(['shumarrDOI' hours{hr} 'nextday=curArr{2}{3}(:,:,presleveliw(2),(thisdaydom+1)*8+ ' num2str(hr-8) ');']);
                    eval(['hgtarrDOI' hours{hr} 'nextday=curArr{3}{3}(:,:,presleveliw(3),(thisdaydom+1)*8+ ' num2str(hr-8) ');']);
                    eval(['uwndarrDOI' hours{hr} 'nextday=curArr{4}{3}(:,:,presleveliw(4),(thisdaydom+1)*8+ ' num2str(hr-8) ');']);
                    eval(['vwndarrDOI' hours{hr} 'nextday=curArr{5}{3}(:,:,presleveliw(5),(thisdaydom+1)*8+ ' num2str(hr-8) ');']);
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
                %For current time
                shumarrDOIthishr=eval(['shumarrDOI' hours{hr} ';']);
                tarrDOIthishr=eval(['tarrDOI' hours{hr} ';']);
                eval(['wbtarrDOI' hours{hr} '=calcwbtfromTandshum(tarrDOIthishr,shumarrDOIthishr,1);']);
                %For next time (i.e. 3 hours later)
                if hr==8 %last hour of day
                    shumarrDOInexthr=eval(['shumarrDOI' hours{1} 'nextday;']);
                    tarrDOInexthr=eval(['tarrDOI' hours{1} 'nextday;']);
                else
                    shumarrDOInexthr=eval(['shumarrDOI' hours{hr+1} ';']);
                    tarrDOInexthr=eval(['tarrDOI' hours{hr+1} ';']);
                end
                eval(['wbtarrDOI' hours{hr} 'nexthr=calcwbtfromTandshum(tarrDOInexthr,shumarrDOInexthr,1);']);
            end
            
            %Now, calculate advection at each point using
            %standard formula of -u*dT/dx-v*dT/dy, giving a result in K/s
            for i=1:277
                if rem(i,20)==0;disp(i);end
                for j=1:349
                    if validpts(i,j)==1 %this is a point of interest
                        dailysumtadv=0;dailysumqadv=0;dailysumwbtadv=0;
                        dailysumwbtcontribtadv=0;dailysumwbtcontribqadv=0;
                        dailysumobstchange=0;dailysumobsqchange=0;dailysumobswbtchange=0;
                        dailysumwbtcontribobstchange=0;dailysumwbtcontribobsqchange=0;
                        dailysumt=0;dailysumq=0;dailysumwbt=0;     
                        alltheptsdata=zeros(7,5);
                        
                        thisptlat=narrlats(i,j);thisptlon=narrlons(i,j);
                        closestpts=wnarrgridpts(thisptlat,thisptlon,1,1,0);
                        for k=1:size(closestpts,1)
                            azimuthtopts(k)=azimuthfromnarrgridpts(closestpts(1,1),closestpts(1,2),...
                                closestpts(k,1),closestpts(k,2));
                        end
                        if size(azimuthtopts,1)==1;azimuthtopts=azimuthtopts';end
                        
                        

                        %Dimensions of alltheptsdata are NARRx|NARRy|fractional weight|azimuth to pt|(azimuth to pt)-(wind azimuth)
                        alltheptsdata(:,1:3)=closestpts(2:8,1:3); %don't include the point of interest itself
                        alltheptsdata(:,4)=azimuthtopts(2:8);
                        distpoipt1=distance('gc',[narrlats(i,j),narrlons(i,j)],...
                            [narrlats(alltheptsdata(1,1),alltheptsdata(1,2)),narrlons(alltheptsdata(1,1),...
                            alltheptsdata(1,2))])*111; %in km
                        distpoipt2=distance('gc',[narrlats(i,j),narrlons(i,j)],...
                            [narrlats(alltheptsdata(2,1),alltheptsdata(2,2)),narrlons(alltheptsdata(2,1),...
                            alltheptsdata(2,2))])*111; %in km
                        
                        
                                          
                        for hr=1:8
                            %Part I. Winds at gridpt of interest
                            uwndarr=eval(['uwndarrDOI' hours{hr}]);uwndthishr=uwndarr(i,j);
                            vwndarr=eval(['vwndarrDOI' hours{hr}]);vwndthishr=vwndarr(i,j);
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
                            for k=1:size(azimuthtopts,1)
                               azdifftopts(k)=abs(wndaz-azimuthtopts(k));
                               if abs(azdifftopts(k))>180
                                   azdifftopts(k)=abs(360-abs(azdifftopts(k))); %so we can go both ways around the circle 
                               end
                            end
                            alltheptsdata(:,5)=azdifftopts(2:8);
                            %Sort to find the two stations that bracket the direction the wind is coming from
                            %Now, the top 2 pts are the ones to use for advection
                            %Weights are based on angular difference between azimuth to them and wind azimuth, and not on distance from POI
                            alltheptsdata=sortrows(alltheptsdata,5); 
                            totalangulardiff=alltheptsdata(1,5)+alltheptsdata(2,5);
                            weightpt1=(totalangulardiff-alltheptsdata(1,5))/totalangulardiff;
                            weightpt2=(totalangulardiff-alltheptsdata(2,5))/totalangulardiff;
                            

                            %Part III. This hr's T, q, & WBT at POI as well as at ones that wind is advecting from
                            tarrthishr=eval(['tarrDOI' hours{hr} ';']);qarrthishr=eval(['shumarrDOI' hours{hr} ';']);
                            wbtarrthishr=eval(['wbtarrDOI' hours{hr} ';']);
                            tptpoi=tarrthishr(i,j);qptpoi=qarrthishr(i,j);
                            wbtptpoi=wbtarrthishr(i,j);
                            %disp('At this hour, 850hPa T, q, & WBT at POI, plus wind mag & azimuth:');
                            %disp(tptpoi);disp(qptpoi);disp(wbtptpoi);disp(wndmag);disp(wndaz);
                            %for k=2:8
                                %fprintf('At this hour, T, q, & WBT at (%d,%d) are %d, %d, %d\n',closestpts(k,1),closestpts(k,2),...
                                %    tarrthishr(closestpts(k,1),closestpts(k,2)),qarrthishr(closestpts(k,1),closestpts(k,2)),...
                                %    wbtarrthishr(closestpts(k,1),closestpts(k,2)));
                            %end
                            tpt1=tarrthishr(alltheptsdata(1,1),alltheptsdata(1,2));
                            qpt1=qarrthishr(alltheptsdata(1,1),alltheptsdata(1,2));
                            wbtpt1=wbtarrthishr(alltheptsdata(1,1),alltheptsdata(1,2));
                            tpt2=tarrthishr(alltheptsdata(2,1),alltheptsdata(2,2));
                            qpt2=qarrthishr(alltheptsdata(2,1),alltheptsdata(2,2));
                            wbtpt2=wbtarrthishr(alltheptsdata(2,1),alltheptsdata(2,2));

                            %Part IV. Calculation of advection using this hour's temps and winds
                            %Changes are calculated forward, i.e. from this hour to the next
                            %Also, compare these values with the observed T and q/WBT change
                            tgradtopt1=(tpt1-tptpoi)/(distpoipt1*1000);tgradtopt2=(tpt2-tptpoi)/(distpoipt1*1000); %in K/m
                            qgradtopt1=(qpt1-qptpoi)/(distpoipt1*1000);qgradtopt2=(qpt2-qptpoi)/(distpoipt1*1000); %in (kg/kg)/m
                            wbtgradtopt1=(wbtpt1-wbtptpoi)/(distpoipt1*1000);wbtgradtopt2=(wbtpt2-wbtptpoi)/(distpoipt1*1000); %in K/m

                            tadv=wndmag*tgradtopt1*weightpt1+wndmag*tgradtopt2*weightpt2; %in K/s
                            qadv=wndmag*1000*qgradtopt1*weightpt1+wndmag*qgradtopt2*weightpt2; %in (g/kg)/s
                            wbtadv=wndmag*wbtgradtopt1*weightpt1+wndmag*wbtgradtopt2*weightpt2; %in K/s
                            [wbttslope,wbtqslope,wbtarray]=calcWBTslopes(tptpoi,1000*qptpoi); %WBT slopes in the current conditions
                            wbtcontribtadv=wbttslope*tadv*10800; %tadv is the total advection-induced T change over 3 hours, in K;
                                %wbttslope is the deltaWBT/deltaT slope at the current T, so that the product gives the
                                %WBT change that this T change is responsible for
                            wbtcontribqadv=wbtqslope*qadv*10800; %ditto for q
                            if isnan(wbttslope);disp('wbttslope=NaN');return;end
                            if isnan(wbtqslope);disp('wbtqslope=NaN');return;end
                            dailysumtadv=dailysumtadv+tadv;dailysumqadv=dailysumqadv+qadv;
                            dailysumwbtadv=dailysumwbtadv+wbtadv;
                            dailysumwbtcontribtadv=dailysumwbtcontribtadv+wbtcontribtadv;
                            dailysumwbtcontribqadv=dailysumwbtcontribqadv+wbtcontribqadv;
                            %fprintf('T advection, q advection, and WBT advection at this hour are %d K/hr, %d (kg/kg)/hr, & %d K/hr\n',...
                            %    tadv*3600,qadv*3600,wbtadv*3600);
                            %fprintf('qslope is %d; qadv*10800 is %d;wbtcontribqadv is %d\n',wbtqslope,qadv*10800,wbtcontribqadv);

                            if hr==8 %nexthr is on the next day
                                tarrnexthr=eval(['tarrDOI' hours{1} 'nextday;']);qarrnexthr=eval(['shumarrDOI' hours{1} 'nextday;']);
                                wbtarrnexthr=eval(['wbtarrDOI' hours{hr} 'nexthr;']); %i.e. the next hour from this hour
                            else
                                tarrnexthr=eval(['tarrDOI' hours{hr+1} ';']);qarrnexthr=eval(['shumarrDOI' hours{hr+1} ';']);
                                wbtarrnexthr=eval(['wbtarrDOI' hours{hr} 'nexthr;']); %i.e. the next hour from this hour
                            end
                            tptpoinexthr=tarrnexthr(i,j);qptpoinexthr=qarrnexthr(i,j);
                            wbtptpoinexthr=wbtarrnexthr(i,j);
                            obstchange=tptpoinexthr-tptpoi;obsqchange=1000*(qptpoinexthr-qptpoi); %obsqchange in g/kg
                            obswbtchange=wbtptpoinexthr-wbtptpoi;
                            wbtcontribobstchange=wbttslope*obstchange; %same as above wbtcontrib but for observed changes
                            wbtcontribobsqchange=wbtqslope*obsqchange;
                            %if i==139 && j==244
                            %    disp(tptpoi);disp(1000*qptpoi);disp(wbttslope);disp(wbtqslope);
                            %    disp(obstchange);disp(obsqchange);disp(wbtcontribobstchange);disp(wbtcontribobsqchange);
                            %end
                            dailysumobstchange=dailysumobstchange+obstchange;dailysumobsqchange=dailysumobsqchange+obsqchange;
                            dailysumobswbtchange=dailysumobswbtchange+obswbtchange;
                            dailysumwbtcontribobstchange=dailysumwbtcontribobstchange+wbtcontribobstchange;
                            dailysumwbtcontribobsqchange=dailysumwbtcontribobsqchange+wbtcontribobsqchange;
                            %dailysumt=dailysumt+tptpoi;dailysumq=dailysumq+qptpoi;dailysumwbt=dailysumwbt+wbtptpoi;
                            %fprintf('Observed T, q, and WBT change at this hour are %d K/hr, %d (kg/kg)/hr, & %d K/hr\n',...
                            %    obstchange/3,obsqchange/3,obswbtchange/3);
                            %fprintf('WBT contrib at this hour is %d from obs T change and %d from obs q change\n',...
                            %    wbtcontribobstchange,wbtcontribobsqchange);
                            
                            %Save findings into arrays
                            tadvarray{hw,day}(i,j,hr)=tadv;
                            qadvarray{hw,day}(i,j,hr)=qadv;
                            wbtcontribtadvarray{hw,day}(i,j,hr)=wbtcontribtadv;
                            wbtcontribqadvarray{hw,day}(i,j,hr)=wbtcontribqadv;
                            obstchangearray{hw,day}(i,j,hr)=obstchange;
                            obsqchangearray{hw,day}(i,j,hr)=obsqchange;
                            obswbtchangearray{hw,day}(i,j,hr)=obswbtchange;
                            wbtcontribobstchangearray{hw,day}(i,j,hr)=wbtcontribobstchange;
                            wbtcontribobsqchangearray{hw,day}(i,j,hr)=wbtcontribobsqchange;

                            %If at the end of a day, calculate daily averages in units of (units)/per day
                            %All q arrays are in g/kg
                            if hr==8
                                dailysumtadv=24*3600*dailysumtadv/8;dailysumqadv=24*3600*dailysumqadv/8;dailysumwbtadv=24*3600*dailysumwbtadv/8;
                                dailysumtadvarray{hw,day}(i,j)=dailysumtadv;
                                dailysumqadvarray{hw,day}(i,j)=dailysumqadv;
                                dailysumwbtadvarray{hw,day}(i,j)=dailysumwbtadv;
                                dailysumwbtcontribtadvarray{hw,day}(i,j)=dailysumwbtcontribtadv;
                                dailysumwbtcontribqadvarray{hw,day}(i,j)=dailysumwbtcontribqadv;
                                dailysumobstchangearray{hw,day}(i,j)=dailysumobstchange;
                                dailysumobsqchangearray{hw,day}(i,j)=dailysumobsqchange;
                                dailysumobswbtchangearray{hw,day}(i,j)=dailysumobswbtchange;
                                dailysumwbtcontribobstchangearray{hw,day}(i,j)=dailysumwbtcontribobstchange;
                                dailysumwbtcontribobsqchangearray{hw,day}(i,j)=dailysumwbtcontribobsqchange;
                                %fprintf('Total T adv on this day is %d; total obs T change is %d\n',dailysumtadv,dailysumobstchange);
                                %fprintf('Total q adv on this day is %d; total obs q change is %d\n',dailysumqadv,dailysumobsqchange);
                                %fprintf('Today: wbtcontrib from tadv is %d, wbtcontrib from qadv is %d\n',dailysumwbtcontribtadv,dailysumwbtcontribqadv);
                                %fprintf('Today: wbtcontrib from obstchange is %d, wbtcontrib from obsqchange is %d\n',...
                                %dailysumwbtcontribobstchange,dailysumwbtcontribobsqchange);
                                %if ~thisislastday;dailysumtchange=dailysumt-dailysumtprev;end
                                %fprintf('Today and previous day avg T are %d, %d\n',dailysumt,dailysumtprev);
                            end
                        end
                    end
                end
            end
        end
        disp(clock);
        save(strcat(curDir,'newanalyses'),'tadvarray','qadvarray','wbtcontribtadvarray','wbtcontribqadvarray',...
            'obstchangearray','obsqchangearray','obswbtchangearray','wbtcontribobstchangearray','wbtcontribobsqchangearray',...
            'dailysumtadvarray','dailysumqadvarray','dailysumwbtadvarray','dailysumwbtcontribtadvarray',...
            'dailysumwbtcontribqadvarray','dailysumobstchangearray','dailysumobsqchangearray','dailysumobswbtchangearray',...
            'dailysumwbtcontribobstchangearray','dailysumwbtcontribobsqchangearray','-append');
    end
end


%Using the arrays just calculated, create averages over heat waves
if createtqavgs==1
    if strcmp(desreg,'ne') || strcmp(desreg,'sw')
        dailysumobstchangearray=eval(['dailysumobstchangearray' desreg ';']);
        dailysumobsqchangearray=eval(['dailysumobsqchangearray' desreg ';']);
        dailysumwbtcontribobstchangearray=eval(['dailysumwbtcontribobstchangearray' desreg ';']);
        dailysumwbtcontribobsqchangearray=eval(['dailysumwbtcontribobsqchangearray' desreg ';']);
        dailysumtadvarray=eval(['dailysumtadvarray' desreg ';']);
        dailysumqadvarray=eval(['dailysumqadvarray' desreg ';']);
        dailysumwbtcontribtadvarray=eval(['dailysumwbtcontribtadvarray' desreg ';']);
        dailysumwbtcontribqadvarray=eval(['dailysumwbtcontribqadvarray' desreg ';']);
    else
        disp('Please select a region for which things have already been calculated.');return;
    end
    obstchangesum=zeros(5,277,349); %5 for 5 days max within a hw
    obsqchangesum=zeros(5,277,349);
    wbtcontribobstchangesum=zeros(5,277,349);
    wbtcontribobsqchangesum=zeros(5,277,349);
    tadvsum=zeros(5,277,349);
    qadvsum=zeros(5,277,349);
    wbtcontribtadvsum=zeros(5,277,349);
    wbtcontribqadvsum=zeros(5,277,349);
    hwdaysc=zeros(5,1);
    %for hw=1:size(reghwdoys,2)
    for hw=1:20
        hwlen=size(reghwdoys{hw},1);
        for dayofhw=1:hwlen
            if hwlen==3
                obstchangesum(dayofhw+1,:,:)=...
                    squeeze(obstchangesum(dayofhw+1,:,:))+dailysumobstchangearray{hw,dayofhw};
                obsqchangesum(dayofhw+1,:,:)=...
                    squeeze(obsqchangesum(dayofhw+1,:,:))+dailysumobsqchangearray{hw,dayofhw};
                wbtcontribobstchangesum(dayofhw+1,:,:)=...
                    squeeze(wbtcontribobstchangesum(dayofhw+1,:,:))+dailysumwbtcontribobstchangearray{hw,dayofhw};
                wbtcontribobsqchangesum(dayofhw+1,:,:)=...
                    squeeze(wbtcontribobsqchangesum(dayofhw+1,:,:))+dailysumwbtcontribobsqchangearray{hw,dayofhw};
                tadvsum(dayofhw+1,:,:)=squeeze(tadvsum(dayofhw+1,:,:))+dailysumtadvarray{hw,dayofhw};
                qadvsum(dayofhw+1,:,:)=squeeze(qadvsum(dayofhw+1,:,:))+dailysumqadvarray{hw,dayofhw};
                wbtcontribtadvsum(dayofhw+1,:,:)=...
                    squeeze(wbtcontribtadvsum(dayofhw+1,:,:))+dailysumwbtcontribtadvarray{hw,dayofhw};
                wbtcontribqadvsum(dayofhw+1,:,:)=...
                    squeeze(wbtcontribqadvsum(dayofhw+1,:,:))+dailysumwbtcontribqadvarray{hw,dayofhw};
                hwdaysc(dayofhw+1)=hwdaysc(dayofhw+1)+1;
            else
                obstchangesum(dayofhw,:,:)=...
                    squeeze(obstchangesum(dayofhw,:,:))+dailysumobstchangearray{hw,dayofhw};
                obsqchangesum(dayofhw,:,:)=...
                    squeeze(obsqchangesum(dayofhw,:,:))+dailysumobsqchangearray{hw,dayofhw};
                wbtcontribobstchangesum(dayofhw,:,:)=...
                    squeeze(wbtcontribobstchangesum(dayofhw,:,:))+dailysumwbtcontribobstchangearray{hw,dayofhw};
                wbtcontribobsqchangesum(dayofhw,:,:)=...
                    squeeze(wbtcontribobsqchangesum(dayofhw,:,:))+dailysumwbtcontribobsqchangearray{hw,dayofhw};
                tadvsum(dayofhw,:,:)=squeeze(tadvsum(dayofhw,:,:))+dailysumtadvarray{hw,dayofhw};
                qadvsum(dayofhw,:,:)=squeeze(qadvsum(dayofhw,:,:))+dailysumqadvarray{hw,dayofhw};
                wbtcontribtadvsum(dayofhw,:,:)=...
                    squeeze(wbtcontribtadvsum(dayofhw,:,:))+dailysumwbtcontribtadvarray{hw,dayofhw};
                wbtcontribqadvsum(dayofhw,:,:)=...
                    squeeze(wbtcontribqadvsum(dayofhw,:,:))+dailysumwbtcontribqadvarray{hw,dayofhw};
                hwdaysc(dayofhw)=hwdaysc(dayofhw)+1;
            end
        end
    end
    for i=1:5
        obstchangesum(i,:,:)=obstchangesum(i,:,:)./hwdaysc(i);
        obsqchangesum(i,:,:)=obsqchangesum(i,:,:)./hwdaysc(i);
        wbtcontribobstchangesum(i,:,:)=wbtcontribobstchangesum(i,:,:)./hwdaysc(i);
        wbtcontribobsqchangesum(i,:,:)=wbtcontribobsqchangesum(i,:,:)./hwdaysc(i);
        tadvsum(i,:,:)=tadvsum(i,:,:)./hwdaysc(i);
        qadvsum(i,:,:)=qadvsum(i,:,:)./hwdaysc(i);
        wbtcontribtadvsum(i,:,:)=wbtcontribtadvsum(i,:,:)./hwdaysc(i);
        wbtcontribqadvsum(i,:,:)=wbtcontribqadvsum(i,:,:)./hwdaysc(i);
    end
end

if plottqadvection==1
    data{1}=narrlats;
    data{2}=narrlons;
    for dayofhw=desdayofhwiwf:desdayofhwiwl
        if dayofhw==1;daydescrip='First Days';elseif dayofhw<=4;daydescrip='Middle Days';else daydescrip='Last Days';end
        
        data{3}=squeeze(wbtcontribobstchangesum(dayofhw,:,:));
        %data{3}=squeeze(obstchangearray{deshw,desdayofhw}(:,:,deshr)); %for arrays with hourly data
        %data{3}=squeeze(wbtcontribtadvsum(dayofhw,:,:)); %for arrays with daily data
        %data{3}=squeeze(qadvsum(dayofhw,:,:)); %use days 1, 3, and 5 in final plots
        %caxis limits: -3 to 3 for obstchange (and wbt contrib thereto), -3 to 3 for obsqchange
        
        vararginnew={'variable';'generic scalar';'contour';1;'plotCountries';1;...
            'caxismin';-3;'caxismax';3;'overlaynow';0;'anomavg';'avg'};
        %vararginnew={'variable';'generic scalar';'contour';1;'plotCountries';1;...
        %    'caxismethod';'global';'overlaynow';0;'anomavg';'avg'};
        datatype='NARR';
        [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
        plotModelData(data,regtoplot,vararginnew,datatype);
        curpart=1;highqualityfiguresetup;

        colormap(colormaps('wbt','more'));
        %title(strcat(['WBT Effect of Daily Advective T Change:',' ',daydescrip]),'fontsize',20,'fontname','arial','fontweight','bold');
        title(strcat(['WBT Effect of Daily Observed T Change:',' ',daydescrip]),'fontsize',20,'fontname','arial','fontweight','bold');
        h=colorbar;
        set(h,'fontsize',14,'fontweight','bold','fontname','arial');
        ylabel(h,'Change (deg C)','fontsize',14,'fontweight','bold','fontname','arial');
        curpart=2;figloc=curDir;figname=strcat('tqadvwbtcontribobstsumdayofhw',num2str(dayofhw),desreg);highqualityfiguresetup;
        clf;
    end
end

%Calculates an index that is just the average T at the inland stations minus the average T at the coastal stations, for every hour
%The idea is that sorting by hour will enable the most dramatic situations to be identified and then analyzed
if coastalcoolingindex==1
    nestns=[69;70;71;73;77;94;95;97;98;99;100;101;102;103;107;108;109;137;138;139;179];
    %Whether the station is close to the coast or not
    %(if so, require that the sea breeze kick in by 2 PM LST; if not, require that it kick in by 6 PM LST)
    closetocoast=[0;1;0;-1;-1;0;0;1;0;1;-1;-1;-1;-1;1;0;0;0;1;0;1];
        %a judgment as to whether or not a station faces the ocean/lake 'unimpeded'
        %1=yes, 0=no, -1=so far that sea breezes cannot realistically occur
    for stn=1:size(nestns,1)
        if closetocoast(stn)==1 %coastal
        elseif closetocoast(stn)==0 %a little inland
        else %far inland
        end
    end
end

%Creates composites of standardized SST anomalies for either
    %a. the middle day of each of the 28 heat waves (as originally written), or
    %b. each of the 256 hottest days (the top 4% in MJJASO over 1981-2015)
    %Stuff that's commented out is what needs to change between these two options
if computesstcompositehws==1
    thisdaydata={};thisdayanom={};
    validdayc=zeros(256,1);
    %dayisinmayjunbyhw=zeros(size(reghwdoys,2),1);
    %dayisinaugsepbyhw=zeros(size(reghwdoys,2),1);
    %for hw=1:size(reghwdoys,2)
    for hw=1:256 %called hw but really is just hotday count
        %fprintf('hw is %d\n',hw);
        fprintf('hotday count is %d\n',hw);
        %hwlen=size(reghwdoys{hw},1);
        %if hwlen==5;middleday=3;else middleday=2;end
        %thisdoy=reghwdoys{hw}(middleday,1);
        %thisyear=reghwdoys{hw}(middleday,2);
        thisdoy=regdailyavgt(hw,2);
        thisyear=regdailyavgt(hw,3);
        
        thisdayanommayjun{hw}=NaN.*ones(1440,720);
        thisdayanomaugsep{hw}=NaN.*ones(1440,720);
        
        if thisyear>=1982 && thisyear<=2014
            validdayc(hw)=1;
            %Get SST anomaly data for this day
            dailyanomsstfile=ncread(strcat(dailyanomsstfileloc,'sst.day.anom.',num2str(thisyear),'.v2.nc'),'anom');
            thisdayanom{hw}=dailyanomsstfile(:,:,thisdoy); %because data IS the anomaly
            temp=abs(thisdayanom{hw})>10^3;thisdayanom{hw}(temp)=NaN;
            %Make it standardized
            thisdaystananom{hw}=thisdayanom{hw}./oisststananombydoy{thisdoy};
            temp=abs(thisdaystananom{hw})>10;thisdaystananom{hw}(temp)=NaN;

            %Month-specific arrays as well
            if thisdoy<=181 %May or June
                thisdayanommayjun{hw}=dailyanomsstfile(:,:,thisdoy);
                temp=abs(thisdayanommayjun{hw})>10^3;thisdayanommayjun{hw}(temp)=NaN;
                thisdaystananommayjun{hw}=thisdayanommayjun{hw}./oisststananombydoy{thisdoy};
                temp=abs(thisdaystananommayjun{hw})>10;thisdaystananommayjun{hw}(temp)=NaN;
                dayisinmayjunbyhw(hw)=1;
            elseif thisdoy>=222 %Aug 10-31 or Sep
                thisdayanomaugsep{hw}=dailyanomsstfile(:,:,thisdoy);
                temp=abs(thisdayanomaugsep{hw})>10^3;thisdayanomaugsep{hw}(temp)=NaN;
                thisdaystananomaugsep{hw}=thisdayanomaugsep{hw}./oisststananombydoy{thisdoy};
                temp=abs(thisdaystananomaugsep{hw})>10;thisdaystananomaugsep{hw}(temp)=NaN;
                dayisinaugsepbyhw(hw)=1;
            end

            clear dailyanomsstfile;
        end
    end
    %Average across heat waves
    sumanom=zeros(1440,720);sumstananom=zeros(1440,720);
    sumanommayjun=zeros(1440,720);sumstananommayjun=zeros(1440,720);
    sumanomaugsep=zeros(1440,720);sumstananomaugsep=zeros(1440,720);
    %for hw=1:size(reghwdoys,2)
    for hw=1:256
        if validdayc(hw)==1
            sumanom=sumanom+thisdayanom{hw};
            sumstananom=sumstananom+thisdaystananom{hw};
            if dayisinmayjunbyhw(hw)==1
                sumanommayjun=sumanommayjun+thisdayanommayjun{hw};
                sumstananommayjun=sumstananommayjun+thisdaystananommayjun{hw};
            elseif dayisinaugsepbyhw(hw)==1
                sumanomaugsep=sumanomaugsep+thisdayanomaugsep{hw};
                sumstananomaugsep=sumstananomaugsep+thisdaystananomaugsep{hw};
            end
        end
    end
    %avgsstanomhws=sumanom./size(reghwdoys,2);
    %avgsststananomhws=sumstananom./size(reghwdoys,2);
    avgsstanomhws=sumanom./sum(validdayc);
    avgsststananomhws=sumstananom./sum(validdayc);
    avgsstanomhwsmayjun=sumanommayjun./sum(dayisinmayjunbyhw);
    avgsststananomhwsmayjun=sumstananommayjun./sum(dayisinmayjunbyhw);
    avgsstanomhwsaugsep=sumanomaugsep./sum(dayisinaugsepbyhw);
    avgsststananomhwsaugsep=sumstananomaugsep./sum(dayisinaugsepbyhw);
    save(strcat(curDir,'newanalyses'),'avgsstanomhws','avgsstanomhwsmayjun','avgsstanomhwsaugsep',...
        'avgsststananomhws','avgsststananomhwsmayjun','avgsststananomhwsaugsep','-append');
end


%Plots the above-calculated composites
if plotsstcompositehws==1
    if plotusingplotmodeldata==1
        data{1}=oisstlats;
        data{2}=oisstlons;
        data{3}=double(avgsststananomhwsmayjun);
        
        region='worldminuspoles';
        vararginnew={'variable';'generic scalar';'mystep';0.2;'contour';1;'plotCountries';1;...
            'caxismin';-2;'caxismax';2;'overlaynow';0;'anomavg';'avg'};
        datatype='OISST';
        [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
        plotModelData(data,region,vararginnew,datatype);
        curpart=1;highqualityfiguresetup;
    else %plot using imagescnan
        figure(figc);figc=figc+1;
        curpart=1;highqualityfiguresetup;
        h=imagescnan(fliplr(avgsststananomhwsmayjun(:,150:600))','NanColor',colors('gray'));
            %plot is from 52.5 S to 60 N
        caxis([-3 3]);
        pbaspect([1.25 0.7 1]);
    end
    
    months='May-Jun';
    colormap(colormaps('sst','more'));
    title(strcat(['SST Composite:',' ',months,'Heat Waves']),'fontsize',20,'fontname','arial','fontweight','bold');
    h=colorbar;
    set(h,'fontsize',14,'fontweight','bold','fontname','arial');
    ylabel(h,'Standardized Anomaly (deg C)','fontsize',14,'fontweight','bold','fontname','arial');
    set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
    lonsforlabels={'0';'60 E';'120 E';'180';'120 W';'60 W'};
    latsforlabels={'60 N';'30 N';'0';'30 S'};
    set(gca,'xtick',0:240:1440);
    set(gca,'XTickLabel',lonsforlabels,'fontname','arial','fontweight','bold','fontsize',14);
    set(gca,'ytick',1:120:481);
    set(gca,'YTickLabel',latsforlabels,'fontname','arial','fontweight','bold','fontsize',14);
    curpart=2;figloc=curDir;figname='colin';highqualityfiguresetup;
end

%Update to the adv-az relationship calculated in the old version of this paper
%This new approach scraps the 'advection' part, which was troubled, 
    %and just looks at wind azimuths during heat waves, and hopes to make quality inferences from those alone
%Because this is NARR data, looking just at NYC heat waves wouldn't really make sense
%So, this loop instead uses the wind speed/dir on the 100 highest-T days at each NARR gridpt
if computeupdatedazrelship==1
    minlat=38;maxlat=46;minlon=-80;maxlon=-68;
    validpts=narrgridptsparallelogram(minlat,minlon,minlat,maxlon,maxlat,maxlon,maxlat,minlon);
        %this region corresponds to us-ne-small
        
    %Sort topXXtbynarr so days are chronological (20 sec; commented out if already done)
    topXXttousenarr={};
    for i=1:277
        for j=1:349
            if narrlsmask(i,j)==1 && validpts(i,j)==1
                topXXttousenarr{i,j}=sortrows(squeeze(topXXtbynarr(i,j,:,:)),[2 3 4]);
                datesonly=topXXttousenarr{i,j}(:,2:4);
                [C,ia,ic]=unique(datesonly,'rows');
                topXXttousenarr{i,j}=topXXttousenarr{i,j}(ia,:);
            end
        end
    end
    
    %Go through days and compile data for all gridpts that have that day in their list
    curdaybygridpt=ones(277,349);
    winddirbygridpt=NaN.*ones(277,349,100);
    windspeedbygridpt=NaN.*ones(277,349,100);
    for year=yeariwf:yeariwl
        for month=monthiwf:monthiwl
            fprintf('Current year and month are %d, %d\n',year,month);
            for dom=1:monthlengthsdays(month-monthiwf+1)
                nohotdaysyet=1;
                for i=1:277
                    for j=1:349
                        if narrlsmask(i,j)==1 && validpts(i,j)==1 %land, within parallelogram of the Northeast
                            if curdaybygridpt(i,j)<=size(topXXttousenarr{i,j},1)
                                if topXXttousenarr{i,j}(curdaybygridpt(i,j),2)==year &&...
                                   topXXttousenarr{i,j}(curdaybygridpt(i,j),3)==month &&...
                                   topXXttousenarr{i,j}(curdaybygridpt(i,j),4)==dom
                                    if nohotdaysyet==1
                                        %Yes, need to (and will) load in this day's data
                                        uwndthisday=load(strcat(narrmatDir,'/uwnd/',num2str(year),'/uwnd_',num2str(year),'_0',...
                                            num2str(month),'_01.mat'));
                                        uwndthisday=eval(['uwndthisday.uwnd_' num2str(year) '_0' num2str(month) '_01{3};']);
                                        uwndthispt=mean(uwndthisday(i,j,1,dom*8-7:dom*8),4);
                                        vwndthisday=load(strcat(narrmatDir,'/vwnd/',num2str(year),'/vwnd_',num2str(year),'_0',...
                                            num2str(month),'_01.mat'));
                                        vwndthisday=eval(['vwndthisday.vwnd_' num2str(year) '_0' num2str(month) '_01{3};']);
                                        vwndthispt=mean(vwndthisday(i,j,1,dom*8-7:dom*8),4);
                                        [winddirthispt,windspeedthispt]=cart2compass(uwndthispt,vwndthispt);
                                        winddirbygridpt(i,j,curdaybygridpt(i,j))=winddirthispt;
                                        windspeedbygridpt(i,j,curdaybygridpt(i,j))=windspeedthispt;
                                        curdaybygridpt(i,j)=curdaybygridpt(i,j)+1;
                                        nohotdaysyet=0;
                                    else
                                        uwndthispt=mean(uwndthisday(i,j,1,dom*8-7:dom*8),4);
                                        vwndthispt=mean(vwndthisday(i,j,1,dom*8-7:dom*8),4);
                                        [winddirthispt,windspeedthispt]=cart2compass(uwndthispt,vwndthispt);
                                        winddirbygridpt(i,j,curdaybygridpt(i,j))=winddirthispt;
                                        windspeedbygridpt(i,j,curdaybygridpt(i,j))=windspeedthispt;
                                        curdaybygridpt(i,j)=curdaybygridpt(i,j)+1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    save(strcat(curDir,'newanalyses'),'winddirbygridpt','windspeedbygridpt','curdaybygridpt','-append');
end


if plotupdatedazrelship==1
    %First, quickly compute heat-wave averages and st devs using the arrays calculated just above
    if recomputehwavgs==1
        for i=1:277
            for j=1:349
                avgwinddirbygridpt(i,j)=nanmean(winddirbygridpt(i,j,:));
                stdevwinddirbygridpt(i,j)=nanstd(winddirbygridpt(i,j,:));
                avgwindspeedbygridpt(i,j)=nanmean(windspeedbygridpt(i,j,:));
                stdevwindspeedbygridpt(i,j)=nanstd(windspeedbygridpt(i,j,:));
            end
        end
    end
    
    %Second, compute terrain-adjusted climatological averages
    if recomputeclimoavgs==1
        winddirjjaclimoterrainsfc=0;windspeedjjaclimoterrainsfc=0;
        for doy=120:300
            disp(doy);
            winddirclimoterrainsfc{doy}=NaN.*ones(277,349);windspeedclimoterrainsfc{doy}=NaN.*ones(277,349);
            for i=1:277
                for j=1:349
                    if narrlsmask(i,j)==1
                        if ~isnan(uwndclimoterrainsfc{doy}(i,j)) && ~isnan(vwndclimoterrainsfc{doy}(i,j))  
                            [winddirclimoterrainsfc{doy}(i,j),windspeedclimoterrainsfc{doy}(i,j)]=...
                                cart2compass(uwndclimoterrainsfc{doy}(i,j),vwndclimoterrainsfc{doy}(i,j));
                        end
                    end
                end
            end
            if doy>=151 && doy<=243
                winddirjjaclimoterrainsfc=winddirjjaclimoterrainsfc+winddirclimoterrainsfc{doy};
                windspeedjjaclimoterrainsfc=windspeedjjaclimoterrainsfc+windspeedclimoterrainsfc{doy};
            end
        end
        winddirjjaclimoterrainsfc=winddirjjaclimoterrainsfc./93;
        windspeedjjaclimoterrainsfc=windspeedjjaclimoterrainsfc./93;
    end
    
    %Now, plot all of this stuff
    data{1}=narrlats;
    data{2}=narrlons;
    data{3}=avgwinddirbygridpt;
    %data{3}=winddirjjaclimoterrainsfc;

    region='us-ne-small';
    vararginnew={'variable';'generic scalar';'mystep';10;'contour';1;'plotCountries';1;...
        'caxismin';186;'caxismax';283;'overlaynow';0;'anomavg';'avg'}; 
        %when plotting climatology, set caxis limits 1.75 and 6.25 for wind speed; 186 and 283 for winddir (mystep=10)
    datatype='NARR';
    [caxisRange,mystep,mycolormap,~,~,~,~,~,caxis_min,caxis_max]=...
    plotModelData(data,region,vararginnew,datatype);
    curpart=1;highqualityfiguresetup;
    colormap(colormaps('rainbow','more'));
    title('Average Surface-Wind Azimuth on 256 Hot Days','fontsize',20,'fontname','arial','fontweight','bold');
    h=colorbar;
    set(h,'fontsize',14,'fontweight','bold','fontname','arial');
    ylabel(h,'Wind Direction (deg)','fontsize',14,'fontweight','bold','fontname','arial');
    set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='azrelshipavgwinddir2';highqualityfiguresetup;
end

%Ultimate goal is to compare coast & inland
%Do for all JJA days, and for heat-wave days (reghwdoys) only
if scatterplottanomwinddir==1
    tjfkthisday=zeros(yeariwl-yeariwf+1,182);tclimojfkthisday=zeros(yeariwl-yeariwf+1,182);
    tanomjfkthisday=zeros(yeariwl-yeariwf+1,182);winddirjfkthisday=zeros(yeariwl-yeariwf+1,182);
    tewrthisday=zeros(yeariwl-yeariwf+1,182);tclimoewrthisday=zeros(yeariwl-yeariwf+1,182);
    tanomewrthisday=zeros(yeariwl-yeariwf+1,182);winddirewrthisday=zeros(yeariwl-yeariwf+1,182);
    for year=yeariwf:yeariwl
        if rem(year,4)==0;apr30doy=121;else apr30doy=120;end
        stntz=5; %because in Eastern time zone
        for doy=122:303
            thismon=DOYtoMonth(doy,year);
            tjfkthisday(year-yeariwf+1,doy)=mean(finaldatat{year-yeariwf+1,179}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz));
            tjfkthisdayhourly(year-yeariwf+1,doy,:)=finaldatat{year-yeariwf+1,179}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz);
            tclimojfkthisday(year-yeariwf+1,doy)=mean(avgthishourofdayandmonth{1}(179,thismon-4,:));
            tclimojfkthisdayhourly(year-yeariwf+1,doy,:)=avgthishourofdayandmonth{1}(179,thismon-4,:);
            tanomjfkthisday(year-yeariwf+1,doy)=tjfkthisday(year-yeariwf+1,doy)-tclimojfkthisday(year-yeariwf+1,doy);
            tanomjfkthisdayhourly(year-yeariwf+1,doy,1:24)=...
                squeeze(tjfkthisdayhourly(year-yeariwf+1,doy,:)-tclimojfkthisdayhourly(year-yeariwf+1,doy,:));
            winddirjfkthisday(year-yeariwf+1,doy)=...
                mean(finaldatawinddir{year-yeariwf+1,179}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz));
            winddirjfkthisdayhourly(year-yeariwf+1,doy,:)=...
                finaldatawinddir{year-yeariwf+1,179}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz);
            
            tewrthisday(year-yeariwf+1,doy)=mean(finaldatat{year-yeariwf+1,94}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz));
            tewrthisdayhourly(year-yeariwf+1,doy,:)=finaldatat{year-yeariwf+1,94}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz);
            tclimoewrthisday(year-yeariwf+1,doy)=mean(avgthishourofdayandmonth{1}(94,thismon-4,:));
            tclimoewrthisdayhourly(year-yeariwf+1,doy,:)=avgthishourofdayandmonth{1}(94,thismon-4,:);
            tanomewrthisday(year-yeariwf+1,doy)=tewrthisday(year-yeariwf+1,doy)-tclimoewrthisday(year-yeariwf+1,doy);
            tanomewrthisdayhourly(year-yeariwf+1,doy,1:24)=...
                squeeze(tewrthisdayhourly(year-yeariwf+1,doy,:)-tclimoewrthisdayhourly(year-yeariwf+1,doy,:));
            winddirewrthisday(year-yeariwf+1,doy)=...
                mean(finaldatawinddir{year-yeariwf+1,94}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz));
            winddirewrthisdayhourly(year-yeariwf+1,doy,:)=...
                finaldatawinddir{year-yeariwf+1,94}((doy-apr30doy)*24-23+stntz:(doy-apr30doy)*24+stntz);
        end
    end
    figure(figc);figc=figc+1;
    temptanomjfk=0;tempwinddirjfk=0;temptanomjfkhourly=0;tempwinddirjfkhourly=0;
    temptanomewr=0;tempwinddirewr=0;temptanomewrhourly=0;tempwinddirewrhourly=0;
    jfkdoy=0;jfkyear=0;
    jfkdoyhourly=0;jfkyearhourly=0;jfkhourhourly=0;
    somtimeseries=0;sbctimeseries=0;
    somtimeserieshourly=0;sbctimeserieshourly=0;
    dayc=0;hourc=1;
    for year=1:yeariwl-yeariwf+1
        fprintf('year is %d\n',year);
        if rem(year,4)==0;ly=1;else ly=0;end
        for doy=122:303
            dayc=dayc+1;
            %SOM timeseries was calculated for May 1-Sep 30, regardless of DOY changes in leap years
            if doy<=273;daycforsomtimeseries=(year-1)*153+doy-120-ly;end
            temptjfk(dayc)=tjfkthisday(year,doy);
            temptanomjfk(dayc)=tanomjfkthisday(year,doy);
            tempwinddirjfk(dayc)=winddirjfkthisday(year,doy);
            temptanomjfkhourly(hourc:hourc+23)=tanomjfkthisdayhourly(year,doy,:);
            jfkdoy(dayc)=doy;jfkyear(dayc)=year+yeariwf-1;
            jfkdoyhourly(hourc:hourc+23)=doy;jfkyearhourly(hourc:hourc+23)=year+yeariwf-1;
            jfkhourhourly(hourc:hourc+23)=(hourc:hourc+23)-(hourc*ones(1,24));
            tempwinddirjfkhourly(hourc:hourc+23)=winddirjfkthisdayhourly(year,doy,:);
            temptanomewr(dayc)=tanomewrthisday(year,doy);
            tempwinddirewr(dayc)=winddirewrthisday(year,doy);
            temptanomewrhourly(hourc:hourc+23)=tanomewrthisdayhourly(year,doy,:);
            tempwinddirewrhourly(hourc:hourc+23)=winddirewrthisdayhourly(year,doy,:);
            somtimeseries(dayc)=timeseries(daycforsomtimeseries,3);
            somtimeserieshourly(hourc:hourc+23)=timeseries(daycforsomtimeseries,3);
            sbctimeseries(dayc)=squeeze(hourswithsbcbydoyandhourofdayewrjfk(year,doy));
            sbctimeserieshourly(hourc:hourc+23)=squeeze(hourswithsbcbydoyandhourofdayewrjfk(year,doy,:));
            hourc=hourc+24;
        end
    end
    ewrjfkdifftanomhourly=temptanomewrhourly-temptanomjfkhourly;
    ewrjfkdifftanom=temptanomewr-temptanomjfk;
    %scatter(temptanomstn,tempwinddirstn);
    %scatter(temptanomstnhourly,tempwinddirstnhourly);
    
    %Include EWR-JFK difference in matrix so it is sorted and can be included (via shading) in the below scatterplot 
    tanomandwinddirmatrixjfk=[jfkdoyhourly' jfkyearhourly' jfkhourhourly' temptanomjfkhourly' tempwinddirjfkhourly' temptanomewrhourly'...
        tempwinddirewrhourly' ewrjfkdifftanomhourly' somtimeserieshourly' sbctimeserieshourly'];
    temp=isnan(tanomandwinddirmatrixjfk);tanomandwinddirmatrixjfk(temp)=-Inf;
    tanomandwinddirjfksorted=sortrows(tanomandwinddirmatrixjfk,-4);
    
    %Same but with daily data only
    tanomandwinddirmatrixjfkdaily=[jfkdoy' jfkyear' temptanomjfk' tempwinddirjfk' temptanomewr'...
        tempwinddirewr' ewrjfkdifftanom' somtimeseries' sbctimeseries' temptjfk'];
    temp=isnan(tanomandwinddirmatrixjfkdaily);tanomandwinddirmatrixjfkdaily(temp)=-Inf;
    tanomandwinddirjfksorteddaily=sortrows(tanomandwinddirmatrixjfkdaily,-3);
    tanomandwinddirjfksorteddailybyhottest=sortrows(tanomandwinddirmatrixjfkdaily,-10);
    
    %Colors to use in the shading
    %temp=tanomandwinddirmatrixjfk(:,8);
    %lessthanminus3=temp<=-3;grouping(lessthanminus3)=1;
    %lessthanminus1=temp<=-1;grouping(lessthanminus1)=2;
    %lessthan1=temp<=1;grouping(lessthan1)=3;
    %lessthan3=temp<=3;grouping(lessthan3)=4;
    %morethan3=temp>3;grouping(morethan3)=5;
    grouping=0;
    groupbasedonewrjfktdiff=0;groupbasedonsomcateg=1;groupbasedonsbcoccurrence=0;
    for i=1:5000
        if groupbasedonewrjfktdiff==1
            if tanomandwinddirjfksorted(i,8)<=-3
                color(i,:)=colors('red');grouping(i)=1;
            elseif tanomandwinddirjfksorted(i,8)<=-1
                color(i,:)=colors('orange');grouping(i)=2;
            elseif tanomandwinddirjfksorted(i,8)<=1
                color(i,:)=colors('green');grouping(i)=3;
            elseif tanomandwinddirjfksorted(i,8)<=3
                color(i,:)=colors('blue');grouping(i)=4;
            else
                color(i,:)=colors('purple');grouping(i)=5;
            end
        elseif groupbasedonsomcateg==1
            if tanomandwinddirjfksorted(i,9)==1
                color(i,:)=colors('red');grouping(i)=1;
            elseif tanomandwinddirjfksorted(i,9)==2
                color(i,:)=colors('orange');grouping(i)=2;
            elseif tanomandwinddirjfksorted(i,9)==3
                color(i,:)=colors('green');grouping(i)=3;
            elseif tanomandwinddirjfksorted(i,9)==4
                color(i,:)=colors('blue');grouping(i)=4;
            elseif tanomandwinddirjfksorted(i,9)==5
                color(i,:)=colors('purple');grouping(i)=5;
            else
                color(i,:)=colors('gray');grouping(i)=6;
            end
        elseif groupbasedonsbcoccurrence==1
            if tanomandwinddirjfksorted(i,10)==1 %SBC
                grouping(i)=1;
            else %no SBC
                grouping(i)=2;
            end
        end
    end
    
    %Final scatterplot
    figure(figc);figc=figc+1;
    curpart=1;highqualityfiguresetup;
    ph=gscatter(tanomandwinddirjfksorted(1:2500,5),tanomandwinddirjfksorted(1:2500,4),grouping(1:2500));
    set(ph,'markersize',20);
    set(gca,'fontsize',14,'fontweight','bold','fontname','arial');
    title('JFK Temperature Anomaly vs Wind Direction, for each SOM Category',...
        'fontsize',18,'fontweight','bold','fontname','arial');
    ylabel('Hourly Anomaly (deg C)','fontsize',14,'fontweight','bold','fontname','arial');
    xlabel('Hourly Wind Direction (deg)','fontsize',14,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='tanomvswinddirscatterjfk';highqualityfiguresetup;
end

if freqofsbcbysomcateg==1
    %Get SOM-category data into an easily digestible format
    totaldayc=0;somcategthisday=NaN.*ones(35,366);
    for year=1981:2015
        %fprintf('year is %d\n',year);
        if rem(year,4)==0;ly=1;apr30doy=121;else ly=0;apr30doy=120;end
        for doy=apr30doy+1:apr30doy+153
            totaldayc=totaldayc+1;
            somcategthisday(year-yeariwf+1,doy)=timeseries(totaldayc,3);
        end
    end
    
    %Calculate frequency per category
    totalsomcategc=zeros(6,1);totalsbccountbycateg=zeros(6,1);
    for year=1981:2015
        if rem(year,4)==0;ly=1;apr30doy=121;else ly=0;apr30doy=120;end
        for doy=apr30doy+1:apr30doy+153
            thisdaycateg=somcategthisday(year-yeariwf+1,doy);
            totalsomcategc(thisdaycateg)=totalsomcategc(thisdaycateg)+1;
            if dayswithsbcbydoyewrjfk(year-yeariwf+1,doy)==1
                totalsbccountbycateg(thisdaycateg)=totalsbccountbycateg(thisdaycateg)+1;
            end
        end
    end
    sbcfreqbysomcateg=round2(100.*totalsbccountbycateg./totalsomcategc,0.1);
end

if wbtanombysomcateghotdays==1 %using station data
    if repeatcalc==1
        totalsomcategchws=zeros(6,1);
        for stn=1:size(nestns,1);wbtanomthisday{stn}=zeros(6,1);end
        %for hw=1:size(reghwdoys,2)-1
        %for hw=1:256
            %fprintf('hw is %d\n',hw);
            %hwlen=size(reghwdoys{hw},1);
            %for day=1:hwlen
            for day=1:256
                %doy=reghwdoys{hw}(day,1);year=reghwdoys{hw}(day,2);mon=DOYtoMonth(doy,year);
                doy=regdailyavgt(day,2);
                year=regdailyavgt(day,3);
                if rem(year,4)==0;apr30doy=121;else apr30doy=120;end
                somcategthisdayhere=somcategthisday(year-yeariwf+1,doy);
                totalsomcategchws(somcategthisdayhere)=totalsomcategchws(somcategthisdayhere)+1;
                for stn=1:size(nestns,1)
                    wbtanomthisday{stn}(somcategthisdayhere)=wbtanomthisday{stn}(somcategthisdayhere)+...
                        mean(finaldatawbt{year-yeariwf+1,nestns(stn)}((doy-apr30doy)*24-23:(doy-apr30doy)*24)-...
                        squeeze(avgthishourofdayandmonth{2}(nestns(stn),mon-monthiwf+1,:)));
                end
            end
        %end
        for i=1:6
            for stn=1:size(nestns,1)
                wbtanomthisday{stn}(i)=wbtanomthisday{stn}(i)./totalsomcategchws(i);
            end
        end
    end
    
    figure(figc);curpart=1;highqualityfiguresetup;
    for somcateg=1:6
        subplot(2,3,somcateg);
        plotBlankMap(figc,'us-ne');
        for stn=1:size(nestns,1)
            if wbtanomthisday{stn}(somcateg)<=2.5
                color=colors('purple');
            elseif wbtanomthisday{stn}(somcateg)<=3
                color=colors('blue');
            elseif wbtanomthisday{stn}(somcateg)<=3.5
                color=colors('green');
            elseif wbtanomthisday{stn}(somcateg)<=4
                color=colors('orange');
            elseif wbtanomthisday{stn}(somcateg)>4
                color=colors('red');
            else
                color=colors('gray');
            end

            pt1lat=newstnNumListlats(nestns(stn));pt1lon=newstnNumListlons(nestns(stn));
            h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker','s',...
                'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',11);
            if somcateg<=3;rownow=1;else rownow=2;end
            if rem(somcateg,3)==1;colnow=1;elseif rem(somcateg,3)==2;colnow=2;else colnow=3;end
            if stn==1;fprintf('somcateg: %d, rownow: %d, colnow: %d\n',somcateg,rownow,colnow);end
            if colnow==1;colnowpos=0.03;elseif colnow==2;colnowpos=0.35;else colnowpos=0.67;end
            if rownow==1;rownowpos=0.45;else rownowpos=0.9;end
            set(gca,'Position',[colnowpos 1-rownowpos 0.33 0.33]);
        end
    end
    curpart=2;figloc=curDir;figname='wbtanomstnseachsomcateg';highqualityfiguresetup;
end

%Northeast-only maps of 1. avg max WBT on a hot day, and of avg hour of 2. Tmax and 3. qmax
%Include both station and NARR data here
if plotneavgmaxandhour==1
    avgextrwbtval=NaN.*ones(277,349);narravgmaxhourt=NaN.*ones(277,349);narravgmaxhourq=NaN.*ones(277,349);
    for i=1:277
        for j=1:349
            if narrlsmask(i,j)==1 && tzlist(i,j)==-5 %eastern US only
                avgextrwbtval(i,j)=mean(topXXwbtbynarr(i,j,:,1),3);
                narravgmaxhourt(i,j)=mean(topXXtbynarr(i,j,:,5),3)-5; %requires time-zone adjustment
                narravgmaxhourq(i,j)=mean(topXXqbynarr(i,j,:,5),3)-5;
            end
        end
    end
    
    cbmin=24.5;cbmax=28;
    regionformap='nyc-area';datatype='NARR';
    data={narrlats;narrlons;avgextrwbtval};overlaydata=data;
    vararginnew={'variable';'generic scalar';'contour';1;'mystep';0.5;'plotCountries';1;...
        'caxismin';cbmin;'caxismax';cbmax;'overlaynow';0;'anomavg';'avg'};
    %vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=0;
    %Plot NARR data
    %[~,~,~,~,~,~,~,~,~]=plotModelData(data,regionformap,vararginnew,datatype);
    plotBlankMap(figc,regionformap);figc=figc+1;
    %Include station data
    for stn=1:size(nestns,1)
        avgextrwbtbystn(stn)=mean(topXXwbtbystn{nestns(stn)}(:,1),1);
        if avgextrwbtbystn(stn)>=27.5
            color=[0.501961 0.000000 0.149020];
        elseif avgextrwbtbystn(stn)>=27
            color=[0.788512 0.032388 0.136563];
        elseif avgextrwbtbystn(stn)>=26.5
            color=[0.958631 0.244306 0.148128];
        elseif avgextrwbtbystn(stn)>=26
            color=[0.992218 0.555217 0.236278];
        elseif avgextrwbtbystn(stn)>=25.5
            color=[0.996078 0.749020 0.352941];
        elseif avgextrwbtbystn(stn)>=25
            color=[0.998877 0.906959 0.580300];
        else
            color=[1.000000 0.997785 0.794587];
        end
        h=geoshow(newstnNumListlats(nestns(stn)),newstnNumListlons(nestns(stn)),...
            'DisplayType','Point','Marker','s',...
            'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',10);hold on;
    end
    curpart=1;highqualityfiguresetup;
    
    %mycolormap=[colors('gray');colors('brown');colors('purple');colors('blue');...
    %    colors('sky blue');colors('green');colors('orange');colors('red')];
    colormap(colormaps('wbt','fewerodd'));
    caxisrange=[cbmin cbmax];caxis(caxisrange);colorbar;
    title(strcat('Average Value of Top-100 WBT'),'fontname','arial','fontweight','bold','fontsize',16);
    set(gca,'fontname','arial','fontweight','bold','fontsize',16);
    curpart=2;figloc=curDir;figname='newanalysesavgextrwbtvalnarr';
    highqualityfiguresetup;
    
    if plotavghours==1
        for i=1:2
            if i==1;arr=narravgmaxhourt;var='t';varn='T';else arr=narravgmaxhourq;var='q';varn='q';end
            cbmin=11.5;cbmax=15;
            regionformap='nyc-area';datatype='NARR';
            data={narrlats;narrlons;arr};overlaydata=data;
            vararginnew={'variable';'generic scalar';'contour';1;'mystep';1;'plotCountries';1;...
                'caxismin';cbmin;'caxismax';cbmax;'overlaynow';0;'anomavg';'avg'};
            %vararginnew{size(vararginnew,1)+1}='nonewfig';vararginnew{size(vararginnew,1)+1}=0;
            %Plot NARR data
            %[~,~,~,~,~,~,~,~,~]=plotModelData(data,regionformap,vararginnew,datatype);
            plotBlankMap(figc,regionformap);figc=figc+1;
            
            %Include station data
            for stn=1:size(nestns,1)
                eval(['avghourextr' var 'bystn(stn)=mean(topXX' var 'bystn{nestns(stn)}(:,5),1);']);
                temp=eval(['mean(topXX' var 'bystn{nestns(stn)}(:,5),1);']);
                if temp>=14.5
                    color=[0.500000 0.000000 0.000000];
                elseif temp>=14
                    color=[1.000000 0.174510 0.000000];
                elseif temp>=13.5
                    color=[1.000000 0.833333 0.000000];
                elseif temp>=13
                    color=[0.502846 1.000000 0.464896];
                elseif temp>=12.5
                    color=[0.000000 0.833333 1.000000];
                elseif temp>=12
                    color=[0.000000 0.174510 1.000000];
                else
                    color=[0.000000 0.000000 0.517825];
                end
                h=geoshow(newstnNumListlats(nestns(stn)),newstnNumListlons(nestns(stn)),...
                    'DisplayType','Point','Marker','s',...
                    'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',10);hold on;
            end
            curpart=1;highqualityfiguresetup;
            %mycolormap=[colors('gray');colors('brown');colors('purple');colors('blue');...
            %    colors('sky blue');colors('green');colors('orange');colors('red')];
            colormap(colormaps('rainbow','fewerodd'));
            caxisrange=[cbmin cbmax];caxis(caxisrange);colorbar;
            title(strcat(['Average Hour of Top-100 ',varn,'max']),'fontname','arial','fontweight','bold','fontsize',16);
            set(gca,'fontname','arial','fontweight','bold','fontsize',16);
            curpart=2;figloc=curDir;figname=strcat('newanalysesavghourofmax',var,'narr');
            highqualityfiguresetup;
        end
    end
end


if calcseabreezefromdailytracedeviations==1
    %First, calculate JJA-avg daily trace of T, WBT, and q for each NE stn
    if dostep1==1
        jjadailytraces=zeros(3,size(nestns,1),10,24);
        for var=1:3
            if var==1;stndata=stndatat;elseif var==2;stndata=stndatawbt;else stndata=stndataq;end
            for stn=1:size(nestns,1)
                alldayc=0;
                for year=1:35
                    for relmon=2:4
                        curstndata=stndata{nestns(stn),year,relmon};
                        for dayendhour=24:24:size(curstndata,1)
                            alldayc=alldayc+1;
                            jjadailytraces(var,stn,alldayc,:)=curstndata(dayendhour-23:dayendhour);
                        end
                    end
                end
                jjaavgdailytraces(var,stn,1:24)=nanmean(jjadailytraces(var,stn,:,1:24),3);
            end
        end
    end
    
    %Next, compute each WBT-based hot day's deviation from this average
    if dostep2==1
        thisdaytraceanom=zeros(3,size(nestns,1),100,24);
        hotdaystraceanoms=zeros(3,size(nestns,1),24);
        for var=1:3
            if var==1;stndata=stndatat;elseif var==2;stndata=stndatawbt;else stndata=stndataq;end
            for stn=1:size(nestns,1)
                thisstnhotdaylist=topXXwbtbystn{nestns(stn)};
                for i=1:100
                    thisyear=thisstnhotdaylist(i,2);
                    thismonth=thisstnhotdaylist(i,3);
                    thisday=thisstnhotdaylist(i,4);
                    thisdoy=DatetoDOY(thismonth,thisday,thisyear);%apr30doy=DatetoDOY(4,30,thisyear);
                    curstndata=stndata{nestns(stn),thisyear-yeariwf+1,thismonth-monthiwf+1};
                    thisdaydata=curstndata(24*thisday-23:24*thisday);
                    thisdaytraceanom(var,stn,i,:)=thisdaydata-squeeze(jjaavgdailytraces(var,stn,:));
                end
                hotdaystraceanoms(var,stn,1:24)=nanmean(thisdaytraceanom(var,stn,:,1:24),3);
            end
        end
    end
    
    %Plot each hot day's trace anom to see if any patterns emerge visually
    figure(figc);figc=figc+1;
    for i=1:100
        plot(squeeze(thisdaytraceanom(1,21,i,:)));hold on;
        if thisdaytraceanom(1,21,i,17)-thisdaytraceanom(1,21,i,24)>=4
            potsbd(i)=1;
        else
            potsbd(i)=0;
        end
    end
end


if sbcstats==1
    %Compare traces of hot days that do and don't have SBC
    avgtracesbchotdays=zeros(3,2,24);avgtracenonsbchotdays=zeros(3,2,24);
    stderrorofdiffsbchot=0;stderrorofdiffnonsbchot=0;sigma1=0;sigma2=0;
    for var=1:3
        if var==1
            topXXbystn=topXXtbystn;stndata=stndatat;
        elseif var==2
            topXXbystn=topXXwbtbystn;stndata=stndatawbt;
        else
            topXXbystn=topXXqbystn;stndata=stndataq;
        end
        for stn=1:2
            if stn==1;stnnum=94;else stnnum=179;end
            thisstnhotdaylist=topXXbystn{stnnum};
            sbchotdaysdata{stn}=zeros(2,1,24);
            nonsbchotdaysdata{stn}=zeros(2,1,24);
            sbcdayc=0;nonsbcdayc=0;
            for i=1:100
                thisyear=thisstnhotdaylist(i,2);thisrelyear=thisyear-yeariwf+1;
                thismonth=thisstnhotdaylist(i,3);
                thisday=thisstnhotdaylist(i,4);
                thisdoy=DatetoDOY(thismonth,thisday,thisyear);
                curstndata=stndata{stnnum,thisyear-yeariwf+1,thismonth-monthiwf+1};
                thisdaydata=curstndata(24*thisday-23:24*thisday);
                %Determine if this hot day has SBC or not
                %Don't include years 17-23 as the SBC definition is messed up for those years for some reason
                if thisrelyear<=16 || thisrelyear>=24
                    if dayswithsbcbydoyewrjfk(thisrelyear,thisdoy)==1
                        sbcdayc=sbcdayc+1;
                        sbchotdaysdata{stn}(sbcdayc,:)=thisdaydata;
                    else
                        nonsbcdayc=nonsbcdayc+1;
                        nonsbchotdaysdata{stn}(nonsbcdayc,:)=thisdaydata;
                    end
                end
            end
            avgtracesbchotdays(var,stn,:)=squeeze(mean(sbchotdaysdata{stn},1));
            avgtracenonsbchotdays(var,stn,:)=squeeze(mean(nonsbchotdaysdata{stn},1));
        end
        
        %Compute std error of EWR-JFK difference for SBC hot days
        sigma1(1:24,var)=nanstd(squeeze(sbchotdaysdata{1}),1)';n1(var)=size(sbchotdaysdata{1},1);
        sigma2(1:24,var)=nanstd(squeeze(sbchotdaysdata{2}),1)';n2(var)=size(sbchotdaysdata{2},1);
        stderrorofdiffsbchot(1:24,var)=sqrt((sigma1(:,var).^2/n1(var))+(sigma2(:,var).^2/n2(var)));
        stderrorofdiffsbchot(1:24,var)=[stderrorofdiffsbchot(6:24,var);stderrorofdiffsbchot(1:5,var)]; %adjusted for time zone
        %...and for non-SBC hot days
        sigma1(1:24,var)=nanstd(squeeze(nonsbchotdaysdata{1}),1)';n1(var)=size(nonsbchotdaysdata{1},1);
        sigma2(1:24,var)=nanstd(squeeze(nonsbchotdaysdata{2}),1)';n2(var)=size(nonsbchotdaysdata{2},1);
        stderrorofdiffnonsbchot(1:24,var)=sqrt((sigma1(:,var).^2/n1(var))+(sigma2(:,var).^2/n2(var)));
        stderrorofdiffnonsbchot(1:24,var)=[stderrorofdiffnonsbchot(6:24,var);stderrorofdiffnonsbchot(1:5,var)];
    end
    
    %EWR-JFK, SBC vs non-SBC, T or WBT, hot days
    %vartoplot=1 --> T; vartoplot=2 --> WBT
    for vartoplot=2:2
        figure(figc);figc=figc+1;curpart=1;highqualityfiguresetup;
        thingtoplotsbc=squeeze(avgtracesbchotdays(vartoplot,1,:))-squeeze(avgtracesbchotdays(vartoplot,2,:));
        thingtoplotsbc=[thingtoplotsbc(6:24);thingtoplotsbc(1:5)]; %adjusted for EST time zone (not UTC)
        topcurve=thingtoplotsbc+2.*stderrorofdiffsbchot(:,vartoplot);
        bottomcurve=thingtoplotsbc-2.*stderrorofdiffsbchot(:,vartoplot);
        x=1:24;
        fill([x fliplr(x)],[topcurve' fliplr(bottomcurve')],'b');hold on;

        thingtoplotnonsbc=squeeze(avgtracenonsbchotdays(vartoplot,1,:))-squeeze(avgtracenonsbchotdays(vartoplot,2,:));
        thingtoplotnonsbc=[thingtoplotnonsbc(6:24);thingtoplotnonsbc(1:5)]; %adjusted for EST time zone (not UTC)
        topcurve=thingtoplotnonsbc+2.*stderrorofdiffnonsbchot(:,vartoplot);
        bottomcurve=thingtoplotnonsbc-2.*stderrorofdiffnonsbchot(:,vartoplot);

        %Smooth things for the purposes of making a nice plot
        thingtoplotnonsbc(1)=0.25*thingtoplotnonsbc(24)+0.5*thingtoplotnonsbc(1)+0.25*thingtoplotnonsbc(2);
        thingtoplotsbc(1)=0.25*thingtoplotsbc(24)+0.5*thingtoplotsbc(1)+0.25*thingtoplotsbc(2);
        topcurve(1)=0.25*topcurve(24)+0.5*topcurve(1)+0.25*topcurve(2);
        bottomcurve(1)=0.25*bottomcurve(24)+0.5*bottomcurve(1)+0.25*bottomcurve(2);
        for i=2:23
            thingtoplotnonsbc(i)=0.25*thingtoplotnonsbc(i-1)+0.5*thingtoplotnonsbc(i)+0.25*thingtoplotnonsbc(i+1);
            thingtoplotsbc(i)=0.25*thingtoplotsbc(i-1)+0.5*thingtoplotsbc(i)+0.25*thingtoplotsbc(i+1);
            topcurve(i)=0.25*topcurve(i-1)+0.5*topcurve(i)+0.25*topcurve(i+1);
            bottomcurve(i)=0.25*bottomcurve(i-1)+0.5*bottomcurve(i)+0.25*bottomcurve(i+1);
        end
        thingtoplotnonsbc(24)=0.25*thingtoplotnonsbc(23)+0.5*thingtoplotnonsbc(24)+0.25*thingtoplotnonsbc(1);
        thingtoplotsbc(24)=0.25*thingtoplotsbc(23)+0.5*thingtoplotsbc(24)+0.25*thingtoplotsbc(1);
        topcurve(24)=0.25*topcurve(23)+0.5*topcurve(24)+0.25*topcurve(1);
        bottomcurve(24)=0.25*bottomcurve(23)+0.5*bottomcurve(24)+0.25*bottomcurve(1);

        x=1:24;
        fill([x fliplr(x)],[topcurve' fliplr(bottomcurve')],'r');hold on;

        plot(thingtoplotsbc,'color',colors('green'),'linewidth',4);
        plot(thingtoplotnonsbc,'color',colors('orange'),'linewidth',4);
        legend('SBC Days (mean+/-2*std error)','Non-SBC Days (mean+/-2*std error)');
        xlim([1 24]);
        set(gca,'fontname','arial','fontsize',14,'fontweight','bold');
        if vartoplot==1
            title('EWR-JFK Hourly T Difference, Hot Days','fontname','arial','fontsize',16,'fontweight','bold');
            fignametouse='newanalysesewrjfktdiffhotdays';
        elseif vartoplot==2
            title('EWR-JFK Hourly WBT Difference, Hot Days','fontname','arial','fontsize',16,'fontweight','bold');
            fignametouse='newanalysesewrjfkwbtdiffhotdays';
        end
        xlabel('Hour of Day (LST)','fontname','arial','fontsize',14,'fontweight','bold');
        ylabel('Difference (deg C)','fontname','arial','fontsize',14,'fontweight','bold');
        
        curpart=2;figloc=curDir;figname=fignametouse;highqualityfiguresetup;
    end
    
    
    %Now, compare traces of NON-hot days that do and don't have SBC
    avgtracesbcnonhotdays=zeros(3,2,24);avgtracenonsbcnonhotdays=zeros(3,2,24);
    for var=1:1
        if var==1
            topXXbystn=topXXtbystn;stndata=stndatat;
        elseif var==2
            topXXbystn=topXXwbtbystn;stndata=stndatawbt;
        else
            topXXbystn=topXXqbystn;stndata=stndataq;
        end
        for stn=1:2
            if stn==1;stnnum=94;else stnnum=179;end
            thisstnhotdaylist=topXXbystn{stnnum};
            sbcnonhotdaysdata{stn}=zeros(2,1,24);
            nonsbcnonhotdaysdata{stn}=zeros(2,1,24);
            sbcdayc=0;nonsbcdayc=0;
            %for i=1:100
            for year=yeariwf:yeariwl
                fprintf('Year in non-hot-days calculation is %d\n',year);
                thisrelyear=year-yeariwf+1;
                for month=2:4 %JJA
                    for day=1:monthlengthsdays(month)
                        %Ensure this day is not a hot day
                        notahotday=1; %assume the best
                        for i=1:100
                            if year==thisstnhotdaylist(i,2) && month==thisstnhotdaylist(i,3) &&...
                                    day==thisstnhotdaylist(i,4)
                                fprintf('hot day found at %d, %d, %d',year,month,day);
                                notahotday=0;
                            end
                        end
                        if notahotday==1
                            thisdoy=DatetoDOY(month,day,year);
                            curstndata=stndata{stnnum,thisrelyear,month};
                            thisdaydata=curstndata(24*day-23:24*day);
                            %Determine if this NON-hot day has SBC or not
                            %Don't include years 17-23 as the SBC definition is messed up for those years for some reason
                            if thisrelyear<=16 || thisrelyear>=24
                                if dayswithsbcbydoyewrjfk(thisrelyear,thisdoy)==1
                                    sbcdayc=sbcdayc+1;
                                    sbcnonhotdaysdata{stn}(sbcdayc,:)=thisdaydata;
                                else
                                    nonsbcdayc=nonsbcdayc+1;
                                    nonsbcnonhotdaysdata{stn}(nonsbcdayc,:)=thisdaydata;
                                end
                            end
                        end
                    end
                end
            end
            avgtracesbcnonhotdays(var,stn,:)=squeeze(nanmean(sbcnonhotdaysdata{stn},1));
            avgtracenonsbcnonhotdays(var,stn,:)=squeeze(nanmean(nonsbcnonhotdaysdata{stn},1));
        end
        
        %Compute std error of EWR-JFK difference for SBC non-hot days
        sigma1(var,1:24)=nanstd(squeeze(sbcnonhotdaysdata{1}),1);n1(var)=size(sbcnonhotdaysdata{1},1);
        sigma2(var,1:24)=nanstd(squeeze(sbcnonhotdaysdata{2}),1);n2(var)=size(sbcnonhotdaysdata{2},1);
        stderrorofdiffsbcnonhot(var,:)=sqrt((sigma1(var,:).^2/n1(var))+(sigma2(var,:).^2/n2(var)));
        %...and for non-SBC non-hot days
        sigma1(var,1:24)=nanstd(squeeze(nonsbcnonhotdaysdata{1}),1);n1(var)=size(nonsbcnonhotdaysdata{1},1);
        sigma2(var,1:24)=nanstd(squeeze(nonsbcnonhotdaysdata{2}),1);n2(var)=size(nonsbcnonhotdaysdata{2},1);
        stderrorofdiffnonsbcnonhot(var,:)=sqrt((sigma1(var,:).^2/n1(var))+(sigma2(var,:).^2/n2(var)));
    end
    
    %EWR-JFK, SBC, T, non-hot days
    figure(figc);figc=figc+1;
    thingtoplot=squeeze(avgtracesbcnonhotdays(1,1,:))-squeeze(avgtracesbcnonhotdays(1,2,:));
    topcurve=thingtoplot+2.*stderrorofdiffsbcnonhot(1,:)';
    bottomcurve=thingtoplot-2.*stderrorofdiffsbcnonhot(1,:)';
    x=1:24;
    fill([x fliplr(x)],[topcurve' fliplr(bottomcurve')],'b');hold on;
    title('ewr-jfk, sbc, t, non-hot days');
    %EWR-JFK, non-SBC, T, non-hot days
    figure(figc);figc=figc+1;
    thingtoplot=squeeze(avgtracenonsbcnonhotdays(1,1,:))-squeeze(avgtracenonsbcnonhotdays(1,2,:));
    topcurve=thingtoplot+2.*stderrorofdiffnonsbcnonhot(1,:)';
    bottomcurve=thingtoplot-2.*stderrorofdiffnonsbcnonhot(1,:)';
    x=1:24;
    fill([x fliplr(x)],[topcurve' fliplr(bottomcurve')],'r');hold on;
    title('ewr-jfk, non-sbc, t, non-hot days');
end

%Make time series comparing near-coast JJA SST and a. JJA-avg WBT & b. # extremes of WBT in the NYC area
if timeseriessstwbtcompare==1
    %First order of business: time series of near-coast JJA SST
    %"Near-coast" defined as continental shelf, Cape Cod to Delaware Bay
    %Rows and columns reference the array once it's been flipped to the normal north-upward geographic position
    nearcoastptsrows=[193;194;195;196;195;196;197;194;195;196;197;195;196;197;198;...
        195;196;197;198;199;195;196;197;198;199;196;197;198;199;200;196;197;198;199;200;...
        196;197;198;199;200;196;198;199;200;196;198;199;200;196;198;199;200;201;...
        196;198;199;200;201;202;203;204;198;199;200;201;202;203;204;205;198;199;200;...
        201;202;203;204;205;202;203;204;205;203;204;205;204;205;206;204;205;206;204;205;204];
    nearcoastptscols=[1159;1159;1159;1159;1158;1158;1158;1157;1157;1157;1157;1156;1156;1156;1156;...
        1155;1155;1155;1155;1155;1154;1154;1154;1154;1154;1153;1153;1153;1153;1153;1152;1152;1152;1152;1152;...
        1151;1151;1151;1151;1151;1150;1150;1150;1150;1149;1149;1149;1149;1148;1148;1148;1148;1148;...
        1147;1147;1147;1147;1147;1147;1147;1147;1146;1146;1146;1146;1146;1146;1146;1146;1145;1145;1145;...
        1145;1145;1145;1145;1145;1144;1144;1144;1144;1143;1143;1143;1142;1142;1142;1141;1141;1141;1140;1140;1139];
    avgnearcoastsstthisday=NaN.*ones(35,365);
    for year=1982:2014
        fprintf('Year is %d\n',year);
        if rem(year,4)==0;ly=1;else ly=0;end
        for doy=153:243
            %fprintf('doy is %d\n',doy);
            tempsum=0;
            if doy==153 %don't read in file again unless necessary
                dailysstfile=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(year),'0101-',...
                    num2str(year),'0630.nc'),'tos'); %daily data from Jan 1 to Jun 30
                daystosubtract=0;
            elseif (ly==1 && doy==183) || (ly==0 && doy==182) %don't read in file again unless necessary
                dailysstfile=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(year),'0701-',...
                    num2str(year),'1231.nc'),'tos'); %daily data from Jul 1 to Dec 31
                daystosubtract=181;
            end
            thisdayobs=dailysstfile(:,:,doy-daystosubtract)-273.15;fclose('all');
            thisdayobs=flipud(thisdayobs');
            for i=1:size(nearcoastptsrows,1)
                tempsum=tempsum+thisdayobs(nearcoastptsrows(i),nearcoastptscols(i));
            end
            avgnearcoastsstthisday(year-yeariwf+1,doy)=tempsum/93;
        end
    end
    yearlyavgnearcoastsst=nanmean(avgnearcoastsstthisday,2);
    
    
    %Second order of business: compute JJA-avg WBT
    temp=sortrows(nycdailyavgvecwbt,[2 3 4]);
    newrow=1;
    for row=1:size(temp,1)
        if temp(row,3)>=6 && temp(row,3)<=8 %i.e. JJA
            newtemp(newrow,1:4)=temp(row,1:4);
            newrow=newrow+1;
        end
    end
    temp=newtemp<0;newtemp(temp)=NaN;
    for year=1:35
        yearlyavgnycwbt(year)=nanmean(newtemp(year*92-91:year*92,1));
    end
    
    
    %Third order of business: compute # of hot T and WBT days in each year (using the 250 cutoff)
    nychotwbtdays250=nycdailyavgvecwbt(1:250,:);
    nychottdays250=nycdailyavgvect(1:250,:);
    for year=1981:2015
        countwbtthisyear=0;counttthisyear=0;
        for i=1:250
            if nychotwbtdays250(i,2)==year
                countwbtthisyear=countwbtthisyear+1;
            end
            if nychottdays250(i,2)==year
                counttthisyear=counttthisyear+1;
            end
        end
        yearlycounthotwbtdays(year-yeariwf+1)=countwbtthisyear;
        yearlycounthottdays(year-yeariwf+1)=counttthisyear;
    end
    save(strcat(curDir,'newanalyses4'),'yearlyavgnearcoastsst','yearlyavgnycwbt','yearlycounthotwbtdays',...
        'yearlycounthottdays','-append');
    
    figure(figc);figc=figc+1;
    curpart=1;highqualityfiguresetup;
    scatter(yearlyavgnearcoastsst,yearlycounthottdays,'fill');
    ylim([-2 20]);
    xlabel('JJA-Avg Near-Coast SST (deg C)','fontname','arial','fontweight','bold','fontsize',16);
    ylabel('Annual Count of Extreme-WBT Days','fontname','arial','fontweight','bold','fontsize',16);
    title('JJA-Avg Near-Coast SST vs Annual Count of Extreme-WBT Days','fontname','arial','fontweight','bold','fontsize',18);
    set(gca,'fontname','arial','fontweight','bold','fontsize',16);
    curpart=2;figloc=curDir;figname='newanalysesscattersstwbt';highqualityfiguresetup;
    
    figure(figc);figc=figc+1;
    curpart=1;highqualityfiguresetup;
    x=1981:2015;
    plot(x,yearlyavgnearcoastsst,'g','linewidth',2);hold on;
    plot(x,yearlyavgnycwbt,'r','linewidth',2);
    plot(x,yearlycounthottdays,'linewidth',2);
    legend('JJA-Avg Near-Coast SST','JJA-Avg WBT','Annual Count of Extreme-WBT Days',...
        'fontname','arial','fontweight','bold','fontsize',12);
    legend('location','northwest');
    xlabel('Year','fontname','arial','fontweight','bold','fontsize',16);
    ylabel('Temperature (deg C) or Annual Count','fontname','arial','fontweight','bold','fontsize',16);
    title('JJA-Avg Near-Coast SST vs Annual Count of Extreme-WBT Days','fontname','arial','fontweight','bold','fontsize',18);
    set(gca,'fontname','arial','fontweight','bold','fontsize',12);
    curpart=2;figloc=curDir;figname='newanalyseslinegraphsstwbt';highqualityfiguresetup;
end


if uhimetric==1
    %Use T(EWR+LGA)-T(ring of stns surrounding) to define metro-area UHI
    %surrounding stns: Atlantic City (70), Providence (97), Hartford (98), Scranton (100), Binghamton (102)
    %a bit inexact but Central Park data is really quite bad, and only exists since 1995 to boot
    uhimetric=zeros(35,4416);
    for year=1:35
        ewrdata=finaldatat{year,94};
        lgadata=finaldatat{year,95};
        ewrlgamean(year,:)=(ewrdata+lgadata)./2;
        ringstnsmean(year,:)=(finaldatat{year,70}+finaldatat{year,97}+finaldatat{year,98}+...
            finaldatat{year,100}+finaldatat{year,102})./5;
        uhimetric(year,:)=squeeze(ewrlgamean(year,:))-squeeze(ringstnsmean(year,:));
    end
    
    %Average UHI metric for each day, May 1-Oct 31
    avguhibyday=zeros(184,1);
    for day=1:184
        hourstart=day*24-23;hourend=day*24;
        avguhibyday(day)=nanmean(nanmean(uhimetric(:,hourstart:hourend)));
    end
    
    %Average UHI metric for each hour of the day, JJA
    avguhibyhour=zeros(24,1);
    for totalhourc=1:4416
        hourofday=rem(totalhourc,24);if hourofday==0;hourofday=24;end
        avguhibyhour(hourofday)=avguhibyhour(hourofday)+nanmean(uhimetric(:,totalhourc));
    end
    avguhibyhour=avguhibyhour./184;
    avguhibyhour=[avguhibyhour(6:24);avguhibyhour(1:5)];
    
    %EWR, JFK, and EWR-JFK daily T for all days
    for year=1:35
        for day=1:184
            ewrdailyt(year,day)=nanmean(finaldatat{year,94}(day*24-23:day*24));
            jfkdailyt(year,day)=nanmean(finaldatat{year,179}(day*24-23:day*24));
            ewrminusjfkdailyt(year,day)=ewrdailyt(year,day)-jfkdailyt(year,day);
            ewrdailyt1d((year-1)*184+day)=ewrdailyt(year,day);
            jfkdailyt1d((year-1)*184+day)=jfkdailyt(year,day);
            ewrminusjfkdailyt1d((year-1)*184+day)=ewrminusjfkdailyt(year,day);
        end
    end
    
    %UHI on NYC hot days, plus various other metrics to compare it with
    for i=1:100
        thishotdayyear=nycdailyavgvecwbt(i,2);relyear=thishotdayyear-yeariwf+1;
        if rem(thishotdayyear,4)==0;apr30doy=121;else apr30doy=120;end
        thishotdaymonth=nycdailyavgvecwbt(i,3);
        thishotdayday=nycdailyavgvecwbt(i,4);
        thishotdaydoy=DatetoDOY(thishotdaymonth,thishotdayday,thishotdayyear);
        thishotdayuhi(i)=nanmean(uhimetric(relyear,(thishotdaydoy-apr30doy)*24-23:(thishotdaydoy-apr30doy)*24));
        thishotdayuhianomfromdoyavg(i)=thishotdayuhi(i)-avguhibyday(thishotdaydoy-apr30doy);
        jfkwinddir4pmlst(i)=finaldatawinddir{relyear,179}((thishotdaydoy-apr30doy)*24-3);
        sbcyesorno(i)=dayswithsbcbydoyewrjfk(relyear,thishotdaydoy);
        ewrjfkdailytdiff(i)=nanmean(finaldatat{relyear,94}((thishotdaydoy-apr30doy)*24-23:(thishotdaydoy-apr30doy)*24))-...
            nanmean(finaldatat{relyear,179}((thishotdaydoy-apr30doy)*24-23:(thishotdaydoy-apr30doy)*24));
    end
    for year=1:35
        ewrjfkdailytdiffalljjadaysbyyear(year)=nanmean(finaldatat{year,94})-nanmean(finaldatat{year,179});
    end
    ewrjfkdailytdiffalljjadays=nanmean(ewrjfkdailytdiffalljjadaysbyyear);
    for i=1:100;ewrjfkdailytdiffanomfromjjaavg(i)=ewrjfkdailytdiff(i)-ewrjfkdailytdiffalljjadays;end
    
    %Scatterplot of EWR-JFK difference (proxy for sea breeze) vs UHI strength
    figure(figc);clf;figc=figc+1;
    scatter(ewrjfkdailytdiff,thishotdayuhianomfromdoyavg);
    
    %Scatterplot of EWR-JFK difference vs EWR T, for all days
    %This yields a clear relationship!
    figure(figc);clf;figc=figc+1;
    scatter(ewrdailyt1d,ewrminusjfkdailyt1d);
    temp=[ewrdailyt1d' ewrminusjfkdailyt1d'];
    corrcoefficient=corrcoef(temp,'rows','complete');
    
    %Using the same data, plot empirical distributions of EWR-JFK daily-avg T for each decile of EWR daily-avg T
    p10=quantile(ewrdailyt1d,0.1);p20=quantile(ewrdailyt1d,0.2);p30=quantile(ewrdailyt1d,0.3);
    p40=quantile(ewrdailyt1d,0.4);p50=quantile(ewrdailyt1d,0.5);p60=quantile(ewrdailyt1d,0.6);
    p70=quantile(ewrdailyt1d,0.7);p80=quantile(ewrdailyt1d,0.8);p90=quantile(ewrdailyt1d,0.9);
    p10temp1=ewrdailyt1d<=p10; %only <=p10 EWR daily-avg T
    p10temp2=(p10temp1.*ewrminusjfkdailyt1d)'; %corresponding EWR-JFK daily-avg T
    p10temp3=p10temp2==0;p10temp2(p10temp3)=NaN; %set values to zero instead of NaN so they don't mess up the histogram 
    p20temp1=ewrdailyt1d<=p20;p20temp1=(p20temp1.*ewrdailyt1d)>=p10;p20temp2=(p20temp1.*ewrminusjfkdailyt1d)';
    p20temp3=p20temp2==0;p20temp2(p20temp3)=NaN;
    p30temp1=ewrdailyt1d<=p30;p30temp1=(p30temp1.*ewrdailyt1d)>=p20;p30temp2=(p30temp1.*ewrminusjfkdailyt1d)';
    p30temp3=p30temp2==0;p30temp2(p30temp3)=NaN;
    p40temp1=ewrdailyt1d<=p40;p40temp1=(p40temp1.*ewrdailyt1d)>=p30;p40temp2=(p40temp1.*ewrminusjfkdailyt1d)';
    p40temp3=p40temp2==0;p40temp2(p40temp3)=NaN;
    p50temp1=ewrdailyt1d<=p50;p50temp1=(p50temp1.*ewrdailyt1d)>=p40;p50temp2=(p50temp1.*ewrminusjfkdailyt1d)';
    p50temp3=p50temp2==0;p50temp2(p50temp3)=NaN;
    p60temp1=ewrdailyt1d<=p60;p60temp1=(p60temp1.*ewrdailyt1d)>=p50;p60temp2=(p60temp1.*ewrminusjfkdailyt1d)';
    p60temp3=p60temp2==0;p60temp2(p60temp3)=NaN;
    p70temp1=ewrdailyt1d<=p70;p70temp1=(p70temp1.*ewrdailyt1d)>=p60;p70temp2=(p70temp1.*ewrminusjfkdailyt1d)';
    p70temp3=p70temp2==0;p70temp2(p70temp3)=NaN;
    p80temp1=ewrdailyt1d<=p80;p80temp1=(p80temp1.*ewrdailyt1d)>=p70;p80temp2=(p80temp1.*ewrminusjfkdailyt1d)';
    p80temp3=p80temp2==0;p80temp2(p80temp3)=NaN;
    p90temp1=ewrdailyt1d<=p90;p90temp1=(p90temp1.*ewrdailyt1d)>=p80;p90temp2=(p90temp1.*ewrminusjfkdailyt1d)';
    p90temp3=p90temp2==0;p90temp2(p90temp3)=NaN;
    p100temp1=ewrdailyt1d>p90;p100temp2=(p100temp1.*ewrminusjfkdailyt1d)';
    p100temp3=p100temp2==0;p100temp2(p100temp3)=NaN;
    
    figure(figc);clf;figc=figc+1;
    curpart=1;highqualityfiguresetup;
    colorstouse=varycolor(10);
    for i=10:10:100
        pd=fitdist(eval(['p' num2str(i) 'temp2;']),'Normal');
        x_values=-6:0.05:6;y=pdf(pd,x_values);
        plot(x_values,y,'color',colorstouse(i/10,:),'linewidth',2);
        hold on;
    end
    legend('0-10','10-20','20-30','30-40','40-50','50-60','60-70','70-80','80-90','90-100');
    set(gca,'fontname','arial','fontsize',16,'fontweight','bold');
    ylabel('Probability Density','fontname','arial','fontsize',16,'fontweight','bold');
    xlabel('EWR-JFK Temperature Difference (deg C)','fontname','arial','fontsize',16,'fontweight','bold');
    title('Empirical Distributions of EWR-JFK T by Decile of EWR T','fontname','arial','fontsize',20,'fontweight','bold');
    curpart=2;figloc=curDir;figname='newanalysesdecilesewrjfkt';highqualityfiguresetup;
end


if annualheatstress==1
    totalhoursheatstress=zeros(190,1);
    totalhoursheatstressshoulder=zeros(190,1);totalhoursheatstresspeak=zeros(190,1);
    for stn=1:190
        for year=1:35
            heatstressthisyear=finaldatawbt{year,stn}>=25;
            totalhoursheatstress(stn)=totalhoursheatstress(stn)+sum(heatstressthisyear);
            for i=1:4416
                if finaldatawbt{year,stn}(i)>=25 && (i<1500 || i>2900) %May, Jun, Sep, Oct
                    totalhoursheatstressshoulder(stn)=totalhoursheatstressshoulder(stn)+1;
                elseif finaldatawbt{year,stn}(i)>=25 %Jul, Aug
                    totalhoursheatstresspeak(stn)=totalhoursheatstresspeak(stn)+1;
                end
            end
        end
        avghoursheatstress(stn)=totalhoursheatstress(stn)./35;
        avghoursheatstressshoulder(stn)=totalhoursheatstressshoulder(stn)./35;
        avghoursheatstresspeak(stn)=totalhoursheatstresspeak(stn)./35;
    end
    
    thingtoplot=eval(['avghoursheatstress' whattoplot ';']);
    if strcmp(whattoplot,'')
        l1=5;l2=20;l3=50;l4=125;l5=500;l6=round2(max(thingtoplot),100);
        titlename='Annual';
    elseif strcmp(whattoplot,'peak')
        l1=100;l2=250;l3=400;l4=550;l5=700;l6=round2(max(thingtoplot),100);
        titlename='Jul-Aug';
    else
        l1=100;l2=250;l3=400;l4=550;l5=700;l6=round2(max(thingtoplot),100);
        titlename='Shoulder Seasons';
    end
    plotBlankMap(figc,'usa');figc=figc+1;
    curpart=1;highqualityfiguresetup;
    for stn=190:-1:1
        if thingtoplot(stn)<=l1
            color=colors('purple');
        elseif thingtoplot(stn)<=l2
            color=colors('blue');
        elseif thingtoplot(stn)<=l3
            color=colors('sky blue');
        elseif thingtoplot(stn)<=l4
            color=colors('green');
        elseif thingtoplot(stn)<=l5
            color=colors('orange');
        else
            color=colors('red');
        end

        pt1lat=newstnNumListlats(stn);pt1lon=newstnNumListlons(stn);
        h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker','s',...
            'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',11);
    end
    mycolormap=[colors('purple');colors('blue');...
        colors('sky blue');colors('green');colors('orange');colors('red')];
    colormap(mycolormap);titlec=4;
    colorbarc=3.5;edamultipurposelegendcreator;
    text(1.15,0.35,'Number of Hours','fontname','arial','fontsize',16,...
        'fontweight','bold','units','normalized','rotation',90);
    title(strcat(['Number of Hours with WBT >=25 deg C, ',titlename]),...
        'fontname','arial','fontweight','bold','fontsize',18);
    curpart=2;figloc=curDir;figname='newanalyseswbtexceedmapnational';highqualityfiguresetup;
    
    if strcmp(whattoplot,'')
        l1=10;l2=30;l3=50;l4=70;l5=100;l6=150;
        titlename='Annual';
    elseif strcmp(whattoplot,'peak')
        l1=10;l2=30;l3=50;l4=70;l5=100;l6=150;
        titlename='Jul-Aug';
    else
        l1=10;l2=30;l3=50;l4=70;l5=100;l6=150;
        titlename='Shoulder Seasons';
    end
    thingtoplot=eval(['avghoursheatstress' whattoplot ';']);
    plotBlankMap(figc,'us-ne-small');figc=figc+1;
    for stn=190:-1:1
        if thingtoplot(stn)<=10
            color=colors('purple');
        elseif thingtoplot(stn)<=30
            color=colors('blue');
        elseif thingtoplot(stn)<=50
            color=colors('sky blue');
        elseif thingtoplot(stn)<=70
            color=colors('green');
        elseif thingtoplot(stn)<=100
            color=colors('orange');
        else
            color=colors('red');
        end

        pt1lat=newstnNumListlats(stn);pt1lon=newstnNumListlons(stn);
        h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker','s',...
            'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',11);
    end
    mycolormap=[colors('purple');colors('blue');...
        colors('sky blue');colors('green');colors('orange');colors('red')];
    colormap(mycolormap);titlec=4;
    colorbarc=3.5;edamultipurposelegendcreator;
    text(1.2,0.35,'Number of Hours','fontname','arial','fontsize',16,...
        'fontweight','bold','units','normalized','rotation',90);
    title(strcat(['Number of Hours with WBT >=25 deg C, ',titlename]),...
        'fontname','arial','fontweight','bold','fontsize',18);
    curpart=2;figloc=curDir;figname='newanalyseswbtexceedmapne';highqualityfiguresetup;
    
    %Annual cycles for Gulf Coast and inland-South stations
    %gulfcoaststns=
end

%Gulf and Atlantic coasts only
if wbtexceed25ssthistogram==1
    gulfcoastcoastalstns=[16;17;18;19;20;21;22;27;29;32;35;36];
    gulfcoastinlandstns=[23;24;25;26;28;30;31;33;34;37;38;39];
    atlanticcoastalstns=[47;48;70;95;96;97;99;138;178;179];
    atlanticinlandstns=[49;50;55;66;67;68;69;71;94;98;100;137;139];
    %Compute seasonal cycle of climatological fraction of days exceeding 25C for each of the 4 sets of stations
    temp=zeros(27,4);
    for stn=1:size(gulfcoastcoastalstns,1)
        stnnum=gulfcoastcoastalstns(stn);
        for year=1:35
            for i=1:4416
                if finaldatawbt{year,stnnum}(i)>=25
                    curweek=round2(i/168,1,'ceil');
                    temp(curweek,1)=temp(curweek,1)+1;
                end
            end
        end
        temp(:,1)=100.*temp(:,1)./(35*168);
    end
    for stn=1:size(gulfcoastinlandstns,1)
        stnnum=gulfcoastinlandstns(stn);
        for year=1:35
            for i=1:4416
                if finaldatawbt{year,stnnum}(i)>=25
                    curweek=round2(i/168,1,'ceil');
                    temp(curweek,2)=temp(curweek,2)+1;
                end
            end
        end
        temp(:,2)=100.*temp(:,2)./(35*168);
    end
    for stn=1:size(atlanticcoastalstns,1)
        stnnum=atlanticcoastalstns(stn);
        for year=1:35
            for i=1:4416
                if finaldatawbt{year,stnnum}(i)>=25
                    curweek=round2(i/168,1,'ceil');
                    temp(curweek,3)=temp(curweek,3)+1;
                end
            end
        end
        temp(:,3)=100.*temp(:,3)./(35*168);
    end
    for stn=1:size(atlanticinlandstns,1)
        stnnum=atlanticinlandstns(stn);
        for year=1:35
            for i=1:4416
                if finaldatawbt{year,stnnum}(i)>=25
                    curweek=round2(i/168,1,'ceil');
                    temp(curweek,4)=temp(curweek,4)+1;
                end
            end
        end
        temp(:,4)=100.*temp(:,4)./(35*168);
    end
    
    
    %Just plot the seasonal cycle of Gulf near-coast SST on top of these percent curves
    southlat=28;northlat=32;westlon=265;eastlon=278;
    leftcolumn=720-((90-southlat)*4);rightcolumn=720-((90-northlat)*4);
    toprow=westlon*4;bottomrow=eastlon*4;
    weeklysstdata=zeros(27,35);
    for year=1982:2014
        fprintf('Current year is %d\n',year);
        dailysstfile1=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(year),'0101-',...
            num2str(year),'0630.nc'),'tos'); %daily data from Jan 1 to Jun 30
        dailysstfile1gulfonly=dailysstfile1(toprow:bottomrow,leftcolumn:rightcolumn,:);clear dailysstfile1;
        for weekinmjjaso=1:8
            weeklysstdata(weekinmjjaso,year-1982+1)=...
                nanmean(nanmean(nanmean(dailysstfile1gulfonly(:,:,122+weekinmjjaso*7-6:122+weekinmjjaso*7))))-273.15;
        end
        clear dailysstfile1gulfonly;
        dailysstfile2=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(year),'0701-',...
            num2str(year),'1231.nc'),'tos'); %daily data from Jul 1 to Dec 31
        dailysstfile2gulfonly=dailysstfile2(toprow:bottomrow,leftcolumn:rightcolumn,:);clear dailysstfile2;
        for weekinmjjaso=9:26
            weeklysstdata(weekinmjjaso,year-1982+1)=...
                nanmean(nanmean(nanmean(dailysstfile2gulfonly(:,:,(weekinmjjaso-8)*7-6:(weekinmjjaso-8)*7))))-273.15;
        end
        clear dailysstfile2gulfonly;
    end
    save(strcat(curDir,'newanalyses4'),'weeklysstdata','-append');
    climweeklysst=mean(weeklysstdata,2);
    %Normalize each region by its count of >=25-C WBT hours
    normcountgccoastal=100*temp(:,1)./sum(temp(:,1)); %percent of annual >=25-C WBT hours occurring in each week, climatologically 
    normcountgcinland=100*temp(:,2)./sum(temp(:,2));
    %Plot!!
    figure(figc);figc=figc+1;
    curpart=1;highqualityfiguresetup;
    plot(normcountgccoastal,'linewidth',2);hold on;
    plot(normcountgcinland,'g','linewidth',2);plot(climweeklysst(1:26),'r','linewidth',2);
    legend('Coastal Stns','Inland Stns','Near-Coast SST');
    legend('location','east');
    set(gca,'fontname','arial','fontweight','bold','fontsize',16);
    set(gca,'xticklabel','');
    xaxislabels={'May 1','Jun 1','Jul 1','Aug 1','Sep 1','Oct 1'};
    ax=gca;set(ax,'XTick',[1 1+31/7 1+61/7 1+92/7 1+123/7 1+153/7]);
    set(gca,'XTickLabel',xaxislabels,'fontsize',14,'fontweight','bold','fontname','arial');
    xlim([1 1+183/7]);
    xlabel('Month','fontname','arial','fontweight','bold','fontsize',16);
    ylabel('Degrees C or Percent','fontname','arial','fontweight','bold','fontsize',16);
    title('Weekly-Average 25C WBT Exceedances in the US South, versus Near-Coast Gulf SSTs',...
        'fontname','arial','fontweight','bold','fontsize',18);
    curpart=2;figloc=curDir;figname='newanalyseswbtexceedplot';highqualityfiguresetup;
    
    plotBlankMap(figc,'usa');figc=figc+1;
    curpart=1;highqualityfiguresetup;
    for i=1:size(gulfcoastcoastalstns,1)
        geoshow(newstnNumListlats(gulfcoastcoastalstns(i)),newstnNumListlons(gulfcoastcoastalstns(i)),...
            'DisplayType','Point','Marker','s','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',11);
    end
    for j=1:size(gulfcoastinlandstns,1)
        geoshow(newstnNumListlats(gulfcoastinlandstns(j)),newstnNumListlons(gulfcoastinlandstns(j)),...
            'DisplayType','Point','Marker','s','MarkerFaceColor','r','MarkerEdgeColor','r','MarkerSize',11);
    end
    curpart=2;figloc=curDir;figname='newanalysesgulfcoaststns';highqualityfiguresetup;
    
    
    %Perhaps, an ultimate goal would be to compute normalized fraction of days exceeding 25C
    %for each bin of near-coast SST, though the newanalyseswbtexceedplot seems like it might be
    %telling all the information that there is
end

if diurnalcycleexamination==1
    %Get diurnal cycle of T, q, and WBT for each extreme-WBT day
    stnstodo=[94;95;96;179];
    tdiurnalcycle=zeros(179,24);wbtdiurnalcycle=zeros(179,24);qdiurnalcycle=zeros(179,24);
    for stnc=1:size(stnstodo,1)
        stn=stnstodo(stnc);
        topXXwbtlist=topXXwbtbystn{stn};
        for i=1:250
            thisyear=topXXwbtlist(i,2);if rem(thisyear,4)==0;apr30doy=121;else apr30doy=120;end
            thismonth=topXXwbtlist(i,3);
            thisday=topXXwbtlist(i,4);
            thisdoy=DatetoDOY(thismonth,thisday,thisyear);
            tdataextremewbtdays(stn,i,:)=...
                finaldatat{thisyear-yeariwf+1,stn}((thisdoy-apr30doy)*24-23:(thisdoy-apr30doy)*24);
            wbtdataextremewbtdays(stn,i,:)=...
                finaldatawbt{thisyear-yeariwf+1,stn}((thisdoy-apr30doy)*24-23:(thisdoy-apr30doy)*24);
            qdataextremewbtdays(stn,i,:)=...
                finaldataq{thisyear-yeariwf+1,stn}((thisdoy-apr30doy)*24-23:(thisdoy-apr30doy)*24);
        end
        tdiurnalcycle(stn,:)=squeeze(nanmean(tdataextremewbtdays(stn,:,:),2));
        wbtdiurnalcycle(stn,:)=squeeze(nanmean(wbtdataextremewbtdays(stn,:,:),2));
        qdiurnalcycle(stn,:)=squeeze(nanmean(qdataextremewbtdays(stn,:,:),2));
        tdiurnalstdev(stn,:)=nanstd(squeeze(tdataextremewbtdays(stn,:,:)),1);
        wbtdiurnalstdev(stn,:)=nanstd(squeeze(wbtdataextremewbtdays(stn,:,:)),1);
        qdiurnalstdev(stn,:)=nanstd(squeeze(qdataextremewbtdays(stn,:,:)),1);
        %tdiurnalcycle(stn,:)=[tdiurnalcycle(stn,6:24) tdiurnalcycle(stn,1:5)];
        %wbtdiurnalcycle(stn,:)=[wbtdiurnalcycle(stn,6:24) wbtdiurnalcycle(stn,1:5)];
        %qdiurnalcycle(stn,:)=[qdiurnalcycle(stn,6:24) qdiurnalcycle(stn,1:5)];
        tdiurnalplus1stdev(stn,:)=tdiurnalcycle(stn,:)+tdiurnalstdev(stn,:);
        wbtdiurnalplus1stdev(stn,:)=wbtdiurnalcycle(stn,:)+wbtdiurnalstdev(stn,:);
        qdiurnalplus1stdev(stn,:)=qdiurnalcycle(stn,:)+qdiurnalstdev(stn,:);
        tdiurnalminus1stdev(stn,:)=tdiurnalcycle(stn,:)-tdiurnalstdev(stn,:);
        wbtdiurnalminus1stdev(stn,:)=wbtdiurnalcycle(stn,:)-wbtdiurnalstdev(stn,:);
        qdiurnalminus1stdev(stn,:)=qdiurnalcycle(stn,:)-qdiurnalstdev(stn,:);
    end
end

%Main point of this is comparing MSA ratios by coastal position over a day and over a season
if msaratioanalysis==1
    for stn=1:190
        msaratio(stn,:)=corresptanomstan{stn}./correspqanomstan{stn};
        hoursofoccur(stn,:)=topXXwbtbystn{stn}(:,5);
        cooccurringt(stn,:)=correspt{stn};cooccurringq(stn,:)=correspq{stn};
    end
    %For all stations, MSA ratio and co-occurring T and q vs hour of day
    avgmsaratiobyhour=zeros(190,24);avgcooccurringtbyhour=zeros(190,24);avgcooccurringqbyhour=zeros(190,24);
    for stn=1:190
        msasum=zeros(24,1);msacount=zeros(24,1);
        tsum=zeros(24,1);tcount=zeros(24,1);
        qsum=zeros(24,1);qcount=zeros(24,1);
        for i=1:100
            if hoursofoccur(stn,i)==0;hoursofoccur(stn,i)=24;end
            if ~isnan(msaratio(stn,i)) && abs(msaratio(stn,i))<5
                msasum(hoursofoccur(stn,i))=msasum(hoursofoccur(stn,i))+msaratio(stn,i);
                msacount(hoursofoccur(stn,i))=msacount(hoursofoccur(stn,i))+1;      
            end
            tsum(hoursofoccur(stn,i))=tsum(hoursofoccur(stn,i))+cooccurringt(stn,i);
            tcount(hoursofoccur(stn,i))=tcount(hoursofoccur(stn,i))+1;   
            qsum(hoursofoccur(stn,i))=qsum(hoursofoccur(stn,i))+cooccurringq(stn,i);
            qcount(hoursofoccur(stn,i))=qcount(hoursofoccur(stn,i))+1;  
        end
        for hour=1:24
            if msacount(hour)>=3
                avgmsaratiobyhour(stn,hour)=msasum(hour)./msacount(hour);
            else
                avgmsaratiobyhour(stn,hour)=NaN;
            end
            if tcount(hour)>=3
                avgcooccurringtbyhour(stn,hour)=tsum(hour)./tcount(hour);
            else
                avgcooccurringtbyhour(stn,hour)=NaN;
            end
            if qcount(hour)>=3
                avgcooccurringqbyhour(stn,hour)=qsum(hour)./qcount(hour);
            else
                avgcooccurringqbyhour(stn,hour)=NaN;
            end
        end
    end
    %Coastal, near-coastal, and inland averages
    necoastalstns=[21;2;19;10];nenearcoastalstns=[1;6;3;18;7;8];neinlandstns=[4;5;9;11;12;13;14;15;16;17;20];
    meancoastalmsaratio=zeros(24,1);meannearcoastalmsaratio=zeros(24,1);meaninlandmsaratio=zeros(24,1);
    meancoastalcooccurringt=zeros(24,1);meannearcoastalcooccurringt=zeros(24,1);meaninlandcooccurringt=zeros(24,1);
    meancoastalcooccurringq=zeros(24,1);meannearcoastalcooccurringq=zeros(24,1);meaninlandcooccurringq=zeros(24,1);
    coastalmsac=zeros(24,1);nearcoastalmsac=zeros(24,1);inlandmsac=zeros(24,1);
    coastalcotc=zeros(24,1);nearcoastalcotc=zeros(24,1);inlandcotc=zeros(24,1);
    coastalcoqc=zeros(24,1);nearcoastalcoqc=zeros(24,1);inlandcoqc=zeros(24,1);
    for stnc=1:4
        thisstn=nestns(necoastalstns(stnc));
        for hour=1:24
            if ~isnan(avgmsaratiobyhour(thisstn,hour))
                meancoastalmsaratio(hour)=meancoastalmsaratio(hour)+avgmsaratiobyhour(thisstn,hour)';
                coastalmsac(hour)=coastalmsac(hour)+1;
            end
            if ~isnan(avgcooccurringtbyhour(thisstn,hour))
                meancoastalcooccurringt(hour)=meancoastalcooccurringt(hour)+avgcooccurringtbyhour(thisstn,hour)';
                coastalcotc(hour)=coastalcotc(hour)+1;
            end
            if ~isnan(avgcooccurringqbyhour(thisstn,hour))
                meancoastalcooccurringq(hour)=meancoastalcooccurringq(hour)+avgcooccurringqbyhour(thisstn,hour)';
                coastalcoqc(hour)=coastalcoqc(hour)+1;
            end
        end
    end
    for stnc=1:6
        thisstn=nestns(nenearcoastalstns(stnc));
        for hour=1:24
            if ~isnan(avgmsaratiobyhour(thisstn,hour))
                meannearcoastalmsaratio(hour)=meannearcoastalmsaratio(hour)+avgmsaratiobyhour(thisstn,hour)';
                nearcoastalmsac(hour)=nearcoastalmsac(hour)+1;
            end
            if ~isnan(avgcooccurringtbyhour(thisstn,hour))
                meannearcoastalcooccurringt(hour)=meannearcoastalcooccurringt(hour)+avgcooccurringtbyhour(thisstn,hour)';
                nearcoastalcotc(hour)=nearcoastalcotc(hour)+1;
            end
            if ~isnan(avgcooccurringqbyhour(thisstn,hour))
                meannearcoastalcooccurringq(hour)=meannearcoastalcooccurringq(hour)+avgcooccurringqbyhour(thisstn,hour)';
                nearcoastalcoqc(hour)=nearcoastalcoqc(hour)+1;
            end
        end
    end
    for stnc=1:11
        thisstn=nestns(neinlandstns(stnc));
        for hour=1:24
            if ~isnan(avgmsaratiobyhour(thisstn,hour))
                meaninlandmsaratio(hour)=meaninlandmsaratio(hour)+avgmsaratiobyhour(thisstn,hour)';
                inlandmsac(hour)=inlandmsac(hour)+1;
            end
            if ~isnan(avgcooccurringtbyhour(thisstn,hour))
                meaninlandcooccurringt(hour)=meaninlandcooccurringt(hour)+avgcooccurringtbyhour(thisstn,hour)';
                inlandcotc(hour)=inlandcotc(hour)+1;
            end
            if ~isnan(avgcooccurringqbyhour(thisstn,hour))
                meaninlandcooccurringq(hour)=meaninlandcooccurringq(hour)+avgcooccurringqbyhour(thisstn,hour)';
                inlandcoqc(hour)=inlandcoqc(hour)+1;
            end
        end
    end
    meancoastalmsaratio=meancoastalmsaratio./coastalmsac;
    meannearcoastalmsaratio=meannearcoastalmsaratio./nearcoastalmsac;
    meaninlandmsaratio=meaninlandmsaratio./inlandmsac;
    meancoastalcooccurringt=meancoastalcooccurringt./coastalcotc;
    meannearcoastalcooccurringt=meannearcoastalcooccurringt./nearcoastalcotc;
    meaninlandcooccurringt=meaninlandcooccurringt./inlandcotc;
    meancoastalcooccurringq=meancoastalcooccurringq./coastalcoqc;
    meannearcoastalcooccurringq=meannearcoastalcooccurringq./nearcoastalcoqc;
    meaninlandcooccurringq=meaninlandcooccurringq./inlandcoqc;
    
    %Plot diurnality results
    figure(figc);figc=figc+1;curpart=1;highqualityfiguresetup;
    plot(meancoastalmsaratio,'linewidth',2);hold on;
    plot(meannearcoastalmsaratio,'g','linewidth',2);
    plot(meaninlandmsaratio,'r','linewidth',2);
    xlim([8 22]);
    legend('Coastal','Near-Coastal','Inland');
    set(gca,'fontsize',16,'fontweight','bold','fontname','arial');
    xlabel('Hour (LST)','fontsize',16,'fontweight','bold','fontname','arial');
    ylabel('MSA Ratio','fontsize',16,'fontweight','bold','fontname','arial');
    title('Diurnality of MSA Ratio for Northeast-US Stations','fontsize',20,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='newanalysesmsaratiodiurnal';highqualityfiguresetup;
    
    figure(figc);figc=figc+1;curpart=1;highqualityfiguresetup;
    plot(meancoastalcooccurringt,'linewidth',2);hold on;
    plot(meannearcoastalcooccurringt,'g','linewidth',2);
    plot(meaninlandcooccurringt,'r','linewidth',2);
    xlim([8 22]);
    legend('Coastal','Near-Coastal','Inland');
    set(gca,'fontsize',16,'fontweight','bold','fontname','arial');
    xlabel('Hour (LST)','fontsize',16,'fontweight','bold','fontname','arial');
    ylabel('Temperature (deg C)','fontsize',16,'fontweight','bold','fontname','arial');
    title('Diurnality of T Co-Occurring with Extreme WBT, for Northeast-US Stations','fontsize',20,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='newanalysescooccurringtdiurnal';highqualityfiguresetup;
    
    figure(figc);figc=figc+1;curpart=1;highqualityfiguresetup;
    plot(meancoastalcooccurringq,'linewidth',2);hold on;
    plot(meannearcoastalcooccurringq,'g','linewidth',2);
    plot(meaninlandcooccurringq,'r','linewidth',2);
    xlim([8 22]);
    legend('Coastal','Near-Coastal','Inland');
    set(gca,'fontsize',16,'fontweight','bold','fontname','arial');
    xlabel('Hour (LST)','fontsize',16,'fontweight','bold','fontname','arial');
    ylabel('Specific Humidity (g/kg)','fontsize',16,'fontweight','bold','fontname','arial');
    title('Diurnality of q Co-Occurring with Extreme WBT, for Northeast-US Stations','fontsize',20,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='newanalysescooccurringqdiurnal';highqualityfiguresetup;
    
    
    %Compute seasonality
    for stn=1:190
        msaratio(stn,:)=corresptanomstan{stn}./correspqanomstan{stn};
        doyofoccur(stn,:)=DatetoDOY(topXXwbtbystn{stn}(:,3),topXXwbtbystn{stn}(:,4),topXXwbtbystn{stn}(:,2));
    end
    %For all stations, MSA ratio vs day of year
    avgmsaratiobydoy=zeros(190,24);
    for stn=1:190
        msasum=zeros(365,1);msacount=zeros(365,1);
        for i=1:100
            if ~isnan(msaratio(stn,i)) && abs(msaratio(stn,i))<5
                doyofoccurcateg(stn,i)=round2(doyofoccur(stn,i),5);
                msasum(doyofoccurcateg(stn,i))=msasum(doyofoccurcateg(stn,i))+msaratio(stn,i);
                msacount(doyofoccurcateg(stn,i))=msacount(doyofoccurcateg(stn,i))+1;
            end
        end
        for doy=1:365
            if msacount(doy)>=3
                avgmsaratiobydoy(stn,doy)=msasum(doy)./msacount(doy);
            else
                avgmsaratiobydoy(stn,doy)=NaN;
            end
        end
    end
    
    meancoastalmsaratio=zeros(73,1);meannearcoastalmsaratio=zeros(73,1);meaninlandmsaratio=zeros(73,1);
    coastalc=zeros(73,1);nearcoastalc=zeros(73,1);inlandc=zeros(73,1);
    for stnc=1:4
        thisstn=nestns(necoastalstns(stnc));
        pentadc=1;
        for doy=5:5:365
            pentadc=pentadc+1;
            if ~isnan(avgmsaratiobydoy(thisstn,doy)) && avgmsaratiobydoy(thisstn,doy)~=0
                meancoastalmsaratio(pentadc)=meancoastalmsaratio(pentadc)+avgmsaratiobydoy(thisstn,doy)';
                coastalc(pentadc)=coastalc(pentadc)+1;
            end
        end
    end
    for stnc=1:6
        thisstn=nestns(nenearcoastalstns(stnc));
        pentadc=1;
        for doy=5:5:365
            pentadc=pentadc+1;
            if ~isnan(avgmsaratiobydoy(thisstn,doy)) && avgmsaratiobydoy(thisstn,doy)~=0
                meannearcoastalmsaratio(pentadc)=meannearcoastalmsaratio(pentadc)+avgmsaratiobydoy(thisstn,doy)';
                nearcoastalc(pentadc)=nearcoastalc(pentadc)+1;
            end
        end
    end
    for stnc=1:11
        thisstn=nestns(neinlandstns(stnc));
        pentadc=1;
        for doy=5:5:365
            pentadc=pentadc+1;
            if ~isnan(avgmsaratiobydoy(thisstn,doy)) && avgmsaratiobydoy(thisstn,doy)~=0
                meaninlandmsaratio(pentadc)=meaninlandmsaratio(pentadc)+avgmsaratiobydoy(thisstn,doy)';
                inlandc(pentadc)=inlandc(pentadc)+1;
            end
        end
    end
    meancoastalmsaratio=meancoastalmsaratio./coastalc;
    meannearcoastalmsaratio=meannearcoastalmsaratio./nearcoastalc;
    meaninlandmsaratio=meaninlandmsaratio./inlandc;
    
    %Smooth
    for pentad=39:47
        smmeancoastalmsaratio(pentad)=0.15*meancoastalmsaratio(pentad-2)+0.2*meancoastalmsaratio(pentad-1)+...
            0.3*meancoastalmsaratio(pentad)+0.2*meancoastalmsaratio(pentad+1)+0.15*meancoastalmsaratio(pentad+2);
    end
    for pentad=40:47
        smmeannearcoastalmsaratio(pentad)=0.15*meannearcoastalmsaratio(pentad-2)+0.2*meannearcoastalmsaratio(pentad-1)+...
            0.3*meannearcoastalmsaratio(pentad)+0.2*meannearcoastalmsaratio(pentad+1)+0.15*meannearcoastalmsaratio(pentad+2);
    end
    for pentad=35:47
        smmeaninlandmsaratio(pentad)=0.15*meaninlandmsaratio(pentad-2)+0.2*meaninlandmsaratio(pentad-1)+...
            0.3*meaninlandmsaratio(pentad)+0.2*meaninlandmsaratio(pentad+1)+0.15*meaninlandmsaratio(pentad+2);
    end
    temp=smmeancoastalmsaratio==0;smmeancoastalmsaratio(temp)=NaN;
    temp=smmeannearcoastalmsaratio==0;smmeannearcoastalmsaratio(temp)=NaN;
    temp=smmeaninlandmsaratio==0;smmeaninlandmsaratio(temp)=NaN;
    
    %Plot seasonality results
    figure(figc);figc=figc+1;curpart=1;highqualityfiguresetup;
    plot(meancoastalmsaratio,'linewidth',2,'linestyle',':');hold on;
    plot(meannearcoastalmsaratio,'g','linewidth',2,'linestyle',':');
    plot(meaninlandmsaratio,'r','linewidth',2,'linestyle',':');
    xlim([33 50]);
    plot(smmeancoastalmsaratio,'linewidth',4);
    plot(smmeannearcoastalmsaratio,'g','linewidth',4);
    plot(smmeaninlandmsaratio,'r','linewidth',4);
    legend('Coastal','Near-Coastal','Inland');
    set(gca,'fontsize',16,'fontweight','bold','fontname','arial');
    xlabel('Pentad','fontsize',16,'fontweight','bold','fontname','arial');
    ylabel('MSA Ratio','fontsize',16,'fontweight','bold','fontname','arial');
    title('Seasonality of MSA Ratio for Northeast-US Stations','fontsize',20,'fontweight','bold','fontname','arial');
    curpart=2;figloc=curDir;figname='newanalysesmsaratioseasonal';highqualityfiguresetup;
    
    plotBlankMap(figc,'us-ne');figc=figc+1;
    for stn=1:4
        stnnum=nestns(necoastalstns(stn));
        geoshow(newstnNumListlats(stnnum),newstnNumListlons(stnnum),...
            'DisplayType','Point','Marker','s','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',11);
    end
    for stn=1:6
        stnnum=nestns(nenearcoastalstns(stn));
        geoshow(newstnNumListlats(stnnum),newstnNumListlons(stnnum),...
            'DisplayType','Point','Marker','s','MarkerFaceColor','g','MarkerEdgeColor','g','MarkerSize',11);
    end
    for stn=1:11
        stnnum=nestns(neinlandstns(stn));
        geoshow(newstnNumListlats(stnnum),newstnNumListlons(stnnum),...
            'DisplayType','Point','Marker','s','MarkerFaceColor','r','MarkerEdgeColor','r','MarkerSize',11);
    end
    curpart=2;figloc=curDir;figname='newanalysesnecoastalinlandstnmap';highqualityfiguresetup;
    
    plotBlankMap(figc,'nyc-area');figc=figc+1;
    nycstns=[6;7;21];
    for stn=1:3
        stnnum=nestns(nycstns(stn));
        geoshow(newstnNumListlats(stnnum),newstnNumListlons(stnnum),...
            'DisplayType','Point','Marker','s','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',11);
    end
    curpart=2;figloc=curDir;figname='newanalysesnycstnmap';highqualityfiguresetup;
end


