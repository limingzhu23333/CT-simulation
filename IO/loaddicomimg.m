function [img, dcminfo] = loaddicomimg(filepath, dcmext)
% [img, dcminfo] = loaddicomimg(filepath, toclass)
% load dicom image(s)

if nargin<2
    dcmext = '.dcm';
end

if isfile(filepath)
    % read file
    dcminfo = dicominfo(filepath);
    img = dicomread(filepath);
    % to float
    img = double(img);
    % scale
    if isfield(dcminfo, 'RescaleIntercept')
        img = img.*dcminfo.RescaleSlope + dcminfo.RescaleIntercept + 1000;
    end
elseif isdir(filepath)
    [img, dcminfo] = loaddcmimage2(filepath, dcmext);
else
    img = [];
    dcminfo = [];
end
end


function [img, dcminfo] = loaddcmimage2(imgpath, dcmext)

if nargin<2
    dcmext = '.dcm';
end

files = dir(fullfile(imgpath, [ '*' dcmext]));
[~, sortidx] = natsortfiles({files.name});
files = files(sortidx);
Nf = size(files(:), 1);

img = [];
dcminfo = [];
for ii = 1:Nf
    [img_ii, dcminfo_ii] = loaddicomimg(fullfile(files(ii).folder, files(ii).name));
    if ii == 1
        img = zeros([size(img_ii) Nf]);
        dcminfo = dcminfo_ii;
        dcminfo(Nf) = dcminfo_ii;
    end
    img(:,:,ii) = img_ii;
    dcminfo(ii) = dcminfo_ii;
end

end