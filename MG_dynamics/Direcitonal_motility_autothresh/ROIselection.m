% Function to select regions of interest using original and thresholded image

% Input:
    % stack: original image, converted to double and normalized
    % stack_BW: thesholded image, as logical array
    % pipet_yn: binary; 0 = run laser ablation analysis; 1 = run ATP puff
        % analysis

% Output:
    % ROI_center: calculated from injury site polygon or point placed
        % at tip of pipet
    % ROI_polygon: polygon surrounding injury site or pipet, to be
        % cropped later in analysis

function [ROI_center, ROI_polygon] = ROIselection(stack,stack_BW,pipet_yn)

% For injury analysis, define injury core ROI and calculate center    
if ~pipet_yn==1
     
    fprintf('Draw polygon around injury core ... \n')
    fprintf('Click to add vertices, Right click to close shape, double click center to finish \n')
    
    figure;
    imshow(stack_BW(:,:,1)); %shows first time frame
    core=impoly; %generates 'polygon' object
    pos1=wait(core); % Waits for user to draw polygon
    ROI_polygon=getPosition(core); %gives position of polygon vertices 
    %as n by 2 matrix with x,y coordinates... so n_col by n_row
    %Calculate core_center in row by column coordinates
    core_center_x=(max(ROI_polygon(:,1))+min(ROI_polygon(:,1)))/2;
    core_center_y=(max(ROI_polygon(:,2))+min(ROI_polygon(:,2)))/2;
    ROI_center = cat(2,core_center_x,core_center_y);
    close(gcf);
    
% For ATP puff analysis, define tip of pipet and outline pipet
else % i.e. pipet_yn==1;
        
    % 1) Select tip of pipet to define ROI_center    
    fprintf('Click on tip of pipet ... \nUse normal button click to add point. \n')
    fprintf('Press Return or Enter after click \n')
    fprintf('Press delete or Backspace to remove point \n')
    
    figure;
    imshow(stack(:,:,1),[0 0.3]); %shows first time frame at high contrast/brightness
    [core_x, core_y] =getpts; % User selects point at tip of pipet
    ROI_center = cat(2,core_x,core_y);
    close(gcf);
 
    % 2) Draw polygon around pipet to define ROI_polygon
    fprintf('Draw polygon around pipet ... \n')
    fprintf('Click to add vertices, Right click to close shape, double click center to finish \n')
    
    figure;
    imshow(stack(:,:,15),[0 0.3]); %shows first time frame at high contrast/brightness
    pipet=impoly; %generates 'polygon' object
    pos1=wait(pipet);
    ROI_polygon=getPosition(pipet); %gives position of polygon vertices 
    %as n by 2 matrix with x,y coordinates... so n_col by n_row
    close(gcf);
end
    
end