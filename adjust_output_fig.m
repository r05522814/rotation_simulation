clear variables; close all; clc;

% outputsize = [2 1.5]; %inches
outputsize = [2 1.5]; %cetermeters

file_name = 'Validation_confusionmatrix_20190927_7cat_day&night';

fig = openfig([file_name '.fig']);
% fig = openfig([file_name '.fig'],'invisible');

% set(gca,'Xtick',0:1000:3000,'Ytick',-1500:750:1500,'Ztick',-400:400:400,'fontsize',7);
% set(gca,'fontsize',7);

% colormap(parula);
% colormap(jet);
colorbar off;
% title('');
%%
% for visualization
set(gcf,'Units','inches','position',[2 2 outputsize])%[5 5 2.5 1.8]

fig.PaperPositionMode = 'auto';

% for export
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 outputsize]);%[0 0 2.5 1.9],'PaperSize', [1.7 1.9]

%%
% saveas(gcf, [file_name '_with_colorbar' '.emf']);
% saveas(gcf, [file_name '.emf']);