% Function to generate color-coded quiver plots of velocity from optic flow
% data and analysis

% -Brendan Whitelaw, Majewska Lab, University of Rochester Neuroscience

% Input:
    % results_file: filepath for matlab variables containing analysis results
        % requires 'stack', 'velocity_mat', 'directional_vel_mat', and 'final_mask'
        % as variables
    % quiver_file: filepath to save quiver plots
    % downsample: degree of downsampling for plotting velocity vectors
    
% Output:
% Saves quiver plot in location defined by the quiver_file path

function [] = quiver_flowvectors(results_file, quiver_file, downsample)

% Load variables into workspace:
load(results_file,'stack','velocity_mat','directional_vel_mat','final_mask','pos_mat');

n_time = size(stack,3); % Define number of frames

% Split up x and y velocity and position matrices:
velocity_mat(isnan(velocity_mat)) = 0;
xvel = squeeze(velocity_mat(:,:,:,1));
yvel = squeeze(velocity_mat(:,:,:,2));

xpos = squeeze(pos_mat(:,:,1));
ypos = squeeze(pos_mat(:,:,2));

% Generate separate masks for positive and negative directional velocity for
% eventual color coding of velocity vectors
directional_vel = squeeze(directional_vel_mat(:,:,:,1)); % Matrix containing net directional velocity
directional_vel(:,:,1)=0; % Set velocity at initial time point to zero
directional_vel(isnan(directional_vel))=0;
% Make positive mask --> green color
positive_mask = directional_vel > 0 & final_mask > 0; % Use logical indexing to make mask
% Make negative mask --> red color
negative_mask = directional_vel < 0 & final_mask > 0;

% Apply masks to separate velocity matrices
positive_xvel = xvel .* positive_mask;
negative_xvel = xvel .* negative_mask;
positive_yvel = yvel .* positive_mask;
negative_yvel = yvel .* negative_mask;


% Save 1st frame without quiver plot (not considered in the analysis)
figure
imshow(stack(:,:,1),'Border','tight');
frame = getframe(gcf);
imwrite(frame.cdata,quiver_file);

for k=2:n_time
    
    %Filter velocity vectors with an average filter, circle radius 4.
    h=fspecial('disk',4);
    posi_xvel_filt=imfilter(positive_xvel(:,:,k),h);
    posi_yvel_filt=imfilter(positive_yvel(:,:,k),h);
    neg_xvel_filt=imfilter(negative_xvel(:,:,k),h);
    neg_yvel_filt=imfilter(negative_yvel(:,:,k),h);
    
    %Downsample velocity and position matrices (to avoid plotting all of
    %them)
    posi_xvel_filt2=posi_xvel_filt(1:downsample:end,1:downsample:end);
    posi_yvel_filt2=posi_yvel_filt(1:downsample:end,1:downsample:end);
    neg_xvel_filt2=neg_xvel_filt(1:downsample:end,1:downsample:end);
    neg_yvel_filt2=neg_yvel_filt(1:downsample:end,1:downsample:end);
    xpos2=xpos(1:downsample:end,1:downsample:end);
    ypos2=ypos(1:downsample:end,1:downsample:end);
    
    figure
    imshow(stack(:,:,k),'Border','tight');
    hold on;
    quiver(xpos2,ypos2,posi_xvel_filt2,posi_yvel_filt2,3,'Color', 'g');
    quiver(xpos2,ypos2,neg_xvel_filt2,neg_yvel_filt2,3,'Color', 'r');
    hold off
    frame = getframe(gcf);
    %Save .tif with the quiver plot
    imwrite(frame.cdata,quiver_file,'WriteMode','append');
    close all
end
end
