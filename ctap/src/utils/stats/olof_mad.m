function out = olof_mad(x)

% MAD	Median Absolute Distances from the sample median.
%			Y = MAD(X) computes the robust estimator of scale MAD (Median
%			Absolute Distances from the sample median) for the vector X.
%   	If X is a matrix, Y is a vector of MAD values pertaining to each
%   	column of X.
%
%  		Ref. P.J. Rousseeuw, 1991. "Tutorial to robust statistics",
%       	 J. of Chemometrics, Vol. 5, pp. 1-20.
%
%   	See also MEDIAN and STD.

%			Olof Liungman, 1998
%			Dept. of Oceanography, Earth Sciences Centre
%			Göteborg University, Sweden
%			E-mail: olof.liungman@oce.gu.se

% From Matlab File Exchange on 23.10.2009

[rows,cols] = size(x);
if cols==1
  x = x';
  rows = 1;
end

m = ones(rows,1)*median(x);
out = 1.483*median(abs(x-m));
