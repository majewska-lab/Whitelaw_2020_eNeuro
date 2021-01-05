%Pixel-based motility analysis for use with pre-thresholded movies (output
%of EM-threshold method in R).

% Input:
    % input_dir: folder containing thresholded movies.
    
% Output: 

% Dependent functions:
    % TIFFStack: https://github.com/DylanMuir/TIFFStack. Redownload if not
    % working
    
    

%Select input folder 
fprintf('Select input folder');
fprintf('\n')
input_dir = uigetdir();
addpath(input_dir);

%Get file list, and remove trailing spaces
input_list = dir(fullfile(input_dir,'*.tif'));
input_names = {input_list.name};
input_names = strtrim(input_names);

warning('off'); %Turn off warnings for TIFFStack

% Initialize a cell array to store data for each file/sample.
Results = {};

% Run pixel-based motility analysis on each file (internal function
% MotilityAnalysis.
for i=1:size(input_names,2)
    mot_results = MotilityAnalysis(fullfile(input_dir,input_names{i}));
    for j=1:size(mot_results,2)
    Results{j,i} = mot_results{j};
    end
    fprintf(strcat(num2str(i),'of',num2str(size(input_names,2))))
    fprintf('\n')
end

% Export motility data into one matrix:
motility_index = [];
for i=1:size(input_names,1)
    motility_index(:,i) = Results{5,i}(:);
end

% Export coverage data into one matrix:
coverage_index = [];
for i=1:size(input_names,1)
    coverage_index(:,i) = Results{6,i}(:);
end

motility = [];
surveillance = [];
for i = 1:size(input_names,2)
    motility(i) = Results{9,i};
    surveillance(i) = Results{8,i};
end

save(fullfile(input_dir,'mot_results.mat'), 'Results', 'coverage_index', 'motility_index','input_names');

fprintf('All DONE');
fprintf('\n')


% Define function for pixel-based motility analysis: on an image-by-image
% basis
function [motility_output] = MotilityAnalysis(file_path)
% Run pixel-based motility analysis
% Input:
    % Full path for file to be analyzed
% Output:
    % One-dimensional cell array with each element of analysis:
        % motility_output=cell(1,8);
        % motility_output{1,1}=extensionPix;
        % motility_output{1,2}=retractionPix;
        % motility_output{1,3}=stablePix;
        % motility_output{1,4}=blankPix;
        % motility_output{1,5}=motilityIndex;
        % motility_output{1,6}=coverageIndex;
        % motility_output{1,8}=coverage;
        % motility_output{1,9}=motility;
        % motility_output{1,10}=file;

[folder, file_name, ext] = fileparts(file_path);
fprintf('File selected: %s\n',file_name);
% Input variables: stack_BW. Dimensions for stack are in (y,x,t)

% Import thresholded TIFF stack and convert to logical
stack = TIFFStack(file_path);
stack = stack(:,:,:);
if ~islogical(stack)
    stack_BW = imbinarize(stack); 
end


%Create empty arrays to store variables
extensionPix = [];
retractionPix = [];
stablePix = [];
blankPix = [];

%Generate arrays for extension, retraction, stable, and blank pixels.
tdim=size(stack_BW,3); % Number of time points
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
motility_output=cell(1,8);
motility_output{1,1}=extensionPix;
motility_output{1,2}=retractionPix;
motility_output{1,3}=stablePix;
motility_output{1,4}=blankPix;
motility_output{1,5}=motilityIndex;
motility_output{1,6}=coverageIndex;
motility_output{1,8}=coverage;
motility_output{1,9}=motility;
motility_output{1,10}=file_name;
end


