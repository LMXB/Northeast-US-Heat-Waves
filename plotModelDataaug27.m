%add options to make subplots
%data is of form [lats;lons;matrix] where each is an identically sized 2D grid

%for example, the input might be:
%data={lats;lons;matrix};
%region='us-ne';
%vararginnew={'contour';1;'mystep';2;'plotCountries';1;'colormap';'jet'};

%If caxismethod='regional', then mystep is overwritten to match this
%regional formulation, even if explicitly specified in the function call

function [fg, cb] = plotModelData(data, region, vararginnew)

caxisRange = [];
exist figc;if ans==1;figc=figc+1;else figc=1;end   
contour = false;
cb = 0;
fg = 0;

fgTitle = '';
fgXaxis = '';
fgYaxis = '';
noNewFig = false;
colormapVal = '';
vectorData = {};
plotCountries = false;

fprintf('Region chosen is: %s\n',region);
disp('Variable arguments chosen are listed below:');
disp(vararginnew);
if mod(length(vararginnew),2)~=0
    disp('Error: must have an even # of arguments.');
else
    for count=1:2:length(vararginnew)-1
        key = vararginnew{count};
        val = vararginnew{count+1};
        switch key
            case 'contour'
                contour = val;
            case 'mystep'
                mystep = val;
            case 'caxismin'
                caxis_min=val;
            case 'caxismax'
                caxis_max=val;
            case 'caxismethod'
                caxis_method=val; %'regional' or 'global' (latter is default)
            case 'figc'
                figc = val;
            case 'title'
                fgTitle = val;
            case 'xaxis'
                fgXaxis = val;
            case 'yaxis'
                fgYaxis = val;
            case 'nonewfig'
                noNewFig = val;
            case 'colormap'
                colormapVal = val;
            case 'vectorData'
                vectorData = val;
            case 'countries'
                plotCountries = val;
        end
    end
end

fgHandles = findobj('Type','figure');
if length(fgHandles) > 0
    figc = max(fgHandles)+1;
end
if noNewFig~=1
    fg = figure(figc);clf;
    set(fg, 'Color', [1,1,1]);
    axis off;
    title(fgTitle);xlabel(fgXaxis);ylabel(fgYaxis);
else
    hold on;
end

if strcmp(region, 'world')
    worldmap world;
    data{1}(:, end+1) = data{1}(:, end) + (data{1}(:, end)-data{1}(:, end-1));
    data{2}(:, end+1) = data{2}(:, end) + (data{2}(:, end)-data{2}(:, end-1));
    data{3}(:, end+1) = data{3}(:, end) + (data{3}(:, end)-data{3}(:, end-1)); 
    mlabel off; plabel off;
elseif strcmp(region, 'north atlantic')
    worldmap([25 75], [-75 10]);
elseif strcmp(region, 'usa')
    southlat=23;northlat=50;westlon=-128;eastlon=-63;
elseif strcmp(region, 'usa-exp')
    southlat=23;northlat=60;westlon=-135;eastlon=-55;
elseif strcmp(region, 'africa')
    southlat=-30;northlat=30;westlon=-20;eastlon=60;
elseif strcmp(region, 'west-africa')
    southlat=0;northlat=30;westlon=-20;eastlon=40;
elseif strcmp(region, 'north-america')
    southlat=20;northlat=75;westlon=-160;eastlon=-35;
elseif strcmp(region, 'us-ne')
    southlat=35;northlat=50;westlon=-85;eastlon=-60;
elseif strcmp(region, 'na-east')
    southlat=25;northlat=55;westlon=-100;eastlon=-50;
elseif strcmp(region, 'nyc-area')
    southlat=39;northlat=42;westlon=-76;eastlon=-72;
else
    worldmap(region);
    data{1}(:, end+1) = data{1}(:, end) + (data{1}(:, end)-data{1}(:, end-1));
    data{2}(:, end+1) = data{2}(:, end) + (data{2}(:, end)-data{2}(:, end-1));
end

axesm('mercator','MapLatLimit',[southlat northlat],'MapLonLimit',[westlon eastlon]);
framem off; gridm off; mlabel off; plabel off;
%Assumes sw point is always over land... would need to be adjusted otherwise
a=wnarrgridpts(southlat,westlon);
southindex=a(1,1);westindex=a(1,2);
b=wnarrgridpts(northlat,eastlon);
northindex=b(1,1);eastindex=b(1,2);

if length(colormapVal) > 0
    colormap(colormapVal);
else
    colormap('jet'); %i.e. the default colormap
end

exist mystep;
if ans==0
    mystep = (max(max(data{3}))-min(min(data{3})))/10;
end
%Determine the color range, either by specification in the function call or
%by default here
exist caxis_min;
if ans==0
    exist caxis_method;
    if ans==0 %default is to determine range globally
        caxis_min=round2(min(min(data{3})), mystep, 'floor');
    elseif strcmp(caxis_method,'regional')
        caxis_min=round2(min(min(data{3}(southindex:northindex,westindex:eastindex))), mystep, 'floor');
        mystep = (max(max(data{3}(southindex:northindex,westindex:eastindex)))-...
            min(min(data{3}(southindex:northindex,westindex:eastindex))))/10;
        disp('Note: Step size has been overwritten to match the regional nature of the color axis.');
    else
        caxis_min = round2(min(min(data{3})), mystep, 'floor');
    end
end
exist caxis_max;
if ans==0
    exist caxis_method;
    if ans==0 %default is to determine range globally
        caxis_max=round2(max(max(data{3})), mystep, 'ceil');
    elseif strcmp(caxis_method,'regional')
        caxis_max=round2(max(max(data{3}(southindex:northindex,westindex:eastindex))), mystep, 'ceil');
        mystep = (max(max(data{3}(southindex:northindex,westindex:eastindex)))-...
            min(min(data{3}(southindex:northindex,westindex:eastindex))))/10;
    else
        caxis_max = round2(max(max(data{3})), mystep, 'ceil');
    end
end
caxisRange=[caxis_min,caxis_max];


if contour
    if mystep ~= -1    
        contourfm(data{1}, data{2}, data{3}, 'LevelStep', mystep);    
    else
        contourfm(data{1}, data{2}, data{3});
    end
    caxis(caxisRange);
    phr=sprintf('Contour interval: %0.3f',mystep);
    uicontrol('Style','text','String',phr,'Units','normalized',...
        'Position',[0.4 0.05 0.2 0.05],'BackgroundColor','w');
else
    pcolorm(data{1}, data{2}, data{3});
    caxis(caxisRange);
end

if length(vectorData) ~= 0
    quiverm(vectorData{1}, vectorData{2}, vectorData{3}, vectorData{4}, 'k');
end

load coast;
plotm(lat, long, 'Color', [0 0 0], 'LineWidth', 2);

states = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
         {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');

if plotCountries
    countries = shaperead('countries', 'UseGeoCoords', true);
    geoshow(countries, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
    tightmap;
end

if ~noNewFig
    cb = colorbar('Location', 'southoutside');
end

xlim([-0.5 0.5]);
if strcmp(region,'us-ne')
    zoom(2.5);
    ylim([0.6 1.0]);
end
tightmap;
    
end

