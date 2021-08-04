% test of Compton formula
% run a system configure script first

samplekeV = SYS.world.samplekeV;
mu = SYS.world.water.material.mu_total;

f0src = SYS.source.spectrum{1};
% f0(f0==0) = nan;

t = 1/16;

samplekeV2 = samplekeV(1):t:samplekeV(end);
mu2 = interp1(samplekeV, mu, samplekeV2);
f0 = interp1(samplekeV, f0src, samplekeV2);
Nsmp2 = size(samplekeV2(:), 1);

D1 = (0:2:600)';
D2 = (0:2:600)';
Nd1 = size(D1(:),1);
Nd2 = size(D2(:),1);

f1 = exp(-D1*mu2).*f0;

mec2 = 511;
theta_x = 0.1;
theta = asin(theta_x.^2).*2;
ctm = (1-cos(theta))./mec2;

invg = 1./(1./samplekeV2 - ctm);
finvg = interp2(samplekeV2, D1, f1, repmat(invg, Nd1, 1), repmat(D1, 1, Nsmp2));
finvg = fillmissing(finvg, 'const', 0);
dginvg = 1./(ctm.*invg + 1).^2;

f_KN = finvg./dginvg;
f_R = f1;

y1 = f_KN*samplekeV2(:).*t;

% Oxygen
Z = 8;
Wz = 15.9994;

alphare2 = 7.940775e-30*1e4; % m^2 -> cm^2
Watom = 1.66053904e-27*1e3;  % kg -> g
lambda_A0 = 12398.520;

% KeV0 = 50;
sigma0_coh = 2.166E-02;
sigma0_inc = 1.609E-01;
dataO = readmatrix('E:\matlab\CTsimulation\test\O_FS.csv');

q = 1./(1+ctm.*samplekeV2);
dsigmaKN = (alphare2/2/Watom/Wz).*q.^2.*(q+1./q-sin(theta).^2)./10;
dsigmaR = (alphare2/2/Watom/Wz).*(1+cos(theta).^2)./10;
x_theta = abs(sin(theta./2))*(samplekeV2.*(1e3/lambda_A0));
F_theta = interp1(dataO(:,1), dataO(:,2), x_theta, 'pchip');
S_theta = interp1(dataO(:,1), dataO(:,3), x_theta, 'pchip');


fd = exp(-D2*mu2).*samplekeV2;
E_KN = (dsigmaKN.*S_theta.*f_KN)*fd'.*t;
E_R = (dsigmaR.*F_theta.^2.*f_R)*fd'.*t;
E = E_KN+E_R;

f2 = (dsigmaKN.*S_theta.*f_KN + dsigmaR.*F_theta.^2.*f_R).*exp(-mu2.*D2);
E0src = f0src*samplekeV(:);
E0 = ((dsigmaKN.*S_theta+dsigmaR.*F_theta.^2).*f0)*samplekeV2(:).*t;
% E1 = ((dsigmaKN.*S_theta+dsigmaR.*F_theta.^2).*f1)*samplekeV2(:).*t;
% E2 = ((dsigmaKN.*S_theta+dsigmaR.*F_theta.^2).*f2)*samplekeV2(:).*t;


