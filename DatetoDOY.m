function doy = DatetoDOY(mon,day,year)
%Converts a date to its day of year (number b/w 1 and 366)
    
m1sl=1;m2sl=32;m3sl=61;m4sl=92;m5sl=122;m6sl=153;m7sl=183;m8sl=214;m9sl=245;m10sl=275;m11sl=306;m12sl=336;
m1s=1;m2s=32;m3s=60;m4s=91;m5s=121;m6s=152;m7s=182;m8s=213;m9s=244;m10s=274;m11s=305;m12s=335;

if rem(year,4)==0;suffix=['l'];else suffix=[''];end %have to consider leap years

%Determine the month of this date
if mon==1 %Jan
    doy=day;
elseif mon==2 %Feb
    doy=day+eval(['m2s' suffix])-1;
elseif mon==3 %Mar
    doy=day+eval(['m3s' suffix])-1;
elseif mon==4 %Apr
    doy=day+eval(['m4s' suffix])-1;
elseif mon==5 %May
    doy=day+eval(['m5s' suffix])-1;
elseif mon==6 %Jun
    doy=day+eval(['m6s' suffix])-1;
elseif mon==7 %Jul
    doy=day+eval(['m7s' suffix])-1;
elseif mon==8 %Aug
    doy=day+eval(['m8s' suffix])-1;
elseif mon==9 %Sep
    doy=day+eval(['m9s' suffix])-1;
elseif mon==10 %Oct
    doy=day+eval(['m10s' suffix])-1;
elseif mon==11 %Nov
    doy=day+eval(['m11s' suffix])-1;
elseif mon==12 %Dec
    doy=day+eval(['m12s' suffix])-1;
else
    disp('Please enter a valid month/day combination.');
end


end