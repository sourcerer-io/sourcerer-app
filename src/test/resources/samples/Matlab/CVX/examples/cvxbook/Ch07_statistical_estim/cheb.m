function [cvx_optval,P,q,r,X,lambda] = cheb(A,b,Sigma);

% Computes Chebyshev lower bounds on probability vectors
%
% Calculates a lower bound on the probability that a random vector
% x with mean zero and covariance Sigma satisfies A x <= b
%
% Sigma must be positive definite
%
% output arguments:
% - prob: lower bound on probability
% - P,q,r: x'*P*x + 2*q'*x + r is a quadratic function
%   that majorizes the 0-1 indicator function of the complement
%   of the polyhedron,
% - X, lambda:  a discrete distribution with mean zero, covariance
%   Sigma and Prob(X not in C)  >= 1-prob

%
% maximize  1 - Tr Sigma*P - r
% s.t.      [ P  q     ]             [ 0      a_i/2 ]
%           [ q' r - 1 ] >= tau(i) * [ a_i'/2  -b_i ], i=1,...,m
%           taui >= 0
%           [ P q  ]
%           [ q' r ] >= 0
%
% variables P in Sn, q in Rn, r in R
%

[ m, n ] = size( A );
cvx_begin sdp quiet
    variable P(n,n) symmetric
    variables q(n) r tau(m)
    dual variables Z{m}
    maximize( 1 - trace( Sigma * P ) - r )
    subject to
        for i = 1 : m,
            qadj = q - 0.5 * tau(i) * A(i,:)';
            radj = r - 1 + tau(i) * b(i);
            [ P, qadj ; qadj', radj ] >= 0 : Z{i};
        end
        [ P, q ; q', r ] >= 0;
        tau >= 0;
cvx_end

if nargout < 4,
    return
end

X = [];
lambda = [];
for i=1:m
   Zi = Z{i};
   if (abs(Zi(3,3)) > 1e-4)
      lambda = [lambda; Zi(3,3)];
      X = [X Zi(1:2,3)/Zi(3,3)];
   end;
end;
mu = 1-sum(lambda);
if (mu>1e-5)
   w = (-X*lambda)/mu;
   W = (Sigma - X*diag(lambda)*X')/mu;
   [v,d] = eig(W-w*w');
   d = diag(d);
   s = sum(d>1e-5);
   if (d(1) > 1e-5)
      X = [X w+sqrt(s)*sqrt(d(1))*v(:,1) ...
            w-sqrt(s)*sqrt(d(1))*v(:,1)];
      lambda = [lambda; mu/(2*s); mu/(2*s)];
   elseif (d(2) > 1e-5)
      X = [X w+sqrt(s)*sqrt(d(2))*v(:,2) ...
            w-sqrt(s)*sqrt(d(2))*v(:,2)];
      lambda = [lambda; mu/(2*s); mu/(2*s)];
   else
      X = [X w];
      lambda = [lambda; mu];
   end;
end;
