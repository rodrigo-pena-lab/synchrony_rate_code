
clear
clc


%%
load L5e_results_frequency_PD_synch_0.mat
nSeeds = numel(seeds);

fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Stimulation frequency (Hz)');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])



%%
load L5e_results_frequency_PD_synch_0p5.mat
nSeeds = numel(seeds);

fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Stimulation frequency (Hz)');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])



%%
load L5e_results_frequency_PD_synch_1.mat
nSeeds = numel(seeds);

fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Stimulation frequency (Hz)');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])









%%
load L5e_results_synchrony_PD_100Hz.mat
nSeeds = numel(seeds);

fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Input synchrony');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])



%%
load L5e_results_synchrony_PD_800Hz.mat
nSeeds = numel(seeds);

fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Input synchrony');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])




%%
load L5e_results_synchrony_PD_2000Hz.mat
nSeeds = numel(seeds);

fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Input synchrony');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])






%%
%%
load L5e_results_frequency_PD_synch_0.mat
fig = figure('Color','w','Name','L5e firing frequency');
hold on;
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Stimulation frequency (Hz)');
ylabel('L5e mean firing frequency (Hz)');
ylim([0 25])

load L5e_results_frequency_PD_synch_0p5.mat
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','r');

load L5e_results_frequency_PD_synch_1.mat
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','b');

legend({'Syn 0' 'Syn 0.5' 'Syn 1'})
box off



%%
load L5e_results_synchrony_PD_100Hz.mat
fig = figure('Color','w','Name','L5e firing frequency');
hold on;
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k');
xlabel('Input synchrony');
ylabel('L5e mean firing frequency (Hz)');
box off
ylim([0 25])

load L5e_results_synchrony_PD_800Hz.mat
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','r');

load L5e_results_synchrony_PD_2000Hz.mat
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','b');

legend({'Input freq 100 Hz' 'Input freq 800 Hz' 'Input freq 2000 Hz'})
box off
