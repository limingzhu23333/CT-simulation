% function [v2, sinp12, J] = S3renormalize(u1, u2)
% S3 renormalization transform, polar

% in test

% debug
u1xyz = (rand(1,3)-1/2).*3.0;
u2xyz = (rand(1,3)-1/2).*1.5;
u1 = xyz2polar(u1xyz);
u2 = xyz2polar(u2xyz);


tol_eps = 1e-12;
N1 = size(u1, 1);
N2 = size(u2, 2);

% E3 to S3
p1 = atan(u1(:,1)).*2;
nr1 = [polar2xyz(u1)./(1+u1(:,1).^2) cos(p1)./2];

p2 = atan(u2(:,1)).*2;
nr2 = [polar2xyz(u2)./(1+u2(:,1).^2) cos(p2)./2];

vh = (nr1.*2 - [0 0 0 1])./2; 
nrvh = sqrt(sum(vh.^2, 2));
vh = vh./nrvh;
vh(nrvh<tol_eps, :) = 0;

% Householder
nr2h = nr2 - vh.*sum(vh.*nr2, 2).*2;
s_phase = nr2h(:,2)>0 || (nr2h(:,2)==0 && nr2h(:,1)>0);
p12 = acos(nr2h(:, 4).*2);
p12(~s_phase) = -p12(~s_phase);

% rho12 = sqrt(sum(nr2h(:,1:3).^2,2));
% theta12 = atan2(nr2h(:,2), nr2h(:,1));
% phi12 = fillmissing(acos(nr2h(:,3)./rho12), 'constant', 0);
pb = atan(cot(p1).*(sin(p1).*sin(p12))./(-cos(p2)+cos(p1).*cos(p12)));
% s = pb<p12;
s = mod(pb-p12, pi*2)>pi;
pb(s) = pb(s)+pi;

p12_map = p12-sin(p12.*2)./2+sin(pb.*2)./2;
% rho12_map = rho12.*sin(p12_map)./sin(p12);
nr2h_map = nr2h;
nr2h_map(:, 4) = cos(p12_map)./2;
% nr2h_map(:,1:3) = nr2h_map(:,1:3).*(sin(p12_map)./sin(p12));
nr2h_map(:,1:3) = nr2h_map(:,1:3)./sin(p12);
s = abs(p12)<tol_eps;
nr2h_map(s,1:3) = ones(sum(s), 3).*(1/sqrt(3));
nr2h_map(:,1:3) = nr2h_map(:,1:3).*sin(p12_map);

% inv Householder
nr2_map = nr2h_map - vh.*sum(vh.*nr2h_map, 2).*2;

% S3 to E3
v2xyz = nr2_map(:, 1:3)./(nr2_map(:, 4)+1/2);
v2 = xyz2polar(v2xyz);

% J and other
sinp12 = sin(p12_map).^2;
J = ((1+v2(:,1).^2)./(1+u2(:,1).^2)).^3.*2;


% debug
pa = pb-pi;
Nt = 100;
t = linspace(pa, pb, Nt)';
tr = repmat(nr2h, Nt, 1);
tr(:,4) = cos(t)./2;
tr(:, 1:3) = sin(t)*(nr2h(1:3)./sin(p12));
tr2 = tr - vh.*sum(vh.*tr, 2).*2;
t2 = tr2(:, 1:3)./(tr2(:, 4)+1/2);

figure;
hold on;
[Xsph,Ysph,Zsph]=sphere();
mesh(Xsph,Ysph,Zsph);
hidden off;
plot3(u1xyz(1), u1xyz(2), u1xyz(3), 'b.');
plot3(u2xyz(1), u2xyz(2), u2xyz(3), 'r.');
plot3(v2xyz(1), v2xyz(2), v2xyz(3), 'g.');
plot3(t2(:,1), t2(:,2), t2(:,3));

% end