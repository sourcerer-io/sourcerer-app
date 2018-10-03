function v = tfocs_tuple( w )

% TFOCS_TUPLE The TFOCS tuple object.
%    This object is used to create tuples, which are elements of
%    vector spaces that are Cartesian products of other vector
%    spaces. TFOCS assumes that any element in a tfocs_tuple can
%    perform the following basic operations:
%        --- addition (plus)
%        --- subtraction (minus)
%        --- multiplication by real scalars (times,mtimes)
%        --- dot products (tfocs_dot)
%        --- squared norm (tfocs_normsq, optional)
%        --- size (size; single-argument calls only)

if ~iscell(w) && ~isempty(w)
    error('tfocs_tuple constructor: input must be a cell array');
end
v.value_ = reshape( w, 1, numel(w) );
v = class( v, 'tfocs_tuple' );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

