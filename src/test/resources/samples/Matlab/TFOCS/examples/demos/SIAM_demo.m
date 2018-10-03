%% RPCA demo using TFOCS
% This is a demo of Robust PCA (RPCA) using <http://tfocs.stanford.edu TFOCS>. Since 2009,
% there has been much interest in this specific RPCA formulation
% (RPCA can refer to many different formulations; we will state
% our formulation precisely below), but most solvers
% assume equality constraints. One great feature of TFOCS
% is how easy it is to prototype new formulations, so we show
% here a formulation using inequality constraints.
% 
% The basic (equality constraint) RPCA formulation is:
% ( see <http://perception.csl.uiuc.edu/matrix-rank/references.html here>
% for references )
%     
% $$ \min_{S,L} \|L\|_* + \lambda \|S\|_{\ell_1} \quad\textrm{subject to}\;L+S = X $$
% 
% The idea is that some object $X$ can be broken into two components $X=L+S$,
% where $L$ is low-rank and $S$ is sparse.  To tease out this separation,
% RPCA penalizes $\|L\|_*$ (the nuclear norm of $L$), which is a proxy for
% the rank of $L$.  We also penalizes $\|S\|_{\ell_1}$ which is just the sum
% of the absolute value of all the entries of the matrix $S$; this is a proxy
% for the number of non-zero entries of $S$.
%
% The parameter $\lambda$ is important, as it controls how much weight
% to put on $S$ relative to $L$.  This parameter is not overly sensitive,
% and we picked the value used in this demo by a few quick rounds of trial-and-error.
%
% _Code by Stephen Becker, May 2011_

%% Inequality constraints
% In this demo, $X$ is a video. In particular, each column of $X$ is the set
% of $m n$ pixels from a $m \times n$ pixel frame of the video, reshaped
% so that it is now a vector instead of a matrix.
%
% The particular video we use is not compressed using a video codec, so
% each frame of the video is stored. This leads to huge files, so to save
% a bit of space, the value of each pixel is stored as an 8 bit number,
% which means we can think of it as a value from $0,1,2,\ldots,255$.  Now,
% we may imagine that there is some "true" video where each pixel
% is a _real_ number between $[0,255]$, and that we see a quantized version of it.
% It would be nice to apply RPCA to this true version instead of applying 
% it to the quantized version.  In particular, it is unlikely that the quantized
% version can be split nicely into a low-rank and sparse component.
% To account for this quantization, we will ask that $S+L$ is not exactly equal
% to $X$, but rather that $S+L$ agrees with $X$ up to the precision
% of the quantization.  The quantization can induce at most an error of .5 in
% the pixel value (e.g. true value is 5.6, which is rounded to 6.0, so an error of .4;
% or a true value of 6.4, which is also rounded to 6.0, so also an error of 0.4).
% A nice way to capture this is via the $\ell_\infty$ norm.
%
% So, the inequality constrained version of RPCA uses the same objective
% function, but instead of the constraints $L+S=X$, the constraints are
%
% $$ \|L+S-X\|_{\ell_\infty} \le 0.5. $$

%% Numerical demo
% We demonstrate this on a video clip taken from a surveillance
% camera in a subway station.  Not only is there a background
% and a foreground (i.e. people), but there is an escalator
% with periodic motion.  Conventional background subtraction
% algorithms would have difficulty with the escalator, but 
% this RPCA formulation easily captures it as part of the low-rank
%   structure.
% The clip is taken from the data at this website (after
% a bit of processing to convert it to grayscale):
% http://perception.i2r.a-star.edu.sg/bk_model/bk_index.html

% Load the data:
disp('Please download the escalator_data.m (3.7 MB) file from:')
disp('  http://cvxr.com/tfocs/demos/rpca/escalator_data.mat');
load escalator_data % contains X (data), m and n (height and width)
X = double(X);

% addpath ~/Dropbox/TFOCS/   % add TFOCS to your path, so change this to suit your computer


%%
nFrames     = size(X,2);

lambda  = 1e-2;

opts = [];
opts.stopCrit       = 4;
opts.printEvery     = 1;
opts.tol            = 1e-4;

opts.maxIts         = 25;

opts.errFcn{1}      = @(f,d,p) norm(p{1}+p{2}-X,'fro')/norm(X,'fro');

largescale      = false;

for inequality_constraints = 0:1

    
    if inequality_constraints
        % if we already have equality constraint solution,
        %   it would make sense to "warm-start":
%         x0      = { LL_0, SS_0 };
        % but it's more fair to start all over:
        x0      = { X, zeros(size(X))   };
        z0      = [];
    else
        x0      = { X, zeros(size(X))   };
        z0      = [];
    end
    
    
    obj    = { prox_nuclear(1,largescale), prox_l1(lambda) };
    affine = { 1, 1, -X };
    
    mu = 1e-4;
    if inequality_constraints
        epsilon  = 0.5;
        dualProx = prox_l1(epsilon);
    else
        dualProx = proj_Rn;
    end
    
    tic
    % call the TFOCS solver:
    [x,out,optsOut] = tfocs_SCD( obj, affine, dualProx, mu, x0, z0, opts);
    toc
    
    % save the variables
    LL =x{1};
    SS =x{2};
    if ~inequality_constraints
        z0      = out.dual;
        LL_0    = LL;
        SS_0    = SS;
    end
    
end % end loop over "inequality_constriants" variable

%% show all together in movie format
% If you run this in your own computer, you can see the movie. On the webpage,
%   we have a youtube version of the video.
% The top row is using equality constraints, and the bottom row
% is using inequality constraints.
%  The first column of both rows is the same (i.e. it is the original image).
mat  = @(x) reshape( x, m, n );
figure();
colormap( 'Gray' );
k = 1;
for k = 1:nFrames
    
    imagesc( [mat(X(:,k)), mat(LL_0(:,k)),  mat(SS_0(:,k)); ...
              mat(X(:,k)), mat(LL(:,k)),    mat(SS(:,k))  ] );
  
    axis off
    axis image
    
    drawnow;
    pause(.05); 
    
    if k == round(nFrames/2)
        snapnow; % Take a single still snapshot for publishing the m file to html format
    end
end

%% Is there a difference between the two versions?
% Compare the equality constrained version and the inequality
%   constrained version.  To do this, we can check whether
%   the "L" components are really low rank
%   and whether the "S" components are really sparse.
% Even if the two versions appear visually similar, the variables
%   may behave quite differently with respect to low-rankness
%   and sparsity.

fprintf('"S" from equality constrained version has  \t%.1f%% nonzero entries\n',...
    100*nnz(SS_0)/numel(SS_0) );
fprintf('"S" from inequality constrained version has  \t%.1f%% nonzero entries\n',...
    100*nnz(SS)/numel(SS) );

s  = svd(LL);    % inequality constraints
s0 = svd(LL_0);  % equality constraints

fprintf('"L" from equality constrained version has numerical rank\t %d (of %d possible)\n',...
    sum( s0>1e-6), min( m*n, nFrames)  );
fprintf('"L" from inequality constrained version has numerical rank\t %d (of %d possible)\n',...
    sum( s > 1e-6), min( m*n, nFrames)  );

figure();
semilogy( s0 ,'o-') 
hold all;
semilogy( s ,'o-')
legend('Equality constraints','Inequality constraints');
xlabel('sorted singular value location');
ylabel('value of singular value');
title('Comparison of RPCA using equality and inequality constraints');

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

