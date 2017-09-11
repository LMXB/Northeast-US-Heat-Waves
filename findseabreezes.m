%Finds sea-breeze times for weather stations, or grid cells in a reanalysis dataset
%(when using reanalysis, interpolate if necessary to get the data for the particular hours required)
%Uses the Borne et al 1998 method to do this
%In brief, this method is:
%1. Get the 700- and 1000-hPa wind fields
%2. Filter out days with large changes in 700-hPa wind speed or dir from the previous day
%3. Filter out days with 700-hPa wind speed >=11 m/s at 13:00 LST
%4. Require that Tland-Tsea>3 C
%5. Require that the surface wind dir change by >30 deg from sunrise+1hr to sunset-5hr
%6. Require that the sharp change in wind dir during the day not be followed by
    %a sharp change immediately thereafter (i.e. the sea breeze persists for a decent amount of time)
    
%Various adjustments made to make the index more suitable for the NE US and not Scandinavia:
%To include more sea breezes with short duration, I reduce the requirements of filter 6
    %to a ratio of 4 and a period of 3 hours (vs 6 and 5 hours in Borne et al)
%Also, since no morning sea breezes are expected, the time range searched in filter 6 is
    %reduced from 6 AM-7 PM LST to 12 PM-7 PM LST
%The primary potentially problematic assumption is that quick local changes in wind are due to
    %a sea breeze and not e.g. katabatic wind
%Thus, I add a 7th condition:
%7. Require that the wind is coming from the general direction of the ocean in that region
    %(within a 120-deg window centered on it)

%Then, I also added an 8th condition:
%8. Require that the wind-dir switch is toward the general sea-breeze direction for that station,
    %rather than away from it -- this is a necessary addition to the 7th condition, so that e.g.
    %a wind switch from 180 to 135 is not classified as a sea breeze where the coast is oriented east-west
    
%And finally, a 9th condition:
%9. Require that the temperature decrease (by any amount) after the quick change in wind direction 

%With all these conditions, it's clear that this algorithm is intended to be relatively conservative

%Current runtime: about 2.5 min per heat wave, 2 hours total

computeseabreezedays=1;
compilestats=1;

curDir='/Users/craymon3/General_Academics/Research/Exploratory_Plots/';
narrDir='/Volumes/MacFormatted4TBExternalDrive/NARR_3-hourly_data_mat/';
dailysstfileloc='/Volumes/MacFormatted4TBExternalDrive/NOAA_OISST_Daily_Data/';

%Useful info for May-Sep
monthhourstarts=[1;745;1465;2209;2953];
monthhourstops=[744;1464;2208;2952;3672];
monthlengthsdays=[31;30;31;31;30];

%Approximate sea-breeze direction (in deg) for each of the 21 NE stations currently being examined
%These stations are listed in the prologue of readnortheastdata

%The direction from which sea/lake breezes are most likely to come, evaluated visually using Google Maps
seabreezedir=[90;120;120;45;45;130;200;170;180;90;90;90;90;315;315;225;20;100;90;270;180];

%Whether the station is close to the coast or not
%(if so, require that the sea breeze kick in by 2 PM LST; if not, require that it kick in by 6 PM LST)
closetocoast=[0;1;0;-1;-1;0;0;1;0;1;-1;-1;-1;-1;1;0;0;0;1;0;1];
    %a judgment as to whether or not a station faces the ocean/lake 'unimpeded'
    %1=yes, 0=no, -1=so far that sea breezes cannot realistically occur

%Load the time series of wind for stations during heat waves only (use reghwbyTstarts)
%For East Coast, UTC-LST offset is 5 hours
%Since interpolation will be done between 3-hour intervals, need to get 'extra' hours on either end
%e.g. if stntz=5, to represent LST midnight we want data for 5 AM and thus need to get 3 AM as well as 6 AM
%NARR reanalysis is used for synoptic conditions at 700 hPa
%If at some future point radiosondes are desired instead, use the database at http://esrl.noaa.gov/raobs/

