function r = crossfit3(p, x, y, s, rate, lambda)

if nargin<5
    rate = 1.0;
end
if nargin<6
    lambda = 0;
end
     
% r1 = x(2,:) + p(1).*y(1,:) + p(2).*y(3,:) - y(2,:).*(1+p(1)+p(2));
% r1 = r1./(-y(2,:).*log2(y(2,:)));

% py = [p(1) -p(1)-p(2) p(2)];
py = [p(1) 0 p(2)];

r1 = x(2,:).*rate(2) + py*(x.*rate);
r1 = r1./rate(2) - y(2,:);

% r1 = y(2,:).*rate(2) + py*(y.*rate);
% r1 = r1./rate(2) - x(2,:);

r1 = r1./(-y(2,:).*log2(y(2,:)));

r = [r1(s)  p.*lambda];

end