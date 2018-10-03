function z = kl_div( x, y )

%KL_DIV   Scalar relative entropy.
%   KL_DIV(X,Y) returns an array of the same size as X+Y with the Kullback-
%   Leubler divergence function applied to each element:
%                    { X.*LOG(X./Y)-X+Y if X >  0 & Y >  0,
%      KL_DIV(X,Y) = { 0                if X == 0 & Y >= 0,
%                    { +Inf             otherwise.
%   X and Y must either be the same size, or one must be a scalar. If X and
%   Y are vector PDFs, then SUM(KL_DIV(X,Y)) returns their Kullback-Leibler
%   divergence, which in the case of PDFs is equal to SUM(REL_ENTR(X,Y)).
%
%   Disciplined convex programming information:
%       KL_DIV(X,Y) is convex and nonmonotonic in both X and Y. Thus when
%       used in CVX expressions, X and Y must be real and affine. The use 
%       of KL_DIV(X,Y) in an objective or constraint will effectively 
%       constrain both X and Y to be nonnegative, hence there is no need to
%       add additional constraints X >= 0 or Y >= 0 to enforce this.

narginchk(2,2);
cvx_expert_check( 'kl_div', x, y );
z = rel_entr( x, y ) - x + y;

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
