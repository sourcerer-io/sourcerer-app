function A = linop_explicit( op )
%LINOP_EXPLICIT Outputs the explicit matrix representation
%   of a (implicitly defined) linear operator.
%   Useful for checking correctness of code.
% A = LINOP_EXPLICIT( OP ) 
%   returns the matrix A such that A*X = OP(X)

% Introduced June 2016

if nargin == 0,
    error( 'Not enough input arguments.' );
end
sz = op([],0);
if isnumeric(sz),
    sz = { [sz(2),1], [sz(1),1] };
end
% convert [n1;n2] to [n1,n2] if necessary:
for kk = 1:2
    sz{kk} = sz{kk}(:).';
end
% If inputs and outputs are not vectors, then we cannot represent
%   with matrix multiplication
if sz{1}(2) ~= 1 || sz{2}(2) ~= 1
    error('Cannot represent this operator as matrix since input/output is not a vector');
end
m   = sz{2}(1);
n   = sz{1}(1);
e   = zeros(n,1);
A   = zeros(m,n);
for i = 1:n
    e(i) = 1;
    A(:,i)  = op( e, 1 );
    e(i) = 0;
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
