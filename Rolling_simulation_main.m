%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is used for observing the difference between leg and wheel
% Especially for the different characteristics on different terrains
%
% Geometry included
%
% Last advised : 2018/01/16
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% opengl info


%% Draw the continuous animation with given conditions
clear variables; clc;

timer_total = tic;

r = 0.11;  % leg length (m)
delta_r_initial = 0;  % delta leg length (m) [0 , 0.045]
leg_mass = 1 ; % define the mass of the structure (kg)

static_friction_const = 0.8; % define the equivalent static friction constant between the wheel and the ground 
mass_force = [0 -(leg_mass*9.8)];

%% Settings

enable.video = 1;  % switch to 1 to enable video recording
enable.xls_record = 1;   % switch to 1 to write the data to the excel file
enable.time_elapsed_print = 1;  % switch to 1 to show the time elapsed of each iteration
enable.plot_quiver = 1;  % switch to 1 to show the force quiver including mass and reaction force from the ground
enable.plot_required_torque = 1; % switch 1 to show the 

visualization.force = 0.02; % set the quiver factor for the force vector 
visualization.movement = 25; % set the quiver factor for the movement vector 

%% Inital values
hip_joint_initial = [0,0.15];  % initail position of the hip joint
theta_initial = 0; % define the intial posture of the leg
theta_end = theta_initial + 2 * pi; % define the fianl posture of the leg

% define how much time the leg is going to run (sec)
t_initial = 0;
t_end = 10; 

V_initial = 0;

% define the resolution of the animation
% More points, higher resolution 
num_of_iterations = 1001;


gait_table(1,:) = linspace(t_initial, t_end, num_of_iterations);
gait_table(2,:) = linspace(theta_initial, theta_end, num_of_iterations);
gait_table(3,:) = 0 * gait_table(1,:) + delta_r_initial ; 

t_increment = (t_end - t_initial)/ (num_of_iterations - 1);

%% Define landscape
x_range = [-0.2, 1.5]; % range of the window
y_range = [-0.2, 0.6];

x_partition_diff = 0.001; % define the resolution of the gound
x_partition = x_range(1):x_partition_diff:x_range(2);  % x_partition

landscape_function = 2;  

switch(landscape_function)
    case 1   % Rough terrain
        landscape_partition = 0.05 * sin(10 * x_partition) + x_partition*0.1 ;
        landscape_str = 'rough';
    case 2   % Flat terrain
        landscape_partition = 0 * x_partition   ;
        landscape_str = 'flat';
    case 3   % Stairs
        landscape_partition = craete_stair_landscape(x_partition, 6, 8) ;  
        % (x_partition, stair_level, level_height)
        landscape_str = 'stairs';
    case 4   % parabolic
        landscape_partition = 0.8 * (x_partition + 0.1).^2  ;  
        landscape_str = 'parabolic';
end

landscape_partition_diff = diff(landscape_partition);

landscape_table(1,:) = x_partition;
landscape_table(2,:) = landscape_partition;

% first dirivative value
landscape_table(3,1) = 0;
landscape_table(3,2:end) = landscape_partition_diff;

clear x_partition landscape_partition landscape_partition_diff;

%% Video settings
if enable.video == 1
    video_filename = ['T=',num2str(t_end ),'(s)'...
                      ', Theta=',num2str(theta_initial*180/pi),'~',num2str(theta_end*180/pi),'(deg)'...
                      ', dr=',num2str(delta_r_initial),...
                      ', Fs=',num2str(static_friction_const),...
                      ', ',landscape_str,'.avi'];
    writerObj = VideoWriter(video_filename);
    writerObj.FrameRate = 1 / t_increment;  % set playing frame rate
    open(writerObj);   
end

%% Plot the landscape and the leg with initial value
figure(1)
set(gcf,'name','Leg rotaion simulation','Position', [100 100 1500 800]);

% First trial
% To get the leg_contour for the further contacting calculation
hip_joint = hip_joint_initial;
V_last = V_initial;
leg_contour = def_leg_contour(hip_joint, theta_initial, delta_r_initial);
movement_vector = [0 0];

