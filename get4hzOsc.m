function [osctimesup]=get4hzOsc(stvm)
%Identify candidates for 3-5Hz Vm Oscillations.
%stvm is the subthreshold portion of the Vm (no spikes)
%finds potential oscillations by looking for hyperpolarized segments
%hyperpolarizations are found by looking at the zscore over a window of the
%recording. Thresholds are set for duration and zscore magnitude.

%osctimesup is a two column matrix with the start and stop times in samples

%When assigning oscillation times manually, first click where the oscillation begins, and
%then click where the oscillation ends. Then, press enter twice. If the
%oscillation is not in the full view, press enter while the mouse is in the
%plot window, then enter one of the following codes followed by enter:
%   '4' - move the frame back 1 seconds
%   '6' - move the frame forward 1 seconds
%   '5' - zoom out by 1 seconds
%   '1' - go back to the prior candidate
%   '9' - quit identifying candidates

samplerate = 12414; %set your SR here.
dfactor = 4; 
dstvm = downsample(stvm,dfactor);
SR = samplerate/dfactor; 

%set up a filter for identifying candidates
filtsize = .2*SR;
fcoeff = ones(1,round(filtsize))/filtsize;
fdelay = ((length(fcoeff)-1)/2);
%set threshold settings
winsize = 20*SR; %set the window size
zthresh = -1; %here is the magnitude threshold
ztimethresh = .25*SR; %here is the time threshold
winsize = 20*SR; %set the window size
candidates=[];

%find the candidates
for win = 1:length(dstvm)/winsize
    w0 = (win-1)*winsize+1;
    w1 = win*winsize;
    %get filtered zscore
    winz = zscore(dstvm(w0:w1));
    fwinz = filter(fcoeff,1,winz);
    %find out when the zscore is less than zthresh
    lowscore = fwinz;
    lowscore(lowscore>zthresh) = 0;
    lowscore(lowscore<=zthresh) = 1;
    d = diff(lowscore);
    %find out how long each period is below zthresh
    start = find(d==1)-fdelay;
    stop = find(d==-1)-fdelay;
    if length(start)>length(stop)
        start(length(start)) = [];
    end
    if isempty(start) || isempty(stop)
        continue
    end
    len = stop - start;
    %apply the duration threshold
    len = find(len>=ztimethresh);
    %asign periods greater than ztimethresh to candidates
    for i = 1:length(len)
        candidates = [candidates; w0+start(len(i)) w0+stop(len(i))];
    end
end

%look at each candidate and manually assign if and where osc is
osctimes = [];
fbuff = -6000;
ebuff = 6000;
i=1;
while i <= length(candidates)
    temp = dstvm(candidates(i,1)+fbuff:candidates(i,2)+ebuff);
    figure(1)
    plot(temp)
    %ginput enables matlab to collect mouse clicks on the plot
    [inx,~] = ginput(2);
    %if two points have been selected, add them to the storage array
    if length(inx)==2
        inx = inx + (candidates(i,1)+fbuff);
        osctimes = [osctimes; inx(1) inx(2)];
    end
    in = input('press enter or code: ');
    %if extra actions are necessary, add to this conditional
    if in==1
        i = i-1;
    elseif in ==5
        fbuff = fbuff-3000;
        ebuff = ebuff+3000;
    elseif in ==4
        fbuff = fbuff-3000;
        ebuff = ebuff-3000;
    elseif in ==6
        fbuff = fbuff+3000;
        ebuff = ebuff+3000;
    elseif in ==9
        i = length(candidates)+1;
    else
        i= i+1;
        fbuff = -6000;
        ebuff = 6000;
    end
    disp([num2str(i) '/' num2str(length(candidates))])
end

%correct times for downsampling
osctimesup = osctimes*dfactor;


