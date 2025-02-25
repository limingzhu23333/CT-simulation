function [v2, sinp12, J] = S3renormalize(u1, u2, flag_outpolar, flag_inpolar)
% S3 renormalization transform
% move u2 to u1

if nargin<3
    flag_outpolar = true;
end
if nargin<4
    flag_inpolar = true;
end

tol_nr = 1e-16;
tol_p12 = 1e-12;

% E3 to S3
if flag_inpolar
    p1 = atan(u1(:,1)).*2;
    nr1 = [polar2xyz(u1)./(1+u1(:,1).^2) cos(p1)./2]; 
    p2 = atan(u2(:,1)).*2;
    nr2 = [polar2xyz(u2)./(1+u2(:,1).^2) cos(p2)./2];
else
    rho1sq = sum(u1.^2, 2);
    p1 = atan(sqrt(rho1sq)).*2;
    nr1 = [u1./(1+rho1sq) cos(p1)./2];
    rho2sq = sum(u2.^2, 2);
    p2 = atan(sqrt(rho2sq)).*2;
    nr2 = [u2./(1+rho2sq) cos(p2)./2];
end

vh = (nr1.*2 - [0 0 0 1])./2; 
nrvh = sqrt(sum(vh.^2, 2));
vh = vh./nrvh;
s_eps = nrvh<tol_nr;
if any(s_eps)
    vh(s_eps, :) = 0;
end
% vh = normr(vh);

% Householder
nr2h = nr2 - vh.*sum(vh.*nr2, 2).*2;
s_phase = nr2h(:,2)>0 | (nr2h(:,2)==0 & nr2h(:,1)>0);
p12 = acos(nr2h(:, 4).*2);
p12(~s_phase) = -p12(~s_phase);

% rho12 = sqrt(sum(nr2h(:,1:3).^2,2));
% theta12 = atan2(nr2h(:,2), nr2h(:,1));
% phi12 = fillmissing(acos(nr2h(:,3)./rho12), 'constant', 0);
% pb = atan(cot(p1).*(sin(p1).*sin(p12))./(-cos(p2)+cos(p1).*cos(p12)));
% % s = pb<p12;
% s = mod(pb-p12, pi*2)>pi;
% pb(s) = pb(s)+pi;

costheta = (-cos(p2)+cos(p1).*cos(p12))./(sin(p1).*sin(p12));
costheta(abs(p12)<tol_p12) = 1;
sinpb2 = 1./(tan(p1).*costheta + 1./(tan(p1).*costheta));

% p12_map = p12-sin(p12.*2)./2+sin(pb.*2)./2;
p12_shift = sinpb2 - sin(p12.*2)./2;
% to avoid 0 p12_shift
s_eps = abs(p12_shift)<tol_p12;
if any(s_eps)
    p12_shift(s_eps) = ((p12_shift(s_eps)>=0).*2-1).*tol_p12;
end
p12_map = p12 + p12_shift;
% rho12_map = rho12.*sin(p12_map)./sin(p12);
nr2h_map = nr2h;
nr2h_map(:, 4) = cos(p12_map)./2;
% nr2h_map(:,1:3) = nr2h_map(:,1:3).*(sin(p12_map)./sin(p12));
nr2h_map(:,1:3) = nr2h_map(:,1:3)./sin(p12);
s = abs(p12)<tol_p12;
nr2h_map(s,1:3) = ones(sum(s), 3).*(1/sqrt(3)/2);
nr2h_map(:,1:3) = nr2h_map(:,1:3).*sin(p12_map);

% inv Householder
nr2_map = nr2h_map - vh.*sum(vh.*nr2h_map, 2).*2;

% S3 to E3
v2 = nr2_map(:, 1:3)./(nr2_map(:, 4)+1/2);
if flag_outpolar
    v2 = xyz2polar(v2);
    J = ((1+v2(:,1).^2)./(1+u2(:,1).^2)).^3;
else
    J = ((1+sum(v2.^2,2))./(1+u2(:,1).^2)).^3;
end

% sin(phi12)^2*2
sinp12 = sin(p12_map).^2.*2;


% % debug
% pa = pb-pi;
% Nt = 100;
% t = [linspace(0, pa, Nt)'; linspace(pa, pb, Nt)';];
% tr = repmat(nr2h, Nt*2, 1);
% tr(:,4) = cos(t)./2;
% tr(:, 1:3) = sin(t)*(nr2h(1:3)./sin(p12));
% tr2 = tr - vh.*sum(vh.*tr, 2).*2;
% t2 = tr2(:, 1:3)./(tr2(:, 4)+1/2);
% 
% figure;
% hold on;
% [Xsph,Ysph,Zsph]=sphere();
% mesh(Xsph,Ysph,Zsph);
% hidden off;
% plot3(u1xyz(1), u1xyz(2), u1xyz(3), 'b.');
% plot3(u2xyz(1), u2xyz(2), u2xyz(3), 'r.');
% plot3(v2xyz(1), v2xyz(2), v2xyz(3), 'g.');
% plot3(t2(1:Nt,1), t2(1:Nt,2), t2(1:Nt,3), '--');
% plot3(t2(Nt+1:end,1), t2(Nt+1:end,2), t2(Nt+1:end,3));

end