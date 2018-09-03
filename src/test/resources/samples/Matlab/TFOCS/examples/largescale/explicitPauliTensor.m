function u = explicitPauliTensor( list )
% u = explicitPauliTensor( list )
%   makes the explicit matrix corresponding to the tensor
%   product of Pauli matrices.
%   "list" should be an ordered vector, where each entry is
%   either 1, 2, 3 or 4, correspodning to the X, Y, Z and I
%   Pauli matrices, respectively.

if ~isvector(list) || max(list) > 4 || min(list) < 1
    error('Error making Pauli matrices');
end

PX = [0,1;1,0]; PY = [0,-1i;1i,0]; PZ =[1,0;0,-1]; PI = eye(2);

PAULI{1} = PX;
PAULI{2} = PY;
PAULI{3} = PZ;
PAULI{4} = PI;

u=1;
for i = 1:length(list)
    u = kron( u, sparse( PAULI{list(i)} ));
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
