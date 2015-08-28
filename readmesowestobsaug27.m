%Reads in MesoWest station data that has hourly T, RH, winds, etc
%Primary aim is to compare these point humidity and wind values with NARR
%ones, to establish biases before using the NARR (which is not only
%spatially continuous but has a longer temporal record, 1979-pres vs 2002-pres)
%Order in spreadsheets doesn't matter because everything will be
%chronologically sorted at the end anyway
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

%of 311 total recorded there

%Because the heatwaves are already defined, just do an analogous thing to 
%what I did before in readnycdata to create total-severity scores in the 
%matrix hwsorted: namely, integrate heat indices over the course of the
%heatwave. The actual numerical value doesn't matter, just its size relative
%to the other pre-defined heatwaves.

%Variables to set
numstns=11;
stnpr={'KEWR';'KTEB';'KNYC';'KLGA';'KJFK';'KACY';'KPHL';'KTTN';'KBDR';'KHPN';'KISP'};
stnpr2={'kewr';'kteb';'knyc';'klga';'kjfk';'kacy';'kphl';'kttn';'kbdr';'khpn';'kisp'};
acceptt=[49;50;51;52;53;54;55;56]; %acceptable/standard obs times, in min after the hour
%third column in hwstarts is hw length (again, as defined at Central Park)
hwstarts=[223 2002 5;199 2011 7;195 2013 9;185 2010 6;214 2005 4;208 2006 9;175 2003 4;172 2012 3;...
    219 2005 8;171 2010 10;158 2008 5;220 2010 4];
excludeaug2002=1;
checkformissingtimes=0;
makescatterplot=1; %of heatwave severity scores
groupbyregion=0; %for scatterplot, whether to split into coast and inland groups (vs each station individually)
consolidatestns=0; %for scatterplot, whether to plot the average position of each stn (vs one pt per heatwave)
maxonly=0; %for scatterplot, whether to plot dry & wet scores derived only from max/daytime values (vs all)
minonly=1; %same as above, but for min/nighttime values

%That's all the settings, time to calculate
hwstarts=sortrows(hwstarts,2); %chronological order
numhws=size(hwstarts,1);
if excludeaug2002==1;reduc=-1;else reduc=0;end
hwlengths=zeros(numstns,numhws);hwintegindb=zeros(numstns,numhws);

%First, read in csv files and clean them up, by doing unit conversions,
%eliminating intra-hourly special readings, etc
%Also can check for missing times
%Strangely, some use 24-hr time and others 12-hr
%Patriotically, the resulting total number of hours in these heatwaves is 1776!
cd /Users/colin/Desktop/General_Academics/Research/Exploratory_Plots/MesoWest_Hourly_Stn_Obs
kewr=csvread('KEWR-data.csv');kteb=csvread('KTEB-data.csv');
knyc=csvread('KNYC-data.csv');klga=csvread('KLGA-data.csv');
kjfk=csvread('KJFK-data.csv');kacy=csvread('KACY-data.csv');
kphl=csvread('KPHL-data.csv');kttn=csvread('KTTN-data.csv');
kbdr=csvread('KBDR-data.csv');khpn=csvread('KHPN-data.csv');
kisp=csvread('KISP-data.csv');

cleandata={};
for i=1:numstns
    curstn=stnpr2{i};
    
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


%Compare heatwave-severity scores from hwsorted (using daily max & min alone)
%to those computed above (using the full heat index and hourly data)
%For hourly data, summing above the 90th percentile over the heatwave
%as was done for daily data perhaps is not the best strategy, as it
%tends to lessen the differences between heatwaves
%Since these hourly obs solely consist of heatwave days, I estimated above
%that the 70th hourly pctile here is roughly equal to the 90th overall 
%(for each stn separately of course)

%Numbering is different than in readnycdata, so account for that
%Also, in hwintegind, hw's are in chronological order -- need to wrangle
%the others into that as well, for the dual purposes of sanity and organization
numberingconvvec(1,:)=[1 5]; %Newark
numberingconvvec(2,:)=[2 14]; %Teterboro
numberingconvvec(3,:)=[3 7]; %Central Park
numberingconvvec(4,:)=[4 4]; %LGA
numberingconvvec(5,:)=[5 3]; %JFK
numberingconvvec(6,:)=[6 1]; %AtlCityA
numberingconvvec(7,:)=[7 13]; %PhiladelphiaA
numberingconvvec(8,:)=[8 9]; %TrentonA
numberingconvvec(9,:)=[9 2]; %BridgeportA
numberingconvvec(10,:)=[10 6]; %WhitePlainsA
numberingconvvec(11,:)=[11 18]; %IslipA

