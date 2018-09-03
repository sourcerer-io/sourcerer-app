% Minimize sidelobe level of an FIR broadband far-field antenna array
% "Antenna array pattern synthesis via convex optimization"
% by H. Lebret and S. Boyd
% (figures are generated)
%
% Designs a broadband antenna array with the far-field wave model such that:
% - it minimizes sidelobe level outside the beamwidth of the pattern
% - it has a unit sensitivity at some target direction and for some frequencies
%
% This is a convex problem (after sampling it can be formulated as an SOCP).
%
%   minimize   max |y(theta,f)|        for theta,f outside the desired region
%       s.t.   y(theta_tar,f_tar) = 1
%
% where y is the antenna array gain pattern (complex function) and
% variables are w (antenna array weights or shading coefficients).
% Gain pattern is a linear function of w: y(theta,f) = w'*a(theta,f)
% for some a(theta,f) describing antenna array configuration and specs.
%
% Written for CVX by Almir Mutapcic 02/02/06

% select array geometry
ARRAY_GEOMETRY = '2D_UNIFORM_LATTICE';
% ARRAY_GEOMETRY = '2D_RANDOM';

%********************************************************************
% problem specs
%********************************************************************
P = 2;                % number of filter taps at each antenna element
fs = 8000;            % sampling rate = 8000 Hz
T = 1/fs;             % sampling spacing
c = 2000;             % wave speed

theta_tar = 70;       % target direction
half_beamwidth = 10;  % half beamwidth around the target direction
f_low  = 1500;        % low frequency bound for the desired band
f_high = 2000;        % high frequency bound for the desired band

%********************************************************************
% random array of n antenna elements
%********************************************************************
if strcmp( ARRAY_GEOMETRY, '2D_RANDOM' )
  % set random seed to repeat experiments
  rand('state',0);

  % uniformly distributed on [0,L]-by-[0,L] square
  n = 20;
  L = 0.45*(c/f_high)*sqrt(n);
  % loc is a column vector of x and y coordinates
  loc = L*rand(n,2);

%********************************************************************
% uniform 2D array with m-by-m element with d spacing
%********************************************************************
elseif strcmp( ARRAY_GEOMETRY, '2D_UNIFORM_LATTICE' )
  m = 6; n = m^2;
  d = 0.45*(c/f_high);

  loc = zeros(n,2);
  for x = 0:m-1
    for y = 0:m-1
      loc(m*y+x+1,:) = [x y];
    end
  end
  loc = loc*d;

else
  error('Undefined array geometry')
end

%********************************************************************
% construct optimization data
%********************************************************************
% discretized grid sampling parameters
numtheta = 180;
numfreqs = 6;

theta = linspace(1,360,numtheta)';
freqs = linspace(500,3000,numfreqs)';

clear Atotal;
for k = 1:numfreqs
  % FIR portion of the main matrix
  Afir = kron( ones(numtheta,n), -[0:P-1]/fs );

  % cos/sine part of the main matrix
  Alocx = kron( loc(:,1)', ones(1,P) );
  Alocy = kron( loc(:,2)', ones(1,P) );
  Aloc = kron( cos(pi*theta/180)/c, Alocx ) + kron( sin(pi*theta/180)/c, Alocy );

  % create the main matrix for each frequency sample
  Atotal(:,:,k) = exp(2*pi*i*freqs(k)*(Afir+Aloc));
end

% single out indices so we can make equalities and inequalities
inbandInd    = find( freqs >= f_low & freqs <= f_high );
outbandInd   = find( freqs < f_low | freqs > f_high );
thetaStopInd = find( theta > (theta_tar+half_beamwidth) | ...
                     theta < (theta_tar-half_beamwidth) );
[diffClosest, thetaTarInd] = min( abs(theta - theta_tar) );

% create target and stopband constraint matrices
Atar = []; As = [];
% inband frequencies constraints
for k = [inbandInd]'
  Atar = [Atar; Atotal(thetaTarInd,:,k)];
  As = [As; Atotal(thetaStopInd,:,k)];
end
% outband frequencies constraints
for k = [outbandInd]'
  As = [As; Atotal(:,:,k)];
end

%********************************************************************
% optimization problem
%********************************************************************
cvx_begin
  variable w(n*P) complex
  minimize( max( abs( As*w ) ) )
  subject to
    % target direction equality constraint
    Atar*w == 1;
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
end

fprintf(1,'The minimum sidelobe level is %3.2f dB.\n\n',...
          20*log10(cvx_optval) );

%********************************************************************
% plots
%********************************************************************
figure(1); clf;
plot(loc(:,1),loc(:,2),'o')
title('Antenna locations')
axis('square')

% plots of array patterns (cross sections for different frequencies)
figure(2); clf;
clr = { 'r' 'r' 'b' 'b' 'r' 'r' };
linetype = {'--' '--' '-' '-' '--' '--'};
for k = 1:numfreqs
  plot(theta, 20*log10(abs(Atotal(:,:,k)*w)), [clr{k} linetype{k}]);
  hold on;
end
axis([1 360 -15 0])
title('Passband (blue solid curves) and stopband (red dashed curves)')
xlabel('look angle'), ylabel('abs(y) in dB');
hold off;

% cross section polar plots
figure(3); clf;
bw = 2*half_beamwidth;
subplot(2,2,1); polar_plot_ant(abs( Atotal(:,:,2)*w ),theta_tar,bw,'f = 1000 (stop)');
subplot(2,2,2); polar_plot_ant(abs( Atotal(:,:,3)*w ),theta_tar,bw,'f = 1500 (pass)');
subplot(2,2,3); polar_plot_ant(abs( Atotal(:,:,4)*w ),theta_tar,bw,'f = 2000 (pass)');
subplot(2,2,4); polar_plot_ant(abs( Atotal(:,:,5)*w ),theta_tar,bw,'f = 2500 (stop)');
