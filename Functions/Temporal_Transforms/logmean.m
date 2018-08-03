function data_out = logmean(data_in)

% LOGMEAN Takes the log-ratio of raw intensity data.
%
%   data_out = LOGMEAN(data_in) takes a light-level data array "data_in" of
%   the format MEAS x TIME, and takes the negative log of each element of a
%   row divided by that row's average. The result is output into "data_out"
%   in the same MEAS x TIME format.
%
%   The formal equation for the LOGMEAN operation is:
%        y_{out} = -log(y_{in} / <y_{in}>)
%
%   If the data is complex (as in the frequency domain case), Y is
%   converted into amplitude and phase for the Rytov approximation:
%       Y_amp=abs(y_{in});
%       Y_phase=angle(y_{in});
%       <Y_amp>=abs(mean(y_{in}));
%       <Y_phase>=angle(mean(y_{in}));
%
%       Y_Rytov_amp=-log(Y_amp / <Y_amp>);
%       Y_Rytov_phase=-(Y_phase - <Y_phase>);
%
%       y_{out} = Y_Rytov_amp .* exp(i.*Y_Rytov_phase);
%
%   Example: If data = [1, 10, 100; exp(1), 10*exp(1), 100*exp(1)];
%
%   then LOGMEAN(data) yields [3.6109, 1.3083, -.9943; 3.6109, 1.3083,
%   -.9943].
%
% See Also: LOWPASS, HIGHPASS.
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

%% Parameters and Initialization.
dims = size(data_in);
Nt = dims(end); % Assumes time is always the last dimension.
NDtf = (ndims(data_in) > 2);
isZ=any(~isreal(data_in(:)));

%% N-D Input.
if NDtf
    data_in = reshape(data_in, [], Nt);
end

%% Perform Logmean.
if ~isZ % All Real
    data_out = -log(bsxfun(@rdivide, data_in, mean(data_in, 2)));
else
    Y_amp0=abs(mean(data_in,2));
    Y_ph0=angle(mean(data_in,2));
    
    Y_Ry_amp=-log(bsxfun(@rdivide, abs(data_in), Y_amp0));
    Y_Ry_ph=-(bsxfun(@minus, angle(data_in), Y_ph0));
    
    data_out=Y_Ry_amp.*exp(1i.*Y_Ry_ph);
end

%% N-D Output.
if NDtf
    data_out = reshape(data_out, dims);
end



%
