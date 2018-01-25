function [spatialCorrM,Xi,Yi,x,y,z] = make2DCorMatrix(xyLum,h,v,method,exptraMethod)


% argins:
% 
% xyLum:        [n*3] double: the first 2ed and 3rd column are for X,Y and luminance respectively
% 
% h:            [1] double: number of horizontal lines of the screen e.g., 768
% v:            [1] double: number of vertical lines of the screen e.g., 1024
% method         [string] : interploate/extrapolate method e.g., 'spline'
 % Written by Yang Zhang Jan 01 14:49:54 2018
 % Soochow University, China
 %  zhangyang873@gmail.com


if ~exist('method','var')||isempty(method)
  method = 'spline';
end 


if ~exist('exptraMethod','var')||isempty(exptraMethod)
	exptraMethod = 2; % 1and 2 for exptrapolate and just replace 
end 


xyLum = sortrows(xyLum,[1 2]);

% check inputs:

if size(unique(xyLum(:,1:2),'rows'),1) ~= size(xyLum,1)
    error('please check you input, looks like there are redundant xy coordinates!');
end 

nCol  = numel(unique(xyLum(:,1))); % x
nRow  = numel(unique(xyLum(:,2))); % y

x = reshape(xyLum(:,1),nRow,nCol); % to make it tobe nRow * nCol

y = reshape(xyLum(:,2),nRow,nCol); % to make it tobe nRow * nCol

z = reshape(xyLum(:,3),nRow,nCol); % to make it tobe nRow * nCol


%  nrow = 4 ncol = 3
% x:
% 1 3 5
% 1 3 5
% 1 3 5
% 1 3 5
% y:
% 3 3 3 
% 5 5 5
% 7 7 7
% 9 9 9

switch exptraMethod
case 1
  for iCol = 1:nCol
  	mUz(1,iCol) = interp1(y(:,iCol),z(:,iCol),1,method,'extrap');
  	mDz(1,iCol) = interp1(y(:,iCol),z(:,iCol),v,method,'extrap');
  end 


  for iRow = 1:nRow
  	mLz(iRow,1) = interp1(x(iRow,:),z(iRow,:),1,method,'extrap');
  	mRz(iRow,1) = interp1(x(iRow,:),z(iRow,:),h,method,'extrap');
  end 


  LUz = interp1(x(1,:),mUz(1,:),1,method,'extrap');
  LDz = interp1(x(1,:),mDz(end,:),1,method,'extrap');

  RUz = interp1(x(1,:),mUz(1,:),h,method,'extrap');
  RDz = interp1(x(1,:),mDz(1,:),h,method,'extrap');
case 2

  mUz = z(1,:);
  mDz = z(end,:);

  mLz = z(1,:);
  mRz = z(end,:);

  LUz = z(1,1);
  LDz = z(end,1);

  RUz = z(1,end);
  RDz = z(end,end);

otherwise
  error('exptraMethod should be of [1 2]!');
end 
% LUz = interp1(y(:,1),mLz(:,1),1,method,'extrap');


 X = [1,           x(1,:),h;...
      ones(nRow,1),x,     ones(nRow,1)*h;...
      1,           x(1,:),h];


 Y = [1,     ones(1,nCol)  ,1;...
      y(:,1),y             ,y(:,1);...
      v,     ones(1,nCol)*v,v];


 Z = [LUz,mUz,RUz;...
      mLz,z  ,mRz;...
      LDz,mDz,RDz];


[Xi,Yi] = meshgrid(1:h,1:v);


spatialCorrM = interp2(X,Y,Z,Xi,Yi,method);
spatialCorrM = min(spatialCorrM(:))./spatialCorrM;







