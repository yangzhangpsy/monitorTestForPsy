function [CIExyY,myCorrectionMatrix] = ColorCAL2_bcl(command,samples,myCorrectionMatrix)

% useage:
%
% inputs:
%
%	 command                 [string]:       the command should be of either 'initialize' or 'measure'
%	 samples                 [double]:       number of measures
%	 myCorrectionMatrix      [double matrix]: the port address
%	 ColorCALIICDCPort       [string]:       the calibration Matrix used to correct the return values
%
% outputs:
%	 CIExyY         [1*3 double]  measured color values
%	 myCorrectionMatrix [matrix]   correction Matrix used to transform the raw data to CIExyY
%
%
%
% demo:
% before measure the xyY, we have to initialize it first via
%
% [CIExyY,myCorrectionMatrix] = ColorCAL2_bcl('initialize');
%
% or
%
% [CIExyY,myCorrectionMatrix] = ColorCAL2_bcl('initialize',[],[],portAddress);
%
% and then measure it via:
%
% [CIExyY,myCorrectionMatrix] = ColorCAL2_bcl('measure',1,myCorrectionMatrix);
%
% Shows how to make measurements using the ColorCAL II CDC interface.
% This script calls several other separate functions which are included
% below.
%
% CIExyY returns the XYZ values for each measurement (each row
% represents a different measurement).
%
%
% revised by yang 2017/9/23 17:46:33

if nargin < 1
    helpStr = { 'useage: '
        ' '
        'inputs: '
        ' '
        '    command                 [string]:       the command should be of either ''initialize'' or ''measure'' '
        '    samples                 [double]:       number of measures  '
        '    myCorrectionMatrix      [double matrix]: the port address  '
        '    ColorCALIICDCPort       [string]:       the calibration Matrix used to correct the return values '
        ' '
        'outputs: '
        '    CIExyY         [1*3 double]  measured color values '
        '    myCorrectionMatrix [matrix]   correction Matrix used to transform the raw data to CIExyY '
        ' '
        ' '
        ' '
        'demo: '
        'before measure the xyY, we have to initialize it first via '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCAL2_bcl(''initialize''); '
        ' '
        'or  '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCAL2_bcl(''initialize'',[],[],portAddress); '
        ' '
        'and then measure it via: '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCAL2_bcl(''measure'',1,myCorrectionMatrix); '
        ' '
        ' '
        'Shows how to make measurements using the ColorCAL II CDC interface. '
        'This script calls several other separate functions which are included '
        'below. '
        ' '
        'CIExyY returns the XYZ values for each measurement (each row '
        'represents a different measurement). '
        ' '
        ' '
        'revised by yang 2017/9/23 17:46:33 '};
    
    for iRow = 1:numel(helpStr)
        disp(helpStr{iRow});
    end
    CIExyY             = [];
    myCorrectionMatrix = [];
    
    return;
end



if ~exist('command','var')||isempty(command)
    command = 'initialize';
end

if ~exist('samples','var')||isempty(samples)
    samples = 5;
end

if ~exist('myCorrectionMatrix','var')||isempty(myCorrectionMatrix)
    myCorrectionMatrix = [];
end

CIExyY = [];



if strcmpi(command(1),'i')||isempty(myCorrectionMatrix)
    % First, the ColorCAL II should have its zero level calibrated. This can
    % simply be done by placing one's hand over the ColorCAL II sensor to block
    % all light.
    disp('Please cover the ColorCAL II so that no light can enter it, then press any key:');
    
    % Wait for a keypress to indicate the ColorCAL II sensor is covered.
    pause;
    
    % This is a separate function (see further below in this script) that will
    % calibrate the ColorCAL II's zero level (i.e. the value for no light).
    ColorCal2('ZeroCalibration');
    % Confirm the calibration is complete. Position the ColorCAL II to take a
    % measurement from the screen.
    disp('OK, you can now uncover ColorCAL II. Please position ColorCAL II where desired, then press any key to continue:');
    
    % Wait for a keypress to confirm ColorCAL II is in position before
    % continuing.
    pause;
    
    % Obtains the XYZ colour correction matrix specific to the ColorCAL II
    % being used, via the CDC port. This is a separate function (see further
    % below in this script).
    myCorrectionMatrix = ColorCal2('ReadColorMatrix');
    myCorrectionMatrix = myCorrectionMatrix(1:3,:);
end % added by yang


if strcmpi(command(1),'m')
    % Cycle through each sample.
    transformedValues = zeros(samples,3);
    for iSample = 1:samples
        s = ColorCal2('MeasureXYZ');
        transformedValues(iSample, 1:3) = myCorrectionMatrix * [s.x s.y s.z]';
        
    end
    
    % Convert recorded XYZ values into CIE xyY values using PsychToolbox
    % supplied function XYZToxyY (included at the bottom of the script).
    CIExyY = XYZToxyY(transformedValues')';
    
end



function [xyY] = XYZToxyY(XYZ)
% [xyY] = XYZToxyY(XYZ)
%
% Compute chromaticity and luminance from tristimulus values.
%
% 8/24/09  dhb  Speed it up vastly for large arrays.

denom = sum(XYZ,1);
xy = XYZ(1:2,:)./denom([1 1]',:);
xyY = [xy ; XYZ(2,:)];