% initialize data_record
data_record = double.empty(5,0);


%% Main loop start

for loop_iteration = 1:num_of_iterations

    timer_loop = tic;
    
    subplot(5,1,1:4);
    
    t = gait_table(1,loop_iteration);
    theta = gait_table(2,loop_iteration);
    if loop_iteration > 1
        theta_increment = gait_table(2,loop_iteration) - gait_table(2,loop_iteration-1);
    else
        theta_increment = 0;
    end
    delta_r = gait_table(3,loop_iteration);
    
    
    % apply the movement
    hip_joint = hip_joint + movement_vector; 
    
    %% Check overlap and update the hip joint and contact point
    % Geometric constrian check and fix
    
    % Find normal force point
    normal_force_point = find_normal_force_point(leg_contour,landscape_table);
    
    if ~isempty(normal_force_point.point_1)
        
        % tangent of normal force point
        land_diff = lookup_table(landscape_table(1,:),landscape_table(3,:),normal_force_point.point_1(1));  
                
        % l* sin(theta), where theta is the angle between tangent vector and verticle line
        force_distance = abs(normal_force_point.point_1(3))*( x_partition_diff / sqrt(x_partition_diff^2 + land_diff^2) ); 
        
        % The steeper slope, the smaller value, range(0,1]
        force_distance = force_distance * (0.3);  % for distance estimation error, more reasonable result
        
        force_direction = [-land_diff , x_partition_diff];
        % normalize
        force_direction = force_direction/ (sqrt(land_diff^2+x_partition_diff^2));
        
        % visualize the position shifting  by using arrow
        % according to the overlap
%         force_mag = -100 * normal_force_point.point_1(3);  % scaled parameter for visualization
%         quiver(normal_force_point.point_1(1),normal_force_point.point_1(2),...
%                -force_mag * land_diff , force_mag * x_partition_diff,... (-y,x)
%                 'MaxHeadSize',0.5,'color','b');
        
        % plot contacting point
        plot_legend.contact_point_1 = ...
            plot(normal_force_point.point_1(1),normal_force_point.point_1(2),'marker','*','MarkerSize',10,'color','b');
        hold on;
        
        contact_point_1 = [normal_force_point.point_1(1) , normal_force_point.point_1(2)];
        rolling_point.point = contact_point_1;
        rolling_point.normal_force_dir = force_direction;
        
        % adjust the hip joint
        hip_joint = hip_joint + force_distance * force_direction;
        
    else
        contact_point_1 = [];
        rolling_point.point = [];
        rolling_point.normal_force_dir = [];
    end
    
    
    if ~isempty(normal_force_point.point_2)

        land_diff = lookup_table(landscape_table(1,:),landscape_table(3,:),normal_force_point.point_2(1));       
        % Visualize the position shifting by using arrow
        % according to the overlap

        force_distance = abs(normal_force_point.point_2(3))*( x_partition_diff / norm([x_partition_diff, land_diff]) );

        force_distance = force_distance *(0.3);  % for distance estimation error, more reasonable result
        
        
        force_direction = [-land_diff , x_partition_diff];
        force_direction = force_direction / (norm([land_diff, x_partition_diff]));
        
        
