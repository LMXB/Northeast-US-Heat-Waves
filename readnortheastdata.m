%Alternative to makeheatwaverankingnew in analyzenycdata, using the same dataset as
    %compiled for & used in the WBT/T overlap paper
%Northeast stations within that US dataset are:
%69 -- Baltimore/Washington, MD
%70 -- Atlantic City, NJ
%71 -- Philadelphia, PA
%73 -- Charleston, WV
%77 -- Huntington, WV (5)
%94 -- Newark, NJ
%95 -- Queens LGA, NY
%96 -- Islip, NY -- eliminated b/c missing too much data in the second half of the time period
%97 -- Providence, RI
%98 -- Hartford, CT 
%99 -- Boston, MA (10)
%100 - Scranton, PA
%101 - Williamsport, PA
%102 - Binghamton, NY
%103 - Pittsburgh, PA 
%107 - Erie, PA (15)
%108 - Buffalo, NY
%109 - Rochester, NY
%137 - Concord, NH
%138 - Portland, ME 
%139 - Burlington, VT (20)
%178 - Brunswick, ME -- eliminated b/c missing too much data in the second half of the time period
%179 - Queens JFK, NY
nestns=[69;70;71;73;77;94;95;97;98;99;100;101;102;103;107;108;109;137;138;139;179];
monthhourends=[744;1464;2208;2952;3672];
highpct=0.975;lowpct=0.90;savestuff=1; %defaults are 0.975 and 0.90, and these are used in all subsequent
        %plots unless otherwise specified
    %low pct was increased from 0.81 to 0.90 to increase the number of short heat waves vis-à-vis long ones
%highpct=0.925;lowpct=0.70;savestuff=0; %alternative that increases the number of heat waves, used only for
    %the plots which require a larger sample size -- used only temporarily, with the results not saved
    %into the official mat files
utclst=5;

curDir='/Users/craymon3/General_Academics/Research/Exploratory_Plots/';

%Runtime options
%Execute only one loop at a time
computeprctiles=0; %1 min
    if computeprctiles==1
        variwf=1;variwl=3;
        stniwf=1;stniwl=size(nestns,1);
        yeariwf=1981;yeariwl=2015;relyeariwf=1;relyeariwl=35;
        monthiwf=6;monthiwl=8;relmonthiwf=2;relmonthiwl=4;
        maxhwlength=17;
    end
findheatwaves=0; %5 sec; find station & homogenized regional heat waves (still using JFK, LGA, and EWR to define)
    if findheatwaves==1
        mergeadjhws=1;
        eliminateadjhws=1;
        
        variwf=1;variwl=1;
        stniwf=1;stniwl=size(nestns,1);
        yeariwf=1981;yeariwl=2015;relyeariwf=1;relyeariwl=35;
        monthiwf=5;monthiwl=9;relmonthiwf=1;relmonthiwl=5;
        maxhwlength=17;
    end
findhotdaysonly=1; %10 sec; hot days (no heat-wave requirement), computed as the days with the highest daily-avg T
    %averaged across JFK, EWR, and LGA
getdataallhwdays=0; %1 sec; hourly data for all regional heat-wave days for all 23 NE stations
    if getdataallhwdays==1
        variwf=1;variwl=1;
        stniwf=1;stniwl=size(nestns,1);
    end
wbtdailymaxmatrix=0; %1 sec; intimately tied to the previous loop
    
    
%Computation of station-specific hourly-integrated and daily-max percentiles of T, WBT, and q for JJA
    %the latter answers, e.g., 'what is p97.5 of avg daily Tmax for a period of 6 days at JFK?'
%Due to heat-wave definition being used (see DefinitionsNotes), p81
    %and p97.5 are the ones of the most interest, though this lowpct
    %and highpct respectively can be modified as desired
%If a heat wave crosses month lines, thresholds for continuation
    %change as appropriate, weighting by the # of days in each month
