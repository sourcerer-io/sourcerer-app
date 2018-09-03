% CVX: Matrix structure definitions and utilities.
%    CVX provides a keyword-based method for definiting matrices
%    with one or more types of structure; e.g.
%        variable X(n,n) symmetric toeplitz tridiagonal;
%    CVX automatically computes an efficient basis for the requested
%    structure. The files in this directory implement those computations.
%
%    None of these files should be called directly---matrix structure is
%    selected in the VARIABLE declaration; see VARIABLE for more details.
%    Below are the keywords that are available, and the structures they
%    represent. Keywords can be freely combined (see the above example),
%    but of course some combinations are degenerate, yielding only the 
%    all-zero matrix; e.g.,
%       variable X(n,n) 
%
% Structures:
%   banded            - (U,L)-banded matrices.
%   complex           - Complex variables of all sizes.
%   diagonal          - Diagonal matrices.
%   hankel            - Hankel matrices.
%   hermitian         - Complex Hermitian matrices.
%   lower_bidiagonal  - Lower bidiagonal matrices.
%   lower_hessenberg  - Lower Hessenberg matrices.
%   lower_triangular  - Lower triangular matrices.
%   scaled_identity   - Scaled identity: t*eye(n).
%   skew_symmetric    - Skew-symmetric matrices.
%   sparse            - Matrices with a fixed sparsity pattern.
%   symmetric         - Symmetric matrices.
%   toeplitz          - Toeplitz matrices.
%   tridiagonal       - Tridiagional matrices.
%   upper_bidiagonal  - Upper bidiagonal matrices.
%   upper_hankel      - Upper Hankel matrices.
%   upper_hessenberg  - Upper Hessenberg matrices.
%   upper_triangular  - Upper triangular matrices.

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
