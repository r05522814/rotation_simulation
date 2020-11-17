%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is used for observing the difference between leg and wheel
% Especially for the different characteristics on different terrains
% For exploring data points
%
% Geometry included
% Dynamic condisered
%
% Last advised : 2020/09/03
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% opengl info


%% Draw the continuous animation with given conditions 
clear variables; clc;
timer_total = tic;

mode_array = 1:3;
% trajectory_mode = 3;  
% 1:constant omega, constant dr = 0, wheel mode 
% 2:constant omega, constant dr = 0.045, legged mode 
% 3:assigned trajectory, CPG trajectory is used here, Trot
% 4:assigned trajectory, CPG trajectory is used here, Walk

leg_mass = 5 ; % define the mass of the structure (kg)
% define the inertia of the structure (kg*m^2) predict by solidworks
% wheel:0.1118(kg*m^2)
% leg:0.02211(kg*m^2)
% motor inertia is small enough to be neglected

mu_s = 0.6; % define the equivalent static friction constant between the wheel and the ground 
mu_k = 0.5; % define the equivalent dynamic friction constant

record_data_row_index = 1;
analysis_data_row_index = 1; % index for recording one point, with varying initial theta

%% Save data
enable.savedata = 1; 
enable.savefig = 1;
%% define how much time the leg is going to run (sec)
t_initial = 0;  % (s)
t_end = 5; 
% define the resolution of the animation
% More points, higher resolution 
num_of_iterations = 1001;
t_array = linspace(t_initial, t_end, num_of_iterations);  % t

%% Inital values 

hip_joint_initial = [0,0.2];  % initail position of the hip joint 
theta_initial_assigned_deg_array = 0:10:179;  % 18 points
% theta_initial_assigned_deg_array = 0;

size_theta_initial_array = size(theta_initial_assigned_deg_array, 2);

forward_vel_goal = 0.4; % define forward velocity

% initialize data_record
record_data = double.empty(0,14);

%% import xlsx data

input_trajectory_data_filename = 'CPG trajectory';
trot_xlsx_tab_str = ['Trot, V=', num2str(forward_vel_goal)];
trot_trajectory_data = xlsread([input_trajectory_data_filename,'.xlsx'],trot_xlsx_tab_str);
walk_xlsx_tab_str = ['Walk, V=', num2str(forward_vel_goal)];
walk_trajectory_data = xlsread([input_trajectory_data_filename,'.xlsx'],walk_xlsx_tab_str);

%% Define landscape 

landscpae_var.x_range = [-0.5, 4.5]; % range of the window
landscpae_var.y_range = [-0.25, 1.0];
landscpae_var.x_partition_diff = 0.001; % define the resolution of the gound

landscpae_var.level_num = 8;

level_height_array = 0.05:0.005:0.15;
% level_height_array = 0.1:0.1;
size_size_level_height_array = size(level_height_array,2);

total_loop_iteration = size_size_level_height_array * size_theta_initial_array * size(mode_array,2);

landscpae_var.mu_s = mu_s;
landscpae_var.mu_k = mu_k;
fprintf('(Fs, Fk) = (%.1f, %.1f)\n',mu_s, mu_k);

for trajectory_mode = mode_array  
    % 1:constant omega, constant dr = 0, wheel mode 
    % 2:constant omega, constant dr = 0.045, legged mode 
    % 3:assigned trajectory, CPG trajectory Trot
    % 4:assigned trajectory, CPG trajectory Walk

    for level_height = level_height_array(1:end)  
        landscpae_var.level_height = level_height;

        for theta_initial_assigned_deg = theta_initial_assigned_deg_array(1:end)

            theta_initial_assigned_rad = theta_initial_assigned_deg/180*pi;
            timer_loop = tic;
            
            % define the gait table                    
            switch trajectory_mode
                
                case {1,2} % constant omega, constant dr  
                    if trajectory_mode == 1 % wheel mode
    %                   hip_joint_initial = [0,0.1];  % bug fixing for wheel critical condition
                        delta_r_initial = 0;
                        rotating_sum_theta = forward_vel_goal *(t_end-t_initial) / 0.11;
                        theta_end = theta_initial_assigned_rad + rotating_sum_theta; %(V/r)*t=w*t
                        trajectory.leg_inertia = 0.1118; % wheel
                        input_trajectory_data_filename = ['const w & dr=0, V=',num2str(forward_vel_goal)];
                    else  % trajectory_mode == 2  % legged mode
