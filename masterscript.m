%Master script that allows other scripts to be run with multiple different options at the click of a button
%If using this, be sure to comment out clustdes assignment in readnarrdata3hourly
loopstodo=[1;1];

if loopstodo(1)==1
    for clustdes=131:134
        readnarrdata3hourly;
    end
end
if loopstodo(2)==1
    for clustdes=141:144
        readnarrdata3hourly;
    end
end