%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is used for observing the difference between leg and wheel
% Especially for the different characteristics on different terrains
%
% Geometry included
% Dynamic condisered
%
% Concentric dual model
% Position control, input 'time-theta, time-r' trajectory
%
% Last advised : 2020/09/03
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% opengl info

%% Draw the continuous animation with given conditions 
clear variables; clc; close all;
timer_total = tic;

trajectory_mode = 2;  
% 1:constant omega, constant dr = 0, wheel mode 
% 2:constant omega, constant dr = 0.045, legged mode 
% 3:assigned trajectory, CPG trajectory, Trot
% 4:assigned trajectory, CPG trajectory, Walk


radius = 0.11;  % leg length (m)
% delta_r_initial = 0.045;  % delta leg length (m) [0 , 0.045]

leg_mass = 5 ; % define the mass of the structure (kg)
% leg_inertia = 0.02211; % define the inertia of the structure (kg*m^2) predict by solidworks
% wheel:0.1118(kg*m^2); leg:0.02211(kg*m^2)
% motor inertia is small enough to be neglected

mu_s = 1.0; % define the equivalent static friction constant between the wheel and the ground 
mu_k = 0.9; % define the equivalent dynamic friction constant

mass_force = [0 -(leg_mass*9.8)];
%% Settings 
enable.video = 1;  % switch to 1 to enable video recording

enable.xls_record = 0;   % switch to 1 to write the data to the excel file
enable.time_elapsed_print = 1;  % switch to 1 to show the time elapsed of each iteration

enable.plot_procedure = 0; % switch 1 to plot all the procedure
    enable.plot_quiver = 1;  % switch to 1 to show the force quiver including mass and reaction force from the ground
    enable.v_a = 1;
enable.plot_required_torque = 0; % switch 1 to show the required_torque at final plot    

enable.analysis_text = 1;  % switch 1 to show the analysis result in the last frame
enable.save_final_plot = 0; % switch 1 to save the final plot

visualization.force = 0.003; % set the quiver factor for the force vector 
visualization.movement = 25; % set the quiver factor for the movement vector 

% Window settings
x_range = [-0.5, 2.5]; % range of the window [-0.5, 4]
y_range = [-0.2, 0.6];  % [-0.2, 1.0]

window_size = [100 100 1200 500];  % [100 100 1000 500]
title_fontsize = 12;
label_fontsize = 12;
text_fontsize = 12;
legend_fontsize = 12;
outputsize = [9, 3.5];    %[3.5 1.5]; %inches

text_pos.landscape = [x_range(1) + 0.05 , y_range(2) - 0.05];
text_pos.slipping = [x_range(1) + 0.05 , y_range(2) - 0.15];
text_pos.v = [x_range(1) + 0.2 , y_range(1) + 0.12];
text_pos.a = [x_range(1) + 0.2 , y_range(1) + 0.06];
%% Inital values 
% 
hip_joint_initial = [0,0.2];  % initail position of the hip joint
% hip_joint_initial = [-0.002,0.1169];

% Define forward vel
forward_vel_goal = 0.2; %m/s

% define how much time the leg is going to run (sec)
t_initial = 0;  % (s)
t_end = 5; 
V_initial = [0 0] ; % (m/s)

num_of_iterations = 1001;
% define the resolution of the animation
% More points, higher resolution 
t_array = linspace(t_initial, t_end, num_of_iterations);  % t

theta_initial_assigned_deg = 0; % define the intial posture of the leg (deg)
theta_initial_assigned_rad = theta_initial_assigned_deg /180*pi;

switch trajectory_mode
    case {1,2} % constant omega, constant dr       
        if trajectory_mode == 1  % wheel mode
            delta_r_initial = 0;
            leg_inertia = 0.1118;
            rotating_sum_theta = forward_vel_goal*(t_end-t_initial) / 0.11; 
            input_trajectory_data_filename = ['const w & dr=0, V=',num2str(forward_vel_goal)];
        else  % trajectory_mode == 2, legged mode
            delta_r_initial = 0.045;
            leg_inertia = 0.02211;
            rotating_sum_theta = forward_vel_goal*(t_end-t_initial) / 0.155 * 1.068; % fixing ratio         
            input_trajectory_data_filename = ['const w & dr=0.045, V=',num2str(forward_vel_goal)];
        end
        theta_end = theta_initial_assigned_deg/180*pi + rotating_sum_theta; %(V/r)*t=w*t
        % define the gait table
        theta_array_full_shifted = linspace(theta_initial_assigned_rad, theta_end, num_of_iterations); % constant omega 
        theta_array_dual_full_shifted = theta_array_full_shifted + 0.5 * pi;
        
%         theta_array = rem(theta_array_full, 2*pi); % project to [0,2*pi)
        r_array_shifted = 0 * theta_array_full_shifted + delta_r_initial ;  % constant delta_r
        r_array_dual_shifted = r_array_shifted;
        
        input_xlsx_tab_str = '';
    
    case {3,4}  % input assigned trajectory, CPG trajectory is used here
        
        % Load trajectory data
        input_trajectory_data_filename = 'CPG trajectory';
        if trajectory_mode == 3
            input_xlsx_tab_str = ['Trot, V=', num2str(forward_vel_goal)];
        else  % trajectory_mode == 4
            input_xlsx_tab_str = ['Walk, V=', num2str(forward_vel_goal)];     
        end

        input_trajectory_data = xlsread([input_trajectory_data_filename,'.xlsx'],input_xlsx_tab_str);
        trajectory_t = input_trajectory_data(:,1);
        trajectory_theta = input_trajectory_data(:,2);      
        trajectory_r = input_trajectory_data(:,3);
        
        t_array_rem = rem(t_array, max(trajectory_t));  % max(trajectory_t) is period of the gait
        t_array_floor = floor(t_array/ max(trajectory_t));  % period number
        
        % shift theta to the origin to reduce omega spike 
        trajectory_theta_trimed = trajectory_theta -(trajectory_theta(1) - (trajectory_theta(2) - trajectory_theta(1)));

        Fn_traj_theta = @(t) interp1(trajectory_t, (trajectory_theta_trimed)/180*pi, t,'linear','extrap');
        theta_array = Fn_traj_theta(t_array_rem);
        

        theta_array_full = max(theta_array)*t_array_floor + theta_array;
        
        theta_array_shifted_ind = find(theta_array_full >= theta_initial_assigned_rad,1,'first');
        theta_array_full_shifted = circshift(theta_array_full, -(theta_array_shifted_ind-1));
        theta_array_full_shifted(end-theta_array_shifted_ind+2:end) = ...
            theta_array_full_shifted(end-theta_array_shifted_ind+2:end) + theta_array_full(end);  
        

        % define the dual leg phase shifting
        dual_shift_t_ind = find(t_array <= max(trajectory_t)/4, 1, 'last'); % 0.25 period
        
        theta_array_dual_full_shifted = circshift(theta_array_full_shifted, -dual_shift_t_ind);
        theta_array_dual_full_shifted(end-dual_shift_t_ind+1 : end) = ...
            theta_array_dual_full_shifted(end-dual_shift_t_ind+1 : end) + theta_array_full_shifted(end) - theta_array_full_shifted(1);
        
