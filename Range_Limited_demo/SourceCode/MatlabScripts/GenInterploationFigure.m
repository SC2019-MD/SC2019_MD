clear all;
clf;

X = 1:0.01:50;

for i = 1:length(X)
    Y(i) = X(i)^-0.5;
end


plot(X,Y,'k','LineWidth',3);
set(gca,'xtick',[],'ytick',[]);
%set(gca,'visible','off');
xlim([0.5 30]);
ylim([0.15 1]);
xlabel('r^2 value','FontSize', 30);
ylabel('r^{-k} term','FontSize', 30);