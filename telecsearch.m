%Looks for relationships between NE-US temperatures and teleconnection indices,
%and makes plots & maps of various kinds

%First order of business is to load the text files of the candidate indices
%Each contains monthly values from 01/1950 to 07/2015
nao=load('indicesmonthlynao.txt','r');nao=nao(:,3);
ao=load('indicesmonthlyao.txt','r');ao=ao(:,3);
pna=load('indicesmonthlypna.txt','r');pna=pna(:,3);
enso=load('indicesmonthlyenso.txt','r'); %cols are nino1+2;nino3;nino4;nino3.4,
%where each region's values (unnormalized) are followed by its monthly anomaly
%http://www.esrl.noaa.gov/psd/data/climateindices/list/
    enso=enso(:,10); %using Nino 3.4
nummon=size(pna,1);
startyear=1950;
indiceslist={'NAO';'AO';'PNA';'ENSO'};numindices=size(indiceslist,1);
monlist={'Jun';'Jul';'Aug'};
exist figc;if ans==1;figc=figc+1;else figc=1;end

colorlist={colors('red');colors('light red');colors('light orange');...
    colors('light green');colors('green');colors('blue');
    colors('light purple');colors('pink')};

show90pcthists=0;
showfulldistnhists=0;


%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~%);>~
%Computation and plot creation


%Make composite maps of NARR JJA max temp for each index's positive and
%negative phases
%Each month really needs to be considered on its own, however, 
%as readings can change considerably month-to-month

%1. Create timeseries of self-normalized JJA readings for each index
jjac=1;
for i=1:nummon-7 %through 12/14
    if rem(i,12)==6
        NAOjja(jjac:jjac+2)=nao(i:i+2);
        AOjja(jjac:jjac+2)=ao(i:i+2);
        PNAjja(jjac:jjac+2)=pna(i:i+2);
        ENSOjja(jjac:jjac+2)=enso(i:i+2);
        jjac=jjac+3;
    end
end
NAOjja=NAOjja-mean(NAOjja);AOjja=AOjja-mean(AOjja);
PNAjja=PNAjja-mean(PNAjja);ENSOjja=ENSOjja-mean(ENSOjja);

%2. Values are considered above, near, or below normal relative to the 25th
%and 75th percentiles
vecjjapctiles=zeros(size(NAOjja,2),10);
%first two columns are just year & month
for mon=1:3:size(vecjjapctiles,1)
    vecjjapctiles(mon:mon+2,1)=startyear;
    vecjjapctiles(mon,2)=6;vecjjapctiles(mon+1,2)=7;vecjjapctiles(mon+2,2)=8;
    startyear=startyear+1;
end
%columns 3-10 are NAO & 1/0/-1, same for AO, PNA, and ENSO
for mon=1:size(vecjjapctiles,1)
    for index=1:numindices
        curindex=eval([indiceslist{index} 'jja';]);
        curindexval=eval([indiceslist{index} 'jja(mon)';]);
        vecjjapctiles(mon,index*2+1)=curindexval;
        if curindexval>quantile(curindex,0.75)
            vecjjapctiles(mon,index*2+2)=1;
        elseif curindexval<quantile(curindex,0.25)
            vecjjapctiles(mon,index*2+2)=-1;
        else
            vecjjapctiles(mon,index*2+2)=0;
        end
    end
end


