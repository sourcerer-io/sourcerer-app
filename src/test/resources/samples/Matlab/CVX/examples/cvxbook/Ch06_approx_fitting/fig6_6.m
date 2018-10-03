% Example 6.3: Optimal input design
% Section 6.3.2, Figure 6.6
% Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 09/26/05
%
% Consider a dynamical system with scalar input sequence u(0),u(1),...,u(N)
% and scalar output sequence y(0),y(1),...,y(N) related by the convolution
% y = h*u where h = [h(0),h(1),...,h(N)] is the impulse response.
% Our goal is to choose an input sequence to minimize the weighted sum:
%           minimize J_track + delta*J_der + eta*J_mag
% where J_track = 1/(N+1) sum_{t=0}^N (y(t) - y_des(t))^2
%       J_mag   = 1/(N+1) sum_{t=0}^N u(t)^2
%       J_der   = 1/N sum_{t=0}^{N-1} (u(t+1) - u(t))^2

% Input data
m = 201;  n = 201;  N=200;
t = [0:m-1]';
h = (1/9)*((.9).^t) .* (1 - 0.4*cos(2*t));   % sum(h) is approx. 1

H = toeplitz(h', [h(1) zeros(1,n-1)]);
% m1 = round(m/6); m2 = round(m/5); m3 = round(m/5);  m4 = m-m1-m2-m3;
m1 = round(m/5); m2 = round(m/4); m3 = round(m/4);  m4 = m-m1-m2-m3;
y_des = [zeros(m1,1); ones(m2,1); -ones(m3,1); zeros(m4,1)];

D = [-eye(n-1) zeros(n-1,1)];
D = D + [zeros(n-1,1) eye(n-1)];

delta = [0 0 0.3];
eta = [0.005 0.05 0.05];
disp('Finding the optimal input for ');
for i = 1:length(delta)
    disp(['* delta = ' num2str(delta(i)) ' and eta = ' num2str(eta(i))]);
    cvx_begin quiet
    variable u(N+1)
    minimize ( square_pos(norm(H*u - y_des))/(N+1) + ...
               eta(i)*square_pos(norm(u))/(N+1) + ...
               delta(i)*square_pos(norm(D*u))/N )
    cvx_end
    switch(i)
        case 1
            figure(1); plot(t,u); xlabel('t'); ylabel('u(t)');
            title(['Input u(t) for \delta = ' num2str(delta(i)) ' and  \eta = ' num2str(eta(i))]);
            %         print -deps smoothreg1u.eps
            figure(2); plot(t,H*u); xlabel('t'); ylabel('y(t)');
            title(['Output y(t) for \delta = ' num2str(delta(i)) ' and  \eta = ' num2str(eta(i))]);
            %         print -deps smoothreg1y.eps
        case 2
            figure(3); plot(t,u); xlabel('t'); ylabel('u(t)');
            title(['Input u(t) for \delta = ' num2str(delta(i)) ' and  \eta = ' num2str(eta(i))]);
            %         print -deps smoothreg2u.eps
            figure(4); plot(t,H*u); xlabel('t'); ylabel('y(t)');
            title(['Output y(t) for \delta = ' num2str(delta(i)) ' and  \eta = ' num2str(eta(i))]);
            %         print -deps smoothreg2y.eps
        case 3
            figure(5); plot(t,u); xlabel('t'); ylabel('u(t)');
            title(['Input u(t) for \delta = ' num2str(delta(i)) ' and  \eta = ' num2str(eta(i))]);
            %         print -deps smoothreg3u.eps
            figure(6); plot(t,H*u); xlabel('t'); ylabel('y(t)');
            title(['Output y(t) for \delta = ' num2str(delta(i)) ' and  \eta = ' num2str(eta(i))]);
            %         print -deps smoothreg3y.eps
    end
end
