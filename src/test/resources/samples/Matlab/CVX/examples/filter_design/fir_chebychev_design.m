% Chebychev design of an FIR filter given a desired H(w)
% "Filter design" lecture notes (EE364) by S. Boyd
% (figures are generated)
%
% Designs an FIR filter given a desired frequency response H_des(w).
% The design is judged by the maximum absolute error (Chebychev norm).
% This is a convex problem (after sampling it can be formulated as an SOCP).
%
%   minimize   max |H(w) - H_des(w)|     for w in [0,pi]
%
% where H is the frequency response function and variable is h
% (the filter impulse response).
%
% Written for CVX by Almir Mutapcic 02/02/06

%********************************************************************
% problem specs
%********************************************************************
% number of FIR coefficients (including the zeroth one)
n = 20;

% rule-of-thumb frequency discretization (Cheney's Approx. Theory book)
m = 15*n;
w = linspace(0,pi,m)'; % omega

%********************************************************************
% construct the desired filter
%********************************************************************
% fractional delay
D = 8.25;            % delay value
Hdes = exp(-j*D*w);  % desired frequency response

% Gaussian filter with linear phase (uncomment lines below for this design)
% var = 0.05;
% Hdes = 1/(sqrt(2*pi*var))*exp(-(w-pi/2).^2/(2*var));
% Hdes = Hdes.*exp(-j*n/2*w);

%*********************************************************************
% solve the minimax (Chebychev) design problem
%*********************************************************************
% A is the matrix used to compute the frequency response
% A(w,:) = [1 exp(-j*w) exp(-j*2*w) ... exp(-j*n*w)]
A = exp( -j*kron(w,[0:n-1]) );

% optimal Chebyshev filter formulation
cvx_begin
  variable h(n,1)
  minimize( max( abs( A*h - Hdes ) ) )
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  h = [];
end

%*********************************************************************
% plotting routines
%*********************************************************************
% plot the FIR impulse reponse
figure(1)
stem([0:n-1],h)
xlabel('n')
ylabel('h(n)')

% plot the frequency response
H = [exp(-j*kron(w,[0:n-1]))]*h;
figure(2)
% magnitude
subplot(2,1,1);
plot(w,20*log10(abs(H)),w,20*log10(abs(Hdes)),'--')
xlabel('w')
ylabel('mag H in dB')
axis([0 pi -30 10])
legend('optimized','desired','Location','SouthEast')
% phase
subplot(2,1,2)
plot(w,angle(H))
axis([0,pi,-pi,pi])
xlabel('w'), ylabel('phase H(w)')
