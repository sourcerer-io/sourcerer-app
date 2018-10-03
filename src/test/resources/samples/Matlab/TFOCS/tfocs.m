function varargout = tfocs( smoothF, affineF, projectorF, x0, opts )
% TFOCS Minimize a convex problem using a first-order algorithm.
% [ x, out, opts ] = tfocs( smoothF, affineF, projectorF, x0, opts )
%     Minimizes or maximizes a smooth or composite function using one of
%     the TFOCS first-order algorithms. The nominal standard form that
%     TFOCS handles is this:
%         minimize smoothF(affineF(x))+projectorF(x)
%     The affineF and projectorF functions are optional; specifically, they
%     may be omitted by suppling an empty array [] in their place. Thus
%     TFOCS supports standard forms such as
%         minimize smoothF(affineF(x))
%         minimize smoothF(x) + projectorF(x)
%         minimize smoothF(x)
%     A variety of more advanced standard forms are supported, but only
%     this simple form is discussed here. See the TFOCS user guide for
%     more information on these advanced forms; see also TFOCS_SCD.
%
% FUNCTIONS:
%    smoothF is expected to operate as follows:
%       [ fx, gx ] = smoothF( x )
%       fx: the value of the smooth function at x
%       gx: the gradient of the smooth function at x
%       TFOCS only asks for the gradient if it needs it, so if they are
%       significantly more expensive to compute, you should optimize
%       your function for the 'nargout==1' case.
%
%    affineF may take one of many forms:
%       [] (empty): represents affineF(x) = x.
%       A, where A is a matrix: represents affineF(x) = A*x.
%       A, where A is a linear operator function obeying SPARCO conventions:
%           y = A(x,0) or y = A([],0) returns the size of A.
%           y = A(x,1) returns the forward operation applied to x.
%           y = A(x,2) returns the adjoint operation applied to x.
%       { A, b }, where A is either a matrix or linear operator and b
%       is a matrix, adds the offset b to the forward operation.
%    As mentioned above, affineF is optional. However, if the computational
%    cost of evaluating your objective is dominated by an affine operation,
%    it is worthwhile to provide it separately, as TFOCS orders its
%    calculations to reduce the number of times it will be called.
%
%    projectorF is the most complex, and has two modes of operation.
%       Cx = projectorF( x )
%           Returns the value of the prox function at x. Note that no
%           projection is taking place, so in many cases this should be
%           a relatively simple calculation.
%       [ Cz, z ] = projectorF( x, t )
%           Computes the minimizer 
%              z = argmin_z projectorF(z) + 1/(2*t)*\|x-y\|^2
%           The norm is Euclidean: \|z\| = <z,z>^{1/2}.
%
% OTHER INPUTS:
%   x0: a feasible initial point
%   opts: a structure containing further options. Please consult the TFOCS
%         user guide for full details, but key entries include:
%       opts.alg          the algorithm to use; e.g., 'AT', 'LLM', etc.
%       opts.maxIts       max number of iterations
%       opts.maxCounts    max number of counts
%       opts.tol          tolerance for convergence: relative step length
%       opts.printEvery   displays output every 'printEvery' iteration
%       opts.maxmin       +1 to minimize (default), -1 to maximize
%   Calling the function with no arguments displays the default values of
%   opts, and returns that default structure in the third output.
%
% OUTPUTS
%   x       optimal point, up to the tolerance
%   out     contains extra information collected during the run
%   opts    structure containing the options used

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% User has requested viewing the default values of "opts"
if nargin == 0 || ( nargin==1 && isstruct(smoothF) )
    if nargout == 0
        tfocs_initialize;
    else
%         opts = tfocs_AT();
        tfocs_initialize;
        opts.alg = 'AT';
        varargout{1} = opts;
    end
    return
elseif nargin == 1 && ischar(smoothF) && ...
    (strcmpi(smoothF,'v') || strcmpi(smoothF,'version') ...
    || strcmpi(smoothF,'-v') || strcmpi(smoothF,'-version') )
    % Display version information
%     type version.txt 
    disp('TFOCS v1.3, October 2013');
    return
end


error(nargchk(1,5,nargin));
if nargin < 2, affineF = []; end
if nargin < 3, projectorF = []; end
if nargin < 4, x0 = []; end
if nargin < 5, opts = []; end
if ~isfield( opts, 'alg' ), 
    alg = 'AT';
else
    alg = upper( opts.alg );
end

if isnumeric(affineF) && ~isempty(affineF)
    affineF = {affineF};
end

[ varargout{1:max(nargout,1)} ] = feval( [ 'tfocs_', alg ], smoothF, affineF, projectorF, x0, opts );
if nargout > 2,
    varargout{3}.alg = alg;
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
