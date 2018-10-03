% Figures 6.21-6.23: Basis pursuit using Gabor functions
% Section 6.5.4
% Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Argyris Zymnis - 11/27/2005
%
% Here we find a sparse basis for a signal y out of
% a set of Gabor functions. We do this by solving
%       minimize  ||A*x-y||_2 + ||x||_1
%
% where the columns of A are sampled Gabor functions.
% We then fix the sparsity pattern obtained and solve
%       minimize  ||A*x-y||_2
%
% NOTE: The file takes a while to run

clear

% Problem parameters
sigma = 0.05;  % Size of Gaussian function
Tinv  = 500;   % Inverse of sample time
Thr   = 0.001; % Basis signal threshold
kmax  = 30;    % Number of signals are 2*kmax+1
w0    = 5;     % Base frequency (w0 * kmax should be 150 for good results)

% Build sine/cosine basis
fprintf(1,'Building dictionary matrix...');
% Gaussian kernels
TK = (Tinv+1)*(2*kmax+1);
t  = (0:Tinv)'/Tinv;
A  = exp(-t.^2/(sigma^2));
ns = nnz(A>=Thr)-1;
A  = A([ns+1:-1:1,2:ns+1],:);
ii = (0:2*ns)';
jj = ones(2*ns+1,1)*(1:Tinv+1);
oT = ones(1,Tinv+1);
A  = sparse(ii(:,oT)+jj,jj,A(:,oT));
A  = A(ns+1:ns+Tinv+1,:);
% Sine/Cosine basis
k  = [ 0, reshape( [ 1 : kmax ; 1 : kmax ], 1, 2 * kmax ) ];
p  = zeros(1,2*kmax+1); p(3:2:end) = -pi/2;
SC = cos(w0*t*k+ones(Tinv+1,1)*p);
% Multiply
ii = 1:numel(SC);
jj = rem(ii-1,Tinv+1)+1;
A  = sparse(ii,jj,SC(:)) * A;
A  = reshape(A,Tinv+1,(Tinv+1)*(2*kmax+1));
fprintf(1,'done.\n');

% Construct example signal
a = 0.5*sin(t*11)+1;
theta = sin(5*t)*30;
b = a.*sin(theta);

% Solve the Basis Pursuit problem
disp('Solving Basis Pursuit problem...');
tic
cvx_begin
    variable x(30561)
    minimize(sum_square(A*x-b)+norm(x,1))
cvx_end
disp('done');
toc

% Reoptimize problem over nonzero coefficients
p = find(abs(x) > 1e-5);
A2 = A(:,p);
x2 = A2 \ b;

% Constants
M = 61; % Number of different Basis signals
sk = 250; % Index of s = 0.5

% Plot example basis functions;
%if (0) % to do this, re-run basispursuit.m to create A
figure(1); clf;
subplot(3,1,1); plot(t,A(:,M*sk+1)); axis([0 1 -1 1]);
title('Basis function 1');
subplot(3,1,2); plot(t,A(:,M*sk+31)); axis([0 1 -1 1]);
title('Basis function 2');
subplot(3,1,3); plot(t,A(:,M*sk+61)); axis([0 1 -1 1]);
title('Basis function 3');
%print -deps bp-dict_helv.eps

% Plot reconstructed signal
figure(2); clf;
subplot(2,1,1);
plot(t,A2*x2,'--',t,b,'-'); axis([0 1 -1.5 1.5]);
xlabel('t'); ylabel('y_{hat} and y');
title('Original and Reconstructed signals')
subplot(2,1,2);
plot(t,A2*x2-b); axis([0 1 -0.06 0.06]);
title('Reconstruction error')
xlabel('t'); ylabel('y - y_{hat}');
%print -deps bp-approx_helv.eps

% Plot frequency plot
figure(3); clf;

subplot(2,1,1);
plot(t,b); xlabel('t'); ylabel('y'); axis([0 1 -1.5 1.5]);
title('Original Signal')
subplot(2,1,2);
plot(t,150*abs(cos(w0*t)),'--');
hold on;
for k = 1:length(t);
  if(abs(x((k-1)*M+1)) > 1e-5), plot(t(k),0,'o'); end;
  for j = 2:2:kmax*2
    if((abs(x((k-1)*M+j)) > 1e-5) | (abs(x((k-1)*M+j+1)) > 1e-5)),
      plot(t(k),w0*j/2,'o');
    end;
  end;
end;
xlabel('t'); ylabel('w');
title('Instantaneous frequency')
hold off;