%Prepare to make histograms to compare each station's maxes & mins in + and - index years
%jjattempbyi=cell{numstns,numindices,3,3}; %3 months and 3 categories in cols 3 & 4
jjamaxbyi={};jjaminbyi={};lastind=4;stniwf=1;stniwl=22;
for stnc=stniwf:stniwl
    nsabove6=1;nsnear6=1;nsbelow6=1; %newstart
    nsabove7=1;nsnear7=1;nsbelow7=1;
    nsabove8=1;nsnear8=1;nsbelow8=1;
    for y=1950:2014
        yc=y-1949;
        for mon=6:8
            if mon==6;monlen=30;else monlen=31;end
            sd=eval(sprintf('m%us',mon));ed=eval(sprintf('m%us',mon+1))-1;
            %disp(yc*3+(mon-5)-3);
            for selind=1:lastind
                %NAO+ and no missing days allowed
                if vecjjapctiles(yc*3+mon-5-3,2*selind+2)==1 && cmmaxwy{stnc,y-1864,mon}(1)>0
                    ns=eval(sprintf('nsabove%u',mon));
                    jjamaxbyi{stnc,selind,mon-5,1}(ns:ns+monlen-1)=cmmaxwy{stnc,y-1864,mon}(1:monlen);
                    jjaminbyi{stnc,selind,mon-5,1}(ns:ns+monlen-1)=cmminwy{stnc,y-1864,mon}(1:monlen);
                    %disp(cmmaxwy{stnc,y-1864,mon}(1));disp(ns);
                    %disp(jjaminbyi{stnc,selind,mon-5,1}(ns:ns+monlen-1));
                    if selind==lastind;eval(['nsabove' num2str(mon) '=ns+monlen;']);end
                %NAO neutral
                elseif vecjjapctiles(yc*3+mon-5-3,2*selind+2)==0 && cmmaxwy{stnc,y-1864,mon}(1)>0
                    ns=eval(sprintf('nsnear%u',mon));
                    jjamaxbyi{stnc,selind,mon-5,2}(ns:ns+monlen-1)=cmmaxwy{stnc,y-1864,mon}(1:monlen);
                    jjaminbyi{stnc,selind,mon-5,2}(ns:ns+monlen-1)=cmminwy{stnc,y-1864,mon}(1:monlen);
                    if selind==lastind;eval(['nsnear' num2str(mon) '=ns+monlen;']);end
                %NAO-
                elseif vecjjapctiles(yc*3+mon-5-3,2*selind+2)==-1 && cmmaxwy{stnc,y-1864,mon}(1)>0
                    ns=eval(sprintf('nsbelow%u',mon));
                    jjamaxbyi{stnc,selind,mon-5,3}(ns:ns+monlen-1)=cmmaxwy{stnc,y-1864,mon}(1:monlen);
                    jjaminbyi{stnc,selind,mon-5,3}(ns:ns+monlen-1)=cmminwy{stnc,y-1864,mon}(1:monlen);
                    if selind==lastind;eval(['nsbelow' num2str(mon) '=ns+monlen;']);end
                end
            end
        end
    end
end


%Final parts of analysis, and the creation of histograms and maps
%Creates one figure for every index, each with 2 cities
%Also creates composite maps of station observations broken down by index phase
%Note that the category (max/min/etc) "I want last", as well as the
%selected index, determine what will be outputted in the composite maps
%cat 1 = max, cat 2 = min

%Some quick settings
catiwf=1;catiwl=1;selind=2;
stnsperfig=2;selmon=7;


