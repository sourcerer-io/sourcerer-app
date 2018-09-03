% Figures 6.8-6.10: Quadratic smoothing
% Section 6.3.3
% Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX Argyris Zymnis - 10/2005
%
% Suppose we have a signal x, which does not vary too rapidly
% and that x is corrupted by some small, rapidly varying noise v,
% ie. x_cor = x + v. Then if we want to reconstruct x from x_cor
% we should solve (with x_hat as the parameter)
%        minimize ||x_hat - x_cor||_2 + lambda*phi_quad(x_hat)
%
% where phi_quad(x) = sum(x_(i+1)-x_i)^2 , for i = 1 to n-1.
% The parameter lambda controls the ''smoothness'' of x_hat.
%
% The first figure which is generated shows the original and
% the corrupted signals. The second figure shows the tradeoff curve
% obtained when varying lambda and the third figure shows three
% reconstructed signals.
%
% NOTE: This is not a good problem to use CVX on. By exploiting
% the sparsity in this case, we can solve this problem much more
% efficiently using least squares.


randn('state',0);

n = 4000;  t = (0:n-1)';
exact = 0.5*sin((2*pi/n)*t).*sin(0.01*t);
corrupt = exact + 0.05*randn(size(exact));

figure(1)
subplot(211)
plot(t,exact,'-');
axis([0 n -0.6 0.6])
title('original signal');
ylabel('ya');

subplot(212)
plot(t,corrupt,'-');
axis([0 n -0.6 0.6])
xlabel('x');
ylabel('yb');
title('corrupted signal');
%print -deps smoothrec_signals.eps % figure 6.8, page 313

A = sparse(n-1,n);
A(:,1:n-1) = -speye(n-1,n-1);  A(:,2:n) = A(:,2:n)+speye(n-1,n-1);

% tradeoff curve, figure 6.9, page 313
nopts = 100;
lambdas = logspace(-10,10,nopts);

obj1 = [];  obj2 = [];

fprintf('computing 100 points on tradeoff curve ... \n');

for i=1:nopts

  lambda = lambdas(i);
  cvx_begin quiet
    variable x(n)
    minimize(norm(x-corrupt)+lambda*norm(x(2:n)-x(1:n-1)))
  cvx_end
  obj1 = [obj1, norm(full(A*x))];
  obj2 = [obj2, norm(full(x-corrupt))];

  fprintf('tradeoff point %d\n',i);
end;

figure(2)
plot(obj2,obj1,'-');  hold on;
plot(0,norm(A*corrupt),'o');
plot(norm(corrupt),0,'o');  hold off;
xlabel('x');
ylabel('y');
title('||xhat-xcorr||_2 vs. ||D xhat||_2');
%print -deps smoothrec_tradeoff.eps % figure 6.9, page 313

%three smooth signals, figure 6.10, page 314
nopts = 3;
alphas = [8 3 1];
xrecon = [];

for i=1:3
   fprintf(1,'Reconstructed Signals: %d of 3 \n',i)
   alpha = alphas(i);
   cvx_begin quiet
    variable x(n)
    minimize(norm(x(2:n)-x(1:n-1)))
    subject to
        norm(x-corrupt) <= alpha;
   cvx_end
   xrecon = [xrecon, x];

end

figure(3)
subplot(311), plot(xrecon(:,1));
axis([0 n -0.6 0.6])
ylabel('ya');
title('||xhat-xcorr||_2=8');
subplot(312), plot(xrecon(:,2));
axis([0 n -0.6 0.6])
ylabel('yb');
title('||xhat-xcorr||_2=3');
subplot(313), plot(xrecon(:,3));
axis([0 n -0.6 0.6])
xlabel('x');
ylabel('yc');
title('||xhat-xcorr||_2=1');
%print -deps smoothrec_results.eps % figure 6.10, page 314