%Dimensions of integxxxprctiles are station|month|hw length|prctile
if computeprctiles==1
    for variab=variwf:variwl
        if variab==1
            finaldata=finaldatat;newintegTprctiles=0;newintegTprctilesofdailymax=0;
            newintegTvecsaveforlater={};
        elseif variab==2
            finaldata=finaldatawbt;newintegWBTprctiles=0;newintegWBTprctilesofdailymax=0;
            newintegWBTvecsaveforlater={};
        elseif variab==3
            finaldata=finaldataq;newintegqprctiles=0;newintegqprctilesofdailymax=0;
            newintegqvecsaveforlater={};
        end
        
        for stn=stniwf:stniwl
            fprintf('Current station is %s (ordinate: %d)\n',newstnNumListnames{nestns(stn)},stn);
            for potentialhwlength=1:maxhwlength
                validdayc=0;integvec=0;dailymaxvec=0;
                for month=relmonthiwf:relmonthiwl
                     for year=relyeariwf:relyeariwl
                         for hourinmjjas=1:24:monthhourends(relmonthiwl)-23
                             %Periods have to be entirely within months to contribute to the monthly percentiles
                             if month==1
                                if hourinmjjas+24*potentialhwlength-1<=monthhourends(month)
                                    if min(finaldata{year,nestns(stn)}(hourinmjjas:hourinmjjas+24*potentialhwlength-1))>-50
                                        %Go ahead & calculate stuff for this period 
                                        integvalue=sum(finaldata{year,nestns(stn)}(hourinmjjas:hourinmjjas+24*potentialhwlength-1));
                                        validdayc=validdayc+1;%if integvalue==0;disp(hourinmjjas);end
                                        integvec(validdayc)=integvalue;
                                        %Calculate and add up daily maxes
                                        for day=1:potentialhwlength
                                            thisdaymax(day)=max(finaldata{year,nestns(stn)}...
                                                (hourinmjjas+24*day-24:hourinmjjas+24*day-1));
                                        end
                                        avgdailymax=mean(thisdaymax);
                                        dailymaxvec(validdayc)=avgdailymax;
                                    end
                                end
                             else
                                 if hourinmjjas>=monthhourends(month-1)+1 &&...
                                        hourinmjjas+24*potentialhwlength-1<=monthhourends(month)
                                    if min(finaldata{year,nestns(stn)}(hourinmjjas:hourinmjjas+24*potentialhwlength-1))>-50
                                        %go ahead & calculate
                                        integvalue=sum(finaldata{year,nestns(stn)}(hourinmjjas:hourinmjjas+24*potentialhwlength-1));
                                        validdayc=validdayc+1;%if integvalue==0;disp(hourinmjjas);end
                                        integvec(validdayc)=integvalue;
                                        %Calculate and add up daily maxes
                                        for day=1:potentialhwlength
                                            thisdaymax(day)=max(finaldata{year,nestns(stn)}...
                                                (hourinmjjas+24*day-24:hourinmjjas+24*day-1));
                                        end
                                        avgdailymax=mean(thisdaymax);
                                        dailymaxvec(validdayc)=avgdailymax;
                                    end
                                 end
                             end   
                         end
                     end
                end
                 %validdayc for phl=1 should be something like 1000 (30 days in a month x 35 years)
                 %validdayc for phl=17 should be something like 455 (13 possible 17-day periods in a month x 35 years)
                if variab==1
                    newintegTvecsaveforlater{stn,potentialhwlength}=integvec./(potentialhwlength*24);
                    newintegTprctiles(stn,potentialhwlength,1)=quantile(integvec,highpct)/(potentialhwlength*24);
                    newintegTprctiles(stn,potentialhwlength,2)=quantile(integvec,lowpct)/(potentialhwlength*24);
                    newintegTprctilesofdailymax(stn,potentialhwlength,1)=quantile(dailymaxvec,highpct);
                    newintegTprctilesofdailymax(stn,potentialhwlength,2)=quantile(dailymaxvec,lowpct);
                    if savestuff==1;save(strcat(curDir,'readnortheastdata'),'newintegTvecsaveforlater',...
                        'newintegTprctiles','newintegTprctilesofdailymax','-append');end
                elseif variab==2
                    newintegWBTvecsaveforlater{stn,potentialhwlength}=integvec./(potentialhwlength*24);
                    newintegWBTprctiles(stn,potentialhwlength,1)=quantile(integvec,highpct)/(potentialhwlength*24);
                    newintegWBTprctiles(stn,potentialhwlength,2)=quantile(integvec,lowpct)/(potentialhwlength*24);
                    newintegWBTprctilesofdailymax(stn,potentialhwlength,1)=quantile(dailymaxvec,highpct);
                    newintegWBTprctilesofdailymax(stn,potentialhwlength,2)=quantile(dailymaxvec,lowpct);
                    if savestuff==1;save(strcat(curDir,'readnortheastdata'),'newintegWBTvecsaveforlater',...
                        'newintegWBTprctiles','newintegWBTprctilesofdailymax','-append');end
                elseif variab==3
                    newintegqvecsaveforlater{stn,potentialhwlength}=integvec./(potentialhwlength*24);
                    newintegqprctiles(stn,potentialhwlength,1)=quantile(integvec,highpct)/(potentialhwlength*24);
                    newintegqprctiles(stn,potentialhwlength,2)=quantile(integvec,lowpct)/(potentialhwlength*24);
                    newintegqprctilesofdailymax(stn,potentialhwlength,1)=quantile(dailymaxvec,highpct);
                    newintegqprctilesofdailymax(stn,potentialhwlength,2)=quantile(dailymaxvec,lowpct);
                    if savestuff==1;save(strcat(curDir,'readnortheastdata'),'newintegqvecsaveforlater',...
                        'newintegqprctiles','newintegqprctilesofdailymax','-append');end
                end
            end
        end
    end
