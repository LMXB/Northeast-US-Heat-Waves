%A flexible plotting script that can handle multiple types of data,
%regions, and special specifications


%data argument is of form [lats;lons;matrix] where each is an identically sized 2D grid
%277x349 for NARR, 144x73 for NCEP
%or, for wind, [lats;lons;uwndmatrix;vwndmatrix]

%for example, the input might be:
%data={lats;lons;matrix};region='us-ne';
%vararginnew={'variable';'temperature';'contour';1;'mystep';2;'plotCountries';1;...
%'colormap';'jet';'caxismethod';'regional10';'overlaynow';0};
%vararginnew={'variable';'wet-bulb temp';'contour';0;'plotCountries';1;...
%'colormap';'jet';'caxismin';0.1;'caxismax';0.5;'overlaynow';0};

%for a temperature field overlaid with wind barbs:
%vararginnew={'variable';'wind';'contour';1;'plotCountries';1;...
%'caxismethod';'regional10';'vectorData';data;'overlaynow';1;...
%'overlayvariable';'temperature';'datatooverlay';overlaydata};
%where data is of form {lats;lons;uwndmatrix;vwndmatrix}

%If caxismethod='regionalxx', then mystep is overwritten to match this
%regional formulation, even if mystep was explicitly specified in the function call

function [caxisRange,mystep,mycolormap]=plotModelData(data,region,vararginnew,datatype)

caxisRange=[];
exist figc;if ans==1;figc=figc+1;else figc=1;end   
contour=false;
cb=0;fg=0;
lsmask=ncread('land.nc','land')';

fgTitle='';fgXaxis='';fgYaxis='';
noNewFig = false;
colormapVal = '';
vectorData = {};
varlistnames={'2-m Temp.';'Wet-Bulb Temp.';'Geopot. Height';'Wind'};

if strcmp(datatype,'NARR') || strcmp(datatype,'NCEP')
else
    disp('Please enter a valid data type.');
    return;
end
    

fprintf('Region chosen is: %s\n',region);
disp('Variable arguments chosen are listed below:');
disp(vararginnew);
if mod(length(vararginnew),2)~=0
    disp('Error: must have an even # of arguments.');
else
    for count=1:2:length(vararginnew)-1
        key=vararginnew{count};
        val=vararginnew{count+1};
        switch key
            case 'variable'
                vartype=val; %'wind', 'temperature', 'height', or 'wet-bulb temp'
            case 'contour'
                contour=val;
            case 'plotCountries'
                plotcountries=val;
            case 'mystep'
                mystep=val;
            case 'caxismin'
                caxis_min=val;
            case 'caxismax'
                caxis_max=val;
            case 'caxismethod'
                caxis_method=val; %'regional10', 'regional25', or 'global' (last is default)
            case 'figc'
                figc=val;
            case 'title'
                fgTitle=val;
            case 'xaxis'
                fgXaxis=val;
            case 'yaxis'
                fgYaxis=val;
            case 'nonewfig'
                noNewFig=val;
            case 'colormap'
                colormapVal=val;
            case 'vectorData'
                vectorData=val;
            case 'overlaynow'
                overlaynow=val;
            case 'overlayvariable'
                overlayvartype=val; %will be plotted as contours or barbs
            case 'overlayvariable2'
                overlayvartype2=val; %wind, so will be plotted as barbs
            case 'underlayvariable'
                underlayvartype=val; %will be plotted as colors
            case 'datatooverlay'
                overlaydata=val;
            case 'datatooverlay2'
                overlaydata2=val;
            case 'datatounderlay'
                underlaydata=val;
        end
    end
end

fgHandles = findobj('Type','figure');
if length(fgHandles)>0
    figc=max(fgHandles)+1;
end
if noNewFig~=1
    fg=figure(figc);clf;
    set(fg,'Color',[1,1,1]);
    axis off;
    title(fgTitle);xlabel(fgXaxis);ylabel(fgYaxis);
else
    fg=figure(figc);clf;set(fg,'Color',[1,1,1]);hold on;
end

%Use eqdazim projection for data that go up to the pole
if strcmp(region, 'world')
    worldmap world;mapproj='robinson';
    underlaydata{1}(:, end+1) = underlaydata{1}(:, end) + (underlaydata{1}(:, end)-underlaydata{1}(:, end-1));
    underlaydata{2}(:, end+1) = underlaydata{2}(:, end) + (underlaydata{2}(:, end)-underlaydata{2}(:, end-1));
    underlaydata{3}(:, end+1) = underlaydata{3}(:, end) + (underlaydata{3}(:, end)-underlaydata{3}(:, end-1)); 
    mlabel off; plabel off;
