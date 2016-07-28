function main(in, dim, rate, slice)
%
% USAGE: (in, dim, rate, slice)
%
%   in: vol, a 4d image
%   dim: 1=sagittal (default), 2=coronal, 3=axial
%   rate: # of volumes per second (default=10)
%   slice: slice to display (default=numerical middle slice)
%

% ------ Copyright (C) 2014 ------
%	Author: Bob Spunt
%	Affilitation: Caltech
%	Email: spunt@caltech.edu
%
%	$Revision Date: Aug_20_2014
if nargin < 3, rate = 10; end
if nargin < 2, dim = 1; end
if nargin < 1, error('USAGE: (in, dim, [slice])'); end
if iscell(in), in = char(in); end
h       = spm_vol(in);
nvol    = length(h);
dimvol  = h(1).dim;
if nargin < 4, slice = round(dimvol(dim)/2); end
fprintf('\n | - Reading data for %d image volumes', nvol);
d       = spm_read_vols(h);
if dim==1
    d       = imrotate(squeeze(d(slice, :, :, :)), 90);
elseif dim==2
    d       = imrotate(squeeze(d(:, slice, :, :)), 90);
else
    d       = imrotate(squeeze(d(:, :, slice, :)), 90);
end
fprintf(' - DONE\n');
playagain = 1; 
while playagain==1
    ddim = size(d);
    pos = [100 100 ddim([2 1])*10]; 
    figure('units', 'pixels', 'pos', pos, 'resize', 'off', 'color', 'black', 'menu', 'none', 'name', 'Timeseries Movie');    
    h1  = imagesc(d(:,:,1),[min(d(:)) max(d(:))]); colormap('gray'); axis off;
    f   = sprintf('%%0%dd', length(num2str(nvol))); 
    t   = title(sprintf(['Volume ' f ' of ' f], 1, nvol),  'FontName', 'Arial', 'Color', [1 1 1], 'FontSize', 20, 'FontWeight', 'bold');
    hold on; 
    for i=1:nvol
        set(t, 'String', sprintf(['Volume ' f ' of ' f], i, nvol)); 
        set(h1,'CData',autobrightvol(d(:,:,i)));
        pause(1/rate);
    end;
    % playagain = input('Play it again? [1=Yes, 2=No] ');
    playagain = 2;
    close gcf
end
end
function vol = uigetvol(message, multitag)
% UIGETVOL Dialogue for selecting image volume file
%
%   USAGE: vol = uigetvol(message, multitag)
%       
%       message = to display to user
%       multitag = (default = 0) tag to allow selecting multiple images 
%
if nargin < 2, multitag = 0; end
if nargin < 1, message = 'Select Image File'; end
if ~multitag
    [imname, pname] = uigetfile({'*.img; *.nii', 'Image File'; '*.*', 'All Files (*.*)'}, message);
else
    [imname, pname] = uigetfile({'*.img; *.nii', 'Image File'; '*.*', 'All Files (*.*)'}, message, 'MultiSelect', 'on');
end
if isequal(imname,0) || isequal(pname,0)
    vol = [];
else
    vol = fullfile(pname, strcat(imname));
end
end
function out = autobrightvol(in)
d = [min(in(:)) max(in(:))];
out = in; 
out(:) = scaledata(out(:), [0 1]);
out = imadjust(out);
out(:) = scaledata(out(:), d); 

end

function out = scaledata(in, minmax)
% SCALEDATA
%
% USAGE: out = scaledata(in, minmax)
%
% Example:
% a = [1 2 3 4 5];
% a_out = scaledata(a,0,1);
% 
% Output obtained: 
%            0    0.1111    0.2222    0.3333    0.4444
%       0.5556    0.6667    0.7778    0.8889    1.0000
%
% Program written by:
% Aniruddha Kembhavi, July 11, 2007
if nargin<2, minmax = [0 1]; end
if nargin<1, error('USAGE: out = scaledata(in, minmax)'); end
out = in - repmat(min(in), size(in, 1), 1); 
out = ((out./repmat(range(out), size(out,1), 1))*(minmax(2)-minmax(1))) + minmax(1); 
end
 
 
