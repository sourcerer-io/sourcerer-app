function op = linop_fft( N, bigN, cmode, width )
%LINOP_FFT Fast Fourier transform linear operator.
% OP = LINOP_FFT( N )
%   returns a function handle that computes the 1D FFT. 
%   If given a matrix, it operates on each column separately (i.e. it 
%   does NOT automatically switch to a 2D FFT).
%
% By default, it assumes the input the FFT is real, and the output
%   is therefore complex and conjugate-symmetric
%
% OP = LINOP_FFT( N, M )
%   will zero-pad the input so that it is size M. Currently, the code
%   requires M > N, which is typical in applications.
%   The forward linear operator takes a vector of dimension N and returns a
%   vector of dimension M; the adjoint takes a M-vector and returns a N-vector.
%   By default, M = N.
%
% OP = LINOP_FFT( N, M, CMODE )
%   specifies the complex mode of the linear operator. The choices are:
%       'r2c' (default) : real input and complex (conjugate-symmetric) output
%       'c2c'           : complex input and outpuyt
%       'r2r'           : real input and real output. The real output
%   retains the same number of degrees of freedom because it exploits
%   the redudancy in the conjugate-symmetry of the complex output of the fft.
%
% OP = LINOP_FFT( N, M, CMODE, WIDTH )
%   specifies that the domain is the space of N x WIDTH matrices
%   (and the range is M x WIDTH ).
%
% new in TFOCS v1.3

% Wed, Jan 4 2011

error(nargchk(1,4,nargin));

% the naming convention "bigN" refers to the fact that we usually
%   will pad the input with zeros to take an oversampled FFT.
%   In this case, "bigN" is the size of the zero-padded input,
%   and hence also the size of the output.
if nargin < 2 || isempty(bigN), bigN = N; end
if bigN < N, error('cannot yet handle bigN < N, but there is no inherent limitiation'); end
if nargin < 3 || isempty(cmode), 
    cmode = 'r2c';
    warning('TFOCS:FFTdefaultMode','In linop_fft, using default ''r2c'' mode for fft; this will take real-part of input only!');
end
if nargin < 4 || isempty(width), width = 1; end
sz = { [N,width], [bigN,width] };

% allow normalization to make it orthogonal? To do so, divide forward mode by sqrt(bigN)

switch lower(cmode)
    case 'c2c'
        op = @(x,mode)linop_fft_c2c( sz, N, bigN, x, mode );
    case 'r2c'
        op = @(x,mode)linop_fft_r2c( sz, N, bigN, x, mode );
    case 'r2r'
        n2  = bigN/2;
        even    = (n2 == round(n2) );   % find if n is even or odd
        if ~even
            n2 = (bigN+1)/2;
        end
        op = @(x,mode)linop_fft_r2r( sz, N, bigN, n2, even, x, mode );
    otherwise
        error('bad input for cmode: must be "c2c", "r2c", or "r2r"');
end

function y = linop_fft_c2c(sz, N, bigN, x, mode)
switch mode,
    case 0, y = sz;
    case 1, y = fft(x,bigN);    % input of size N. Norm is bigN
    case 2, 
        y = bigN*ifft(x); % do NOT use ifft(x,N) because we want to truncate AFTER the ifft, not before
        y = y(1:N,:);
end

function y = linop_fft_r2c(sz, N, bigN, x, mode)
switch mode,
    case 0, y = sz;
    case 1, 
        if ~isreal(x), 
            x = real(x);
%             x = real(x+conj(x))/2; % another possibility
        end
        y = fft(x,bigN);
    case 2, 
        y = bigN*ifft(x,'symmetric');
        y = y(1:N,:);
end


function y = linop_fft_r2r(sz, N, bigN, n2, even, x, mode)
switch mode,
    case 0, y = sz;
    case 1, 
        error(sizeCheck( x, mode, sz ));
        if ~isreal(x), 
            x = real(x);
        end
        z   = fft(x,bigN); % output is of size bigN
        y   = real(z);
        if even
            %   y( (n2+2):bigN, : )    = imag( z( 2:n2, : ) ); % convention "A" (not orthogonal)
            y( (n2+2):bigN, : )    = -imag( z( n2:-1:2, : ) ); % convention "B" (orthogonal)
            y( n2+1, :) = y( n2+1, :)/sqrt(2);
        else
            %  y( (n2+1):bigN, : )    = imag( z( 2:n2, : ) ); % convention "A"
            y( (n2+1):bigN, : )    = -imag( z( n2:-1:2, : ) );% convention "B"
        end
        y = sqrt(2)*y;  % the sqrt(2) is so adjoint=inverse
        y(1,:) = y(1,:)/sqrt(2);
    case 2, 
        error(sizeCheck( x, mode, sz ));
        assert( isreal(x) );
        y   = complex(x);  % reserve the memory for y
        n   = bigN;
        if even
            %  y(2:n2, : )     = x(2:n2, : ) + 1i*x((n2+2):n, : ); % convention "A"
            y(2:n2, : )     = ( x(2:n2, : ) - 1i*x(n:-1:(n2+2), : ) )/sqrt(2); % convention "B"
            
            % We can skip this (see the "trick" mentioned below)
            %   y(n:-1:n2+2, : )= conj( y(2:n2,:) );
        else
            %  y(2:n2, : )   = x(2:n2, : ) + 1i*x((n2+1):n, : ); % convention "A"
            y(2:n2, : )   = ( x(2:n2, : ) - 1i*x(n:-1:(n2+1), : ) )/sqrt(2); % convention "B"
            
            % We can skip this (see the "trick" mentioned below)
            %   y(n:-1:n2+1, : )= conj( y(2:n2, :) );
        end
        % Note: we are using a trick. We have commented out
        %  the lines that set y(n2+2:n) (or n2+1:n), because
        %  the ifft, when using the 'symmetric' option,
        %  will not look at these entries.
        
        y = bigN*ifft(y,'symmetric');
        y = y(1:N,:);
end

function ok = sizeCheck( x, mode, sz )
szX = size(x);
szY = sz{mode};
if numel(szX) == numel(sz{1}) && all( szX == szY )
    ok = [];
else
    ok = 'Dimensions mismatch in linop_fft; please check your input size. ';
    if numel(szX) == 2
        if szX(1) == szY(2) && szX(2) == szY(1)
            ok = strcat(ok,' Looks like you have a row vector instead of a column vector');
        end
    end
end

%{
The conjugate-to-real transformation as a matrix.
(we design this for conjugate-symmetry, but you must make sure
 that it still does the same operations when the input
 is not conjugate-symmetric)

n       = 10;
even    = n/2 == round(n/2)
P       = zeros(n);
P(1,1)  = 1;            % DC component
if even, d      = n/2 - 1; 
P(d+2,d+2)      = 1;    % Nyquist component
else, d = (n-1)/2; end

I   = eye(d)/sqrt(2);
J   = fliplr(I);

first=2:d+1;
if even,     second=d+3:n; else,  second=d+2:n; end

% Convention "A"
P(first, first)  = I;       % upper left block
P(second,first)  = -1i*I;   % lower left block

P(first, second)  = J;      % upper right block
P(second,second)  = 1i*J;   % lower right block

% or... this makes P' = inv(P). Convention "B"

P(first, first)  = I;       % upper left block
P(second,first)  = 1i*J;    % lower left block. now, J, not I

P(first, second)  = J;      % upper right block
P(second,second)  = -1i*I;  % lower right block. now, I, not J
%}



% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license informatio