end


%Instead of hourlytvecs (as in analyzenycdata), use finaldatat as the basis for defining heat waves
%Examine only heat waves that are of 3-5 days' duration ('shortonly')
%Use hourly integrated percentiles, as before, rather than Tmax as was done in Meehl & Tebaldi 2004
if findheatwaves==1
    hwregister={};hoursofhws={};newhwregisterbyT={};newhwregisterbyWBT={};
    newreghwbyTstarts=0;newreghwbyWBTstarts=0;newhwbyTstarthours=0;newhwbyWBTstarthours=0;
    for variab=variwf:variwl
        numreghws=0;reghwdays=0;reghwstarts=0;hwstarthours=0;
        reghwstartendhours=0;
        if variab==1;finaldata=finaldatat;integXprctiles=newintegTprctiles;end
        if variab==2;finaldata=finaldatawbt;integXprctiles=newintegWBTprctiles;end
        for stn=stniwf:stniwl
            fprintf('Defining heat waves for station %s (ordinate: %d)\n',newstnNumListnames{nestns(stn)},stn);
            %fprintf('maxhwlength: %d\n',maxhwlength);
            numhws=0;consechotdayc=0;
            for year=relyeariwf:relyeariwl
                %fprintf('Current year is %d\n',year);
                i=1;
                while i<=monthhourends(relmonthiwl)-maxhwlength*24
                    %Start by testing a seed of 3 days, in which no missing data is allowed
                    if min(finaldata{year,nestns(stn)}(i:i+71))>-50
                        if i<=monthhourends(1)
                            month=5;dom=round2(i/24,1,'ceil');
                        elseif i<=monthhourends(2)
                            month=6;dom=round2((i-monthhourends(1))/24,1,'ceil');
                        elseif i<=monthhourends(3)
                            month=7;dom=round2((i-monthhourends(2))/24,1,'ceil');
                        elseif i<=monthhourends(4)
                            month=8;dom=round2((i-monthhourends(3))/24,1,'ceil');
                        else
                            month=9;dom=round2((i-monthhourends(4))/24,1,'ceil');
                        end
                        
                        if month>=monthiwf && month<=monthiwl
                            integX=sum(finaldata{year,nestns(stn)}(i:i+71))/72;
                            if integX>=integXprctiles(stn,3,1) %meets the minimum reqts for a heat wave
                                %This first part applies to every heat wave
                                hwlength=3;%fprintf('Starting heat wave # %d\n',numhws+1);
                                hwregister{stn}(numhws+1,1)=DatetoDOY(month,dom,year+yeariwf-1);
                                hoursofhws{stn}(numhws+1,1)=i; %heat wave's already 2 days old
                                %testing if we can take it to the next level
                                integXtest=sum(finaldata{year,nestns(stn)}(i:i+(hwlength+1)*24-1))/((hwlength+1)*24);
                                potentialnewdaysum=sum(finaldata{year,nestns(stn)}(i+(hwlength*24):i+(hwlength+1)*24-1))/24;
                                hwgoeson=1;
                                
                                %Now, see about extending the heat wave beyond 3 days
                                while hwlength<=maxhwlength && hwgoeson==1
                                    newi=i+hwlength*24;
                                    if hwlength<maxhwlength;if newi>monthhourends(month-4);month=month+1;end;end
                                    curmonth=month;
                                    if curmonth==5;dom=round2(newi/24,1,'ceil');else dom=round2((newi-monthhourends(curmonth-5))/24-1,1,'ceil');end
                                    %fprintf('numhws: %d\n',numhws);
                                    %fprintf('hwlength and maxhwlength: %d, %d\n',hwlength,maxhwlength);
                                    %fprintf('integXtest and integXprctiles(hw length): %0.2f, %0.2f\n',integXtest,integXprctiles(stn,hwlength,1));
                                    %fprintf('potentialnewdaysum and integXprctiles(this day): %0.2f, %0.2f\n',...
                                    %    potentialnewdaysum,integXprctiles(stn,1,2));
                                    if hwlength==maxhwlength || curmonth==monthiwl+1 %%%heat wave needs to end%%%
                                        %disp('ending heat wave (date constraint)');
                                        hwgoeson=0;numhws=numhws+1;
                                        hwregister{stn}(numhws,2)=DatetoDOY(curmonth,dom,year);
                                        hwregister{stn}(numhws,3)=year+yeariwf-1;
                                        hoursofhws{stn}(numhws,2)=newi-1;
                                    elseif integXtest>integXprctiles(stn,hwlength,1) && ...
                                            potentialnewdaysum>integXprctiles(stn,1,2) %%%heat wave is extended%%%
                                        %fprintf('extending heat wave; potentialnewdaysum and integXprctiles are %0.2f, %0.2f\n',...
                                        %    potentialnewdaysum,integXprctiles(stn,1,1));
                                        hwlength=hwlength+1;%disp(hwlength);
                                        integXtest=sum(finaldata{year,nestns(stn)}(i:newi+23))/((hwlength)*24);
                                        potentialnewdaysum=sum(finaldata{year,nestns(stn)}(newi:newi+23))/24;
                                        %fprintf('i, newi, hwlength: %d, %d, %d\n',i,newi,hwlength);
                                    else %%%heat wave fizzles out and is no longer extended%%%
                                        %disp('ending heat wave (T/WBT constraint)');
                                        hwgoeson=0;numhws=numhws+1;
                                        hwregister{stn}(numhws,2)=DatetoDOY(curmonth,dom,year);
                                        hwregister{stn}(numhws,3)=year+yeariwf-1;
                                        %hwregister{stn}(numhws,4)=finaldata{year,nestns(stn)}(i+hwlength*24-1);
                                        hoursofhws{stn}(numhws,2)=i+hwlength*24-1;
                                    end
                                end
                                %fprintf('\n');
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
        end
        
        %Merge heat waves that are adjacent (e.g. one is Jul 6-9 and another is Jul 10-12)
        if mergeadjhws==1
            newhwregister={};
            for stn=1:size(nestns,1)
                register=hwregister{stn};
                newregister=register(1,:);newc=1;
                for i=2:size(register,1)
                    newc=newc+1;
                    if register(i,1)==register(i-1,2)+1 && register(i,3)==register(i-1,3)
                        newc=newc-1;
                        newregister(newc,1)=register(i-1,1);
                        newregister(newc,2)=register(i,2);
                        newregister(newc,3)=register(i,3);
                    else
                        newregister(newc,:)=register(i,:);
                    end
                end
                newhwregister{stn}=newregister;
            end

            if variab==1;hwregisterbyT=newhwregister;end
            if variab==2;hwregisterbyWBT=newhwregister;end
        else
            if variab==1;hwregisterbyT=hwregister;end
            if variab==2;hwregisterbyWBT=hwregister;end
        end
        
        
        %Calculate dates for homogenized regional heat waves (i.e. days when
        %2 out of 3 of LGA, JFK, and Newark are experiencing a heat wave)
        c=1;
        hwchere=0;stnthatstartedit=0;stninthemiddle=0;stnthatfinishedit=0;
        for row=1:300;thishwhasbeennoted(row,1)=0;thishwhasbeennoted(row,2)=0;end
        for stn=1:3
            if stn==1;truestn=6;elseif stn==2;truestn=7;else truestn=21;end
            for row=1:size(hwregister{truestn},1)
                %fprintf('row is %d\n',row);
                for potentialreghwday=hwregister{truestn}(row,1):hwregister{truestn}(row,2)
                    %look at days within these heat wave to see if they qualify as regional hot days
                    totalstnshwc=1; %how many stations are experiencing a heat wave on this day
                    potentialreghwyear=hwregister{truestn}(row,3);
                    potentialhwstarthour=hoursofhws{truestn}(row,1);
                    for otherstns=1:3
                        if otherstns~=stn
                            if otherstns==1;trueotherstn=6;elseif otherstns==2;trueotherstn=7;else trueotherstn=21;end
                            for i=1:size(hwregister{trueotherstn},1)
                                otherstartday=hwregister{trueotherstn}(i,1);otherendday=hwregister{trueotherstn}(i,2);
                                otherstarthour=hoursofhws{trueotherstn}(i,1);otherendhour=hoursofhws{trueotherstn}(i,2);
                                year=hwregister{trueotherstn}(i,3);
                                if year==potentialreghwyear
                                    if otherstartday<=potentialreghwday && otherendday>=potentialreghwday
                                        if thishwhasbeennoted(row,1)==0 && thishwhasbeennoted(row,2)==0
                                            hwchere=hwchere+1;
                                            thishwhasbeennoted(row,stn)=1;
                                        end
                                        stnthatstartedit(hwchere)=stn;
                                        if otherstns==4
                                            stnthatfinishedit(hwchere)=4;
                                        elseif otherstns==5 %need to consider both of the other stns in determining the hours of this hw
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
                        disp('regional hw day');
                        %disp(potentialreghwday);disp(potentialreghwyear);
                        reghwdays(c,1)=potentialreghwday;
                        reghwdays(c,2)=potentialreghwyear;
                        reghwstartendhours(c,1)=potentialhwstarthour; %start hour of this heat wave, referenced to hourlytvecs
                        reghwstartendhours(c,2)=potentialhwstarthour+24*(otherendday-otherstartday+1); %end hour
                        c=c+1;
                    end
                end
            end
        end
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
        rowon=1;withinavalidheatwave=0;rowtocreate=1;curhwlength=0;reghwdayscl=zeros(10,2);
        while rowon<=size(reghwdays,1)-2
            if withinavalidheatwave==1
                if rowon>=2
                    currowday=reghwdays(rowon,1);currowyear=reghwdays(rowon,2);
                    prevrowday=reghwdays(rowon-1,1);prevrowyear=reghwdays(rowon-1,2);
                    %Within a heat wave and it goes on, so inch along day by day
                    if currowday==prevrowday+1 && currowyear==prevrowyear
                        reghwdayscl(rowtocreate,:)=reghwdays(rowon,:);
                        rowon=rowon+1;rowtocreate=rowtocreate+1;
                        curhwlength=curhwlength+1;
                    else
                        %Ok that heat wave's over, but are we at the start of another one?
                        currowday=reghwdays(rowon,1);currowyear=reghwdays(rowon,2);
                        nextrowday=reghwdays(rowon+1,1);nextrowyear=reghwdays(rowon+1,2);
                        tworowsdownday=reghwdays(rowon+2,1);tworowsdownyear=reghwdays(rowon+2,2);
                        if tworowsdownyear==currowyear && tworowsdownday==currowday+2
                            withinavalidheatwave=1;
                            reghwdayscl(rowtocreate:rowtocreate+2,:)=reghwdays(rowon:rowon+2,:);
                            rowon=rowon+3;rowtocreate=rowtocreate+3;%rowtocreate2=rowtocreate2+1;
                            curhwlength=3;
                        else
                            %Heat wave is over, get back up and look for the next one
                            withinavalidheatwave=0;
                            rowon=rowon+1;curhwlength=0;
                        end
                    end
                end
            else
                currowday=reghwdays(rowon,1);currowyear=reghwdays(rowon,2);
                nextrowday=reghwdays(rowon+1,1);nextrowyear=reghwdays(rowon+1,2);
                tworowsdownday=reghwdays(rowon+2,1);tworowsdownyear=reghwdays(rowon+2,2);
                if tworowsdownyear==currowyear && tworowsdownday==currowday+2
                    withinavalidheatwave=1;
                    reghwdayscl(rowtocreate:rowtocreate+2,:)=reghwdays(rowon:rowon+2,:);
                    rowon=rowon+3;rowtocreate=rowtocreate+3;
                    curhwlength=3;
                else
                    withinavalidheatwave=0;
                    rowon=rowon+1;curhwlength=0;
                end
            end
        end
        %If necessary (visually):
        %reghwdayscl=reghwdayscl(1:133,:);
        
        
        if eliminateadjhws==1 %eliminate merged heat waves, so we keep the analysis strictly on 3-to-5-day events
            hwlength=1;marktodestroyorsave=zeros(size(reghwdayscl,1),1);
            for i=2:size(reghwdayscl,1)
                if reghwdayscl(i,1)==reghwdayscl(i-1,1)+1 && reghwdayscl(i,2)==reghwdayscl(i-1,2)
                    hwlength=hwlength+1;
                else
                    for j=i-hwlength:i
                        if hwlength>5
                            marktodestroyorsave(j)=1; %destroy
                        else
                            marktodestroyorsave(j)=0; %save
                        end
                    end
                    hwlength=1;
                end
            end
            %marktodestroyorsave(119)=0; %don't know why this row isn't saved automatically, as it should be
            newrow=0;temp=zeros(2,2);
            for row=1:size(reghwdayscl,1)
                if marktodestroyorsave(row)==0
                    newrow=newrow+1;
                    temp(newrow,:)=reghwdayscl(row,:);
                end
            end
            reghwdayscl=temp;
        end
        
        
        if variab==1
            reghwdaysclT=reghwdayscl;
            if savestuff==1;save(strcat(curDir,'readnortheastdata.mat'),'reghwdayscl','reghwdaysclT','nestns',...
                'hwregisterbyT','-append');end
        elseif variab==2
            reghwdaysclWBT=reghwdayscl;
            if savestuff==1;save(strcat(curDir,'readnortheastdata.mat'),'reghwdaysclWBT','hwregisterbyWBT','-append');end
        end
    end
