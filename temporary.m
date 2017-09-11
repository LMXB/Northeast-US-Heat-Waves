%temporary script, written the evening of 1/24/17
%select variables copy-and-pasted out of the donarrcompositebydayofhw loop in newanalyses
%Runtime: about 30 sec per day, so 50 min for 100 extreme days
%TO RUN FULLY, SUBSTITUTE IN ADDZERO THROUGHOUT BELOW LOOP
dayposcategc=0;
narrt850arrayanomhwdays={};narrq850arrayanomhwdays={};narrwbt850arrayanomhwdays={};
narrgh500arrayanomhwdays={};narruwnd850arrayanomhwdays={};narrvwnd850arrayanomhwdays={};
oisstarrayanomhwdays={};narrwinddir850arrayavganomhwdays={};narrwindspeed850arrayavganomhwdays={};
for hotday=1:100 %position in a list of NYC hot days
    fprintf('current hot day is %d\n',hotday);
    day=1; %when running with NYC hot days only, this is a meaningless index
    doy=DatetoDOY(nycdailyavgvect(hotday,3),nycdailyavgvect(hotday,4),nycdailyavgvect(hotday,2));
    year=nycdailyavgvect(hotday,2);
    month=nycdailyavgvect(hotday,3);if month<=9;addzero='0';else addzero='';end
    dom=DOYtoDOM(doy,year);
    if rem(year,4)==0;ly=1;else ly=0;end
    if year>=1982 && year<=2014
        fprintf('Current year,month,dom are %d,%d,%d\n',year,month,dom);
        doyminus2=doy-2;monthminus2=DOYtoMonth(doyminus2,year);domminus2=DOYtoDOM(doyminus2,year);
        doyplus2=doy+2;monthplus2=DOYtoMonth(doyplus2,year);domplus2=DOYtoDOM(doyplus2,year);
        doyminus5=doy-5;monthminus5=DOYtoMonth(doyminus5,year);domminus5=DOYtoDOM(doyminus5,year);
        doyminus10=doy-10;monthminus10=DOYtoMonth(doyminus10,year);domminus10=DOYtoDOM(doyminus10,year);
        doyminus20=doy-20;monthminus20=DOYtoMonth(doyminus20,year);domminus20=DOYtoDOM(doyminus20,year);
        doyplus5=doy+5;monthplus5=DOYtoMonth(doyplus5,year);domplus5=DOYtoDOM(doyplus5,year);
        doyplus10=doy+10;monthplus10=DOYtoMonth(doyplus10,year);domplus10=DOYtoDOM(doyplus10,year);
        doyplus20=doy+20;monthplus20=DOYtoMonth(doyplus20,year);domplus20=DOYtoDOM(doyplus20,year);

        %hwif day~=1 && day~=hwlen && month==prevmonth && year==prevyear;needtoreload=0;else needtoreload=1;end
        needtoreload=1;
        if needtoreload==1
            if rem(year,4)==0;ly=1;else ly=0;end
            tfile=load(strcat(narrmatDir,'air/',num2str(year),'/air_',num2str(year),'_0',num2str(month),'_01.mat'));
            tdata=eval(['tfile.air_' num2str(year) '_0' num2str(month) '_01;']);
            tdata=squeeze(tdata{3}(:,:,2,:));clear tfile;
            shumfile=load(strcat(narrmatDir,'shum/',num2str(year),'/shum_',num2str(year),'_0',num2str(month),'_01.mat'));
            shumdata=eval(['shumfile.shum_' num2str(year) '_0' num2str(month) '_01;']);
            shumdata=squeeze(shumdata{3}(:,:,2,:));clear shumfile;
            if monthminus20~=month %have to load arrays for previous month too
                tfile=load(strcat(narrmatDir,'air/',num2str(year),'/air_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                tdataprevmon=eval(['tfile.air_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                tdataprevmon=squeeze(tdataprevmon{3}(:,:,2,:));clear tfile;
                shumfile=load(strcat(narrmatDir,'shum/',num2str(year),'/shum_',num2str(year),'_0',num2str(monthminus20),'_01.mat'));
                shumdataprevmon=eval(['shumfile.shum_' num2str(year) '_0' num2str(monthminus20) '_01;']);
                shumdataprevmon=squeeze(shumdataprevmon{3}(:,:,2,:));clear shumfile;
            end
            if monthplus20~=month %have to load arrays for subsequent month too
                tfile=load(strcat(narrmatDir,'air/',num2str(year),'/air_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                tdatanextmon=eval(['tfile.air_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                tdatanextmon=squeeze(tdatanextmon{3}(:,:,2,:));clear tfile;
                shumfile=load(strcat(narrmatDir,'shum/',num2str(year),'/shum_',num2str(year),'_0',num2str(monthplus20),'_01.mat'));
                shumdatanextmon=eval(['shumfile.shum_' num2str(year) '_0' num2str(monthplus20) '_01;']);
                shumdatanextmon=squeeze(shumdatanextmon{3}(:,:,2,:));clear shumfile;
            end
        end
        dayposcategc=dayposcategc+1;
        
        %20 days before
        if monthminus20~=month
            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{4}(dayposcategc,:,:)=mean(tdatatouse(:,:,domminus20*8-7:domminus20*8),3)-273.15-tclimo850{doyminus20};
        narrq850arrayanomhwdays{4}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domminus20*8-7:domminus20*8),3)-shumclimo850{doyminus20};
        narrwbt850arrayanomhwdays{4}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus20*8-7:domminus20*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domminus20*8-7:domminus20*8),3)),1))-wbtclimo850{doyminus20};
        %10 days before
        if monthminus10~=month
            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{5}(dayposcategc,:,:)=mean(tdatatouse(:,:,domminus10*8-7:domminus10*8),3)-273.15-tclimo850{doyminus10};
        narrq850arrayanomhwdays{5}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domminus10*8-7:domminus10*8),3)-shumclimo850{doyminus10};
        narrwbt850arrayanomhwdays{5}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus10*8-7:domminus10*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domminus10*8-7:domminus10*8),3)),1))-wbtclimo850{doyminus10};
        %5 days before
        if monthminus5~=month
            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{6}(dayposcategc,:,:)=mean(tdatatouse(:,:,domminus5*8-7:domminus5*8),3)-273.15-tclimo850{doyminus5};
        narrq850arrayanomhwdays{6}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domminus5*8-7:domminus5*8),3)-shumclimo850{doyminus5};
        narrwbt850arrayanomhwdays{6}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus5*8-7:domminus5*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domminus5*8-7:domminus5*8),3)),1))-wbtclimo850{doyminus5};
        %2 days before
        if monthminus2~=month
            tdatatouse=tdataprevmon;shumdatatouse=shumdataprevmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{1}(dayposcategc,:,:)=mean(tdatatouse(:,:,domminus2*8-7:domminus2*8),3)-273.15-tclimo850{doyminus2};
        narrq850arrayanomhwdays{1}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domminus2*8-7:domminus2*8),3)-shumclimo850{doyminus2};
        narrwbt850arrayanomhwdays{1}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domminus2*8-7:domminus2*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domminus2*8-7:domminus2*8),3)),1))-wbtclimo850{doyminus2};
        clear tdataprevmon;clear shumdataprevmon;clear ghdataprevmon;clear uwnddataprevmon;clear vwnddataprevmon;
        %Same-day
        tdatatouse=tdata;shumdatatouse=shumdata;
        narrt850arrayanomhwdays{2}(dayposcategc,:,:)=mean(tdatatouse(:,:,dom*8-7:dom*8),3)-273.15-tclimo850{doy};
        narrq850arrayanomhwdays{2}(dayposcategc,:,:)=mean(shumdatatouse(:,:,dom*8-7:dom*8),3)-shumclimo850{doy};
        narrwbt850arrayanomhwdays{2}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,dom*8-7:dom*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,dom*8-7:dom*8),3)),1))-wbtclimo850{doy};
        %2 days after
        if monthplus2~=month
            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{3}(dayposcategc,:,:)=mean(tdatatouse(:,:,domplus2*8-7:domplus2*8),3)-273.15-tclimo850{doyplus2};
        narrq850arrayanomhwdays{3}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domplus2*8-7:domplus2*8),3)-shumclimo850{doyplus2};
        narrwbt850arrayanomhwdays{3}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus2*8-7:domplus2*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domplus2*8-7:domplus2*8),3)),1))-wbtclimo850{doyplus2};
        %5 days after
        if monthplus5~=month
            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{7}(dayposcategc,:,:)=mean(tdatatouse(:,:,domplus5*8-7:domplus5*8),3)-273.15-tclimo850{doyplus5};
        narrq850arrayanomhwdays{7}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domplus5*8-7:domplus5*8),3)-shumclimo850{doyplus5};
        narrwbt850arrayanomhwdays{7}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus5*8-7:domplus5*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domplus5*8-7:domplus5*8),3)),1))-wbtclimo850{doyplus5};
        %10 days after
        if monthplus10~=month
            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{8}(dayposcategc,:,:)=mean(tdatatouse(:,:,domplus10*8-7:domplus10*8),3)-273.15-tclimo850{doyplus10};
        narrq850arrayanomhwdays{8}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domplus10*8-7:domplus10*8),3)-shumclimo850{doyplus10};
        narrwbt850arrayanomhwdays{8}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus10*8-7:domplus10*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domplus10*8-7:domplus10*8),3)),1))-wbtclimo850{doyplus10};
        %20 days after
        if monthplus20~=month
            tdatatouse=tdatanextmon;shumdatatouse=shumdatanextmon;
        else
            tdatatouse=tdata;shumdatatouse=shumdata;
        end
        narrt850arrayanomhwdays{9}(dayposcategc,:,:)=mean(tdatatouse(:,:,domplus20*8-7:domplus20*8),3)-273.15-tclimo850{doyplus20};
        narrq850arrayanomhwdays{9}(dayposcategc,:,:)=mean(shumdatatouse(:,:,domplus20*8-7:domplus20*8),3)-shumclimo850{doyplus20};
        narrwbt850arrayanomhwdays{9}(dayposcategc,:,:)=...
            squeeze(calcwbtfromTandshum(squeeze(mean(tdatatouse(:,:,domplus20*8-7:domplus20*8),3)-273.15),...
            squeeze(mean(shumdatatouse(:,:,domplus20*8-7:domplus20*8),3)),1))-wbtclimo850{doyplus20};
        clear tdatanextmon;clear shumdatanextmon;clear ghdatanextmon;clear uwnddatanextmon;clear vwnddatanextmon;
        fclose('all');
        prevmonth=month;prevyear=year;
    end
    clear dailyanomsstfile;fclose('all');
end
save(strcat(curDir,'newanalyses5'),'narrt850arrayanomhwdays','narrq850arrayanomhwdays','narrwbt850arrayanomhwdays');

