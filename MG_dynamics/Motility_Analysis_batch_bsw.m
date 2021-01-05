%Motility analysis: This requires an xyt time series
%image that is cropped to remove any blank space from registration.

% Pre-processing:
% (1) Select input and output directories and gather file list (.tif)
% (2) Import TIF and manually set threshold based on first time point
% (3) Save thresholded images as .mat workspace and binary .tif stack. 
% Analysis:
% (1) Loads thresholded movies
% (2) Runs pixel-based motility analysis (extended, retracted, motility
%     index, surveillance/coverage (i.e. total pixels covered), etc.

%Select input folder 
fprintf('Select input folder');
input_dir=uigetdir();
addpath(input_dir);
%Get file list, and remove trailing spaces
input_names=list_directory(input_dir,'.tif');
input_names=strtrim(input_names);
%Run ablation analysis for each file
warning('off'); %Turn off warnings for TIFFStack
fprintf('Running preprocessing')
fprintf('\n')

% For each image file in imput directory, run the preprocessing funciton.
% This will allow the user to input a new threshold based on the first time
% point. It will save the thresholded stacks as .tif files in one folder
% and also as .mat files in another, to be used in the analysis seciton.
thresh_store = []; % initialize empty array to store threshold values
for i=1:size(input_names,1)
    [thresh, percentile] = MotilityPre(input_dir,input_names{i});
    thresh_store(1,i) = thresh;
    thresh_store(2,i) = percentile; 
    fprintf(strcat(num2str(i),'of',num2str(size(input_names,1))))
    fprintf('\n')
end

fprintf('Running analysis')
fprintf('\n')
% For each thresholded image stack ('.mat' files), it will run the motility
% analysis similar to GO Sipe's program.

% Initialize a cell array to store data for each run. 
Results = {};

for i=1:size(input_names,1)
    mot_results = MotilityAnalysis(input_dir,input_names{i});
    for j=1:size(mot_results,2)
    Results{j,i} = mot_results{j};
    end
    fprintf(strcat(num2str(i),'of',num2str(size(input_names,1))))
    fprintf('\n')
end

% Export motility data into one matrix:
motility_index = [];
for i=1:size(input_names,1)
    motility_index(:,i) = Results{5,i}(:);
end
motility_avg = mean(motility_index,1);

% Export coverage data into one matrix:
coverage = [];
for i=1:size(input_names,1)
    coverage(i) = Results{8,i};
end

mot_results_name = fullfile(input_dir,strcat('mot_results-',date()));
save(mot_results_name,'input_names','motility_index','motility_avg','coverage');

fprintf('All DONE');
fprintf('\n')

% Define function for ablation analysis
function [thresh, percentile] = MotilityPre(input_dir,file)
%Saves thresholded image as tif stack to input folder for later viewing.
%Saves thresholded image as MAT file
fprintf('File selected: %s\n',file);
cd(input_dir);
mkdir('Thresholded_images');
BW_dir=fullfile(input_dir,'Thresholded_images');
BWfilename=strrep(file,'.tif','BW');
BWfilename=strcat(BWfilename,'.tif');
BWfile=fullfile(BW_dir,BWfilename);

if ~exist(BWfile)

    Img = TIFFStack(file);
    stack = Img(:,:,:); %Creates a working variable copying the orignal tif file
    stack=double(stack); %Converts the image stack to double precision.
    stack=stack/max(max(max(stack)));
    xdim=size(stack,2);
    ydim=size(stack,1);
    tdim=size(stack,3);
    %NOTE: the dimensions for stack are in (y,x,t)

    % Create image of first time point
    stack_init = squeeze(stack(:,:,1));
    % Open thresh_tool function to generate threshold;
    [newthresh, stack_init_BW] = thresh_tool(stack_init);

    % Calculate the 'percentile' at which the threshold was set.
    stack_init_vec = stack_init(:);
    percentile = 0; % Use the second line if you want to save this... but
    % need the invprctile function
    % percentile = invprctile(stack_init_vec,newthresh);
  
    % Binarize image at new threshold for each time point. The save as
    % a .tif file.
    stack_BW = []; % Initialize empty array
    for i=1:tdim
        stack_BW(:,:,i) = imbinarize(stack(:,:,i),newthresh);
    end

    %Save binarized video as TIFF stack into new folder 
    cd(BW_dir);
    imwrite(stack_BW(:,:,1),BWfilename);
    for j=2:tdim
        imwrite(stack_BW(:,:,j),BWfilename,'WriteMode','append')
    end

    %Save threshold and thresholded stack as .mat file into 'Thresholded_stacks' folder
    cd(input_dir);
    mkdir('Thresholded_stacks');
    output1_dir=fullfile(input_dir,'Thresholded_stacks');
    cd(output1_dir);
    MATfilename1=strrep(file,'.tif','stackBW');
    MATfilename1=strcat(MATfilename1,'.mat');
    save(MATfilename1,'newthresh','stack_BW')

    close all
    thresh = newthresh;
else
    thresh = 0;
    percentile = 0; 
 
end % If thresholded image file already exists, it won't redo it. 


end


% Define function for motility analysis
% Requires a binarized xyt stack, as a variable in a '.mat' file
function [output2] = MotilityAnalysis(input_dir,file)
%Analyzes output1 and saves analysis as excel spread sheet in output directory
fprintf('File selected: %s\n',file, '%s\n');
%Input variables: stack_BW. Dimensions for stack are in (y,x,t)
output1_dir = fullfile(input_dir,'Thresholded_stacks');
cd(output1_dir);
file_name = strrep(file,'.tif','stackBW.mat');
load(file_name,'stack_BW');
xdim=size(stack_BW,2);
ydim=size(stack_BW,1);
tdim=size(stack_BW,3);

%Create empty arrays to store variables
extensionPix = [];
retractionPix = [];
stablePix = [];
blankPix = [];
%Generate arrays for extension, retraction, stable, and blank pixels.
for j=1:tdim-1
    img_sum=stack_BW(:,:,j)+2*stack_BW(:,:,j+1);
    extended=img_sum==2;
    extensionPix(j)=sum(extended,'all');
    retracted=img_sum==1;
    retractionPix(j)=sum(retracted,'all');
    stable=img_sum==3;
    stablePix(j)=sum(stable,'all');
    blank=img_sum==0;
    blankPix(j)=sum(blank,'all');
end
% Calculate motility index at each timepoint
motilityIndex = (extensionPix+retractionPix)./stablePix;
% Calculate coverage index at each timepoint
coverageIndex = (extensionPix + stablePix)./(extensionPix+retractionPix+stablePix+blankPix);

% Calculate surveillance, process coverage, and average motility between pre
% and post treatment 
% Creates the Max T-projeciton of binarized images
coverage_BW=max(stack_BW(:,:,:),[],3); 
% Calculate the fraction of pixels occupied by microglia in the Max-T
% projection
coverage=sum(coverage_BW,'all')/numel(coverage_BW);
% Calculate the average motility index across all time points.
motility=mean(motilityIndex(:));

% In future, I can put in pixel coverage at each time point

%Export data into cell array 
output2=cell(1,8);
output2{1,1}=extensionPix;
output2{1,2}=retractionPix;
output2{1,3}=stablePix;
output2{1,4}=blankPix;
output2{1,5}=motilityIndex;
output2{1,6}=coverageIndex;
output2{1,8}=coverage;
output2{1,9}=motility;
output2{1,10}=file;
end


