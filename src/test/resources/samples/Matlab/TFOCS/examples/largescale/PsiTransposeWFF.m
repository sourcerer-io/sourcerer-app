function y = PsiTransposeWFF(x,w_type,log_length,min_scale,max_scale,shift_redundancy,freq_redundancy, PLOT)
% Windowed Fourier Frame Analysis
% y = PsiTransposeWFF( x, w_type, log_length, min_scale, max_scale,...
%       shift_redundancy, freq_redundancy, plot )
%   w_type is the type of window.  Currently, this supports 'isine' (iterate sine)
%   and 'gaussian'.  Default: 'isine' (to use default, set this to [] ).
%
% Core code written by Peter Stobbe; modifications by Stephen Becker
if isempty(w_type), w_type = 'isine'; end
if nargin < 8 || isempty(PLOT), PLOT = false; end

% w is a is a vector of with the window of the largest scale
% smaller scale windows are just this subsampled
[w, window_redundancy] = make_window(max_scale,w_type);

y = [];
c = ((max_scale - min_scale + 1)*window_redundancy*2.^((1:max_scale)'+freq_redundancy+shift_redundancy)).^-.5;
  
    
for k = min_scale:max_scale
    M = 2^(log_length-k) +(2^(log_length-k)+1)*(2^shift_redundancy-1);
    z = [myRepMat(x,2^shift_redundancy); zeros(2^k - 2^(k-shift_redundancy),2^shift_redundancy)];
    z = reshape(z,2^k,M);
    z = z.*myRepMat(w(2^(max_scale-k)*(1:2^k)'),M);
    z(2^(k+freq_redundancy),M) = 0;
    z = fft(z);
    z = [z(1,:)*c(k);       real(z(2:end/2,:))*c(k-1); ...
        z(end/2+1,:)*c(k); imag(z(end/2+2:end,:))*c(k-1)];
    y = [y; z(:)];
end

function B = myRepMat(A,n)
B = A(:,ones(n,1));

function [w,window_redundancy] = make_window(max_scale,w_type)
% [w,window_redundancy] = make_window(max_scale,w_type)
%   w_type can be
%       'isine' for iterated sine
%       'gaussian' for gaussian
%       'trapezoid' for trapezoidal shape (not a frame)

x = (1:2^max_scale)'/2^(max_scale-1)-1;
if isequal(w_type,'isine')
    w = sin(pi/4*(1+cos(pi*x)));
    window_redundancy = 1/2;
elseif isequal(w_type,'gaussian')
    w = exp(-x.^2*8*log(2));
    window_redundancy = mean(w.^2);
elseif isequal(w_type,'trapezoid')
    w = min(1,2*(1-abs(x)));
    window_redundancy = mean(w.^2);
else
    disp('Error in make_window: unknown window type');
    disp('Options are: isine, gaussian, trapezoid');
end
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
