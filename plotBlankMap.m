function [caxisRange,mystep,mycolormap] = plotBlankMap(figct,region)

fg=figure(figct);
fgTitle = '';fgXaxis = '';fgYaxis = '';
plotCountries = false;
%fprintf('Region chosen is: %s\n',region);

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

set(fg,'Color',[1 1 1]);
axesm('mercator','MapLatLimit',[southlat northlat],'MapLonLimit',[westlon eastlon]);
framem on; gridm off; mlabel off; plabel off;
axis on;axis off; %this is not crazy, it somehow gets the frame lines to be all the same width

load coast;
states=shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
         {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
if plotCountries
    countries=shaperead('countries', 'UseGeoCoords', true);
    geoshow(countries, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
    tightmap;
end

%xlim([-0.5 0.5]);
if strcmp(region,'us-ne')
    zoom(2.5);
    ylim([0.6 1.0]);
end
tightmap;
    
end