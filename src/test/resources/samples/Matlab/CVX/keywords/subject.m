function subject( to )

%SUBJECT Implements the "subject to" keyword.
%   The keyword
%      SUBJECT TO
%   is a "no-op"---that is, it has no functional value. It is provided
%   solely to allow CVX models to read more closely to their mathematical
%   counterparts; e.g.
%      MINIMIZE( <objective> )
%      SUBJECT TO
%           <constraint1>
%           ...
%   It may be omitted without altering the model in any way.

% We had some consistency checking code here, but given that this is supposed to be 
% no-op, it seems sensible to remove it all.

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
