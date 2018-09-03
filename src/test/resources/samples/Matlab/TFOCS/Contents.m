% TFOCS: Templates for First-Order Conic Solvers
% TFOCS v1.3 
%10-Oct-2013
%
% Main TFOCS program
%   tfocs                          - Minimize a convex problem using a first-order algorithm.
%   tfocs_SCD                      - Smoothed conic dual form of TFOCS, for problems with non-trivial linear operators.
%   continuation                   - Meta-wrapper to run TFOCS_SCD in continuation mode.
% Miscellaneous functions
%   tfocs_version                  - Version information.
%   tfocs_where                    - Returns the location of the TFOCS system.
% Operator calculus
%   linop_adjoint                  - Computes the adjoint operator of a TFOCS linear operator
%   linop_compose                  - Composes two TFOCS linear operators
%   linop_scale                    - Scaling linear operator.
%   prox_dualize                   - Define a proximity function by its dual
%   prox_scale                     - Scaling a proximity/projection function.
%   tfunc_scale                    - Scaling a function.
%   tfunc_sum                      - Sum of functions.
%   tfocs_normsq                   - Squared norm. 
%   linop_normest                  - Estimates the operator norm.
% Linear operators
%   linop_matrix                   - Linear operator, assembled from a matrix.
%   linop_dot                      - Linear operator formed from a dot product.
%   linop_fft                      - Fast Fourier transform linear operator.
%   linop_TV                       - 2D Total-Variation (TV) linear operator.
%   linop_TV3D                     - 3D Total-Variation (TV) linear operator.
%   linop_handles                  - Linear operator from user-supplied function handles.
%   linop_spot                     - Linear operator, assembled from a SPOT operator.
%   linop_reshape                  - Linear operator to perform reshaping of matrices.
%   linop_subsample                - Subsampling linear operator.
%   linop_vec                      - Matrix to vector reshape operator
% Projection operators (proximity operators for indicator functions)
%   proj_0                         - Projection onto the set {0}
%   proj_box                       - Projection onto box constraints.
%   proj_l1                        - Projection onto the scaled 1-norm ball.
%   proj_l2                        - Projection onto the scaled 2-norm ball.
%   proj_linf                      - Projection onto the scaled infinity norm ball.
%   proj_linfl2                    - Projection of each row of a matrix onto the scaled 2-norm ball.
%   proj_max                       - Projection onto the scaled set of vectors with max entry less than 1
%   proj_conic                     - Projection onto the second order (aka Lorentz) cone
%   proj_l2group                   - Projection of each group of coordinates onto the 2-norm ball.
%   proj_singleAffine              - Projection onto a single affine equality or in-equality constraint.
%   proj_boxAffine                 - Projection onto a single affine equality along with box constraints.
%   proj_affine                    - Projection onto a general affine equation, e.g., solutions of linear equations.
%   proj_nuclear                   - Projection onto the set of matrices with nuclear norm less than or equal to q.
%   proj_psd                       - Projection onto the positive semidefinite cone.
%   proj_psdUTrace                 - Projection onto the positive semidefinite cone with fixed trace.
%   proj_Rn                        - "Projection" onto the entire space.
%   proj_Rplus                     - Projection onto the nonnegative orthant.
%   proj_simplex                   - Projection onto the simplex.
%   proj_spectral                  - Projection onto the set of matrices with spectral norm less than or equal to q
%   proj_maxEig                    - Projection onto the set of symmetric matrices with maximum eigenvalue less than 1
% Proximity operators of general convex functions
%   prox_0                         - The zero proximity function:
%   prox_boxDual                   - Dual function of box indicator function { l <= x <= u }
%   prox_hinge                     - Hinge-loss function.
%   prox_hingeDual                 - Dual function of the Hinge-loss function.
%   prox_l1                        - L1 norm.
%   prox_Sl1                       - Sorted (aka ordered) L1 norm.
%   prox_l1l2                      - L1-L2 block norm: sum of L2 norms of rows.
%   prox_l1linf                    - L1-LInf block norm: sum of L2 norms of rows.
%   prox_l1pos                     - L1 norm, restricted to x >= 0
%   prox_l2                        - L2 norm.
%   prox_linf                      - L-infinity norm.
%   prox_max                       - Maximum function.
%   prox_nuclear                   - Nuclear norm.
%   prox_spectral                  - Spectral norm, i.e. max singular value.
%   prox_maxEig                    - Maximum eigenvalue of a symmetri matrix.
%   prox_trace                     - Nuclear norm, for positive semidefinite matrices. Equivalent to trace.
% Smooth functions
%   smooth_constant                - Constant function generation.
%   smooth_entropy                 - The entropy function -sum( x_i log(x_i) )
%   smooth_handles                 - Smooth function from separate f/g handles.
%   smooth_huber                   - Huber function generation.
%   smooth_linear                  - Linear function generation.
%   smooth_logdet                  - The -log( det( X ) ) function.
%   smooth_logLLogistic            - Log-likelihood function of a logistic: sum_i( y_i mu_i - log( 1+exp(mu_i) ) )
%   smooth_logLPoisson             - Log-likelihood of a Poisson: sum_i (-lambda_i + x_i * log( lambda_i) )
%   smooth_logsumexp               - The function log(sum(exp(x)))
%   smooth_quad                    - Quadratic function generation.
% Testing functions
%   test_nonsmooth                 - Runs diagnostic tests to ensure a non-smooth function conforms to TFOCS conventions
%   test_proxPair                  - Runs diagnostics on a pair of functions to check if they are Legendre conjugates.
%   test_smooth                    - Runs diagnostic checks on a TFOCS smooth function object.
%   linop_test                     - Performs an adjoint test on a linear operator.
% Premade solvers for specific problems (vector variables)
%   solver_L1RLS                   - l1-regularized least squares problem, sometimes called the LASSO.
%   solver_LASSO                   - Minimize residual subject to l1-norm constraints.
%   solver_SLOPE                   - Sorted L One Penalized Estimation (LASSO using sorted/ordered l1 norm)
%   solver_sBP                     - Basis pursuit (l1-norm with equality constraints). Uses smoothing.
%   solver_sBPDN                   - Basis pursuit de-noising. BP with relaxed constraints. Uses smoothing.
%   solver_sBPDN_W                 - Weighted BPDN problem. Uses smoothing.
%   solver_sBPDN_WW                - BPDN with two separate (weighted) l1-norm terms. Uses smoothing.
%   solver_sDantzig                - Dantzig selector problem. Uses smoothing.
%   solver_sDantzig_W              - Weighted Dantzig selector problem. Uses smoothing.
%   solver_sLP                     - Generic linear programming in standard form. Uses smoothing.
%   solver_sLP_box                 - Generic linear programming with box constraints. Uses smoothing.
% Premade solvers for specific problems (matrix variables)
%   solver_psdComp                 - Matrix completion for PSD matrices.
%   solver_psdCompConstrainedTrace - Matrix completion with constrained trace, for PSD matrices.
%   solver_TraceLS                 - Unconstrained form of trace-regularized least-squares problem.
%   solver_sNuclearBP              - Nuclear norm basis pursuit problem (i.e. matrix completion). Uses smoothing.
%   solver_sNuclearBPDN            - Nuclear norm basis pursuit problem with relaxed constraints. Uses smoothing.
%   solver_sSDP                    - Generic semi-definite programs (SDP). Uses smoothing.
%   solver_sLMI                    - Generic linear matrix inequality problems (LMI is the dual of a SDP). Uses smoothing.
% Algorithm variants
%   tfocs_AT                       - Auslender and Teboulle's accelerated method.
%   tfocs_GRA                      - Gradient descent.
%   tfocs_LLM                      - Lan, Lu and Monteiro's accelerated method.
%   tfocs_N07                      - Nesterov's 2007 accelerated method.
%   tfocs_N83                      - Nesterov's 1983 accelerated method; also by Beck and Teboulle 2005 (FISTA).
%   tfocs_TS                       - Tseng's modification of Nesterov's 2007 method.
