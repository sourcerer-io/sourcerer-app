% Example 6.4: Regressor selection problem
% Section 6.3.1, Figure 6.7
% Original by Lieven Vandenberghe
% Adapted for CVX Argyris Zymnis - 10/2005
%
% Solves
%        minimize   ||A*x-b||_2
%        subject to card(x) <= k
%
% where card(x) denotes the number of nonzero elements in x,
% by first solving (for some value of alpha close to ||x_ln||_1)
%        minimize   ||A*x-b||_2
%        subject to ||x||_1 <= alpha
%
% and iteratively decreasing alpha so as to get card(x) = k
% The sparsity pattern is then fixed in A and b and
%        minimize   ||A*x-b||_2
%
% is solved

rand('state',0);

m = 10;
n = 20;

A = randn(m,n);
b = A*[randn(round(m/2),1); zeros(n-round(m/2),1)];
b = b + 0.1*norm(b)*randn(m,1);

if (1) %%%%%%%%%%%%

% tradeoff curve for heuristic
%
% min.  ||Ax-b||_2
% s.t.  ||x||_1 <= alpha

residuals_heur = [norm(b)];
xln = A'*((A*A')\b);
lnorm = norm(xln,1);
nopts = 100;
alphas = linspace(0,lnorm,nopts);
residuals_heur = [norm(b)];
card_heur = [0];


for k=2:(nopts-1)
  alpha = alphas(k);

  cvx_begin quiet
    variable x(n)
    minimize(norm(A*x-b))
    subject to
        norm(x,1) <= alpha;
  cvx_end

  x(find(abs(x) < 1e-3*max(abs(x)))) = 0;
  ind = find(abs(x));
  sparsity = length(ind);
  fprintf(1,'Current sparsity pattern k = %d \n',sparsity);
  x = zeros(n,1);  x(ind) = A(:,ind)\b;
  card_heur = [card_heur, sparsity];
  residuals_heur = [residuals_heur, norm(A*x-b)];
end;

obj1 = norm(b)
obj2 = [0];

i=1;
for k=1:m-1
  if ~isempty(find(card_heur == k))
     obj2(i+1) = k;
     obj1(i+1) = min(residuals_heur(find(card_heur ==k)));
     i=i+1;
  end;
end;
obj2(i) = m;  obj1(i) = 0;

end; %%%%%%%%%%%%%%%%%%%


% globally optimal tradeoff


if (1) %%%%%%%%%%%%%

bestx = zeros(n,m);
bestres = zeros(1,m);

for k=1:m-1
  k
  % enumerate sparsity patterns with exactly k nonzeros
  bestres(k) = Inf;
  ind = 1:k
  nocases = 1;
  done = 0;
  while ~done
     done = 1;
     for i=0:k-1
       if (ind(k-i) < n-i),
          ind(k-i:k) = ind(k-i)+[1:i+1];
          done = 0;
          break;
       end;
     end;
     if done, break; end;
     x = zeros(n,1);
     x(ind) = A(:,ind)\b;
     if (norm(A*x-b) < bestres(k)),
        bestres(k) = norm(A*x-b);
        bestx(:,k) = x;
     end;
     nocases = nocases + 1;
  end;
  nocases
  factorial(n)/(factorial(n-k)*factorial(k))
end;

x = A\b;
bestres(m) = norm(A*x-b);
bestres = [norm(b) bestres];

end; %%%%%%%%%

figure
hold off
obj1dbl =[];
obj2dbl =[];
for i=1:length(obj1)-1
  obj1dbl = [obj1dbl, obj1(i), obj1(i)];
  obj2dbl = [obj2dbl, obj2(i), obj2(i+1)];
end;
obj1dbl = [obj1dbl, obj1(length(obj1))];
obj2dbl = [obj2dbl, obj2(length(obj1))];

bestobj1 = bestres;
bestobj2 = [0:1:m];
bestobj1dbl =[];
bestobj2dbl =[];
for i=1:length(bestobj1)-1
  bestobj1dbl = [bestobj1dbl, bestobj1(i), bestobj1(i)];
  bestobj2dbl = [bestobj2dbl, bestobj2(i), bestobj2(i+1)];
end;
bestobj1dbl = [bestobj1dbl, bestobj1(length(bestobj1))];
bestobj2dbl = [bestobj2dbl, bestobj2(length(bestobj1))];

plot(obj1dbl,obj2dbl,'-', bestobj1dbl, bestobj2dbl,'--');
hold on
plot(obj1,obj2,'o', bestobj1, bestobj2,'o');
axis([0 ceil(2*norm(b))/2 0 m+1])
xlabel('x');
ylabel('y');
hold off

%print -deps sparse_regressor_global_helv.eps
%save regressor_results