%                         hip_joint_initial = [0,0.2];  % bug fixing for wheel critical condition
                        delta_r_initial = 0.045;
                        rotating_sum_theta = forward_vel_goal *(t_end-t_initial) / 0.155 * 1.068; % fixing constant
                        theta_end = theta_initial_assigned_rad + rotating_sum_theta; %(V/r)*t=w*t
                        trajectory.leg_inertia = 0.02211; %leg
                        input_trajectory_data_filename = ['const w & dr=0.045, V=',num2str(forward_vel_goal)];
                    end
                    % define the gait table
                    theta_array_full_shifted = linspace(theta_initial_assigned_rad, theta_end, num_of_iterations); % constant omega 
                    theta_array_dual_full_shifted = theta_array_full_shifted + 0.5 * pi;
                    
                    r_array_shifted = 0 * theta_array_full_shifted + delta_r_initial ;  % constant delta_r
                    r_array_dual_shifted = r_array_shifted;
                    trajectory.name = input_trajectory_data_filename;

                    
                case {3,4}  % input assigned trajectory, CPG trajectory is used here
    %                         hip_joint_initial = [0,0.2];  % bug fixing for wheel critical condition
                    % Load trajectory data                    
                    input_trajectory_data_filename = 'CPG trajectory';
                    if trajectory_mode == 3
                        input_xlsx_tab_str = trot_xlsx_tab_str;
                        input_trajectory_data = trot_trajectory_data;
                    else  % trajectory_mode == 4
                        input_xlsx_tab_str = walk_xlsx_tab_str;
                        input_trajectory_data = walk_trajectory_data;
                    end
                    trajectory.name = [input_trajectory_data_filename,', ',input_xlsx_tab_str];
%                     input_trajectory_data = xlsread([input_trajectory_data_filename,'.xlsx'],input_xlsx_tab_str);

                    % input_trajectory_data : [t,theta,r]
                    trajectory_t = input_trajectory_data(:,1);
                    trajectory_theta = input_trajectory_data(:,2);
                    trajectory_r = input_trajectory_data(:,3);

                    t_array_rem = rem(t_array, max(trajectory_t));  % max(trajectory_t) is period of the gait
                    t_array_floor = floor(t_array/ max(trajectory_t)); % period number

                    Fn_traj_theta = @(t) interp1(trajectory_t, (trajectory_theta)/180*pi, t,'linear','extrap');
                    theta_array = Fn_traj_theta(t_array_rem);

                    % shift theta to the origin to reduce omega spike 
                    theta_array_trimed = theta_array -(theta_array(1) - (theta_array(2) - theta_array(1)));
                    theta_array_full = max(theta_array_trimed)*t_array_floor + theta_array_trimed;

                    theta_array_shifted_ind = find(theta_array_full >= theta_initial_assigned_rad,1,'first');
                    theta_array_full_shifted = circshift(theta_array_full, -(theta_array_shifted_ind-1));
                    theta_array_full_shifted(end-theta_array_shifted_ind+2:end) = ...
                                theta_array_full_shifted(end-theta_array_shifted_ind+2:end) + theta_array_full(end); 

                    % define the dual leg phase shifting
                    dual_shift_t_ind = find(t_array <= max(trajectory_t)/4, 1, 'last'); % 0.25 period

                    theta_array_dual_full_shifted = circshift(theta_array_full_shifted, -dual_shift_t_ind);
                    theta_array_dual_full_shifted(end-dual_shift_t_ind+1 : end) = ...
                        theta_array_dual_full_shifted(end-dual_shift_t_ind+1 : end) + theta_array_full_shifted(end) - theta_array_full_shifted(1);        
                            
                    % define the relation of theta and r: r(theta) 
                    Fn_r_of_th = @(theta) interp1(trajectory_theta*pi/180, trajectory_r, theta,'linear','extrap');
                    r_array_shifted = Fn_r_of_th(rem(theta_array_full_shifted,2*pi));

                    r_array_dual_shifted = Fn_r_of_th(rem(theta_array_dual_full_shifted,2*pi)); 
                    
                    trajectory.leg_inertia = 0.02211; %leg
                    
            end

            trajectory.table = [ t_array;
                                theta_array_full_shifted;
                                theta_array_dual_full_shifted;
                                r_array_shifted;
                                r_array_dual_shifted];
            trajectory.hip_ini = hip_joint_initial;
            

            data = Fn_rolling_simulation_dualModel_stairs(landscpae_var , trajectory);

            record_data(record_data_row_index, :) ...
                             = [landscpae_var.level_height, ...
                                landscpae_var.level_num, ...
                                mu_s,mu_k,...
                                data.landscape_analysis,...  % [mean, std, base_freq, peak2peak]   % standard deviation is the square root of variance
                                trajectory_mode,...
                                theta_initial_assigned_deg,...
                                data.hip_joint_vs_landscape_length_ratio,...
                                data.work_per_landscape_length,...
                                data.average_speed_x,...
                                data.hip_joint_y_delta];

            
            
            time_str = [sprintf('%.1f',(record_data_row_index/total_loop_iteration*100)),'%%, ',...
            sprintf('loop = %.2f(s)', toc(timer_loop)),', ',...
            sprintf('Elapsed = %.2f(s)', toc(timer_total)),', ',...
            sprintf('%d, %.2f(m), %d(deg)\n', trajectory_mode, level_height, theta_initial_assigned_deg)];
            fprintf(time_str);   
            
            record_data_row_index = record_data_row_index + 1;

        end  % end of varing initial theta

        %% one point data analysis, data of different initial value

        record_data_row_range = ... % different initial theta points are combined as a set
            (analysis_data_row_index-1) * size_theta_initial_array + 1: analysis_data_row_index * size_theta_initial_array;

        analysis_data(analysis_data_row_index,:) = ...
                       [record_data(record_data_row_range(1),1:4),record_data(record_data_row_range(1),9),... % [amp, freq, mu_s, mu_k, mode]
                        mean(record_data(record_data_row_range,11)),std(record_data(record_data_row_range,11)),...  % hip_joint_vs_landscape_length_ratio
                        mean(record_data(record_data_row_range,12)),std(record_data(record_data_row_range,12)),...  % work_per_landscape_length
                        mean(record_data(record_data_row_range,13)),std(record_data(record_data_row_range,13)),...  % average_speed_x
                        mean(record_data(record_data_row_range,14)),std(record_data(record_data_row_range,14))];  % hip_joint_y_delta_sum

        analysis_data_row_index = analysis_data_row_index + 1;

    end % end of varying level height
    
