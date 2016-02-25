function [cgridpts] = wnarrgridpts(deslat,deslon,oceanok)
%Four closest gridpts to a given lat/lon (the four corners of a square), 
%   with weights on each based on Cartesian distance, calculated for 277x349 NARR
%   reanalyses
%Ocean option dictates whether or not ocean points are OK

cgridpts=zeros(4,3); %columns are lat & lon of point, and then its fractional weight

deslatrad=deslat*pi/180;
closest10=1000*ones(10,5);mindists=1000*ones(10,1);

%Use soil moisture for lats/lons
temp=load('-mat','soilm_narr_01_01');
%Land-sea mask
lsmask=ncread('land.nc','land')';

soilm_narr_01_01=temp(1).soilm_0000_01_01;
lats=soilm_narr_01_01{1}; %277x349, as are all NARR arrays
lons=soilm_narr_01_01{2}; %ditto
narrgriddimx=size(lats,1);
narrgriddimy=size(lons,2);

%Computation loop
%fprintf('Computing NARR gridpoints closest to %0.2f, %0.2f\n',deslat,deslon);
for i=1:narrgriddimx
    for j=1:narrgriddimy
        thislat=lats(i,j);
        thislon=lons(i,j);
        dist=sqrt(abs(((thislat-deslat)*111)^2)+...
            abs(((thislon-deslon)*111*cos(deslatrad))^2));
        mindists=sort(mindists);
        if dist<mindists(10)
            mindists(10)=dist;
            closest10(10,1)=thislat;
            closest10(10,2)=thislon;
            closest10(10,3)=i;
            closest10(10,4)=j;
            closest10(10,5)=dist;
            closest10=sortrows(closest10,5);
        end
    end
end
%disp(closest10);

if oceanok==0
    i=1;endthis=0;cgrc=0;nopfinc=0;nopf=0; %numoceanptsfound
    oldlatloc=0;oldlonloc=0;
    while i-nopf<=4 && endthis==0
        if endthis==0
            if lsmask(closest10(i+nopf,3),closest10(i+nopf,4))==0 %let this loop through until the next land pt
                nopf=nopf+1;nopfinc=1;
                latloc=lats(closest10(i+nopf,3),closest10(i+nopf,4));
                lonloc=lons(closest10(i+nopf,3),closest10(i+nopf,4));
                fprintf('Ocean pt found at %0.2f, %0.2f\n',latloc,lonloc);
                if i+nopf==10 %can't find 4 land pts among 10 closest
                    %disp('Still have not found four land pts... Reconsider your choices');
                    lsmask(closest10(i+nopf,3),closest10(i+nopf,4))=0;
                end
            else
                exist latloc;if ans==1;oldlatloc=latloc;end
                ans1=ans;
                exist lonloc;if ans==1;oldlonloc=lonloc;end
                ans2=ans;
                latloc=lats(closest10(i+nopf,3),closest10(i+nopf,4));
                lonloc=lons(closest10(i+nopf,3),closest10(i+nopf,4));
                if ans1==0 && ans2==0 || oldlatloc~=latloc && oldlonloc~=lonloc
                    %disp(sprintf('Land point found at %0.2f, %0.2f',latloc,lonloc));
                end
                nopfinc=0;cgrc=cgrc+1;
            end
        end
        if i+nopf<=10 && nopf~=9 && nopfinc==0
            cgridpts(cgrc,1)=closest10(i+nopf,3);cgridpts(cgrc,2)=closest10(i+nopf,4);
            cgridpts(cgrc,3)=sum(closest10(1:4,5))/closest10(i+nopf,5);
            i=i+1;
        end
        if cgrc==4 %happily found 4 pts
            endthis=1;
        elseif i+nopf==10 %couldn't find 4 land pts
            endthis=1;disp(sprintf('Could not find four land pts. Using just %d land pts among the top 10\n',cgrc));
        end
        %disp('End this');disp(endthis);disp('i');disp(i);disp('i+nopf');disp(i+nopf);
    end
    %disp(closest10);
else
    cgridpts(:,1)=closest10(1:4,3);
    cgridpts(:,2)=closest10(1:4,4);
    for i=1:4
        cgridpts(i,3)=sum(closest10(1:4,5))/closest10(i,5);
    end
end
summ=sum(cgridpts(1:4,3));
cgridpts(1,3)=cgridpts(1,3)/summ;
cgridpts(2,3)=cgridpts(2,3)/summ;
cgridpts(3,3)=cgridpts(3,3)/summ;
cgridpts(4,3)=cgridpts(4,3)/summ;

cgridpts=cgridpts(1:4,:);

end

