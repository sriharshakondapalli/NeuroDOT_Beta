function PlotMeshSurface(mesh, params)

% PLOTMESHSURFACE Creates a 3D surface mesh visualization.
% 
%   PLOTMESHSURFACE(mesh) creates a 3D visualization of the surface mesh
%   "mesh". If no region data is provided in "mesh.region", all nodes will
%   be assumed to form a single region. If a field "data" is provided as
%   part of the "mesh" structure, that data will be used to color the
%   visualization. If both "data" and "region" are present, the "region"
%   values are used as an underlay for the colormapping.
%   
% 
%   PLOTMESHSURFACE(mesh, params) allows the user to specify parameters
%    for plot creation.
%
%   "params" fields that apply to this function (and their defaults):
%       fig_size    [20, 200, 1240, 420]        Default figure position
%                                               vector.
%       fig_handle  (none)                      Specifies a figure to
%                                               target.
%       Cmap.P      'jet'                       Colormap for positive data
%                                               values.
%       BG          [0.8, 0.8, 0.8]             Background color, as an RGB
%                                               triplet.
%       orientation 't'                         Select orientation of
%                                               volume. 't' for transverse,
%                                               's' for sagittal.
% 
%   Note: APPLYCMAP has further options for using "params" to specify
%   parameters for the fusion, scaling, and colormapping process.
% 
% Dependencies: APPLYCMAP
% 
% See Also: PLOTSLICES, PLOTCAP, CAP_FITTER.
% 
% Copyright (c) 2017 Washington University 
% Created By: Adam T. Eggebrecht
% Eggebrecht et al., 2014, Nature Photonics; Zeff et al., 2007, PNAS.
%
% Washington University hereby grants to you a non-transferable, 
% non-exclusive, royalty-free, non-commercial, research license to use 
% and copy the computer code that is provided here (the Software).  
% You agree to include this license and the above copyright notice in 
% all copies of the Software.  The Software may not be distributed, 
% shared, or transferred to any third party.  This license does not 
% grant any rights or licenses to any other patents, copyrights, or 
% other forms of intellectual property owned or controlled by Washington 
% University.
% 
% YOU AGREE THAT THE SOFTWARE PROVIDED HEREUNDER IS EXPERIMENTAL AND IS 
% PROVIDED AS IS, WITHOUT ANY WARRANTY OF ANY KIND, EXPRESSED OR 
% IMPLIED, INCLUDING WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY 
% OR FITNESS FOR ANY PARTICULAR PURPOSE, OR NON-INFRINGEMENT OF ANY 
% THIRD-PARTY PATENT, COPYRIGHT, OR ANY OTHER THIRD-PARTY RIGHT.  
% IN NO EVENT SHALL THE CREATORS OF THE SOFTWARE OR WASHINGTON 
% UNIVERSITY BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, OR 
% CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN ANY WAY CONNECTED WITH 
% THE SOFTWARE, THE USE OF THE SOFTWARE, OR THIS AGREEMENT, WHETHER 
% IN BREACH OF CONTRACT, TORT OR OTHERWISE, EVEN IF SUCH PARTY IS 
% ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


%% Parameters and Initialization
LineColor = 'k';
new_fig = 0;

if ~exist('params', 'var')
    params = [];
end

if ~isfield(params, 'orientation')
    params.orientation = 's';
end

if ~isfield(params, 'BGC')  ||  isempty(params.BGC)
    params.BGC = [1,1,1]; % Background color of figure
end

if ~isfield(params, 'fig_size')  ||  isempty(params.fig_size)
    params.fig_size = [20, 200, 560, 560];
end
if ~isfield(params, 'fig_handle')  ||  isempty(params.fig_handle)
    params.fig_handle = figure('Color',  'w',...
        'Position', params.fig_size);
    new_fig = 1;
else
    switch params.fig_handle.Type
        case 'figure'
            set(groot, 'CurrentFigure', params.fig_handle);
        case 'axes'
            set(gcf, 'CurrentAxes', params.fig_handle);
    end
end

if ~isfield(params,'Cmap'), params.Cmap=struct;end
if ~isstruct(params.Cmap)
    temp = params.Cmap;
    params.Cmap = [];
    params.Cmap.P = temp;
end
if ~isfield(params.Cmap,'P'), params.Cmap.P='gray';end
if ~isfield(params,'alpha'), params.alpha=1;end % Transparency
if ~isfield(params,'OL'), params.OL=0;end
if ~isfield(params,'reg'), params.reg=1;end
if ~isfield(params,'TC'),params.TC=0;end  
if ~isfield(params,'PD'), params.PD=0;end
if ~isfield(params,'EdgesON'), params.EdgesON=1;end
if ~isfield(params,'EdgeColor'), params.EdgeColor='k';end
if ~params.EdgesON, params.EdgeColor='none';end
params.cbmode=0; % colorbar ticks not yet supported. update outside fctn.

%% Get face centers of elements for S/D pairs.
switch size(mesh.elements, 2)
    case 4  % extract surface mesh from volume mesh
        TR = triangulation(mesh.elements, mesh.nodes);
        [m.elements, m.nodes] = freeBoundary(TR);
        [~, Ib] = ismember(m.nodes, mesh.nodes, 'rows');
        Ib(Ib == 0) = []; % Clear zero indices.
        if isfield(mesh,'region'), m.region=mesh.region(Ib);end
        if isfield(mesh,'data'), m.data=mesh.data(Ib);end
    case 3
        m=mesh;
end


%% mesh.data and mesh.region together determine coloring rules

if isfield(m,'region') && ~params.reg
    m=rmfield(m,'region');
end
    
