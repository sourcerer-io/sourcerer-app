function [ a, sX ] = size_compat( sX, sY )
a = true;
switch class( sX ),
    case 'double',
        if isempty( sX ) || all( sX == 0 ),
            sX = sY;
        elseif isempty( sY ) || all( sY == 0 ),
        elseif ~isequal( sX, sY ),
            
            % Feb 29, 2012. Special case:
            %   One represents the size a x b x c, where c = 1
            %   The other is a x b (since Matlab often automatically squeezes
            %   3D arrays to 2D if the 3rd dimension is a singletone)
%             if (length(sX) >= 3 && length(sX) == length(sY)+1 && sX(end)==1) || ...
%                     (length(sY) >= 3 && length(sY) == length(sX)+1 && sY(end)==1)
                % do nothing
            % March 2012, a better fix (also due to Graham Coleman)
            if min( length(sX),length(sY) ) >= 2
                truncA  = cutTrailingOnes(sX);
                truncB  = cutTrailingOnes(sY);
                a = isequal( truncA, truncB );
            else
                a = false;
            end
        end
    case 'cell',
        if ~isa( sY, 'cell' ) || numel( sX ) ~= numel( sY ) || isa( sX{1}, 'function_handle' ) && ~isequal( sX, sY ),
            a = false;
        elseif isa( sX{1}, 'function_handle' ),
            a = isequal( sX, sY );
        else
            for k = 1 : numel( sX ),
                [ ta, sX{k} ] = size_compat( sX{k}, sY{k} );
                a = a && ta;
            end
        end
    otherwise,
        a = isequal( sX, sY );
end
if ~a,
    sX = [];
end

function y = cutTrailingOnes( x )
%cuts the final ones of a vector, and columnize

lastNotOne = find( x(:)~=1, 1, 'last' );

%do not cut before 2nd position
lastNotOne = max( 2, lastNotOne );

y = x(1:lastNotOne);

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

