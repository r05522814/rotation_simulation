function plot_legend = plot_landscape_duel_leg(landscape_table,leg_contour)
    %% plot landscape
    plot_legend.landscape = plot(landscape_table(1,:),landscape_table(2,:),'color','k' ,'linewidth', 2.5 );
    hold on;
%     axis equal;
%     axis normal;
    %% plot hip joint
    plot(leg_contour.center(1),leg_contour.center(2),'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',[.49 1 .63], 'MarkerSize',8);
    
    %% plot leg_1
    plot_legend.leg_1 = ...
    plot(leg_contour.leg_1.contour.x, leg_contour.leg_1.contour.y, 'color','b' ,'linewidth', 1.5);
    
    % plot from center to the first point of the contour
    plot([leg_contour.leg_1.center(1), leg_contour.leg_1.contour.x(1)],...
         [leg_contour.leg_1.center(2), leg_contour.leg_1.contour.y(1)], 'color','b','linewidth', 1.5);
    
    % plot the center of the half circle
    plot(leg_contour.leg_1.center(1), leg_contour.leg_1.center(2),... 
        'marker','x','color','b', 'MarkerSize',8);
    
    %% plot leg_2
    plot_legend.leg_2 = ...
    plot(leg_contour.leg_2.contour.x, leg_contour.leg_2.contour.y, 'color','b' ,'linewidth', 1.5);
    
    % plot from center to the first point of the contour
    plot([leg_contour.leg_2.center(1), leg_contour.leg_2.contour.x(1)],...
         [leg_contour.leg_2.center(2), leg_contour.leg_2.contour.y(1)], 'color','b','linewidth', 1.5);
    
    % plot the center of the half circle
    plot(leg_contour.leg_2.center(1), leg_contour.leg_2.center(2),...   
        'marker','x','color','b', 'MarkerSize',8);
    
    %% plot duel leg_3
    plot_legend.leg_3 = ...
    plot(leg_contour.leg_3.contour.x, leg_contour.leg_3.contour.y, 'color','r' ,'linewidth', 1.5);
    
    % plot from center to the first point of the contour
    plot([leg_contour.leg_3.center(1), leg_contour.leg_3.contour.x(1)],...
         [leg_contour.leg_3.center(2), leg_contour.leg_3.contour.y(1)], 'color','r','linewidth', 1.5);
    
    % plot the center of the half circle
    plot(leg_contour.leg_3.center(1), leg_contour.leg_3.center(2),... 
        'marker','x','color','r', 'MarkerSize',8);
    
    %% plot leg_4
    plot_legend.leg_4 = ...
    plot(leg_contour.leg_4.contour.x, leg_contour.leg_4.contour.y, 'color','r' ,'linewidth', 1.5);
    
    % plot from center to the first point of the contour
    plot([leg_contour.leg_4.center(1), leg_contour.leg_4.contour.x(1)],...
         [leg_contour.leg_4.center(2), leg_contour.leg_4.contour.y(1)], 'color','r','linewidth', 1.5);
    
    % plot the center of the half circle
    plot(leg_contour.leg_4.center(1), leg_contour.leg_4.center(2),...   
        'marker','x','color','r', 'MarkerSize',8);

    
    %% show the position of the hip joint
    
    hip_joint_txt = ['Hip joint = (',num2str(leg_contour.center(1),'%.2f'),', ',num2str(leg_contour.center(2),'%.2f'),' )'];
    text(leg_contour.center(1) , leg_contour.center(2) + 0.2, hip_joint_txt,...
        'color',[0 0.5 0], 'fontsize', 10);
    
end