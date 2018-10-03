% Example 7.4: Binary hypothesis testing
% Figure 7.4
% Boyd & Vandenberghe "Convex Optimization"
% Original version by Lieven Vandenberghe
% Updated for CVX by Michael Grant, 2005-12-19

% Generate the data
P = [0.70  0.10
     0.20  0.10
     0.05  0.70
     0.05  0.10];
[n,m] = size(P);

% Construct the tradeoff curve by finding the
% the Pareto optimal deterministic detectors,
% which are the curve's vertices

nopts   = 1000;
weights = logspace(-5,5,nopts);
obj     = [0;1];
inds    = ones(n,1);

% minimize  -t1'*q1 - w*t2'*q2
% s.t.      t1+t2 = 1,  t1,t2 \geq 0

next = 2;
for i = 1 : nopts,
   PW = P * diag( [ 1 ; weights(i) ] );
   [ maxvals, maxinds ] = max( PW' );  % max elt in each row
   if (~isequal(maxinds', inds(:,next-1)))
       inds(:,next) = maxinds';
       T = zeros(m,n);
       for j=1:n
          T(maxinds(1,j),j) = 1;
       end;
       obj(:,next) = 1-diag(T*P);
       next = next+1;
   end;
end;
plot(obj(1,:), obj(2,:),[0 1], [0 1],'--');
grid on
for i=2:size(obj,2)-1
   text(obj(1,i),obj(2,i),['a', num2str(i-1)]);
end;

% Minimax detector: not deterministic

cvx_begin
    variables T( m, n ) D( m, m )
    minimize max( D(1,2), D(2,1) )
    subject to
        D == T * P;
        sum( T, 1 ) == 1;
        T >= 0;
cvx_end

objmp = 1 - diag( D );
text( objmp(1), objmp(2), 'b' );
xlabel('P_{fp}'); ylabel('P_{fn}');

%print -deps roc.eps
