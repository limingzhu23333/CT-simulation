function [P, Pair, Eeff] = projectionscan2(focalposition, detposition, detnormv, bowtie, filter, samplekeV, detspect, detpixelarea, ...
    viewangle, couch, gantrytilt, phantom, method, echo_onoff, GPUonoff)
% the projection simulation, sub function


Nw = size(detspect(:),1);
Np = size(detposition, 1);
Nfocalpos = size(focalposition, 1);
NkeVsample = length(samplekeV(:));
Nview = length(viewangle(:));
Nviewpf = Nview/Nfocalpos;

% ini P & Eeff
P = cell(1, Nw);
Eeff = cell(1, Nw);
switch lower(method)
    case {'default', 1, 'photoncount', 2}
        P(:) = {zeros(Np, Nview)};
        Eeff(:) = {zeros(Np, Nview)};
    case {'energyvector', 3}
        P(:) = {zeros(Np*Nview, Nsample)};
        % No Eeff
    otherwise
        % error
        error(['Unknown projection method: ' method]);
end
Pair = cell(1, Nw);

% projection on bowtie and filter in collimation
[Dmu_air, L] = flewoverbowtie(focalposition, detposition, bowtie, filter, samplekeV);
% distance curse
distscale = detpixelarea./(L.^2.*(pi*4));
% incident angle scale
if ~isempty(detnormv)
    incidnetscale = -AtoBdotVnorm(focalposition, detposition, detnormv)./L;
    incidnetscale(incidnetscale<0) = 0;
else
    incidnetscale = 1;
end
% put the incident scale on distance curse
distscale = distscale.*incidnetscale;

% energy based Posibility of air
for ii = 1:Nw
    switch lower(method)
        case {'default', 1}
            % ernergy integration
            Pair{ii} = (exp(-Dmu_air).*repmat(detspect{ii}, Nfocalpos, 1)) * samplekeV';
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'photoncount', 2}
            % photon counting
            Pair{ii} = sum(exp(-Dmu_air).*repmat(detspect{ii}, Nfocalpos, 1), 2);
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'energyvector', 3}
            % maintain the components on energy
            Pair{ii} = exp(-Dmu_air).*repmat(detspect{ii}, Nfocalpos, 1);
            Pair{ii} = Pair{ii}.*distscale(:);
        otherwise
            % error
            error(['Unknown projection method: ' method]);
    end
    Pair{ii}(isnan(Pair{ii})) = 0;
end
Dmu_air = reshape(Dmu_air, Np, Nfocalpos, NkeVsample); 

% projection on objects (GPU)
% tic
% echo '.'
if echo_onoff, fprintf('.'); end
[D, mu] = projectinphantom(focalposition, detposition, phantom, samplekeV, viewangle, couch, gantrytilt, GPUonoff);
D = reshape(D, Np, Nview, []);
% toc

% echo '.'
if echo_onoff, fprintf('.'); end
% tic
% prepare GPU 
if GPUonoff
    mu = gpuArray(single(mu));
    samplekeV = gpuArray(single(samplekeV));
    detspect = cellfun(@(x) gpuArray(single(x)), detspect, 'UniformOutput', false);
    % Nlimit = gpuArray(single(Nlimit));
    Np = gpuArray(single(Np));
    Nfocalpos = gpuArray(single(Nfocalpos));
    distscale = gpuArray(single(distscale));
    Dmu_air = gpuArray(Dmu_air);
    Dmu = gpuArray(zeros(Np, NkeVsample, 'single'));   
end

% for i_lim = 1:Nlimit
for iview = 1:Nview
    % echo '.'
    if echo_onoff && mod(iview, 100)==0, fprintf('.'); end
    % ifocal
    ifocal = mod(iview-1, Nfocalpos)+1;

    % projection on objects    
    if ~isempty(D)
        Dmu = squeeze(Dmu_air(:, ifocal, :)) + squeeze(D(:, iview, :))*mu;
%         Pmu = Dmu0 + squeeze(D(:, iview, :))*mu;
    else
        Dmu = squeeze(Dmu_air(:, ifocal, :));
    end
       
    % energy based Posibility
    for ii = 1:Nw
        switch lower(method)
            case {'default', 1}
                % ernergy integration
                Dmu = exp(-Dmu).*detspect{ii};
                % for quanmtum noise
                Eeff{ii}(:, iview) = gather(sqrt((Dmu * (samplekeV'.^2))./sum(Dmu, 2)));
                % Pmu = integrol of Dmu 
                Pmu =  Dmu * samplekeV';
                Pmu = Pmu(:).*distscale(:, ifocal);
                P{ii}(:, iview) = gather(Pmu);
            case {'photoncount', 2}
                % photon counting
                Dmu = exp(-Dmu).*detspect{ii};
                Pmu = sum(Dmu, 2).*distscale(:, ifocal);
                P{ii}(:, iview) = gather(Pmu);
            case {'energyvector', 3}
                % maintain the components on energy
                Dmu = exp(-Dmu).*detspect{ii};
                Dmu = reshape(Dmu, Np, []).*distscale(:, ifocal);
                index_p = (1:Np) + Np*(iview-1);
                P{ii}(index_p, :) = gather(reshape(Dmu, Np, []));
            otherwise
                % error
                error(['Unknown projection method: ' method]);
        end
    end
end
% toc

end


function incidnetscale = AtoBdotVnorm(A, B, Vnorm)
% Vnorm*(B-A)'

incidnetscale = (B(:,1)-A(:,1)').*Vnorm(:, 1) + (B(:,2)-A(:,2)').*Vnorm(:, 2) + (B(:,3)-A(:,3)').*Vnorm(:, 3);

end
