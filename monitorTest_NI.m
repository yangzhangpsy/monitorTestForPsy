function [NIData] = monitorTest_NI(targetRect,targetColor,loopNum,bkColor)

% argin:
% 
% 	targetRect     [1*4 double]: a rect that defining the target rect. default: rect size of 200 around the screen center
% 	targetColor    [1*3 double]: the color of the target circle. default: [255 255 255]
% 	loopNum        [1*3 double]: the number of loops             default: [100]
% 	bkColor        [1*3 double]: the color of the background     default: [0 0 0]
% 
% argout:
% 
% NIData            [a struct with three fields]
%       .data       [double]: measured voltages
%       .timeStamps [double]: measure time stamps
%       .onsetTimes [n*loopNum double]: onset times of the flip
% 
% Written by Yang Zhang Tue May 22 20:08:12 2018
% Soochow University, China
% if you do think this function is usefull and use it in your research, please cite our paper:
% Zhang GL, Li AS, Miao CG, He X, Zhang M, Zhang Y.(2018) A consumer-grade LCD monitor for precise visual stimulation. Behav Res Methods. 50(4):1496-1502. doi: 10.3758/s13428-018-1018-7.

if ~exist('targetRect','var')||isempty(targetRect)
    targetRect = [0 0 200 200];
end 

if ~exist('targetColor','var')||isempty(targetColor)
    targetColor = [255,255,255];
end 

if ~exist('loopNum','var')||isempty(loopNum)
    loopNum = 100;
end 

if ~exist('bkColor','var')||isempty(bkColor)
    bkColor = [0,0,0];
end 





instrColor     = [255,255,255] - bkColor; % set the instr color to full contrast of the bkColor

framesPerCycle = 4; % 1 for white circle and 3 for black bk
fs             = 10000;

beforeStimDur  = 0.5;

