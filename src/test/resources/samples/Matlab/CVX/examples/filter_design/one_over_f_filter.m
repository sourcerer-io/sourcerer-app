% Design a 1/f spectrum shaping (pink-noise) filter
% "Filter design" lecture notes (EE364) by S. Boyd
% "FIR filter design via spectral factorization and convex optimization"
% by S.-P. Wu, S. Boyd, and L. Vandenberghe
% (a figure is generated)
%
% Designs a log-Chebychev filter magnitude design given as:
%
%   minimize   max| log|H(w)| - log D(w) |   for w in [0,pi]
%
% where variables are impulse response coefficients h, and data
% is the desired frequency response magnitude D(w).
%
% We can express and solve the log-Chebychev problem above as
%
%   minimize   max( R(w)/D(w)^2, D(w)^2/R(w) )
%       s.t.   R(w) = |H(w)|^2   for w in [0,pi]
%
% where we now use the auto-correlation coeffients r as variables. 
%
% As an example we consider the 1/sqrt(w) spectrum shaping filter
% (the so-called pink-noise filter) where D(w) = 1/sqrt(w).
% Here we use a logarithmically sampled freq range w = [0.01*pi,pi].
%
% Written for CVX by Almir Mutapcic 02/02/06

% parameters
n = 40;      % filter order
m = 15*n;    % frequency discretization (rule-of-thumb)

% log-space frequency specification
wa = 0.01*pi; wb = pi;
wl = logspace(log10(wa),log10(wb),m)';

% desired frequency response (pink-noise filter)
D = 1./sqrt(wl);

% matrix of cosines to compute the power spectrum
Al = [ones(m,1) 2*cos(kron(wl,[1:n-1]))];

% solve the problem using cvx
cvx_begin
  variable r(n,1)   % auto-correlation coefficients
  variable R(m,1)   % power spectrum

  % log-chebychev minimax design
  minimize( max( max( [R./(D.^2)  (D.^2).*inv_pos(R)]' ) ) )
  subject to
     % power spectrum constraint
     R == Al*r;
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
end

% spectral factorization
h = spectral_fact(r);

% figures
figure(1)
H = exp(-j*kron(wl,[0:n-1]))*h;
loglog(wl,abs(H),wl,D,'r--')
set(gca,'XLim',[wa pi])
xlabel('freq w')
ylabel('mag H(w) and D(w)')
legend('optimized','desired')