%         Fn_traj_r = @(t) interp1(trajectory_t, trajectory_r, t,'linear','extrap');
%         r_array = Fn_traj_r(t_array_rem);
%         r_array_shifted = circshift(r_array, -(theta_array_shifted_ind-1));
        
        % define the relation of theta and r: r(theta) 
        Fn_r_of_th = @(theta) interp1(trajectory_theta*pi/180, trajectory_r, theta,'linear','extrap');
        r_array_shifted = Fn_r_of_th(rem(theta_array_full_shifted,2*pi));
        
        r_array_dual_shifted = Fn_r_of_th(rem(theta_array_dual_full_shifted,2*pi)); 
        
        leg_inertia = 0.02211;
end

theta_initial = theta_array_full_shifted(1) ;
theta_dual_initial = theta_array_dual_full_shifted(1);
theta_end = theta_array_full_shifted(end);

delta_r_initial = r_array_shifted(1);
delta_r_dual_initial = r_array_dual_shifted(1);

t_increment = (t_end - t_initial)/ (num_of_iterations - 1);

% dr_array = [0,diff(r_array)/t_increment];
omega_array = diff(theta_array_full_shifted)/t_increment;
omega_array = [omega_array(1),omega_array]; % set initial omega value


alpha_array = [0,diff(omega_array)/t_increment]; 

%% Define landscape 

x_partition_diff = 0.001; % define the resolution of the gound
x_partition = x_range(1):x_partition_diff:x_range(2);  % x_partition

landscape_function_index = 3;  

switch(landscape_function_index)
    case 1   % Rough terrain       
%         landscape_function = @(x) 0.09*sin(10*x) + x*0.1 ;
        landscape_function = @(x) 0.2*sin(0.4 *2*pi *x) +  0;
        landscape_str = 'rough';
    case 2   % Flat terrain
        landscape_function = @(x) 0 * x   ;
        landscape_str = 'flat';
    case 3   % Stairs
        level_height = 0.1;
        landscape_partition = craete_stair_landscape(x_partition, 4, level_height) ;   % 10
        % (x_partition, stair_level, level_height)
        landscape_str = 'stairs';
    case 4   % parabolic
        landscape_function = @(x) 0.9 * (x + 0.1).^2  ;  
        landscape_str = 'parabolic';
end


if landscape_function_index ~= 3
    str_landscape_function = func2str(landscape_function);
    landscape_str_full = [landscape_str,' ',str_landscape_function(5:end)];
    landscape_partition = landscape_function(x_partition);
else
    landscape_str_full = [landscape_str,', L_h = ',num2str(level_height),' (m)'];
    landscape_function = @(x) interp1(x_partition, landscape_partition, x,'linear','extrap');
end
landscape_partition_diff = [diff(landscape_partition),0];
% angle between contact point_tangential and horizontal line
% landscape_partition_phi = atan2(landscape_partition_diff, x_partition_diff);
% landscape_partition_slope = landscape_partition_diff ./ x_partition_diff;

landscape_table = [ x_partition;
                    landscape_partition];

% land_table = [ x_partition;
%                landscape_partition_diff;
%                landscape_partition_slope ];

