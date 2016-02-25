%Plot gridpoints and stations to show where everything is, all on the same
%figure (should be a committee-pleaser)
%Don't much care about NARR gridpoints over water as I can't use these to
%compute anything interesting, or to compare with observational data, or to
%evaluate adaptation strategies

%Turn off output display in wnarrgridpts so this doesn't dump out huge
%numbers of unnecessary updates

%Current runtime: about 3 min

plotBlankMap(figc,'nyc-area');figc=figc+1;

%NARR gridpts first
mycolor=colors('red');
for latinregion=39:0.25:42
    for loninregion=-76:0.25:-72
        res=wnarrgridpts(latinregion,loninregion);
        if res(1,1)~=0 && res(1,2)~=0 %i.e. at least 1 land point was found
            closestlat=lats(res(1,1),res(1,2));
            closestlon=lons(res(1,1),res(1,2));
            h=geoshow(closestlat,closestlon,'DisplayType','Point','Marker','s',...
                        'MarkerFaceColor',mycolor,'MarkerEdgeColor',mycolor,'MarkerSize',5);
        end
        hold on;
    end
end

%CLIMOD stations
mycolor=colors('blue');
for row=1:size(stnlocs,1)
    plotlat=stnlocs(row,1);
    plotlon=stnlocs(row,2);
    h=geoshow(plotlat,plotlon,'DisplayType','Point','Marker','v',...
                        'MarkerFaceColor',mycolor,'MarkerEdgeColor',mycolor,'MarkerSize',8);
    hold on;
end

%If a CLIMOD station is also a MesoWest station (i.e. an NWS ASOS station),
%show a larger marker instead
%CLIMOD stations
mycolor=colors('green');
for row=1:size(mwstnlocs,1)
    plotlat=mwstnlocs(row,1);
    plotlon=mwstnlocs(row,2);
    h=geoshow(plotlat,plotlon,'DisplayType','Point','Marker','v',...
                        'MarkerFaceColor',mycolor,'MarkerEdgeColor',mycolor,'MarkerSize',13);
    hold on;
end

title('NYC-Area First- and Second-Order Stations, with NARR Gridpoints','FontSize',16,'FontWeight','bold');
