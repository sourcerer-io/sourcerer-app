function [ op, inp_dims, otp_dims ] = linop_stack( linearF, inp_dims, otp_dims, DO_DEBUG )

%LINOP_STACK    Stacked linear operators.
%    OP = LINOP_STACK( linearF ), where linearF is a cell vector or cell
%    matrix, returns a function handle for a linear operator that accepts
%    TFOCS_TUPLE objects as input or output, as appropriate, and applies
%    the various linear operators in block matrix fashion.
%
%    If linearF has more than one row, then the output in its forward mode
%    or its input in adjoint mode is a TFOCS_TUPLE object. If linearF has
%    more than one column, then the output in its adjoint mode or its input
%    in forward mode is a TFOCS_TUPLE object.

if nargin < 4 || isempty(DO_DEBUG), DO_DEBUG = false; end

if ~isa( linearF, 'cell' ),
    error( 'First argument must be a cell array.' );
end
[ m, n ] = size( linearF );
if nargin < 2 || isempty( inp_dims ),
    inp_dims = cell( 1, n );
end
if nargin < 3 || isempty( otp_dims ),
    otp_dims = cell( 1, m );
end
rescan = zeros(2,0);
debugPrintf('----- DEBUG INFO: Size of linear matrix (and offsets) ---- \n');
% debugPrintf('---------------------------------------------------------- \n');
for j = 1 : n, debugPrintf('-----------------------------------+'); end
debugPrintf('\n');
% old_inp_d   = {};
for i = 1 : m,
    otp_d = otp_dims{i};
    for j = 1 : n,
        inp_d = inp_dims{j};
        lF = linearF{i,j};
        sZ = [];
        if isempty(lF),
        elseif isa( lF, 'function_handle' ),
            sZ = lF([],0);
        elseif ~isnumeric( lF ),
            error( 'Entries should be real matrices or linear operators.'  );
        elseif ~isreal(lF),  % Why? we now handle A: C --> C
            error( 'Matrix entries must be real.' );
        elseif numel(lF) > 1,
            sZ = size(lF);
            linearF{i,j} = linop_matrix( lF ); % Jan 2012, check this
        elseif lF == 0,
            linearF{i,j} = [];
        else
            if lF == 1,
%                 linearF{i,j} = @(x,mode)x;
                linearF{i,j} = @linop_identity;
            else
                linearF{i,j} = @(x,mode)lF*x;
            end
            if ~isempty(otp_d),
                sZ = { otp_d, otp_d };
            elseif ~isempty(inp_d),
                sZ = { inp_d, inp_d };
            else
                rescan(:,end+1) = [i;j];
            end
        end
        if isempty( sZ ),
            printSizes( inp_d , otp_d ); % if DO_DEBUG is true, this will print
            if j < n, debugPrintf(' |'); end
            continue;
        elseif isnumeric( sZ ),  % This should never be triggered, unless offset is empty
            % June 2011:
            % If this is the offset term, then we allow for a matrix (rather than vector)
            %   offset, as long as the size of the linear portion has been specified:
            if j == n && j > 1
                sZ_old = linearF{i,j-1}([],0);
                if ~isempty( sZ_old) && all( sZ_old{2} == sZ )
                    % We may have a matrix
                    sZ = { [1,1], sZ };
                    % So, re-define linearF{i,j} not to be linop_matrix but rather the constant function
                else
                    sZ = { [sZ(2),1], [sZ(1),1] };
                end
            else
                sZ = { [sZ(2),1], [sZ(1),1] };
            end
        end
        if isempty(inp_d),
            inp_d = sZ{1};
%         elseif ~isequal(inp_d,sZ{1}) && ~isempty( sZ{1} ) % adding Oct 12. Jan 2012, is this right? inp_d was already defined....
%         elseif ~isempty( old_inp_d ) && ~isempty( sZ{1} ) && ~isequal( old_inp_d, sZ{1} )
%             if j > 1
%                 for jj = 1:(j-1)
%                     sZ_old = linearF{i,jj}([],0);
%                     if isempty( sZ_old )
%                         fprintf( 2, ...
%                             'TFOCS message: About to throw an error: may be because element (%d,%d) of \n',i,jj);
%                         fprintf( 2, ...
%                             '  linear operator matrix does not have an explicit size\n' );
%                     end
%                 end
%             end
%             error( 'Incompatible dimensions in element (%d,%d) of the linear operator matrix', i, j );
        end
        inp_dims{j} = inp_d;
%         if ~isempty( inp_d ), old_inp_d   = inp_d; end
        
        if isempty(otp_d),
            otp_d = sZ{2};
        elseif ~isequal(otp_d,sZ{2}),
            if isequal( fliplr(otp_d), sZ{2} )
                fprintf('\nThe sizes match if you switch some rows/columns. Double-check your offsets are column vectors\n\n');
            end
            error( 'Incompatible dimensions in element (%d,%d) of the linear operator matrix', i, j );
        end

        
        printSizes( inp_d, otp_d ); % if DO_DEBUG is true, this will print
        if j < n, debugPrintf(' |'); end
        
    end
    otp_dims{i} = otp_d;
    
    debugPrintf('\n');
    