% clear x_partition landscape_partition landscape_partition_diff;
%% Retrive landscape freq
% landscape_fourier_fit = fit(x_partition',landscape_partition','fourier2');
% FFT_freq_sample = 20; % Hz % Sampling frequency                           
% FFT_L = 1500;             % Length of signal
% FFT_t = (0:FFT_L-1)*(1/FFT_freq_sample);        % Time vector
% frequecy_response_array = find_dominate_freq(landscape_function(FFT_t)', FFT_freq_sample);

%% Video settings
if enable.video == 1
    enable.plot_procedure = 1;
    enable.plot_quiver = 1;
    enable.plot_required_torque = 1;
    % set the playing speed of the video
    video_play_frame_rate = 1;
    
    video_filename = ['Dual'...
                      ', T=',num2str(t_end ),'(s)'...
                      ', Theta=',num2str(theta_initial*180/pi),'~',num2str(theta_end*180/pi),'(deg)'...
                      ', mu_s=',num2str(mu_s),...
                      ', mu_k=',num2str(mu_k),...
                      ', ',landscape_str,...
                      ', ',input_trajectory_data_filename,...
                      ', ',input_xlsx_tab_str,...
                      ', rate=',num2str(video_play_frame_rate),...
                      '.avi'];
    writerObj = VideoWriter(video_filename);
    writerObj.FrameRate = 1 / t_increment * video_play_frame_rate ;  % set playing frame rate
    open(writerObj);   
end

%% Plot the landscape and the leg with initial value
if enable.plot_procedure == 1
%     enable.plot_quiver = 1;
    enable.plot_required_torque = 1;
    figure(1)
    set(gcf,'name','Leg rotaion simulation','Position', window_size);
else
    enable.plot_quiver = 0;
%     enable.plot_required_torque = 0;
end
% First trial
% To get the leg_contour for the further contacting calculation
hip_joint = hip_joint_initial;
V_next = V_initial;
leg_contour = def_dual_leg_contour(hip_joint, theta_initial, theta_dual_initial, delta_r_initial, delta_r_dual_initial);
plot_legend = plot_landscape_dual_leg(landscape_table,leg_contour);


next_movement_vector = [0 0];

% initialize data_record
data_record = double.empty(19,0);

%% Main loop start

for loop_iteration = 1:num_of_iterations

% loop_iteration = 500;
    timer_loop = tic;
    
    if enable.plot_procedure == 1 && enable.plot_required_torque == 1
        subplot(5,1,1:4);
    end
    
    t = t_array(loop_iteration);
    theta = theta_array_full_shifted(loop_iteration);
    theta_dual = theta_array_dual_full_shifted(loop_iteration);
    
    omega = omega_array(loop_iteration);
    delta_r = r_array_shifted(loop_iteration);
    delta_r_dual = r_array_dual_shifted(loop_iteration);
    
    V_now = V_next;
    
    movement_vector = next_movement_vector;
    
    
    % apply the movement
    hip_joint = hip_joint + movement_vector; 
    
    % Return the leg_contour
    leg_contour = def_dual_leg_contour(hip_joint, theta, theta_dual, delta_r, delta_r_dual);
    
    %% Check overlap and update the hip joint and contact point
    % Geometric constrian check and fix
    
    % ===== Find contact point and the revice vector =====
    contact_point = find_contact_point_dual_leg(leg_contour , landscape_table , radius);
    
    if ~isempty(contact_point.point_1.point)
        
        contact_point_1 = contact_point.point_1.point;
        % tangent of normal force point
        land_diff = interp1(x_partition, landscape_partition_diff, contact_point.point_1.point(1));  
                 
        land_tangent_direction = [x_partition_diff , land_diff]; % tangent dir at contact point
        land_tangent_direction = land_tangent_direction / norm(land_tangent_direction);

        revise_direction = contact_point.point_1.revise;
        revise_direction = revise_direction / norm(revise_direction);
        
        contact_point.point_1.land_tangent_direction = land_tangent_direction;
        contact_point.point_1.revise_direction = revise_direction;
        
%         revise_vector_1 = revise_distance * revise_direction;
        revise_vector_array(1,:) = contact_point.point_1.revise;
        
        
        % visualize the position shifting  by using arrow
        % according to the overlap
%         force_mag = -100 * contact_point.point_1(3);  % scaled parameter for visualization
%         quiver(contact_point.point_1(1),contact_point.point_1(2),...
%                -force_mag * land_diff , force_mag * x_partition_diff,... (-y,x)
%                 'MaxHeadSize',0.5,'color','b');
        
        % plot contacting point
        if enable.plot_procedure == 1
            plot_legend.contact_point_1 = ...
                plot(contact_point.point_1.point(1),contact_point.point_1.point(2),'marker','*','MarkerSize',10,'color','b');
            hold on;
        end
        
        
%         % assume rolling point is contact point 1
%         rolling_point.leg_index = 1;
%         rolling_point.point = contact_point_1;
%         rolling_point.land_tangent_force_dir = land_tangent_direction;
%         rolling_point.centripetal_force_dir = revise_direction;
%         rolling_point.istoe = (contact_point.point_1.istip || contact_point.point_1.istoe);
        

        
    else
        contact_point_1 = [];
        revise_vector_array(1,:) = [0,0];
    end
    % <Note>
    % Direction of revise vector: centripetal 
    % If the contact point is on continuous landscape => centripetal_force_dir = land_tangent_direction

    
    if ~isempty(contact_point.point_2.point)
        
        contact_point_2 = contact_point.point_2.point;
        
        land_diff = interp1(x_partition, landscape_partition_diff, contact_point.point_2.point(1));       
        
        land_tangent_direction = [x_partition_diff , land_diff];
        land_tangent_direction = land_tangent_direction / norm(land_tangent_direction);
%         revise_direction = [-land_diff , x_partition_diff] ;
        revise_direction = contact_point.point_2.revise;
        revise_direction = revise_direction / norm(revise_direction);

        revise_vector_array(2,:) = contact_point.point_2.revise;
        
        contact_point.point_2.land_tangent_direction = land_tangent_direction;
        contact_point.point_2.revise_direction = revise_direction;
        
        % Visualize the position shifting by using arrow
        % according to the overlap        
%         force_mag = -100 * contact_point.point_2(3);  % scaled parameter
%         quiver(contact_point.point_2(1),contact_point.point_2(2),...
%                -force_mag * land_diff, force_mag*x_partition_diff,... (-y,x)
%                 'MaxHeadSize',0.5,'color','r');
        % plot contacting point
        if enable.plot_procedure == 1
            plot_legend.contact_point_2 = ...
                plot(contact_point.point_2.point(1),contact_point.point_2.point(2),'marker','*','MarkerSize',10,'color','r');
            hold on;
        end
      
        
%         % redecide rolling point w.r.t contact point_2 
%         if isempty(contact_point_1)
%             rolling_point.leg_index = 2;
%             rolling_point.point  = contact_point_2;
%             rolling_point.land_tangent_force_dir = land_tangent_direction;
%             rolling_point.centripetal_force_dir = revise_direction;
%             rolling_point.istoe = (contact_point.point_2.istip || contact_point.point_2.istoe);
%             
%         elseif contact_point_2(1) > contact_point_1(1)  % Two contact point, the rolling center is the one on the right side
%             rolling_point.leg_index = 2;
%             rolling_point.point  = contact_point_2;
%             rolling_point.land_tangent_force_dir = land_tangent_direction;
%             rolling_point.centripetal_force_dir = revise_direction;
%             rolling_point.istoe = (contact_point.point_2.istip || contact_point.point_2.istoe);
%             
%         end
        
    else
        contact_point_2 = [];
        revise_vector_array(2,:) = [0,0];
    end
    
    
    if ~isempty(contact_point.point_3.point)
        
        contact_point_3 = contact_point.point_3.point;
        
        land_diff = interp1(x_partition, landscape_partition_diff, contact_point.point_3.point(1));
        land_tangent_direction = [x_partition_diff , land_diff];
        land_tangent_direction = land_tangent_direction / norm(land_tangent_direction);
%         revise_direction = [-land_diff , x_partition_diff] ;
        revise_direction = contact_point.point_3.revise;
        revise_direction = revise_direction / norm(revise_direction);

        revise_vector_array(3,:) = contact_point.point_3.revise;
        
        contact_point.point_3.land_tangent_direction = land_tangent_direction;
        contact_point.point_3.revise_direction = revise_direction;
        
        % Visualize the position shifting by using arrow
        % according to the overlap        
%         force_mag = -100 * contact_point.point_2(3);  % scaled parameter
%         quiver(contact_point.point_2(1),contact_point.point_2(2),...
%                -force_mag * land_diff, force_mag*x_partition_diff,... (-y,x)
%                 'MaxHeadSize',0.5,'color','r');
        % plot contacting point
        if enable.plot_procedure == 1
            plot_legend.contact_point_3 = ...
                plot(contact_point.point_3.point(1),contact_point.point_3.point(2),'marker','*','MarkerSize',10,'color','r');
            hold on;
        end
        
    else
        contact_point_3 = [];
        revise_vector_array(3,:) = [0,0];
    end
    
    if ~isempty(contact_point.point_4.point)
        
        contact_point_4 = contact_point.point_4.point;
        land_diff = interp1(x_partition, landscape_partition_diff, contact_point.point_4.point(1));       
        
        land_tangent_direction = [x_partition_diff , land_diff];
        land_tangent_direction = land_tangent_direction / norm(land_tangent_direction);
%         revise_direction = [-land_diff , x_partition_diff] ;
        revise_direction = contact_point.point_4.revise;
        revise_direction = revise_direction / norm(revise_direction);

        revise_vector_array(4,:) = contact_point.point_4.revise;
        
        contact_point.point_4.land_tangent_direction = land_tangent_direction;
        contact_point.point_4.revise_direction = revise_direction;
        
        % Visualize the position shifting by using arrow
        % according to the overlap        
%         force_mag = -100 * contact_point.point_2(3);  % scaled parameter
%         quiver(contact_point.point_2(1),contact_point.point_2(2),...
%                -force_mag * land_diff, force_mag*x_partition_diff,... (-y,x)
%                 'MaxHeadSize',0.5,'color','r');
        % plot contacting point
        if enable.plot_procedure == 1
            plot_legend.contact_point_4 = ...
                plot(contact_point.point_4.point(1),contact_point.point_4.point(2),'marker','*','MarkerSize',10,'color','r');
            hold on;
        end
        
    else
        contact_point_4 = [];
        revise_vector_array(4,:) = [0,0];
    end
    

       
    %======= Determine the contact point ========
    contact_point_array = [contact_point_1; contact_point_2; contact_point_3; contact_point_4];
    if( isempty(contact_point_array))
        % no contact, should fall
%         rolling_point.leg_index = [];
        rolling_point.point = [];
        rolling_point.land_tangent_force_dir = [];
        rolling_point.centripetal_force_dir = [];
        isContact = false;
        rolling_point.istoe = false;
    else
        % contact to ground, find rolling point
        isContact = true;
        contact_point_array = sortrows(contact_point_array,2,'descend');
        contact_point_array = sortrows(contact_point_array,1,'descend'); 
        % sort wrt x index; find the right-upper one
        % srotrow preserve the original order
        
        rolling_point.point = contact_point_array(1,:);
        
        contact_point_cell = {contact_point_1; contact_point_2; contact_point_3; contact_point_4};
        for dummy_ind = 1:4
            if ~isempty(contact_point_cell{dummy_ind})  % contact point exists
                if isequal(contact_point_cell{dummy_ind}, rolling_point.point)
                    
                    rolling_point.land_tangent_force_dir = eval(['contact_point.point_' num2str(dummy_ind) '.land_tangent_direction']);
                    rolling_point.centripetal_force_dir = eval(['contact_point.point_' num2str(dummy_ind) '.revise_direction']);
                    rolling_point.istoe = (...
                    eval(['contact_point.point_' num2str(dummy_ind) '.istip']) || ...
                    eval(['contact_point.point_' num2str(dummy_ind) '.istoe'])  );
                end
            end
        end
        
        
        if enable.plot_procedure == 1
            rolling_point_txt = ['Rolling point = (',num2str(rolling_point.point (1),'%.3f'),', ',num2str(rolling_point.point (2),'%.3f'),' )'];
            text(rolling_point.point (1) , rolling_point.point (2) - 0.1, rolling_point_txt,'color', 'k', 'fontsize', text_fontsize);

            plot_legend.rolling_point = plot (rolling_point.point (1), rolling_point.point (2),'marker','.','MarkerSize',20,'color','g');
        end
    end
    
    
    % ======= Adjust the hip joint position ===========
    
    % choose the larger value along the +x and -x direction
    if ~isempty(revise_vector_array(revise_vector_array(:,1)>0)) % exists positive revision
        revision_x_pos = max( revise_vector_array(revise_vector_array(:,1)>0, 1) ); % find the lagest
    else
        revision_x_pos = 0;
    end
    if ~isempty(revise_vector_array(revise_vector_array(:,1)<0)) % exists negative revision
        revision_x_neg = min( revise_vector_array(revise_vector_array(:,1)<0, 1) ); % find the smallest
    else
        revision_x_neg = 0;
    end
    % union of the value of both dircetions
    revise_vector(1) = revision_x_pos + revision_x_neg;
    
    
    % choose the larger value along the +y and -y direction
    if ~isempty(revise_vector_array(revise_vector_array(:,2)>0)) % exists positive revision
        revision_y_pos = max( revise_vector_array(revise_vector_array(:,2)>0, 2) ); % find the lagest
    else
        revision_y_pos = 0;
    end
    if ~isempty(revise_vector_array(revise_vector_array(:,2)<0)) % exists negative revision
        revision_y_neg = min( revise_vector_array(revise_vector_array(:,2)<0, 2) ); % find the smallest
    else
        revision_y_neg = 0;
    end
    % union of the value of both dircetions
    revise_vector(2) = revision_y_pos + revision_y_neg;

    hip_joint = hip_joint + revise_vector;
    leg_contour = def_dual_leg_contour(hip_joint, theta, theta_dual, delta_r, delta_r_dual);
    
    %******** check after revise *************
%     check_contact_point = find_contact_point(leg_contour , landscape_table , radius);
%     if(isempty(check_contact_point.point_1) && isempty(check_contact_point.point_2) && isContact)
% %         disp('contact point error');
%         isContact = false;
%     end

    if(rolling_point.istoe)
        text( x_range(1) + 0.05 , y_range(2) - 0.25, 'Is Toe !','color', 'b','fontsize', text_fontsize);
    end
    
     
    %% Drawings 
    
    if enable.plot_procedure == 1
        % Draw the landscape and the leg
        plot_legend = plot_landscape_dual_leg(landscape_table,leg_contour);

        title_str = [sprintf('T = %.2f',t), ' (s) , ',...
                    '\Delta \theta = ', sprintf('%.2f',theta*180/pi),' \circ , ',...
                    '\Delta r = ', sprintf('%.1f',delta_r*100),' (cm) , '...
                    '\mu_s = ', sprintf('%.1f',mu_s),...
                    ' , \mu_k = ', sprintf('%.1f',mu_k),...
                    ' , ', landscape_str ,...
                    ', ',input_trajectory_data_filename,...
                    ', ',input_xlsx_tab_str ];

        title(title_str, 'fontsize',title_fontsize);
        xlabel('x (m)','FontSize',label_fontsize);
        ylabel('y (m)','FontSize',label_fontsize);
        axis equal;
        axis([x_range y_range]); % acorrding to the given landscape

        V_txt = ['V = (',sprintf('%.2f',V_now(1)),',',...
        sprintf('%.2f',V_now(2)),') , |V| = ',sprintf('%.2f',norm(V_now)),'(m/s)'] ;
        if enable.v_a == 1
            text( text_pos.v(1),text_pos.v(2), V_txt ,'color', 'k', 'fontsize', text_fontsize);
        end
        text( text_pos.landscape(1),text_pos.landscape(2), landscape_str_full,'color', 'k','fontsize', text_fontsize)
    end
   
    %% Determin next step : revolution considering slip effect 
    
    % Kinetics considered
    
    % Calculate reaction force
    if(isContact)   % Contact with ground
        
        % Assume no slip first, Calculating tangential force
        % if tangential force > F_static_friction (mu_s)  =>  Slipping
            % => tangential force = F_dynamic_friction (mu_k)
        % Else => rolling without slipping
           
        
        % ==========Assume no slip first================
        
        % Equivelent R, from contact point to the hip
        rotation_radius_vector = hip_joint - rolling_point.point ; % contact point to the hip
        
        
        new_rotation_radius_vector = ...
        rotation_radius_vector * [cos(-omega*t_increment) sin(-omega*t_increment) 
                                 -sin(-omega*t_increment) cos(-omega*t_increment)] ;
                             
        V_next_assumption = ((rolling_point.point + new_rotation_radius_vector) - hip_joint)/t_increment;
        
        a_next_assumption = (V_next_assumption - V_now)/t_increment;

        % Force equilibrium
%         rolling_point.reaction_force = leg_mass * acc(1:2) - mass_force;  % F + W = ma
        rolling_point.reaction_force = leg_mass * a_next_assumption - mass_force;
   
%         if enable.plot_quiver == 1
% 
%             quiver(hip_joint(1),hip_joint(2),...
%             acc(1)*visualization.force , acc(2)*visualization.force,... 
%             'MaxHeadSize',0.5,'color','r', 'LineStyle', '-'); 
%         
%             quiver(hip_joint(1),hip_joint(2),...
%             vel(1)*visualization.force , vel(2)*visualization.force,... 
%             'MaxHeadSize',0.5,'color','b', 'LineStyle', '-'); % brown
%         end
        if rolling_point.istoe == true
            % ******reaction force is determined by ground**********
            rolling_point.tangent_force_dir = rolling_point.land_tangent_force_dir;                                                                            
            rolling_point.normal_force_dir = rolling_point.land_tangent_force_dir* [0 1 ;
                                                                                   -1 0] ;

            
        else % *****reaction force is determined by centripetal dir*********
            rolling_point.normal_force_dir = rolling_point.centripetal_force_dir;
            rolling_point.tangent_force_dir = rolling_point.normal_force_dir * [0 -1 ;
                                                                                1 0] ;
        end
        
        rolling_point.tangent_force = dot(rolling_point.reaction_force, rolling_point.tangent_force_dir)*rolling_point.tangent_force_dir;
        
        friction_force_sign = sign(dot(rolling_point.reaction_force, rolling_point.tangent_force_dir));
        
       
        % forward: pos value ; backward : neg value
        
        
%         rolling_point.tangent_force_dir = rolling_point.tangent_force / norm(rolling_point.tangent_force);

%         if(rolling_point.normal_force_dir(1) < 0)
%             disp("tangent dir error");
%         end
%         
        

        
        if dot(rolling_point.reaction_force, rolling_point.normal_force_dir) < 0
            rolling_point.normal_force = [0 0];
            rolling_point.reaction_force = rolling_point.tangent_force; % 0
%             disp('no normal force provided!')
        else
            rolling_point.normal_force = dot(rolling_point.reaction_force, rolling_point.normal_force_dir)*rolling_point.normal_force_dir;

        end
        
%         rolling_point.normal_force_dir = rolling_point.normal_force / norm(rolling_point.normal_force);

%         if(rolling_point.normal_force_dir(2) < 0)
%             disp("normal force dir error");
%         end
        % ground can only provide positive normal force


%         rolling_point

        % ==== friction part =====
        % max friction force
        max_static_friction = mu_s * norm(rolling_point.normal_force);
%         max_static_friction_force = max_static_friction * rolling_point.tangent_force_dir ;
        

        if( norm(rolling_point.tangent_force) <= max_static_friction )
            % No-slip condition, rolling with respect to the contact point 
            % calculate the total reaction force provided by ground
            % Rolling
            
            isRolling = true;
            if enable.plot_procedure == 1
                text( text_pos.slipping(1),text_pos.slipping(2), 'No slip','color', 'k', 'fontsize', text_fontsize);
            end
        else
            % Slip condition
            % calculate the total reaction force provided by ground
            dynamic_friction_force = mu_k * norm(rolling_point.normal_force) * rolling_point.tangent_force_dir * friction_force_sign;
            rolling_point.tangent_force = dynamic_friction_force;
            rolling_point.reaction_force = rolling_point.normal_force + rolling_point.tangent_force;
            
            
            % transfer the external force to displacement
            isRolling = false;  % not static, considering kinetics
            if enable.plot_procedure == 1
                
                if max_static_friction == 0
                    text( text_pos.slipping(1),text_pos.slipping(2), 'Falling !','color', 'r','fontsize', text_fontsize);
                else
                    text( text_pos.slipping(1),text_pos.slipping(2), 'Slipping !','color', 'r','fontsize', text_fontsize);
                end
            end 
        end

        

        % visualize the force including mass, reaction normal and reaction tangential
        if enable.plot_quiver == 1
%             plot_legend.mass_force = quiver(hip_joint(1),hip_joint(2),...
%             mass_force(1) * visualization.force , mass_force(2) * visualization.force,... 
%             'MaxHeadSize',0.5,'color','k', 'LineStyle', ':');

            plot_legend.reaction_force = quiver(rolling_point.point(1),rolling_point.point(2),...
            rolling_point.reaction_force(1) * visualization.force , rolling_point.reaction_force(2) * visualization.force,... 
            'MaxHeadSize',0.5,'color','k', 'LineStyle', ':');

%             % normal reaction force
%             plot_legend.reaction_normal_force = quiver(rolling_point.point(1),rolling_point.point(2),...
%             rolling_point.normal_force(1)*visualization.force , rolling_point.normal_force(2)*visualization.force,... 
%             'MaxHeadSize',0.5,'color',[0.6350 0.0780 0.1840], 'LineStyle', ':'); % brown

%             % tangential reaction force
%             plot_legend.reaction_tangent_force = quiver(rolling_point.point(1),rolling_point.point(2),...
%             rolling_point.tangent_force(1)*visualization.force , rolling_point.tangent_force(2)*visualization.force,... 
%             'MaxHeadSize',0.5,'color','r', 'LineStyle', ':'); % brown
        end
    else      
        % Does not contact to ground, fall. Reaction force is 0
        rolling_point.reaction_force = [0,0];
        rotation_radius_vector = [0,0];

        isRolling = false;  % not static, considering kinetics
        if enable.plot_procedure == 1
            text( text_pos.slipping(1),text_pos.slipping(2), 'Falling !','color', 'k', 'fontsize', text_fontsize);
            if enable.plot_quiver == 1
                plot_legend.reaction_force = quiver(0,0, 0,0,... 
                'MaxHeadSize',0.5,'color','k', 'LineStyle', ':');
            end
        end
        
    end
    
    total_force = rolling_point.reaction_force + mass_force;
    if enable.plot_quiver == 1
        % total force
        plot_legend.total_force = quiver(hip_joint(1),hip_joint(2),...
        total_force(1)*visualization.force , total_force(2)*visualization.force,... 
        'MaxHeadSize',0.5,'color',[0.6350 0.0780 0.1840], 'LineStyle', '--'); % brown
    end
    
    
    ture_acceleration = (total_force) / leg_mass;
    
    required_torque = leg_inertia * alpha_array(loop_iteration)...
                    + cross([rolling_point.reaction_force 0],[rotation_radius_vector 0]);
    required_torque = required_torque(3);
    
    
    if enable.plot_procedure == 1 && enable.v_a == 1
        a_txt = ['a = (',sprintf('%.2f',ture_acceleration(1)),',',...
        sprintf('%.2f',ture_acceleration(2)),') , |a| = ',sprintf('%.2f',norm(ture_acceleration)),'(m/s^2)'] ;
        text( text_pos.a(1),text_pos.a(2) , a_txt ,'color', 'k', 'fontsize', text_fontsize);
    end


    % visualize the total force by using arrow
%     if enable.plot_quiver == 1
%         plot_legend.total_force = quiver(hip_joint(1),hip_joint(2),...
%                    visualization.force * rolling_point.reaction_force(1),visualization.force * rolling_point.reaction_force(2),... 
%                     'MaxHeadSize',2,'color','r'); 
%     end

        
    % ============= Determine movement ========================
    
    
%     if isRolling == true  % Rolling
%         % No-slip condition, rolling with respect to the contact point            
%         % rotate clockwise wrt the contact point
%         
%         next_movement_vector = V_next_assumption * t_increment;
% 
%         V_next = V_now + ture_acceleration * t_increment;
% %         movement_vector = position - hip_joint;
%     else  
%         % not static, considering kinetics
%         % additional force convert to acceleration   
%         % including falling and slipping
% 
% %         movement_vector = V_last * t_increment * 0.1 + 0.5 * acceleration * t_increment^2;
%                           
%     end
    
    V_next = V_now + ture_acceleration * t_increment;
    next_movement_vector = V_now * t_increment + 0.5 * ture_acceleration * t_increment^2;


    % visualize the hip joint movement by using arrow
    % now hip joint position
    % scaled parameter
    if enable.plot_quiver == 1
        plot_legend.movement = quiver(hip_joint(1),hip_joint(2),...
                       visualization.movement * next_movement_vector(1),visualization.movement * next_movement_vector(2),... 
                        'MaxHeadSize',0.5,'color','k');
    end
    
    %% Record data, adjust array size with loop
    data_record(1,loop_iteration) = t;
    data_record(2,loop_iteration) = theta;
    data_record(3,loop_iteration) = delta_r;
    data_record(4,loop_iteration) = hip_joint(1);
    data_record(5,loop_iteration) = hip_joint(2);
    data_record(6,loop_iteration) = required_torque;  
    data_record(7,loop_iteration) = omega;
    
    data_record(8,loop_iteration) = V_now(1);
    data_record(9,loop_iteration) = V_now(2);
    
    data_record(10,loop_iteration) = rolling_point.reaction_force(1);
    data_record(11,loop_iteration) = rolling_point.reaction_force(2);
    
    if enable.plot_procedure == 1
        % plot the trajectory of the hip joint
        plot_legend.hip = plot(data_record(4,:),data_record(5,:),...
                'marker','.','MarkerSize',2,'color',[0.4660   0.6740   0.1880]);

        % plot the legend
        if enable.plot_quiver == 1
            legend([plot_legend.hip, plot_legend.movement,...
                    plot_legend.total_force, plot_legend.reaction_force],...
            {'Hip trajectory','Movement','F_{total}','F_{react}'},...
            'FontSize',text_fontsize ,'location','northeast');    
        else
%             legend([plot_legend.landscape plot_legend.hip plot_legend.leg_1 plot_legend.leg_2 plot_legend.movement],...
%             {'Landscape','Hip joint trajectory','Leg_1','Leg_2','Movement vector'},...
%             'FontSize',text_fontsize);
            legend([plot_legend.hip],...
            {'Hip trajectory'},...
            'FontSize',text_fontsize, 'location','northeast');
        end
    end
        
    % write video or refresh drawing
    if enable.video == 1
        videoFrame = getframe(gcf);
        writeVideo(writerObj, videoFrame);
        hold off;
    else
        if enable.plot_procedure == 1
            drawnow;
            hold off;
        end
    end
    
    
    % print the elapsed time
    if enable.time_elapsed_print == 1
        time_str = [sprintf('%.1f',(loop_iteration/num_of_iterations*100)),'%% , ',...
                    sprintf('Elapsed = %.2f(s)', toc(timer_total))...
                    sprintf(', loop = %.2f(s)\n', toc(timer_loop))];
        fprintf(time_str);
    end
    
    if enable.plot_procedure == 1 && enable.plot_required_torque == 1
        subplot(5,1,5);   
        plot(data_record(1,:),data_record(6,:),'color',[ 0    0.4470    0.7410],'linewidth',1.5);
        hold on;
        plot([0 t_end],[0 0],'--','color',[0.01 0.01 0.01]);
        title(['Minimun torque require = ',sprintf('%.2f',required_torque),' (Nm)'],'FontSize',text_fontsize);
        xlabel('time (s)','FontSize',label_fontsize);
        ylabel('Torque (Nm)','FontSize',label_fontsize);
        xlim([t_initial t_end]);
        hold off;

%         subplot(5,1,5);   
%         plot(data_record(1,:),data_record(10,:),'color',[ 0    0.4470    0.7410],'linewidth',1.5);
%         hold on;
%         plot([0 t_end],[0 0],'--','color',[0.01 0.01 0.01]);
%         title(['Reaction force x = ',sprintf('%.2f',required_torque),' [N]']);
%         xlabel('time [s]');
%         ylabel('Reaction force x [N]');
%         xlim([t_initial t_end]);
%         hold off;
    end
    
    
    
end

%% Calculation
% Calculate required work
% Power = torque * w [Nm*rad/s = Watt], Work = Sum(Power*dt) [J]
total_work = trapz(data_record(1,:), data_record(6,:).*data_record(7,:) ); % S(torque,omega)dt
total_work_abs = trapz(data_record(1,:), abs(data_record(6,:)).*abs(data_record(7,:)) );
% considering abs(positive torque & negative torque)

% Calculate the arc length of hip joint trajectory  
% Calculate integrand from x,y derivatives, and integrate to calculate arc length
hip_joint_trajectory_length =  trapz(hypot(   diff( data_record(4,:) ), diff( data_record(5,:) )  ));   

% calculate the variance of hip joint y, represent the height change of CoM 
hip_joint_y_delta_sum = trapz(  abs( diff( data_record(5,:) ) ) );


% Calculate the length of the landscape, where the hip joint has traveled
% hip joint x-part projection
% including abs(positive & negative)
traveled_landscape.points = [data_record(4,:) ; 
                            interp1(x_partition, landscape_table(2,:), data_record(4,:) )];
traveled_landscape.length = trapz(hypot( diff(traveled_landscape.points(1,:)) , diff(traveled_landscape.points(2,:)) ));




hip_joint_vs_landscape_length_ratio = hip_joint_trajectory_length / traveled_landscape.length  % [m/m]
work_per_landscape_length = total_work_abs / traveled_landscape.length  % [J/m]
average_velocity = hip_joint_trajectory_length / (t_end - t_initial);  %[m/s]
average_speed_x = (data_record(4,end)-data_record(4,1)) / (t_end - t_initial) %[m/s]
hip_joint_y_delta = hip_joint_y_delta_sum / traveled_landscape.length; % height variance/x_dis [m/m]

data_record(12,1) = total_work_abs;
data_record(13,1) = hip_joint_trajectory_length;
data_record(14,1) = traveled_landscape.length;
data_record(15,1) = hip_joint_vs_landscape_length_ratio;
data_record(16,1) = work_per_landscape_length;
data_record(17,1) = average_velocity;
data_record(18,1) = average_speed_x;
data_record(19,1) = hip_joint_y_delta;



%%
if enable.video == 1
    close(writerObj);
    fprintf('video finished\n');
end

if enable.xls_record == 1
    xlsx_tab_str = [input_xlsx_tab_str,',',num2str(theta_end*180/pi,'%.1f'),',', landscape_str];
    data_record_trans = data_record'; % switch arrangement from row to column
%     data_col_header = {'T' ,'Theta','Hip joint x','Hip joint y','Min required torque'};

    [xls_status, xls_message] = xlswrite([datestr(date,'yyyy-mm-dd'),'_sim_result','.xlsx'],data_record_trans, xlsx_tab_str);


%     [xls_status, xls_message] = writetable(data_table,'table.xlsx','Sheet', xlsx_tab_str);
    if xls_status == 1
        fprintf('xlsx write sucessful\n');
    else
        fprintf('xlsx write error\n');
    end
end

fprintf('Total time = %f sec\n', toc(timer_total));
%% Roughly estimate the correctness by the final plot

figure(1)
set(gcf,'name','Leg rotaion simulation','Position', window_size);
if enable.plot_required_torque == 1
    subplot(5,1,1:4);
end
% Draw the landscape and the leg
hold off;
plot_legend = plot_landscape_dual_leg(landscape_table,leg_contour);
hold on;
title_str = [sprintf('T = %.2f',t), ' (s) , ',...
            '\mu_s = ', sprintf('%.1f',mu_s),...
            ' , \mu_k = ', sprintf('%.1f',mu_k),...
            ' , ',landscape_str,...
            ' , ',input_trajectory_data_filename,...
            ' ',input_xlsx_tab_str];
%                 '\Delta \theta = ', sprintf('%.2f',theta*180/pi),' \circ , ',...
%                 '\Delta r = ', sprintf('%.1f',delta_r*100),' (cm) , '...

title(title_str, 'fontsize',title_fontsize);
xlabel('x (m)','FontSize',label_fontsize);
ylabel('y (m)','FontSize',label_fontsize);
axis equal;
axis([x_range y_range]); % acorrding to the given landscape

V_txt = ['V = (',sprintf('%.2f',V_now(1)),',',...
sprintf('%.2f',V_now(2)),') , |V| = ',sprintf('%.2f',norm(V_now)),'[m/s]'] ;

a_txt = ['a = (',sprintf('%.2f',ture_acceleration(1)),',',...
sprintf('%.2f',ture_acceleration(2)),') , |a| = ',sprintf('%.2f',norm(ture_acceleration)),'[m/s^2]'] ;

%     if enable.v_a == 1
%         text( text_pos.v(1), text_pos.v(2), V_txt ,'color', 'k', 'fontsize', text_fontsize);
%         text( text_pos.a(1), text_pos.a(2), a_txt ,'color', 'k', 'fontsize', text_fontsize);
%     end

Analysis_1_txt = ['Hip tra/ Landscape length  = ',num2str(hip_joint_vs_landscape_length_ratio,'%.4f'), ' (m/m)'] ;
Analysis_2_txt = ['Vx = ',num2str(average_speed_x,'%.4f'), ' (m/s)'] ;
Analysis_3_txt = ['W = ',num2str(work_per_landscape_length,'%.4f'), ' (J/m)'] ;
Analysis_4_txt = ['\delta = ',num2str(hip_joint_y_delta,'%.4f'), ' (m/m)'] ;
if enable.analysis_text == 1
    text_pos.analysis = [x_range(2) - 1.8 , y_range(1) + 0.24];
%         text( text_pos.analysis(1), text_pos.analysis(2) , Analysis_1_txt ,'color', 'k', 'fontsize', text_fontsize);
    text( text_pos.analysis(1), text_pos.analysis(2) - 0.06 , Analysis_2_txt ,'color', 'k', 'fontsize', text_fontsize);
    text( text_pos.analysis(1), text_pos.analysis(2) - 0.12 , Analysis_3_txt ,'color', 'k', 'fontsize', text_fontsize);
    text( text_pos.analysis(1), text_pos.analysis(2) - 0.18 , Analysis_4_txt ,'color', 'k', 'fontsize', text_fontsize);
end


text( text_pos.landscape(1), text_pos.landscape(2), landscape_str_full,'color', 'k','fontsize', text_fontsize)
% plot the trajectory of the hip joint
plot_legend.hip = plot(data_record(4,:),data_record(5,:),...
        'marker','.','MarkerSize',2,'color',[0.4660   0.6740   0.1880]);

legend([plot_legend.landscape,plot_legend.hip],...
{'Landscape','Hip joint trajectory'},...
'FontSize',legend_fontsize, 'location','southeast');    


%     figure(2)
%     set(gcf,'name','minimun torque require');
if enable.plot_required_torque == 1
    subplot(5,1,5);
    plot(data_record(1,:),data_record(6,:),'linewidth',1.5);
    hold on;
    plot([0 t_end],[0 0],'--','color',[0.01 0.01 0.01]);
    title('Minimun torque require');
%     ylim([-50 50]);
    xlabel('time (s)');
    ylabel('Torque (Nm)');
    hold off;
end

if enable.save_final_plot == 1
%     title('');
%     set(gca,'Xtick',-0.5:0.5:1.5,'Ytick',0:0.2:0.4,'fontsize', label_fontsize)
%     % set(gca,'fontsize',7);
% %     axis normal;
%     % for visualization
%     set(gcf,'Units','centimeter','Position',[2 2 outputsize])%[5 5 2.5 1.8]  'Resize', 'on'
%     fig.PaperPositionMode = 'auto';
%     % for export
%     set(gcf,'PaperUnits','centimeter','PaperPosition',[0 0 outputsize]);%[0 0 2.5 1.9],'PaperSize', [1.7 1.9],

    fig_filename = ['T=',num2str(t_end ),'(s)'...
                  ',Theta=',num2str(theta_initial*180/pi),'~',num2str(theta_end*180/pi),'(deg)'...
                  ' , ',landscape_str,...
                  ', ',input_trajectory_data_filename,...
                  ' ',input_xlsx_tab_str,...
                  '.fig'];     
%                       ',A=',num2str(amp),...
%                       ',F=',num2str(freq),...
%                       ',b=',num2str(bias),...

    currentfolder = pwd;
    fig_path = fullfile(currentfolder, 'Snapshot');
    saveas(gca, fullfile(fig_path,fig_filename));
    fprintf('Figure saved sucessful\n');
end

%% torque analysis
% figure
% subplot(3,1,1);
% plot(t_array,alpha_array*leg_inertia,'linewidth',1.5)
% title('I*\alpha');
% xlabel('t [s]');
% ylabel('torque [Nm]');
% 
% subplot(3,1,2);
% plot(t_array,data_record(10,:),'linewidth',1.5);
% hold on;
% plot(t_array,data_record(11,:),'linewidth',1.5);
% title('Reaction force','fontsize',12);
% xlabel('t [s]');
% ylabel('force [N]');
% legend('F_f','F_N');
% 
% subplot(3,1,3);
% plot(data_record(1,:),data_record(6,:),'color',[ 0    0.4470    0.7410],'linewidth',1.5);
% title('Minimun torque','fontsize',12);
% xlabel('time [s]','fontsize',12);
% ylabel('torque [Nm]','fontsize',12);



