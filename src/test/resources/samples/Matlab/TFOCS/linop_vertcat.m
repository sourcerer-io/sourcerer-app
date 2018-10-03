function op = linop_vertcat( varargin )
%LINOP_VERTCAT Combines two or more TFOCS lienar operators
%OP = LINOP_VERTCAT( OP1, OP2, ..., OPN )
%    Defines the linear operator
%       OP(x,1) = [OP1(x,1);
%                  ...
%                  OPN(x,1)];
%   which has adjoint
%       OP(x,2) = OP1(x1,2) + ... + OPN(xn,2)
%

% Introduced June 2016

if nargin == 0,
    error( 'Not enough input arguments.' );
end
sz = { [], [] };
sz_x = [];
for k = 1 : nargin,
    tL = varargin{k}; % current linear operator
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
    
    if isempty(tsz{1}),
        error('For now, each operator must have an explicit output size');
    end
    if isempty(sz{1})
        sz{1} = tsz{1};
    else
        % all operators work on the same dimension input
        if ~isequal( tsz{1}, sz{1} )
            error('All operators must have the same size input');
        end
    end
    if isempty(sz{2}),
        sz{2} = tsz{2};
        sz_x(1) = tsz{2}(1);
    else
        % check that others are compatible with # of columns:
        if numel( sz{2} ) ~= numel( tsz{2} ) || ~isequal( tsz{2}(2:end), sz{2}(2:end) )
            error('All operators must have outputs with equal number of columns');
        end
        sz{2}(1) = sz{2}(1) + tsz{2}(1); % increment first dimension only
        sz_x = [sz_x, tsz{2}(1)];
    end
end
% Explanation of above code:
% suppose have three inputs, opA, opB, opC; with sizes szA, szB, szC
%   where opA: szA{1} --> szA{2}
%   then we need sz_{1} to be the same no matter what!
%   Furthermore, output sizes should have same # of columns
%    (preferably a single column, since least chance for errors)



if nargin == 1,
    op = varargin{1};
else
    op = @(x,mode)linop_horzcat_impl( varargin, sz, sz_x, x, mode );
end

function y = linop_horzcat_impl( ops, sz,sz_x, x, mode )
switch mode,
    case 0,
        y = sz;
    case 1,
        y   = [];
        for k = 1:numel(ops)
            y = vertcat( y, ops{k}( x, 1 ) );
        end
    case 2,
        % Need to split input up
        cs = cumsum(sz_x);
        y = ops{1}( x(1:cs(1)), 2 );
        for k = 2 : numel(ops),
            y = y + ops{k}( x( (cs(k-1)+1):cs(k)  ), 2 );
        end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