end
debugPrintf('---------------------------------------------------------- \n');

%
% In some cases, we cannot resolve the dimensions on the first pass:
% specifically, those entries that represent scalar scaling operations.
% In those cases, we know that the input and output dimensions must be the
% same, but we may not have yet determined either in the first pass. So
% we rescan those entries until all ambiguities are resolved or until no
% further progress is made.
%

while ~isempty(rescan),
    rescan_o = rescan;
    rescan = zeros(2,0);
    for ij = rescan,
        i = ij(1); j = ij(2);
        lF = linearF{i,j};
        if isnumeric(lF) && numel(lF) == 1,
            if isempty(inp_dims{j}),
                if isempty(otp_dims{i}),
                    rescan(:,end+1) = [i;j];
                    continue;
                else
                    inp_dims{j} = otp_dims{i};
                end
            elseif isempty(otp_dims{i}),
                otp_dims{i} = inp_dims{j};
            elseif ~isequal( inp_dims{i}, otp_dims{j} ),
                error( 'Incompatible dimensions in element (%d,%d) of the linear operator matrix', i, j );
            end
            if DO_DEBUG
                fprintf('Affine term (%d,%d) has size:', i, j );
                printSizes( inp_dims{j}, otp_dims{i} );
            end
        end
    end
    % Prevent infinite loops
    if numel(rescan) == numel(rescan_o),
        break;
    end
end
debugPrintf('---------------------------------------------------------- \n');

if m == 1 && n == 1,
    op = linearF{1,1};
    inp_dims = inp_dims{1};
    otp_dims = otp_dims{1};
    if isempty(op),
        op = @linop_identity;
    end
elseif m == 1,
    otp_dims = otp_dims{1};
    op = @(x,mode)linop_stack_row( linearF,  n,    { inp_dims, otp_dims }, x, mode );
elseif n == 1,
    inp_dims = inp_dims{1};
    op = @(x,mode)linop_stack_col( linearF,  m,    { inp_dims, otp_dims }, x, mode );
else
    op = @(x,mode)linop_stack_mat( linearF, [m,n], { inp_dims, otp_dims }, x, mode );
end


% ------- Internal subfunctions ------------
% These functions can see the workspace variables of the main function
function debugPrintf( varargin )
if DO_DEBUG
    fprintf( varargin{:} );
end
end

function printSizes( inp_d, otp_d )
if DO_DEBUG
    % Print size of domain
    if isempty( inp_d )
        fprintf(' (     ?      )');
    else
        if length( inp_d ) == 1, inp_d = [inp_d, 1 ]; end
        fprintf(' (');
        for kk = 1:length(inp_d)-1, fprintf('%4d x ', inp_d(kk) ); end
        fprintf('%4d )', inp_d(end) );
    end
    % Print size of range
    fprintf(' --> ');
    if isempty( otp_d )
        fprintf('(     ?      )');
    else
        if length( otp_d ) == 1, otp_d = [otp_d, 1 ]; end
        fprintf('(');
        for kk = 1:length(otp_d)-1, fprintf('%4d x ', otp_d(kk) ); end
        fprintf('%4d )', otp_d(end) );
    end
end
end


end % end of main program

% ------- External subfunctions ------------
function y = linop_stack_row( linearF, N, dims, x, mode )
switch mode,
    case 0,
        y = dims;
    case 1,
        y = 0;
        x = cell( x );
        for j = 1 : N,
            lF = linearF{j};
            if ~isempty(lF), y = y + lF(x{j},1); end
        end
    case 2,
        y = cell(1,N);
        for j = 1 : N,
            lF = linearF{j};
            if ~isempty(lF), y{j} = lF(x,2); else y{j} = 0*x; end
        end
        y = tfocs_tuple( y );
end
end

function y = linop_stack_col( linearF, N, dims, x, mode )
switch mode,
    case 0,
        y = dims;
    case 1,
        y = cell(1,N);
        for j = 1 : N,
            lF = linearF{j};
            if ~isempty(lF), y{j} = lF(x,1); else y{j} = 0*x; end
        end
        y = tfocs_tuple( y );
    case 2,
        y = 0;
        x = cell( x );
        for j = 1 : N,
            lF = linearF{j};
            if ~isempty(lF), y = y + lF(x{j},2); end
        end
end
end

function y = linop_stack_mat( linearF, sZ, dims, x, mode )
switch mode,
    case 0,
        y = dims;
    case 1,
        x = cell( x );
        y = cell( 1, sZ(1) );
        for i = 1 : sZ(1),
            ans = 0;
            for j = 1 : sZ(2),
                lF = linearF{i,j};
                if ~isempty(lF), ans = ans + lF(x{j},1); end
            end
            y{i} = ans;
        end
        y = tfocs_tuple( y );
    case 2,
        x = cell( x );
        y = cell( 1, sZ(2) );
        for j = 1 : sZ(2),
            ans = 0;
            for i = 1 : sZ(1),
                lF = linearF{i,j};
                if ~isempty(lF), ans = ans + lF(x{i},2); end
            end
            y{j} = ans;
        end
        y = tfocs_tuple( y );
end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
