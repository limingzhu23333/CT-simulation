function [dataflow, prmflow, status] = reconnode_bonehardencorr(dataflow, prmflow, status)
% recon node, boneharden correction
% [dataflow, prmflow, status] = reconnode_bonehardencorr(dataflow, prmflow, status);

% Copyright Dier Zhang
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

% parameters to use in prmflow
% Nview = prmflow.recon.Nview;
% Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nshot = prmflow.recon.Nshot;
Imageorg = dataflow.image;

% calibration table
bonecorr = prmflow.corrtable.(status.nodename);
bonecurve = reshape(bonecorr.bonecurve, bonecorr.bonecurvelength, []);

% enhance bone edge
if isfield(prmflow.pipe.(status.nodename), 'edgeenhance')
    edgeenhance = prmflow.pipe.(status.nodename).edgeenhance;
else
    edgeenhance = true;
end
if isfield(prmflow.pipe.(status.nodename), 'edgekernel')
    edgekernel = prmflow.pipe.(status.nodename).edgekernel;
else
    edgekernel = 2.0;
end
if isfield(prmflow.pipe.(status.nodename), 'edgescale')
    edgescale = prmflow.pipe.(status.nodename).edgescale;
else
    edgescale = 1.0;
end
if edgeenhance
    minvalue = min(bonecurve(:,1)) - 20;
    pixelsize = prmflow.recon.FOV/prmflow.recon.imagesize;
    ImageBE = bonecorrEdgeEnhance(dataflow.image, minvalue, pixelsize, edgekernel, edgescale);
else
    ImageBE = dataflow.image;
end

% use bone curve to adjust image
BoneImage = GetBoneImg(ImageBE, bonecurve);

% forward projection
Nx = prmflow.recon.imagesize;
Ny = prmflow.recon.imagesize;
h_img = prmflow.recon.FOV/prmflow.recon.imagesize;


dp = h_img;
fov = 1.5 * min(prmflow.recon.FOV, prmflow.recon.maxFOV);
Np = floor(fov/dp/2)*2+1;
d_h = single((-(Np-1)/2:(Np-1)/2))';
Nview = 800;
PImageBE = FP(ImageBE, Nx, Ny, Np, Nview, h_img, d_h);
PBoneImage = FP(BoneImage, Nx, Ny, Np, Nview, h_img, d_h);

% calculate the diff of projection
channelpos = d_h * dp;
Dfix = CalcDb(PImageBE, PBoneImage, bonecorr, channelpos);

% recon the diff
dataflow.rawdata = reshape(Dfix, Np, []);
prmflow.recon.Nslice = prmflow.recon.Nslice * prmflow.recon.Nshot;
prmflow.recon.startviewangle = -pi/2;
prmflow.recon.Nshot = 1;
prmflow.recon.Nviewprot = Nview;
prmflow.recon.delta_view = pi/Nview;
prmflow.recon.delta_d = h_img;
prmflow.recon.Npixel = Np;
prmflow.recon.midchannel = Np/2+0.5;
prmflow.recon.gantrytilt = 0;
[dataflow, prmflow, status] = reconnode_Filter(dataflow, prmflow, status);
[dataflow, prmflow, status] = reconnode_Backprojection(dataflow, prmflow, status);

% add diff to original
Imagediff = dataflow.image;
dataflow.image = Imageorg + Imagediff;

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end



function ImgOut = GetBoneImg(ImgIn, BoneCurve)
minValue = min(BoneCurve(:,1));
maxValue = max(BoneCurve(:,1));
ImgIn(ImgIn < minValue) = 0;
ImgIn(ImgIn > maxValue) = maxValue;
idx = find(ImgIn > 0);
ImgIn(idx)=interp1(BoneCurve(:,1), BoneCurve(:,2), ImgIn(idx));
ImgOut = ImgIn;
end

function proj = FP(ImgIn, Nx, Ny, Np, Nview, h_img, d_h)
gpuDevice;

viewangle = linspace(0, pi, Nview+1);
viewangle = single(viewangle(1:Nview));

Nimg = size(ImgIn, 3);
imgindex = repmat(reshape(single(1:Nimg), 1, 1, []), Np, Nx);

ImgIn = gpuArray(ImgIn);
viewangle = gpuArray(viewangle);
imgindex = gpuArray(imgindex);
h_img = gpuArray(single(h_img));
d_h = gpuArray(d_h);
Nx = gpuArray(single(Nx));
Ny = gpuArray(single(Ny));

proj = zeros(Np, Nimg, Nview, 'single');
for iview = 1:Nview
    [interpX, interpY, cs_view] = parallellinearinterp2D2(Nx, Ny, d_h, viewangle(iview));
    p = interp3(ImgIn, repmat(interpY,1,1,Nimg), repmat(interpX,1,1,Nimg), imgindex, 'linear', 0); 
    proj(:, :, iview) = gather(squeeze(sum(p, 2)).*(abs(cs_view)*h_img));
end

end


function Dfix = CalcDb(D, Db, bonecorr, channelpos)
HCscale = 1000;
Dscale = 1/HCscale/bonecorr.curvescale(1);
bonescale = 1/HCscale/bonecorr.curvescale(2);
bonecorr.order = reshape(bonecorr.order, 1, []);
curvematrix = reshape(bonecorr.curvematrix, bonecorr.order);
efffilter = interp1( bonecorr.beamposition, bonecorr.effbeamfilter, channelpos, 'linear', 'extrap');
efffilter = efffilter./bonecorr.curvescale(3);
mubonmuw = bonecorr.refrencebonemu/bonecorr.refrencemu;
Dbcurve = polyval3dm(curvematrix, D.*Dscale, Db.*bonescale, efffilter);
Dfix = (Dbcurve.*mubonmuw-1).*Db;
end