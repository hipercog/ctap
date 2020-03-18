function value = cor(x,y)
R = corrcoef(x,y);
value = R(1,2);