for selstn=stniwf:stniwl %defined for marquee group only (would need to change above loops for others)
    if show90pcthists==1
        if rem(selstn,stnsperfig)==1
            figure(figc);figc=figc+1;hold on;
            startstn=selstn;endstn=startstn+stnsperfig-1;
        else
            figure(figc-2);
        end
    end
    relstn=selstn-startstn+1;

    if selmon==6;monlen=30;else monlen=31;end
    %Fractional rate of occurrence of 90th-perc max & min
    jjamax1=0;jjamax2=0;jjamax3=0;jjamin1=0;jjamin2=0;jjamin3=0;
    jjamax1=jjamaxbyi{selstn,selind,selmon-5,1}(:);jjamin1=jjaminbyi{selstn,selind,selmon-5,1}(:);
    jjamax2=jjamaxbyi{selstn,selind,selmon-5,2}(:);jjamin2=jjaminbyi{selstn,selind,selmon-5,2}(:);
    jjamax3=jjamaxbyi{selstn,selind,selmon-5,3}(:);jjamin3=jjaminbyi{selstn,selind,selmon-5,3}(:);
    jjamax=[jjamax1;jjamax2;jjamax3];
    pctile90max=quantile(jjamax,0.9);
    jjamin=[jjamin1;jjamin2;jjamin3];
    pctile90min=quantile(jjamin,0.9);

    jmax901=jjamax1>=pctile90max;jmin901=jjamin1>=pctile90min;cx=1;cn=1;
    jjamaxsub1=0;jjaminsub1=0;
    for i=1:size(jjamax1)
        if jmax901(i)==1;jjamaxsub1(cx)=jjamax1(i);cx=cx+1;end
        if jmin901(i)==1;jjaminsub1(cn)=jjamin1(i);cn=cn+1;end
    end
    jmax902=jjamax2>=pctile90max;jmin902=jjamin2>=pctile90min;cx=1;cn=1;
    jjamaxsub2=0;jjaminsub2=0;
    for i=1:size(jjamax2)
        if jmax902(i)==1;jjamaxsub2(cx)=jjamax2(i);cx=cx+1;end
        if jmin902(i)==1;jjaminsub2(cn)=jjamin2(i);cn=cn+1;end
    end
    jmax903=jjamax3>=pctile90max;jmin903=jjamin3>=pctile90min;cx=1;cn=1;
    jjamaxsub3=0;jjaminsub3=0;
    for i=1:size(jjamax3)
        if jmax903(i)==1;jjamaxsub3(cx)=jjamax3(i);cx=cx+1;end
        if jmin903(i)==1;jjaminsub3(cn)=jjamin3(i);cn=cn+1;end
    end
    jjamaxsub=[jjamaxsub1';jjamaxsub2';jjamaxsub3'];
    jjaminsub=[jjaminsub1';jjaminsub2';jjaminsub3'];

    %Histogram of temperatures exceeding the 90th pctile by NAO phase,
    %shown as per number of months with that phase
    variabs={'max';'min'};variabs2={'Days';'Nights'};
    for categ=catiwf:catiwl
        v=variabs{categ};if categ==2;sup=1;else sup=0;end
        pltpos=[relstn*6-5;relstn*6-3;relstn*6-1];%disp(pltpos+sup);
        %figure(figc);figc=figc+1;
        centers=[round2(min([min(eval(['jja' char(v) 'sub1']));min(eval(['jja' char(v) 'sub2']));...
            min(eval(['jja' char(v) 'sub3']))]),2,'floor'):1:...
            round2(max(eval(['jja' char(v) 'sub'])),2,'ceil')];
        if show90pcthists==1
            ax1=subplot_tight(3*stnsperfig,2,pltpos(1)+sup);s1=hist(eval(['jja' char(v) 'sub1']),centers);
            s1=s1./(size(eval(['jja' char(v) '1']),1)/monlen);bar(centers,s1,'BarWidth',1);hold on;
            title(sprintf('%s %s %s >90th Pctile Per Month w/ %s Phase +, 0, -',...
                pr{selstn},monlist{selmon-5},v,indiceslist{selind}),'FontSize',16,'FontWeight','bold');
            ax2=subplot_tight(3*stnsperfig,2,pltpos(2)+sup);s2=hist(eval(['jja' char(v) 'sub2']),centers);
            s2=s2./(size(eval(['jja' char(v) '2']),1)/monlen);bar(centers,s2,'BarWidth',1);
            ax3=subplot_tight(3*stnsperfig,2,pltpos(3)+sup);s3=hist(eval(['jja' char(v) 'sub3']),centers);
            s3=s3./(size(eval(['jja' char(v) '3']),1)/monlen);bar(centers,s3,'BarWidth',1);

            axesHandles=get(gcf,'children');curAxesHandles=axesHandles(1:3);
            xlim([round2(eval(['pctile90' char(v)]),2,'floor') round2(max(eval(['jja' char(v) 'sub'])),...
                2,'ceil')]);
            ylim([0 1.2*max([max(s1);max(s2);max(s3)])]);
            %disp(xlim);disp(ylim);disp(pctile90max);disp(pctile90min);
            set(curAxesHandles,'xlim',xlim);set(curAxesHandles,'ylim',ylim);
        end
    end



    %Make composite maps of station avg max temps for JJA 1950-2014 under NAO+,
    %NAO-,PNA+,etc.
    latlim=[39 42];lonlim=[-76 -72]; %NYC area
    fgtitle=sprintf('Deviations in warm %s %s under %s+',monlist{selmon-5},variabs2{categ},indiceslist{selind});
    
    if show90pcthists==1
        if selstn==stniwf;figciw=figc;end
        fg=figure(figciw);hold on;figc=figc+1;
    else
        fg=figure(figc);
    end
    set(fg,'Color',[1 1 1]);title(fgtitle,'FontSize',16,'FontWeight','bold');
    axesm('mercator','MapLatLimit',latlim,'MapLonLimit',lonlim);axis off;
    framem off;gridm off; mlabel off; plabel off;
    load coast;
    states=shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
             {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
    geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
    tightmap;

    %To start off, focus on JFK warm Jul nights under NAO+
    %without any effect, expectation is of course for a constant 10% chance of 
    %90th pct warm days and nights across all 3 phases of each index... 
    %This part explores whether that's the case, and, more
    %pertinently, how much the deviation from that expectation varies from
    %station to station
    %Use a combination of 80th, 90th, and 95th percentiles to alleviate some of
    %the problems of having the percentile of interest be right in the middle 
    %of a big chunk of data that all has the same value

    markerlist={'v';'o';'s'};
    jqqqxxx=eval(['j' char(variabs{categ}) '901']);
    jjaqqqx=eval(['jja' char(variabs{categ}) '1']);
    jjaqqq=eval(['jja' char(variabs{categ})]);
    
    act1=sum(jqqqxxx); %number of warm Jul nights under NAO+
    exp1=size(jjaqqqx,1)/10; %number of total Jul nights under NAO+, /10
    jqqq801=jjaqqqx>=quantile(jjaqqq,0.8);
    act2=sum(jqqq801);
    exp2=size(jjaqqqx,1)/5;
    jqqq951=jjaqqqx>=quantile(jjaqqq,0.95);
    act3=sum(jqqq951);
    exp3=size(jjaqqqx,1)/20;

    score(selstn)=(act1/exp1+act2/exp2+act3/exp3)/3; %actual/expected for top percentiles
    %disp(score);
    if score(selstn)>1.2
        mark=markerlist{1};color=colors('red');
    elseif score(selstn)<0.8
        mark=markerlist{3};color=colors('blue');
    else
        mark=markerlist{2};color=colors('green');
    end

    pt1lat=stnlocs(selstn,1);pt1lon=stnlocs(selstn,2);
    h=geoshow(pt1lat,pt1lon,'DisplayType','Point','Marker',mark,...
        'MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',11);
    %textm(pt1(1),pt1(2)+0.2,'XXX','FontSize',14,'FontWeight','bold');
end
figc=figc+1;

%July 90th-pct analysis

%under NAO+, most stations have more warm nights, except AtlCity and some western suburbs
%mixed bag, mostly null w.r.t. warm days

%under AO+, a mixture of warm and average nights with little spatial coherence
%null along coast and more warm days inland, particularly pronounced in Trenton and northern NJ

%under PNA+, clear signals at night: more warm nights along the coast near NYC, fewer
%to neutral everywhere else
%generally neutral but fewer warm days in NJ

%under ENSO+, most stations have more warm nights, with the greatest anomalies along the coast
%similar story for days, except that the warmth is pretty evenly distributed






%size(jjatempbyi{1,1,1,1}(:)) %should be something like 400x1
%Normalize, add labels, combine months if possible
%this is for AtlCityA, NAO, June, all 3 categories
%Everything in each of the vectors as subsetted below is a daily value
%recorded during a June with NAO in one particular phase; however, we don't
%know which year it was exactly as all the months are run together

if showfulldistnhists==1
    %Maxes
    figure(figc);figc=figc+1;
    subplot(3,1,1);hist(jjamax1(jjamax1>0));hold on;
    title(sprintf('%s %s Maxes with %s Above, Near, and Below Average',...
        pr{selstn},monlist{selmon-5},indiceslist{selind}),'FontSize',16,'FontWeight','bold');
    subplot(3,1,2);hist(jjamax2(jjamax2>0));
    subplot(3,1,3);hist(jjamax3(jjamax3>0));
    xlim([round2(min(jjamax(jjamax>0)),5,'floor') round2(max(jjamax(jjamax>0)),5,'ceil')]);
    axesHandles=get(gcf,'children');set(axesHandles,'xlim',xlim);
    %Mins
    figure(figc);figc=figc+1;
    subplot(3,1,1);hist(jjamin1(jjamin1>0));hold on;
    title(sprintf('%s %s Mins with %s Above, Near, and Below Average',...
        pr{selstn},monlist{selmon-5},indiceslist{selind}),'FontSize',16,'FontWeight','bold');
    subplot(3,1,2);hist(jjamin2(jjamin2>0));
    subplot(3,1,3);hist(jjamin3(jjamin3>0));
    xlim([round2(min(jjamin(jjamin>0)),5,'floor') round2(max(jjamin(jjamin>0)),5,'ceil')]);
    axesHandles=get(gcf,'children');set(axesHandles,'xlim',xlim);
end




                


   

