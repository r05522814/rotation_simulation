function contact_point = find_contact_point(leg_contour , landscape_table , r)
% When the leg_contour and the gound is overlap, return the contact point
% and the distance needed as the displacement of thew leg

    error_dis = 0.01;


    contact_area_index_1 = leg_contour.leg_1.contour.y <= interp1(landscape_table(1,:),landscape_table(2,:),leg_contour.leg_1.contour.x);
    contact_area_index_2 = leg_contour.leg_2.contour.y <= interp1(landscape_table(1,:),landscape_table(2,:),leg_contour.leg_2.contour.x);   
    contact_area_index_3 = leg_contour.leg_3.contour.y <= interp1(landscape_table(1,:),landscape_table(2,:),leg_contour.leg_3.contour.x);
    contact_area_index_4 = leg_contour.leg_4.contour.y <= interp1(landscape_table(1,:),landscape_table(2,:),leg_contour.leg_4.contour.x);
    % find all the points of contour lower than the landscape
    
    leg_1_touch_gound = ~isempty( find(contact_area_index_1, 1) ) ;
    leg_2_touch_gound = ~isempty( find(contact_area_index_2, 1) ) ;
    leg_3_touch_gound = ~isempty( find(contact_area_index_3, 1) ) ;
    leg_4_touch_gound = ~isempty( find(contact_area_index_4, 1) ) ;

    if leg_1_touch_gound
        % define searching area of x of the landscape
        contact_area_x_1 = leg_contour.leg_1.contour.x( 1, contact_area_index_1 );

        contact_area_y_1 = interp1(landscape_table(1,:),landscape_table(2,:),contact_area_x_1);

        landscape_points_1 = [contact_area_x_1 ; contact_area_y_1];   
        ditance_matrix_1 = pdist2 (leg_contour.leg_1.center , landscape_points_1'  );
        % ditance_matrix(i,j) 
        % means the distance from ith point in X to jth point in Y
        
        % Find the min_dis between the half circle center and the ground
        min_distance_1 = min(ditance_matrix_1(:));
        [i,j] = find(ditance_matrix_1 == min_distance_1 , 1);
        
        revise_vector_1 = (leg_contour.leg_1.center - landscape_points_1(:,j)')/norm(leg_contour.leg_1.center - landscape_points_1(:,j)');
        revise_vector_1 = revise_vector_1*(r - min_distance_1);
        
        contact_point.point_1.point = landscape_points_1(:,j)';
        contact_point.point_1.revise = revise_vector_1;

        %ditance between contact point and tip & toe
        contact_point.point_1.istip = norm(landscape_points_1(:,j)' - leg_contour.leg_1.tip ) < error_dis;
        contact_point.point_1.istoe = norm(landscape_points_1(:,j)' - leg_contour.leg_1.toe ) < error_dis;
 
    else
        contact_point.point_1.point = [];
        contact_point.point_1.revise = [];
    end

    if leg_2_touch_gound

        contact_area_x_2 = leg_contour.leg_2.contour.x( 1, contact_area_index_2 );
        contact_area_y_2 = interp1(landscape_table(1,:),landscape_table(2,:),contact_area_x_2);

        landscape_points_2 = [contact_area_x_2 ; contact_area_y_2];   
        ditance_matrix_2 = pdist2 ( leg_contour.leg_2.center , landscape_points_2'  );
        % ditance_matrix(i,j) 
        % means the distance from ith point in X to jth point in Y
        
        min_distance_2 = min(ditance_matrix_2(:));
        [u,v] = find(ditance_matrix_2 == min_distance_2 , 1);
        revise_vector_2 = (leg_contour.leg_2.center - landscape_points_2(:,v)') / norm(leg_contour.leg_2.center - landscape_points_2(:,v)');
        revise_vector_2 = revise_vector_2 * (r - min_distance_2);
        contact_point.point_2.point = landscape_points_2(:,v)';
        contact_point.point_2.revise = revise_vector_2;

        %ditance between contact point and tip & toe
        contact_point.point_2.istip = norm(landscape_points_2(:,v)' - leg_contour.leg_2.tip ) < error_dis;
        contact_point.point_2.istoe = norm(landscape_points_2(:,v)' - leg_contour.leg_2.toe ) < error_dis;
    else
        contact_point.point_2.point = [];
        contact_point.point_2.revise = [];
    end
    
    if leg_3_touch_gound
        % define searching area of x of the landscape
        contact_area_x_3 = leg_contour.leg_3.contour.x( 1, contact_area_index_3 );

        contact_area_y_3 = interp1(landscape_table(1,:),landscape_table(2,:),contact_area_x_3);

        landscape_points_3 = [contact_area_x_3 ; contact_area_y_3];   
        ditance_matrix_3 = pdist2 (leg_contour.leg_3.center , landscape_points_3'  );
        % ditance_matrix(i,j) 
        % means the distance from ith point in X to jth point in Y
        
        % Find the min_dis between the half circle center and the ground
        min_distance_3 = min(ditance_matrix_3(:));
        [i,j] = find(ditance_matrix_3 == min_distance_3 , 1);
        
        revise_vector_3 = (leg_contour.leg_3.center - landscape_points_3(:,j)')/norm(leg_contour.leg_3.center - landscape_points_3(:,j)');
        revise_vector_3 = revise_vector_3*(r - min_distance_3);
        
        contact_point.point_3.point = landscape_points_3(:,j)';
        contact_point.point_3.revise = revise_vector_3;

        %ditance between contact point and tip & toe
        contact_point.point_3.istip = norm(landscape_points_3(:,j)' - leg_contour.leg_3.tip ) < error_dis;
        contact_point.point_3.istoe = norm(landscape_points_3(:,j)' - leg_contour.leg_3.toe ) < error_dis;
 
    else
        contact_point.point_3.point = [];
        contact_point.point_3.revise = [];
    end

    if leg_4_touch_gound

        contact_area_x_4 = leg_contour.leg_4.contour.x( 1, contact_area_index_4 );
        contact_area_y_4 = interp1(landscape_table(1,:),landscape_table(2,:),contact_area_x_4);

        landscape_points_4 = [contact_area_x_4 ; contact_area_y_4];   
        ditance_matrix_4 = pdist2 ( leg_contour.leg_4.center , landscape_points_4'  );
        % ditance_matrix(i,j) 
        % means the distance from ith point in X to jth point in Y
        
        min_distance_4 = min(ditance_matrix_4(:));
        [u,v] = find(ditance_matrix_4 == min_distance_4 , 1);
        revise_vector_4 = (leg_contour.leg_4.center - landscape_points_4(:,v)') / norm(leg_contour.leg_4.center - landscape_points_4(:,v)');
        revise_vector_4 = revise_vector_4 * (r - min_distance_4);
        contact_point.point_4.point = landscape_points_4(:,v)';
        contact_point.point_4.revise = revise_vector_4;

        %ditance between contact point and tip & toe
        contact_point.point_4.istip = norm(landscape_points_4(:,v)' - leg_contour.leg_4.tip ) < error_dis;
        contact_point.point_4.istoe = norm(landscape_points_4(:,v)' - leg_contour.leg_4.toe ) < error_dis;
    else
        contact_point.point_4.point = [];
        contact_point.point_4.revise = [];
    end
end



