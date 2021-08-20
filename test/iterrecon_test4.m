% run after iterrecon_test3


% BV
mu_BV = 0.25;
lambda = 0.03;
tau_BV = 3.0;
% mu_L = 0.1;

% F^2
Kf2 = Kfilt.^2.*pi.*tau_BV;
% or
Kf0 = Kfilt.*pi.*tau_BV;
% L
L = splaplace2D(imgsize);

% iteration
Niter = 20;
tol_iter = 0.01;
alpha = 0.2;

u = zeros(imgsize, imgsize, Niter);
u(:,:,1) = img1a;
Gu = u;
b1 = filterbackproj2D(P1, pbm, Kfilt+1i.*Kf2);
b2 = TVpenalty_test1(real(b1)-imag(b1), mu_BV, lambda) + imag(b1);

rerr = nan(Niter-1, 1);
fig = figure;
for ii = 1:Niter-1
    % Gu
    if ii>1
        Gu(:,:,ii) = TVpenalty_test1(u(:,:,ii), mu_BV, lambda, Gu(:,:,ii-1));
    else
        Gu(:,:,ii) = TVpenalty_test1(u(:,:,ii), mu_BV, lambda);
    end
    % u1 = A*(Gu + i(I-G)u);
    u1 = parallelprojinimage(pbm, (Gu(:,:,ii) + 1i.*(u(:,:,ii)-Gu(:,:,ii))), '2D linearinterp');
    % u2 = Re(u1) + F1*Im(u1)
    u2 = real(u1) + fconv(imag(u1), Kf0);
    % u3 = A'*(F+iF1*F)*u2
    u3 = filterbackproj2D(u2, pbm, Kfilt+1i.*Kf2);
    % u4 = G(Re(u3) - Im(u3)) + Im(u3);
    u4 = TVpenalty_test1(real(u3)-imag(u3), mu_BV, lambda) + imag(u3);
    % r
    r = b2-u4;
    u(:,:,ii+1) = u(:,:,ii) + r.*alpha;
    
    rerr(ii) = sqrt(sum(r(:).^2)).*(1e3/imgsize^2);
    figure(fig);
    plot(1:Niter-1, rerr,'.-');
    axis([0 Niter 0 max(rerr).*1.1]);
    drawnow;
end
Gu(:,:,ii+1) = TVpenalty_test1(u(:,:,ii+1), mu_BV, lambda);

% img2 = u(:,:,ii) + (u2(:,:,ii)-u(:,:,ii)).*tau_BV;





function y = fconv(x, K)

sizeX = size(x);
len = size(K, 1);
x(len, 1) = 0;

y = ifft(fft(x).*K);
y = y(1:sizeX,:);

end

function y = LLx(L, x)

xsize = size(x);
y = reshape(L*x(:), xsize);

end

