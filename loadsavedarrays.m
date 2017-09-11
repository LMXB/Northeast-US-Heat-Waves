%Loads various relevant arrays
%Default is 92.5% heat-wave definition and stationsused=3
%Current runtime: 1 min 15 sec

runremote=0;
if runremote==0
    curDir='/Users/craymon3/General_Academics/Research/Exploratory_Plots/';
elseif runremote==1
    curDir='/cr/cr2630/Exploratory_Plots/';
    addpath('/cr/cr2630/GeneralPurposeScripts/');
end

temp=load(strcat(curDir,'basicstuff.mat'));
stnlocsh=temp.stnlocsh;
hourly90prctiles=temp.hourly90prctiles;
regTvecsavedforlater=temp.regTvecsavedforlater;
narrlats=temp.narrlats;
narrlons=temp.narrlons;
narrsz=temp.narrsz;
ncalist=temp.ncalist;
%integTprctiles=temp.integTprctiles;
%integWBTprctiles=temp.integWBTprctiles;

temp=load(strcat(curDir,'Saved_Variables_etc/analyzenycdatahighpct925su3'));
reghwbyTstarts=temp.reghwbyTstarts;
reghwbyTstartsshortonly=temp.reghwbyTstartsshortonly;
hwbyTstarthours=temp.hwbyTstarthours;
hwbyTstarthoursshortonly=temp;hwbyTstarthoursshortonly;
numreghwsbyT=temp.numreghwsbyT;
Xmatrix=temp.Xmatrix;
idx=temp.idx;
reghwdaysbyT=temp.reghwdaysbyT;
maxhwlength=temp.maxhwlength;
integTprctiles=temp.integTprctiles;
regTprctiles=temp.regTprctiles;

temp=load(strcat(curDir,'Saved_Variables_etc/readnycdata.mat'));
hourlytvecs=temp.hourlytvecs; %data for every hour spanning 1941-2015 for 11 Northeast stations
        %Columns of hourlytvecs are
    %hour|day|month|year|T|dewpt|wdir|wspd|wgust|pres|skycov|RH|heatindex|WBT, with units of
    %                    C   C    deg  kts  kts   hPa eighths %      C     C
    %11 stations are 'acy';'bdr';'jfk';'lga';'ewr';'hpn';'nyc';'ttn';'phl';'teb';'isp'
    
temp=load(strcat(curDir,'Saved_Variables_etc/organizenarrheatwaves.mat'));
plotdays=temp.plotdays;
fullhwdaystoplot=temp.fullhwdaystoplot;
plotalldays=temp.plotalldays;
plotdaysshortonly=temp.plotdaysshortonly;


temp=load(strcat(curDir,'readnortheastdata.mat'));
nestns=temp.nestns;
newintegTvecsaveforlater=temp.newintegTvecsaveforlater;
newintegTprctiles=temp.newintegTprctiles;
newintegTprctilesofdailymax=temp.newintegTprctilesofdailymax;
newintegWBTvecsaveforlater=temp.newintegWBTvecsaveforlater;
newintegWBTprctiles=temp.newintegWBTprctiles;
newintegWBTprctilesofdailymax=temp.newintegWBTprctilesofdailymax;
newintegqvecsaveforlater=temp.newintegqvecsaveforlater;
newintegqprctiles=temp.newintegqprctiles;
newintegqprctilesofdailymax=temp.newintegqprctilesofdailymax;
reghwdayscl=temp.reghwdayscl;
reghwdaysclT=temp.reghwdaysclT;
%hwregisterbyT=temp.hwregisterbyT;
%hwregisterbyWBT=temp.hwregisterbyWBT;
%reghwdaysclWBT=temp.reghwdaysclWBT;
dailymaxwbtcentralday=temp.dailymaxwbtcentralday;
wbtallhwdaysanom=temp.wbtallhwdaysanom;
dailymaxwbtcdanom=temp.dailymaxwbtcdanom;
hwmonths=temp.hwmonths;
reghwdoys=temp.reghwdoys;
regdailyavgt=temp.regdailyavgt;

if runremote==0
    temp=load('/Users/craymon3/General_Academics/Research/WBTT_Overlap_Paper/Saved_Arrays/addendumncdcholder.mat');
elseif runremote==1
    temp=load('/cr/cr2630/WBTT_Overlap_Paper/addendumncdcholder.mat');
    rrh;
end
finaldatawinddir=temp.finaldatawinddir;
finaldatawindspeed=temp.finaldatawindspeed;

temp=load(strcat(curDir,'seabreezecalc.mat'));
closetocoast=temp.closetocoast;
%seabreezedays=temp.seabreezedays;
%lastfilterpassed=temp.lastfilterpassed;

%temp=load(strcat(curDir,'somclusteringZ500only.mat'));
%Z500alldaysfromsomcalc=temp.Z500alldays;

