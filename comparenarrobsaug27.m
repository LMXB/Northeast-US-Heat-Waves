%Compares NARR and observational data for given months
%The NARR data I have is once-daily, so have to average station-obs max & min as
%approximation
%Do statistics first, and then later produce maps
%Also look in how justified it really is to avg station-obs max & min as a proxy for
%avg daily temp (typically averaged over 24 hourly obs) -- do both for
%hourly obs and compare

%Run readnarrdata and readnycdata before running this script, or load results

%Current runtime: 

daysinm=0;prevdaysinm=0;
startyear=1979;stopyear=1999;numyears=stopyear-startyear+1;
stniwf=4;stniwl=4; %from prefixes in readnycdata
yeariwf=1;yeariwl=2; %1979=1
monthiwf=1;monthiwl=12;
m1s=1;m2s=32;m3s=61;m4s=92;m5s=122;m6s=153;m7s=183;m8s=214;m9s=245;m10s=275;m11s=306;m12s=336;
adj=6; %number of years to adjust by, because cleanmonthlymaxes start in 1973
pr1={'AtlCityA';'BridgeportA';'JFK';'LaGuardia';'NewarkA';'WhitePlA';...
    'CentralPark';'Brooklyn'}; %A stands for Airport
pr2={'TrentonA';'TrentonCity';'AtlCity';'TomsRiver';'PhiladelphiaA'};
pr3={'TeterboroA';'LittleFalls';'Paterson';'JerseyCity'};
pr4={'IslipA';'Scarsdale';'DobbsFerry';'PortJervis';'Mineola'};
pr=[pr1;pr2;pr3;pr4]; %station sets to use in this run -- JFK, LGA, EWR are 3,4,5 in a standard run
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
stnlocs=[stnlocs1;stnlocs2;stnlocs3;stnlocs4];



%Basically, put all the data in 3D cells (a cool jail for it)
numstnsiw=stniwl-stniwf+1;numyearsiw=yeariwl-yeariwf+1;
nummonthsiw=monthiwl-monthiwf+1;
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
            narravgts{stn,year,month}=squeeze(Tcell{year,month}(clgp(stn,1),clgp(stn,2),1,:));
            narravgtsn{stn,year,month}=squeeze(Tcell{year,month}(clgp(stn,1)+1,clgp(stn,2),1,:));
            narravgtss{stn,year,month}=squeeze(Tcell{year,month}(clgp(stn,1)-1,clgp(stn,2),1,:));
            narravgtse{stn,year,month}=squeeze(Tcell{year,month}(clgp(stn,1),clgp(stn,2)+1,1,:));
            narravgtsw{stn,year,month}=squeeze(Tcell{year,month}(clgp(stn,1),clgp(stn,2)-1,1,:));
            %alternative regional formulation: jul1979temps(day,:,:)=Tcell{1,7}(129:131,257:260,1,day);
        end
    end
end

%maxes are offset by a day because of the 8 AM practice
%Compare observational max, min, and avg with NARR avg computed with
%(min+max)/2 and hourly-average formulations
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
plot(obsmaxts{stniw,yeariw,monthiw},'Color',colors('red'));hold on;
plot(obsmints{stniw,yeariw,monthiw},'Color',colors('light blue'));hold on;
plot(dhavgvecs{stniw}(sd:ed,yeariw)+Kc,'Color',colors('blue'));hold on;
plot(narravgts{stniw,yeariw,monthiw},'LineWidth',5,'Color',colors('green')); %and for closest NARR gridpt
plot(narravgtsn{stniw,yeariw,monthiw},'LineStyle',':','Color',colors('fuchsia')); %adjacent gridpts
plot(narravgtss{stniw,yeariw,monthiw},'LineStyle',':','Color',colors('gray'));
plot(narravgtse{stniw,yeariw,monthiw},'LineStyle',':','Color',colors('dark blue'));
plot(narravgtsw{stniw,yeariw,monthiw},'LineStyle',':','Color',colors('purple'));
legend('Obs (Min+Max)/2','Obs Max','Obs Min','Obs Hourly Avg','Colocated NARR Gridpt',...
    'Gridpt to N','Gridpt to S','Gridpt to E','Gridpt to W');

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
%Example: average error at JFK in October is mean(diffavgs(4,:,10));
%Chart of errors with showing rough confidence bounds
for stn=stniwf:stniwl
    figure(figc);figc=figc+1;
    plot(squeeze(mean(diff50s(stn,:,:))));hold on; %for each month
    plot(squeeze(mean(diff975s(stn,:,:))),'Color',colors('green'));
    plot(squeeze(mean(diff25s(stn,:,:))),'Color',colors('red'));
    xlim([1 12]);
    phrase=sprintf('%s NARR-Obs Difference',char(prefixes(stn)));
    title(phrase,'FontSize',14);
    legend('Average of Abs. Values','97.5th Percentile','2.5th Percentile');
end

%errors bow out from zero in the winter as opposed to the summer


cg=wnarrgridpts(40.76,-73.98);
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

%Example: data for July 1979
%jul1979temps=zeros(31,3,4); 
%(130,258) aka Newark will be (:,2,2) in this regional matrix; 
%(130,259) aka JFK is likewise (:,2,3)
%for day=1:31;jul1979temps(day,:,:)=Tcell{1,1,7}(129:131,257:260,1,day);end



%Compare stations to the weighted avg of their surrounding NARR gridpts for
%JJA days with max temp >90th percentile, 40th-60th percentile, and <10th percentile
%Also implement for min temp
%Start with AtlCityA (#1); ovy is overlap year (relative to 1864, with 1865=1)
for stnc=1:1
    closest4=wnarrgridpts(stnlocs(stnc,1),stnlocs(stnc,2));
    dayc=1;
    for mon=6:8
        if mon==6;monlen=30;else monlen=31;end
        for day=1:monlen
            stnoutputmaxes=cmmaxwy{stnc,ovy,mon}(day);
            stnoutputmins=cmminwy{stnc,ovy,mon}(day);
            wnarroutput=(closest4(1,3)*Tcell{1,ovy-114,mon}(closest4(1,1),closest4(1,2),1,day)+...
                closest4(2,3)*Tcell{1,ovy-114,mon}(closest4(2,1),closest4(2,2),1,day)+...
                closest4(3,3)*Tcell{1,ovy-114,mon}(closest4(3,1),closest4(3,2),1,day)+...
                closest4(4,3)*Tcell{1,ovy-114,mon}(closest4(4,1),closest4(4,2),1,day))-273.15;
            stnoutputvec(dayc)=(stnoutputmaxes+stnoutputmins)/2;wnarroutputvec(dayc)=wnarroutput;
            dayc=dayc+1;
        end
    end
end
