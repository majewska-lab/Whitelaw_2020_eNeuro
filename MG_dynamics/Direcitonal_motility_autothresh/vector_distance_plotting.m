% Section for dividing up P2Y12 and PI3Kg KO ones (can be modified to
% isolate any a single
close all

% First, load summary data: average_all for samples and the array indices
% for each condition. Make sure there is a .mat file with the right name
% and data in it. 
input_dir = uigetdir();


pwd
cd(input_dir);
load('vector_distance_results.mat');

% Define subsamples, based on index corresponding to experimental
% condition; (i.e. which in 'average_all' correspond to the conditions...
% so these are a vector

average_all_subsample1 = average_all(:,:,:);

%subsample1 = control;
%subsample2 = P2Y12_KO;
%subsample3 = PI3Kg_KO;

% Separate out large results matrix using indices defined above
%average_all_subsample1 = average_all(:,:,subsample1);
%average_all_subsample2 = average_all(:,:,subsample2);
%average_all_subsample3 = average_all(:,:,subsample3);

% Script to generate a 'heatmap' plot of the direcitonal velocity as a
% function of time and distance: v(T,D)

% Take the average over all experiments, end up with 15 (distance) x 30
% (time matrix)
averages1 = mean(average_all_subsample1,3); % Gives 32 (time) by 15 (distance) matrix
averages1 = transpose(averages1); % Need to match axes in p.color plot
averages1(:,17) = []; % Get rid of disconinuity in imaging
averages1(:,1) = []; % Get rid of initial time point

% Define the axes variables:
T = [2:2:60]; % time
D = [5:8:120]; % distance

% Set up axes:
f1 = figure;
ax1 = axes();

% Plot the velocities as a 'heatmap' (my word)
s1 = pcolor(ax1,T,D,averages1);
s1.FaceColor = 'interp'; % Smooths out the colors

% Change colormap to blue -> red; and add bar on side
colormap jet
colorbar


% Label axes
ax1.FontSize = 14;
ax1.LabelFontSizeMultiplier = 1.6;
ax1.XLabel.String = 'Time (min)';
ax1.YLabel.String = 'Radius (um)';
ax1.XTick = [0:10:60];
ax1.CLim = [-4 4]; % Set scale of colorbar

s1.EdgeColor = [0 0 0]; % Edges are black lines; use 'none' for no edges
s1.LineStyle = ':'; % Make edges dotted lines

f1.Position = [1509 714 610 420]; % Make the figure a bit wider

saveas(f1,'control_fig.pdf');

%% Plot the second and third conditions:

%{
% subsample 2 corresponds to P2Y12_KO
averages2 = mean(average_all_subsample2,3); % Gives 32 (time) by 15 (distance) matrix
averages2 = transpose(averages2); % Need to match axes in p.color plot
averages2(:,17) = []; % Get rid of disconinuity in imaging
averages2(:,1) = []; % Get rid of initial time point

% Set up axes:
f2 = figure;
ax2 = axes();

% Plot the velocities as a 'heatmap' (my word)
s2 = pcolor(ax2,T,D,averages2);
s2.FaceColor = 'interp'; % Smooths out the colors

% Change colormap to blue -> red; and add bar on side
colormap jet
colorbar


% Label axes
ax2.FontSize = 14;
ax2.LabelFontSizeMultiplier = 1.6;
ax2.XLabel.String = 'Time (min)';
ax2.YLabel.String = 'Radius (um)';
ax2.XTick = [0:10:60];
ax2.CLim = [-4 4]; % Sets scale of colorbar

s2.EdgeColor = [0 0 0]; % Edges are black lines; use 'none' for no edges
s2.LineStyle = ':'; % Make edges dotted lines

f2.Position = [1509 714 610 420]; % Make the figure a bit wider

saveas(f2,'P2Y12_KO_fig.pdf')

% subsample 3 corresponds to PI3Kg_KO
averages3 = mean(average_all_subsample3,3); % Gives 32 (time) by 15 (distance) matrix
averages3 = transpose(averages3); % Need to match axes in p.color plot
averages3(:,17) = []; % Get rid of disconinuity in imaging
averages3(:,1) = []; % Get rid of initial time point

% Set up axes:
f3 = figure;
ax3 = axes();

% Plot the velocities as a 'heatmap' (my word)
s3 = pcolor(ax3,T,D,averages3);
s3.FaceColor = 'interp'; % Smooths out the colors

% Change colormap to blue -> red; and add bar on side
colormap jet
colorbar

% Label axes
ax3.FontSize = 14;
ax3.LabelFontSizeMultiplier = 1.6;

ax3.XLabel.String = 'Time (min)';
ax3.YLabel.String = 'Radius (um)';
ax3.XTick = [0:10:60];
ax3.CLim = [-4 4]; % Sets scale of colorbar

s3.EdgeColor = [0 0 0]; % Edges are black lines; use 'none' for no edges
s3.LineStyle = ':'; % Make edges dotted lines

f3.Position = [1509 714 610 420]; % Make the figure a bit wider

saveas(f3,'PI3Kg_KO.pdf')

%}

