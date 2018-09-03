%% Matrix completion demo
% This short demo shows how to use TFOCS to perform nuclear norm minimization.
% Nuclear norm minimization is used for recovering all the entries of 
% a partially observed low-rank matrix.

%% Setup a problem
rng(234923);    % for reproducible results
N   = 16;       % the matrix is N x N
r   = 2;        % the rank of the matrix
df  = 2*N*r - r^2;  % degrees of freedom of a N x N rank r matrix
nSamples    = 3*df; % number of observed entries

% For this demo, we will use a matrix with integer entries
% because it will make displaying the matrix easier.
iMax    = 5;
X       = randi(iMax,N,r)*randi(iMax,r,N); % Our target matrix

%%
% Now suppose we only see a few entries of X. Let "Omega" be the set
% of observed entries
rPerm   = randperm(N^2); % use "randsample" if you have the stats toolbox
omega   = sort( rPerm(1:nSamples) );

%%
% Print out the observed matrix in a nice format.
% The "NaN" entries represent unobserved values. The goal
% of this demo is to find out what those values are!

Y = nan(N);
Y(omega) = X(omega);
disp('The "NaN" entries represent unobserved values');
disp(Y)

%% Matrix completion via TFOCS
% We use nuclear norm relaxation.  There are strong theorems that
% show this relaxation will usually give you the *exact* original low-rank
% matrix provided that certain conditions hold. However, these
% conditions are generally not possible to check 'a priori',
% so I cannot guarantee that this will work. But by choosing
% enough measurements, it becomes increasingly likely to work.

% Add TFOCS to your path (modify this line appropriately):
addpath ~/Dropbox/TFOCS/

observations = X(omega);    % the observed entries
mu           = .001;        % smoothing parameter

% The solver runs in seconds
tic
Xk = solver_sNuclearBP( {N,N,omega}, observations, mu );
toc

%%
% To display the recovered matrix, let's round it to the nearest
% .0001 so that it displays nicely:
disp('Recovered matrix (rounding to nearest .0001):')
disp( round(Xk*10000)/10000 )

% and for reference, here is the original matrix:
disp('Original matrix:')
disp( X )

% The relative error (without the rounding) is quite low:
fprintf('Relative error, no rounding: %.8f%%\n', norm(X-Xk,'fro')/norm(X,'fro')*100 );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

