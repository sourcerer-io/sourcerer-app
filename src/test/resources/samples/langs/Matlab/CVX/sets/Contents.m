% CVX: Definitions of common convex sets.
%   complex_lorentz         - Complex second-order cone.                        {(x,y): norm(x)<=y}
%   convex_poly_coeffs      - Coefficients of convex degree-n polynomials.      {p: p(x) convex}
%   exp_cone                - The exponential cone.                             {(x,y,z): y>=0, y*exp(x/y) <= z }
%   hermitian_semidefinite  - Hermitian positive semidefinite matrices.         {X: X==X', min(eig(X))>=0}
%   lorentz                 - Real second-order cones.                          {(x,y): norm(x)<=y}
%   nonneg_poly_coeffs      - Coefficients of nonnegative degree-n polynomials. {p: p(x)>=0 for all x}
%   nonnegative             - The nonnegative orthant.                          {x: x>=0}
%   norm_ball               - Norm ball.                                        {x: norm(x,p) <= 1}
%   rotated_complex_lorentz - Rotated complex second-order cone.                {(x,y,z): norm(x)^2 <= y*z, y>=0, z>=0 }
%   rotated_lorentz         - Rotated real second-order cone.                   {(x,y,z): norm(x)^2 <= y*z, y>=0, z>=0 }
%   semidefinite            - Real symmetric positive semidefinite matrices     {X: X==X', min(eig(X))>=0}
%   simplex                 - The unit simplex.                                 {x: x>=0, sum(x)==1}

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