%         force_mag = -100 * normal_force_point.point_2(3);  % scaled parameter
%         quiver(normal_force_point.point_2(1),normal_force_point.point_2(2),...
%                -force_mag * land_diff, force_mag*x_partition_diff,... (-y,x)
%                 'MaxHeadSize',0.5,'color','r');            
        % plot contacting point
        plot_legend.contact_point_2 = ...
            plot(normal_force_point.point_2(1),normal_force_point.point_2(2),'marker','*','MarkerSize',10,'color','r');
        hold on;
        
        
        contact_point_2 = [normal_force_point.point_2(1) , normal_force_point.point_2(2)];
        rolling_point.point = contact_point_2;
        
        % Adjust the hip joint
        hip_joint = hip_joint + force_distance * force_direction;
        
        % redecide rolling center
        if isempty(contact_point_1) 
            rolling_point.point  = contact_point_2;
            rolling_point.normal_force_dir = force_direction;
            
        elseif contact_point_2(1) > contact_point_1(1)  % Two contact point, the rolling center is the right one
            rolling_point.point  = contact_point_2;
            rolling_point.normal_force_dir = force_direction;
            
        end
        
    else
        contact_point_2 = [];
    end
       
    
    if( isempty(contact_point_1) && isempty(contact_point_2) )
        rolling_point.point  = [];
        rolling_point.normal_force_dir = [];
    else
        rolling_point_txt = ['Rolling point = (',num2str(rolling_point.point (1),4),', ',num2str(rolling_point.point (2),4),' )'];
        text(rolling_point.point (1) , rolling_point.point (2) - 0.1, rolling_point_txt,'color', 'k', 'fontsize', 12);

        plot_legend.rolling_point = plot (rolling_point.point (1), rolling_point.point (2),'marker','.','MarkerSize',20,'color','g');
    end
    
    
    
    
    %% Drawings 

    % Return the leg_contour
    leg_contour = def_leg_contour(hip_joint, theta, delta_r);
    
    % Draw the landscape and the leg
    plot_legend = plot_landscape_leg(landscape_table,leg_contour);

    title_str = [sprintf('T = %.2f',t), ' (s) , ',...
                '\Delta \theta = ', sprintf('%.2f',theta*180/pi),' \circ , ',...
                '\Delta r = ', sprintf('%.1f',delta_r*100),' (cm) , '...
                '\mu_s = ', sprintf('%.1f',static_friction_const),' , ', landscape_str ];
            
    title(title_str, 'fontsize',18);
    axis equal;
    axis([x_range y_range]); % acorrding to the given landscape

   
    %% Determin next step : revolution considering slip effect 
    % Force constrains considered
    
    if(~isempty(rolling_point.point))   % Contact with ground

        % considering friction effect

        rolling_point.normal_force = ...
            dot(-mass_force , rolling_point.normal_force_dir) * rolling_point.normal_force_dir;

        rolling_point.tangent_force = (-mass_force) - rolling_point.normal_force;

        % max friction force
        max_static_friction = static_friction_const * norm(rolling_point.normal_force);
        rolling_point.tangent_force_dir = (rolling_point.tangent_force) / norm(rolling_point.tangent_force);
        max_static_friction_force = max_static_friction * rolling_point.tangent_force_dir ;
        
        rotation_radius_vector = hip_joint - rolling_point.point ; % contact point to the hip

        if( norm(rolling_point.tangent_force) <= max_static_friction )
            % No-slip condition, rolling with respect to the contact point 
            % calculate the total reaction force provided by ground
            rolling_point.total_reaction_force = rolling_point.normal_force + rolling_point.tangent_force;
            % Static
            isStatic = true;
            text( x_range(1) + 0.05 , y_range(2) - 0.1, 'No slip','color', 'k', 'fontsize', 12);
            
        else
            % Slip condition
            % calculate the total reaction force provided by ground
            rolling_point.total_reaction_force = rolling_point.normal_force + max_static_friction_force;
            
            % gravity fraction can't be eliminate by the friction
