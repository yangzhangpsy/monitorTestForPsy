function [eventBins,foundMarkers,epochedData,baselineRange,beplotedX] = monitorTestNew(cntfilename,nframes,ifi)


% argin:
% cntfilename   [string]:  full filename of the cnt file, e,g,. 'C:/test1.cnt'
% nframes       [double]:  defined the number of stim frames 
% ifi           [double]:  monitor inter-refresh interval in msec (e.g., 1000/120 for a refresh rate of 120 Hz)
% Written by Yang Zhang, Soochow Univeristy
% zhangyang873@gmail.com
% if you do think this function is usefull and use it in your research, please cite our paper:
% Zhang GL, Li AS, Miao CG, He X, Zhang M, Zhang Y.(2018) A consumer-grade LCD monitor for precise visual stimulation. Behav Res Methods. 50(4):1496-1502. doi: 10.3758/s13428-018-1018-7.

if ~exist('nframes','var')||isempty(nframes)
	nframes = 4;
end


if ~exist('ifi','var')||isempty(ifi)
	ifi = 1000/120;
end

isBaseLineCorrect = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              begin 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
smoothRangeBins = 8;
thresholdRation = 0.4;

c         = loadcnt_bcl(cntfilename);

triggerCode = [c.event(:).stimtype];

c.event(~ismember(triggerCode,[100]))=[]; % filtered out the no stim triggers


eventBins = [c.event(:).offset];

tempData = c.data(eventBins(1):eventBins(end));

%----- get the polarity of the Data ---------/
if abs(max(tempData(:)))>abs(min(tempData(:)))
	polarity =  1;
else
	polarity = -1;
end
%--------------------------------------------\

data      = c.data*polarity;
stimDur   = round(ifi*nframes*c.header.rate/1000);



[Noused,filenameOnly] = fileparts(cntfilename);


maxData = max(data(:));
threshold       = maxData*thresholdRation;

subThresholdLow = threshold*0.9;
subThresholdUp  = threshold*1.1;

blindWins       = round((nframes - 1)*ifi*c.header.rate/1000) ;


figure;
set(gcf,'Name',filenameOnly);

subplot(3,1,1);
plot(data,'r');

hold on;


bePlotXs = [eventBins;eventBins;nan(size(eventBins))];
bePlotYs = [min(data(:))*ones(size(eventBins));max(data(:))*ones(size(eventBins));nan(size(eventBins))];

line(bePlotXs(:),bePlotYs(:),'Color',[0 0 1]);



markerIdx = data>threshold;
markerIdx3 = data>subThresholdLow;
markerIdx2 = data>subThresholdUp;


startBin = c.event(1).offset - blindWins;
endBin = c.event(end).offset + 1000;



foundMarkers = [];

foundMarkersOff = [];


% for iBin = max(startBin,blindWins+1):endBin
iBin = max(startBin,blindWins+1);

iLoop = 1;

while iBin < endBin 

    isIncreased = false;

	if all(markerIdx(iBin:(smoothRangeBins+iBin-1)))
		foundMarkers = [foundMarkers, iBin];

		iBin = iBin + blindWins; % skipping the blind wins ranges
        
        fprintf('markerOn : %d -->%d\n',foundMarkers(end),iBin);
        
%         isIncreased = true;
        cEndBin = iBin + round(blindWins/2);
        
        while iBin < cEndBin
            if all(markerIdx(iBin - smoothRangeBins:iBin - 1))&&~markerIdx(iBin)
                foundMarkersOff = [foundMarkersOff, iBin];

                iBin = iBin + round(blindWins/2); % skipping the blind wins ranges

                fprintf('markerOff: %d -->%d\n',foundMarkersOff(end),iBin);
                break;
            end
            iBin = iBin +1;
        end
        
        
	end




	if ~isIncreased
		iBin = iBin +1;
	end

	iLoop = iLoop +1;
end 

% while iBin < endBin 
    
%     isIncreased = false;
% %     
% %      if ~mod(iLoop,1000)
% %      	fprintf('%d\n',iBin);
% %      end
% 	if all(~markerIdx2(iBin - smoothRangeBins:iBin - 1))&&markerIdx(iBin)
% 		foundMarkers = [foundMarkers, iBin];

% 		iBin = iBin + blindWins; % skipping the blind wins ranges
        
%         fprintf('markerOn : %d -->%d\n',foundMarkers(end),iBin);
        
%         isIncreased = true;
% 	end

% 	if all(markerIdx3(iBin - smoothRangeBins:iBin - 1))&&~markerIdx(iBin)
% 		foundMarkersOff = [foundMarkersOff, iBin];

% 		iBin = iBin + round(blindWins/2); % skipping the blind wins ranges
        
%         fprintf('markerOff: %d -->%d\n',foundMarkersOff(end),iBin);
%         isIncreased = true;
% 	end

% 	if ~isIncreased
% 		iBin = iBin +1;
% 	end

% 	iLoop = iLoop +1;
% end % while



% end


bePlotXs = [foundMarkers;foundMarkers;nan(size(foundMarkers))];
bePlotYs = [min(data(:))*ones(size(foundMarkers));max(data(:))*ones(size(foundMarkers));nan(size(foundMarkers))];

line(bePlotXs(:),bePlotYs(:),'Color',[0 1 0]);


bePlotXs = [foundMarkersOff;foundMarkersOff;nan(size(foundMarkersOff))];
bePlotYs = [min(data(:))*ones(size(foundMarkersOff));max(data(:))*ones(size(foundMarkersOff));nan(size(foundMarkersOff))];

line(bePlotXs(:),bePlotYs(:),'Color',[0.5 0.5 0.5]);


lh = legend('rawData','trigger','thresholdOn','thresholdOff');
set(lh,'box','off');

xlabel('time bins');

ylabel('voltages (uV)');

xlim([max(eventBins(1) - 1000,1),min(foundMarkersOff(end)+1000,numel(data))]);
hold off;


subplot(3,1,2);

plot([(foundMarkers - eventBins)',(foundMarkersOff - foundMarkers)']);

xlabel('testing nums');
ylabel('deviations (bins)');

lh = legend('threshold on - trigger','threshold off - on');
set(lh,'box','off');

ylim([min(mean(foundMarkers - eventBins),mean(foundMarkersOff - foundMarkers))*0.2,max(mean(foundMarkers - eventBins),mean(foundMarkersOff - foundMarkers))*1.6]);







subplot(3,1,3);

epochedTriggerBins = eventBins - foundMarkers;

beplotedX          = [epochedTriggerBins;epochedTriggerBins;nan(size(epochedTriggerBins))];

beplotedY          = repmat([-5;10;NaN],1,numel(epochedTriggerBins));

plot(beplotedX(:),beplotedY(:));


hold on;

baselineRange = round(stimDur*0.1);

epochedData = zeros(stimDur + baselineRange+1,numel(foundMarkers));


for iEvent = 1:numel(foundMarkers)
	epochedData(:,iEvent) = data((foundMarkers(iEvent)-baselineRange):(foundMarkers(iEvent)+stimDur)  );
end


beplotedX = -baselineRange:stimDur;

if isBaseLineCorrect
    epochedData = epochedData - repmat(mean(epochedData(1:20,:)),size(epochedData,1),1);
end

plot(beplotedX,epochedData);

xlabel('time bins');
ylabel('epoched data (uV)');

ylim([-5,maxData + 5]);
xlim([min(epochedTriggerBins - 5),beplotedX(end)]);



hold off;
