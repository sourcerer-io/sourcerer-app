% Spectral factorization using Kolmogorov 1939 approach
% (code follows pp. 232-233, Signal Analysis, by A. Papoulis)
%
% Computes the minimum-phase impulse response which satisfies
% given auto-correlation.
%
% Input:
%   r: top-half of the auto-correlation coefficients
%      starts from 0th element to end of the auto-corelation
%      should be passed in as a column vector
% Output
%   h: impulse response that gives the desired auto-correlation

function h = spectral_fact(r)

% length of the impulse response sequence
nr = length(r);
n  = (nr+1)/2;

% over-sampling factor
mult_factor = 30;        % should have mult_factor*(n) >> n
m = mult_factor*n;

% computation method:
% H(exp(jTw)) = alpha(w) + j*phi(w)
% where alpha(w) = 1/2*ln(R(w)) and phi(w) = Hilbert_trans(alpha(w))

% compute 1/2*ln(R(w))
w = 2*pi*[0:m-1]/m;
R = exp( -j*kron(w',[-(n-1):n-1]) )*r;
R = abs(real(R)); % remove numerical noise from the imaginary part
figure; plot(20*log10(R));
alpha = 1/2*log(R);

% find the Hilbert transform
alphatmp = fft(alpha);
alphatmp(floor(m/2)+1:m) = -alphatmp(floor(m/2)+1:m);
alphatmp(1) = 0;
alphatmp(floor(m/2)+1) = 0;
phi = real(ifft(j*alphatmp));

% now retrieve the original sampling
index  = find(rem([0:m-1],mult_factor)==0);
alpha1 = alpha(index);
phi1   = phi(index);

% compute the impulse response (inverse Fourier transform)
h = ifft(exp(alpha1+j*phi1),n);
