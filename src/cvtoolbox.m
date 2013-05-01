function varargout = cvtoolbox(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cvtoolbox_OpeningFcn, ...
                   'gui_OutputFcn',  @cvtoolbox_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


function cvtoolbox_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    % Modes:
    % 1 - Image
    % 2 - Images from folder
    % 3 - Video
    % 4 - Webcam
    handles.mode = 1;
    % filters
    handles.filters.saltpepper.status = 0;
    handles.filters.saltpepper.d = 0.01;
    
    handles.filters.blur.status = 0;
    handles.filters.blur.len = 1;
    handles.filters.blur.theta = 1;
    
    handles.filters.dilate.status = 0;
    handles.filters.dilate.height = 1;
    handles.filters.dilate.radius = 1;
    handles.filters.dilate.n = 2;
    
    handles.filters.erode.status = 0;
    handles.filters.erode.height = 1;
    handles.filters.erode.radius = 1;
    handles.filters.erode.n = 2;
    
    handles.filters.histogram.status = 0;
    handles.filters.equalization.status = 0;
    
    handles.filters.sobel.status = 0;
    handles.filters.sobel.threshold = 0.0;
    handles.filters.sobel.direction = 'both';
    
    handles.filters.laplacian.status = 0;
    handles.filters.laplacian.threshold = 0.0;
    handles.filters.laplacian.sigma = 1.0;
    
    handles.filters.canny.status = 0;
    handles.filters.canny.threshold = 0.0;
    handles.filters.canny.sigma = 1.0;
    
    handles.filters.colorspace.status = 0;
    handles.filters.colorspace.value = 1;
    
    handles.filters.open.status = 0;
    handles.filters.open.height = 1;
    handles.filters.open.radius = 1;
    handles.filters.open.n = 2;
    
    handles.filters.close.status = 0;
    handles.filters.close.height = 1;
    handles.filters.close.radius = 1;
    handles.filters.close.n = 2;
    
    handles.filters.hough.status = 0;
    handles.filters.hough.value = 1;
    handles.filters.hough.min_radius = 1;
    handles.filters.hough.max_radius = 11;
    
    handles.filters.contours.status = 0;
    handles.filters.contours.levels = 1.0;
    
    handles.filters.harris.status = 0;
    
    handles.filters.surf.status = 0;
    handles.filters.surf.points = 1;
    
    handles.filters.fast.status = 0;
    
    handles.filters.sharp.status = 0;
    handles.filters.sharp.kernel = 1;
    
    handles.filters.logo.status = 0;
    handles.filters.logo.image = [];
    handles.filters.logo.mask = [];
    handles.filters.logo.position = [];

    handles.filters.bounding.status = 0;
    
    handles.video.vObj = [];
    handles.video.nFrames = 1;
    
    handles.cam.obj = 0;
    handles.cam.playing = 0;
    
    guidata(hObject, handles);


function varargout = cvtoolbox_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

    
function playCam(hObject, eventdata, handles)
    while (handles.cam.playing == 1)
        handles = guidata(hObject);
        handles.image = getsnapshot(handles.cam.obj);
        guidata(hObject, handles);
        processImage(hObject, eventdata, handles);
    end
    
    
function playVideo(hObject, eventdata, handles)
    while ~isDone(handles.vid)
        handles.image = step(handles.vid);
        guidata(hObject, handles);
        processImage(hObject, eventdata, handles);
    end

    
function playBtn_Callback(hObject, eventdata, handles)
    set(findobj('tag', 'filtersTable'), 'ColumnEditable', [true false]);
    if (handles.mode == 3)
        handles.vid = vision.VideoFileReader(handles.video_path);
        guidata(hObject, handles);
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        if (handles.cam.playing == 1)
            handles.cam.playing = 0;
            imaqreset;
            set(findobj('tag', 'playBtn'), 'string', '>');
            set(findobj('tag', 'filtersTable'), 'ColumnEditable', [false false]);
        else
            handles.cam.playing = 1;
            set(findobj('tag', 'playBtn'), 'string', '||');
        end
        guidata(hObject, handles);
        playCam(hObject, eventdata, handles);
    end


function forwardBtn_Callback(hObject, eventdata, handles)
    if (handles.mode == 2)
        % we are watching a folder
        % enable the backward button
        set(findobj('tag', 'backwardBtn'), 'Enable', 'on');
        handles.current_image = handles.current_image + 1;
        if (handles.current_image == length(handles.files_list))
            % disable the forward button
            set(findobj('tag', 'forwardBtn'), 'Enable', 'off');
        end
        guidata(hObject, handles);
        % load the next image
        loadImage(hObject, eventdata, handles)
    elseif (handles.mode == 3)
        % watching a video
    elseif (handles.mode == 4)
        % from webcam
    end

    
function loadImage(hObject, eventdata, handles)
    handles.image = imread([handles.folder_name '/' handles.files_list(handles.current_image).name]);
    
    obj = findobj('tag', 'inputFrame');
    imshow(handles.image, 'parent', obj);
    set(obj, 'tag', 'inputFrame');
    
    guidata(hObject, handles);
    processImage(hObject, eventdata, handles);
    

function processImage(hObject, eventdata, handles)    
    if (handles.mode == 3)
        inputImage = double(handles.image);
        handles.outputImage = double(handles.image);
    else
        inputImage = handles.image;
        handles.outputImage = handles.image;
    end
    
    if (handles.filters.logo.status == 1)
        if (~isempty(handles.filters.logo.image) && ...
                ~isempty(handles.filters.logo.mask))
            % resize
            pos = floor(handles.filters.logo.position);
            im3 = imresize(handles.filters.logo.image, [pos(4) pos(3)]);
            mask = uint8(handles.filters.logo.mask);
            % combine mask and resized image
            try
                mask(pos(2):pos(2)+pos(4)-1, pos(1):pos(1)+pos(3)-1) = mask(pos(2):pos(2)+pos(4)-1, pos(1):pos(1)+pos(3)-1).*im3;
            catch err
                mask(pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3)) = mask(pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3)).*im3;
            end
            try
                inputImage = rgb2gray(inputImage);
                handles.outputImage = rgb2gray(handles.outputImage);
            catch err
            end

            % add new mask and input and output
            mask = imresize(mask, size(inputImage));
            handles.outputImage = imadd(im2double(handles.outputImage), im2double(mask));
            inputImage = imadd(im2double(inputImage), im2double(mask));
            
        end
    end
    
    % show also in input image
    imshow(inputImage, 'Parent', handles.inputFrame);
    
    if (handles.filters.colorspace.status == 1)
        switch handles.filters.colorspace.value
            case 1
                % RGB
                try
                    handles.outputImage = inputImage;
                catch err
                    % nothing
                end
            case 2
                % HSV
                try
                    handles.outputImage = rgb2hsv(inputImage);
                catch err
                    % nothing
                end
            case 3
                % Lab
                try 
                    C = makecform('srgb2lab');
                    handles.outputImage = applycform(inputImage, C);
                catch err
                    % nothing
                end
            case 4
                % Ntsc
                try 
                    handles.outputImage = rgb2ntsc(inputImage);
                catch err
                    %nothing
                end
            case 5
                %ycbcr
                try
                    handles.outputImage = rgb2ycbcr(inputImage);
                catch err
                    % nothing
                end
        end
    else
        try
            handles.outputImage = rgb2gray(inputImage);
        catch err
            handles.outputImage = inputImage;
        end
    end
    
    
    if (handles.filters.saltpepper.status == 1)
        handles.outputImage = imnoise(handles.outputImage,'salt & pepper', handles.filters.saltpepper.d);
    end
    
    if (handles.filters.blur.status == 1)
        PSF = fspecial('motion', handles.filters.blur.len, handles.filters.blur.theta);
        handles.outputImage = imfilter(handles.outputImage, PSF, 'conv', 'circular');
    end
    
    if (handles.filters.dilate.status == 1)
        se = strel('ball',  double(ceil(handles.filters.dilate.radius)), ...
                        double(handles.filters.dilate.height), ...
                        double(ceil(handles.filters.dilate.n)));
        
        handles.outputImage = imdilate(im2uint8(handles.outputImage), se);
    end
    
    if (handles.filters.erode.status == 1)
        se = strel('ball',  double(ceil(handles.filters.erode.radius)), ...
                        double(handles.filters.erode.height), ...
                        double(ceil(handles.filters.erode.n)));
                    
        handles.outputImage = imerode(im2uint8(handles.outputImage), se);
    end
    
    if (handles.filters.sobel.status == 1)
        handles.outputImage = edge(handles.outputImage, 'sobel', ... 
                                handles.filters.sobel.threshold, ...
                                handles.filters.sobel.direction);
    end
    
    if (handles.filters.laplacian.status == 1)
        handles.outputImage = edge(handles.outputImage, 'log', ... 
                                handles.filters.laplacian.threshold, ...
                                handles.filters.laplacian.sigma);
    end
    
    if (handles.filters.canny.status == 1)
        handles.outputImage = edge(handles.outputImage, 'canny', ... 
                                handles.filters.canny.threshold, ...
                                handles.filters.canny.sigma);
    end
    
    if (handles.filters.open.status == 1)
        se = strel('ball',  double(ceil(handles.filters.open.radius)), ...
                        double(handles.filters.open.height), ...
                        double(ceil(handles.filters.open.n)));
                    
        handles.outputImage = imopen(handles.outputImage, se);
    end
    
    if (handles.filters.close.status == 1)
        se = strel('ball',  double(ceil(handles.filters.close.radius)), ...
                        double(handles.filters.close.height), ...
                        double(ceil(handles.filters.close.n)));
                    
        handles.outputImage = imclose(handles.outputImage, se);
    end
    
    if (handles.filters.fast.status == 1)
        hcornerdet = vision.CornerDetector('Method','Local intensity comparison (Rosten & Drummond)');
        handles.outputImage = im2single(handles.outputImage);
        pts = step(hcornerdet, handles.outputImage);

        % Note that the color data range must match the data range of the input image I
        color = [1 0 0]; % [red, green, blue]
        hdrawmarkers = vision.MarkerInserter('Shape', 'Circle', 'BorderColor', 'Custom', 'CustomBorderColor', color);

        % Convert the grayscale input image I to an RGB image J before inserting the marker
        handles.outputImage = repmat(handles.outputImage,[1 1 3]);
        handles.outputImage = step(hdrawmarkers, handles.outputImage, pts); % draw directly in the image
    end
    
    if (handles.filters.sharp.status == 1)
        kernel = 'unsharp';
        switch handles.filters.sharp.kernel
            case 1
                kernel = 'laplacian';
            case 2
                kernel = 'gaussian';
            case 3
                kernel = 'log';
            case 4
                kernel = 'unsharp';
        end
        
        h = fspecial(kernel);
        handles.outputImage = imfilter(handles.outputImage, h, 'replicate');
    end
    

    % Ploting the result ###==============================##
    
    obj = handles.outputFrame;
    axes(obj);
    imshow(handles.outputImage, 'parent', obj); 
    
    % ######################################################
    
    if (handles.filters.contours.status == 1)
        % find contours
        handles.outputImage = imcontour(handles.outputImage, ceil(handles.filters.contours.levels));
        set(obj, 'XTick', []);
        set(obj, 'YTick', []);
    end
    hold on;
    
    if (handles.filters.harris.status == 1)
        C = corner(handles.outputImage);
        plot(C(:,1), C(:,2), 'r*');
    end
    
    if (handles.filters.surf.status == 1)
        try
            points = detectSURFFeatures(handles.outputImage);
            [features, valid_points] = extractFeatures(handles.outputImage, points);

            % Plot the ten strongest SURF features
            plot(valid_points.selectStrongest(ceil(handles.filters.surf.points)),'showOrientation',true);
        catch err
            % nothing
        end
    end
    
    if (handles.filters.bounding.status == 1)
        out = im2bw(handles.outputImage);
        out = imfill(out, 'holes');
        S = regionprops(logical(out), 'BoundingBox');
        
        arrayfun(@(x) rectangle('Position', S(x).BoundingBox, 'EdgeColor', 'green'), 1:length(S))
    end
    
    if (handles.filters.hough.status == 1)
        if (handles.filters.hough.value == 1)            
            BW = edge(handles.outputImage, 'canny');
            [H,theta,rho] = hough(BW);
            P = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
            lines = houghlines(BW,theta,rho,P,'FillGap',5,'MinLength',7);

            max_len = 0;
            for k = 1:length(lines)
                xy = [lines(k).point1; lines(k).point2];
                plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

                % Plot beginnings and ends of lines
                plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
                plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

                % Determine the endpoints of the longest line segment
                len = norm(lines(k).point1 - lines(k).point2);
                if ( len > max_len)
                    max_len = len;
                    xy_long = xy;
                end
            end

            % highlight the longest line segment
            plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');
        elseif (handles.filters.hough.value == 2)
            try
                [centers, radii, metric] = imfindcircles(handles.outputImage,[handles.filters.hough.min_radius handles.filters.hough.max_radius]);
                viscircles(centers, radii,'EdgeColor','b');
            catch err
                % do nothing
            end
        end
    end
    hold off;
    
    
    % ####################################################################
    % Histogram
    
    axes(handles.histogramFrame);
    if (handles.filters.histogram.status == 1 && handles.filters.equalization.status ~= 1)
        imhist(handles.outputImage);
    elseif(handles.filters.equalization.status == 1)
        % Histogram Equalization
        imhist(histeq(uint8(handles.outputImage)));
    else
        cla;
    end

    % ####################################################################
    
    guidata(hObject, handles);
        

