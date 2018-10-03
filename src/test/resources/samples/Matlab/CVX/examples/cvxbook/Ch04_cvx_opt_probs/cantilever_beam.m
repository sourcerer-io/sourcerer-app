% Exercise 4.31: Design of a cantilever beam (GP)
% Boyd & Vandenberghe "Convex Optimization"
% Almir Mutapcic - 01/30/06
% Updated to use GP mode 02/08/06
% (a figure is generated)
%
% We have a segmented cantilever beam with N segments. Each segment
% has a unit length and variable width and height (rectangular profile).
% The goal is minimize the total volume of the beam, over all segment
% widths w_i and heights h_i, subject to constraints on aspect ratios,
% maximum allowable stress in the material, vertical deflection y, etc.
%
% The problem can be posed as a geometric program (posynomial form)
%     minimize    sum( w_i* h_i)
%         s.t.    w_min <= w_i <= w_max,       for all i = 1,...,N
%                 h_min <= h_i <= h_max
%                 S_min <= h_i/w_i <= S_max
%                 6*i*F/(w_i*h_i^2) <= sigma_max
%                 6*F/(E*w_i*h_i^3) == d_i
%                 (2*i - 1)*d_i + v_(i+1) <= v_i
%                 (i - 1/3)*d_i + v_(i+1) + y_(i+1) <= y_i
%                 y_1 <= y_max
%
% with variables w_i, h_i, d_i, (i = 1,...,N) and v_i, y_i (i = 1,...,N+1).
% (Consult the book for other definitions and a recursive formulation of
% this problem.)

% optimization variables
N = 8;

% constants
wmin = .1; wmax = 100;
hmin = .1; hmax = 6;
Smin = 1/5; Smax = 5;
sigma_max = 1;
ymax = 10;
E = 1; F = 1;

cvx_begin gp
  % optimization variables
  variables w(N) h(N) v(N+1) y(N+1);

  % objective is the total volume of the beam
  % obj = sum of (widths*heights*lengths) over each section
  % (recall that the length of each segment is set to be 1)
  minimize( w'*h )
  subject to
    % non-recursive formulation
    d = 6*F*ones(N,1)./(E*ones(N,1).*w.*h.^3);
    for i = 1:N
      (2*i-1)*d(i) + v(i+1) <= v(i);
      (i-1/3)*d(i) + v(i+1) + y(i+1) <= y(i);
    end

    % constraint set
    wmin <= w    <= wmax;
    hmin <= h    <= hmax;
    Smin <= h./w <= Smax;
    6*F*[1:N]'./(w.*(h.^2)) <= sigma_max;
    y(1) <= ymax;
cvx_end

% display results
disp('The optimal widths and heights are: ');
w, h
fprintf(1,'The optimal minimum volume of the beam is %3.4f.\n', sum(w.*h))

% plot the 3D model of the optimal cantilever beam
figure, clf
cantilever_beam_plot([h; w])