elseif strcmp(region, 'usa')
    southlat=25;northlat=50;westlon=-126;eastlon=-64;mapproj='lambert';
elseif strcmp(region, 'usa-exp')
    southlat=23;northlat=60;westlon=-135;eastlon=-55;mapproj='lambert';
elseif strcmp(region, 'north-america')
    southlat=20;northlat=80;westlon=-170;eastlon=-35;mapproj='lambert';
elseif strcmp(region, 'us-ne')
    southlat=35;northlat=50;westlon=-85;eastlon=-60;mapproj='mercator';
elseif strcmp(region, 'na-east')
    southlat=25;northlat=55;westlon=-100;eastlon=-50;mapproj='lambert'; 
elseif strcmp(region, 'nyc-area')
    southlat=39;northlat=42;westlon=-76;eastlon=-72;mapproj='mercator';
else
    worldmap(region);
    underlaydata{1}(:, end+1) = underlaydata{1}(:, end) + (underlaydata{1}(:, end)-underlaydata{1}(:, end-1));
    underlaydata{2}(:, end+1) = underlaydata{2}(:, end) + (underlaydata{2}(:, end)-underlaydata{2}(:, end-1));
end

%Convert lat/lon corners to NARR gridpts
if strcmp(datatype,'NARR')
    temp1=wnarrgridpts(northlat,eastlon,1);
    temp2=wnarrgridpts(southlat,westlon,1);
elseif strcmp(datatype,'NCEP')
    if eastlon<0;eastlon=eastlon+360;end
    if westlon<0;westlon=westlon+360;end
    temp1=wncepgridpts(northlat,eastlon,1);
    temp2=wncepgridpts(southlat,westlon,1);
end
northindex=temp1(1,1);eastindex=temp1(1,2); 
southindex=temp2(1,1);westindex=temp2(1,2);
%disp(northindex);disp(southindex);disp(eastindex);disp(westindex);

axesm(mapproj,'MapLatLimit',[southlat northlat],'MapLonLimit',[westlon eastlon]);
framem on;gridm off;mlabel off;plabel off;axis on;axis off;

if length(colormapVal)>0;colormap(colormapVal);else colormap('jet');end
mycolormap=colormap;

%Mfcr is the matrix to be plotted in color-filled contours, i.e.
%either the only thing, or the underlay
%exist vartype;
%if ans==1
    %if strcmp(underlayvartype,'temperature')
        %if overlaynow==1
exist underlaydata;
if ans==0
    underlaydata=data;
    exist vartype;
    if ans==1;underlayvartype=vartype;end
end
mfcr=underlaydata{3};
exist underlayvartype;
if ans==1
    if strcmp(underlayvartype,'wet-bulb temp') || strcmp(underlayvartype,'temperature')
        dispunits='deg C';
    elseif strcmp(underlayvartype,'height')
        dispunits='m';
    elseif strcmp(underlayvartype,'wind')
        dispunits='m/s';
    end
else
    dispunits=''; %unknown
end

exist mystep;
%Default is 10 steps
if ans==0;mystep=(max(max(mfcr))-min(min(mfcr)))/10;end

%Determine the color range, either by specification in the function call or by default here
exist caxis_min;
if ans==0
    exist caxis_method;
    if ans==0 %default is to determine range globally
        caxis_min=round2(min(min(mfcr)),mystep,'floor');
    elseif strcmp(caxis_method,'regional10')
        mystep=(max(max(mfcr(southindex:northindex,westindex:eastindex)))-...
            min(min(mfcr(southindex:northindex,westindex:eastindex))))/10;
        caxis_min=round2(min(min(mfcr(southindex:northindex,westindex:eastindex))), mystep, 'floor');
        disp('Note: Step size has been overwritten to match the regional nature of the color axis.');
    elseif strcmp(caxis_method,'regional25')
        mystep=(max(max(mfcr(southindex:northindex,westindex:eastindex)))-...
            min(min(mfcr(southindex:northindex,westindex:eastindex))))/25;
        caxis_min=round2(min(min(mfcr(southindex:northindex,westindex:eastindex))), mystep, 'floor');
        disp('Note: Step size has been overwritten to match the regional nature of the color axis.');
    else
        caxis_min=round2(min(min(mfcr)),mystep,'floor');
    end