%             movement_vector = ... % 0.01
%             (max_static_friction - norm(rolling_point.tangent_force)) * rolling_point.tangent_force_dir ...
%             /leg_mass *0.5* 0.01 ;
            % transfer the external force to displacement
        
            isStatic = false;  % not static, considering kinetics
            text( x_range(1) + 0.05 , y_range(2) - 0.1, 'Slipping !','color', 'r','fontsize', 12);
        end
        
        % visualize the force including mass, reaction normal and reaction tangential
        if enable.plot_quiver == 1
            

            plot_legend.mass_force = quiver(hip_joint(1),hip_joint(2),...
            mass_force(1) * visualization.force , mass_force(2) * visualization.force,... 
            'MaxHeadSize',0.5,'color','k', 'LineStyle', ':');

            plot_legend.reaction_force = quiver(rolling_point.point(1),rolling_point.point(2),...
            -mass_force(1) * visualization.force , -mass_force(2) * visualization.force,... 
            'MaxHeadSize',0.5,'color','k', 'LineStyle', ':');

            % normal reaction force
            plot_legend.reaction_normal_force = quiver(rolling_point.point(1),rolling_point.point(2),...
            rolling_point.normal_force(1)*visualization.force , rolling_point.normal_force(2)*visualization.force,... 
            'MaxHeadSize',0.5,'color',[0.6350 0.0780 0.1840], 'LineStyle', ':'); % brown

            % tangential reaction force
            plot_legend.reaction_tangent_force = quiver(rolling_point.point(1),rolling_point.point(2),...
            rolling_point.tangent_force(1)*visualization.force , rolling_point.tangent_force(2)*visualization.force,... 
            'MaxHeadSize',0.5,'color',[0.6350 0.0780 0.1840], 'LineStyle', ':'); % brown

            % max friction
            plot_legend.max_friction = quiver(rolling_point.point(1),rolling_point.point(2),...
            max_static_friction_force(1)*visualization.force, max_static_friction_force(2)*visualization.force,... 
            'MaxHeadSize',0.5,'color',[0.8500 0.3250 0.0980], 'LineStyle', ':');  
        end
        
        % When contacting with ground, the normal direction of the vel should be zero
        V_last = V_last - dot( V_last , rolling_point.normal_force_dir) * rolling_point.normal_force_dir;
        
        min_require_torque = cross([rolling_point.total_reaction_force 0],[rotation_radius_vector 0]);
        min_require_torque = min_require_torque(3); 
        
    else
        % Does not contact to ground, fall.
        rolling_point.total_reaction_force = 0;
%         movement_vector = mass_force / leg_mass *0.5* 0.01;  %(t_increment^2);
        isStatic = false;  % not static, considering kinetics
        min_require_torque = 0;
        text(  x_range(1) + 0.05 , y_range(2) - 0.1, 'Falling !','color', 'k', 'fontsize', 12);
    end
    
    
    % Calculating total force
    total_force = mass_force + rolling_point.total_reaction_force;
    total_acceleration = total_force / leg_mass;
    
    % visualize the total force by using arrow
%     if enable.plot_quiver == 1
%         plot_legend.total_force = quiver(hip_joint(1),hip_joint(2),...
%                    visualization.force * total_force(1),visualization.force * total_force(2),... 
%                     'MaxHeadSize',2,'color','r'); 
%     end

        
    % Determine movement
    if isStatic == true  % Static
        % No-slip condition, rolling with respect to the contact point            
        % rotate clockwise wrt the contact point
        
        new_rotation_radius_vector =  rotation_radius_vector * [cos(-theta_increment) sin(-theta_increment) 
                                                               -sin(-theta_increment) cos(-theta_increment)] ;
        movement_vector = (rolling_point.point + new_rotation_radius_vector) - hip_joint;
