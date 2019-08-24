function v = tfocs_dot( x, y )
% TFOCS_DOT   Dot product <x,y>.  Returns real(x'*y)
%   For matrices, this is the inner product that induces the Frobenius
%   norm, i.e. <x,y> = tr(x'*y), and not matrix multiplication.

% Note: this is real(x'*y) and not real(x.'*y)

if isempty( x ) || isempty( y ),
    v = 0;
    return;
end

% Allow scalar times vector multiplies:
if isscalar(x) && ~isscalar(y)
    if ~x, 
        v = 0; 
        return;
    else
%         x = repmat(x,size(y,1),size(y,2) ); % doesn't work if y is a cell
        % The above code fails if y is multi-dimensional. Also, not 
        % memory efficient. Switching to this (10/9/2013)
        % (Thanks to Graham Coleman for finding this bug, btw)
        if issparse(y)
            v = real( x * sum(nonzeros(y)) );
        else
            v = real( x * sum(y(:)) );
        end
        return;
    end
elseif isscalar(y) && ~isscalar(x)
    if ~y
        v = 0;
        return;
    else
        y = repmat(y,size(x,1),size(x,2) );
        if issparse(x)
            v = real( y * sum(nonzeros(x)) );
        else
            v = real( y * sum(x(:)) );
        end
        return;
        
    end
end

if isreal( x ) || isreal( y ),
    if issparse( x ) || issparse( y ),
        v = sum( nonzeros( real(x) .* real(y) ) );
    else
        % Split this into two cases (first case could be handled by
        % second case, but we're trying to make it very fast since
        % this code is called very often)
        if ndims(x)==2 && ndims(y)==2 && size(x,2) == 1 && size(y,2) == 1 && isreal(x) && isreal(y)
            v = sum( x'*y ); % do we really need 'sum' ?
        else
            % Take real part first (since one of x and y is real anyhow)
            %   in order to save some computation:
            v = real(x(:))' * real(y(:));
        end
    end
else
    if issparse( x ) || issparse( y ),
        v = sum( nonzeros( real(x) .* real(y) ) ) + ...
            sum( nonzeros( imag(x) .* imag(y) ) );
    else
        % SRB: this is very slow:
%         v = sum( real(x(:))' * real(y(:)) ) + ...
%             sum( imag(x(:))' * imag(y(:)) );
        if ndims(x)==2 && ndims(y)==2 && size(x,2) == 1 && size(y,2) == 1
            v = sum(real( x'*y ) );
        else
            % This is the most generic code.
            v = real( x(:)'*y(:) );
        end
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.