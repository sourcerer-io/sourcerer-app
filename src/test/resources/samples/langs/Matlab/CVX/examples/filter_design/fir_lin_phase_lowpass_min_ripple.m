% Minimize stopband ripple of a linear phase lowpass FIR filter
% "Filter design" lecture notes (EE364) by S. Boyd
% (figures are generated)
%
% Designs a linear phase FIR lowpass filter such that it:
% - minimizes the maximum passband ripple
% - has a constraint on the maximum stopband attenuation
%
% This is a convex problem.
%
%   minimize   delta
%       s.t.   1/delta <= H(w) <= delta     for w in the passband
%              |H(w)| <= atten_level        for w in the stopband
%
% where H is the frequency response function and variables are
% delta and h (the filter impulse response).
%
% Written for CVX by Almir Mutapcic 02/02/06

%********************************************************************
% user's filter specifications
%********************************************************************
% filter order is 2n+1 (symmetric around the half-point)
n = 10;

wpass = 0.12*pi;        % passband cutoff freq (in radians)
wstop = 0.24*pi;        % stopband start freq (in radians)
atten_level = -30;      % stopband attenuation level in dB

%********************************************************************
% create optimization parameters
%********************************************************************
N = 30*n+1;                            % freq samples (rule-of-thumb)
w = linspace(0,pi,N);
A = [ones(N,1) 2*cos(kron(w',[1:n]))]; % matrix of cosines

% passband 0 <= w <= w_pass
ind = find((0 <= w) & (w <= wpass));   % passband
Ap  = A(ind,:);

% transition band is not constrained (w_pass <= w <= w_stop)

% stopband (w_stop <= w)
ind = find((wstop <= w) & (w <= pi));  % stopband
Us  = 10^(atten_level/20)*ones(length(ind),1);
As  = A(ind,:);

%********************************************************************
% optimization
%********************************************************************
% formulate and solve the linear-phase lowpass filter design
cvx_begin
  variable delta
  variable h(n+1,1);

  minimize( delta )
  subject to
    % passband bounds
    Ap*h <= delta;
    inv_pos(Ap*h) <= delta;

    % stopband bounds
    abs( As*h ) <= Us;
cvx_end

% check if problem was successfully solved
disp(['Problem is ' cvx_status])
if ~strfind(cvx_status,'Solved')
  return
else
  % construct the full impulse response
  h = [flipud(h(2:end)); h];
  fprintf(1,'The optimal minimum passband ripple is %4.3f dB.\n\n',...
            20*log10(delta));
end

%********************************************************************
% plots
%********************************************************************
figure(1)
% FIR impulse response
plot([0:2*n],h','o',[0:2*n],h','b:')
xlabel('t'), ylabel('h(t)')

figure(2)
% frequency response
H = exp(-j*kron(w',[0:2*n]))*h;
% magnitude
subplot(2,1,1)
plot(w,20*log10(abs(H)),[wstop pi],[atten_level atten_level],'r--');
axis([0,pi,-40,10])
xlabel('w'), ylabel('mag H(w) in dB')
% phase
subplot(2,1,2)
plot(w,angle(H))
axis([0,pi,-pi,pi])
xlabel('w'), ylabel('phase H(w)')
