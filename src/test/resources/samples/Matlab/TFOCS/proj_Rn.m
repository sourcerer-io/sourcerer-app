function op = proj_Rn

%PROJ_RN    "Projection" onto the entire space.
%    OP = PROX_RN returns an implementation of the set Rn. Use
%    this function to specify a model with no nonsmooth component. It is
%    identical to both PROX_0 and SMOOTH_CONSTANT( 0 ).
%    The projection onto Rn is just the identity.
% Dual: proj_0.m

op = smooth_constant( 0 );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
