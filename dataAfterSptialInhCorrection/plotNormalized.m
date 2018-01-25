
load('normalized_final.mat');
figure;
imagesc(normalized);
box off;
colorbar;

[myColormap] = makeColormap(30,0,1,0);	
colormap(myColormap);	
caxis([0.7,1.1]);

figureName = '153afterSpLum';
title([figureName]);
print('-dpdf','-painters',[figureName,'.pdf']);
saveas(gcf,[figureName,'.bmp']);