scorescompb=zeros(numstns,numhws+reduc,2); %b is for both
scorescompx=zeros(numstns,numhws+reduc,2);scorescompn=zeros(numstns,numhws+reduc,2);
wetscoreb=zeros(numhws+reduc,3);
wetscorex=zeros(numhws+reduc,3);wetscoren=zeros(numhws+reduc,3);
for i=1:numstns
    oldnum=numberingconvvec(i,2);
    c=1;dryscore=zeros(numhws,3);
    dryscorex=zeros(numhws,3);dryscoren=zeros(numhws,3); %for max only, & min only
    for jj1=1:size(dailymaxvecs1D{oldnum},1)
        for jj1b=2:numhws
            if dailymaxvecs1D{oldnum}(jj1,2)==hwstarts(jj1b,1) &&...
                    dailymaxvecs1D{oldnum}(jj1,3)==hwstarts(jj1b,2) %hw start in C Park
                thismon=round2(dailymaxvecs1D{oldnum}(jj1,2)/30,1,'ceil'); %doesn't have to be exact, just for 90th-pct purposes
                pctile90max=monthlyprctilemaxes{oldnum}(thismon,6);pctile90min=monthlyprctilemins{oldnum}(thismon,6);
                %disp(jj1);disp(oldnum);disp(pctile90max);disp(pctile90min);
                for k=1:hwstarts(jj1b,3) %loop through the duration of the heatwave, hour by hour
                    if dailymaxvecs1D{oldnum}(jj1+k-1,1)>0
                        dryscore(c,1)=dryscore(c,1)+dailymaxvecs1D{oldnum}(jj1+k-1,1)-pctile90max;
                        dryscorex(c,1)=dryscorex(c,1)+dailymaxvecs1D{oldnum}(jj1+k-1,1)-pctile90max;
                    end
                    if dailyminvecs1D{oldnum}(jj1+k-1,1)>0
                        dryscore(c,1)=dryscore(c,1)+dailyminvecs1D{oldnum}(jj1+k-1,1)-pctile90min;
                        dryscoren(c,1)=dryscoren(c,1)+dailyminvecs1D{oldnum}(jj1+k-1,1)-pctile90min;
                    end
                    
                end
                dryscore(c,2)=hwstarts(jj1b,1);dryscorex(c,2)=hwstarts(jj1b,1);dryscoren(c,2)=hwstarts(jj1b,1);
                dryscore(c,3)=hwstarts(jj1b,2);dryscorex(c,3)=hwstarts(jj1b,2);dryscoren(c,3)=hwstarts(jj1b,2);
                %fprintf('End dates for dry-score heatwave #%d',jj1b);disp(dryscore(c,2)+hwstarts(c,3)-1);disp(dryscore(c,3));
                c=c+1;
            end
        end
    end
      
    for jj2=1-reduc:numhws %excluding hw #1, the truncated one in Aug 2002
        wetscoreb(jj2+reduc,1)=hwintegindb(i,jj2);
        wetscorex(jj2+reduc,1)=hwintegindx(i,jj2);wetscoren(jj2+reduc,1)=hwintegindn(i,jj2);
        wetscoreb(jj2+reduc,2)=hwstarts(jj2,1);wetscorex(jj2+reduc,2)=hwstarts(jj2,1);wetscoren(jj2+reduc,2)=hwstarts(jj2,1);
        wetscoreb(jj2+reduc,3)=hwstarts(jj2,2);wetscorex(jj2+reduc,3)=hwstarts(jj2,2);wetscoren(jj2+reduc,3)=hwstarts(jj2,2);
    end
    
    %Chronological order
    dryscore=sortrows(dryscore,3);dryscorex=sortrows(dryscorex,3);dryscoren=sortrows(dryscoren,3);
    wetscoreb=sortrows(wetscoreb,3);
    dryscore=dryscore(1-reduc:numhws,:); %again, excluding Aug 2002
    dryscorex=dryscorex(1-reduc:numhws,:);dryscoren=dryscoren(1-reduc:numhws,:);
    
    scorescompb(i,:,1)=dryscore(:,1);scorescompx(i,:,1)=dryscorex(:,1);scorescompn(i,:,1)=dryscoren(:,1);
    scorescompb(i,:,2)=wetscoreb(:,1);scorescompx(i,:,2)=wetscorex(:,1);scorescompn(i,:,2)=wetscoren(:,1);
