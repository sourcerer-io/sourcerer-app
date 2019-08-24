function ans = size_ambig( sz )

switch class( sz ),
    case 'double',
        ans = isempty( sz );
    case 'cell',
        if isa( sz{1}, 'function_handle' ),
            ans = false; % it's not ambiguous as long as it's a valid function...
        elseif isempty( sz ),
            ans = true;
        else
            ans = false;
            for k = 1 : numel( sz ),
                if size_ambig( sz{k} ),
                    ans = true;
                    break;
                end
            end
        end
    otherwise,
        ans = true;
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