end
exist caxis_max;
if ans==0
    exist caxis_method;
    if ans==0 %default is to determine range globally
        caxis_max=round2(max(max(mfcr)), mystep, 'ceil');
    elseif strcmp(caxis_method,'regional10')
        caxis_max=round2(max(max(mfcr(southindex:northindex,westindex:eastindex))),mystep,'ceil');
        mystep=(max(max(mfcr(southindex:northindex,westindex:eastindex)))-...
            min(min(mfcr(southindex:northindex,westindex:eastindex))))/10;
    elseif strcmp(caxis_method,'regional25')
        caxis_max=round2(max(max(mfcr(southindex:northindex,westindex:eastindex))),mystep,'ceil');
        mystep=(max(max(mfcr(southindex:northindex,westindex:eastindex)))-...
            min(min(mfcr(southindex:northindex,westindex:eastindex))))/25;
    else
        caxis_max=round2(max(max(mfcr)), mystep, 'ceil');
    end
end
caxisRange=[caxis_min,caxis_max];
caxis(caxisRange);%disp(caxisRange);

%Display the underlaid (or only) data, contoured or not
if contour
    contourm(underlaydata{1},underlaydata{2},mfcr,'LevelStep',mystep,'Fill','on','LineColor','k');
else
    pcolorm(underlaydata{1},underlaydata{2},mfcr);hold on;
end

skiprest=0;
if skiprest==0
load coast;framem on;

%states=shaperead('usastatelo','UseGeoCoords',true,'Selector', ...
%         {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})),'Name'});
states=shaperead('usastatelo','UseGeoCoords',true);
geoshow(states,'DisplayType','polygon','DefaultFaceColor','none');

if plotcountries
    borders('Canada','k'); %in most cases, Canada is the only other country in the domain of interest
    if strcmp(region,'north-america')
        borders('Mexico','k');borders('Cuba','k');borders('Bahamas','k');
        borders('Denmark','k');borders('Haiti','k');borders('Dominican Republic','k');
    elseif strcmp(region,'na-east') || strcmp(region,'usa-exp') || strcmp(region,'usa')
        borders('Mexico','k');borders('Cuba','k');borders('Bahamas','k');
    end
    tightmap;
end

if ~noNewFig;cb=colorbar('Location','southoutside');end

xlim([-0.5 0.5]);
if strcmp(region,'us-ne')
    zoom(2.5);ylim([0.6 1.0]);
end

%Need to repeat some steps so that parts of the map are not accidentally overwritten
skiphere=0;
if skiphere==0
 
    
%%%Prepare settings for displaying wind vectors%%%

%Calculate factors based on map size by which to multiply wind-vector sizes so that
%they are visually accurate no matter what the map size is
%Tweak maparea as needed (for each region separately) to empirically make the vectors look right
    %to make arrows smaller (larger), divide maparea by a number > (<) 1
    %to make arrows more (less) dense, reduce (increase) skipstep
    %don't change q as it affects both the length and the density
maparea=(northlat-southlat)*(eastlon-westlon);
if strcmp(region, 'north-america')
    q=4;refval=9;skipstep=2; %only plot every qth vector, also skipping selon skipstep; reference value is in m/s
    maparea=maparea/2; %to fool quivermc into making the arrows smaller
elseif strcmp(region, 'usa-exp')
    q=4;refval=6;skipstep=2;
    maparea=maparea/2;
elseif strcmp(region, 'us-ne')
    q=2;refval=3;skipstep=2;
    maparea=maparea/2;
elseif strcmp(region, 'nyc-area')
    q=1;refval=3;skipstep=1;
    maparea=maparea/2;
end
    
if length(vectorData)~=0
    %Only plot every qth vector so it's not a mess of arrows -- quivermc
    %seems to take care of this automatically however
    quivermc(vectorData{1}(1:q:end,1:q:end),vectorData{2}(1:q:end,1:q:end),...
        vectorData{3}(1:q:end,1:q:end),vectorData{4}(1:q:end,1:q:end),...
        'reference',refval,'maparea',maparea,'skipstep',skipstep);
end
end

geoshow(states,'DisplayType','polygon','DefaultFaceColor','none');