%Using the old set of data, regional heat-wave days were listed in reghwbyTstarts
%Using the new set, they are listed in reghwdayscl (now consolidated into reghwdoys)
if computeseabreezedays==1
    stntz=5;
    for i=1:size(nestns,1);seabreezedays{i,1}=0;lastfilterpassed{i,1}=0;end
    %for row=1:size(reghwdayscl,1)
    for row=1:37 %row is the heat-wave count
        %if reghwbyTstarts(row,2)>=1982 && reghwbyTstarts(row,2)<=2014 
        if reghwdoys{row}(1,2)>=1982 && reghwdoys{row}(1,2)<=2014
                %add'l slight constriction is imposed by time range of OISST data
            fprintf('Analyzing another heat wave, found at row %d\n',row);
            %thisyear=reghwbyTstarts(row,2);
            thisyear=reghwdoys{row}(1,2);
            if rem(year,4)==0;ly=1;may1doy=122;else ly=0;may1doy=121;end %consider leap years

            %Load NARR wind fields for this heat wave, in chunks if necessary b/c heat wave spans two months
            %hwstartdoy=reghwbyTstarts(row,1);
            hwstartdoy=reghwdoys{row}(1,1);
            prehwstartdoy=hwstartdoy-1; %so we can save data for the day before the hw too
            hwstartmon=DOYtoMonth(hwstartdoy,thisyear);prehwstartmon=DOYtoMonth(prehwstartdoy,thisyear);
            hwstartday=DOYtoDOM(hwstartdoy,thisyear);prehwstartday=DOYtoDOM(prehwstartdoy,thisyear);
            thishwnumdays=size(reghwdoys{row},1);
            %hwenddoy=hwstartdoy+reghwbyTstarts(row,3)-1;
            hwenddoy=hwstartdoy+thishwnumdays-1;
            if stntz>0;posthwenddoy=hwenddoy+1;end
                %stntz>0 means west of Greenwich, thus we need data from
                %the next month (selon UTC) to fill in the end of this month (selon LST)
            hwendmon=DOYtoMonth(hwenddoy,thisyear);
            hwendday=DOYtoDOM(hwenddoy,thisyear); %use hwenddoy here b/c time-zone adjustment is made in loop below
            posthwendmon=DOYtoMonth(posthwenddoy,thisyear);
            posthwendday=DOYtoDOM(posthwenddoy,thisyear);
            fprintf('This heat wave starts on %d/%d and ends on %d/%d, %d\n',hwstartmon,hwstartday,hwendmon,hwendday,thisyear);

            uwndstartmon=load(strcat(narrDir,'uwnd/',num2str(thisyear),'/uwnd_',num2str(thisyear),'_0',num2str(hwstartmon),'_01.mat'));
            uwndstartmon=eval(['uwndstartmon.uwnd_' num2str(thisyear) '_0' num2str(hwstartmon) '_01;']);uwndstartmon=uwndstartmon{3};
            vwndstartmon=load(strcat(narrDir,'vwnd/',num2str(thisyear),'/vwnd_',num2str(thisyear),'_0',num2str(hwstartmon),'_01.mat'));
            vwndstartmon=eval(['vwndstartmon.vwnd_' num2str(thisyear) '_0' num2str(hwstartmon) '_01;']);vwndstartmon=vwndstartmon{3};
            %Load data for adjacent months, if necessary
            %Otherwise, uwndstartmon and vwndstartmon will suffice for the whole heat wave
            if hwstartmon<posthwendmon %need to get data for following month
                uwndendmon=load(strcat(narrDir,'uwnd/',num2str(thisyear),'/uwnd_',num2str(thisyear),'_0',num2str(posthwendmon),'_01.mat'));
                uwndendmon=eval(['uwndendmon.uwnd_' num2str(thisyear) '_0' num2str(posthwendmon) '_01;']);uwndendmon=uwndendmon{3};
                vwndendmon=load(strcat(narrDir,'vwnd/',num2str(thisyear),'/vwnd_',num2str(thisyear),'_0',num2str(posthwendmon),'_01.mat'));
                vwndendmon=eval(['vwndendmon.vwnd_' num2str(thisyear) '_0' num2str(posthwendmon) '_01;']);vwndendmon=vwndendmon{3};
            elseif prehwstartmon<hwstartmon %need to get data for previous month
                uwndprestartmon=load(strcat(narrDir,'uwnd/',num2str(thisyear),'/uwnd_',num2str(thisyear),'_0',num2str(prehwstartmon),'_01.mat'));
                uwndprestartmon=eval(['uwndprestartmon.uwnd_' num2str(thisyear) '_0' num2str(prehwstartmon) '_01;']);uwndprestartmon=uwndprestartmon{3};
                vwndprestartmon=load(strcat(narrDir,'vwnd/',num2str(thisyear),'/vwnd_',num2str(thisyear),'_0',num2str(prehwstartmon),'_01.mat'));
                vwndprestartmon=eval(['vwndprestartmon.vwnd_' num2str(thisyear) '_0' num2str(prehwstartmon) '_01;']);vwndprestartmon=vwndprestartmon{3};
            end
                
            for stn=1:size(nestns,1)
                if closetocoast(stn)==-1 %no sea breeze can realistically occur at this station
                    seabreezedays{stn,row}(daywithinhw)=0;
                else
                    %All data arrays go from the day before the first day of the heat wave, to the day after the last day
                    fprintf('Current station is %d\n',nestns(stn));
                    %tthishw=hourlytvecs{stn}(hwbyTstarthours(row,1):hwbyTstarthours(row,4),5);
                    tthishw=finaldatat{thisyear-yeariwf+1,nestns(stn)}((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+1)*24+stntz);
                    tthishwewr=finaldatat{thisyear-yeariwf+1,94}((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+1)*24+stntz);
                    winddirthishw=finaldatawinddir{thisyear-yeariwf+1,nestns(stn)}...
                        ((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+1)*24+stntz);
                    windspeedthishw=finaldatawindspeed{thisyear-yeariwf+1,nestns(stn)}...
                        ((hwstartdoy-may1doy+1)*24+stntz-23:(hwenddoy-may1doy+1)*24+stntz);

                    temp=wnarrgridpts(newstnNumListlats(nestns(stn)),newstnNumListlons(nestns(stn)),1,0);
                    if hwstartmon<posthwendmon %end of hw goes into the next month
                        uwndthispt1=uwndstartmon(temp(1,1),temp(1,2),3,8*prehwstartday-8+round2(stntz/3,1,'floor'):size(uwndstartmon,4));
                        uwndthispt2=uwndendmon(temp(1,1),temp(1,2),3,1:8*hwendday+round2(stntz/3,1,'ceil'));
                        uwnd700thispt=[squeeze(uwndthispt1);squeeze(uwndthispt2)];
                        vwndthispt1=vwndstartmon(temp(1,1),temp(1,2),3,8*prehwstartday-8+round2(stntz/3,1,'floor'):size(vwndstartmon,4));
                        vwndthispt2=vwndendmon(temp(1,1),temp(1,2),3,1:8*hwendday+round2(stntz/3,1,'ceil'));
                        vwnd700thispt=[squeeze(vwndthispt1);squeeze(vwndthispt2)];
                    elseif prehwstartmon<hwstartmon %day before hw is in previous month
                        uwndthispt1=uwndprestartmon(temp(1,1),temp(1,2),3,8*prehwstartday-8+round2(stntz/3,1,'floor'):size(uwndprestartmon,4));
                        uwndthispt2=uwndstartmon(temp(1,1),temp(1,2),3,1:8*hwendday+round2(stntz/3,1,'ceil'));
                        uwnd700thispt=[squeeze(uwndthispt1);squeeze(uwndthispt2)];
                        vwndthispt1=vwndprestartmon(temp(1,1),temp(1,2),3,8*prehwstartday-8+round2(stntz/3,1,'floor'):size(vwndprestartmon,4));
                        vwndthispt2=vwndstartmon(temp(1,1),temp(1,2),3,1:8*hwendday+round2(stntz/3,1,'ceil'));
                        vwnd700thispt=[squeeze(vwndthispt1);squeeze(vwndthispt2)];
                    else %heat wave is in the middle of a month
                        %Get 700-hPa NARR wind for this point during this heat wave
                        %E.g. for stntz=5, data starts at 3 AM UTC the day before the heat wave starts (10 PM LST 2 days before)
                        %and ends at 6 AM UTC the day after the heat wave ends (1 AM LST the day after the heat wave ends)
                        uwnd700thispt=uwndstartmon(temp(1,1),temp(1,2),3,...
                            8*prehwstartday-8+round2(stntz/3,1,'floor'):8*hwendday+round2(stntz/3,1,'ceil'));
                        vwnd700thispt=vwndstartmon(temp(1,1),temp(1,2),3,...
                            8*prehwstartday-8+round2(stntz/3,1,'floor'):8*hwendday+round2(stntz/3,1,'ceil'));
                        uwnd700thispt=squeeze(uwnd700thispt);vwnd700thispt=squeeze(vwnd700thispt);
                    end

                    %Now, for e.g. a 3-day heat wave, tthishw should have 72 points (3*24), and uwnd700thispt 34 ((3+1)*8+2)


                    %Look for sea-breeze days at this station within this heat wave
                    %Starts at hwstart-1 and ends at hwend
                    %For simplicity, this code is written assuming stntz=5, but could be modified
                    for daywithinhw=1:hwenddoy-prehwstartdoy
                        hwdoy=prehwstartdoy+daywithinhw-1;
                        [winddir700at1300lstprevday,windspeed700at1300lstprevday]=...
                            cart2compass(uwnd700thispt(daywithinhw*8-2),vwnd700thispt(daywithinhw*8-2));
                        [winddir700at0100lstcurday,windspeed700at0100lstcurday]=...
                            cart2compass(uwnd700thispt(daywithinhw*8+2),vwnd700thispt(daywithinhw*8+2));
                        [winddir700at1300lstcurday,windspeed700at1300lstcurday]=...
                            cart2compass(uwnd700thispt(daywithinhw*8+6),vwnd700thispt(daywithinhw*8+6));
                        %Because this is summer, assume local sunrise is at 5 AM LST and local sunset is at 7 PM LST
                        tsfccurday=tthishw(daywithinhw*24-23:daywithinhw*24);
                        winddirsfccurday=winddirthishw(daywithinhw*24-23:daywithinhw*24);
                        winddirsfcat0600lstcurday=winddirthishw(daywithinhw*24-24+8);
                        winddirsfcat1400lstcurday=winddirthishw(daywithinhw*24-24+16);
                        winddirsfcat1800lstcurday=winddirthishw(daywithinhw*24-24+20);
                        if closetocoast(stn)==1
                            winddirsfcafternoon=winddirsfcat1400lstcurday;
                        else
                            winddirsfcafternoon=winddirsfcat1800lstcurday;
                        end
                        %Filter 1
                        if abs(winddir700at1300lstcurday-winddir700at1300lstprevday)<120 %units: degrees
                            %Filter 2
                            if abs(windspeed700at1300lstcurday-windspeed700at0100lstcurday)<8 %units: m/s
                                %disp('passed filter 2');
                                %Filter 3
                                if windspeed700at1300lstcurday<11 %units: m/s
                                    %disp('passed filter 3');
                                    dailymaxtewr=max(tthishwewr(daywithinhw*24-23:daywithinhw*24));
                                    %Filter 4
                                    if hwdoy<=181
                                        dailysstfile=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(thisyear),'0101-',...
                                            num2str(thisyear),'0630.nc'),'tos'); %daily data from Jan 1 to Jun 30
                                        temp=0;
                                    else
                                        dailysstfile=ncread(strcat(dailysstfileloc,'tos_OISST_L4_AVHRR-only-v2_',num2str(thisyear),'0701-',...
                                            num2str(thisyear),'1231.nc'),'tos'); %daily data from Jul 1 to Dec 31
                                        temp=181;
                                    end
                                    thisdayobs=dailysstfile(:,:,hwdoy-temp)-273.15;fclose('all');
                                    thisdayobs=flipud(thisdayobs'); %so array is oriented like a normal world map
                                    %In this array, the latitude ordinate starts at 1 at the North Pole,
                                        %and the longitude ordinate starts at 1 at the Prime Meridian (going east)
                                    %Actually, let's just use the SST off of JFK
                                    if newstnNumListlats(nestns(21))>=0 %NH
                                        %stnlatconvtoord=round(720*(90-newstnNumListlats(nestns(stn)))/180);
                                        stnlatconvtoord=round(720*(90-newstnNumListlats(nestns(21)))/180);
                                    else %SH
                                        stnlatconvtoord=round(720*(90+newstnNumListlats(nestns(21)))/180);
                                    end
                                    if newstnNumListlons(nestns(21))>=0 %EH
                                        stnlonconvtoord=round(1440*(newstnNumListlons(nestns(21)))/360);
                                    else %WH
                                        stnlonconvtoord=round(1440*(360+newstnNumListlons(nestns(21)))/360);
                                    end
                                    %fprintf('stnlatconvtoord, stnlonconvtoord is %d, %d\n',stnlatconvtoord,stnlonconvtoord);
                                    if isnan(thisdayobs(stnlatconvtoord,stnlonconvtoord))
                                        %find closest coastal point in order to get its SST
                                        if ~isnan(thisdayobs(stnlatconvtoord,stnlonconvtoord+1))
                                            stnlonconvtoord=stnlonconvtoord+1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord,stnlonconvtoord-1))
                                            stnlonconvtoord=stnlonconvtoord-1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord+1,stnlonconvtoord))
                                            stnlatconvtoord=stnlatconvtoord+1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord-1,stnlonconvtoord))
                                            stnlatconvtoord=stnlatconvtoord-1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord-1,stnlonconvtoord+1))
                                            stnlatconvtoord=stnlatconvtoord-1;stnlonconvtoord=stnlonconvtoord+1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord-1,stnlonconvtoord-1))
                                            stnlatconvtoord=stnlatconvtoord-1;stnlonconvtoord=stnlonconvtoord-1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord+1,stnlonconvtoord-1))
                                            stnlatconvtoord=stnlatconvtoord+1;stnlonconvtoord=stnlonconvtoord-1;
                                        elseif ~isnan(thisdayobs(stnlatconvtoord+1,stnlonconvtoord+1))
                                            stnlatconvtoord=stnlatconvtoord+1;stnlonconvtoord=stnlonconvtoord+1;
                                        end
                                        %fprintf('stnlatconvtoord, stnlonconvtoord is now %d, %d\n',stnlatconvtoord,stnlonconvtoord);
                                    end

                                    %Finally, apply the filter-4 criterion
                                    if dailymaxtewr>thisdayobs(stnlatconvtoord,stnlonconvtoord) %units: deg C
                                        %disp('passed filter 4');
                                        %Filter 5
                                        winddiff=abs(winddirsfcafternoon-winddirsfcat0600lstcurday); %units: degrees
                                        if winddiff>180;winddiff=360-winddiff;end
                                        if winddiff>30 
                                            %disp('passed filter 5');
                                            %Filter 6
                                            %Find maximum hourly wind-dir difference from 12 PM LST to sunset
                                            maxchange=0;
                                            for hourofday=15:21 %1 PM to 7 PM (looking back, so first window is 12 PM-1 PM)
                                                windchangesfccurhourfromprev=abs(winddirsfccurday(hourofday)-winddirsfccurday(hourofday-1));
                                                if windchangesfccurhourfromprev>180;windchangesfccurhourfromprev=360-windchangesfccurhourfromprev;end
                                                if windchangesfccurhourfromprev>maxchange
                                                    maxchange=windchangesfccurhourfromprev;
                                                    hourofmaxchange=hourofday; %actually, do hourofmaxchange-2 to get true LST
                                                end
                                            end
                                            Ppeak=maxchange;
                                            %Find average hourly change in 3 hours subsequent to max hourly change
                                            hourlychange=0;
                                            for i=1:3
                                                hourlychange(i)=abs(winddirsfccurday(hourofmaxchange+i)-winddirsfccurday(hourofmaxchange+i-1));
                                                if hourlychange(i)>180;hourlychange(i)=360-hourlychange(i);end
                                            end
                                            P3mean=mean(hourlychange);

                                            %if Ppeak/P3mean>4
                                                %disp('passed filter 6');
                                                %Filter 7
                                                %Wind at time of max change must be coming from general sea-breeze direction for this stn
                                                newwinddir=winddirsfccurday(hourofmaxchange);
                                                winddiff=abs(newwinddir-seabreezedir(stn));if winddiff>180;winddiff=360-winddiff;end
                                                if winddiff<=180
                                                    disp('passed filter 7');
                                                    %Filter 8
                                                    winddirbeforeswitch=winddirsfccurday(hourofmaxchange-1);
                                                    winddirafterswitch=winddirsfccurday(hourofmaxchange);
                                                    difffromseabreezedirbefore=abs(winddirbeforeswitch-seabreezedir(stn));
                                                    if difffromseabreezedirbefore>180;difffromseabreezedirbefore=360-difffromseabreezedirbefore;end
                                                    difffromseabreezedirafter=abs(winddirafterswitch-seabreezedir(stn));
                                                    if difffromseabreezedirafter>180;difffromseabreezedirafter=360-difffromseabreezedirafter;end
                                                    if difffromseabreezedirafter<difffromseabreezedirbefore
                                                        disp('passed filter 8');
                                                        fprintf('day within hw is %d\n',daywithinhw);
                                                        %Filter 9
                                                        tbeforeswitch=tsfccurday(hourofmaxchange-1);
                                                        tafterswitch=tsfccurday(hourofmaxchange);
                                                        if tafterswitch-tbeforeswitch<-1 && (Ppeak/P3mean>4 || tafterswitch-tbeforeswitch<-3)
                                                            %filter 6 can be bypassed if the T drop is large enough
                                                            disp('passed filter 9');
                                                            fprintf('day within hw is %d\n',daywithinhw);
                                                            seabreezedays{stn,row}(daywithinhw)=1;
                                                            seabreezedaylist{stn,row}(daywithinhw,1)=hwstartdoy+daywithinhw-1;
                                                            seabreezedaylist{stn,row}(daywithinhw,2)=thisyear;
                                                        else
                                                            seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 9
                                                            lastfilterpassed{stn,row}(daywithinhw)=8;
                                                        end
                                                    else
                                                        seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 8
                                                        lastfilterpassed{stn,row}(daywithinhw)=7;
                                                    end
                                                else
                                                    seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 7
                                                    lastfilterpassed{stn,row}(daywithinhw)=6;
                                                end
                                            %else
                                            %    seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 6
                                            %    lastfilterpassed{stn,row}(daywithinhw)=5;
                                            %end
                                        else
                                            seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 5
                                            lastfilterpassed{stn,row}(daywithinhw)=4;
                                        end
                                    else
                                        seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 4
                                        lastfilterpassed{stn,row}(daywithinhw)=3;
                                    end
                                else
                                    seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 3
                                    lastfilterpassed{stn,row}(daywithinhw)=2;
                                end
                            else
                                seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 2
                                lastfilterpassed{stn,row}(daywithinhw)=1;
                            end
                        else
                            seabreezedays{stn,row}(daywithinhw)=0; %didn't pass filter 1
                            lastfilterpassed{stn,row}(daywithinhw)=0;
                        end     
                    end
                end
            end
        end
    end
    save(strcat(curDir,'seabreezecalc'),'closetocoast','seabreezedays','lastfilterpassed','-append');
end

%For troubleshooting only: list of sea-breeze heat-wave days and non-sea-breeze heat-wave days at JFK
%Sea-breeze days:
%6/12/83, 6/13/83, 7/14/83, 8/7/83
%Non-sea-breeze days:
%7/17-19/82, 6/14-16/83, 7/15-22/83, 8/6/83, 8/8-9/83, 6/20-23/88, 8/16-18/87, 8/13-16/85, 8/14-16/84

%Compile stats
if compilestats==1
    %1. Percent of heat-wave days with sea breezes, by stn
    for stn=1:size(nestns,1)
        totalhwdays(stn)=0;totalsbdays(stn)=0;
        for i=1:row
            totalhwdays(stn)=totalhwdays(stn)+size(seabreezedays{stn,i},2);
            totalsbdays(stn)=totalsbdays(stn)+sum(seabreezedays{stn,i});
        end
        percsbdays(stn)=round(100*totalsbdays(stn)./totalhwdays(stn));
    end
    
    %2. Percent of heat-wave days with sea breezes, by month
end






