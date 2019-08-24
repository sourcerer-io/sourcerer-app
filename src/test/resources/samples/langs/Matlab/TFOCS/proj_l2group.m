function op = proj_l2group( q,group_indices )
%PROJ_L2GROUP   Projection onto the intersection of scaled 2-norm balls.
%    OP = PROJ_L2GROUP( Q, GROUP_INDICES ) returns an operator implementing the 
%    indicator function for the intersection of 2-norm ball of size q_k,
%    i.e. intersection_k B_k
%    where B_k = { X |  norm( X(indK) ) <= q(k) }
%    and indK is indexed by group_indices. Group_indices keeps track
%    of the last index in each index set.
%    The index sets must be non-overlapping.
%    For example, if K=2, and ind1 = 1:10 and ind2 = 11:20,
%    then group_indices = [10,20].
%    Q must be a vector of length K or a vector of length N.
%
% With contributions from Joseph Salmon
%
% See also: proj_l2.m

if isempty(q), q = 1; end
% Make sure q is a column vector
if size(q,1) == 1 && size(q,2) > 1, q = q.'; end
q = expand_q(q,group_indices);
op = @(varargin)proj_l2_q( q,group_indices, varargin{:} );
end

function [ v, x ] = proj_l2_q( q,group_indices, x, t )
v = 0;
nrm=group_norm(x,group_indices);

switch nargin,
	case 3,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( nrm, 'inf') > q,
			v = Inf;
		end
	case 4,            
            x = x .* min(1,( q ./ nrm ));
	otherwise,
		error( 'Not enough arguments.' );
end
end


function y=group_norm(x,group_indices)
% the groups are indexed by their end point
    K=length(group_indices);
    y=zeros(size(x));
    j=1; % start of the group
    for k=1:K
        end_point=group_indices(k);
        y(j:end_point)=norm(x(j:end_point));
        j=end_point+1;
    end
end

function Q = expand_q(q,group_indices)
% If we have 2 groups, each of size 10
% (group_indices = [10,20]), then q should
% be a vector of size 20. But it's more convenient
% for the user to pass in a vector of size 2, so this function
% will convert it...
n = group_indices(end);
K = length(group_indices);
if length(q) < n
    Q = ones(n,1);
    j=1; % start of the group
    for k=1:K
        end_point=group_indices(k);
        Q(j:end_point) = q(k);
        j=end_point+1;
    end
else
    Q = q;
end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