end % end of varying trajectory mode


%% Save analysis data

if enable.savedata == 1
    data_file_name = ['Fs=',num2str(mu_s),',Fk=',num2str(mu_k),...
        ',level height[',num2str(level_height_array(1)),'~',num2str(level_height_array(end)),'].mat'];
    save_file_path = fullfile(pwd,['Sim result_stairs_V=',num2str(forward_vel_goal)],data_file_name);

    save(save_file_path,'analysis_data');
    fprintf('Analysis data saved sucessful\n');
end

%% Plot together

set(gcf,'name','Plot sim result','Position', [100 100 1500 800]);
subplot(2,2,1);
hold on;
for mode = 1:2  
    selected_data_row_ind = find(analysis_data(:,5) == mode);
    % close all;
    errorbar(analysis_data(selected_data_row_ind,1),analysis_data(selected_data_row_ind,6),analysis_data(selected_data_row_ind,7));  % crossing ratio
end
hold off;

title('L_h vs Corssing ratio','fontsize', 12);
xlabel('L_h (m)');
ylabel('CR (m/m)');

xl = xlim;
yl = ylim;

% legend('Fixed dr = 0 [m]','Fixed dr = 0.045 [m]','Trot, V=400 [m/s]','Walk, V=400 [m/s]');

% freq_txt = ['Freq = ',num2str(analysis_data(1,2),'%.2f'),' [Hz]'] ;
% mu_s_txt = ['\mu_s = ',num2str(analysis_data(1,3),'%.1f')] ;
% mu_k_txt = ['\mu_k = ',num2str(analysis_data(1,4),'%.1f')] ;
def_txt = 'CR = traj hip / traj landscape';


% text( (xl(2)-xl(1))*0.02 , yl(2)-(yl(2) - yl(1))*0.08 , freq_txt ,'color', 'k', 'fontsize', 10);
% text( (xl(2)-xl(1))*0.02 , yl(2)-(yl(2) - yl(1))*0.16 , mu_s_txt ,'color', 'k', 'fontsize', 10);
% text( (xl(2)-xl(1))*0.02 , yl(2)-(yl(2) - yl(1))*0.24 , mu_k_txt ,'color', 'k', 'fontsize', 10);
text( xl(1)+(xl(2)-xl(1))*0.01 , yl(2)-(yl(2) - yl(1))*0.05 , def_txt ,'color', 'k', 'fontsize', 10); 

subplot(2,2,2);
hold on;
for mode = mode_array  
    selected_data_row_ind = find(analysis_data(:,5) == mode);
    % close all;
    errorbar(analysis_data(selected_data_row_ind,1),analysis_data(selected_data_row_ind,8),analysis_data(selected_data_row_ind,9));  % work
end
hold off;

title('L_h vs W_{avg}','fontsize', 12);
xlabel('L_h (m)');
ylabel('W_{avg} [J/m]');

xl = xlim;
yl = ylim;

