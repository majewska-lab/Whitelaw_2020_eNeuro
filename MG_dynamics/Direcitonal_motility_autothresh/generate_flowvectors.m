% Function to generate optic flow velocity vectors and calculate
% directional velocity relative to a given point (e.g. perform the
% rotational transformation to generate the components 'towards' and
% 'orthogonal' to the relaive position vector)

% Input:
    % img_file: full file path for original 3D (xyt) image file 
    % ROI_center: 1x2 column vector: central reference point to calculate relative
        % velocities. Coordinates in [x,y], corresponding to [column #, row #]
% Output:
    % pos_mat; % Cartesian coordinates: position matrix
    % velocity_mat; % Velocity vectors, cartesian coordinates
    % directional_vel_mat; % Direcitonal velocity


function [pos_mat, velocity_mat, directional_vel_mat] = generate_flowvectors(img_file,ROI_center)
%% Obtaining the flow info from your .tif file
    
stack = TIFFStack(img_file);
stack = stack(:,:,:); %Creates a working variable copying the orignal tif file
stack=double(stack); %Converts the image stack to double precision.
stack=stack/max(stack,[],'all'); %Normalizes image to highest value

xdim=size(stack,2);
ydim=size(stack,1);
tdim=size(stack,3);
%NOTE: the dimensions for stack are in (y=rows,x=columns,t)

%Initialize optic flow object
opticFlow = opticalFlowFarneback; %('NumPyramidLevels',3);%('NeighborhoodSize',10, 'FilterSize', 30);%'NeighborhoodSize',30);%, 'FilterSize', 15);

%Initialize an empty matrix to load values into.
xvel_export=[];yvel_export=[];mag_export=[];orient_export=[];
%Read in video frames and estimate optical flow of each frame.
for i=1:tdim
    frame=squeeze(stack(:,:,i));
    frameGray=mat2gray(frame,[0 1]);
    flow=estimateFlow(opticFlow,frameGray);
    %Export x,y velocites, magnitudes, and orientations of vectors 
    x_vel = [flow.Vx];
    y_vel = [flow.Vy];
    xvel_export(:,:,end+1)=x_vel;
    yvel_export(:,:,end+1)=y_vel;    
end

%Remove the first matrix(:,:,1) of these variables since they are
%empty because of how they were initiated. After this, their time size
%corresponds to the time size of the stack.
xvel_export(:,:,1)=[];
yvel_export(:,:,1)=[];

% Define image parameters
n_rows=size(xvel_export,1);
n_cols=size(xvel_export,2);
n_time=size(xvel_export,3);

% Concatenate velocity matrices to get one matrix.
velocity_mat=cat(4,xvel_export,yvel_export);
    
%% Use ROI_center coordinates to calculate directed motility

% Generated normalized relative position matrix for each pixel of the
% Make sure to do this in n_rows by n_cols notation (i.e. y by x)

%Generate matrices with column (x) and row (y) values relative to core center
cols=1:n_cols;
rows=1:n_rows;
[col_mat,row_mat]=meshgrid(cols,rows);
pos_mat=cat(3,col_mat,row_mat); % position matrix for output
col_mat_rel=-(col_mat-ROI_center(1)); % x-component of relative position vectors
row_mat_rel=-(row_mat-ROI_center(2)); % y-component of relative position vectors
rel_pos_mat=cat(3,col_mat_rel,row_mat_rel); % Relative position matrix

%Generate normalized relative position vector matrix: norm_rel_pos_mat
norm_rel_pos=vecnorm(rel_pos_mat,2,3); % Calculates the norm of each relative position vector
norm_row_mat=row_mat_rel./norm_rel_pos; % Normalizes x-components
norm_col_mat=col_mat_rel./norm_rel_pos; % Normalizes y-components
norm_rel_pos_mat=cat(3,norm_col_mat,norm_row_mat); 
norm_rel_pos_mat(isnan(norm_rel_pos_mat))=0; %Remove NaN (at center)

% Transformation of velocity vectors into components "towards" the core and "orthogonal" to the core
% Get the rotation angle (a) of the coordinate system for each pixel
angle_mat = atan2(norm_row_mat, norm_col_mat); % atan2(Y,X). Y coordinates correspond to the rows. X coordinates correspond to the columns.
% Transformation matrix is:
%       [cos(a), sin(a); -sin(a), cos(a)] 
% so that each new component is defined as:
%    toward = xvel*cos(a) + yvel*sin(a)
%    ortho = -xvel*sin(a) + yvel*cos(a)

vel_toward = []; % initialize toward-component matrix
vel_ortho = []; % initialize orthogonal-component matrix

for i=1:n_time
    vel_toward(:,:,i) = xvel_export(:,:,i).*cos(angle_mat) + yvel_export(:,:,i).*sin(angle_mat);
    vel_ortho(:,:,i) = -xvel_export(:,:,i).*sin(angle_mat) + yvel_export(:,:,i).*cos(angle_mat);
end
% Generate directional velocity matrix in 'towards-orthogonal' coordinates:
% 'vel_mat_tow_ort'
directional_vel_mat=cat(4,vel_toward,vel_ortho);


