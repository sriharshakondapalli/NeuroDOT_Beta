function [A,dim]=GtoAmat(Gs,Gd,mesh,dc,flags)

% This function take a set of Green's functions and a mesh and creates an
% A-matrix.
%
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

%% Paramters
flags.keepmeth='glevel';
if ~isfield(flags,'gthresh'),flags.gthresh=10^-3;end
if ~isfield(flags,'voxmm'),flags.voxmm=2;end
flags.GV=1;


%% Interpolate  
disp('>Finding Voxel Grid and Cropping Limits')
[vox,dim]=getvox(mesh.nodes,cat(2,Gs,Gd),flags);

disp('>Finding Mesh to Voxel Converstion')
[t,p] = tsearchn(mesh.nodes,mesh.elements,reshape(vox,[],3));

disp('>Interpolating Greens Functions')
Gs=voxel(Gs,t,p,mesh.elements,dim);
Gd=voxel(Gd,t,p,mesh.elements,dim);

disp('>Interpolating Optical Properties')
dc=voxel(dc,t,p,mesh.elements,dim);


%% Create dim.Good_Vox
if flags.GV==1
    [Gs,Gd,dc,dim]=Make_Good_Vox(Gs,Gd,dc,dim,mesh,flags);
end


%% Save voxellated G etc
disp('Saving Voxellated Green''s Functions')
save(['GFunc_',flags.tag,'_VOX.mat'],'Gs','Gd','dim','flags',...
    't','p','dc','vox','-v7.3')
clear vox p t


%% Create A-matrix
disp('>Making A-Matrix')
[A,Gsd]=g2a(Gs,Gd,dc,dim,flags);
clear Gs Gd 
disp('>Saving A-Matrix')
save(['A_',flags.tag],'A','dim','flags','Gsd','-v7.3')