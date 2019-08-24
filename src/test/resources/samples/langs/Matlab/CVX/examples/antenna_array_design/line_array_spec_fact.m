% Minimize sidelobe level of a uniform linear array via spectral factorization
% "FIR Filter Design via Spectral Factorization and Convex Optimization" example
% by S.-P. Wu, S. Boyd, and L. Vandenberghe
% (figures are generated)
%
% Designs a uniform linear antenna array using spectral factorization method where:
% - it minimizes sidelobe level outside the beamwidth of the pattern
% - it has a constraint on the maximum ripple around unit gain in the beamwidth
%
%   minimize   max |y(theta)|                   for theta in the stop-beamwidth
%       s.t.   1/delta <= |y(theta)| <= delta   for theta in the pass-beamwidth
%
% We first replace the look-angle variable theta with the "frequency"
% variable omega, defined by omega = -2*pi*d/lambda*cos(theta).
% This transforms the antenna pattern y(theta) into a standard discrete
% Fourier transform of array weights w. Then we apply another change of
% variables: we replace w with its auto-correlation coefficients r.
%
% Now the problem can be solved via spectral factorization approach:
%
%   minimize   max R(omega)                        for omega in the stopband
%       s.t.   (1/delta)^2 <= R(omega) <= delta^2  for omega in the passband
%              R(omega) >= 0                       for all omega
%
% where R(omega) is the squared magnitude of the y(theta) array response
% (and the Fourier transform of the autocorrelation coefficients r).
% Variables are coefficients r. delta is the allowed passband ripple.
% This is a convex problem (can be formulated as an LP after sampling).
%
% Written for CVX by Almir Mutapcic 02/02/06

%********************************************************************
% problem specs: a uniform line array with inter-element spacing d
%                antenna element locations are at d*[0:n-1]
%                (the array pattern will be symmetric around origin)
%********************************************************************
n = 20;               % number of antenna elements
lambda = 1;           % wavelength
d = 0.45*lambda;      % inter-element spacing

% passband direction from 30 to 60 degrees (30 degrees bandwidth)
% transition band is 15 degrees on both sides of the passband
theta_pass = 40;
theta_stop = 50;

% passband max allowed ripple
ripple = 0.1; % in dB (+/- around the unit gain)

%********************************************************************
% construct optimization data
%********************************************************************
% number of frequency samples
m = 30*n;

% convert passband and stopband angles into omega frequencies
omega_zero = -2*pi*d/lambda;
omega_pass = -2*pi*d/lambda*cos(theta_pass*pi/180);
omega_stop = -2*pi*d/lambda*cos(theta_stop*pi/180);
omega_pi   = +2*pi*d/lambda;

% build matrix A that relates R(omega) and r, ie, R = A*r
omega = linspace(-pi,pi,m)';
A = exp( -j*omega(:)*[1-n:n-1] );

% passband constraint matrix
Ap = A(omega >= omega_zero & omega <= omega_pass,:);

% stopband constraint matrix
As = A(omega >= omega_stop & omega <= omega_pi,:);

%********************************************************************
% formulate and solve the magnitude design problem
%********************************************************************
cvx_begin
  variable r(2*n-1,1) complex
  % minimize stopband attenuation
  minimize( max( real( As*r ) ) )
  subject to
    % passband ripple constraints
    (10^(-ripple/20))^2 <= real( Ap*r ) <= (10^(+ripple/20))^2;
    % nonnegative-real constraint for all frequencies
    % a bit redundant: the passband frequencies are already constrained
    real( A*r ) >= 0;
    % auto-correlation symmetry constraints
    imag(r(n)) == 0;
    r(n-1:-1:1) == conj(r(n+1:end));
cvx_end

% check if problem was successfully solved
if ~strfind(cvx_status,'Solved')
    return
end

% find antenna weights by computing the spectral factorization
w = spectral_fact(r);

% divided by 2 since this is in PSD domain
min_sidelobe_level = 10*log10( cvx_optval );
fprintf(1,'The minimum sidelobe level is %3.2f dB.\n\n',...
          min_sidelobe_level);

%********************************************************************
% plots
%********************************************************************
% build matrix G that relates y(theta) and w, ie, y = G*w
theta = [-180:180]';
G = kron( cos(pi*theta/180), [0:n-1] );
G = exp(2*pi*i*d/lambda*G);
y = G*w;

% plot array pattern
figure(1), clf
ymin = -40; ymax = 5;
plot([-180:180], 20*log10(abs(y)), ...
     [theta_stop theta_stop],[ymin ymax],'r--',...
     [-theta_pass -theta_pass],[ymin ymax],'r--',...
     [-theta_stop -theta_stop],[ymin ymax],'r--',...
     [theta_pass theta_pass],[ymin ymax],'r--');
xlabel('look angle'), ylabel('mag y(theta) in dB');
axis([-180 180 ymin ymax]);

% polar plot
figure(2), clf
zerodB = 50;
dBY = 20*log10(abs(y)) + zerodB;
plot(dBY.*cos(pi*theta/180), dBY.*sin(pi*theta/180), '-');
axis([-zerodB zerodB -zerodB zerodB]), axis('off'), axis('square')
hold on
plot(zerodB*cos(pi*theta/180),zerodB*sin(pi*theta/180),'k:') % 0 dB
plot( (min_sidelobe_level + zerodB)*cos(pi*theta/180), ...
      (min_sidelobe_level + zerodB)*sin(pi*theta/180),'k:')  % min level
text(-zerodB,0,'0 dB')
text(-(min_sidelobe_level + zerodB),0,sprintf('%0.1f dB',min_sidelobe_level));
plot([0 60*cos(theta_pass*pi/180)], [0 60*sin(theta_pass*pi/180)], 'k:')
plot([0 60*cos(-theta_pass*pi/180)],[0 60*sin(-theta_pass*pi/180)],'k:')
plot([0 60*cos(theta_stop*pi/180)], [0 60*sin(theta_stop*pi/180)], 'k:')
plot([0 60*cos(-theta_stop*pi/180)],[0 60*sin(-theta_stop*pi/180)],'k:')
hold off
