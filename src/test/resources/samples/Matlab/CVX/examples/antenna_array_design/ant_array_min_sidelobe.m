% Minimize sidelobe level of an array with arbitrary 2-D geometry
% "Convex optimization examples" lecture notes (EE364) by S. Boyd
% "Antenna array pattern synthesis via convex optimization"
% by H. Lebret and S. Boyd
% (figures are generated)
%
% Designs an antenna array such that:
% - it minimizes sidelobe level outside the beamwidth of the pattern
% - it has a unit sensitivity at some target direction
% - it has nulls (zero sensitivity) at specified direction(s) (optional)
%
% This is a convex problem (after sampling it can be formulated as an SOCP).
%
%   minimize   max |y(theta)|     for theta outside the beam
%       s.t.   y(theta_tar) = 1
%              y(theta_null) = 0  (optional)
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

% select if the optimal array pattern should enforce nulls or not
HAS_NULLS = 0; % HAS_NULLS = 1;

%********************************************************************
% problem specs
%********************************************************************
lambda = 1;           % wavelength
theta_tar = 60;       % target direction (should be an integer -- discretization)
half_beamwidth = 10;  % half beamwidth around the target direction

% angles where we want nulls (optional)
if HAS_NULLS
  theta_nulls = [95 110 120 140 225];
end

%********************************************************************
% random array of n antenna elements
%********************************************************************
if strcmp( ARRAY_GEOMETRY, '2D_RANDOM' )
  % set random seed to repeat experiments
  rand('state',0);

  % (uniformly distributed on [0,L]-by-[0,L] square)
  n = 40;
  L = 5;
  loc = L*rand(n,2);
  angleRange = 360;

%********************************************************************
% uniform 1D array with n elements with inter-element spacing d
%********************************************************************
elseif strcmp( ARRAY_GEOMETRY, '1D_UNIFORM_LINE' )
  % (unifrom array on a line)
  n = 30;
  d = 0.45*lambda;
  loc = [d*[0:n-1]' zeros(n,1)];
  angleRange = 180;

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
  angleRange = 360;

else
  error('Undefined array geometry')
end

%********************************************************************
% construct optimization data
%********************************************************************
% build matrix A that relates w and y(theta), ie, y = A*w
theta = [1:angleRange]';
A = kron(cos(pi*theta/180), loc(:,1)') + kron(sin(pi*theta/180), loc(:,2)');
A = exp(2*pi*i/lambda*A);

% target constraint matrix
[diff_closest, ind_closest] = min( abs(theta - theta_tar) );
Atar = A(ind_closest,:);

% nulls constraint matrix
if HAS_NULLS
  Anull = []; ind_nulls = [];
  for k = 1:length(theta_nulls)
    [diff_closest, ind_closest] = min( abs(theta - theta_nulls(k)) );
    Anull = [Anull; A(ind_closest,:)];
    ind_nulls = [ind_nulls ind_closest];
  end
end

% stopband constraint matrix
ind = find(theta <= (theta_tar-half_beamwidth) | ...
           theta >= (theta_tar+half_beamwidth) );
if HAS_NULLS, ind = setdiff(ind,ind_nulls); end;
As = A(ind,:);

%********************************************************************
% optimization problem
%********************************************************************
cvx_begin
  variable w(n) complex
  minimize( max( abs(As*w) ) )
  subject to
    Atar*w == 1;   % target constraint
    if HAS_NULLS   % nulls constraints
      Anull*w == 0;
    end
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
end

min_sidelobe_level = 20*log10( max(abs(As*w)) );
fprintf(1,'The minimum sidelobe level is %3.2f dB.\n\n',...
          min_sidelobe_level );

%********************************************************************
% plots
%********************************************************************
figure(1), clf
plot(loc(:,1),loc(:,2),'o')
title('Antenna locations')

% plot array pattern
if angleRange == 180,
    theta = [1:360]';
    A = [ A; -A ];
end
y = A*w;
figure(2), clf
ymin = floor(0.1*min_sidelobe_level)*10-10; ymax = 0;
plot([1:360], 20*log10(abs(y)), ...
     [theta_tar theta_tar],[ymin ymax],'r--',...
     [theta_tar+half_beamwidth theta_tar+half_beamwidth],[ymin ymax],'g--',...
     [theta_tar-half_beamwidth theta_tar-half_beamwidth],[ymin ymax],'g--');
if HAS_NULLS % add lines that represent null positions
  hold on;
  for k = 1:length(theta_nulls)
    plot([theta_nulls(k) theta_nulls(k)],[ymin ymax],'m--');
  end
  hold off;
end
xlabel('look angle'), ylabel('mag y(theta) in dB');
axis([0 360 ymin ymax]);

% polar plot
figure(3), clf
zerodB = -ymin;
dBY = 20*log10(abs(y)) + zerodB;
ind = find( dBY <= 0 ); dBY(ind) = 0;
plot(dBY.*cos(pi*theta/180), dBY.*sin(pi*theta/180), '-');
axis([-zerodB zerodB -zerodB zerodB]), axis('off'), axis('square')
hold on
plot(zerodB*cos(pi*theta/180),zerodB*sin(pi*theta/180),'k:') % 0 dB
plot( (min_sidelobe_level + zerodB)*cos(pi*theta/180), ...
      (min_sidelobe_level + zerodB)*sin(pi*theta/180),'k:')  % min level
text(-zerodB,0,'0 dB')
tt = text(-(min_sidelobe_level + zerodB),0,sprintf('%0.1f dB',min_sidelobe_level));
set(tt,'HorizontalAlignment','right');
theta_1 = theta_tar+half_beamwidth;
theta_2 = theta_tar-half_beamwidth;
plot([0 55*cos(theta_tar*pi/180)], [0 55*sin(theta_tar*pi/180)], 'k:')
plot([0 55*cos(theta_1*pi/180)], [0 55*sin(theta_1*pi/180)], 'k:')
plot([0 55*cos(theta_2*pi/180)], [0 55*sin(theta_2*pi/180)], 'k:')
if HAS_NULLS % add lines that represent null positions
  for k = 1:length(theta_nulls)
    plot([0 55*cos(theta_nulls(k)*pi/180)], ...
         [0 55*sin(theta_nulls(k)*pi/180)], 'k:')
  end
end
hold off
