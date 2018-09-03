function xi = cvx_invert_structure( x, compact )
global cvx___
if nargin < 2, compact = false; end

%CVX_INVERT_STRUCTURE Compute a right-inverse of a structure mapping.

if ~isreal( x ),

    x = [ real(x), imag(x) ];
    x = x(:,[1:end/2;end/2+1:end]);
    if nargin < 2, compact = false; end
    xi = cvx_invert_structure( x, compact );
    xi = xi(1:2:end,:) - sqrt(-1) * xi(2:2:end,:);
    
elseif compact,

    if cvx___.isoctave,
      [LL,UU,PP,QQ] = lu(x);
      LL = PP' * LL;
      UU = UU * QQ';
    else 
      [LL,UU] = lu(x);
    end
    [jj,ii] = find(UU');
    dd = [true;diff(ii)~=0];
    jj = jj(dd);
    [i2,j2,vv] = find( inv(UU(:,jj)) / LL );
    [vn,vd] = rat(vv);
    xi = sparse(jj(i2),j2,vn./vd,size(x,2),size(x,1));
    
else
    
    xi = x'/(x*x');
    [ii,jj,vv] = find(xi);
    [vn,vd] = rat(vv);
    xi = sparse(ii,jj,vn./vd,size(x,2),size(x,1));
    
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