%         V_now = movement_vector / t_increment ; % Static
        V_now = [0 0];
    else  
        % not static, considering kinetics
        % additional force convert to acceleration      
        V_now = V_last + total_acceleration * t_increment;
        movement_vector = V_now * t_increment;
            
    end
    Vel_now = movement_vector / t_increment;
    Vel_txt = ['V = (',sprintf('%.2f',Vel_now(1)),',',...
        sprintf('%.2f',Vel_now(2)),') , |V| = ',sprintf('%.2f',norm(Vel_now)),'(m/s)'] ;
    text( x_range(2) - 0.4 , y_range(1) + 0.08 , Vel_txt ,'color', 'k', 'fontsize', 12);
    V_last = V_now; 
    
    
    
    % visualize the hip joint movement by using arrow
    % now hip joint position
    % scaled parameter
    if enable.plot_quiver == 1
        plot_legend.movement = quiver(hip_joint(1),hip_joint(2),...
                       visualization.movement * movement_vector(1),visualization.movement * movement_vector(2),... 
                        'MaxHeadSize',0.5,'color','k');
    end
    
    %% Record data, adjust array size with loop
    data_record(1,loop_iteration) = t;
    data_record(2,loop_iteration) = theta;
    data_record(3,loop_iteration) = hip_joint(1);
    data_record(4,loop_iteration) = hip_joint(2);
    data_record(5,loop_iteration) = min_require_torque;
        
    % plot the trajectory of the hip joint
    plot_legend.hip = plot(data_record(3,:),data_record(4,:),...
            'marker','.','MarkerSize',2,'color',[0.4660   0.6740   0.1880]);
        
    % plot the legend    
    legend([plot_legend.landscape plot_legend.hip plot_legend.leg_1 plot_legend.leg_2 plot_legend.movement],...
            {'Landscape','Hip joint trajectory','Leg_1','Leg_2','Movement vector'},...
            'FontSize',14);
        
    % write video or refresh drawing
    if enable.video == 1
        videoFrame = getframe(gcf);
        writeVideo(writerObj, videoFrame);
    else
        drawnow;
    end
    hold off;
    
    % print the elapsed time
    if enable.time_elapsed_print == 1
        time_str = [sprintf('%.1f',(loop_iteration/num_of_iterations*100)),'%% , ',...
                    sprintf('Elapsed = %.2f(s)', toc(timer_total))...
                    sprintf(', loop = %.2f(s)\n', toc(timer_loop))];
        fprintf(time_str);
    end
    
    
    subplot(5,1,5);   
    plot(data_record(1,:),data_record(5,:),'color',[ 0    0.4470    0.7410],'linewidth',1.5);
    hold on;
    plot([0 t_end],[0 0],'--','color',[0.01 0.01 0.01]);
    title(['Minimun torque require = ',sprintf('%.2f',min_require_torque),' (Nm)']);
    xlabel('time (s)');
    ylabel('Torque (Nm)');
    xlim([t_initial t_end]);
    hold off;
    
    
    
end

%% Calculation
% Calculate min. required work
total_work = trapz( data_record(1,:),data_record(5,:));
total_work_abs = trapz( data_record(1,:) , abs(data_record(5,:)) );

% Calculate the length of hip joint trajectory  
% Calculate integrand from x,y derivatives, and integrate to calculate arc length
hip_joint_trajectory_length =  trapz(hypot(   diff( data_record(3,:) ), diff( data_record(4,:) )  ));   

% Calculate the length of the landscape, where the hip joint has traveled 
traveled_landscape.points = [data_record(3,:) ; 
                            lookup_table(landscape_table(1,:),landscape_table(2,:), data_record(3,:) )];
traveled_landscape.length = trapz(hypot( diff(traveled_landscape.points(1,:)) , diff(traveled_landscape.points(2,:)) ));


hip_joint_vs_landscape_length_ratio = hip_joint_trajectory_length / traveled_landscape.length
work_per_landscape_length = total_work_abs / traveled_landscape.length

data_record(6,1) = hip_joint_vs_landscape_length_ratio;
data_record(7,1) = work_per_landscape_length;


%%
if enable.video == 1
    close(writerObj);
    fprintf('video finished\n');
end

if enable.xls_record == 1
    xlsx_tab_str = ['theta=',num2str(theta_end*180/pi),', dr=',num2str(delta_r),', ', landscape_str];
    data_record = data_record'; % switch arrangement from row to column
%     data_col_header = {'T' ,'Theta','Hip joint x','Hip joint y','Min required torque'};

    [xls_status, xls_message] = xlswrite('20180117.xlsx',data_record, xlsx_tab_str);
%     [xls_status, xls_message] = writetable(data_table,'table.xlsx','Sheet', xlsx_tab_str);
    if xls_status == 1
        fprintf('xlsx write sucessful\n');
    else
        fprintf('xlsx write error\n');
    end
end

fprintf('Total time = %f sec\n', toc(timer_total));
%%
% figure(2)
% set(gcf,'name','minimun torque require');
% plot(data_record(1,:),data_record(7,:),'linewidth',1.5);
% hold on;
% plot([0 t_end],[0 0],'--','color',[0.01 0.01 0.01]);
% title('Minimun torque require');
% xlabel('time (s)');
% ylabel('Torque (Nm)');