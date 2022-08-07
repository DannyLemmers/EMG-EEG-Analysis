clear; clc; 
addpath("eeglab\");
eeglab nogui;
%%
datafolders = "D:\ThesisData\Data\P*";
participants = dir(datafolders);
% dataFolder = 'D:\ThesisData\Data\P12\EEG\set_filt';
% sets = dir(fullfile(dataFolder, '*.set'));
fs = 2000;
s50 = fs*50/1000;
sm250 = fs*250/1000;
load('EEGChannels64TMSi.mat');


for i = 1: length(participants)
    subjectNumber = str2double(participants(i).name(2:end));
    rawEEGPath = join(["D:\ThesisData\Data\P", subjectNumber, "\EEG\set_filt"], '');
    sets = dir(fullfile(rawEEGPath, '*.set'));
    for j = 1 : length(sets)
        EEG = pop_loadset(sets(j).name, sets(j).folder);
        data = EEG.data(:,s50:end-sm250,:);    
        snr= snrcalc(data);
        snr = mag2db(snr);
        channels = {ChanLocs.labels};
        channels = upper(channels);
        index = find(ismember(channels, ["M1", "M2"]));%% || channels == "M2");
        channels(index) = [];
        snr(index) = [];
        snr2(j,:) = snr;
        %figure(i)
        %plot_topography(channels, double(snr), false, 'EEGChannels64TMSi.mat');
    end
    figure(99+i)
    sgtitle(join(["SnR of Participant ", string(subjectNumber)], ''))
    subplot(311)
    plot_topography(channels, double(mean(snr2(1:8,:),1)), false, 'EEGChannels64TMSi.mat');
    title('Relax')
    subplot(312)
    plot_topography(channels, double(mean(snr2(9:16,:),1)), false, 'EEGChannels64TMSi.mat');
    title('Let go')
    subplot(313)
    plot_topography(channels, double(mean(snr2(17:24,:),1)), false, 'EEGChannels64TMSi.mat');
    title('Resist')
end

function snr = snrcalc(x)
    xavg = mean(x, 3);
    variance = var(x,0, 3);
    snr = sqrt(size(x,1)*(sum(xavg.^2,2))./sum(variance,2)); %64x1
end

