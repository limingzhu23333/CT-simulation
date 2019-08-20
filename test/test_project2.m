% test script for ideal detector position
% on grid image
% 2D

addpath(genpath('../'));

% detector = load('../system/detectorframe/detectorpos_ideal_1000.mat');
detector.SSD = 550;
detector.SDD = 1000;
detector.hx_ISO = (54.31/180*pi)*detector.SSD/detector.Npixel;
detector.hz_ISO = detector.hx_ISO;
detector.Npixel = 950;
detector.Nslice = 16;
detector.mid_U = 475.5;

detector = idealdetector(detector, false);


detector = everything2single(detector);

% detector.slice = 1;
% detector.position = detector.position(1:950, :);
% detector.position(:, 3) = 0;

focalspot = [0, -detector.SSD, 0];

% object.index = 1;
% object.type = 'image2D';
% object.O = [0, 0, 0];
% object.vector = eye(3);
% object.volume = 1;

object.index = 1;
object.type = 'sphere';
object.O = [150, 0, 0];
object.vector = eye(3).*30;
object.volume = det(object.vector)*pi*2;

object.invV = inv(object.vector);

% imagepath = 'D:\Taiying\Data\testdata\Lung\';
% dcmfiles = ls([imagepath, '*.DCM']);
% object.image = [imagepath, dcmfiles(300,:)];
% info = dicominfo(object.image);
% object.Cimage = single(dicomread(info));
% 
% object.Cimage = object.Cimage+1000;
% object.Cimage(object.Cimage<-1000) = 0;
% object.Cimage = object.Cimage./1000;

object.Cimage = zeros(512, 512);
% object.Cimage(380:410, 280:310) = 1;   


object = everything2single(object);

Nview = 1440;
% Nview = 3;
viewangle = linspace(0, pi*2, Nview+1);
viewangle = viewangle(1:end-1);

tic;
[D, L] = intersection(focalspot, detector.position, object, 'views-ray', viewangle, 0);
toc

% tic;
% D = projectioninimage(focalspot, detector.position, object.Cimage, viewangle);
% toc
