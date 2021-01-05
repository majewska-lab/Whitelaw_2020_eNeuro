% Analyze flow vectors:
    % (1) Generate final mask to restrict analysis to vectors to microglia
        % and given region, excluding injury site or pipet
    % (2) Calculate average direcitonal velocity
    % (3) Calculate convergence
    % (4) Generate quiver plot as RGB .tif
    
% Input:
    % results_file: output of ROIselection.m and generate_flowvectors.m functions
        % stack: image, 3D double array (xyt) with values from 0 to 1
        % stack_BW: thresholded image, 3D logical array (xyt)
        % ROI_center: center of ROI, 1x2 vector (x,y)
        % ROI_polygon: ROI for exclusion, mx2 matrix with (x,y) points for each vertex
        % pos_mat: contains x,y position coordinates for each pixel
        % velocity_mat: 4D (xyt by 2) array containing optic flow vectors (x,y) coordinates
        % directional_vel_mat: optic flow vectors in (towards,orthogonal) coordinates
    % analysis_settings: structure with the following fields:
        % pipet_yn: binary, 0 = laser injury, 1 = ATP puff
        % circle_analysis: binary, 
            % 0 = compute velocity average for whole image; 
            % 1 = restrict calculation to within defined radii
        % outer_radius: scalar, pixel length of outer radius
        % inner_radius: scalar, pixel length of inner radius
        % convergence_thickness: scalar, pixel length of convergence ROI 

        
function [final_mask,velocity_sum,mask_sum,velocity_avg,con_sum,con_size,con_frac] = analyze_flowvectors(results_file,analysis_settings)

% Load variables form ROIselection and generate_flowvectors functions
load(results_file,'stack_BW','ROI_center','ROI_polygon',...
    'velocity_mat','directional_vel_mat');

% (1) Generate final mask to restrict analysis and apply to velocity
% matrices
n_rows = size(stack_BW,1); % number of rows ('y-coordinate')
n_cols = size(stack_BW,2); % number of columns ('x-coordinate')
n_time = size(stack_BW,3); % number of time points

% final_mask is 3D, while some masks are 2D, but will multiply each 
% Initialize matrix for final mask:
final_mask = ones(n_rows,n_cols,n_time);

% Remove core or pipet:
% Generate mask of ROI_polygon
imshow(stack_BW(:,:,1));
ROI_polygon_object = impoly(gca,ROI_polygon);
ROI_polygon_img = createMask(ROI_polygon_object);
close(gcf);
ROI_polygon_mask = ones(n_rows,n_cols) - ROI_polygon_img;

% Multiply to final mask
final_mask = final_mask.*ROI_polygon_mask;

% Restrict to within circle of radius 'outer_radius' and outside circle
% radius 'inner_radius'
if analysis_settings.circle_analysis==1
    circle_outer = createCirclesMask([n_rows,n_cols],ROI_center,analysis_settings.outer_radius);
    circle_inner = createCirclesMask([n_rows,n_cols],ROI_center,analysis_settings.inner_radius);
    circle_mask = circle_outer - circle_inner;    
    final_mask = final_mask.*circle_mask;
end

% Generate 50-px radius circle around pipet tip to exclude from velocity
% analysis and use for convergence
if analysis_settings.pipet_yn ==1
    % 2) 
    pipet_radius_vector = 25; 
    pipet_circle_vector = createCirclesMask([n_rows,n_cols],ROI_center,pipet_radius_vector);
    pipet_circle_mask = ones(n_rows,n_cols)-pipet_circle_vector; % Inverse mask of pipet_circle
    final_mask = final_mask.*pipet_circle_mask;
end

% Mask by microglia:
final_mask = final_mask.*stack_BW;

% For soma analysis: mask by large objects: (need to fix the options here)
exclude_size = 0;
if exclude_size==1 
    obj_sz = 170;
    for i = 1:n_time
        final_mask(:,:,i) = bwareaopen(final_mask(:,:,i),obj_sz);
    end
end
% Mask velocity matrices using final mask:
velocity_mat = velocity_mat.*final_mask;
directional_vel_mat = directional_vel_mat.*final_mask;

% Get rid of NaN values in velocity matrices:
velocity_mat(isnan(velocity_mat))=0; % in (x,y) coordinates
directional_vel_mat(isnan(directional_vel_mat))=0; % in (towards,orthogonal) coordinates

% (2) Calculate Average directional velocity:
    % sum of towards component of all velocities / total pixels analyzed (final_mask)
% Results:
    % velocity_avg: 1xn_time vector of average directional velocity
velocity_sum = sum(directional_vel_mat(:,:,:,1),[1 2]);
velocity_sum = squeeze(velocity_sum); % velocity_sum is now a 1 x n_time vector
mask_sum = sum(final_mask,[1 2]);
mask_sum = squeeze(mask_sum); % mask_sum is now a 1 x n_time vector
velocity_avg = velocity_sum./mask_sum; % velocity_avg is a 1 x n_time vector;


% (3) Calculate convergence ('con'):
% Generally, does two steps: (i) generate and ROI from certain parameters;
% and (ii) calculates the fraction of that ROI occuppied in reference to a
% thresholded image stack (stack_BW). 

% Results:
    % con_sum: 1 x n_time vector, sum of absolute convergence (pixels)
    % con_size: scalar, total size of convergence ROI (pixels)
    % con_frac: 1 x n_time vector, fraction of convergence ROI covered
        % i.e. (con_sum / con_size)
% For laser injury: 
if ~analysis_settings.pipet_yn==1
    % Calculate approximate radius of central injury:
    core_xsize = max(ROI_polygon(:,1))-min(ROI_polygon(:,1));
    core_ysize = max(ROI_polygon(:,2))-min(ROI_polygon(:,2));
    core_diam = (core_xsize+core_ysize)/2;
    % Generate donut-shaped ROI around injury; thickness defined in settings
    con_radius = (core_diam/2) + analysis_settings.convergence_thickness;
    con_ROI = createCirclesMask([n_rows,n_cols],ROI_center,con_radius);
    con_ROI = con_ROI - ROI_polygon_img;
    
    % Mask thresholded image using this ROI
    con_mat = con_ROI .* stack_BW;
    con_sum = squeeze(sum(con_mat, [1 2])); % con_sum is a 1 x n_time vector for absolute (px) convergence
    con_size = sum(con_ROI,[1 2]); % con_size is a scalar referring to size (px)of the convergence ROI
    con_frac = con_sum/con_size; % con_frac is a 1 x n_time vector for normalized convergence (fraction occupied). 
   
% For ATP puff pipet experiments    
else
    % Generate circular ROI centered on tip of pipet and exclude pipet
    con_radius = analysis_settings.convergence_thickness;
    con_ROI = createCirclesMask([n_rows,n_cols],ROI_center,con_radius);
    con_ROI = con_ROI.*ROI_polygon_mask; 
    
    % Mask thresholded image using this ROI
    con_mat = con_ROI.*stack_BW;
    con_sum = squeeze(sum(con_mat, [1 2])); % con_sum is a 1 x n_time vector for absolute (px) convergence
    con_size = sum(con_ROI,[1 2]); % con_size is a scalar referring to size (px)of the convergence ROI
    con_frac = con_sum/con_size; % con_frac is a 1 x n_time vector for normalized convergence (fraction occupied).
end



% End of the function
end