function h = plot_topography(ch_list, values, make_contour, system, ...
    plot_channels, plot_clabels, INTERP_POINTS)
    % Error detection
    if nargin < 2, error('[plot_topography] Not enough parameters.');
    else
        if ~iscell(ch_list) && ~ischar(ch_list)
            error('[plot_topography] ch_list must be "all" or a cell array.');
        end
        if ~isnumeric(values)
            error('[plot_topography] values must be a numeric vector.');
        end
    end
    if nargin < 3, make_contour = false;
    else
        if make_contour~=1 && make_contour~=0
            error('[plot_topography] make_contour must be a boolean (true or false).');
        end
    end
    if nargin < 4, system = '10-20';
    else
        if ~ischar(system) && ~istable(system)
            error('[plot_topography] system must be a string or a table.');
        end
    end
    if nargin < 5, plot_channels = true;
    else
        if plot_channels~=1 && plot_channels~=0
            error('[plot_topography] plot_channels must be a boolean (true or false).');
        end
    end
    if nargin < 5, plot_clabels = false;
    else
        if plot_clabels~=1 && plot_clabels~=0
            error('[plot_topography] plot_clabels must be a boolean (true or false).');
        end
    end
    if nargin < 6, INTERP_POINTS = 1000;
    else
        if ~isnumeric(INTERP_POINTS)
            error('[plot_topography] N must be an integer.');
        else
            if mod(INTERP_POINTS,1) ~= 0
                error('[plot_topography] N must be an integer.');
            end
        end
    end
    
    % Loading electrode locations
    if ischar(system)
        switch system
            case '10-20'
                % 10-20 system
                load('Standard_10-20_81ch.mat', 'locations');
            case '10-10'
                % 10-10 system
                load('Standard_10-10_47ch.mat', 'locations');
            case 'yokogawa'
                % Yokogawa MEG system
                load('MEG_Yokogawa-440ag.mat', 'locations');
            otherwise
                % Custom path
                load(system, 'ChanLocs');
                locations = struct2table(ChanLocs);
                locations.labels = upper(locations.labels);
        end
    else
        % Custom table
        locations = system;
    end
    
    % Finding the desired electrodes
    ch_list = upper(ch_list);
    if ~iscell(ch_list)
        if strcmpi(ch_list,'all')
            idx = 1:length(locations.labels);
            if length(values) ~= length(idx)
                error('[plot_topography] There must be a value for each of the %i channels.', length(idx));
            end
        else, error('[plot_topography] ch_list must be "all" or a cell array.');
        end
    else
        if length(values) ~= length(ch_list)
            error('[plot_topography] values must have the same length as ch_list.');
        end
        idx = NaN(length(ch_list),1);
        for ch = 1:length(ch_list)
            if isempty(find(strcmp(locations.labels,ch_list{ch})))
                warning('[plot_topography] Cannot find the %s electrode.',ch_list{ch});
                ch_list{ch} = [];
                values(ch)  = [];
                idx(ch)     = [];
            else
                idx(ch) = find(strcmp(locations.labels,ch_list{ch}));
            end
        end
    end
    values = values(:);
    
    % Global parameters
    %   Note: Head radius should be set as 0.6388 if the 10-20 system is used.
    %   This number was calculated taking into account that the distance from Fpz
    %   to Oz is d=2*0.511. Thus, if the circle head must cross the nasion and
    %   the inion, it should be set at 5d/8 = 0.6388.
    %   Note2: When the number of interpolation points rises, the plots become
    %   smoother and more accurate, however, computational time also rises.
    HEAD_RADIUS     = 0.6388;%5*2*0.511/8;  % 1/2  of the nasion-inion distance
    HEAD_EXTRA      = 1*2*0.511/8;  % 1/10 of the nasion-inion distance
    k = 4;                          % Number of nearest neighbors for interpolation
    
    % Interpolating input data
        % Creating the rectangle grid (-1,1)
        [ch_x, ch_y] = pol2cart((pi/180).*((-1).*locations.theta(idx)+90), ...
                                locations.radius(idx));     % X, Y channel coords
        % Points out of the head to reach more natural interpolation
        r_ext_points = 1.2;
        [add_x, add_y] = pol2cart(0:pi/4:7*pi/4,r_ext_points*ones(1,8));
        linear_grid = linspace(-r_ext_points,r_ext_points,INTERP_POINTS);         % Linear grid (-1,1)
        [interp_x, interp_y] = meshgrid(linear_grid, linear_grid);
        
        % Interpolate and create the mask
        outer_rho = max(locations.radius(idx));
        if outer_rho > HEAD_RADIUS, mask_radius = outer_rho + HEAD_EXTRA;
        else,                       mask_radius = HEAD_RADIUS;
        end
        mask = (sqrt(interp_x.^2 + interp_y.^2) <= mask_radius); 
        add_values = compute_nearest_values([add_x(:), add_y(:)], [ch_x(:), ch_y(:)], values(:), k);
        interp_z = griddata([ch_x(:); add_x(:)], [ch_y(:); add_y(:)], [values; add_values(:)], interp_x, interp_y, 'natural');
        interp_z(mask == 0) = NaN;
        % Plotting the final interpolation
        pcolor(interp_x, interp_y, interp_z);
        shading interp;
        hold on;
        
        % Contour
        if make_contour
            [~, hfigc] = contour(interp_x, interp_y, interp_z); 
            set(hfigc, 'LineWidth',0.75, 'Color', [0.2 0.2 0.2]); 
            hold on;
        end
    % Plotting the head limits as a circle         
    head_rho    = HEAD_RADIUS;                      % Head radius
    if strcmp(system,'yokogawa'), head_rho = 0.45; end
    head_theta  = linspace(0,2*pi,INTERP_POINTS);   % From 0 to 360Âº
    head_x      = head_rho.*cos(head_theta);        % Cartesian X of the head
    head_y      = head_rho.*sin(head_theta);        % Cartesian Y of the head
    plot(head_x, head_y, 'Color', 'k', 'LineWidth',4);
    hold on;
    % Plotting the nose
    nt = 0.15;      % Half-nose width (in percentage of pi/2)
    nr = 0.22;      % Nose length (in radius units)
    nose_rho   = [head_rho, head_rho+head_rho*nr, head_rho];
    nose_theta = [(pi/2)+(nt*pi/2), pi/2, (pi/2)-(nt*pi/2)];
    nose_x     = nose_rho.*cos(nose_theta);
    nose_y     = nose_rho.*sin(nose_theta);
    plot(nose_x, nose_y, 'Color', 'k', 'LineWidth',4);
    hold on;
    % Plotting the ears as ellipses
    ellipse_a = 0.08;                               % Horizontal exentricity
    ellipse_b = 0.16;                               % Vertical exentricity
    ear_angle = 0.9*pi/8;                           % Mask angle
    offset    = 0.05*HEAD_RADIUS;                   % Ear offset
    ear_rho   = @(ear_theta) 1./(sqrt(((cos(ear_theta).^2)./(ellipse_a^2)) ...
        +((sin(ear_theta).^2)./(ellipse_b^2))));    % Ellipse formula in polar coords
    ear_theta_right = linspace(-pi/2-ear_angle,pi/2+ear_angle,INTERP_POINTS);
    ear_theta_left  = linspace(pi/2-ear_angle,3*pi/2+ear_angle,INTERP_POINTS);
    ear_x_right = ear_rho(ear_theta_right).*cos(ear_theta_right);          
    ear_y_right = ear_rho(ear_theta_right).*sin(ear_theta_right); 
    ear_x_left  = ear_rho(ear_theta_left).*cos(ear_theta_left);         
    ear_y_left  = ear_rho(ear_theta_left).*sin(ear_theta_left); 
    plot(ear_x_right+head_rho+offset, ear_y_right, 'Color', 'k', 'LineWidth',4); hold on;
    plot(ear_x_left-head_rho-offset, ear_y_left, 'Color', 'k', 'LineWidth',4); hold on;
    % Plotting the electrodes
    % [ch_x, ch_y] = pol2cart((pi/180).*(locations.theta(idx)+90), locations.radius(idx));
    if plot_channels, he = scatter(ch_x, ch_y, 60,'k', 'LineWidth',1.5); end
    if plot_clabels, text(ch_x, ch_y, ch_list); end
    if strcmp(system,'yokogawa'), delete(he); plot(ch_x, ch_y, '.k'); end
    
    % Last considerations
    max_height = max([max(nose_y), mask_radius]);
    min_height = -mask_radius;
    max_width  = max([max(ear_x_right+head_rho+offset), mask_radius]);
    min_width  = -max_width;
    L = max([min_height, max_height, min_width, max_width]);
    xlim([-L, L]);
    ylim([-L, L]);  
    colorbar;   % Feel free to modify caxis after calling the function
    axis square;
    axis off;
    hold off;
    h = gcf;
end
% This function compute the mean values of the k-nearest neighbors
%   - coor_add:     XY coordinates of the virtual electrodes
%   - coor_neigh:   XY coordinates of the real electrodes
%   - val_neigh:    Values of the real electrodes
%   - k:            Number of neighbors to consider
function add_val = compute_nearest_values(coor_add, coor_neigh, val_neigh, k)
    
    add_val = NaN(size(coor_add,1),1);
    L = length(add_val);
    
    for i = 1:L
        % Distances between the added electrode and the original ones
        target = repmat(coor_add(i,:),size(coor_neigh,1),1);
        d = sqrt(sum((target-coor_neigh).^2,2));
        
        % K-nearest neighbors
        [~, idx] = sort(d,'ascend');
        idx = idx(2:1+k);
        
        % Final value as the mean value of the k-nearest neighbors
        add_val(i) = mean(val_neigh(idx));
    end
    
end