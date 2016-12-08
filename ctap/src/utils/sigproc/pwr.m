function pwrValue = pwr(sigmat)
    % compute signal power 
    %
    % Inputs:
    %   sigmat  [k,m] numeric, k signals of length m

    pwrValue = (1/size(sigmat,2)) * trapz(power(sigmat,2),2);
    
    % Explanation:
    % 1/(t1-t0)*integral_to_t1 x^2 
    % = fs/length(x)*(1/fs)*trapz(x^2) 
    % = 1/length(x)*trapz(x^2)
end