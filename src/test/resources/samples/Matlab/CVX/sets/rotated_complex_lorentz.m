function cvx_optpnt = rotated_complex_lorentz( sx, dim )

%ROTATED_COMPLEX_LORENTZ   Rotated complex second-order cone.

%   ROTATED_COMPLEX_LORENTZ is the complex version of ROTATED_LORENTZ.
%   ROTATED_COMPLEX_LORENTZ(N), where N is a positive integer, creates a 
%   complex column variable of length N and two real scalar 
%   variables, and constrains them to lie in a complex rotated second-order
%   cone. That is, given the declarations
%       variable x(n) complex
%       variables y z
%   the constraint
%       {x,y,z} == rotated_complex_lorentz(n)
%   is equivalent to
%       norm(x,2) <= geo_mean([y,z])
%   except that using ROTATED_COMPLEX_LORENTZ is more efficient.
%
%   ROTATED_COMPLEX_LORENTZ(SX,DIM), where SX is a valid size vector and
%   DIM is a positive integer, creates a complex array variable of size
%   SX and two real array variables of size SY (see below), and applies the
%   second-order cone constraint along the dimension DIM. That is, given
%   the declarations
%       sy = sx; sy(min(dim,length(sx)+1)) = 1;
%       variable x(sx) complex
%       variables y(sy) z(sz)
%   the constraint
%       {x,y,z} == rotated_complex_lorentz(sx,dim)
%   is equivalent to
%       norms(x,2,dim) <= geo_mean(cat(dim,y,z),dim)
%   except, again, ROTATED_LORENTZ is more efficient. DIM is optional; if
%   it is omitted, the first non-singleton dimension is used.
%
%   Disciplined convex programming information:
%       ROTATED_COMPLEX_LORENTZ is a cvx set specification. See the user 
%       guide for details on how to use sets.

narginchk(1,2);
if nargin == 1,
    cvx_optpnt = rotated_lorentz( sx, [], true );
else
    cvx_optpnt = rotated_lorentz( sx, dim, true );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
