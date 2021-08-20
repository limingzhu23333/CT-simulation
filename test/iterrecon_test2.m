imgsize = 256; h = 1;
img0 = phantom('Modified Shepp-Logan',imgsize);
img0 = img0.*5.0;
mu_e = 0.01;
Ne = 1.0e5;
% mu = 0.025;
% Ne = 3.0e5;


Nview = 600;
viewangle = linspace(0, 180, Nview+1);
viewangle = viewangle(1:end-1);

P0 = radon(img0, viewangle).*h;
img0b = iradon(P0, viewangle, 'linear', 'hann', 1.0, imgsize);
lenP = size(P0, 1);

I0 = exp(-P0.*mu_e);
I1 = poissrnd(I0.*Ne)./Ne;
P1 = -log(I1)./mu_e;
P1(P1>500) = 500;
img1b = iradon(P1, viewangle, 'linear', 'hann', 1.0, imgsize);

alpha_filt = 1.8;
Kfilt = filterdesign('hann', lenP, 1.0, alpha_filt);
P1f = fconv(P1, Kfilt);
img1a = iradon(P1f, viewangle, 'linear', 'none', 1.0, imgsize);

alpha_BV = 1.6;
Kfilt_BV = filterdesign('hann', lenP, 1.0, alpha_BV);


L = splaplace2D(imgsize);
mu_L = 0.1;
mu_BV = 100.3;
lambda = 0.05;

% F^2
Kf2 = Kfilt.*Kfilt_BV.*(pi/2);
% Kf2 = Kfilt;
% or
Kf0 = Kfilt_BV.*(pi/2);

% iteration
Niter = 50;
alpha = 0.05;
b1 = img1a;
u = zeros(imgsize, imgsize, Niter);
u(:,:,1) = img1b;
u2 = u;
rerr = zeros(Niter-1, 1);
for ii = 1:Niter-1
    u2(:,:,ii) = TVpenalty(u(:,:,ii), mu_BV, lambda);
    v1 = radon(u(:,:,ii), viewangle);
%     v1 = radon(u2(:,:,ii), viewangle);
%     v2 = radon(LLx(L, u(:,:,ii)), viewangle)./mu;
    R_BV = (u(:,:,ii) - u2(:,:,ii)).*0;
    R_L = LLx(L, u(:,:,ii))./mu_L;
    v2 = radon(R_BV+R_L, viewangle);
    v = fconv(v1, Kfilt) + fconv(v2, Kf2);
    r = b1 - iradon(v, viewangle, 'linear', 'none', 1.0, imgsize);
    u(:,:,ii+1) = u(:,:,ii) + r.*alpha;
    rerr(ii) = sqrt(sum(r(:).^2)).*(1e3/imgsize^2);
end
u2(:,:,Niter) = TVpenalty(u(:,:,Niter), mu_BV, lambda);

figure;
plot(log(rerr));


function y = fconv(x, K)

sizeX = size(x);
len = size(K, 1);
x(len, 1) = 0;

y = ifft(fft(x).*K);
y = y(1:sizeX,:);

end

function y = LLx(L, x)

Crange = 1000+[-100 100];
f1 = x.*1000;
s1 = (f1>=Crange(1)) & (f1<=Crange(2));
f1(f1<Crange(1)) = Crange(1);
f1(f1>Crange(2)) = Crange(2);

xsize = size(x);
y = reshape(L*f1(:), xsize)./1000;
y(~s1) = 0;

end

function u = TVpenalty(f0, mu, lambda)

Crange = 1000+[-100 100];
Niter = 50;
tol_iter = 1e-2;
imgsize = size(f0);
f1 = f0.*1000;

s1 = (f1>=Crange(1)) & (f1<=Crange(2));
N1 = sum(s1(:));
f1(f1<Crange(1)) = Crange(1);
f1(f1>Crange(2)) = Crange(2);

b = zeros([imgsize 2]);
d = zeros([imgsize 2]);
delta = zeros(1, Niter);

for ii = 1:Niter
    if ii == 1
        u0 = f1;
    else
        u0 = u;
    end
    u = funG(f1, u0, b, d, mu, lambda);
    delta(ii) = sqrt(sum((u(:)-u0(:)).^2)./N1);
    if delta(ii)<tol_iter
        break;
    end
    [d, b] = fundbyub(u, b, lambda);
end
u = u./1000;
u(~s1) = f0(~s1);
% delta(ii)
end

function [d1, b1] = fundbyub(u, b0, lambda)
% d_x^{k+1} = shrink(D_xu^{k+1}+b_x^{k}, 1/\lambda)
% d_y^{k+1} = shrink(D_yu^{k+1}+b_y^{k}, 1/\lambda)

[nx, ny] = size(u);

du = zeros(nx, ny, 2);
du(:,:,1) = [u(2:end,:) - u(1:end-1, :); zeros(1, ny)];
du(:,:,2) = [u(:, 2:end) - u(:, 1:end-1), zeros(nx, 1)];

b0 = b0 + du;
d1 = max(abs(b0)-1/lambda, 0).*(b0./abs(b0));
d1 = fillmissing(d1, 'constant', 0);

b1 = b0 - d1;

end

function u1 = funG(f, u, b, d, mu, lambda)
[nx, ny] = size(u);

u1 = u([2:nx nx], :) + u([1 1:nx-1], :) + u(:, [2:ny ny]) + u(:, [1 1:ny-1]);
u1 = u1 + d([1 1:nx-1], :, 1) - d(:, :, 1) + d(:, [1 1:ny-1], 2) - d(:,:,2);
u1 = u1 - b([1 1:nx-1], :, 1) + b(:, :, 1) - b(:, [1 1:ny-1], 2) + b(:,:,2);
u1 = u1.*(lambda./(mu+4*lambda)) + f.*(mu./(mu+4*lambda));

end