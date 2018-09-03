% FDLA and FMMC solutions for an 8-node, 13-edge graph
% S. Boyd, et. al., "Convex Optimization of Graph Laplacian Eigenvalues"
% ICM'06 talk examples (www.stanford.edu/~boyd/cvx_opt_graph_lapl_eigs.html)
% Written for CVX by Almir Mutapcic 08/29/06
% (figures are generated)
%
% In this example we consider a graph described by the incidence matrix A.
% Each edge has a weight W_i, and we optimize various functions of the
% edge weights as described in the referenced paper; in particular,
%
% - the fastest distributed linear averaging (FDLA) problem (fdla.m)
% - the fastest mixing Markov chain (FMMC) problem (fmmc.m)
%
% Then we compare these solutions to the heuristics listed below:
%
% - maximum-degree heuristic (max_deg.m)
% - constant weights that yield fastest averaging (best_const.m)
% - Metropolis-Hastings heuristic (mh.m)

% small example (incidence matrix A)
A = [ 1  0  0  1  0  0  0  0  0  0  0  0  0;
     -1  1  0  0  1  1  0  0  0  0  0  0  1;
      0 -1  1  0  0  0  0  0 -1  0  0  0  0;
      0  0 -1  0  0 -1  0  0  0 -1  0  0  0;
      0  0  0 -1  0  0 -1  1  0  0  0  0  0;
      0  0  0  0  0  0  1  0  0  0  1  0  0;
      0  0  0  0  0  0  0 -1  1  0 -1  1 -1;
      0  0  0  0 -1  0  0  0  0  1  0 -1  0];

% x and y locations of the graph nodes
xy = [ 1 2   3 3 1 1 2   3 ; ...
       3 2.5 3 2 2 1 1.5 1 ]';

% Compute edge weights: some optimal, some based on heuristics
[n,m] = size(A);

[ w_fdla, rho_fdla ] = fdla(A);
[ w_fmmc, rho_fmmc ] = fmmc(A);
[ w_md,   rho_md   ] = max_deg(A);
[ w_bc,   rho_bc   ] = best_const(A);
[ w_mh,   rho_mh   ] = mh(A);

tau_fdla = 1/log(1/rho_fdla);
tau_fmmc = 1/log(1/rho_fmmc);
tau_md   = 1/log(1/rho_md);
tau_bc   = 1/log(1/rho_bc);
tau_mh   = 1/log(1/rho_mh);

fprintf(1,'\nResults:\n');
fprintf(1,'FDLA weights:\t\t rho = %5.4f \t tau = %5.4f\n',rho_fdla,tau_fdla);
fprintf(1,'FMMC weights:\t\t rho = %5.4f \t tau = %5.4f\n',rho_fmmc,tau_fmmc);
fprintf(1,'M-H weights:\t\t rho = %5.4f \t tau = %5.4f\n',rho_mh,tau_mh);
fprintf(1,'MAX_DEG weights:\t rho = %5.4f \t tau = %5.4f\n',rho_md,tau_md);
fprintf(1,'BEST_CONST weights:\t rho = %5.4f \t tau = %5.4f\n',rho_bc,tau_bc);

% Plot results
figure(1), clf
plotgraph(A,xy,w_fdla);
text(0.55,1.05,'FDLA optimal weights')

figure(2), clf
plotgraph(A,xy,w_fmmc);
text(0.55,1.05,'FMMC optimal weights')

figure(3), clf
plotgraph(A,xy,w_md);
text(0.5,1.05,'Max degree optimal weights')

figure(4), clf
plotgraph(A,xy,w_bc);
text(0.5,1.05,'Best constant optimal weights')

figure(5), clf
plotgraph(A,xy,w_mh);
text(0.46,1.05,'Metropolis-Hastings optimal weights')
