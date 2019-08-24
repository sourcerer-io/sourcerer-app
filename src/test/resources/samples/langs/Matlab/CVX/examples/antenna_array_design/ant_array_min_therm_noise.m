% Minimize thermal noise power of an array with arbitrary 2-D geometry
% "Convex optimization examples" lecture notes (EE364) by S. Boyd
% "Antenna array pattern synthesis via convex optimization"
% by H. Lebret and S. Boyd
% (figures are generated)
%
% Designs an antenna array such that:
% - it has unit a sensitivity at some target direction
% - obeys constraint for minimum sidelobe level outside the beamwidth
% - minimizes thermal noise power in y (sigma*||w||_2^2)
%
% This is a convex problem described as:
%
%   minimize   norm(w)
%       s.t.   y(theta_tar) = 1
%              |y(theta)| <= min_sidelobe   for theta outside the beam
%
% where y is the antenna array gain pattern (complex function) and
% variables are w (antenna array weights or shading coefficients).
% Gain pattern is a linear function of w: y(theta) = w'*a(theta)
% for some a(theta) describing antenna array configuration and specs.
%
% Written for CVX by Almir Mutapcic 02/02/06

% select array geometry
ARRAY_GEOMETRY = '2D_RANDOM';
% ARRAY_GEOMETRY = '1D_UNIFORM_LINE';
% ARRAY_GEOMETRY = '2D_UNIFORM_LATTICE';

%********************************************************************
% problem specs
%********************************************************************
lambda = 1;           % wavelength
theta_tar = 60;       % target direction
half_beamwidth = 10;  % half beamwidth around the target direction
min_sidelobe = -20;   % maximum sidelobe level in dB

%********************************************************************
% random array of n antenna elements
%********************************************************************
if strcmp( ARRAY_GEOMETRY, '2D_RANDOM' )
  % set random seed to repeat experiments
  rand('state',0);

  % (uniformly distributed on [0,L]-by-[0,L] square)
  n = 36;
  L = 5;
  loc = L*rand(n,2);

%********************************************************************
% uniform 1D array with n elements with inter-element spacing d
%********************************************************************
elseif strcmp( ARRAY_GEOMETRY, '1D_UNIFORM_LINE' )
  % (unifrom array on a line)
  n = 30;
  d = 0.45*lambda;
  loc = [d*[0:n-1]' zeros(n,1)];

%********************************************************************
% uniform 2D array with m-by-m element with d spacing
%********************************************************************
elseif strcmp( ARRAY_GEOMETRY, '2D_UNIFORM_LATTICE' )
  m = 6; n = m^2;
  d = 0.45*lambda;

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
% build matrix A that relates w and y(theta), ie, y = A*w
theta = [1:360]';
A = kron(cos(pi*theta/180), loc(:,1)') + kron(sin(pi*theta/180), loc(:,2)');
A = exp(2*pi*i/lambda*A);

% target constraint matrix
[diff_closest, ind_closest] = min( abs(theta - theta_tar) );
Atar = A(ind_closest,:);

% stopband constraint matrix
ind = find(theta <= (theta_tar-half_beamwidth) | ...
           theta >= (theta_tar+half_beamwidth) );
As = A(ind,:);

%********************************************************************
% optimization problem
%********************************************************************
cvx_begin
  variable w(n) complex
  minimize( norm( w ) )
  subject to
    Atar*w == 1;
    abs(As*w) <= 10^(min_sidelobe/20);
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
end

fprintf(1,'The minimum norm of w is %3.2f.\n\n',norm(w));

%********************************************************************
% plots
%********************************************************************
figure(1), clf
plot(loc(:,1),loc(:,2),'o')
title('Antenna locations')

% plot array pattern
y = A*w;

figure(2), clf
ymin = -30; ymax = 0;
plot([1:360], 20*log10(abs(y)), ...
     [theta_tar theta_tar],[ymin ymax],'r--',...
     [theta_tar+half_beamwidth theta_tar+half_beamwidth],[ymin ymax],'g--',...
     [theta_tar-half_beamwidth theta_tar-half_beamwidth],[ymin ymax],'g--',...
     [0 theta_tar-half_beamwidth],[min_sidelobe min_sidelobe],'r--',...
     [theta_tar+half_beamwidth 360],[min_sidelobe min_sidelobe],'r--');
xlabel('look angle'), ylabel('mag y(theta) in dB');
axis([0 360 ymin ymax]);

% polar plot
figure(3), clf
zerodB = 50;
dBY = 20*log10(abs(y)) + zerodB;
plot(dBY.*cos(pi*theta/180), dBY.*sin(pi*theta/180), '-');
axis([-zerodB zerodB -zerodB zerodB]), axis('off'), axis('square')
hold on
plot(zerodB*cos(pi*theta/180),zerodB*sin(pi*theta/180),'k:') % 0 dB
plot( (min_sidelobe + zerodB)*cos(pi*theta/180), ...
      (min_sidelobe + zerodB)*sin(pi*theta/180),'k:')  % min level
text(-zerodB,0,'0 dB')
text(-(min_sidelobe + zerodB),0,sprintf('%0.1f dB',min_sidelobe));
theta_1 = theta_tar+half_beamwidth;
theta_2 = theta_tar-half_beamwidth;
plot([0 55*cos(theta_tar*pi/180)], [0 55*sin(theta_tar*pi/180)], 'k:')
plot([0 55*cos(theta_1*pi/180)], [0 55*sin(theta_1*pi/180)], 'k:')
plot([0 55*cos(theta_2*pi/180)], [0 55*sin(theta_2*pi/180)], 'k:')
hold off
