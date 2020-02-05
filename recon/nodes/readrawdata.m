function [dataflow, prmflow, status] = readrawdata(reconcfg, dataflow, prmflow, status)
% recon node to read raw data in recon/cali pipe line
% [dataflow, prmflow, status] = readrawdata(status.reconcfg, dataflow, prmflow, status);
% or a quick start
% [dataflow, prmflow] = readrawdata(reconcfg);
% the reconcfg is a strucut read from recon xml configure file, inwhich
% reconcfg.rawdata is the rawdata file and reconcfg.offset is the offset data file.
% reconcfg.IOstandard is the data format configure path (If you do not know what it is, try to set reconcfg.IOstandard=[] .)
% A smallest reconcfg is like: reconcfg.rawdata = 'D:/mydatapath/rawdata.raw'; reconcfg.IOstandard = [];,
% which can not run a reconstruction but enough to call some of the recon nodes, like readrawdata.m and reconnode_log2.m.

if nargin<2
    % a quick start
    dataflow = struct();
    prmflow = struct();
end

% load raw data
dataflow = structmerge(loadrawdata(reconcfg.rawdata, reconcfg.IOstandard), dataflow);

% load offset
if isfield(reconcfg, 'offset') && ~isempty(reconcfg.offset)
    dataflow.offset = loadrawdata(reconcfg.offset, reconcfg.IOstandard);
end

% other
if isfield(reconcfg, 'system')
    % views
    dataflow.rawhead.viewangle = (single(dataflow.rawhead.Angle_encoder) - reconcfg.system.angulationzero) ...
                                 ./reconcfg.system.angulationcode.*(pi*2);
end

% recon parameters
if isfield(reconcfg, 'protocol')
%     viewnumber = reconcfg.protocol.viewnumber;
    prmflow.recon.Nshot = reconcfg.protocol.shotnumber;
    prmflow.recon.Nviewprot = reconcfg.protocol.viewperrot;
    % for Axial
    prmflow.recon.Nview = prmflow.recon.Nviewprot * prmflow.recon.Nshot;
end

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];

end


function dataflow = loadrawdata(filename, IOstandard)
% load rawdata (or offset) from the file filename

[~, ~, fileEXT] = fileparts(filename);
switch lower(fileEXT)
    case {'.raw', '.bin'}
        raw = loaddata(filename, IOstandard);
        % data flow
        [dataflow.rawhead, dataflow.rawdata] = raw2dataflow(raw);
    case '.mat'
        raw = load(filename);
        if isfield(raw, 'rawhead') && isfield(raw, 'rawdata')
            dataflow = raw;
        else
            tmpfield = fieldnames(raw);
            [dataflow.rawhead, dataflow.rawdata] = raw2dataflow(raw.(tmpfield{1}));
        end
    case '.pd'
        % external IO of .pd
        dataflow = CRIS2dataflow(filename);
    otherwise
        error('Unknown rawdata ext: %s', fileEXT);
end

end


function [rawhead, rawdata] = raw2dataflow(raw)
% raw to dataflow

rawhead.Angle_encoder = [raw.Angle_encoder];
rawhead.Reading_Number = [raw.Reading_Number];
rawhead.Integration_Time = [raw.Integration_Time];
% rawhead.Time_Stamp = [raw.Time_Stamp];
rawhead.mA = single([raw.mA]);
rawhead.KV = single([raw.KV]);
rawdata = single([raw.Raw_Data]);

end

