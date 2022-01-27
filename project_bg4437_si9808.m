% author: Bhaskar Krishna Gangadhar
% author: Shweta Nateshan Iyer
function project_bg4437_si9808()

    % Make sure the TEST_IMAGES folder is in the same directory are the
    % code.
    close all; clear all;
    addpath('../TEST_IMAGES/');
    shapes = ["Oval", "Squiggle", "Diamond"];
    shape_types = ["Solid", "Not solid"];
     
    file_list = dir('../TEST_IMAGES/*.jpg');
    for counter = 1 : length(file_list)
        
        fprintf('\nINPUT Filename: %s', file_list(counter).name);
        im_in = imread(file_list(counter).name);
        im_og = im2double(im_in);

        
        [~, ~, val] = rgb2hsv(im_og);
        % COnverting the image to binary.
        im_bw = imbinarize(val);

        % cleaning off some tiny white noise that might exist.
        se = strel('disk',4);
        im_bw = imerode(im_bw, se);

        % Performing morphology to increase the dot area.
        se = strel('disk',10);
        im_morphed = imclose(im_bw, se);
       
        % Getting all the regions/cards.
        blobs = regionprops(im_morphed, 'all');
        nBlobs = size(blobs, 1);
        
        anotherCounter = 1;
        for blob_counter = 1: nBlobs
            % Filtering out just the card regions.
            if(blobs(blob_counter).Area > 100000 && blobs(blob_counter).Area < 1000000 && blobs(blob_counter).BoundingBox(3) < 1500)
                onlyCards(anotherCounter) = blobs(blob_counter);
                anotherCounter = anotherCounter +  1;
            end
        end
        
        %%%
        %----------------------------------Shapes-------------------------%
        %%%
        figure;
        for card_counter = 1: length(onlyCards)
            card_bb = onlyCards(card_counter).BoundingBox;
            
            % Blue channel cause most contrast for all the colors in the
            % game.
            im_card = im_og(floor(card_bb(2)):floor(card_bb(2)+card_bb(4)),floor(card_bb(1)):floor(card_bb(1)+floor(card_bb(3))), 3);
            
            % Make it a plain card by filling the shapes.
            card_no_holes = imfill(im_card, 'holes');
            
            % Now subtract the two images to get the shapes.
            im_card = card_no_holes-im_card;
            
            % Let's binarize the image.
            im_card_bw = imbinarize(im_card);
            
            % Make the shapes solid.
            im_shapes = imfill(im_card_bw, 'holes');
            
            is_solid = 1;
            how_much_filled = im_shapes - im_card_bw;
            if sum(how_much_filled(:)) > 100
                is_solid = 2;
            end
            % Find the regions with shapes
            shape_blobs = regionprops(im_shapes, 'all');
            shape_nBlobs = size(shape_blobs, 1);
            
            % Maybe there was some noise, get rid of it.
            if shape_nBlobs > 3
                shape_nBlobs = 3;
            end
            
            % predicting the shape based on the properties of bounding box.
            shape_type = 2;
            if shape_blobs(1).Circularity > 0.7
                shape_type = 1;
            elseif shape_blobs(1).Solidity > 0.9
                shape_type = 3;
            end
            
            %----------------------------------Color-------------------------%
            
            %Getting the colored card image
            im_card_color = im_in(round(card_bb(2)):round(card_bb(2)+card_bb(4)),round(card_bb(1)):round(card_bb(1)+card_bb(3)),:);
            
            %Finding regions with shapes
            shape_blobs_color = regionprops(im_card_bw, 'all');
            
            shape_area = [shape_blobs_color.Area];
            
            stop_condition = 0;
            for shape = 1:length(shape_area)
                
                %Out of all the regions, the one with max area would be the
                %shape on the card. We need to check the color of that
                %shape
                if shape_blobs_color(shape).Area == max(shape_area)
                    dim = shape_blobs_color(shape).BoundingBox;
                    purple_flag = 0;
                    green_flag = 0;
                    red_flag = 0;
                    x_value = round(dim(1));
                    y_value = round(dim(2));
                    
                    %Calling function to check if current shape's color is
                    %red. If not we check for purple or green color.
                    if check_for_red(im_card_color, x_value, y_value) == false
                        
                        %Making the card image darker since some
                        %images are overexposed, causing a slight 
                        %change in the base color of the card
                        im_dark = im_card_color.*(1/2);
                        
                        %Since the first x,y coordinate value we get from
                        %bounding box may not be a color pixel, we loop
                        %till we reach a color pixel
                        for col = x_value : size( im_card_color, 2 )
                            for row = y_value : size( im_card_color, 1 )
                                
                                red_value = im_dark(row,col,1);
                                green_value = im_dark(row,col,2);
                                blue_value = im_dark(row,col,3);
                                
                                %Range for green pixel value
                                if red_value < 55 && green_value > 49 
                                    green_flag = 1;
                                    stop_condition = 1;
                                    break;
                                end
                                %Range for purple pixel value
                                if red_value > 45 && red_value < 78 && green_value < 55 && blue_value > 50
                                    purple_flag = 1;
                                    stop_condition = 1;
                                    break;
                                end                                
                            end
                            if stop_condition == 1
                                break;
                            end
                        end
                        
                    else
                        red_flag = 1;
                    end
                end
                if stop_condition == 1
                    break;
                end
            end
            
            if green_flag == 1
                card_color = 'Green';
            elseif purple_flag == 1
                card_color = 'Purple';
            else
                card_color = 'Red';
            end
            
            %----------------------------------Color-------------------------%
            
           	subplot(3,4,card_counter);
            imshow(im_card_color);
            
            title(sprintf('Shape: %s Number: %d Color: %s Type: %s', shapes(shape_type), shape_nBlobs, card_color, shape_types(is_solid)), '\fontsize{4} text');
            axis image
        end
        
        %%%
        %----------------------------------Shapes-------------------------%
        %%%
        
        % Taking the RGB image to crop out the regions.
        im_output = im_og;
        fprintf('\nNumber of Cards = %d', anotherCounter - 1);
        
        %Initializing variables for minimum and maximum x and y values
        %x_min denotes the x coordinate of the start of longer side in the trapezoid
        %y_min denotes the y coordinate of the shorter side in the trapezoid
        %x_max denotes the x coordinate of the end of longer side in the trapezoid
        %y_max denotes the y coordinate of the longer side in the trapezoid
        x_min = size(im_og,1);
        y_min = size(im_og,2);
        x_max = 0;
        y_max = 0;
        
        for card_counter = 1: length(onlyCards)
            dim = onlyCards(card_counter).BoundingBox;            
            x_min = min([floor(dim(1)), x_min, floor(dim(1)+dim(3))]);
            x_max = max([floor(dim(1)), x_max, floor(dim(1)+dim(3))]);
            y_min = min([floor(dim(2)), y_min, floor(dim(2)+dim(4))]);
            y_max = max([floor(dim(2)), y_max, floor(dim(2)+dim(4))]);
        end
        
        %drawing a rectangle on the basis of trapezoid coordinates found till now-
        %we do not have the x coordinates for the shorter side yet
        im_output = insertShape(im_output,'rectangle',[x_min, y_min, x_max-x_min, y_max-y_min], 'Color','red','LineWidth',10);
