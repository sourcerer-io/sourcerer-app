% Computes the step response of a linear system

function X = simple_step(A,B,DT,N)
n  = size(A,1);
Ad = expm( full( A * DT ) );
Bd = ( Ad - eye(n) ) * B;
Bd = A \ Bd;
X  = zeros(n,N);
for k = 2 : N,
    X(:,k) = Ad*X(:,k-1)+Bd;
end