end

%Hottest days, computed as the average of daily-avg T for JFK, EWR, and LGA
if findhotdaysonly==1
    jfkdailyavgt=NaN.*ones(35,366);ewrdailyavgt=NaN.*ones(35,366);lgadailyavgt=NaN.*ones(35,366);
    totaldayc=0;
    for year=1:35
        dayc=0;
        for starthour=5:24:4416-23
            dayc=dayc+1;
            totaldayc=totaldayc+1;
            jfkavgtthisday=mean(finaldatat{year,179}(starthour:starthour+23));
            ewravgtthisday=mean(finaldatat{year,94}(starthour:starthour+23));
            lgaavgtthisday=mean(finaldatat{year,95}(starthour:starthour+23));
            if rem(year,4)==0;apr30doy=121;else apr30doy=120;end
            doy=dayc+apr30doy;
            jfkdailyavgt(totaldayc,1)=jfkavgtthisday;jfkdailyavgt(totaldayc,2)=doy;jfkdailyavgt(totaldayc,3)=year;
            ewrdailyavgt(totaldayc,1)=ewravgtthisday;ewrdailyavgt(totaldayc,2)=doy;ewrdailyavgt(totaldayc,3)=year;
            lgadailyavgt(totaldayc,1)=lgaavgtthisday;lgadailyavgt(totaldayc,2)=doy;lgadailyavgt(totaldayc,3)=year;
            regdailyavgt(totaldayc,1)=(jfkavgtthisday+ewravgtthisday+lgaavgtthisday)./3;
            regdailyavgt(totaldayc,2)=doy;regdailyavgt(totaldayc,3)=year+yeariwf-1;
        end
    end
    %Sort by T
    regdailyavgt(isnan(regdailyavgt))=-Inf; %so NaN's are not erroneously at the top
    regdailyavgt=sortrows(regdailyavgt,-1);
    save(strcat(curDir,'readnortheastdata'),'regdailyavgt','-append');