temp=load(strcat(curDir,'somclustering.mat'));
Z500hwdays=temp.Z500hwdays;
totalnumdays=temp.totalnumdays;
monthsofhws=temp.monthsofhws;
%ghclimo500=temp.ghclimo500;
Z500_cycle_smooth=temp.Z500_cycle_smooth;
ind_occur=temp.ind_occur;
num_obs=temp.num_obs;
Z500_anom=temp.Z500_anom;
Z500_anom_hwonly=temp.Z500_anom_hwonly;
sTopol=temp.sTopol;
timeseries=temp.timeseries; %all days
sD=temp.sD;
data_name=temp.data_name;
comp_names=temp.comp_names;
comp_norm=temp.comp_norm;
struct_mode=temp.struct_mode;
sMap=temp.sMap;
bmus=temp.bmus;
qerrs=temp.qerrs;
pats=temp.pats;
pat_freq=temp.pat_freq;

%temp=load(strcat(curDir,'somclusteringAonly.mat'));
%A=temp.A;

temp=load(strcat(curDir,'som_lininitvariables.mat'));
dim=temp.dim;
munits=temp.munits;
sTrain=temp.sTrain;
msize=temp.msize;
mdim=temp.mdim;


temp=load(strcat(curDir,'somclusteringresults.mat'));
nlat=temp.nlat;
nlon=temp.nlon;
datalat=temp.datalat;
datalon=temp.datalon;
num_rows=temp.num_rows;
num_cols=temp.num_cols;
K=temp.K;
Map_som=temp.Map_som;
timeserieshws=temp.timeseries;

temp=load(strcat(curDir,'newanalyses'));
hwregisterbyTshortonly=temp.hwregisterbyTshortonly;
signifsbc=temp.signifsbc;
for i=1:1
    if i==1;s='ewrjfk';elseif i==2;s='phlacy';end
    eval(['coastalstnalltdata' s '=temp.coastalstnalltdata' s ';']);
    eval(['numhours5ormore' s '=temp.numhours5ormore' s ';']);
    eval(['dayswithsbcbydoy' s '=temp.dayswithsbcbydoy' s ';']);
    eval(['hourswithsbcbydoyandhourofday' s '=temp.hourswithsbcbydoyandhourofday' s ';']);
    eval(['inlandstnsstdiffbydoy' s '=temp.inlandstnsstdiffbydoy' s ';']);
    eval(['inlandstnsstdiffbydoyandhourofday' s '=temp.inlandstnsstdiffbydoyandhourofday' s ';']);
    eval(['inlandstntmaxes' s '=temp.inlandstntmaxes' s ';']);
end
thwextendedstdevanom=temp.thwextendedstdevanom;
avgpctssbchourshws=temp.avgpctssbchourshws;
avgpctssbchourshws1d=temp.avgpctssbchourshws1d;
tadvarray=temp.tadvarray;
qadvarray=temp.qadvarray;
wbtcontribtadvarray=temp.wbtcontribtadvarray;
wbtcontribqadvarray=temp.wbtcontribqadvarray;
obstchangearray=temp.obstchangearray;
obsqchangearray=temp.obsqchangearray;
obswbtchangearray=temp.obswbtchangearray;
wbtcontribobstchangearray=temp.wbtcontribobstchangearray;
wbtcontribobsqchangearray=temp.wbtcontribobsqchangearray;
dailysumtadvarray=temp.dailysumtadvarray;
dailysumqadvarray=temp.dailysumqadvarray;
dailysumwbtadvarray=temp.dailysumwbtadvarray;
dailysumwbtcontribtadvarray=temp.dailysumwbtcontribtadvarray;
dailysumwbtcontribqadvarray=temp.dailysumwbtcontribqadvarray;
dailysumobstchangearray=temp.dailysumobstchangearray;
dailysumobsqchangearray=temp.dailysumobsqchangearray;
dailysumobswbtchangearray=temp.dailysumobswbtchangearray;
dailysumwbtcontribobstchangearray=temp.dailysumwbtcontribobstchangearray;
dailysumwbtcontribobsqchangearray=temp.dailysumwbtcontribobsqchangearray;
gh500dailyanomarraysbc=temp.gh500dailyanomarraysbc;
uwnd850dailyanomarraysbc=temp.uwnd850dailyanomarraysbc;
vwnd850dailyanomarraysbc=temp.vwnd850dailyanomarraysbc;
gh500dailyanomarraynonsbc=temp.gh500dailyanomarraynonsbc;
uwnd850dailyanomarraynonsbc=temp.uwnd850dailyanomarraynonsbc;
vwnd850dailyanomarraynonsbc=temp.vwnd850dailyanomarraynonsbc;
gh500anomarraysbc=temp.gh500anomarraysbc;
gh500anomarraynonsbc=temp.gh500anomarraynonsbc;
uwnd850anomarraysbc=temp.uwnd850anomarraysbc;
uwnd850anomarraynonsbc=temp.uwnd850anomarraynonsbc;
vwnd850anomarraysbc=temp.vwnd850anomarraysbc;
vwnd850anomarraynonsbc=temp.vwnd850anomarraynonsbc;
uwnd300anomarraysbc=temp.uwnd300anomarraysbc;
uwnd300anomarraynonsbc=temp.uwnd300anomarraynonsbc;
vwnd300anomarraysbc=temp.vwnd300anomarraysbc;
vwnd300anomarraynonsbc=temp.vwnd300anomarraynonsbc;
narrwbtanomcomposite=temp.narrwbtanomcomposite;
narrtanomcomposite=temp.narrtanomcomposite;
narrshumanomcomposite=temp.narrshumanomcomposite;
avgsstanomhws=temp.avgsstanomhws;
avgsststananomhws=temp.avgsststananomhws;
avgsstanomhwsmayjun=temp.avgsstanomhwsmayjun;
avgsststananomhwsmayjun=temp.avgsststananomhwsmayjun;
avgsstanomhwsaugsep=temp.avgsstanomhwsaugsep;
avgsststananomhwsaugsep=temp.avgsststananomhwsaugsep;
winddirbygridpt=temp.winddirbygridpt;
windspeedbygridpt=temp.windspeedbygridpt;
curdaybygridpt=temp.curdaybygridpt;

