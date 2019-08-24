function op = prox_0

%PROX_0    The zero proximity function:
%    OP = PROX_0 returns an implementation of the function OP(X) = 0. Use
%    this function to specify a model with no nonsmooth component. It is
%    identical to both PROJ_Rn and SMOOTH_CONSTANT( 0 ).
% Dual: proj_0.m

op = smooth_constant( 0 );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
