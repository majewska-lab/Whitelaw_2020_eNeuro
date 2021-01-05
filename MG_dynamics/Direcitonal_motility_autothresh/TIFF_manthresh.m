% Function ot read a TIFF stack and manually threshold it. Essentially a
% wrapper for TIFFStack and thresh_tool functions
% -Brendan Whitelaw, Majewska Lab, University of Rochester Neuroscience

% Input:
    % Image file name (.tif)
    
% Output:
    % stack: image stack converted to double and normalized (range 0 to 1)
    % stack_BW: thresholded image stack
    
% Dependent functions:
    % TIFFStack: https://www.mathworks.com/matlabcentral/fileexchange/32025-dylanmuir-tiffstack
    % thresh_tool: https://www.mathworks.com/matlabcentral/fileexchange/6770-thresholding-tool


function [stack, stack_BW] = TIFF_manthresh(img_file)

% Load image stack and convert to normalized double
stack = TIFFStack(img_file);
stack = stack(:,:,:);
stack=double(stack); %Converts the image stack to double precision.
stack=stack/max(stack,[],'all'); %Normalizes image to highest value

% Threshold image file
stack_init = squeeze(stack(:,:,1)); % Create image of initial time point
[newthresh, ~] = thresh_tool(stack_init); % Call thresh_tool for manual threshold selection
stack_BW = imbinarize(stack,newthresh); % Binarize image

end

