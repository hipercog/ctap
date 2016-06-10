function [mu, sigma, P] = EMgauss1D(x, indices, PLOT)
% function EMgauss1D(x, indices)
% Make the EM-GMM fitting in one dimension
% x is data (1 x N)
% indices are guesses for the kernel indices --> len(indices) = number of kernels
% If PLOT==1 --> the estimation procedure is plotted along the iterations

x = x(:);
mu = x(indices)';
M = length(indices);  % number of kernels
N = length(x);        % number of data points

sigma = ones(1,M) * (max(x)-min(x))/M;
r = ones(1, M); P = r/sum(r);
p = zeros(N, M);
X = linspace(min(x) - abs(min(x))*0.5, max(x)*1.3 , 1000);

for t=1:100
   fprintf('%d  ',t)
   
   %% Plotting:
   if PLOT
      %clf; plot(x,'ro'); hold on
      try
         for jj=1:M
            pdf = norm_pdf(X, mu(jj), sigma(jj));
            plot(X, pdf), hold on,
         end
         pause(0.1)
      catch
         disp('woops, something went wrong in plotting')
      end
      hold off
   end

   %% Estimate the parameters
   for j=1:M
      for i=1:N
         p_un = P(j)*norm_pdf(x(i), mu(j), sigma(j));
         p(i,j) = p_un/(P*norm_pdf(x(i), mu, sigma)');
      end
      P(j) = 1/N*sum(p(:,j),1);
      mu(j) = p(:,j)'*x / sum(p(:,j));
      sigma(j) = sqrt(p(:,j)' * (x-mu(j)).^2 / sum(p(:,j)));
   end
   if (t>1 &  max(abs(mu_old-mu) ./ sigma) < 0.01)
      hold off, break;
   end
   mu_old = mu;
   p_old = p;

end
fprintf('... completed. \n');

if PLOT, if num2str(length(find(isnan(p))))>0, disp(['  --- N of NaN indices: ' , num2str(length(find(isnan(p))))]); end, end
if ~PLOT, return, end

%% Plot the "results"
p(isnan(p)) = 0;
clf; plot(x,'ro'); hold on; %axis(limits);
colors = {'r+' 'b+' 'g+' 'k+' 'rx' 'bx' 'gx' 'kx' 'r*' 'b*' 'g*' 'k*'};
for i=1:N
   inds(i) = find(p(i,:)==max(p(i,:)), 1);
   plot(i, x(i), colors{inds(i)}, 'markersize',15,'linewidth',4);
end
 % you may want to plot also the probability distributions of the (first 2 or 3) kernels
ax = axis; y = linspace(ax(3), ax(4), 1000);
plot(norm_pdf(y,mu(1),sigma(1))*1e5, y,'r'), plot(norm_pdf(y,mu(2),sigma(2))*1e5, y, 'b')
if length(mu)==3, plot(norm_pdf(y,mu(3),sigma(3))*1e5, y, 'g'), end
hold off
