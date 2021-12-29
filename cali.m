function triggerLinuxNframe(screenNum)


if ~exist('screenNum','var')
    screenNum = 1; % 1 for inside monitor ;0 for outside monitor 
end


screenNum   = 1; 
ColNum      = 17;
rowNum      = 9;
isdebug     = false;
bkcolor     = [0 0 0];
targetcolor = [255 255 255];
is2DCorrect = 0;

[CIExyY,myCorrectionMatrix] = ColorCAL2_bcl('initialize');
% 
 AssertOpenGL;
 PsychImaging('PrepareConfiguration'); 
 PsychImaging('AddTask', 'AllViews', 'DisplayColorCorrection', 'GainMatrix');

  % opening your win over here
[w,fullrect]   = PsychImaging('OpenWindow',screenNum,targetcolor);

if is2DCorrect
    PsychColorCorrection('SetGainMatrix',w,matrix);
else
    matrix = ones(fullrect([3,4]));
    PsychColorCorrection('SetGainMatrix',w,matrix);
end

eachRectWidth  = fullrect(3)/m;
eachRectHeight = fullrect(4)/n; 

iRect = 0;
for locRow = 1:n
	for  locCol = 1:m
		iRect = iRect+1;
		RectPos(:,iRect) = [eachRectWidth*(locCol-1),eachRectHeight*(locRow-1),eachRectWidth*locCol,eachRectHeight*locRow]';
	end
end

Screen('FrameRect',w,bkcolor',RectPos,1);
Screen('Flip',w);


 
% ifi  = Screen('GetFlipInterval',w);

for iLoc = 1:iRect
   
    fprintf('please press f\n');      
    
    while true

        [kd,sec,keycode] = KbCheck;

        if keycode(KbName('f'))
            break;
        end
    end
    
    WaitSecs(2);

    for iTrial = 1:5

        [CIExyY] = ColorCAL2_bcl('measure',1,myCorrectionMatrix);

        allCIExyY(iTrial,:,iLoc) =  CIExyY;

        WaitSecs(2);
    end
    
end

save;
        
sca;









