function [ xi, R ] = cvx_orthog_structure( xi, clean )

%CVX_ORTHOG_STRUCTURE   Constructs an orthogonal structure matrix.
%    CVX_ORTHOG_STRUCTURE(X), where X is an M x N matrix from CVX's
%    matrix structure facility, determines an orthogonal structure: that
%    is, a matrix Z of size (N-rank(X)) x N such that X * Z' = 0. Roughly
%    speaking, this computes Z = NULL(X,'r')'. However, this should not
%    be used for more general null space computations, because it does not
%    employ sufficiently general numerical safeguards.

% Reduce using an LU factorization with full pivoting.
[LL,xi,pp,qq] = lu(xi,'vector'); %#ok
[m,n] = size(xi); %#ok

xid = diag(xi);
rr = nnz(xid);
if nnz(any(xi,2)) == rr,
    ii = find(xid);
    jj = ii;
else  
    % Find the locations of the leading element in each row. To do this we first
    % find the first element in each row. Transposing xi insures that the
    % indices are sorted properly to accomplish this.
    [ii,jj] = find(xi);
    [ii,indx] = sort(ii);
    dd = [true;diff(ii)~=0];
    ii = ii(dd);
    jj = jj(indx(dd));

    % Sort the rows so that the leftmost nonzero is first. The LU factorization
    % does this already much of the time; but in rank-degenerate cases, further
    % sorting is needed. Use this to select a full-rank triangular submatrix.
    [jj,jndx] = sort(jj);
    dd = [true;diff(jj)~=0];
    ii = ii(jndx(dd));
    jj = jj(dd);

    % Left-divide the full-rank submatrix xi(ii,:) by the full-rank triangle.
    % We actually only need to handle the columns not in the triangle.
    rr = length(ii);
end
j2 = (1:n)'; j2(jj) = [];
Q  = xi(ii,jj) \ xi(ii,j2);

% Use the RAT function to round to a nearby rational number. We know that
% our structure compositions will always have rational results.
[ iq, jq, vv ] = find( Q );
if any( Q ~= round(Q) ),
    [ vn, vd ] = rat( vv );
    vv = vn ./ vd;
end

% This is the reduced row echelon form, returned for debugging purposes only
if nargout > 1,
    R = sparse( [ (1:rr)' ; iq ], qq([ jj ; j2(jq) ]), [ ones(rr,1) ; vv ], rr, n );
end

% For a structure [ I Q ], where I is an identity matrix, the orthogonal
% structure matrix is just [ -Q' I ]. The result of our efforts above is
% a matrix of the form [ I Q ] with its columns scrambled, so we simply
% need to scramble the columns of [ Q' I ] in the same way.

xi = sparse( [ (1:n-rr)' ; jq ], qq([ j2 ; jj(iq) ]), [ ones(n-rr,1) ; - vv ], n - rr, n );

% If we want a clean result, we need to re-sort the rows in order of their
% first column entry.

if nargin == 2 && clean,
    [ii,jj] = find(xi); 
    [ii,indx] = sort(ii);
    dd = [true;diff(ii)~=0];
    ii = ii(dd);
    [jj,jndx] = sort(jj(indx(dd))); %#ok
    xi = xi(ii(jndx),:);
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

    