function backwardBtn_Callback(hObject, eventdata, handles)
    handles.filters.logo.applied = false;
    
    if (handles.mode == 2)
        % we are watching a folder
        % enable the forward button
        set(findobj('tag', 'forwardBtn'), 'Enable', 'on');
        handles.current_image = handles.current_image - 1;
        if (handles.current_image == 1)
            % disable the forward button
            set(findobj('tag', 'backwardBtn'), 'Enable', 'off');
        end
        guidata(hObject, handles);
        % load the next image
        loadImage(hObject, eventdata, handles)
    elseif (handles.mode == 3)
        % watching a video
    elseif (handles.mode == 4)
        % from the webcam
    end


function filtersTable_CreateFcn(hObject, eventdata, handles)
     data = {false, 'Salt and Pepper Noise'; ...
        false, 'Show logo'; ...
        false, 'Convert to Colorspace'; ...
        false, 'Compute Histogram'; ...
        false, 'Equalize Histogram'; ...
        false, 'Dilate';...
        false, 'Erode'; ...
        false, 'Open (Morphological Op.)'; ...
        false, 'Close (Morphological Op.)'; ...
        false, 'Blur'; ...
        false, 'Sobel Operator'; ...
        false, 'Laplacian Operator'; ...
        false, 'Sharp by Kernel'; ...
        false, 'Edge Detection (Canny)'; ...
        false, 'Extract lines and Circles (Hough)'; ...
        false, 'Find Countours'; ...
        false, 'Apply Bounding Box'; ...
%         false, 'Apply minimum enclosing circle'; ...
        false, 'Extract Corners (Harris)'; ...
        false, 'Extract FAST'; ...
        false, 'Extract SURF'; ...
%         false, 'Extract SIFT'; ...
        };
    set(hObject, 'Data', data);
    set(hObject, 'ColumnEditable', [false false]);


