% Plot a polar plot of an antenna array sensitivity
% with lines denoting the target direction and beamwidth.
% This is a helper function used in the broadband antenna examples.
%
% Inputs:
%    X:      an array of abs(y(theta)) where y is the antenna array pattern
%    theta0: target direction
%    bw:     total beamwidth
%    label:  a string displayed as the plot legend
%
% Original code by Lieven Vandenberghe
% Updated for CVX by Almir Mutapcic 02/17/06

function polar_plot_ant(X,theta0,bw,label)

% polar plot
numpoints = length(X);
thetas2 = linspace(1,360,numpoints)';

plot(X.*cos(pi*thetas2/180), X.*sin(pi*thetas2/180), '-');
plot(X.*cos(pi*thetas2/180), X.*sin(pi*thetas2/180), '-');
hold on;
axis('equal');

plot(cos(pi*[thetas2;1]/180), sin(pi*[thetas2;1]/180), '--');
text(1.1,0,'1');

plot([0 cos(pi*theta0/180)], [0 sin(pi*theta0/180)], '--');
sl1 = find(thetas2-theta0 > bw/2);
sl2 = find(thetas2-theta0 < -bw/2);
Gsl = max(max(X(sl1)), max(X(sl2)));
plot(Gsl*cos(pi*thetas2(sl1)/180), Gsl*sin(pi*thetas2(sl1)/180), '--');
plot(Gsl*cos(pi*thetas2(sl2)/180), Gsl*sin(pi*thetas2(sl2)/180), '--');

text(-1,1.1,label);

axis off;
