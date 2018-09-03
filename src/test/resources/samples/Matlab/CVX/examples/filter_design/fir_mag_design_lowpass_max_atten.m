% Maximize stopband attenuation of a lowpass FIR filter (magnitude design)
% "FIR Filter Design via Spectral Factorization and Convex Optimization"
% by S.-P. Wu, S. Boyd, and L. Vandenberghe
% (figures are generated)
%
% Designs an FIR lowpass filter using spectral factorization method where we:
% - minimize maximum stopband attenuation
% - have a constraint on the maximum passband ripple
%
%   minimize   max |H(w)|                      for w in the stopband
%       s.t.   1/delta <= |H(w)| <= delta      for w in the passband
%
% We change variables via spectral factorization method and get:
%
%   minimize   max R(w)                        for w in the stopband
%       s.t.   (1/delta)^2 <= R(w) <= delta^2  for w in the passband
%              R(w) >= 0                       for all w
%
% where R(w) is the squared magnited of the frequency response
% (and the Fourier transform of the autocorrelation coefficients r).
% Variables are coeffients r. delta is the allowed passband ripple.
% This is a convex problem (can be formulated as an LP after sampling).
%
% Written for CVX by Almir Mutapcic 02/02/06

%*********************************************************************
% user's filter specs (for a low-pass filter example)
%*********************************************************************
% number of FIR coefficients (including the zeroth one)
n = 20;

wpass = 0.12*pi;   % end of the passband
wstop = 0.24*pi;   % start of the stopband
delta = 1;         % maximum passband ripple in dB (+/- around 0 dB)

%*********************************************************************
% create optimization parameters
%*********************************************************************
% rule-of-thumb discretization (from Cheney's Approx. Theory book)
m = 15*n;
w = linspace(0,pi,m)'; % omega

% A is the matrix used to compute the power spectrum
% A(w,:) = [1 2*cos(w) 2*cos(2*w) ... 2*cos(n*w)]
A = [ones(m,1) 2*cos(kron(w,[1:n-1]))];

% passband 0 <= w <= w_pass
ind = find((0 <= w) & (w <= wpass));    % passband
Lp  = 10^(-delta/20)*ones(length(ind),1);
Up  = 10^(+delta/20)*ones(length(ind),1);
Ap  = A(ind,:);

% transition band is not constrained (w_pass <= w <= w_stop)

% stopband (w_stop <= w)
ind = find((wstop <= w) & (w <= pi));   % stopband
As  = A(ind,:);

%********************************************************************
% optimization
%********************************************************************
% formulate and solve the magnitude design problem
cvx_begin
  variable r(n,1)

  % this is a feasibility problem
  minimize( max( abs( As*r ) ) )
  subject to
    % passband constraints
    Ap*r >= (Lp.^2);
    Ap*r <= (Up.^2);
    % nonnegative-real constraint for all frequencies (a bit redundant)
    A*r >= 0;
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
end

% compute the spectral factorization
h = spectral_fact(r);

% compute the max attenuation in the stopband (convert to original vars)
Ustop = 10*log10(cvx_optval);
fprintf(1,'The max attenuation in the stopband is %3.2f dB.\n\n',Ustop);

%*********************************************************************
% plotting routines
%*********************************************************************
% frequency response of the designed filter, where j = sqrt(-1)
H = [exp(-j*kron(w,[0:n-1]))]*h;

figure(1)
% FIR impulse response
plot([0:n-1],h','o',[0:n-1],h','b:')
xlabel('t'), ylabel('h(t)')

figure(2)
% magnitude
subplot(2,1,1)
plot(w,20*log10(abs(H)), ...
     [0 wpass],[delta delta],'r--', ...
     [0 wpass],[-delta -delta],'r--', ...
     [wstop pi],[Ustop Ustop],'r--')
xlabel('w')
ylabel('mag H(w) in dB')
axis([0 pi -50 5])
% phase
subplot(2,1,2)
plot(w,angle(H))
axis([0,pi,-pi,pi])
xlabel('w'), ylabel('phase H(w)')