end

%Get T, WBT, and qdata for all heat-wave days at all 23 stations and combine into several big matrices
if getdataallhwdays==1
    tallhwdays={};wbtallhwdays={};qallhwdays={};
    for variab=variwf:variwl
        if variab==1;reghwdayscl=reghwdaysclT;elseif variab==2;reghwdayscl=reghwdaysclWBT;end
        for stn=stniwf:stniwl
            %Extra offsets for stations whose data is for some reason misaligned with its nominal hours of observation
            if stn==4 || stn==6;extraoffset=9;elseif stn==15;extraoffset=5;else extraoffset=0;end
            hwc=1;daywithinhw=0;hwmonths={};reghwdoys={};
            for row=1:size(reghwdayscl,1)
                if row>1
                    if reghwdayscl(row,1)==reghwdayscl(row-1,1)+1 && reghwdayscl(row,2)==reghwdayscl(row-1,2) %same heat wave is continuing
                        daywithinhw=daywithinhw+1;
                    else
                        hwc=hwc+1;daywithinhw=1; %heat wave just ended
                    end
                else
                    daywithinhw=daywithinhw+1; %same heat wave is continuing, by definition
                end
                
                thisyear=reghwdayscl(row,2);thismon=DOYtoMonth(reghwdayscl(row,1),reghwdayscl(row,2));
                thisday=DOYtoDOM(reghwdayscl(row,1),reghwdayscl(row,2));
                daysap=DaysApart(5,1,thisyear,thismon,thisday,thisyear);
                hwmonths{hwc}(daywithinhw,1)=thismon;
                reghwdoys{hwc}(daywithinhw,1)=reghwdayscl(row,1);reghwdoys{hwc}(daywithinhw,2)=reghwdayscl(row,2);
                tallhwdays{stn,hwc}(daywithinhw,:)=...
                    finaldatat{thisyear-yeariwf+1,nestns(stn)}((daysap+1)*24-23+utclst+extraoffset:(daysap+1)*24+utclst+extraoffset);
                wbtallhwdays{stn,hwc}(daywithinhw,:)=...
                    finaldatawbt{thisyear-yeariwf+1,nestns(stn)}((daysap+1)*24-23+utclst+extraoffset:(daysap+1)*24+utclst+extraoffset);
                qallhwdays{stn,hwc}(daywithinhw,:)=...
                    finaldataq{thisyear-yeariwf+1,nestns(stn)}((daysap+1)*24-23+utclst+extraoffset:(daysap+1)*24+utclst+extraoffset);
                if stn==1
                    %fprintf('year,mon,day are %d, %d, %d\n',thisyear,thismon,thisday);
                    %fprintf('daywithinhw is %d\n',daywithinhw);
                end
            end
        end
    end
