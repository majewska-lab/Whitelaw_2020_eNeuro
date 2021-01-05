% Main script to run directional motility analysis from images:
% Option to use manual thresholding in MATLAB or to use pre-thresholded
% movies (requires thresholded stacks in 8-bit .tif format and with same
% name original images (with '_thresholded' appended to the end)

% At each step, for a given input image, intermediate data (e.g. ROI
% details, flow vectors) are saved in a results file as matlab variables.
% These variables which are then loaded within subsequent functions.

% Calls the following functions:
    % (0) load_thresh or TIFF_manthresh
    % (1) ROIselection: 
    % (2) generate_flowvectors:
    % (3) analyze_flowvectors:
    % (4) velocity_quiverplot:

% Input: 
    % img_dir: user selects a directory containing 3D-tifs (movies) for
        % analysis. 
    % imgBW_dir: user selects a directory containing thresholded 3D tifs.
        % Must have same name as files in img_dir, but with _BW appended to the
        % end (e.g. "filename_BW.tif").
    % User-defined inputs in dialog box:
          
% Output:
    % Results: 
    
% Dependent functions:
    % settingsdlg: https://www.mathworks.com/matlabcentral/fileexchange/26312-settings-dialog

close all
clearvars 

% Test if proper toolboxes are installed:
if ~license('test','Video_and_Image_Blockset') == 1
    error('Error: install Computer Vision Toolbox')
end
if ~license('test','Image_Toolbox') == 1
    error('Error: install Image Processing Toolbox')
end

fprintf('Select image file directory \n');
img_dir = uigetdir();


% (0) Select settings for analysis: 
[settings, button] = settingsdlg(...
    {'Look for old files?'; 'old_files'}, true, ...
    {'Re-analyze vectors?'; 'reanalyze'}, true, ...
    {'Manual threshold?'; 'man_thresh'}, false, ... 
    {'Pipet experiment?'; 'pipet_yn'}, true, ...
    {'Restrict analysis to circle?'; 'circle_analysis'}, true, ...
    {'Outer radius for anlaysis (px):'; 'outer_radius'}, 200, ...
    {'Inner radius for analysis (px):'; 'inner_radius'}, 0, ...
    {'Convergence analysis thickness (px)'; 'convergence_thickness'}, 40, ...
    {'Quiver plot?'; 'quiver_plot'}, true, ...
    {'Downsample (for quiver plot)'; 'downsample'}, 10 ...
);

if strcmp(button,'cancel') || isempty(button)
    fprintf('\n**** No settings were entered. Script stopped. *****\n\n\n');
    return
end

% Generate list of image files
input_list = dir(fullfile(img_dir,'*.tif'));
input_names = {input_list.name};
input_names = strtrim(input_names);

% Create directory to store results:
flow_results_dir = fullfile(img_dir,'flow_results');
mkdir(flow_results_dir);
% Generate file names for flow vectors to be saved
flow_results_names = strrep(input_names,'.tif','_flowresults.mat');


% (0) Read and threshold each images:
    % If thresholding was already completed, just select the folder with
    % the thresholded images
    % Else, do manual thresholding and save the images  

    
% Check if image and thresholded image already exist in .mat format:
if isfile(fullfile(flow_results_dir,flow_results_names{1})) == 0
    
if settings.man_thresh==0
    fprintf('Select thresholded image file directory \n');
    imgBW_dir = uigetdir();
    % Generate list of thresholded image files... note: default is to list
    % alphabetically, so the thresholded image files must have same order
    % alphabetically as original files!
    inputBW_list = dir(fullfile(imgBW_dir,'*.tif'));
    inputBW_names = {inputBW_list.name};
    inputBW_names = strtrim(inputBW_names);
    
    fprintf('Loading pre-thresholded images \n');
    for i = 1:size(input_names,2)
        img_file = fullfile(img_dir,input_names{i}); % Define image file name
        imgBW_file = fullfile(imgBW_dir,inputBW_names{i}); % Define thresholded image file name
        % Import original and thresholded image and save as workspace variables 
        [stack, stack_BW] = load_thresh(img_file,imgBW_file);
        results_file = fullfile(flow_results_dir,flow_results_names{i});
        save(results_file,'stack','stack_BW');
    end
        
else
    % Execute manual thresholding 
    for i = 1:size(input_names,2)
        img_file = fullfile(img_dir,input_names{i}); % Define image file name
        % Import original image, manually threshold, and save as workspace variables 
        [stack, stack_BW] = TIFF_manthresh(img_file);
        results_file = fullfile(flow_results_dir,flow_results_names{i});
        save(results_file,'stack','stack_BW');
    end   
end

end % end for file check

% (1) Select ROIs for each image:
    % For injury (pipet_yn = 0): draw polygon around core and calculates
    % center
    % For ATP puff (pipet_yn = 1): select center and draw polygon around
    % pipet

    
fprintf('Running ROI selection \n');
for i = 1:size(input_names,2)
    img_file = fullfile(img_dir,input_names{i}); % Define input file
    results_file = fullfile(flow_results_dir,flow_results_names{i}); % Define output file
        % Check if ROI selection has already occured
    results_vars = who('-file', results_file); 
    if ismember('ROI_center', results_vars) == 1
       fprintf("ROI selection already done \n") 
    else
        % Run if no ROI selection
        [ROI_center, ROI_polygon] = ROIselection(stack,stack_BW,settings.pipet_yn);
        save(results_file,'ROI_center','ROI_polygon','-append');
    end
end


% (2) Generate the velocity vectors, using optic flow 
    % Uses xyt .tif stack and ROI_center coordinates 
    % note: the flow vector data is too large to compile into one data
    % structure and should be saved for each file. 
    
  
fprintf('Running optic flow \n');
for i = 1:size(input_names,2)
    img_file = fullfile(img_dir,input_names{i});
    results_file = fullfile(flow_results_dir,flow_results_names{i});
    load(results_file,'ROI_center')
       % Check if optic flow has already occured
    results_vars = who('-file', results_file); 
    if ismember('velocity_mat', results_vars) == 1
       fprintf("Optic flow already done \n") 
    else
        % Run if no optic flow vectors done yet
        [pos_mat, velocity_mat, directional_vel_mat] = generate_flowvectors(img_file,ROI_center);
        save(results_file,'pos_mat','velocity_mat','directional_vel_mat','-append');
    end  
end


% (3) Analyze flow vectors:
    % Apply masks (microglia, radii, pipet or ablation)
    % Calculate average directional velocity within mask
    % Save data to flow_results.mat file
    
fprintf('Analyzing flow vectors \n');
for i = 1:size(input_names,2)
    results_file = fullfile(flow_results_dir,flow_results_names{i});
        % Check if vector analysis has been completed
    results_vars = who('-file', results_file); 
    if ismember('velocity_avg', results_vars) == 1 && settings.reanalyze == 0
       fprintf("Analyze vectors already done \n") 
    else
        % Run if no vector analysis done yet
        [final_mask,velocity_sum,mask_sum,velocity_avg,con_sum,con_size,con_frac] = ...
            analyze_flowvectors(results_file,settings);
        save(results_file,'final_mask','velocity_sum', 'mask_sum', 'velocity_avg',...
            'con_sum', 'con_size', 'con_frac', '-append');
    end
end

% (4) Generate quiver plots (optional)

if settings.quiver_plot
    % Make directory to store quiver plots (in img_dir)
    quiver_dir = fullfile(img_dir,'quiver');
    mkdir(quiver_dir);
    % Generate file names for quiver plots
    quiver_names = strrep(input_names,'.tif','_quiver.tif');
    
    for i = 1:size(input_names,2)
        results_file = fullfile(flow_results_dir,flow_results_names{i});
        quiver_file = fullfile(quiver_dir,quiver_names{i});
        quiver_flowvectors(results_file,quiver_file,settings.downsample);
    end
end


%% 
% Compile data from all samples into single arrays (or character arrays)

% Calculate smallest number of time points in all files:
n_times = [];
for i = 1:size(flow_results_names,2)
    results_file = fullfile(flow_results_dir,flow_results_names{i});
    load(results_file,'velocity_avg');
    n_times(i) = size(velocity_avg,1);
end
n_time = min(n_times); % smallest number of time points

% Initialize variables (matrices to copy into excel)
velocity_avg_mat = []; % Average directional velocity
con_size_mat = []; % Size of convergence ROI
con_frac_mat = []; % Normalized convergence
con_frac_adj_mat = []; % Normalized convergence subtracted by first time point

% Add results from each file/sample to matrix
for i = 1:size(flow_results_names,2)
    results_file = fullfile(flow_results_dir,flow_results_names{i});
    load(results_file,'velocity_avg','con_size','con_frac');
    velocity_avg_mat(1:n_time,i) = velocity_avg(1:n_time);
    con_size_mat(i) = con_size;
    con_frac_mat(1:n_time,i) = con_frac(1:n_time);
    con_frac_adj = con_frac - con_frac(1);
    con_frac_adj_mat(1:n_time,i) = con_frac_adj(1:n_time);
end

% Save summary data in new file
comp_results_file = fullfile(img_dir,strcat('all_results-',date()));
save(comp_results_file,'velocity_avg_mat','con_size_mat','con_frac_mat','con_frac_adj_mat','input_names','settings');

fprintf('\n ALL DONE \n');


