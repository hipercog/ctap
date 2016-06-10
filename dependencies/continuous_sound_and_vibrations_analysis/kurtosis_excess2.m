function k = kurtosis_excess2(x, dimension)
% % kurtosis_excess2: Calculates the excess kurtosis of a matrix.
% % 
% % x is a matrix
% % 
% % dimension is the dimension along which to calculate the kurtosis excess
% % 
%If A = M x N matix, kurtosis(A) = 1 x N vector.
%If A = M x N matix, kurtosis(A,1) = 1 x N vector.
%If A = M x N matix, kurtosis(A,2) = M x 1 vector.

dim_X = size(x);
if nargin < 2 
    dimension = 1;
end

% Calculate the mean along the specified dimension
m = mean(x,dimension); 

if isequal(dimension, 1)
    rep_mat_a=[dim_X(1),1];
else
    rep_mat_a=[1,dim_X(dimension)];
end

moment4=1./dim_X(dimension).*sum( (x - repmat(m,rep_mat_a) ).^4, dimension);
moment2=1./dim_X(dimension).*sum( (x - repmat(m,rep_mat_a) ).^2, dimension);

k = (moment4./(moment2.^2)) - 3;


