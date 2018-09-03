% Figure 6.24: Fitting a convex function to given data
% Section 6.5.5
% Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Argyris Zymnis - 11/27/2005
%
% Here we find the convex function f that best fits
% some given data in the least squares sense.
% To do this we solve
%     minimize    ||yns - yhat||_2
%     subject to  yhat(j) >= yhat(i) + g(i)*(u(j) - u(i)), for all i,j

clear

% Noise level in percent and random seed.
rand('state',29);
noiseint=.05;

% Generate the data set
u = [0:0.04:2]';
m=length(u);
y = 5*(u-1).^4 + .6*(u-1).^2 + 0.5*u;
v1=u>=.2;
v2=u<=.6;
v3=v1.*v2;
dipvec=((v3.*u-.4*ones(1,size(v3,2))).^(2)).*v3;
y=y+40*(dipvec-((.2))^2*v3);

% add perturbation and plots the input data
randf=noiseint*(rand(m,1)-.5);
yns=y+norm(y)*(randf);
figure
plot(u,yns,'o');

% min. ||yns-yhat||_2
% s.t. yhat(j) >= yhat(i) + g(i)*(u(j) - u(i)), for all i,j
cvx_begin
    variables yhat(m) g(m)
    minimize(norm(yns-yhat))
    subject to
        yhat*ones(1,m) >= ones(m,1)*yhat' + (ones(m,1)*g').*(u*ones(1,m)-ones(m,1)*u');
cvx_end

nopts =1000;
t = linspace(0,2,nopts);
f = max(yhat(:,ones(1,nopts)) + ...
      g(:,ones(1,nopts)).*(t(ones(m,1),:)-u(:,ones(1,nopts))));
plot(u,yns,'o',t,f,'-');
axis off
%print -deps interpol_convex_function2.eps
