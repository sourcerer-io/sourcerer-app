function cvx_optpnt = complex_lorentz( sx, dim )

%COMPLEX_LORENTZ   Complex second-order cone.
%   COMPLEX_LORENTZ(N), where N is a positive integer, creates a column
%   variable of length N and a scalar variable, and constrains them
%   to lie in a second-order cone. That is, given the declaration
%       variable x(n) complex
%       variable y
%   the constraint
%       {x,y} == complex_lorentz(n)
%   is equivalent to
%       norm(x,2) <= y
%   The inequality form is more natural, and preferred in most cases. But
%   in fact, the COMPLEX_LORENTZ set form is used by CVX itself to convert
%   complex NORM()-based constraints to solvable form.
%
%   COMPLEX_LORENTZ(SX,DIM), where SX is a valid size vector and DIM is a
%   positive integer, creates an array variable of size SX and an array
%   variable of size SY (see below) and applies the second-order cone
%   constraint along dimension DIM. That is, given the declarations
%       sy = sx; sy(min(dim,length(sx)+1))=1;
%       variable x(sx) complex
%       variable y(sy)
%   the constraint
%       {x,y} == complex_lorentz(sx,dim)
%   is equivalent to
%       norms(x,2,dim) <= y
%   Again, the inequality form is preferred, but CVX uses the set form
%   internally. DIM is optional; if it is omitted, the first non-singleton
%   dimension is used.
%
%   LORENTZ(SX,DIM,CPLX) creates real second-order cones if CPLX is FALSE,
%   and complex second-order cones if CPLX is TRUE. The latter case is
%   equivalent to COMPLEX_LORENTZ(SX,DIM).
%
%   Disciplined convex programming information:
%       LORENTZ is a cvx set specification. See the user guide for
%       details on how to use sets.

narginchk(1,2);
if nargin == 1,
    cvx_optpnt = lorentz( sx, [], true );
else
    cvx_optpnt = lorentz( sx, dim, true );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
