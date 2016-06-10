function label = litekmeans(X, k, label)
% Perform k-means clustering.
%   X: d x n data matrix
%   k: number of seeds
% Written by Michael Chen (sth4nth@gmail.com).
% Modified by Jussi Korpela (jussi.korpela@ttl.fi).
n = size(X,2);
last = 0;

if ~exist('label', 'var')
    label = ceil(k*rand(1,n));  % random initialization   
end

centerDistArr = NaN(n,k);
while any(label ~= last)
    [u,~,label] = unique(label);   % remove empty clusters
    k = length(u);
    E = sparse(1:n,label,1,n,k,n);  % transform label into indicator matrix
    m = X*(E*spdiags(1./sum(E,1)',0,k,k));    % compute m of each cluster
    last = label;
    
    % Assignment to clusters
    % original:
    %[~,label] = max(bsxfun(@minus,m'*X,dot(m,m,1)'/2),[],1); % assign samples to the nearest centers
    
    % Re-written by jkor 2.10.2015:
    % Compute euclidean distance
    for k=1:size(m,2)
        tmp = X - repmat(m(:,k),1,n);
        for i=1:n
           centerDistArr(i,k) = vecnorm(tmp(:,i)); 
        end
    end
    [~,label] = min(centerDistArr,[],2); %assign to clusters
    
end
[~,~,label] = unique(label);

    function vn=vecnorm(x)
       vn = sqrt(dot(x,x,1));
    end
end