end

%WBT daily maxes for central day of each hw (or avg of middle two if it's a 4-day hw)
%dims are 21 stns x 37 hws
if wbtdailymaxmatrix==1
    dailymaxwbtcentralday=0;
     for stn=stniwf:stniwl
         for hw=1:hwc-1
             numdaysthishw=size(wbtallhwdays{stn,hw},1);
             if numdaysthishw==3
                dailymaxwbtcentralday(stn,hw)=max(wbtallhwdays{stn,hw}(2,:));
             elseif numdaysthishw==4
                dailymaxwbtcentralday(stn,hw)=(max(wbtallhwdays{stn,hw}(2,:))+max(wbtallhwdays{stn,hw}(3,:)))/2;
             elseif numdaysthishw==5
                dailymaxwbtcentralday(stn,hw)=max(wbtallhwdays{stn,hw}(3,:));
             end
         end
     end
     
     %Create same matrix but as anomalies relative to each stn & month's averages
     dailymaxwbtcdanom=0;
     for stn=stniwf:stniwl
         for hw=1:hwc-1
             %for row=1:size(wbtallhwdays{stn,hw},1)
                thishwclimotouse=0;
                for row=1:size(wbtallhwdays{stn,hw},1)
                    thishwclimotouse=thishwclimotouse+avgdailymaxthismonth{2}(nestns(stn),hwmonths{hw}(row)-monthiwf+1);
                end
                thishwclimotouse=thishwclimotouse./size(wbtallhwdays{stn,hw},1);
                dailymaxwbtcdanom(stn,hw)=dailymaxwbtcentralday(stn,hw)-thishwclimotouse;
             %end
         end
     end
     
     if savestuff==1;save(strcat(curDir,'readnortheastdata'),'dailymaxwbtcentralday','wbtallhwdaysanom',...
         'dailymaxwbtcdanom','hwmonths','reghwdoys','-append');end
end





