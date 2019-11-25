function simuresultsoutput(SYS, Data)
% simuresultsoutput(SYS, Data)

% output the rawdata and air (no offset?)
rawdataoutput(SYS, Data);

% to be use
mu_ref = 0.020323982562342;
HCscale = 1000*log(2)/mu_ref;

% recon xml
Nw = SYS.source.Wnumber;
recon = cell(1, Nw);
for iw = 1:Nw
    % rawdata
    recon{iw}.rawdata = [SYS.output.path SYS.output.files.rawdata{iw} '_' SYS.output.rawdataversion '.raw'];
    % detector corr
    recon{iw}.detector_corr = SYS.detector.detector_corr.frame_base;
    % focal position
    recon{iw}.focalposition = SYS.source.focalposition;
    % protocol
    recon{iw}.protocol = SYS.protocol;
    recon{iw}.protocol.KV = SYS.source.KV{iw};
    recon{iw}.protocol.mA = SYS.source.mA{iw};
    % recon work flow
    recon{iw}.pipe.Air = struct();
    recon{iw}.pipe.Beamharden = struct();
    recon{iw}.pipe.Housefield = HCscale;
    recon{iw}.pipe.Rebin = struct();
    recon{iw}.pipe.Filter = struct();
    recon{iw}.pipe.Backprojection = struct();
    % TBC
end
% save xml file
root.configure.recon = recon;
reconxmlfile = [SYS.output.path 'recon_series' num2str(SYS.protocol.series_index) '.xml'];
struct2xml(root, reconxmlfile);

end