function filtersTable_CellSelectionCallback(hObject, eventdata, handles)
    cell = eventdata.Indices;
    
    % hide all the frames
    frames = {'saltPepperFrame', 'blurFrame', 'dilateFrame', 'erodeFrame', ...
            'sobelFrame', 'laplacianFrame', 'cannyFrame', 'colorspaceFrame',...  
            'openFrame', 'closeFrame', 'houghFrame', 'contoursFrame' ...
            'surfFrame', 'sharpFrame', 'logoFrame'};
        
    arrayfun(@(x) set(findobj('tag', cell2mat(frames(x))), 'Visible', 'off'), 1:length(frames));
    
    % show the config parameters for the selected filter
    switch cell(1)
        case 1
            % Salt and Pepper Noise
            set(findobj('tag', 'saltPepperFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'saltPepperFrame'), 'Position', [0, 3, 50, 10]);
            set(findobj('tag', 'saltPepperFrame'), 'Visible', 'on');
        case 2
            % Show logo
            set(findobj('tag', 'logoFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'logoFrame'), 'Position', [0, 2, 50, 10]);
            set(findobj('tag', 'logoFrame'), 'Visible', 'on');
        case 3
            % Convert to Colorspace
            set(findobj('tag', 'colorspaceFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'colorspaceFrame'), 'Position', [0, 3, 50, 10]);
            set(findobj('tag', 'colorspaceFrame'), 'Visible', 'on');
        case 4
            % Compute Histogram
            
        case 5
            % Equalize Histogram
        case 6
            % Dilate
            set(findobj('tag', 'dilateFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'dilateFrame'), 'Position', [0, 2, 10, 10]);
            set(findobj('tag', 'dilateFrame'), 'Visible', 'on');
        case 7
            % Erode
            set(findobj('tag', 'erodeFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'erodeFrame'), 'Position', [0, 2, 50, 10]);
            set(findobj('tag', 'erodeFrame'), 'Visible', 'on');
        case 8
            % Open (Morphological Op.)
            set(findobj('tag', 'openFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'openFrame'), 'Position', [0, 2, 10, 10]);
            set(findobj('tag', 'openFrame'), 'Visible', 'on');
        case 9
            % Close (Morphological Op.)
            set(findobj('tag', 'closeFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'closeFrame'), 'Position', [0, 2, 10, 10]);
            set(findobj('tag', 'closeFrame'), 'Visible', 'on');
        case 10
            % Blur
            set(findobj('tag', 'blurFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'blurFrame'), 'Position', [0, 2, 50, 10]);
            set(findobj('tag', 'blurFrame'), 'Visible', 'on');
        case 11
            % Sobel Operator
            set(findobj('tag', 'sobelFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'sobelFrame'), 'Position', [0, 2, 50, 10]);
            set(findobj('tag', 'sobelFrame'), 'Visible', 'on');
        case 12
            % Laplacian Operator
            set(findobj('tag', 'laplacianFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'laplacianFrame'), 'Position', [0, 2, 50, 10]);
            set(findobj('tag', 'laplacianFrame'), 'Visible', 'on');
        case 13
            % Sharp by Kernel
            set(findobj('tag', 'sharpFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'sharpFrame'), 'Position', [0, 3, 50, 10]);
            set(findobj('tag', 'sharpFrame'), 'Visible', 'on');
        case 14
            % Edge Detection (Canny)
            set(findobj('tag', 'cannyFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'cannyFrame'), 'Position', [0, 2, 50, 10]);
            set(findobj('tag', 'cannyFrame'), 'Visible', 'on');
        case 15
            % Extract lines and Circles (Hough)
            set(findobj('tag', 'houghFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'houghFrame'), 'Position', [0, 3, 50, 10]);
            set(findobj('tag', 'houghFrame'), 'Visible', 'on');
        case 16
            % Find Countours
            set(findobj('tag', 'contoursFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'contoursFrame'), 'Position', [0, 3, 50, 10]);
            set(findobj('tag', 'contoursFrame'), 'Visible', 'on');
        case 17
            % Apply Bounding Box
%         case 18
%             % Apply minimum enclosing circle
        case 18
            % Extract Corners (Harris)
        case 19
            % Extract FAST
        case 20
            % Extract SURF
            set(findobj('tag', 'surfFrame'), 'Parent', findobj('tag', 'configPanel'));
            set(findobj('tag', 'surfFrame'), 'Position', [0, 3, 50, 10]);
            set(findobj('tag', 'surfFrame'), 'Visible', 'on');
%         case 22
            % Extract SIFT
    end


function loadFolderAction_Callback(hObject, eventdata, handles)
    handles.mode = 2; % images from folder
    handles.folder_name = uigetdir; % getting the dir name
    
    if (handles.folder_name == 0), return; end;
    
    handles.current_image = 1;
    handles.files_list = dir([handles.folder_name]);
    
    % filtering images (no directories)
    f = imformats();
    isImg = @(y) sum(arrayfun(@(x) f(x).isa(y), 1:length(f)));
    list = logical(cellfun(@(x) isImg([handles.folder_name '/' x]), {handles.files_list(:).name}));
    handles.files_list = handles.files_list(list);
   
    % updating data
    guidata(hObject, handles);
    if (length(handles.files_list) > 0)
        % show current image
        loadImage(hObject, eventdata, handles);
        % enable filters checkboxes
        set(findobj('tag', 'filtersTable'), 'ColumnEditable', [true false]);
        
        if (length(handles.files_list) > 1)
            set(findobj('tag', 'forwardBtn'), 'Enable', 'on');
        end
    end
    

function loadImageAction_Callback(hObject, eventdata, handles)
    handles.filters.logo.applied = false;
    
    handles.mode = 1; % Image Mode
    [imgFile, canceled] = imgetfile;
    if (canceled), return; end;
    % Make sure the file is an image
    handles.image_file = imgFile;
    handles.image = imread(handles.image_file);
    
    obj = findobj('tag', 'inputFrame');
    imshow(handles.image, 'parent', obj);
    set(obj, 'tag', 'inputFrame');
    
    obj = findobj('tag', 'outputFrame');
    imshow(handles.image, 'parent', obj);
    set(obj, 'tag', 'outputFrame');
    
    % disable the buttons
    set(findobj('tag', 'backwardBtn'), 'Enable', 'off');
    set(findobj('tag', 'playBtn'), 'Enable', 'off');
    set(findobj('tag', 'forwardBtn'), 'Enable', 'off');
    % enable checkboxes
    set(findobj('tag', 'filtersTable'), 'ColumnEditable', [true false]);
    guidata(hObject, handles);
    processImage(hObject, eventdata, handles);
    

function loadVideoAction_Callback(hObject, eventdata, handles)
    [file, path] = uigetfile('*');
    handles.mode = 3;
    handles.video_path = [path '/' file];

    % set the correct string to the play btn
    set(findobj('tag', 'playBtn'), 'String', '>');
    % activate the play button
    set(findobj('tag', 'playBtn'), 'Enable', 'on');
    
    % check if the webcam is playing
    if (handles.cam.playing == 1)
        handles.cam.playing = 0;
    end
    
    guidata(hObject, handles);
    

function connectCameraAction_Callback(hObject, eventdata, handles)
    handles.mode = 4; % webcam mode
    % set the correct string to the play btn and activate it
    set(findobj('tag', 'playBtn'), 'String', '>', 'Enable', 'on');
    
    try
        if (~isDone(handles.vid))
            release(handles.vid);
        end
    catch err
    end
    
    handles.cam.obj = videoinput('linuxvideo');
    set(handles.cam.obj, 'framesperTrigger', 1);
    set(handles.cam.obj, 'TriggerRepeat', Inf);
    set(handles.cam.obj, 'ReturnedColorSpace', 'rgb');
    
    guidata(hObject, handles);
    

function saveAsAction_Callback(hObject, eventdata, handles)
    try
        [name, path] = uiputfile( ... 
            {'.jpeg', 'JPEG Image (.jpeg)'}, ...
            'Save file as ...', ... 
            'new_file');

        imwrite(handles.outputImage, [path '/' name], 'jpeg');
        
    catch err
    end

    
function exitAction_Callback(hObject, eventdata, handles)


function toolMenu_Callback(hObject, eventdata, handles)


function stereoModuleAction_Callback(hObject, eventdata, handles)
    % Call the stereo module
    stereo

    
function filtersTable_CellEditCallback(hObject, eventdata, handles)
    cell = eventdata.Indices;
    activated = eventdata.NewData;
    
    % show the config parameters for the selected filter
    switch cell(1)
        case 1
            % Salt and Pepper Noise
            handles.filters.saltpepper.status = activated;
        case 2
            % Show logo
            handles.filters.logo.status = activated;
        case 3
            % Convert to Colorspace
            handles.filters.colorspace.status = activated;
        case 4
            % Compute Histogram
            handles.filters.histogram.status = activated;
        case 5
            % Equalize Histogram
            handles.filters.equalization.status = activated;
        case 6
            % Dilate
            handles.filters.dilate.status = activated;
        case 7
            % Erode
            handles.filters.erode.status = activated;
        case 8
            % Open (Morphological Op.)
            handles.filters.open.status = activated;
        case 9
            % Close (Morphological Op.)
            handles.filters.close.status = activated;
        case 10
            % Blur
            handles.filters.blur.status = activated;
        case 11
            % Sobel Operator
            handles.filters.sobel.status = activated;
        case 12
            % Laplacian Operator
            handles.filters.laplacian.status = activated;
        case 13
            % Sharp by Kernel
            handles.filters.sharp.status = activated;
        case 14
            % Edge Detection (Canny)
            handles.filters.canny.status = activated;
        case 15
            % Extract lines and Circles (Hough)
            handles.filters.hough.status = activated;
        case 16
            % Find Countours
            handles.filters.contours.status = activated;
        case 17
            % Apply Bounding Box
            handles.filters.bounding.status = activated;
%         case 18
%             % Apply minimum enclosing circle
        case 18
            % Extract Corners (Harris)
            handles.filters.harris.status = activated;
        case 19
            % Extract FAST
            handles.filters.fast.status = activated;
        case 20
            % Extract SURF
            handles.filters.surf.status = activated;
%         case 22
%             % Extract SIFT
    end
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end
    

function saltPepperSlider_Callback(hObject, eventdata, handles)
    handles.filters.saltpepper.d = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function saltPepperSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    set(hObject, 'Value', 0.01);


function blurLenSlider_Callback(hObject, eventdata, handles)
    handles.filters.blur.len = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function blurLenSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function blurThetaSlider_Callback(hObject, eventdata, handles)
    handles.filters.blur.theta = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function blurThetaSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function dilateHeightSlider_Callback(hObject, eventdata, handles)
    handles.filters.dilate.height = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function dilateHeightSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function dilateRadiusSlider_Callback(hObject, eventdata, handles)
    handles.filters.dilate.radius = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function dilateRadiusSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function erodeRadiusSlider_Callback(hObject, eventdata, handles)
    handles.filters.erode.radius = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function erodeRadiusSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function erodeHeightSlider_Callback(hObject, eventdata, handles)
    handles.filters.erode.height = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function erodeHeightSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function sobelThresholdSlider_Callback(hObject, eventdata, handles)
    handles.filters.sobel.threshold = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function sobelThresholdSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function sobelDirectionMenu_Callback(hObject, eventdata, handles)
    contents = cellstr(get(hObject, 'String'));
    handles.filters.sobel.direction = contents{get(hObject, 'Value')};
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end
    

function sobelDirectionMenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function laplacianSigmaSlider_Callback(hObject, eventdata, handles)
    handles.filters.laplacian.sigma = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function laplacianSigmaSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBakgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function laplacianThresholdSlider_Callback(hObject, eventdata, handles)
    handles.filters.laplacian.threshold = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function laplacianThresholdSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function cannyThresholdSlider_Callback(hObject, eventdata, handles)
    handles.filters.canny.threshold = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function cannyThresholdSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function cannySigmaSlider_Callback(hObject, eventdata, handles)
    handles.filters.canny.sigma = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function cannySigmaSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function colorspaceMenu_Callback(hObject, eventdata, handles)
    handles.filters.colorspace.value = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function colorspaceMenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function openRadiusSlider_Callback(hObject, eventdata, handles)
    handles.filters.open.radius = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function openRadiusSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function openHeightSlider_Callback(hObject, eventdata, handles)
    handles.filters.open.height = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function openHeightSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function closeHeightSlider_Callback(hObject, eventdata, handles)
    handles.filters.close.height = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end
    

function closeHeightSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

    
function closeRadiusSlider_Callback(hObject, eventdata, handles)
    handles.filters.close.radius = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function closeRadiusSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function houghMenu_Callback(hObject, eventdata, handles)
    handles.filters.hough.value = get(hObject, 'Value');
    if (handles.filters.hough.value == 2)
        % show the stuff
        set(findobj('tag', 'minRadiusText'), 'visible', 'on');
        set(findobj('tag', 'maxRadiusText'), 'visible', 'on');
        set(findobj('tag', 'minRadiusHoughMenu'), 'visible', 'on');
        set(findobj('tag', 'maxRadiusHoughMenu'), 'visible', 'on');
    else
        % hide the stuff
        set(findobj('tag', 'minRadiusText'), 'visible', 'off');
        set(findobj('tag', 'maxRadiusText'), 'visible', 'off');
        set(findobj('tag', 'minRadiusHoughMenu'), 'visible', 'off');
        set(findobj('tag', 'maxRadiusHoughMenu'), 'visible', 'off');
    end
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end
    
    
function houghMenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function minRadiusHoughMenu_Callback(hObject, eventdata, handles)
    handles.filters.hough.min_radius = get(hObject, 'value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end

    
function minRadiusHoughMenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function maxRadiusHoughMenu_Callback(hObject, eventdata, handles)
    handles.filters.hough.max_radius = (get(hObject, 'value') + 10);
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end

    
function maxRadiusHoughMenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


function contourLevelSlider_Callback(hObject, eventdata, handles)
    handles.filters.contours.levels = get(hObject, 'Value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end  


function contourLevelSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

    
function surfPointsSlider_Callback(hObject, eventdata, handles)
    handles.filters.surf.points = get(hObject, 'value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function surfPointsSlider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function sharpKernelMenu_Callback(hObject, eventdata, handles)
    handles.filters.sharp.kernel = get(hObject, 'value');
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end


function sharpKernelMenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

    
function logoFileBtn_Callback(hObject, eventdata, handles)
    [imgFile, canceled] = imgetfile;
    if (~canceled)
        handles.filters.logo.image = imread(imgFile);
        try
            handles.filters.logo.image = rgb2gray(handles.filters.logo.image);
        catch err
        end
%         resetLogoStuff(hObject, eventdata, handles);
    end
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end

    
function logoSelectROIBtn_Callback(hObject, eventdata, handles)
%     resetLogoStuff(hObject, eventdata, handles);
    h = imrect(findobj('tag', 'inputFrame'));
    handles.filters.logo.mask = h.createMask();
    handles.filters.logo.position = h.getPosition();
    h.delete();
    guidata(hObject, handles);
    if (handles.mode == 3)
        playVideo(hObject, eventdata, handles);
    elseif (handles.mode == 4)
        playCam(hObject, eventdata, handles);
    else
        processImage(hObject, eventdata, handles);
    end