end
for i=1:numstns
    scorescomp2b(i,1)=sum(scorescompb(i,:,1))/(numhws+reduc);
    scorescomp2x(i,1)=sum(scorescompx(i,:,1))/(numhws+reduc);scorescomp2n(i,1)=sum(scorescompn(i,:,1))/(numhws+reduc);
    scorescomp2b(i,2)=sum(scorescompb(i,:,2))/(numhws+reduc);
    scorescomp2x(i,2)=sum(scorescompx(i,:,2))/(numhws+reduc);scorescomp2n(i,2)=sum(scorescompn(i,:,2))/(numhws+reduc);
end

%Create scatterplot of dry score vs wet score for all stns over these recent heatwaves
if makescatterplot==1
    if maxonly==1;suffix=['x'];phr=', Max Only';elseif minonly==1;suffix=['n'];phr=', Min Only';else suffix=['b'];phr='';end
    sc=eval(['scorescomp' suffix]);sc2=eval(['scorescomp2' suffix]);
    colorlist={colors('red');colors('light red');colors('orange');colors('green');colors('teal');...
        colors('light blue');colors('blue');colors('light purple');colors('pink');colors('brown');colors('grey')};
    grouplist=[2,2,2,2,1,1,2,2,1,2,1];
    colorlistg={colors('red');colors('green')};
    markerlist={'s';'d';'h';'v';'o'};
    figure(figc);figc=figc+1;
    noonesyet=1;notwosyet=1;h=0;hc=1;
    for i=1:numstns
        if consolidatestns==0
            for j=1:numhws+reduc
                %disp(colorlist{i});
                if groupbyregion==1
                    scatter(sc(i,j,1),sc(i,j,2),'MarkerFaceColor',colorlistg{grouplist(i)},...
                            'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                    if grouplist(i)==1 && noonesyet==1 %only do once for each group
                        h(hc)=scatter(sc(i,j,1),sc(i,j,2),'MarkerFaceColor',colorlistg{grouplist(i)},...
                            'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                        hc=hc+1;noonesyet=0;
                    elseif grouplist(i)==2 && notwosyet==1
                        h(hc)=scatter(sc(i,j,1),sc(i,j,2),'MarkerFaceColor',colorlistg{grouplist(i)},...
                            'MarkerEdgeColor',colorlistg{grouplist(i)},'LineWidth',3);
                        hc=hc+1;notwosyet=0;
                    end
                else
                    scatter(sc(i,j,1),sc(i,j,2),'MarkerFaceColor',colorlist{i},...
                            'MarkerEdgeColor',colorlist{i},'LineWidth',3);
                    if j==1 %only do once for each stn, to give plot handles the info they need
                        h(i)=scatter(sc(i,j,1),sc(i,j,2),'MarkerFaceColor',colorlist{i},...
                            'MarkerEdgeColor',colorlist{i},'LineWidth',3);
                    end
                end
                hold on;
            end
        else
            scatter(sc2(i,1),sc2(i,2),'MarkerFaceColor',colorlist{i},...
                            'MarkerEdgeColor',colorlist{i},'LineWidth',3);hold on;
            h(i)=scatter(sc2(i,1),sc2(i,2),'MarkerFaceColor',colorlist{i},...
                            'MarkerEdgeColor',colorlist{i},'LineWidth',3);        
        end
    end
    if groupbyregion==1
        groups={'Inland';'Coastal'};
        legend(h,groups,'Location','Southeast');
    else
        legend(h,stnpr,'Location','Southeast');
    end
    xlabel('Heatwave Severity Score by Temperature Alone','FontSize',14);
    ylabel('Heatwave Severity Score by Hourly Heat Index','FontSize',14);
    title(sprintf('Severity Scores of %d Heatwaves (2002-2013) With and Without Humidity Factored In%s',numhws,phr),...
        'FontSize',16,'FontWeight','bold');
end


%Average temperatures on regional hot days (the ones analyzed in
%readnarrdata) that occurred after 2002 (as this is of course using station data from MesoWest)
%Daily-average temps are calculated from hourly obs
hoteventsstns={};
for i=1:1
%for i=1:numstns
    eventc=0;hour=1;
    while hour<=size(cleandata{1},1)
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
    