if overlaynow==1
    [C,h]=contourm(overlaydata{1},overlaydata{2},overlaydata{3},'LineWidth',2,'LineColor','k');
    if strcmp(region, 'us-ne') || strcmp(region, 'nyc-area')
        labelspacing=800;
    elseif strcmp(region, 'north-america')
        labelspacing=300;
    else
        labelspacing=500;
    end
    t=clabelm(C,h,'LabelSpacing',labelspacing);
    set(t,'FontSize',15,'FontWeight','bold');
    hold on;
    
    exist overlayvartype2;
    if ans~=0
        contourm(overlaydata2{1},overlaydata2{2},overlaydata2{3},'LineWidth',2,'LineColor','k');
    end
    

    if strcmp(underlayvartype,'height')
        underlaydatanum=3;phr=sprintf('Shading: %s in m',varlistnames{underlaydatanum});
    elseif strcmp(underlayvartype,'temperature')
        underlaydatanum=1;phr=sprintf('Shading: %s in deg C',varlistnames{underlaydatanum});
    %elseif strcmp(underlayvartype,'wind') %script not equipped to deal with underlaid wind yet
    %    phr=sprintf('Shading: %s in m/s',varlistnames{underlaydatanum});
    elseif strcmp(underlayvartype,'wet-bulb temp')
        underlaydatanum=2;phr=sprintf('Shading: %s in deg C',varlistnames{underlaydatanum});
    end
    uicontrol('Style','text','String',phr,'Units','normalized',...
        'Position',[0.4 0.06 0.2 0.05],'BackgroundColor','w');
    
    if strcmp(overlayvartype,'height')
        overlaydatanum=3;phrcont=sprintf('Contours: %s in m',varlistnames{overlaydatanum});
    elseif strcmp(overlayvartype,'temperature')
        overlaydatanum=1;phrcont=sprintf('Contours: %s in deg C',varlistnames{overlaydatanum});
    elseif strcmp(overlayvartype,'wind')
        overlaydatanum=4;phrcont=sprintf('Contours: %s in m/s',varlistnames{overlaydatanum});
    elseif strcmp(overlayvartype,'wet-bulb temp')
        overlaydatanum=2;phrcont=sprintf('Contours: %s in deg C',varlistnames{overlaydatanum});
    end
    uicontrol('Style','text','String',phrcont,'Units','normalized',...
        'Position',[0.4 0.02 0.2 0.05],'BackgroundColor','w');
end

%Phrases to display in the caption
if contour
    exist vartype;
    if ans==1
        if overlaynow==1 %mystep corresponds to underlaid variable
            if strcmp(underlayvartype,'height')
                phr=sprintf('(Shading interval: %0.0f %s)',mystep,dispunits);
            elseif strcmp(underlayvartype,'temperature') || strcmp(underlayvartype,'wind') ||...
                   strcmp(underlayvartype,'wet-bulb temp') 
                phr=sprintf('(Shading interval: %0.1f %s)',mystep,dispunits);
            end
        else %mystep corresponds to overlaid variable
            if strcmp(vartype,'height')
                phr=sprintf('(Contour interval: %0.0f %s)',mystep,dispunits);
            elseif strcmp(vartype,'temperature') || strcmp(vartype,'wind') ||...
                   strcmp(vartype,'wet-bulb temp') 
                phr=sprintf('(Contour interval: %0.1f %s)',mystep,dispunits);
            end
        end
    else
        phr=sprintf('(Contour interval: %0.2f)',mystep);
    end
    uicontrol('Style','text','String',phr,'Units','normalized',...
        'Position',[0.4 0.04 0.2 0.05],'BackgroundColor','w');
    if overlaynow==1
        uicontrol('Style','text','String',phrcont,'Units','normalized',...
                'Position',[0.4 0.02 0.2 0.05],'BackgroundColor','w');
    end
end

%Second overlaid variable could show up under either of these names
exist overlayvartype2;
if ans~=0 && overlaynow~=0
    if strcmp(overlayvartype2,'wind');phr='Barbs: Wind in m/s';end
    uicontrol('Style','text','String',phr,'Units','normalized',...
        'Position',[0.4 0.00 0.2 0.05],'BackgroundColor','w');
end
exist vectorData;
if ans~=0 && overlaynow~=0
    phr='Barbs: Wind in m/s';
    uicontrol('Style','text','String',phr,'Units','normalized',...
        'Position',[0.4 0.00 0.2 0.05],'BackgroundColor','w');
end

%Repeat so it's not accidentally overwritten
%if length(vectorData)~=0
%    quivermc(vectorData{1}(1:q:end,1:q:end),vectorData{2}(1:q:end,1:q:end),...
%        vectorData{3}(1:q:end,1:q:end),vectorData{4}(1:q:end,1:q:end),...
%        'reference',refval,'maparea',maparea,'skipstep',skipstep);
%end

%geoshow(states,'DisplayType','polygon','DefaultFaceColor','none');
%if plotcountries;geoshow(countries,'DisplayType','polygon','DefaultFaceColor','none');end
tightmap;

end
end

