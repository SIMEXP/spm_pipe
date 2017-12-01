function [in,out,opt] = spm_brick_realign(in,out,opt)
  
% Realign fmri volumes with SPM's realign
%
% SYNTAX:
% [in,out,opt] = spm_brick_realign(in,out,opt)
%
% IN (string) the name of a 4D fMRI volume. 
%
% OUT.PARAMS 
%   (string) the name of a .mat file with motion parameters
%
% OPT.SPM.QUALITY 
%   (scalar, between 0 and 1, default 0.9) Quality versus speed trade-off.  
%    Highest quality (1) gives most precise results, whereas lower qualities
%    gives faster realignment. The idea is that some voxels contribute little to
%    the estimation of the realignment parameters. This parameter is involved 
%    in selecting the number of voxels that are used.
%
% OPT.SPM.FWHM  
%    (scalar, default 5) The FWHM of the Gaussian smoothing kernel (mm) applied 
%    to the images before estimating the realignment parameters.
%
% OPT.SPM.SEP     
%    (scalar, default 4) the default separation (mm) to sample the images.
% 
% OPT.SPM.RTM      
%    (boolean, default 1) Register to mean.  If true then a two pass procedure 
%    is to be used in order to register the images to the mean of the images 
%    after the first realignment.
% 
% OPT.SPM.WRAP     
%    (vector 1x3, default [0 0 0]) Directions in the volume whose values should 
%    wrap around in. For example, in MRI scans, the images wrap around in the 
%    phase encode direction, so (e.g.) the subject's nose may poke into the back 
%    of the subject's head.
%
% OPT.SPM.INTERP
%   (integer, default 2) B-spline degree used for interpolation.
%
% OPT.METHOD 
%   (string, default first) the estimation method:
%   'first' use the first volume as target
%   'median' use the median volume as target 
%   'unbiased' use all volumes as target and 
%     combine the transformation 
%   'rtm' two pass procedure: Register to mean of the images after the first 
%     realignment.
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

if nargin < 2 
  error('Please specify IN and OUT. Type "help spm_brick_realign" for syntax')
end 

%% Check IN 
if ~ischar(in)
  error('IN should be a string')
end 

%% Check OUT 
out_d.params = NaN;
out = psom_defaults(out_d,out);

%% Default options 
def.spm = spm_get_defaults('realign.estimate');
def.spm = rmfield(def.spm,'rtm');
def.method = 'first';
def.flag_test = false;
if nargin < 3
  opt = struct();
end 
opt = psom_defaults(def,opt);

if opt.flag_test
  return
end 

%% Split the input 4D file into 3D volumes
path_tmp = psom_path_tmp('_realign');
[hdr,vol] = niak_read_vol(in);
list_file = cell(size(vol,4),1);
for tt = 1:size(vol,4)
  list_file{tt} = sprintf('vol%i.nii',tt);
  hdr.file_name = [path_tmp list_file{tt}];
  niak_write_vol(hdr,vol(:,:,:,tt));
end

spm_realign(char(list_file),opt.spm);
