function x = mafilt(x, m)
%MAFILT - moving average filter
b = (1/m)*ones(1,m);
a = 1;
x = filter(b,a,x);
end

