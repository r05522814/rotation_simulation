function leg_contour = def_duel_leg_contour(hip_joint, delta_theta, delta_theta_duel, delta_r, delta_r_duel)

% define initial position of the lag
% couunter-clockwise : + delta_thetatheta
    defined_theta = - delta_theta; 
%     delta_r = 1;

    real_theta = defined_theta + 3/2*pi ;
    
    real_theta_duel = - delta_theta_duel + 3/2*pi;

%     plot(hip_joint(1),hip_joint(2),'marker','o','MarkerSize',8)
%     hold on;
    
    % find the center of the two half circle individually
    leg_1_center = [hip_joint(1) - delta_r*cos(real_theta), ...
                    hip_joint(2) - delta_r*sin(real_theta)];

    leg_2_center = [hip_joint(1) + delta_r*cos(real_theta), ...
                    hip_joint(2) + delta_r*sin(real_theta)];
                
    leg_3_center = [hip_joint(1) - delta_r_duel*cos(real_theta_duel), ...
                    hip_joint(2) - delta_r_duel*sin(real_theta_duel)];

    leg_4_center = [hip_joint(1) + delta_r_duel*cos(real_theta_duel), ...
                    hip_joint(2) + delta_r_duel*sin(real_theta_duel)];

    half_circle_1 = def_half_circle(leg_1_center(1), leg_1_center(2), real_theta, 1);
    half_circle_2 = def_half_circle(leg_2_center(1), leg_2_center(2), real_theta + pi, 2);
    half_circle_3 = def_half_circle(leg_3_center(1), leg_3_center(2), real_theta_duel, 1);
    half_circle_4 = def_half_circle(leg_4_center(1), leg_4_center(2), real_theta_duel + pi, 2);
    
    leg_contour.leg_1.contour = half_circle_1;
    leg_contour.leg_1.center = leg_1_center;
    leg_contour.leg_1.tip = [leg_contour.leg_1.contour.x(1),leg_contour.leg_1.contour.y(1)];
    leg_contour.leg_1.toe = [leg_contour.leg_1.contour.x(end),leg_contour.leg_1.contour.y(end)];
    
    leg_contour.leg_2.contour = half_circle_2;
    leg_contour.leg_2.center = leg_2_center;
    leg_contour.leg_2.tip = [leg_contour.leg_2.contour.x(1),leg_contour.leg_2.contour.y(1)];
    leg_contour.leg_2.toe = [leg_contour.leg_2.contour.x(end),leg_contour.leg_2.contour.y(end)];
        
    leg_contour.leg_3.contour = half_circle_3;
    leg_contour.leg_3.center = leg_3_center;
    leg_contour.leg_3.tip = [leg_contour.leg_3.contour.x(1),leg_contour.leg_3.contour.y(1)];
    leg_contour.leg_3.toe = [leg_contour.leg_3.contour.x(end),leg_contour.leg_3.contour.y(end)];
    
    leg_contour.leg_4.contour = half_circle_4;
    leg_contour.leg_4.center = leg_4_center;
    leg_contour.leg_4.tip = [leg_contour.leg_4.contour.x(1),leg_contour.leg_4.contour.y(1)];
    leg_contour.leg_4.toe = [leg_contour.leg_4.contour.x(end),leg_contour.leg_4.contour.y(end)];
    
    leg_contour.center = hip_joint;
end