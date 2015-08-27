%add options to make subplots
%data is of form [lats;lons;matrix] where each is an identically sized 2D grid

%for example, the input might be:
%data={lats;lons;matrix};
%region='us-ne';
%vararginnew={'contour';1;'mystep';2;'plotCountries';1;'colormap';'jet'};

function [fg, cb] = plotModelData(data, region, vararginnew)

caxisRange = [];
exist figc;
if ans==1;figc=figc+1;else figc=1;end   
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
%disp(region);
%disp(data);
%disp(length(vararginnew));
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
if ~noNewFig
    fg = figure(figc);
    set(fg, 'Color', [1,1,1]);
    axis off;

    title(fgTitle);
    xlabel(fgXaxis);
    ylabel(fgYaxis);
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
    axesm('mercator','MapLatLimit',[23 50],'MapLonLimit',[-128 -63]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'usa-exp')
    axesm('mercator','MapLatLimit',[23 60],'MapLonLimit',[-135 -55]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'africa')
    axesm('mercator','MapLatLimit',[-30 30],'MapLonLimit',[-20 60]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'west-africa')
    axesm('mercator','MapLatLimit',[0 30],'MapLonLimit',[-20 40]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'north-america')
    axesm('mercator','MapLatLimit',[20 75],'MapLonLimit',[-160 -35]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'us-ne')
    axesm('mercator','MapLatLimit',[35 50],'MapLonLimit',[-85 -60]);
    framem off; gridm off; mlabel off; plabel off;
else
    worldmap(region);
    data{1}(:, end+1) = data{1}(:, end) + (data{1}(:, end)-data{1}(:, end-1));
    data{2}(:, end+1) = data{2}(:, end) + (data{2}(:, end)-data{2}(:, end-1));
end

if length(colormapVal) > 0
    colormap(colormapVal);
else
    colormap('jet'); %i.e. the default colormap
end

exist mystep;
if ans==0
    mystep = (max(max(data{3}))-min(min(data{3})))/10;
end
exist caxis_min;
if ans==0
    caxis_min = round2(min(min(data{3})), mystep, 'floor');
end
exist caxis_max;
if ans==0
    caxis_max = round2(max(max(data{3})), mystep, 'ceil');
end
caxisRange=[caxis_min,caxis_max];


if contour
    if mystep ~= -1    
        contourfm(data{1}, data{2}, data{3}, 'LevelStep', mystep);    
    else
        contourfm(data{1}, data{2}, data{3});
    end
    caxis(caxisRange);
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

