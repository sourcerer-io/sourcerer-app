% Exercise 5.1d: Sensitivity analysis for a simple QCQP
% Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 08/29/05
% (a figure is generated)
%
% Let p_star(u) denote the optimal value of:
%           minimize    x^2 + 1
%               s.t.    (x-2)(x-2)<=u
% Finds p_star(u) and plots it versus u.

fprintf(1,'Computing p_star(u)...\n ');

u = linspace(-0.9,10,50);
p_star = zeros(1,length(u));
for i = 1:length(u)
    disp(['for u = ' num2str(u(i))]);
    % perturbed problem
    cvx_begin quiet
        variable x(1)
        minimize ( quad_form(x,1) + 1 )
        quad_form(x,1) - 6*x + 8 <= u(i);
    cvx_end
    % optimal value
    p_star(i) = cvx_optval;
end

fprintf(1,'Done! \n');

% Plots
plot(u,p_star)
axis([-2 10 -2 10])
xlabel('u');
ylabel('p^*(u)')
title('Sensitivity analysis: p^*(u) vs u');
