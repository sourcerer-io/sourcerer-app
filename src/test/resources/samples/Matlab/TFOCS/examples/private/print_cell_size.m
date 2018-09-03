function print_cell_size( c , fid, offsetPossible )
% c should be a cell array

if nargin < 2 || isempty(fid), fid = 1; end
if nargin < 3 || isempty(offsetPossible), offsetPossible = false; end

if ~iscell(c)
    fprintf(fid,'\tcomponent 1: ');
%     d = size(c);
    d = c;
    for k = 1:(length(d)-1)
        fprintf(fid,'%4d x ',d(k) );
    end
    fprintf(fid,'%4d\n', d(k+1) );
    fprintf(fid,' (but input to printCellSize should have been a cell array)\n');
    return;
else
    for j = 1:length(c)
        if j == length(c) && offsetPossible && all(size( c{j} ) == [1,2] ) ...
                && all( c{j} == [1,1] )
            fprintf(fid,'\tcomponent %2d is fixed (i.e. an offset)\n', j );
        else
            fprintf(fid,'\tcomponent %2d: ', j );
            if isempty( c{j} )
                fprintf(fid,'size not yet determined\n');
            else
                d = c{j};
                if length(d) < 2, d = [d,1]; end % this case shouldn't arise...
                for k = 1:(length(d)-1)
                    fprintf(fid,'%4d x ',d(k) );
                end
                fprintf(fid,'%4d\n', d(k+1) ); % bug, Feb 29 2012: change d(k) to d(k+1)
            end
        end
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.