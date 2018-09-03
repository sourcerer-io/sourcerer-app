% Equalizer design example
% "Filter design" lecture notes (EE364) by S. Boyd
% (figures are generated)
%
% Designs a frequency-domain and time-domain FIR equalizer for
% a single-input single-output (SISO) channel.
%
% Frequency-domain equalization uses a Chebychev criteria and
% is specified in terms of frequency response functions.
% It is a convex problem (which can be formulated as an SOCP):
%
%   minimize   max |G(w)H(w) - G_des(w)|     for w in [0,pi] 
%
% where H is the frequency response function and our variable
% is the filter impulse response h. Function G is the unequalized
% frequency response and G_des is the desired freq response.
%
% Time-domain equalization immediately designs the impulse
% response function by specifying the problem in time (it's an LP):
%
%   minimize   max_{t neq D} |g_tilde(t)|
%       s.t.   g_tilde(D) = 1
%
% where g_tilde is the impulse response of equalized system,
% and D is the delay of the system.
%
% Written for CVX by Almir Mutapcic 02/02/06

%********************************************************************
% problem specs
%********************************************************************
% sample channel with impulse response g
g =.5*[ 0.6526;  0.2157; -0.2639;  1.8024; -0.6430; ...
        0.1096; -0.7190;  0.4206; -0.0193;  0.6603;];

% problem parameters
n  = 30;              % filter order
D  = 10;              % overall delay

%********************************************************************
% frequency domain equalization
%********************************************************************
% number of freq samples (rule-of-thumb)
m  = 15*(length(g) + n);

w = linspace(0,pi,m)';
G = exp( -j*kron(w,[0:length(g)-1]) )*g;
A = exp( -j*kron(w,[0:n-1]) );

% desired frequency response is a pure delay (equalized channel)
Gdes = exp(-j*D*w);

% formulate and solve the Chebyshev design problem
cvx_begin
  variable hf(n,1)
  minimize( max( abs( G.*(A*hf) - Gdes ) ) ) 
cvx_end

% check if problem was successfully solved
disp(['Frequency equalization problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
end

%********************************************************************
% time-domain equalization
%********************************************************************
% define the convolution matrix
Tconv = toeplitz([g; zeros(n-1,1)],[g(1) zeros(1,n-1)]);

% create array of all times without t=D
times_not_D = [1:D D+2:size(Tconv,1)];

% formulate and solve the time equalization problem
cvx_begin
  variable t
  variable ht(n,1)

  minimize( max( abs( Tconv(times_not_D,:)*ht ) ) )
  subject to
    Tconv(D+1,:)*ht == 1;
cvx_end

% check if problem was successfully solved
if ~strfind(cvx_status,'Solved')
  disp(['Frequency equalization problem is ' cvx_status])
  return
end

%********************************************************************
% equalizer plots
%********************************************************************
% plot g
figure(1)
plot([0:length(g)-1],g,'o',[0:length(g)-1],g,'b:')
xlabel('t')
ylabel('g(t)')

figure(2)
H = exp(-j*kron(w,[0:length(g)-1]))*g;
% magnitude
subplot(2,1,1);
plot(w,20*log10(abs(H)))
axis([0,pi,-20,20])
xlabel('w')
ylabel('mag G(w) in dB')
% phase
subplot(2,1,2)
plot(w,angle(H))
axis([0,pi,-pi,pi])
xlabel('w')
ylabel('phase G(w)')

% freq equalizer
figure(3)
plot([0:n-1],hf,'o',[0:n-1],hf,'b:')
xlabel('t')
ylabel('h(t)')

% plot g_tilde
figure(4)
gt=conv(g,hf);
plot([1:length(gt)]-1,gt,'o',[1:length(gt)]-1,gt,'b:')
xlabel('t')
ylabel('g tilde(t)')
axis([0,length(gt)-1,-.2 1.2])

figure(5)
H = exp(-j*kron(w,[0:length(gt)-1]))*gt;
% amplitude
subplot(2,1,1)
plot(w,20*log10(abs(H)))
axis([0,pi,-20,20])
xlabel('w')
ylabel('mag G tilde(w) in dB')
% phase
subplot(2,1,2)
plot(w,angle(H))
axis([0,pi,-pi,pi])
xlabel('w')
ylabel('phase G tilde(w)')

% time equalizer
figure(6)
plot([0:n-1],ht,'o',[0:n-1],ht,'b:')
xlabel('t')
ylabel('h(t)')

% plot g_tilde
figure(7)
gt=conv(g,ht);
plot([1:length(gt)]-1,gt,'o',[1:length(gt)]-1,gt,'b:')
xlabel('t')
ylabel('g tilde(t)')

figure(8)
H = exp(-j*kron(w,[0:length(gt)-1]))*gt;
% magnitude
subplot(2,1,1)
plot(w,20*log10(abs(H)))
axis([0,pi,-20,20])
xlabel('w')
ylabel('mag G tilde(w) in dB')
% phase
subplot(2,1,2)
plot(w,angle(H))
axis([0,pi,-pi,pi])
xlabel('w')
ylabel('phase G tilde(w)')
