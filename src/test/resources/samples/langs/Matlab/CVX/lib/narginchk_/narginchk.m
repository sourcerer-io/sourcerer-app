function narginchk(imin, imax)
narg = evalin('caller', 'nargin');
if narg < imin,
	me = {'MATLAB:narginchk:notEnoughInputs', 'Not enough input arguments.'};
elseif narg > imax,
	me = {'MATLAB:narginchk:tooManyInputs', 'Too many input arguments.'};
else
	return
end
throwAsCaller(MException(me{:}));

