function [in,out,opt] = spm_brick_realign(in,out,opt)
% Rigid-body registration of fmri volumes using SPM's realign
%
% SYNTAX:
% [in,out,opt] = spm_brick_realign(in,out,opt)
%
% IN (string) the name of a 4D fMRI volume. 
%
% OUT.PARAM 
%   (string, default same as input with a '_param.txt' suffix) the name of 
%   a .text file with motion parameters (translation along x, y, z, then 
%   rotation roll (y), pitch (x), yaw (z) in degrees
%
% OUT.TRANSF_W
%   (string, default same as input with a '_transf_w.mat' suffix) a .mat file 
%   with a 4x4 world-to-world transformation matrix from each volume to the 
%   volume of reference. The third dimension indexes the different volumes.
%
% OUT.TRANSF_V
%   (string, default same as input with a '_transf_v.mat' suffix) a .mat file 
%   with an updated 4x4 voxel-to-world transformation matrix from each volume 
%   to the volume of reference. The third dimension indexes the different 
%   volumes.
%
% OPT.QUALITY 
%   (scalar, between 0 and 1, default 0.9) Quality versus speed trade-off.  
%    Highest quality (1) gives most precise results, whereas lower qualities
%    gives faster realignment. The idea is that some voxels contribute little to
%    the estimation of the realignment parameters. This parameter is involved 
%    in selecting the number of voxels that are used.
%
% OPT.FWHM  
%    (scalar, default 5) The FWHM of the Gaussian smoothing kernel (mm) applied 
%    to the images before estimating the realignment parameters.
%
% OPT.SEP     
%    (scalar, default 4) the default separation (mm) to sample the images.
% 
% OPT.RTM      
%    (boolean, default 1) Register to mean.  If true then a two pass procedure 
%    is to be used in order to register the images to the mean of the images 
%    after the first realignment.
% 
% OPT.WRAP     
%    (vector 1x3, default [0 0 0]) Directions in the volume whose values should 
%    wrap around in. For example, in MRI scans, the images wrap around in the 
%    phase encode direction, so (e.g.) the subject's nose may poke into the back 
%    of the subject's head.
%
% OPT.INTERP
%   (integer, default 2) B-spline degree used for interpolation.
%
% OPT.FLAG_TEST 
%   (boolean, default false) if true, only update in, out and opt and does not 
%   perform any estimation.
% 
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2017
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : realignment, fmri

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

if nargin < 1
  error('Please specify IN. Type "help spm_brick_realign" for syntax')
end 

%% Check IN 
if ~ischar(in)
  error('IN should be a string')
end 
[path_f,name_f,ext_f] = niak_fileparts(in);
path_f = niak_full_path(path_f);

%% Check OUT 
if nargin < 2
  out = struct();
end
  
out_d.param    = [path_f name_f '_param.txt'];
out_d.transf_w = [path_f name_f '_transf_w.mat'];
out_d.transf_v = [path_f name_f '_transf_v.mat'];
out = psom_defaults(out_d,out);

%% Default options 
def = spm_get_defaults('realign.estimate');
def.flag_test = false;
if nargin < 3
  opt = struct();
end 
opt = psom_defaults(def,opt);

if opt.flag_test
  return
end 

%% tweak opt for spm 
opt_spm = rmfield(opt,'flag_test');
opt_spm.graphics = false;

%% Move to tmp
file_tmp = psom_file_tmp(['_' name_f '.nii']);
[hdr,vol] = niak_read_vol(in);
hdr.file_name = file_tmp;
niak_write_vol(hdr,vol);
V = spm_vol(file_tmp);

%% Split the input 4D file into 3D volumes
Vs = spm_realign(V,opt_spm);

%% Save the updated voxel-to-world transformation
if ~strcmp(out.transf_v,'skip')
  mat = zeros(4,4,length(V));
  for tt = 1:length(V)
    mat(:,:,tt) = Vs(tt).mat;
  end
  save(out.transf_v,'mat');
end 

%% Save the world-to-world transformation
if ~strcmp(out.transf_w,'skip')
  mat = zeros(4,4,length(V));
  for tt = 1:length(V)
    mat(:,:,tt) = Vs(tt).mat\V(tt).mat;
  end
  save(out.transf_w,'mat');
end 

%% Save the params
if ~strcmp(out.transf_w,'skip')
  param = zeros(length(V),6);
  for tt = 1:length(V)
    [rot,tsl] = niak_transf2param(Vs(tt).mat\V(tt).mat);
    param(tt,:) = [tsl' rot(3) rot(1) rot(2)];
  end
  save(out.param,'-ascii','param');
end 

%% Clean temporary file 
psom_clean(file_tmp);