% legend('Fixed dr = 0 [m]','Fixed dr = 0.045 [m]','Trot, V=400 [m/s]','Walk, V=400 [m/s]');
% 
% freq_txt = ['Freq = ',num2str(analysis_data(1,2),'%.2f'),' [Hz]'] ;
% mu_s_txt = ['\mu_s = ',num2str(analysis_data(1,3),'%.1f')] ;
% mu_k_txt = ['\mu_k = ',num2str(analysis_data(1,4),'%.1f')] ;
def_txt = 'W_{avg} = abs work / traveled landscape x';
% 
% text( (xl(2)-xl(1))*0.02 , yl(2)-(yl(2) - yl(1))*0.08 , freq_txt ,'color', 'k', 'fontsize', 10);
% text( (xl(2)-xl(1))*0.02 , yl(2)-(yl(2) - yl(1))*0.16 , mu_s_txt ,'color', 'k', 'fontsize', 10);
% text( (xl(2)-xl(1))*0.02 , yl(2)-(yl(2) - yl(1))*0.24 , mu_k_txt ,'color', 'k', 'fontsize', 10);
text( xl(1)+(xl(2)-xl(1))*0.01 , yl(2)-(yl(2) - yl(1))*0.05 , def_txt ,'color', 'k', 'fontsize', 10); 

subplot(2,2,3);
hold on;
for mode = mode_array  
    selected_data_row_ind = find(analysis_data(:,5) == mode);
    % close all;
    errorbar(analysis_data(selected_data_row_ind,1),analysis_data(selected_data_row_ind,10),analysis_data(selected_data_row_ind,11));  % work
end
hold off;

title('L_h vs Vx','fontsize', 12);
xlabel('L_h (m)');
ylabel('Vx (m/s)');

% xl = xlim;
% yl = ylim;

% legend('Fixed dr = 0 [m]','Fixed dr = 0.045 [m]','Trot, V=400 [m/s]','Walk, V=400 [m/s]');
% 
% freq_txt = ['Freq = ',num2str(analysis_data(1,2),'%.2f'),' [Hz]'] ;
% mu_s_txt = ['\mu_s = ',num2str(analysis_data(1,3),'%.1f')] ;
% mu_k_txt = ['\mu_k = ',num2str(analysis_data(1,4),'%.1f')] ;
% 
% text( (xl(2)-xl(1))*0.02 , (yl(2) - yl(1))*0.24 , freq_txt ,'color', 'k', 'fontsize', 10);
% text( (xl(2)-xl(1))*0.02 , (yl(2) - yl(1))*0.16 , mu_s_txt ,'color', 'k', 'fontsize', 10);
% text( (xl(2)-xl(1))*0.02 , (yl(2) - yl(1))*0.08 , mu_k_txt ,'color', 'k', 'fontsize', 10);

subplot(2,2,4);
hold on;
for mode = mode_array 
    selected_data_row_ind = find(analysis_data(:,5) == mode);
    % close all;
    errorbar(analysis_data(selected_data_row_ind,1),analysis_data(selected_data_row_ind,12),analysis_data(selected_data_row_ind,13));  % work
end
hold off;

title('L_h vs \delta, diff. theta I.C.','fontsize', 12);
xlabel('L_h (m)');
ylabel('\delta (m/m)');

xl = xlim;
yl = ylim;

legend('Fixed dr = 0 (m)','Fixed dr = 0.045 (m)');

mu_s_txt = ['\mu_s = ',num2str(analysis_data(end,3),'%.1f')] ;
mu_k_txt = ['\mu_k = ',num2str(analysis_data(end,4),'%.1f')] ;
def_txt = 'Hip height delta per length = Hip height delta sum / traveled landscape x';

text( xl(2)-(xl(2)-xl(1))*0.2 , (yl(2) - yl(1))*0.24 , mu_s_txt ,'color', 'k', 'fontsize', 10);
text( xl(2)-(xl(2)-xl(1))*0.2 , (yl(2) - yl(1))*0.16 , mu_k_txt ,'color', 'k', 'fontsize', 10);
text( xl(1)+(xl(2)-xl(1))*0.01 , yl(2)-(yl(2) - yl(1))*0.05 , def_txt ,'color', 'k', 'fontsize', 10); 

%% save fig
if enable.savefig == 1

    fig_file_name = ['Fs=',num2str(mu_s),',Fk=',num2str(mu_k),...
        ',level height[',num2str(level_height_array(1)),'~',num2str(level_height_array(end)),'].fig'];

%     fig_file_name = 'test.fig';
    save_fig_path = fullfile(pwd,['Sim result_stairs_V=',num2str(forward_vel_goal)],fig_file_name);        

    saveas(gca, save_fig_path);
    fprintf('Figure saved sucessful\n');
%     close all; 
%     clear analysis_data;

end