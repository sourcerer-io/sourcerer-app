function op = linop_compose( varargin )
%LINOP_COMPOSE Composes two TFOCS linear operators
%OP = LINOP_COMPOSE( OP1, OP2, ..., OPN )
%    Constructs a TFOCS-compatible linear operator from the composition of
%    two or more linear operators and/or matrices. That is,
%       OP(x,1) = OP1(OP2(...(OPN(x,1),...,1),1)
%       OP(x,2) = OPN(...(OP2(OP1(x,2),2)...,2)
%    If matrices are supplied, they must be real; to include complex
%    matrices, convert them first to linear operators using LINOP_MATRIX.

if nargin == 0,
    error( 'Not enough input arguments.' );
end
sz = { [], [] };
for k = 1 : nargin,
    tL = varargin{k};
    if isempty(tL) || ~isa(tL,'function_handle') && ~isnumeric(tL) || ndims(tL) > 2,
        error( 'Arguments must be linear operators, scalars, or matrices.' );
    elseif isnumeric(tL),
        if ~isreal(tL),
            error( 'S or scalar arguments must be real.' );
        elseif numel(tL) == 1,
            tL = linop_scale( tL );
        else
            tL = linop_matrix( tL );
        end
        varargin{k} = tL;
    end
    try
        tsz = tL([],0);
    catch
        error( 'Arguments must be linear operators, scalars, or matrices.' );
    end
    if isempty(tsz)     % i.e. output of linop_identity is []
        tsz = { [], [] };
    end
    if isnumeric(tsz),
        tsz = { [tsz(2),1], [tsz(1),1] };
    end
    
    % convert [n1;n2] to [n1,n2] if necessary:
    for kk = 1:2
        %if iscolumn( tsz{kk} )
            %tsz{kk} = tsz{kk}.';
        %end
        tsz{kk} = tsz{kk}(:).';
    end
    
    if ~isempty(sz{1}) && ~isempty(tsz{2}) && ~isequal(tsz{2},sz{1}),
        for kk = 1:min( numel(tsz{2}), numel( sz{1} ) )
            fprintf('Found incompatible sizes: %d ~= %d\n', tsz{2}(kk), sz{1}(kk) );
        end
        error( 'Incompatible dimensions in linear operator composition.' );
    end
    if ~isempty(tsz{1}),
        sz{1} = tsz{1};
    end
    if isempty(sz{2}),
        sz{2} = tsz{2};
    end
end
% Explanation of above code:
% suppose have three inputs, opA, opB, opC; with sizes szA, szB, szC
%   where opA: szA{1} --> szA{2}
%   so we need szC{2} == szB{1} and szB{2} = szA{1}
%
% so  sz{2} = szA{2}
% and sz{1} = szC{1}

if nargin == 1,
    op = varargin{1};
else
    op = @(x,mode)linop_compose_impl( varargin, sz, x, mode );
end

function y = linop_compose_impl( ops, sz, y, mode )
switch mode,
    case 0,
        y = sz;
    case 1,
        for k = numel(ops) : -1 : 1,
            y = ops{k}( y, 1 );
        end
    case 2,
        for k = 1 : numel(ops),
            y = ops{k}( y, 2 );
        end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