%         imshow(im_output);
        
        %Finding x coordinates for the shorter side.
        small_x_min = size(im_og,1);
        small_x_max = 0;
        for card_counter = 1: length(onlyCards)
            dim = onlyCards(card_counter).BoundingBox;
            
            if (dim(2) > y_min-300 && dim(2) < y_min+300)
                small_x_min = floor(min([small_x_min, dim(1)]));
                small_x_max = floor(max([small_x_max, dim(1)+dim(4)]));
            end
        end
        
        %First row denotes the x points of the trapezoid
        %Second row denotes the corresponding y points of the trapezoid
        input_points = [small_x_min x_min x_max small_x_max
                        y_min y_max y_max y_min];
        
        %First row denotes the x points of the expected rectangle
        %Second row denotes the corresponding y points of the rectangle
        output_points = [small_x_min small_x_min small_x_max small_x_max;
                        y_min y_max y_max y_min];
        
        %Transforming points based on Matlab's convention.
        %X values in the first column and Y values in the second column
        input_points_t = [input_points(1,:).', input_points(2,:).'];
        output_points_t = [output_points(1,:).', output_points(2,:).'];
        
        %Projective transformation is used when the scene appears tilted.
        %Returns the geometric transformation which is to be applied to get
        %the rectangular image.
        t_cards = fitgeotrans(input_points_t, output_points_t, 'projective');
        
        %Applying geometric transformation to the image - Moving all pixels
        %into a new image
        im_rectified = imwarp(im_og, t_cards, 'OutputView', imref2d(size(im_og)));
        
%         figure, imagesc(im_rectified);
        
        %Since y points make up the rows
        im_cropped = im_rectified(y_min:y_max, small_x_min:small_x_max, :);
        figure();
        imshow(im_cropped);
        
    end
    
end

%This function checks if the current shape's color is red
function bool = check_for_red(im_card, x_value, y_value)

bool = false;
    for col = x_value : size( im_card, 2 )
        for row = y_value : size( im_card, 1 )
            
            red_value = im_card(row,col,1);
            green_value = im_card(row,col,2);
            blue_value = im_card(row,col,3);
            
            %Threshold for red pixel value
            if red_value > 200 && green_value < 200 && blue_value < 150
               bool = true;
               break;
            end
        end
        if bool == true
            break;
        end
    end
    
end
