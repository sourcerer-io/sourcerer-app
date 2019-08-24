function op = linop_reshape( sz_in, sz_out )

%LINOP_RESHAPE  Linear operator to perform reshaping of matrices.
%    op = linop_reshape( sz_in, sz_out ) creates a linear operator that
%    uses the matlab 'reshape' function to reshape between sz_in and sz_out.
%    Both sz_in and sz_out must be vectors with d elements (for dimension d).
%    Assumes the number of elements does not change.
%
%
% Contributed by Graham Coleman, graham.coleman@upf.edu
%   See also linop_vec
error( nargchk(nargin,2,2));
if ~isnumeric(sz_in) || ~isnumeric(sz_out)
    error('sz_in and sz_out must be arrays');
elseif numel(sz_in) ~= numel(sz_out)
    error('sz_in and sz_out must have the same number of elements (usually 2)');
elseif prod( sz_in(:) ) ~= prod( sz_out(:) )
    error('The number of elements cannot change from sz_in to sz_out');
end
sz_in  = sz_in(:).';
sz_out = sz_out(:).';
    
op = @(x,mode) gkcop_reshape_impl( sz_in, sz_out, x, mode );

function y = gkcop_reshape_impl( sz_in, sz_out, x, mode )
switch mode,
    case 0, y = { sz_in, sz_out };
    case 1, y = reshape( x, sz_out );
    case 2, y = reshape( x, sz_in );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