temp=load(strcat(curDir,'newanalyses2'));
tdatathisday=temp.tdatathisday;
shumdatathisday=temp.shumdatathisday;
wbtdatathisday=temp.wbtdatathisday;
wbtanomthisday=temp.wbtanomthisday;
wbtanomhwdays=temp.wbtanomhwdays;
myavg=temp.myavg;
myvals=temp.myvals;
Z500alldays=temp.Z500alldays;
anomz500thisday=temp.anomz500thisday;
anomz500thisdaybyreg=temp.anomz500thisdaybyreg;

temp=load(strcat(curDir,'newanalyses3'));
narrt850arrayavganomhwdays=temp.narrt850arrayavganomhwdays;
narrq850arrayavganomhwdays=temp.narrq850arrayavganomhwdays;
narrwbt850arrayavganomhwdays=temp.narrwbt850arrayavganomhwdays;
narrgh500arrayavganomhwdays=temp.narrgh500arrayavganomhwdays;
narruwnd850arrayavganomhwdays=temp.narruwnd850arrayavganomhwdays;
narrvwnd850arrayavganomhwdays=temp.narrvwnd850arrayavganomhwdays;
oisstarrayavganomhwdays=temp.oisstarrayavganomhwdays;
nycdailyavgvect=temp.nycdailyavgvect;
nycdailyavgvecwbt=temp.nycdailyavgvecwbt;
nycdailyavgvecq=temp.nycdailyavgvecq;

temp=load(strcat(curDir,'newanalyses4'));
yearlyavgnearcoastsst=temp.yearlyavgnearcoastsst;
weeklysstdata=temp.weeklysstdata;
yearlyavgnycwbt=temp.yearlyavgnycwbt;
yearlycounthotwbtdays=temp.yearlycounthotwbtdays;
yearlycounthottdays=temp.yearlycounthottdays;

temp=load('computenarrclimo'); %THESE ARE AVERAGES BY DAY OF THE YEAR, SO THE FIRST 119 CELLS ARE EMPTY
tclimo1000=temp.tclimo1000;tclimo850=temp.tclimo850;
tclimo700=temp.tclimo700;tclimo500=temp.tclimo500;tclimo300=temp.tclimo300;
shumclimo1000=temp.shumclimo1000;shumclimo850=temp.shumclimo850;
shumclimo700=temp.shumclimo700;shumclimo500=temp.shumclimo500;shumclimo300=temp.shumclimo300;
uwndclimo1000=temp.uwndclimo1000;uwndclimo850=temp.uwndclimo850;
uwndclimo700=temp.uwndclimo700;uwndclimo500=temp.uwndclimo500;uwndclimo300=temp.uwndclimo300;
vwndclimo1000=temp.vwndclimo1000;vwndclimo850=temp.vwndclimo850;
vwndclimo700=temp.vwndclimo700;vwndclimo500=temp.vwndclimo500;vwndclimo300=temp.vwndclimo300;
ghclimo1000=temp.ghclimo1000;ghclimo850=temp.ghclimo850;
ghclimo700=temp.ghclimo700;ghclimo500=temp.ghclimo500;ghclimo300=temp.ghclimo300;
wbtclimo1000=temp.wbtclimo1000;wbtclimo850=temp.wbtclimo850;
wbtclimo700=temp.wbtclimo700;wbtclimo500=temp.wbtclimo500;wbtclimo300=temp.wbtclimo300;
tclimoterrainsfc=temp.tclimoterrainsfc;
shumclimoterrainsfc=temp.shumclimoterrainsfc;
uwndclimoterrainsfc=temp.uwndclimoterrainsfc;
vwndclimoterrainsfc=temp.vwndclimoterrainsfc;
wbtclimoterrainsfc=temp.wbtclimoterrainsfc;