if ~isfield(m,'data')       % NO DATA
    if ~isfield(m,'region') % no data, no regions
        cb=0;
        FaceColor = [0.25, 0.25, 0.25];
        EdgeColor = params.EdgeColor;
        FaceLighting = 'flat';
        AmbientStrength = 0.5;        
        h = patch('Faces', m.elements, 'Vertices',m.nodes,...
            'EdgeColor', EdgeColor, 'FaceColor', FaceColor,...
            'FaceLighting', FaceLighting,...
            'AmbientStrength', AmbientStrength);        
        
    else                      % data are regions               
        params.PD=1;
        params.TC=1;
        params.DR=max(m.region(:));
        tempCmap=params.Cmap.P;
        params.Cmap.P=eval([tempCmap, '(', num2str(params.DR), ');']);
        cb=1;
        CMAP=params.Cmap.P;
        EdgeColor = params.EdgeColor;
        FaceColor = 'flat';
        FaceLighting = 'gouraud';
        AmbientStrength = 0.25;
        DiffuseStrength = 0.75; % or 0.75
        SpecularStrength = 0.1;        
        FV_CData=params.Cmap.P(mode(reshape(m.region(m.elements(:)),[],3),2),:);        
        h = patch('Faces', m.elements, 'Vertices', m.nodes,...
            'EdgeColor', EdgeColor, 'FaceColor', FaceColor,...
            'FaceVertexCData', FV_CData, 'FaceLighting', FaceLighting,...
            'AmbientStrength', AmbientStrength, 'DiffuseStrength',... 
            DiffuseStrength,'SpecularStrength', SpecularStrength);        
    end
    
else                        % DATA
    if ~isfield(m,'region') % no regions
        if ~isfield(params,'BG'),params.BG=[0.25, 0.25, 0.25];end
        [FV_CData,CMAP] = applycmap(m.data, [], params);
    else                    % with regions: grayscale underlay
        [FV_CData,CMAP] = applycmap(m.data, m.region, params);
    end
    cb=1;
    EdgeColor = params.EdgeColor;
    FaceColor = 'interp';
    FaceLighting = 'gouraud';
    AmbientStrength = 0.25;
    DiffuseStrength = 0.75; % or 0.75
    SpecularStrength = 0.1;
    h = patch('Faces', m.elements, 'Vertices', m.nodes,...
        'EdgeColor', EdgeColor, 'FaceColor', FaceColor,...
        'FaceVertexCData', FV_CData, 'FaceLighting', FaceLighting,...
        'AmbientStrength', AmbientStrength, 'DiffuseStrength',...
        DiffuseStrength,'SpecularStrength', SpecularStrength);
end
        
        
set(gca, 'Color', params.BGC);%, 'XTick', [], 'YTick', [], 'ZTick', []);

switch params.orientation
    case 's'
        set(gca, 'ZDir', 'rev');
    case 't'
        set(gca, 'XDir', 'rev');
    case 'c'
        set(gca, 'YDir', 'rev');
end

axis image
% axis off
hold on
rotate3d on


%% Set additional lighting
% Lower lighting
light('Position', [-140, 90, -100], 'Style', 'local')
light('Position', [-140, -350, -100], 'Style', 'local')
light('Position', [300, 90, -100], 'Style', 'local')
light('Position', [300, -350, -100], 'Style', 'local')

% Higher lighting
light('Position', [-140, 90, 360], 'Style', 'local');
light('Position', [-140, -350, 360], 'Style', 'local');
light('Position', [300, 90, 360], 'Style', 'local');
light('Position', [300, -350, 360], 'Style', 'local');

xlabel('X', 'Color', LineColor)
ylabel('Y', 'Color', LineColor)
zlabel('Z', 'Color', LineColor)

if new_fig
    view(163, -86)
end

if isfield(params,'side')
    switch params.side
        case 'post'
            light('Position',[-500,-20,0],'Style','local');
            light('Position',[500,-20,0],'Style','local');
            light('Position',[0,-200,50],'Style','local');
        case 'dorsal'
            light('Position',[-500,-20,100],'Style','local');
            light('Position',[500,-20,100],'Style','local');
            light('Position',[100,-200,200],'Style','local');
            light('Position',[100,200,200],'Style','local');
            light('Position',[0,200,0],'Style','local');
            light('Position',[200,200,0],'Style','local');
            light('Position',[100,500,100],'Style','local');
        case 'coronal'
            if ~any(m.nodes(:)<0)
                light('Position',[-500,-20,100],'Style','local');
                light('Position',[500,-20,100],'Style','local');
                light('Position',[100,-200,200],'Style','local');
                light('Position',[100,200,200],'Style','local');
                light('Position',[0,200,0],'Style','local');
                light('Position',[200,200,0],'Style','local');
                light('Position',[100,500,100],'Style','local');
            else
                mm=mean(m.nodes);
                x=-mm(1);y=mm(2);z=-mm(3);
                light('Position',[-(x+400),y-150,z],'Style','local');
                light('Position',[x+400,y-150,z],'Style','local');
                light('Position',[x,-(y+50),z+100],'Style','local');
                light('Position',[x,y+50,z+100],'Style','local');
                % light('Position',[100,200,0],'Style','local');
                light('Position',[x-100,y+50,z-100],'Style','local');
                light('Position',[x+100,y+50,z-100],'Style','local');
                light('Position',[x,y+350,z],'Style','local');
            end
            
    end
end


% Add a colorbar.
if cb
    colormap(CMAP)
    h2 = colorbar('Color', LineColor);
    if params.cbmode
        set(h2, 'Ticks', params.cbticks, 'TickLabels', params.cblabels);
    end
end


%
