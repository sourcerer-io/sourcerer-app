% CVX: Built-in operators and functions supported in CVX models.
%   
%   The following operators and functions are included with MATLAB but
%   have either been verified to work properly within CVX models or have
%   been extended with additional code to do so. In many cases, typing
%      help cvx/<func>
%   where <func> is one of the names listed below will provide specific
%   help on the proper use of that item in CVX models---including any
%   restrictions imposed by the DCP and DGP rulesets.
%
%   For a list of new functions created specifically for CVX, type
%   "help cvx/functions".
%
%   The exponential and logarithm functions, along with the starred 
%   functions listed in "help cvx/functions", are supported using a
%   "successive approximation" approach: the solver must be called 
%   multiple times to achieve the required accuracy. Thus models using
%   these functions should be expected to run more slowly than models
%   of comparable size that do not. See the CVX user guide for details.
%
% Computational operators:
%    plus (+), uplus (unary +), minus (-), uminus (unary -), times (.*),
%    mtimes (*), ldivide (.\), mldivide (\), rdivide (./), mrdivide (/), 
%    power (.^), mpower (^), subsref/subsasgn/end (subscripting),
%    transpose (.'), ctranspose (')
% Relational operators:
%    eq (==), ge (>=), gt (>), le (<=), lt(<), ne (~=).
% Linear/affine functions:
%    blkdiag, cat, conj, conv, cumsum, diag, dot, find, flipdim, fliplr, 
%    flipud, hankel, horzcat, imag, ipermute, kron, permute, polyval, real,
%    repmat, reshape, rot90, sparse, sum, toeplitz, tril, triu, vertcat
% Nonlinear functions:
%    abs, exp(*), log (*), max, min, norm, prod, sqrt
% Query functions:
%    disp/display, end, isempty, isequal, length, isreal, ndims, nnz,
%    numel, size, spy

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
