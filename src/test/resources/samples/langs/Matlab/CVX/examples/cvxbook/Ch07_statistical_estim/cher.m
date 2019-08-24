function prob = cher( A, b, Sigma );

% Computes Chernoff upper bounds on probability
%
% Computes a bound on the probability that a Gaussian random vector
% N(0,Sigma) satisfies A x <= b, by solving a QP
%

[ m, n ] = size( A );
cvx_begin quiet
    variable u( m )
    minimize( b' * u + 0.5 * sum_square( chol( Sigma ) * A' * u ) )
    subject to
        u >= 0;
cvx_end
prob = exp( cvx_optval );
