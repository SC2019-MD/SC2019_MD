load('LJArgon_500_500iteration.mat');
num_iteration = 100;
xbound = 24;
ybound = 24;
zbound = 24;

figure(1);
for i = 1:num_iteration
    scatter3(position_data_history(i,:,1),position_data_history(i,:,2),position_data_history(i,:,3));
    set(gca,'XLim',[0 xbound],'YLim',[0 ybound],'ZLim',[0 zbound])
    LJ_energy = sum(position_data_history(i,:,4)) / 2;
    title_str = sprintf('Iteration %d, System LJ potential is %e', i, LJ_energy);
    title(title_str);
    pause(1.5);
end

%{
% Analyze the variance of each individual particle's LJ energy over time
% Found the particle 306 and 353 has big variance
var_over_time = single(zeros(500,1));
for i = 1:500
    var_over_time(i) = var(position_data_history(1:num_iteration,i,4));
end
fprintf('maximum variance is %f, mininum variance is %f\n', max(var_over_time), min(var_over_time));

figure(3);
for i = 40:50
    tmp = single(zeros(2,3));
    tmp(1,:) = position_data_history(i,306,1:3);
    tmp(2,:) = position_data_history(i,353,1:3);
    scatter3(tmp(:,1),tmp(:,2),tmp(:,3));
    %set(gca,'XLim',[0 xbound],'YLim',[0 ybound],'ZLim',[0 zbound])
    LJ_energy = position_data_history(i,306,4) + position_data_history(i,353,4);
    title_str = sprintf('Iteration %d, System LJ potential is %e', i, LJ_energy);
    title(title_str);
    pause(1.5);
end
%}