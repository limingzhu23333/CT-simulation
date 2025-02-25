function [P, Pair, Eeff] = projectionscan2(focalposition, detposition, Npixel, pixelrange, detnormv, bowtie, filter, samplekeV, ...
    detspect, detpixelarea, viewangle, couch, gantrytilt, phantom, method, echo_onoff, GPUonoff)
% the projection simulation, sub function


Nw = size(detspect(:),1);
Np = size(detposition, 1);
Nslice = Np/Npixel;
Nfocalpos = size(focalposition, 1);
NkeVsample = length(samplekeV(:));
Nview = length(viewangle(:));
Nviewpf = Nview/Nfocalpos;
Cclass = class(detposition);

if ~isempty(pixelrange)
    Nrange = max(mod(pixelrange(2, :)-pixelrange(1, :), Npixel)+1);
    Np = Nrange*Nslice;
end

% ini P & Eeff
P = cell(1, Nw);
Eeff = cell(1, Nw);
switch lower(method)
    case {'default', 1, 'photoncount', 2}
        P(:) = {zeros(Np, Nview, Cclass)};
        Eeff(:) = {zeros(Np, Nview, Cclass)};
    case {'energyvector', 3}
        P(:) = {zeros(Np*Nview, NkeVsample, Cclass)};
        % No Eeff
    otherwise
        % error
        error(['Unknown projection method: ' method]);
end
Pair = cell(1, Nw);

% projection on bowtie and filter in collimation
if isempty(pixelrange)
    [Dmu_air, distscale] = airprojection(focalposition, detposition, detpixelarea, detnormv, bowtie, filter, samplekeV);
else
    distscale = zeros(Np, Nfocalpos, Cclass);
    Dmu_air = zeros(Np*Nfocalpos, NkeVsample, Cclass);
    for ii = 1:Nfocalpos
        index_det = mod(pixelrange(1,ii)-1+(0:Nrange-1)', Npixel)+1 + (0:Nslice-1).*Npixel;
        detposition_ii = detposition(index_det(:),:);
        if length(detpixelarea)>1
            detpixelarea_ii = detpixelarea(index_det(:));
        else
            detpixelarea_ii = detpixelarea;
        end
        if ~isempty(detnormv)
            detnormv_ii = detnormv(index_det(:), :);
        else
            detnormv_ii = [];
        end
        index_D = (1:Np) + (ii-1).*Np;
        % different focal different bowtie/filter (if they have)
        i_bowtie = min(ii, size(bowtie, 1));
        i_filter = min(ii, size(filter, 1));
        [Dmu_air(index_D, :), distscale(:, ii)] = airprojection(focalposition(ii,:), detposition_ii, detpixelarea_ii, ...
            detnormv_ii, bowtie(i_bowtie, :), filter(i_filter, :), samplekeV);        
    end
end

% energy based Posibility of air
for ii = 1:Nw
    switch lower(method)
        case {'default', 1}
            % ernergy integration
            Pair{ii} = (exp(-Dmu_air).*detspect{ii}) * samplekeV';
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'photoncount', 2}
            % photon counting
            Pair{ii} = sum(exp(-Dmu_air).*detspect{ii}, 2);
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'energyvector', 3}
            % maintain the components on energy
            Pair{ii} = exp(-Dmu_air).*detspect{ii};
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
if isempty(pixelrange)
    [D, mu] = projectinphantom(focalposition, detposition, phantom, samplekeV, viewangle, couch, gantrytilt, GPUonoff);
else
    Nobject = phantom.Nobject;
    D = zeros(Np*Nfocalpos, Nviewpf*Nobject, Cclass);
    for ii = 1:Nfocalpos
        index_det = mod(pixelrange(1,ii)-1+(0:Nrange-1)', Npixel)+1 + (0:Nslice-1).*Npixel;
        detposition_ii = detposition(index_det(:),:);
        index_view = ii:Nfocalpos:Nview;
        index_D = (1:Np) + (ii-1).*Np;
        [D(index_D, :), mu] = projectinphantom(focalposition(ii, :), detposition_ii, phantom, samplekeV, ...
            viewangle(index_view), couch(index_view, :), gantrytilt(index_view), GPUonoff);
    end  
end
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
        Dmu = reshape(Dmu_air(:, ifocal, :), Np, NkeVsample) + reshape(D(:, iview, :), Np, [])*mu;
%         Pmu = Dmu0 + squeeze(D(:, iview, :))*mu;
    else
        Dmu = squeeze(Dmu_air(:, ifocal, :));
    end
    
    % energy based Posibility
    for ii = 1:Nw
        switch lower(method)
            case {'default', 1}
                % ernergy integration
                Pmu = exp(-Dmu).*detspect{ii};
                % for quanmtum noise
%                 Eeff{ii}(:, iview) = gather(sqrt((Pmu * (samplekeV'.^2))./sum(Pmu, 2)));
                Eeff{ii}(:, iview) = gather( (Pmu*(samplekeV'.^2))./(Pmu*samplekeV') );
                % Pmu = integrol of Dmu 
                Pmu =  Pmu * samplekeV';
                Pmu = Pmu(:).*distscale(:, ifocal);
                P{ii}(:, iview) = gather(Pmu);
            case {'photoncount', 2}
                % photon counting
                Pmu = exp(-Dmu).*detspect{ii};
                Pmu = sum(Pmu, 2).*distscale(:, ifocal);
                P{ii}(:, iview) = gather(Pmu);
            case {'energyvector', 3}
                % maintain the components on energy
                Pmu = exp(-Dmu).*detspect{ii};
                Pmu = reshape(Pmu, Np, []).*distscale(:, ifocal);
                index_p = (1:Np) + Np*(iview-1);
                P{ii}(index_p, :) = gather(reshape(Pmu, Np, []));
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


function [Dmu_air, distscale] = airprojection(focalposition, detposition, detpixelarea, detnormv, bowtie, filter, samplekeV)

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

end
