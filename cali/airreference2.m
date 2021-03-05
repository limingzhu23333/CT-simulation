function [airref, referr] = airreference2(rawdata, refpixel, Npixel, Nslice, flag_slice)
% air reference for rawdata, to use side module as refernce detector and 
% compare with the references in airref
% [rawref, referr] = airreference2(rawdata, airref, refpixel, Npixel, Nslice);
% INPUT:
%   rawdata         raw data, in size Npixel*Nslice*Nview
%   refpixel        number of reference pixels
%   Npixel          pixel number of each slice
%   Nslice          slice number
% OUPUT:
%   airref          reference value (raw-air), in size 2*Nview
%   referr          err of the reference, in size 2*Nview
%                   which is used to judge if the refernce detectors are
%                   blocked by objects in FOV

% size or reshape
if nargin<4 || isempty(Nslice)
    [Npixel, Nslice, Nview] = size(rawdata);
else
    rawdata = reshape(rawdata, Npixel, Nslice, []);
    Nview = size(rawdata, 3);
end
% is slice independent
if nargin<5
    flag_slice = false;
end

% skip the edge slices
if Nslice>2 && ~flag_slice
    index_slice = 2:Nslice-1;
    Nref = Nslice-2;
else
    index_slice = 1:Nslice;
    Nref = Nslice;
end

% reference data
ref1 = reshape(rawdata(1:refpixel, index_slice, :), [], Nview);
ref2 = reshape(rawdata(Npixel-refpixel+1:Npixel, index_slice, :), [], Nview);

% reference
if ~flag_slice
    airref = [mean(ref1); mean(ref2)];
else
    airref = [squeeze(mean(reshape(ref1, refpixel, Nref, Nview), 1)); ...
              squeeze(mean(reshape(ref2, refpixel, Nref, Nview), 1))];
end

% reference error (STD)
ref1_err = sqrt(sum((ref1-airref(1,:)).^2))./sqrt(Nref*refpixel);
ref2_err = sqrt(sum((ref2-airref(2,:)).^2))./sqrt(Nref*refpixel);
referr = [ref1_err; ref2_err];

return

