function img = backproj2D_GPU(p, theta, ctrIdx, hond, N, centerond, maxR)
% back projection 
% img = backproj2D_GPU(p, theta, ctrIdx, hond, N, centerond, maxR)
% like backproj2D_2

if nargin<6
    centerond = [0 0];
end
if nargin<7
    maxR = inf;
end

if ~isa(p, 'gpuArray')
    p = gpuArray(p);
end
pclass = classGPU(p);

% size of the p, Np*Nslice*Nview
sizep = size(p);
if length(sizep) > 2
    Nslice = sizep(2);
else
    Nslice = 1;
    p = reshape(p, sizep(1), 1, sizep(2));
end

% xyz and other
[x,y,z,Sxy,costheta,sintheta] = backproj2Dprepare(N, Nslice, hond, centerond, maxR, theta, pclass);

Nxy = size(x, 1);
ctrIdx = gpuArray(cast(ctrIdx, pclass));
% sliceshift = gpuArray(cast(sliceshift, pclass));
% Np = gpuArray(cast(Np, pclass));
% Nslice = gpuArray(cast(Nslice, pclass));
% N = gpuArray(cast(N, pclass));
% proj = gpuArray([zeros(Np+1, Nslice, pclass); nan(1, Nslice, pclass)]);
% proj = gpuArray(zeros(Np, Nslice, pclass));
% Allocate memory for the image
img_GPU = gpuArray(zeros(Nxy, Nslice, pclass));

Nview = length(theta);

% proj = gpuArray(zeros(Np*Nslice, maxview, pclass));
% sliceshift = gpuArray(cast(sliceshift(:) + (0:maxview-1).*(Np*Nslice), pclass));
if Nslice>1
    for iview = 1:Nview
        % projection sample
        Eta = (-x.*sintheta(iview) + y.*costheta(iview)) + ctrIdx;
        % interpolation and add to image
        img_GPU = img_GPU + interp2(p(:,:,iview), z, Eta, 'linear', 0);
    end
else
    for iview = 1:Nview
        % projection sample
        Eta = (-x.*sintheta(iview) + y.*costheta(iview)) + ctrIdx;
        % interpolation and add to image
        img_GPU = img_GPU + interp1(p(:,:,iview), Eta, 'linear', 0);
    end
end

img = zeros(N^2, Nslice, pclass);
img(Sxy, :) = gather(img_GPU).*(pi/length(theta)/2);
img = reshape(img, N, N, Nslice);

end