try
    %=============== over all parameters ==========================/
    screens                       = Screen('Screens');
    screenNum                     = max(screens);
    [screenSize(1),screenSize(2)] = Screen('WindowSize',screenNum);

    if isempty(targetPos)
        targetPos = screenSize/2;
    end 

     targetRect  = CenterRectOnPointd(targetRect,targetPos(1),targetPos(2));
    
    
    % Reinitialize the global random number stream using a seed based on the current time.
    RandStream.setGlobalStream(RandStream('mt19937ar','Seed','shuffle'));
    monitorTest_NI.startTime = datestr(now,'yyyy-mm-dd HH:MM:SS');

    %----- setup keys for kbCheck ---/
    KbName('UnifyKeyNames');

    escapeKey = KbName('ESCAPE');
    enterKey  = KbName('Return');
    enterKey  = enterKey(1);
    
    spaceKey  = KbName('space');

    allActivedKeys = unique([enterKey,escapeKey,spaceKey]);

    RestrictKeysForKbCheck(allActivedKeys);
    %--------------------------------\
    
    %%%%%%%%%%%%%%%%%%%% do PTB jobs %%%%%%%%%%%%%%%%
    AssertOpenGL;
    
    commandwindow;
    [w, fullRect]  = Screen('OpenWindow',screenNum,bkColor);% multisample was set to 4
    Screen('BlendFunction',w,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    Screen('Preference', 'TextAntiAliasing', 1);
    
    % --- give ptb maxmium priority ---/
    Priority(MaxPriority(w));
    %----------------------------------\
    HideCursor;
    
    ifi = Screen('GetFlipInterval',w);
    

    acquireTimeInSec = loopNum*ifi*framesPerCycle + beforeStimDur + 0.1;

    %--- initializing NI Device--/
    s                   =daq.createSession('ni');
    s.Rate              = fs;
    s.DurationInSeconds = acquireTimeInSec;
    
	ch       = addAnalogInputChannel(s,'Dev1', 'ai0', 'Voltage');
	ch.Range = [-1,1]; % set a measurement range of -1 to 1 voltages 
	                   % (our phosphor's output range is about +-0.38 voltages)
	listh    = s.addlistener('DataAvailable', @getACData);
    %----------------------------\

    %----- setting font ----/
    Screen('TextSize',w,28);
    Screen('TextStyle',w,1);% 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
    Screen('TextMode',w,'TextStroke');
    %----------------------\

    % frist frame: instruction %
    Screen('FillRect',w, bkColor); % clean the screen to bkcolor
    Screen('FillArc',w,[255 255 255],targetRect,0,360);
    Screen('DrawLine',w,[0 0 0],targetRect(1),targetRect(2),targetRect(3),targetRect(4),2);
    Screen('DrawLine',w,[0 0 0],targetRect(1),targetRect(4),targetRect(3),targetRect(2),2);
    DrawFormattedText(w,'Put the photophsor on the cross\n When you are ready, press "ANY" key to start..','center',targetRect(4)+60,[255 255 255]);
    Screen('Flip',w);
    
    KbPressWait(-1);
    
    %------- loop 50 times: ---/
    % disp a white circle for 1 frame followed by a black bk for 3 frames

    onsetTimes = zeros(loopNum,2);

    Priority(MaxPriority(w));

    Screen('FillRect',w, bkColor); % clean the screen to bkcolor
    beforeStatTime = Screen('Flip',w);

    % start offline acquisiation,costing time usually less than 0.5 second
    startBackground(s);

    %--- warm up the GPU ?-----/ about 1/12 second 
    for i=1:10 
	    Screen('FillRect',w, bkColor); % clean the screen to bkcolor
	    Screen('Flip',w);
    end 
    %--------------------------\

    for iLoop = 1:loopNum
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The first frame: black bk for 3 ifi
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect',w, bkColor);
        Screen('FillArc',w,targetColor,targetRect,0,360);
        abortExpCheck(escapeKey);

        if iLoop ==1
            onsetTimes(iLoop,1) = Screen('Flip',w,beforeStatTime + beforeStimDur);
        else
            onsetTimes(iLoop,1) = Screen('Flip',w,onsetTimes(iLoop-1,2)+ ifi*2.5);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The second frame: white circle 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Screen('FillRect',w, bkColor);
        abortExpCheck(escapeKey);
        onsetTimes(iLoop,2) = Screen('Flip',w,onsetTimes(iLoop,1)+ifi*.5);
    end

    %---------------------------\


    wait(s);

	NIData            = getAllData;
	NIData.onsetTimes = onsetTimes;

	%-- close the NI device --/
    delete(listh);
    % s.removeChannel(ch);
    s.release;
    delete(s);
	%-------------------------\

	Priority(0);
    
    monitorTest_NI.endTime = datestr(now,'yyyy-mm-dd HH:MM:SS');


    DrawFormattedText(w,'The current run was finished !\n\n Thank you very much for your participation','center','center',instrColor);
    
    Screen('Flip',w);
    
    WaitSecs(2);
    
    sca; % clean screens
    
    ShowCursor;
    RestrictKeysForKbCheck([]); % reenable all keys
    
    warning on; %#ok<*WNON>
    %----------------------\
    
save(['NITest_', datestr(now,'yy_mm_dd_HHMMSS'),'_full']);
    %------ end of exp ------
catch monitorTest_NI_Error

    sca;
    ShowCursor;
    Priority(0);

    %-- close the NI device --/
    try
	    wait(s);

	    NIData = getAllData;

	    delete(listh);
	    s.release;
	    delete(s);
    end 
    %-------------------------\

    save(['NITest_', datestr(now,'yy_mm_dd_HHMMSS'),'_debug']);
    
    RestrictKeysForKbCheck([]); % reenable all keys
    warning on; %#ok<*WNON>
    
    rethrow(monitorTest_NI_Error);
end % exp end


end % function















%% getting data from the global vars
function [ NIData] = getAllData()
	global allData allTimes

	NIData.data       = allData;
	NIData.timeStamps = allTimes;

	clear global allData allTimes
end



%% %% the callback function to get the buffer data
function getACData(src,event) %#ok<*INUSL>

	global allData allTimes 

	if ~exist('allData','var')
	    allData  = [];
	    allTimes = [];
	end 

	allData  = [allData;event.Data];
	allTimes = [allTimes;event.TimeStamps];
end



%% abortExpCheck: check the keyborad to see whether aborted the exp or not
function abortExpCheck(escapeKey)

	%---- check experiment abortation --------------------/
	[keyIsDown, Noused, keyCode]= KbCheck(-1); %#ok<*ASGLU>

	if keyIsDown
	    if keyCode(escapeKey)
	        error('The experiment was aborted by the experimenter ...');
	    end
	end
	%-----------------------------------------------------\

end

