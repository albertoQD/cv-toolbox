function varargout = stereo(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @stereo_OpeningFcn, ...
                       'gui_OutputFcn',  @stereo_OutputFcn, ...
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


% --- Executes just before stereo is made visible.
function stereo_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;

    handles.leftImage = [];
    handles.rightImage = [];
    
    % Update handles structure
    guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = stereo_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;


% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function toolsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to toolsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function fundamentalMatrixAction_Callback(hObject, eventdata, handles)
    if (isempty(handles.leftImage) || isempty(handles.rightImage)), return; end;
    
    left = handles.leftImage;
    right = handles.rightImage;
    try
        left = rgb2gray(left);
        right = rgb2gray(right);
    catch err
    end
    
    % extract features 
    points1 = detectSURFFeatures(left);
    points2 = detectSURFFeatures(right); 
    
    % Extract the features.

    [f1, vpts1] = extractFeatures(left, points1);
    [f2, vpts2] = extractFeatures(right, points2);
    
    indexPairs = matchFeatures(f1, f2) ;
    matched_pts1 = vpts1(indexPairs(:, 1));handles.fundamental
    matched_pts2 = vpts2(indexPairs(:, 2));
    
    a1 = []; a2 = [];
    for i = 1:length(matched_pts1)
        a1 = [a1; matched_pts1(i).Location];
    end
    
    for i = 1:length(matched_pts2)
        a2 = [a2; matched_pts2(i).Location];
    end
    
    % fundamental matrix
    fmatrix = estimateFundamentalMatrix(a1, a2, 'NumTrials', 4000, 'Method', 'Norm8Point');
    disp('Fundamental Matrix: ');
    disp(fmatrix);


% --------------------------------------------------------------------
function homographyMatrixAction_Callback(hObject, eventdata, handles)
    if (isempty(handles.leftImage) || isempty(handles.rightImage)), return; end;
    
    left = handles.leftImage;
    right = handles.rightImage;
    try
        left = rgb2gray(left);
        right = rgb2gray(right);
    catch err
    end
    
    % extract features 
    points1 = detectSURFFeatures(left);
    points2 = detectSURFFeatures(right); 
    
    % Extract the features.

    [f1, vpts1] = extractFeatures(left, points1);
    [f2, vpts2] = extractFeatures(right, points2);
    
    indexPairs = matchFeatures(f1, f2);
    matched_pts1 = vpts1(indexPairs(:, 1));
    matched_pts2 = vpts2(indexPairs(:, 2));
    
    gte = vision.GeometricTransformEstimator;
    gte.Transform = 'Projective';
    [tform inlierIdx] = step(gte, matched_pts2.Location, matched_pts1.Location);
    disp('Homography Matrix:');
    disp(tform);

% --------------------------------------------------------------------
function findMatchesAction_Callback(hObject, eventdata, handles)
    if (isempty(handles.leftImage) || isempty(handles.rightImage)), return; end;
    
    left = handles.leftImage;
    right = handles.rightImage;
    try
        left = rgb2gray(left);
        right = rgb2gray(right);
    catch err
    end
    
    % extract features 
    points1 = detectSURFFeatures(left);
    points2 = detectSURFFeatures(right); 
    
    % Extract the features.

    [f1, vpts1] = extractFeatures(left, points1);
    [f2, vpts2] = extractFeatures(right, points2);
    
    indexPairs = matchFeatures(f1, f2) ;
    matched_pts1 = vpts1(indexPairs(:, 1));
    matched_pts2 = vpts2(indexPairs(:, 2));
    
    axes(handles.axes3);
    cvexShowMatches(left,right,matched_pts1,matched_pts2);
%     
%     a1 = []; a2 = [];
%     for i = 1:length(matched_pts1)
%         a1 = [a1; matched_pts1(i).Location];
%     end
%     
%     for i = 1:length(matched_pts2)
%         a2 = [a2; matched_pts2(i).Location];
%     end
%     
%     % plot the left image
%     obj = findobj('tag', 'leftImage');
%     axes(findobj('tag', 'leftImage'));
%     imshow(handles.leftImage); hold on;
%     % plot the points in left
%     scatter(a1(:,1),a1(:,2));
%     hold off;
%     set(obj, 'tag', 'leftImage');
%     
%     % plot the right image
%     obj = findobj('tag', 'rightImage');
%     axes(findobj('tag', 'rightImage'));
%     imshow(handles.rightImage); hold on;
%     scatter(a2(:,1),a2(:,2));
% %     [xa2 ya2] = ds2nfu(a2(:,1),a1(:,2));
%     hold off;
%     set(obj, 'tag', 'rightImage');
    


% --------------------------------------------------------------------
function generateMosaicAction_Callback(hObject, eventdata, handles)

    if (isempty(handles.leftImage) || isempty(handles.rightImage)), return; end;
    
    left = handles.leftImage;
    right = handles.rightImage;
    try
        left = rgb2gray(left);
        right = rgb2gray(right);
    catch err
    end
    
    % extract features 
    points1 = detectSURFFeatures(left);
    points2 = detectSURFFeatures(right); 
    
    % Extract the features.

    [f1, vpts1] = extractFeatures(left, points1);
    [f2, vpts2] = extractFeatures(right, points2);
    
    indexPairs = matchFeatures(f1, f2);
    matched_pts1 = vpts1(indexPairs(:, 1));
    matched_pts2 = vpts2(indexPairs(:, 2));
    
    gte = vision.GeometricTransformEstimator;
    gte.Transform = 'Projective';
    [tform inlierIdx] = step(gte, matched_pts2.Location, matched_pts1.Location);
    disp('Homography Matrix:');
    disp(tform);
    
    % mosaicing
%     nright = imtransform(right,maketform('projective', double(tform))); % opcion 1
    
    agt = vision.GeometricTransformer('OutputImagePositionSource', 'Property');
    nright = step(agt, im2single(right), tform);
    halphablend = vision.AlphaBlender;
    mosaic =  step(halphablend, uint8(left), uint8(nright));
    figure; imshow(nright); title('Recovered image');



% --------------------------------------------------------------------
function leftImageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to leftImageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function rightImageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to rightImageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function saveAsAction_Callback(hObject, eventdata, handles)
% hObject    handle to saveAsAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function rightFromFileAction_Callback(hObject, eventdata, handles)
    [img, canceled] = imgetfile;
    if (canceled), return; end;
    handles.fundamental = [];
    handles.rightImage = imread(img);
    
    obj = findobj('tag', 'rightImage');
    imshow(handles.rightImage, 'parent', obj);
    set(obj, 'tag', 'rightImage');
    
    guidata(hObject, handles);


% --------------------------------------------------------------------
function rightFromCameraAction_Callback(hObject, eventdata, handles)
    vid = videoinput('linuxvideo', 1);
    set(vid, 'ReturnedColorSpace', 'RGB');
    img = getsnapshot(vid);
    imshow(img)


% --------------------------------------------------------------------
function leftFromFileAction_Callback(hObject, eventdata, handles)
    [img, canceled] = imgetfile;
    if (canceled), return; end;
    handles.fundamental = [];
    handles.leftImage = imread(img);
    
    obj = findobj('tag', 'leftImage');
    imshow(handles.leftImage, 'parent', obj);
    set(obj, 'tag', 'leftImage');
    
    guidata(hObject, handles);


% --------------------------------------------------------------------
function leftFromCameraAction_Callback(hObject, eventdata, handles)
% hObject    handle to leftFromCameraAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function calibrateCameraAction_Callback(hObject, eventdata, handles)
    addpath('toolbox_calib');
    calib_gui_normal();


% --------------------------------------------------------------------
function drawEpipolarLinesAction_Callback(hObject, eventdata, handles)

    if (isempty(handles.leftImage) || isempty(handles.rightImage)), return; end;
    
    left = handles.leftImage;
    right = handles.rightImage;
    try
        left = rgb2gray(left);
        right = rgb2gray(right);
    catch err
    end
    
    % extract features 
    points1 = detectSURFFeatures(left);
    points2 = detectSURFFeatures(right); 
    
    % Extract the features.

    [f1, vpts1] = extractFeatures(left, points1);
    [f2, vpts2] = extractFeatures(right, points2);
    
    indexPairs = matchFeatures(f1, f2);
    matched_pts1 = vpts1(indexPairs(:, 1));
    matched_pts2 = vpts2(indexPairs(:, 2));
    
    a1 = []; a2 = [];
    for i = 1:length(matched_pts1)
        a1 = [a1; matched_pts1(i).Location];
    end
    
    for i = 1:length(matched_pts2)
        a2 = [a2; matched_pts2(i).Location];
    end

    % fundamental matrix
%     fmatrix = estimateFundamentalMatrix(a1, a2, 'NumTrials', 4000);
    fmatrix = estimateFundamentalMatrix(a1, a2, 'NumTrials', 4000, 'Method', 'RANSAC');
    % Lines in right image
    linesRight = epipolarLine(fmatrix, a1);
    
    obj = findobj('tag', 'rightImage');
    axes(obj);
    imshow(right); hold on;
    pts = lineToBorderPoints(linesRight, size(right));
    line(pts(:, [1,3])', pts(:, [2,4])');
    hold off;
    set(obj, 'tag', 'rightImage');
    
    % Lines in left image
    linesLeft = epipolarLine(fmatrix', a2);
    
    obj = findobj('tag', 'leftImage');
    axes(obj);
    imshow(left); hold on;
    pts = lineToBorderPoints(linesLeft, size(left));
    line(pts(:, [1,3])', pts(:, [2,4])');
    hold off;
    set(obj, 'tag', 'leftImage');