function [prmflow, status] = loadcalitables(prmflow, status)
% load calibration tables
% [prmflow, status] = loadcalitables(reconcfg, prmflow, status);


% corrpath is the path to looking for corr files
if isfield(prmflow, 'corrpath')  && ~isempty(prmflow.corrpath)
    corrpath = prmflow.corrpath;
elseif isfield(prmflow.system, 'corrpath') && ~isempty(prmflow.system.corrpath)
    corrpath = prmflow.system.corrpath;
else
    [corrpath, ~, ~] = fileparts(prmflow.rawdata);
end
% corrext is the ext of the corr files
if isfield(prmflow.system, 'corrext')
    corrext = prmflow.system.corrext;
    % NOTE: set corrext = '.(corr|ct)' to looking for both .corr and .ct files
else
    % default corrext is .corr
    corrext = '.corr';
end

% detector position
% try to look for detector corr in corrpath
detcorrfile = corrcouplerule(prmflow.protocol, corrpath, prmflow.system.filematchrule, 'detector', corrext);
if isempty(detcorrfile)
    if isfield(prmflow, 'detector_corr')
        detcorrfile = prmflow.detector_corr;
    else
        detcorrfile = prmflow.system.detector_corr;
    end
end
prmflow.system.detector_corr = detcorrfile;
% load corr file
det_corr = loaddata(detcorrfile, prmflow.IOstandard);
% explain the collimator
prmflow.system.detector = collimatorexposure(prmflow.protocol.collimator, [], det_corr, prmflow.system.collimatorexplain);
% mergeslice
prmflow.system.detector.position = reshape(prmflow.system.detector.position, [], 3);
[prmflow.system.detector.position, Nmergedslice] = ...
    detectorslicemerge(prmflow.system.detector.position, prmflow.system.detector.Npixel, prmflow.system.detector.Nslice, ...
    prmflow.system.detector.slicemerge, 'mean');
prmflow.system.detector.Nmergedslice = Nmergedslice;
% copy other parameters from det_corr
prmflow.system.detector = structmerge(prmflow.system.detector, det_corr);

% to prm.recon
prmflow.recon.Nslice = Nmergedslice;
prmflow.recon.Npixel = double(prmflow.system.detector.Npixel);

% other tables
pipenodes = fieldnames(prmflow.pipe);
for ii = 1:length(pipenodes)
    % node name
    nodename = regexp(pipenodes{ii}, '_', 'split');
    nodename = lower(nodename{1});
    % is the .corr has been defined?
    if ~isfield(prmflow.pipe.(pipenodes{ii}), 'corr') || isempty(prmflow.pipe.(pipenodes{ii}).corr)
        % if the nodename is included in filematchrule to find the corr file
        if isfield(prmflow.system.filematchrule, nodename)
            corrfile = corrcouplerule(prmflow.protocol, corrpath, prmflow.system.filematchrule, nodename, corrext);
            if corrfile
                prmflow.pipe.(pipenodes{ii}).corr = corrfile;
%                 corrfile
            end
        end
    end
    % load the corrfile
    if isfield(prmflow.pipe.(pipenodes{ii}), 'corr')
        if isempty(prmflow.pipe.(pipenodes{ii}).corr)
            error('Not found the calibration table of recon node: %s!', pipenodes{ii});
        end
        prmflow.corrtable.(pipenodes{ii}) = loaddata(prmflow.pipe.(pipenodes{ii}).corr, prmflow.IOstandard);
        prmflow.corrtable.(pipenodes{ii}).filename = prmflow.pipe.(pipenodes{ii}).corr;
        % reuse corr for different collimator
        prmflow.corrtable.(pipenodes{ii}) = ...
            collimatedcorr(prmflow.corrtable.(pipenodes{ii}), nodename, prmflow.system.detector);
    end
end

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];

end

