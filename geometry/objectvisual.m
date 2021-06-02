function [h, map] = objectvisual(object, hfig, color)
% to plot(mesh) an object
% [h, map] = objectvisual(object, hfig, color);
% or h = objectvisual(object);
% e.g.
%   f1=figure; hold on;
%   [h1, map1]=objectvisual(object1,f1,color1);  CD1=h1.CData;
%   [h2, map2]=objectvisual(object2,f1,color2);  CD2=h2.CData;
%   set(h1, 'CData', (CD1+1).*0.9999);  set(h2, 'CData', (CD2+1).*0.9999+2);
%   colormap([map1; map2]);
%   caxis([0,4]);
% to plot two objects in different color 


if nargin<2
    figure();
elseif isempty(hfig)
    figure(gcf);
else
    figure(hfig);
end
if nargin<3 || isempty(color)
    color = hsv2rgb(rand(1, 3).*0.8 + 0.2);
end

switch lower(object.type)
    case {'sphere', 'ellipsoid'}
        % sphere
        nshell = 20;
        nangle = 24;
        thetagrid = linspace(0, pi*2, nangle+1);
        phigrid = linspace(0, pi, nshell);
        X = sin(phigrid(:))*cos(thetagrid);
        Y = sin(phigrid(:))*sin(thetagrid);
        Z = repmat(cos(phigrid(:)), 1, nangle+1);   
    case {'cylinder'}
        % cylinder
        ncover = 5;
        nshell = 10;
        nangle = 24;
        thetagrid = linspace(0, pi*2, nangle+1);
        zshell = linspace(-1, 1, nshell);
        zgrid = [-ones(1, ncover) zshell ones(1, ncover)];
        rhocov = linspace(0, 1, ncover+1);
        rhogrid = [rhocov(1:end-1) ones(1, nshell) rhocov(end-1:-1:1)];
%         [theta, rho] = meshgrid(thetagrid, rhogrid);
        X = rhogrid(:)*cos(thetagrid);
        Y = rhogrid(:)*sin(thetagrid);
        Z = repmat(zgrid(:), 1, nangle+1);
    case 'tube'
        % cylinder without cover
        nshell = 12;
        nangle = 24;
        thetagrid = linspace(0, pi*2, nangle+1);
        zgrid = linspace(-1, 1, nshell);
        X = repmat(cos(thetagrid), nshell, 1);
        Y = repmat(sin(thetagrid), nshell, 1);
        Z = repmat(zgrid(:), 1, nangle+1);
    case 'cone'
        % cone
        if isfield(object, 'anglerange')
            anglerange = object.anglerange;
        else
            anglerange = [0 pi*2];
        end
        nangle = ceil(abs(anglerange(2)-anglerange(1))/pi*12);
        nshell = 12;
        thetagrid = linspace(anglerange(1), anglerange(2), nangle+1);
        zgrid = linspace(0, 1, nshell);
        X = zgrid(:)*cos(thetagrid);
        Y = zgrid(:)*sin(thetagrid);
        Z = repmat(zgrid(:), 1, nangle+1);
    otherwise
        warning('Unknown object type %s!', object.type);
        X = []; Y = []; Z = [];
end

gridsize = size(Z);
C = Z;
[X, Y, Z] = tac(reshape([X(:) Y(:) Z(:)]*object.V+object.O, [gridsize 3]), [1 2]);

cscale = linspace(0.6, 1.3, 64);
map = 1-cscale(:)*(1-color);
map(map>1) = 1;
map(map<0) = 0;

colormap(map);
h = mesh(X, Y, Z, C, 'FaceAlpha', 0.3);

end

