% BP test code
% for 3D Axial no tilt, shots fill up

% inputs are dataflow, prmflow
if exist('df0', 'var')
    dataflow = df0;
    clear df0;
end

if exist('pf0', 'var')
    prmflow = pf0;
    clear pf0;
end

detector = prmflow.system.detector;
SID = detector.SID;
SDD = detector.SDD;
delta_z = detector.hz_ISO;
Nshot = prmflow.recon.Nshot;
FOV = prmflow.recon.FOV;
Nviewprot = prmflow.recon.Nviewprot;
startviewangle = prmflow.recon.startviewangle;
imagesize = prmflow.recon.imagesize;
midchannel = prmflow.recon.midchannel;
delta_d = prmflow.recon.delta_d;
Nslice = prmflow.recon.Nslice;
Nimage = prmflow.recon.Nimage;
imageincrement = prmflow.recon.imageincrement;
imagecenter = prmflow.recon.imagecenter;
couchdirection = prmflow.recon.couchdirection;
% set center to (0, 0)
% imagecenter(:, 1:2) = 0;

h = FOV/imagesize;

% ini image
image = zeros(imagesize, imagesize, Nimage);

xygrid = (-(imagesize-1)/2 : (imagesize-1)/2).*h;
[X, Y] = ndgrid(xygrid);

zgrid = (-(Nslice-1)/2 : (Nslice-1)/2).*imageincrement;
% slicegrid = (-(Nslice-1)/2 : (Nslice-1)/2).*delta_z;
midslice = (Nslice+1)/2;

for ishot = 1:Nshot
    sliceindex = (1:Nslice) + (ishot-1)*Nslice;
    viewangle = startviewangle(ishot) + linspace(0, pi*2, Nviewprot);
    costheta = cos(viewangle);
    sintheta = sin(viewangle);
    Xis = X(:) - imagecenter(sliceindex, 1)';
    Yis = Y(:) - imagecenter(sliceindex, 2)';
    for iview = 1:Nviewprot
        Eta = -Xis.*sintheta(iview) + Yis.*costheta(iview);
        Zeta = Xis.*costheta(iview) + Yis.*sintheta(iview);
        
        t_slice = zgrid.*(SID/delta_z)./(sqrt(Eta.^2+SID^2) + Zeta) + midslice;
        t_chn = Eta./delta_d + midchannel;
    end
end

