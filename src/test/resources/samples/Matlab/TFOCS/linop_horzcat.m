function op = linop_horzcat( varargin )
%LINOP_HORZCAT Combines two or more TFOCS lienar operators
%OP = LINOP_HORZCAT( OP1, OP2, ..., OPN )
%    Defines the linear operator
%      OP(x,1) = OP1(x1,1) + ... + OPN(xn,1)
%    which has adjoint
%       OP(x,2) = [OP1(x,2);
%                  ...
%                  OPN(x,2)];
%
% See also linop_vertcat.m

% Introduced June 2016
% Not sure how efficient this implementation is

if nargin == 0,
    error( 'Not enough input arguments.' );
end
for k = 1 : nargin,
    varargin{k}     = linop_adjoint( varargin{k} );
end
op  = linop_adjoint( linop_vertcat( varargin{:} ) );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
