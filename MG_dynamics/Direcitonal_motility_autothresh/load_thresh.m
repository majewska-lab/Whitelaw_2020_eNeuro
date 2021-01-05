% Function to read a TIFF stack and a separate stack for it's tresholded image. 
% Essentially a wrapper for TIFFStack to load these images and convert to
% usuable workspace variables in matlab
% -Brendan Whitelaw, Majewska Lab, University of Rochester Neuroscience

% Input:
    % img_file: Image file name (.tif)
    % imgBW_file: Thresholded image file name
    
% Output:
    % stack: image stack converted to double and normalized (range 0 to 1)
    % stack_BW: thresholded image stack
    
% Dependent functions:
    % TIFFStack: https://www.mathworks.com/matlabcentral/fileexchange/32025-dylanmuir-tiffstack
    


function [stack, stack_BW] = load_thresh(img_file,imgBW_file)

% Load image stack and convert to normalized double
stack = TIFFStack(img_file);
stack = stack(:,:,:);
stack=double(stack); %Converts the image stack to double precision.
stack=stack/max(stack,[],'all'); %Normalizes image to highest value

% Load thresholded image stack and convert to logical, if not already
stack_BW = TIFFStack(imgBW_file);
stack_BW = stack_BW(:,:,:);
if ~islogical(stack_BW)
    stack_BW = imbinarize(stack_BW); 
end

end

