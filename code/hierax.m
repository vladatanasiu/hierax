classdef hierax < matlab.apps.AppBase
% Enhance the legibility of papyri images
%
% The purpose of this app is to enhance the legibility of papyri images. It
% uses color processing and optical illusions and provides a an interactive
% image viewing capability. Please refer to the help file included in the
% app distribution package for more information.
% 
% The technical aspects of the image processing methods used in Hierax and 
% their evaluation through a user experiment are described in the following 
% paper: Vlad Atanasiu, Isabelle Marthot-Santaniello, “Legibility 
% Enhancement of Papyri Using Color Processing and Visual Illusions: 
% A Case Study in Critical Vision”, accepted for publication in the
% International Journal on Document Analysis and Recognition (IJDAR).
%
% This file, hierax.m, contains the user interface of the software; the
% image processing is carried out by hierax_process.m and its dependent
% functions.
%
% -------------
% REQUIREMENTS
% -------------
% – Matlab R2020b Update4
% – Image Processing Toolbox
%
% -------------
% REMINDERS
% -------------
% – When releasing a new version of the app, do not forget to change the
% app version, under properties > AppVersion.
% – Also, update the gui/about.html file, if needed.
% – When variable names that appear in the hierax_settings.json file have
% changed, then delete that file before running the new version of the app.
%
% -------------
% LOG
% -------------
% 2021.03.30 - [mod] change of logo
% 2021.01.29 - [mod] open online help in a browser
% 2020.12.29 - [fix] multichannel images are checked for identical channels
% 2020.12.21 - [fix] on Windows, writes correctly unreadable files
% 2020.12.18 - [new] handles multi-channel images
%            - [new] outputs names of unreadable images to a text file
% 2020.12.10 - [fix] fixed overlapping elements issue
% 2020.12.09 - [new] option to retain only the red channel of color images
%              [mod] minor improvements
% 2020.11.29 - [new] added text logo
% 2020.11.21 - [new] added timer
% 2020.11.11 - [fix] app doesn't stop anymore if the first image in a set
%              of images is grayscale
% 2020.11.07 - [mod] improved UI readability; extended documentation
% 2020.11.03 - [adm] first public release
% 2020.07.01 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/


    % Properties that correspond to app components
    properties (Access = public)
        
        UIFigure                     matlab.ui.Figure
        TabGroup                     matlab.ui.container.TabGroup
        
        % Enhance tab
        EnhanceTab                   matlab.ui.container.Tab
        GridLayoutEnhance1           matlab.ui.container.GridLayout
        GridLayoutEnhance2           matlab.ui.container.GridLayout
        GridLayoutEnhance3           matlab.ui.container.GridLayout
        GridLayoutEnhance4           matlab.ui.container.GridLayout
        
        ProcessingPanel              matlab.ui.container.Panel
        VividnessCheckBox            matlab.ui.control.CheckBox
        LSVCheckBox                  matlab.ui.control.CheckBox
        AdapthisteqCheckBox          matlab.ui.control.CheckBox
        RetinexCheckBox              matlab.ui.control.CheckBox
        RetinexListBox               matlab.ui.control.ListBox

        PostprocessingPanel          matlab.ui.container.Panel
        NegativeCheckBox             matlab.ui.control.CheckBox
        BlueCheckBox                 matlab.ui.control.CheckBox
        
        AuxiliariesPanel             matlab.ui.container.Panel
        MaskBackgroundCheckBox       matlab.ui.control.CheckBox
        BackgroundButtonGroup        matlab.ui.container.ButtonGroup
        LightBackgroundButton        matlab.ui.control.RadioButton
        DarkBackgroundButton         matlab.ui.control.RadioButton
        ShadowsButtonGroup           matlab.ui.container.ButtonGroup
        KeepShadowsButton            matlab.ui.control.RadioButton
        RemoveShadowsButton          matlab.ui.control.RadioButton
        RedChannelOnlyCheckBox       matlab.ui.control.CheckBox

        DataPanel                    matlab.ui.container.Panel
        SelectImagesButton           matlab.ui.control.Button

        SavePanel                    matlab.ui.container.Panel
        JPEGCheckBox                 matlab.ui.control.CheckBox
        TIFFCheckBox                 matlab.ui.control.CheckBox
        JPEGQualityLabel             matlab.ui.control.Label
        JPEGQualityEditField         matlab.ui.control.NumericEditField
        
        StatusBarLabel               matlab.ui.control.Label

        HelpPanel                    matlab.ui.container.Panel
        HelpOnlineButton             matlab.ui.control.Button
        HelpLocalButton              matlab.ui.control.Button
        FalconImage                  matlab.ui.control.Image

        
        % Overview tab
        OverviewTab                  matlab.ui.container.Tab
        GridLayoutOverview1          matlab.ui.container.GridLayout
        GridLayoutOverview2          matlab.ui.container.GridLayout

        OverviewWrapperPanel         matlab.ui.container.Panel
        OverviewPanel                matlab.ui.container.Panel
        OverviewGrid                 matlab.ui.container.GridLayout
        
        OverviewToolsPanel           matlab.ui.container.Panel
        SaveOverviewButton           matlab.ui.control.Button
        LoadImagesInViewerButton     matlab.ui.control.Button

        
        % Detail panel
        DetailTab                    matlab.ui.container.Tab
        DetailPanel1                 matlab.ui.container.Panel
        DetailPanel2                 matlab.ui.container.Panel
        DetailDropDown1              matlab.ui.control.DropDown
        DetailDropDown2              matlab.ui.control.DropDown

        InteractionToolsPanel        matlab.ui.container.Panel
        ZoomButton                   matlab.ui.control.StateButton
        PanButton                    matlab.ui.control.StateButton
        RotateButton                 matlab.ui.control.StateButton
        ResetButton                  matlab.ui.control.Button
        PreviousButton               matlab.ui.control.Button
        NextButton                   matlab.ui.control.Button
        
        MoveImagePanel               matlab.ui.container.Panel
        MoveImageToTopButton         matlab.ui.control.Button
        MoveImageUpButton            matlab.ui.control.Button
        MoveImageDownButton          matlab.ui.control.Button
        MoveImageToBottomButton      matlab.ui.control.Button

        ReorderImagesPanel           matlab.ui.container.Panel
        ListImagesInterleavedButton  matlab.ui.control.Button
        ListImagesSequentialButton   matlab.ui.control.Button
        
        
        % About Tab
        AboutTab                     matlab.ui.container.Tab
        MottoLabel                   matlab.ui.control.Label
        VersionLabel                 matlab.ui.control.Label
        AboutHTML                    matlab.ui.control.HTML
        
    end

    % Variables, handles, objects, etc.
    properties (Access = private)
        
        % Application Version displayed in the UI About tab
        % --------------------------
        % UPDATE AT EACH NEW VERSION
        % --------------------------
        AppVersion = '2021.03.30';
        % --------------------------
        
        % paths
        AppRoot = ''; % Matlab / Matlab Runtime root
        AppPath = ''; % app path in respect to Matlab root
        AppName = 'Hierax';
        
        % UI settings
        Settings

        % specify method labels and lists
        MethodLabels
        MethodIndices
        MethodLists
        
        % structure with arrays holding the enhanced images and thier 
        % labels; the last image is the input image
        Images % = struct('Pixels',{},'Labels',{})

        % specifies if the first image to be processed was 
        % grayscale and if it was enhanced
        Grayscale

        % url of first image
        DirWrite = 'enhanced';
        ImageURL = struct('read',['.',filesep],...
            'write',['.',filesep,'enhancement',filesep]);
        
        % overview image of all enhanced images (tile)
        OverviewPanelPadding % top, right, bottom, left
        OverviewImages
        OverviewGridRows
        OverviewGridCols
        OverviewGridCell
        OverviewIsUpToDate
        OverviewMosaic
        OverviewClickedImageIndex

        % order of images by class
        % {'sequential'} | 'interleaved' | 'custom'
        CurrentImageOrder = 'sequential';

        % we will display enhanced images, but only the first among those
        % selected by the user
        FirstImage = struct('show',false,'is',false,'filename','');
        AppFirstUse = true % is this the first time images were processed?
        LoadedImages % false if the displayed images are produced during
        % the last enhancememnt round and true if uploaded by the user
        Abort % logical; true if enhancement process aborted by user by 
        % pressing the cancel button on the waitbar

        % JPEG quality of saved images
        JpegQuality = 75;
        
        % colors
        ColorGray = [0.9412, 0.9412, 0.9412]; % color of figure background
        
        % create programmatically axes in the detail tab to display images.
        % this is needed to have support for linkedaxes, which is not yet 
        % (@R2020a) provided by App Designer, so that we can synchronize  
        % interactivity between image axes
        DetailAxes1 matlab.graphics.axis.Axes
        DetailAxes2 matlab.graphics.axis.Axes
        DetailImage1
        DetailImage2
        % used to synchronize image interaction in detail tab
        LinkpropHandle
        
        % interaction properties
        % axes limits & orientation just after the images were displayed
        AxesInitialState
        % angle in degrees by which to interactively rotate the images
        RotationAngle = 5;

        % Messages to display on a GUI status bar
        Status = struct(...
            'Header','   ',...
            'Message','');

    end

    % Startup
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app)
            
            % ---
            % create variously ordered lists of method labels to be
            % selectred from by users to order the image stack in the 
            % display tab
            % ---
            % input image label
            app.MethodLabels.input = {...
                'Original'};

            % methods for color images
            app.MethodLabels.color.processing = {...
                'Vividness', ...
                'LSV', ...
                'Adapthisteq', ...
                'Retinex MSRCR-RGB', ...
                'Retinex MSR-VAB', ...
                'Retinex MSR-LAB', ...
                'Retinex MSR-V', ...
                'Retinex MSR-L', ...
                'Retinex MSRCP-I', ...
                'Retinex MSRCP-V', ...
                'Retinex MSRCP-L'};
            app.MethodLabels.color.postprocessing = {...
                '', ...
                'Negative', ...
                'Blue Negative'};
            app.MethodLabels.color.auxiliaries = {...
                '',...
                'Masked'};

            % methods for grayscale images
            app.MethodLabels.grayscale.processing = {...
                'Adapthisteq', ...
                'Retinex MSR-A'};
            app.MethodLabels.grayscale.postprocessing = {...
                '', ...
                'Negative'};
            app.MethodLabels.grayscale.auxiliaries = {...
                '',...
                'Masked'};
            
            % generate ordered lists of all method labels
            app.MethodLists.potential = hierax_lists(app.MethodLabels);

            
            % ---
            % continue preparing GUI components
            % ---
            
            % memorize initial distance of overview panel to window edge
            top = app.OverviewWrapperPanel.Position(4) - ...
                    app.OverviewPanel.Position(4) - ...
                    app.OverviewPanel.Position(2);
            right = app.OverviewWrapperPanel.Position(3) - ...
                    app.OverviewPanel.Position(3) - ...
                    app.OverviewPanel.Position(1);
            bottom = app.OverviewPanel.Position(2);
            left = app.OverviewPanel.Position(1);
            app.OverviewPanelPadding = [top, right, bottom, left];
            
            % hide empty GUI elements
            app.DetailDropDown1.Visible = 'off';
            app.DetailDropDown2.Visible = 'off';

            % create axes for images in detail tab
            app.DetailAxes1 = axes(app.DetailPanel1);
            app.DetailAxes2 = axes(app.DetailPanel2);
      
            % link axes for synchronous interaction
            app.LinkpropHandle = ...
                linkprop([app.DetailAxes1, app.DetailAxes2], ...
                {'View', 'XLim', 'YLim', 'ZLim'});
            
            % components that become visible once images are generated
            app.DetailAxes1.Visible = 'off';
            app.DetailAxes2.Visible = 'off';
            app.InteractionToolsPanel.Visible = 'off';
            app.MoveImagePanel.Visible = 'off';
            app.ReorderImagesPanel.Visible = 'off';
            
            % patch to avoid large images vanishing during panning
            noVanishingImages
            
        end
        
    end
    
    % Image interactions
    methods (Access = private)

        % Zoom toggle tool on callback
        function ZoomButtonValueChanged(app, ~)
            % activate zoom interaction

            if app.ZoomButton.Value == true
                
                % activate tool
                enableLegacyExplorationModes(app.UIFigure)
                ClickedTool = zoom(app.UIFigure);
                ClickedTool.Direction = 'in';
                ClickedTool.Enable = 'on';
                
                % change color
                app.ZoomButton.FontColor = [0 0 0];
                app.ZoomButton.BackgroundColor = [1 1 1];
                app.PanButton.FontColor = [1 1 1];
                app.PanButton.BackgroundColor = [0.149 0.149 0.149];
                app.RotateButton.FontColor = [1 1 1];
                app.RotateButton.BackgroundColor = [0.149 0.149 0.149];

                % unset other buttons than the pressed one
                app.PanButton.Value = false;
                app.RotateButton.Value = false;

                % unset tools callbacks
                OtherTool = pan(app.UIFigure);
                OtherTool.Enable = 'off';

            else
                
                % deactivate tool
                enableLegacyExplorationModes(app.UIFigure)
                ClickedTool = zoom(app.UIFigure);
                ClickedTool.Enable = 'off';

                % change color
                app.ZoomButton.FontColor = [1 1 1];
                app.ZoomButton.BackgroundColor = [0.149 0.149 0.149];
                
            end
        
        end
        
        % Pan toggle tool on callback
        function PanButtonValueChanged(app, ~)
            % activate pan interaction

            if app.PanButton.Value == true
                
                % activate tool
                enableLegacyExplorationModes(app.UIFigure)
                ClickedTool = pan(app.UIFigure);
                ClickedTool.Enable = 'on';
                
                % change color
                app.PanButton.FontColor = [0 0 0];
                app.PanButton.BackgroundColor = [1 1 1];
                app.ZoomButton.FontColor = [1 1 1];
                app.ZoomButton.BackgroundColor = [0.149 0.149 0.149];
                app.RotateButton.FontColor = [1 1 1];
                app.RotateButton.BackgroundColor = [0.149 0.149 0.149];

                % unset other buttons than the pressed one
                app.ZoomButton.Value = false;
                app.RotateButton.Value = false;

                % unset tools callbacks
                OtherTool = zoom(app.UIFigure);
                OtherTool.Enable = 'off';

            else
                
                % deactivate tool
                enableLegacyExplorationModes(app.UIFigure)
                ClickedTool = pan(app.UIFigure);
                ClickedTool.Enable = 'off';

                % change color
                app.PanButton.FontColor = [1 1 1];
                app.PanButton.BackgroundColor = [0.149 0.149 0.149];
                
            end
            
        end
        
        % Rotate toggle tool on callback
        function RotateButtonValueChanged(app, ~)
            % activate rotation interaction
            
            if app.RotateButton.Value == true
                
                % unset other buttons than the pressed one
                app.ZoomButton.Value = false;
                app.PanButton.Value = false;
                
                % change color
                app.RotateButton.FontColor = [0 0 0];
                app.RotateButton.BackgroundColor = [1 1 1];
                app.ZoomButton.FontColor = [1 1 1];
                app.ZoomButton.BackgroundColor = [0.149 0.149 0.149];
                app.PanButton.FontColor = [1 1 1];
                app.PanButton.BackgroundColor = [0.149 0.149 0.149];

                % unset tools callbacks
                OtherTool = zoom(app.UIFigure);
                OtherTool.Enable = 'off';
                OtherTool = pan(app.UIFigure);
                OtherTool.Enable = 'off';

            else    

                % change color
                app.RotateButton.FontColor = [1 1 1];
                app.RotateButton.BackgroundColor = [0.149 0.149 0.149];

            end
            
        end
        
        % Reset View push button tool on callback
        function ResetButtonPushed(app, ~)

            % reset zoom level and orientation of all axes
            app.DetailAxes1.XLim = app.AxesInitialState.XLim;
            app.DetailAxes1.YLim = app.AxesInitialState.YLim;
            app.DetailAxes1.View = ...
                [app.AxesInitialState.Az, app.AxesInitialState.El];
            app.DetailAxes2.XLim = app.AxesInitialState.XLim;
            app.DetailAxes2.YLim = app.AxesInitialState.YLim;
            app.DetailAxes2.View = ...
                [app.AxesInitialState.Az, app.AxesInitialState.El];
            
        end
        
        % Previous push button callback
        function PreviousButtonPushed(app, ~)
            % show next right-hand image

            % unset tools callbacks
            OtherTool = zoom(app.UIFigure);
            OtherTool.Enable = 'off';
            OtherTool = pan(app.UIFigure);
            OtherTool.Enable = 'off';
                
            % unset other buttons than the pressed one
            app.ZoomButton.Value = false;
            app.PanButton.Value = false;
            app.RotateButton.Value = false;
                
            % change color of other buttons
            app.ZoomButton.FontColor = [1 1 1];
            app.ZoomButton.BackgroundColor = [0.149 0.149 0.149];
            app.PanButton.FontColor = [1 1 1];
            app.PanButton.BackgroundColor = [0.149 0.149 0.149];
            app.RotateButton.FontColor = [1 1 1];
            app.RotateButton.BackgroundColor = [0.149 0.149 0.149];
            
            % change image
            event.Key = 'uparrow';
            UIFigureKeyPress(app, event)
            
        end
        
        % Next push button callback
        function NextButtonPushed(app, ~)
            % show next right-hand image

            % unset tools callbacks
            OtherTool = zoom(app.UIFigure);
            OtherTool.Enable = 'off';
            OtherTool = pan(app.UIFigure);
            OtherTool.Enable = 'off';
                
            % unset other buttons than the pressed one
            app.ZoomButton.Value = false;
            app.PanButton.Value = false;
            app.RotateButton.Value = false;
                
            % change color of other buttons
            app.ZoomButton.FontColor = [1 1 1];
            app.ZoomButton.BackgroundColor = [0.149 0.149 0.149];
            app.PanButton.FontColor = [1 1 1];
            app.PanButton.BackgroundColor = [0.149 0.149 0.149];
            app.RotateButton.FontColor = [1 1 1];
            app.RotateButton.BackgroundColor = [0.149 0.149 0.149];
            
            % change image
            event.Key = 'downarrow';
            UIFigureKeyPress(app, event)
            
        end
    
    end
    
    % Keyboard interaction
    methods (Access = private)
        
        function UIFigureKeyPress(app, event)
            key = event.Key;
            
            switch key

                case 'rightarrow'

                    if app.RotateButton.Value == true
                        
                        % rotate the two images by a fixed angle
                        [az, ~] = view(app.DetailAxes1);
                        view(app.DetailAxes1,[az + app.RotationAngle, 90])
                        view(app.DetailAxes2,[az + app.RotationAngle, 90])
                        
                    else
                        % show on the right the next image in the list
                        
                        % get current axis limits
                        former_axes_xlim = app.DetailAxes1.XLim;
                        former_axes_ylim = app.DetailAxes1.YLim;
                        [former_axes_azimuth, former_axes_elevation] = ...
                            view(app.DetailAxes1);

                        % find label of next method in the menu
                        current_item = app.DetailDropDown1.Value;
                        menu_items = app.DetailDropDown1.Items;
                        [~,k] = ismember(current_item,menu_items);
                        if k ~= length(menu_items)
                            next_item_index = k + 1;
                        else
                            next_item_index = 1;
                        end

                        % set new item
                        next_item = app.DetailDropDown1.Items{next_item_index};
                        app.DetailDropDown1.Value = next_item;
                        imshow(app.Images.Bitmaps{next_item_index},...
                            'Parent',app.DetailAxes1)

                        % set former axis limits on new axis
                        app.DetailAxes1.XLim = former_axes_xlim;
                        app.DetailAxes1.YLim = former_axes_ylim;
                        app.DetailAxes1.View = ...
                            [former_axes_azimuth, former_axes_elevation];

                        % remove axes toolbars
                        app.DetailAxes1.Toolbar = [];
                        
                    end

                case 'leftarrow'

                    if app.RotateButton.Value == true
                        
                        % rotate the two images by fixed angle
                        [az, ~] = view(app.DetailAxes1);
                        view(app.DetailAxes1,[az - app.RotationAngle, 90])
                        view(app.DetailAxes2,[az - app.RotationAngle, 90])
                        
                    else
                        % show on the left the previous image in the list
                        
                        % get current axis limits
                        former_axes_xlim = app.DetailAxes1.XLim;
                        former_axes_ylim = app.DetailAxes1.YLim;
                        [former_axes_azimuth, former_axes_elevation] = ...
                            view(app.DetailAxes1);

                        % find label of next method in the menu
                        current_item = app.DetailDropDown1.Value;
                        menu_items = app.DetailDropDown1.Items;
                        [~,k] = ismember(current_item,menu_items);
                        if k ~= 1
                            next_item_index = k - 1;
                        else
                            next_item_index = length(menu_items);
                        end

                        % set new item
                        next_item = app.DetailDropDown1.Items{next_item_index};
                        app.DetailDropDown1.Value = next_item;
                        imshow(app.Images.Bitmaps{next_item_index},...
                            'Parent',app.DetailAxes1)

                        % set former axis limits on new axis
                        app.DetailAxes1.XLim = former_axes_xlim;
                        app.DetailAxes1.YLim = former_axes_ylim;
                        app.DetailAxes1.View = ...
                            [former_axes_azimuth, former_axes_elevation];

                        % remove axes toolbars
                        app.DetailAxes1.Toolbar = [];
                        
                    end

                case 'downarrow'
                    
                    if app.RotateButton.Value == true
                        
                        % rotate the two images by 90° clockwise
                        theta = 90;
                        [az, ~] = view(app.DetailAxes1);
                        view(app.DetailAxes1,[az + theta, 90])
                        view(app.DetailAxes2,[az + theta, 90])
                        
                    else
                        % show on the right the next image in the list

                        % get current axis limits
                        former_axes_xlim = app.DetailAxes2.XLim;
                        former_axes_ylim = app.DetailAxes2.YLim;
                        [former_axes_azimuth, former_axes_elevation] = ...
                            view(app.DetailAxes2);

                        % find label of next method in the menu
                        current_item = app.DetailDropDown2.Value;
                        menu_items = app.DetailDropDown2.Items;
                        [~,k] = ismember(current_item,menu_items);
                        if k ~= length(menu_items)
                            next_item_index = k + 1;
                        else
                            next_item_index = 1;
                        end

                        % set new item
                        next_item = app.DetailDropDown2.Items{next_item_index};
                        app.DetailDropDown2.Value = next_item;
                        imshow(app.Images.Bitmaps{next_item_index},...
                            'Parent',app.DetailAxes2)

                        % set former axis limits on new axis
                        app.DetailAxes2.XLim = former_axes_xlim;
                        app.DetailAxes2.YLim = former_axes_ylim;
                        app.DetailAxes2.View = ...
                            [former_axes_azimuth, former_axes_elevation];

                        % remove axes toolbars
                        app.DetailAxes2.Toolbar = [];
                    end

                case 'uparrow'
                    
                    if app.RotateButton.Value == true
                        
                        % rotate the two images by 90° counter-clockwise
                        theta = -90;
                        [az, ~] = view(app.DetailAxes1);
                        view(app.DetailAxes1,[az + theta, 90])
                        view(app.DetailAxes2,[az + theta, 90])
                        
                    else
                        % show on the left the previous image in the list

                        % get current axis limits
                        former_axes_xlim = app.DetailAxes2.XLim;
                        former_axes_ylim = app.DetailAxes2.YLim;
                        [former_axes_azimuth, former_axes_elevation] = ...
                            view(app.DetailAxes2);

                        % find label of next method in the menu
                        current_item = app.DetailDropDown2.Value;
                        menu_items = app.DetailDropDown2.Items;
                        [~,k] = ismember(current_item,menu_items);
                        if k ~= 1
                            next_item_index = k - 1;
                        else
                            next_item_index = length(menu_items);
                        end

                        % set new item
                        next_item = app.DetailDropDown2.Items{next_item_index};
                        app.DetailDropDown2.Value = next_item;
                        imshow(app.Images.Bitmaps{next_item_index},...
                            'Parent',app.DetailAxes2)

                        % set former axis limits on new axis
                        app.DetailAxes2.XLim = former_axes_xlim;
                        app.DetailAxes2.YLim = former_axes_ylim;
                        app.DetailAxes2.View = ...
                            [former_axes_azimuth, former_axes_elevation];

                        % remove axes toolbars
                        app.DetailAxes2.Toolbar = [];
                    end
                    
                case 't'
                    MoveImageToTopButtonPushed(app)
                    
                case 'u'
                    MoveImageUpButtonPushed(app)
                    
                case 'd'
                    MoveImageDownButtonPushed(app)
                    
                case 'b'
                    MoveImageToBottomButtonPushed(app)
                    
                case 'i'
                    ListImagesInterleavedButtonPushed(app)
                    
                case 's'
                    ListImagesSequentialButtonPushed(app)

            end
        end
    end

    % UI components callbacks
    methods (Access = private)

        % Make toolbar tools visible only if Detail Tab is active
        function TabGroupSelectionChanged(app, ~)

            % update overview image
            if strcmp(app.TabGroup.SelectedTab.Title,'Overview') == true ...
                    && app.AppFirstUse == false

                UpdateOverview(app)
                app.AppFirstUse = false;
            end
                
        end
        
        % Select & Enhance Images
        function EnhanceImagesButtonPushed(app, ~)

            % determine preprocessing to apply
            do.mask = app.MaskBackgroundCheckBox.Value;
            if app.LightBackgroundButton.Value == true
                do.maskBackground = 'lightBackground';
            else
                do.maskBackground = 'darkBackground';
            end
            if do.mask == true
                do.deshadow = app.RemoveShadowsButton.Value;
            end
            do.red = app.RedChannelOnlyCheckBox.Value;
            
            % determine enhancement methods to apply
            do.vividness = app.VividnessCheckBox.Value;
            do.lsv = app.LSVCheckBox.Value;
            do.adapthisteq = app.AdapthisteqCheckBox.Value;
            do.retinex = app.RetinexCheckBox.Value;
            do.retinexMethods = app.RetinexListBox.Value;            
            do.negative = app.NegativeCheckBox.Value;
            do.blue = app.BlueCheckBox.Value;
            
            % determine selected enhancement classes
            do.processing = true;
            do.postprocessing = true;
            if (app.VividnessCheckBox.Value || ...
                    app.LSVCheckBox.Value || ...
                    app.AdapthisteqCheckBox.Value || ...
                    app.RetinexCheckBox.Value) == false
                
                do.processing = false;
            end
            if (app.NegativeCheckBox.Value || ...
                    app.BlueCheckBox.Value) == false
                
                do.postprocessing = false;
            end
            
            % check that at least one processing method was selected
            if do.processing == false
                
                uialert(app.UIFigure,...
                    ['Please select at least one enhancement method ',...
                    'in the Methods panel.'],...
                    'Request','Icon','warning');
                return
            end
            
            % varia
            app.FirstImage.is = true;
            app.StatusBarLabel.Text = '';
            app.LoadedImages.is = false;
            
            multiWaitbar('The Machine Is Working. Drink Water...',1);
            startTimer = tic; % measure processing duration
            
            % -------------------------------------------------------------
            % process images
            % -------------------------------------------------------------
            
            [app.Images, app.FirstImage, app.ImageURL, ...
                app.Status.Message, app.Grayscale, app.Abort] = ...
                    hierax_process(...
                        do, app.JPEGCheckBox.Value, ...
                        app.TIFFCheckBox.Value, app.FirstImage, ...
                        app.AppRoot, app.DirWrite, app.ImageURL, ...
                        app.JpegQuality, app.UIFigure);
            
            % -------------------------------------------------------------

            % return if processing aborted
            if app.Abort == true
                multiWaitbar('The Machine Is Working. Drink Water...',...
                    'Close');
                return
            end
            
            % return if no images processed
            if isempty(app.Images.Bitmaps)
                
                % display any message at the bottom of the figure
                if ~isempty(app.Status.Message)
                    app.StatusBarLabel.Text = ...
                        [app.Status.Header,app.Status.Message];
                end
                
                % message user
                uialert(app.UIFigure,...
                    'No Images Processed.','Information','Icon','info');
                
                multiWaitbar('The Machine Is Working. Drink Water...',...
                    'Close');
                return
            end
            
            % display processing duration in the stauts bar of the enhance tab
            processingDuration = toc(startTimer);
            processingDuration = datestr(seconds(processingDuration),'HH:MM:SS');
            processingDuration = datevec(processingDuration);
            processingDuration = [...
                num2str(processingDuration(4)),'h ',...
                num2str(processingDuration(5)),'m ',...
                num2str(processingDuration(6)),'s'];
            del = '';
            if ~isempty(app.Status.Message)
                del = ' – ';
            end
            if processingDuration(6) == 0
                processingDuration = ['less than ',processingDuration];
            end

            % display total number of generated images minus the original
            nImage = length(app.Images.Bitmaps) - 1;
            plural = 's';
            if nImage == 1
                plural = '';
            end

            % output display-bar message
            app.Status.Message = [app.Status.Message,del,...
                num2str(nImage),' image',plural,' generated in ',...
                processingDuration,'.'];

            % display images in viewer
            DisplayImages(app)
            
        end
        
        % Display processed or selected images
        function DisplayImages(app, ~)
            
            if app.LoadedImages.is == true
                % no information available on enhancement class types
                
                % create overview image
                CreateOverview(app)

            else % order images by enhancement class type
                
                % limit method lists to methods of this enhacement round
                LimitMethodLists(app);
            
                % create overview image
                CreateOverview(app)
                
                % present images initially in order of sequential 
                % enhancement classses since it is more efficient;
                % the default order is as output by the ninon_process 
                % function, i.e., interleaved, and will be used by overview
                % as reference grid cell index
                ListImagesSequentialButtonPushed(app)
                
                % allow reordering images by class
                app.ReorderImagesPanel.Visible = 'on';
                  
                % update overview image
                UpdateOverview(app)

            end
            
            % show the filename of the displayed image
            app.UIFigure.Name = [app.AppName, ' · ', ...
                app.FirstImage.filename];
            
            % display any message at the bottom of the figure
            if ~isempty(app.Status.Message)
                app.StatusBarLabel.Text = ...
                    [app.Status.Header,app.Status.Message];
            end
            
            % make UI components visible
            if app.AppFirstUse == true   
                
                app.DetailAxes1.Visible = 'on';
                app.DetailAxes2.Visible = 'on';
                app.DetailDropDown1.Visible = 'on';
                app.DetailDropDown2.Visible = 'on';

                app.InteractionToolsPanel.Visible = 'on';
                app.MoveImagePanel.Visible = 'on';
                app.ReorderImagesPanel.Visible = 'on';

            end
            
            % clear axes & reset custom properties
            cla(app.DetailAxes1,'reset')
            cla(app.DetailAxes2,'reset')
            
            % enable buttons
            app.SaveOverviewButton.Enable = 'on';
            
            % populate drop-down menus in detail tab with method labels
            app.DetailDropDown1.Items = app.Images.Labels;
            app.DetailDropDown2.Items = app.Images.Labels;
            app.DetailDropDown1.Value = app.Images.Labels{1};
            app.DetailDropDown2.Value = app.Images.Labels{2};

            % show two enhanced images side by side in detail tab
            imshow(app.Images.Bitmaps{1},'Parent',app.DetailAxes1)
            imshow(app.Images.Bitmaps{2},'Parent',app.DetailAxes2)

            % remove axes toolbars
            app.DetailAxes1.Toolbar = [];
            app.DetailAxes2.Toolbar = [];

            % block image interaction via the mouseover toolbar
            disableDefaultInteractivity(app.DetailAxes1);
            disableDefaultInteractivity(app.DetailAxes2);
            
            % get initial axes limits & orientation 
            % to be used by the reset view tool
            app.AxesInitialState.XLim = app.DetailAxes1.XLim;
            app.AxesInitialState.YLim = app.DetailAxes1.YLim;
            [CameraAzimuth, CameraElevation] = view(app.DetailAxes1);
            app.AxesInitialState.Az = CameraAzimuth;
            app.AxesInitialState.El = CameraElevation;
            
            % wrap up
            app.AppFirstUse = false;
            multiWaitbar('The Machine Is Working. Drink Water...','Close');
            
            % give focus to Overview tab
            app.TabGroup.SelectedTab = app.OverviewTab;

        end

        % Create overview image mosaic
        function CreateOverview(app, ~)
                
            multiWaitbar('Preparing Overview Image', 'Busy');
            
            % image amount and size
            nImage = length(app.Images.Bitmaps);
            hImage = size(app.Images.Bitmaps{1},1);
            wImage = size(app.Images.Bitmaps{1},2);

            % position within tab of available area to display the image tile
            % static distance to window border
            x0 = app.OverviewPanelPadding(4);
            y0 = app.OverviewPanelPadding(3);
            % aspect dynamically determined from current window aspect
            w0 = app.OverviewWrapperPanel.Position(3) - ...
                app.OverviewPanelPadding(2) - app.OverviewPanelPadding(4); 
            h0 = app.OverviewWrapperPanel.Position(4) - ...
                app.OverviewPanelPadding(1) - app.OverviewPanelPadding(3); 

            % determine number of grid row and columns
            row = 1:nImage;
            col = ceil(nImage./row);
            w = col*wImage;
            h = row*hImage;
            aspect = w./h;
            aspect0 = w0/h0;
            [~,row] = min(abs(aspect0 - aspect));
            col = col(row);
            app.OverviewGridRows = row;
            app.OverviewGridCols = col;

            % set position on panel of an area specific to an image
            if w0/(wImage*col) < h0/(hImage*row)
                pw = w0;
                ph = floor((hImage*row)*w0/(wImage*col));
                px = x0;
                py = y0 + floor((h0 - ph)/2);
            else
                pw = floor((wImage*col)*h0/(hImage*row));
                ph = h0;
                px = x0 + floor((w0 - pw)/2);
                py = y0;
            end
            app.OverviewPanel.Position = [px,py,pw,ph];

            % remove prexisting grid and images
            if ~isempty(app.OverviewGrid)
                app.OverviewGrid.delete
                app.OverviewImages.delete
            end

            % create grid
            app.OverviewGrid = uigridlayout(app.OverviewPanel,[row,col]);
            app.OverviewGrid.ColumnSpacing = 0;
            app.OverviewGrid.RowSpacing = 0;
            app.OverviewGrid.Padding = [0 0 0 0];
            app.OverviewGrid.BackgroundColor = [0.149 0.149 0.149];

            % preallocate array for image objects
            app.OverviewImages = gobjects(nImage);
            app.OverviewGridCell = gobjects(nImage);

            % populate grid with images
            k = 0;
            for kRow = 1:row
                for kCol = 1:col
                    k = k + 1;
                    if k > nImage
                        break
                    end

                    % read image from stack
                    I = app.Images.Bitmaps{k};

                    % ensure image is a m-by-n-by-3 truecolor image array
                    bitdepth = size(I,3);
                    if bitdepth == 1
                        % stack grayscale images
                        I = cat(3,I,I,I);
                    elseif bitdepth ~= 3
                        continue
                    end

                    % create grid cell
                    app.OverviewGridCell(k) = uigridlayout(app.OverviewGrid,[1,1]);
                    app.OverviewGridCell(k).Layout.Row = kRow;
                    app.OverviewGridCell(k).Layout.Column = kCol;
                    app.OverviewGridCell(k).ColumnSpacing = 0;
                    app.OverviewGridCell(k).RowSpacing = 0;
                    app.OverviewGridCell(k).Padding = [0 0 0 0];
                    app.OverviewGridCell(k).BackgroundColor = [0.149 0.149 0.149];
                    
                    % put image
                    app.OverviewImages(k) = uiimage(app.OverviewGridCell(k));
                    app.OverviewImages(k).ImageSource = I;
                    app.OverviewImages(k).Tooltip = app.Images.Labels{k};
                    app.OverviewImages(k).ImageClickedFcn = ...
                        createCallbackFcn(app, @OnClickOverviewTile, true);
                end
            end
            
            % draw image now, so that it is ready when the Overview tab
            % is given focus
            drawnow
            
            % make overview mosaic visible
            app.OverviewIsUpToDate = true;
            app.OverviewPanel.Visible = 'on';
            app.OverviewPanel.BorderType = 'none';
            app.OverviewPanel.BackgroundColor = [0.149 0.149 0.149];

            multiWaitbar('Preparing Overview Image', 'Reset');
            multiWaitbar('Preparing Overview Image','Close');
            
        end

        % Update overview image
        function UpdateOverview(app, ~)
            
            if app.OverviewIsUpToDate
                return
            end
            
            multiWaitbar('Preparing Overview Image', 'Busy');
            
            % convert array indices to subscripts
            [c,r] = ind2sub(...
                [app.OverviewGridCols, app.OverviewGridRows],...
                1:length(app.Images.Indices));
            idx = cell2mat(app.Images.Indices);
            [row,k] = sortrows(cat(2,r',idx'),2);
            row = row(:,1);
            col = c(k);
            
            % reorder images
            n = length(app.OverviewImages);
            for k = 1:n
                
                app.OverviewGridCell(k).Layout.Column = col(k);
                app.OverviewGridCell(k).Layout.Row = row(k);
                
            end
            
            app.OverviewIsUpToDate = true;
            multiWaitbar('Preparing Overview Image', 'Reset');
            multiWaitbar('Preparing Overview Image','Close');
            
        end
        
        % Capture clicks on Overview tile
        function OnClickOverviewTile(app, event)

            % Get index of clicked overview image into images stack
            [~,app.OverviewClickedImageIndex] = ...
                ismember(event.Source.Tooltip, app.Images.Labels);
            
            % Update current image shown in Detail tab
            app.DetailDropDown2.Value = ...
                app.Images.Labels{app.OverviewClickedImageIndex};
            DetailDropDown2ValueChanged(app)
            
            % give focus to Overview tab
            app.TabGroup.SelectedTab = app.DetailTab;
            TabGroupSelectionChanged(app, event)

        end
        
        % Save overview image
        function SaveOverview(app, ~)
            
            multiWaitbar('Saving Overview Image',0.5);
            
            % create overview image mosaic
            app.OverviewMosaic = imtile(app.Images.Bitmaps,...
                'GridSize',[app.OverviewGridRows, app.OverviewGridCols],...
                'ThumbnailSize',[],...
                'BackgroundColor',[0.149 0.149 0.149],...
                'BorderSize',[0,0]);
            
            % create directory were to save the image if not existing
            [image_path,~,~] = fileparts(app.ImageURL.write);
            [mkdir_status,mkdir_msg] = mkdir(image_path);
            if mkdir_status == 0
                multiWaitbar('Saving Overview Image','Close');
                uialert(app.UIFigure,...
                    mkdir_msg,'Error','Icon','error');
                return
            end

            % generate file name
            if app.LoadedImages.is == false
                % the name of the overview image is known, it is the
                % one of the enhanced image
                fn = [app.ImageURL.write(1:end-4),'-overview-',...
                    app.CurrentImageOrder,'-order'];
            else
                % overview name is ambiguous in the case of images loaded
                % by the user in the viewer, so a generic name is used
                fn = fullfile(image_path,'images-overview-custom-order');
            end
            
            % save images
            if app.TIFFCheckBox.Value == true
                imwrite(app.OverviewMosaic,[fn,'.tif'])
            end
            if app.JPEGCheckBox.Value == true
                imwrite(app.OverviewMosaic,[fn,'.jpg'],...
                    'Quality',app.JpegQuality)
            end

            multiWaitbar('Saving Overview Image',1);
            multiWaitbar('Saving Overview Image','Close');
            
        end

        % Load images in viewer without enhancing them
        function LoadImagesInViewerButtonPushed(app, ~)
            
            % show waitbar
            multiWaitbar('The Machine Is Working. Drink Water...',1);

            % initialization
            app.Images.Bitmaps = {};
            app.Images.Labels = {};
            app.Images.Indices = {};

            % select interactively images to enhance from last used directory
            [image_path,~,~] = fileparts(app.ImageURL.read);
            [image_file,image_path] = uigetfile(...
               [image_path,filesep,'*.*'],...
               'Select One or More Files', 'MultiSelect', 'on');

            % catch if user pressed the Cancel button
            if isa(image_file,'double')
                multiWaitbar('The Machine Is Working. Drink Water...',...
                    'Close');
                return
            end

            % ensure there are at least two images selected so that we have
            % enough to compare
            if iscell(image_file)
                nImages = length(image_file); % multiple images
            else
                % single image
                multiWaitbar('Reading Images','Close');
                multiWaitbar('The Machine Is Working. Drink Water...',...
                    'Close');
                uialert(app.UIFigure,...
                    'Please select at least two images.',...
                    'Request','Icon','warning');
                return
            end

            % loop through image list to load them in a structure
            multiWaitbar('Reading Images',0,'CanCancel','on');
            unreadableImages = 0;
            dImages = 1/nImages;
            for kImages = 1:nImages

                % read image
                app.Images.Labels{kImages} = image_file{kImages};
                app.Images.Indices{kImages} = kImages;
                imurl = [image_path,image_file{kImages}];
                % memorize the name of the first file
                if kImages == 1
                    app.FirstImage.filename = image_file{kImages};
                end

                try
                    app.Images.Bitmaps{kImages} = imread(imurl);
                catch
                    unreadableImages = unreadableImages + 1;
                    continue
                end
                
                % add indices to be used for reordering overview images
                app.Images.Indices{kImages} = kImages;

                % next image
                abort = multiWaitbar('Reading Images','Increment',dImages);

                % stop processing if user pressed the waitbar cancel button
                if abort == true
                    multiWaitbar('Reading Images','Close');
                    multiWaitbar(...
                        'The Machine Is Working. Drink Water...','Close');
                    return
                end

            end
            multiWaitbar('Reading Images','Close');
            
            % no readable images were found
            if unreadableImages == nImages
                multiWaitbar(...
                    'The Machine Is Working. Drink Water...','Close');
                return
            end

            % end loading images
            app.Status.Message = '';
            app.FirstImage.is = true;
            app.LoadedImages.is = true;
            app.CurrentImageOrder = 'custom';
            
            % display images
            DisplayImages(app)
            
            % disable predefined image stack order lists
            app.ReorderImagesPanel.Visible = 'off';
            
            % update memorized image source directory
            app.ImageURL.read = fullfile(image_path,image_file{1});
            app.ImageURL.write = fullfile(image_path,...
                app.DirWrite,image_file{1});
            
            % update figure name
            app.UIFigure.Name = 'Hierax · Custom Images';
            
            multiWaitbar('The Machine Is Working. Drink Water...','Close');
            
        end

        % Value changed function: DropDown1DetailTab
        function DetailDropDown1ValueChanged(app, ~)

            % find index of current item in the menu
            current_item = app.DetailDropDown1.Value;
            menu_items = app.DetailDropDown1.Items;
            [~,k] = ismember(current_item,menu_items);
            
            % get current axis limits
            former_axes_xlim = app.DetailAxes1.XLim;
            former_axes_ylim = app.DetailAxes1.YLim;
            [former_axes_azimuth, former_axes_elevation] = ...
                view(app.DetailAxes1);

            % show image associated with current menu item
            imshow(app.Images.Bitmaps{k},'Parent',app.DetailAxes1)

            % remove axes toolbars
            app.DetailAxes1.Toolbar = [];

            % block image interaction via the mouseover toolbar
            disableDefaultInteractivity(app.DetailAxes1);
                            
            % set former axis limits on new axis
            app.DetailAxes1.XLim = former_axes_xlim;
            app.DetailAxes1.YLim = former_axes_ylim;
            app.DetailAxes1.View = ...
                [former_axes_azimuth, former_axes_elevation];

        end
        
        % Value changed function: DropDown2DetailTab
        function DetailDropDown2ValueChanged(app, ~)
            
            % find index of current item in the menu
            current_item = app.DetailDropDown2.Value;
            menu_items = app.DetailDropDown2.Items;
            [~,k] = ismember(current_item,menu_items);

            % get current axis limits
            former_axes_xlim = app.DetailAxes2.XLim;
            former_axes_ylim = app.DetailAxes2.YLim;
            [former_axes_azimuth, former_axes_elevation] = ...
                view(app.DetailAxes2);

            % show image associated with current menu item
            imshow(app.Images.Bitmaps{k},'Parent',app.DetailAxes2)

            % remove axes toolbars
            app.DetailAxes2.Toolbar = [];

            % block image interaction via the mouseover toolbar
            disableDefaultInteractivity(app.DetailAxes2);
                
            % set former axis limits on new axis
            app.DetailAxes2.XLim = former_axes_xlim;
            app.DetailAxes2.YLim = former_axes_ylim;
            app.DetailAxes2.View = ...
                [former_axes_azimuth, former_axes_elevation];

        end
        
        % Value changed function: RetinexCheckBox
        function RetinexCheckBoxValueChanged(app, ~)

            % Masking parameters are accessible only if masking selected.
            value = app.RetinexCheckBox.Value;
            if value == true
                app.RetinexListBox.Enable = 'on';
           else
                app.RetinexListBox.Enable = 'off';
            end
        end

        % Value changed function: MaskBackgroundCheckBox
        function MaskBackgroundCheckBoxValueChanged(app, ~)

            % Masking parameters are accessible only if masking selected.
            value = app.MaskBackgroundCheckBox.Value;
            if value == true
                app.BackgroundButtonGroup.Enable = 'on';
                app.ShadowsButtonGroup.Enable = 'on';
            else
                app.BackgroundButtonGroup.Enable = 'off';
                app.ShadowsButtonGroup.Enable = 'off';
            end
        end
        
        % Value changed function: JPEGQualityEditField
        function JPEGQualityEditFieldValueChanged(app, ~)
            
            % update memorized quality value
            app.JpegQuality = app.JPEGQualityEditField.Value;
            
        end
        
        % Do on HelpOnlineButton pushed
        function HelpOnlineButtonPushed(~, ~)
            
            % show online documentation in external web browser
            web('https://hierax.ch','-browser')

        end

        % Do on HelpLocalButton pushed
        function HelpLocalButtonPushed(app, ~)
            
            % tell how to get the local documentation
            message = {['A copy of the documentation has also been ',...
                'shipped with the software; to read it, please open ',...
                'in a web browser the file "hierax.html", found in ',...
                'the folder "help", located where you unzipped the ',...
                'Hierax software file.']};
            uialert(app.UIFigure,message,'How To Read The Local Manual',...
                'Icon','info');

        end

        % Image clicked function: FalconImageClicked
        function FalconImageClicked(app, ~)
            
            message = {'Dusk. Blue cats.'; '— Basho'};
            uialert(app.UIFigure,message,'',...
                'Icon','info');
            
        end
        
    end
    
    % Reorder image stack and display the next image
    methods (Access = private)
        
        % Limit method lists to methods of this enhacement round
        function LimitMethodLists(app)
            
            % methods currently selected by the user
            app.MethodLists.round.active = app.Images.Labels;

            % generate the intersection between all possible method 
            % combinations (MethodLists.potential) and the methods 
            % selected by the user during the present processing round 
            % (MethodLists.round)
            if app.Grayscale.is && app.Grayscale.processed

                % grayscale image
                idx = ismember(...
                    app.MethodLists.potential.grayscale.interleaved, ...
                    app.MethodLists.round.active);
                app.MethodLists.round.interleaved = ...
                    app.MethodLists.potential.grayscale.interleaved(idx);
                idx = ismember(...
                    app.MethodLists.potential.grayscale.sequential, ...
                    app.MethodLists.round.active);
                app.MethodLists.round.sequential = ...
                    app.MethodLists.potential.grayscale.sequential(idx);

            else
                
                % color image
                idx = ismember(...
                    app.MethodLists.potential.color.interleaved, ...
                    app.MethodLists.round.active);
                app.MethodLists.round.interleaved = ...
                    app.MethodLists.potential.color.interleaved(idx);
                idx = ismember(...
                    app.MethodLists.potential.color.sequential, ...
                    app.MethodLists.round.active);
                app.MethodLists.round.sequential = ...
                    app.MethodLists.potential.color.sequential(idx);
            end
        end
        
        % Move image to top of stack
        function MoveImageToTopButtonPushed(app, ~)
            
            % set current image order
            app.CurrentImageOrder = 'custom';

            % get current and list items
            current_item = app.DetailDropDown1.Value;
            list_items = app.DetailDropDown1.Items;
            
            % find index of current item in the list
            n = length(list_items);
            current_location = ismember(list_items,current_item);
            k = sum( (1:n) .* double(current_location));

            % rearrange list
            if k == 1
                % do nothing, selection is at the top of the list
                return
            end
                
            % move selection to top of list in...
            % detail drop down menus
            app.DetailDropDown2.Items = ...
                [app.DetailDropDown2.Items(k),...
                app.DetailDropDown2.Items(1:k - 1),...
                app.DetailDropDown2.Items(k + 1:end)];
            app.DetailDropDown1.Items = app.DetailDropDown2.Items;
            app.DetailDropDown1.Value = list_items(k-1);

            % image stack
            app.Images.Bitmaps = ...
                [app.Images.Bitmaps(k),...
                app.Images.Bitmaps(1:k - 1),...
                app.Images.Bitmaps(k + 1:end)];
            app.Images.Labels = ...
                [app.Images.Labels(k),...
                app.Images.Labels(1:k - 1),...
                app.Images.Labels(k + 1:end)];
            app.Images.Indices = ...
                [app.Images.Indices(k),...
                app.Images.Indices(1:k - 1),...
                app.Images.Indices(k + 1:end)];

            % methods list
            app.MethodLists.round.active = app.DetailDropDown2.Items;
            
            % memorize that the image order has changed
            app.OverviewIsUpToDate = false;
            
            % show the new image
            DetailDropDown1ValueChanged(app)
            DetailDropDown2ValueChanged(app)
            
        end

        % Move image upwards in stack
        function MoveImageUpButtonPushed(app, ~)
            
            % set current image order
            app.CurrentImageOrder = 'custom';

            % get current and list items
            current_item = app.DetailDropDown1.Value;
            list_items = app.DetailDropDown1.Items;

            % find index of current item in the list
            n = length(list_items);
            current_location = ismember(list_items,current_item);
            k = sum( (1:n) .* double(current_location));

            % rearrange list
            if k == 1
                % do nothing, selection is at the top of the list
                return
            end
                
            % move selection upwards in ....
            % detail drop down menus
            app.DetailDropDown2.Items = ...
                [app.DetailDropDown2.Items(1:k - 2),...
                app.DetailDropDown2.Items(k),...
                app.DetailDropDown2.Items(k - 1),...
                app.DetailDropDown2.Items(k + 1:end)];
            app.DetailDropDown1.Items = app.DetailDropDown2.Items;
            app.DetailDropDown1.Value = list_items(k-1);

            % image stack
            app.Images.Bitmaps = ...
                [app.Images.Bitmaps(1:k - 2),...
                app.Images.Bitmaps(k),...
                app.Images.Bitmaps(k - 1),...
                app.Images.Bitmaps(k + 1:end)];
            app.Images.Labels = ...
                [app.Images.Labels(1:k - 2),...
                app.Images.Labels(k),...
                app.Images.Labels(k - 1),...
                app.Images.Labels(k + 1:end)];
            app.Images.Indices = ...
                [app.Images.Indices(1:k - 2),...
                app.Images.Indices(k),...
                app.Images.Indices(k - 1),...
                app.Images.Indices(k + 1:end)];

            % methods list
            app.MethodLists.round.active = app.DetailDropDown2.Items;
            
            % memorize that the image order has changed
            app.OverviewIsUpToDate = false;
            
            % show the new image
            DetailDropDown1ValueChanged(app)
            DetailDropDown2ValueChanged(app)
            
        end
        
        % Move image downwards in stack
        function MoveImageDownButtonPushed(app, ~)
            
            % set current image order
            app.CurrentImageOrder = 'custom';

            % get current and list items
            current_item = app.DetailDropDown1.Value;
            list_items = app.DetailDropDown1.Items;

            % find index of current item in the list
            n = length(list_items);
            current_location = ismember(list_items,current_item);
            k = sum( (1:n) .* double(current_location));

            % rearrange list
            if k == n
                % do nothing, selection is at the bottom of the list
                return
            end
            
            % move selection downwards in ....
            % detail drop down menus
            app.DetailDropDown2.Items = ...
                [app.DetailDropDown2.Items(1:k - 1),...
                app.DetailDropDown2.Items(k + 1),...
                app.DetailDropDown2.Items(k),...
                app.DetailDropDown2.Items(k + 2:end)];
            app.DetailDropDown1.Items = app.DetailDropDown2.Items;
            app.DetailDropDown1.Value = list_items(k+1);

            % image stack
            app.Images.Bitmaps = ...
                [app.Images.Bitmaps(1:k - 1),...
                app.Images.Bitmaps(k + 1),...
                app.Images.Bitmaps(k),...
                app.Images.Bitmaps(k + 2:end)];
            app.Images.Labels = ...
                [app.Images.Labels(1:k - 1),...
                app.Images.Labels(k + 1),...
                app.Images.Labels(k),...
                app.Images.Labels(k + 2:end)];
            app.Images.Indices = ...
                [app.Images.Indices(1:k - 1),...
                app.Images.Indices(k + 1),...
                app.Images.Indices(k),...
                app.Images.Indices(k + 2:end)];

            % methods list
            app.MethodLists.round.active = app.DetailDropDown2.Items;
            
            % memorize that the image order has changed
            app.OverviewIsUpToDate = false;
            
            % show the new image
            DetailDropDown1ValueChanged(app)
            DetailDropDown2ValueChanged(app)

        end
        
        % Move image to bottom of stack
        function MoveImageToBottomButtonPushed(app, ~)
            
            % set current image order
            app.CurrentImageOrder = 'custom';

            % get current and list items
            current_item = app.DetailDropDown1.Value;
            list_items = app.DetailDropDown1.Items;

            % find index of current item in the list
            n = length(list_items);
            current_location = ismember(list_items,current_item);
            k = sum( (1:n) .* double(current_location) );

            % rearrange list
            if k == n
                % if selection is at the bottom of the list do nothing
                return
            end

            % move selection to bottom of list in...
            % detail drop down menus
            app.DetailDropDown2.Items = ...
                [app.DetailDropDown2.Items(1:k - 1),...
                app.DetailDropDown2.Items(k + 1:end),...
                app.DetailDropDown2.Items(k)];
            app.DetailDropDown1.Items = app.DetailDropDown2.Items;
            app.DetailDropDown1.Value = list_items(k+1);
            
            % image stack
            app.Images.Bitmaps = ...
                [app.Images.Bitmaps(1:k - 1),...
                app.Images.Bitmaps(k + 1:end),...
                app.Images.Bitmaps(k)];
            app.Images.Labels = ...
                [app.Images.Labels(1:k - 1),...
                app.Images.Labels(k + 1:end),...
                app.Images.Labels(k)];
            app.Images.Indices = ...
                [app.Images.Indices(1:k - 1),...
                app.Images.Indices(k + 1:end),...
                app.Images.Indices(k)];
                
            % methods list
            app.MethodLists.round.active = app.DetailDropDown2.Items;

            % memorize that the image order has changed
            app.OverviewIsUpToDate = false;
            
            % show the new image
            DetailDropDown1ValueChanged(app)
            DetailDropDown2ValueChanged(app)
            
        end
        
        % Order images by interleaved classes
        % E.g.: Vividness, Vividness Negative, Vividness Blue Negative, 
        % LSV, LSV Negative, LSV Blue Negative, 
        function ListImagesInterleavedButtonPushed(app, ~)
            
            % set current image order
            app.CurrentImageOrder = 'interleaved';

            % image stack
            [~,idx] = ismember(app.MethodLists.round.interleaved,...
                app.MethodLists.round.active);
            app.Images.Bitmaps = app.Images.Bitmaps(idx);
            app.Images.Labels = app.Images.Labels(idx);
            app.Images.Indices = app.Images.Indices(idx);
            
            % update active list
            app.MethodLists.round.active = app.MethodLists.round.active(idx);
            
            % update detail drop down menus
            app.DetailDropDown1.Items = app.MethodLists.round.interleaved;
            app.DetailDropDown2.Items = app.MethodLists.round.interleaved;
            
            % memorize that the image order has changed
            app.OverviewIsUpToDate = false;
            
        end
        
        % Order images by sequential classes
        % E.g.: Vividness, LSV, Vividness Negative, LSV Negative, 
        % Vividness Blue Negative, LSV Blue Negative, 
        function ListImagesSequentialButtonPushed(app, ~)

            % set current image order
            app.CurrentImageOrder = 'sequential';

            % image stack
            [~,idx] = ismember(app.MethodLists.round.sequential,...
                app.MethodLists.round.active);
            app.Images.Bitmaps = app.Images.Bitmaps(idx);
            app.Images.Labels = app.Images.Labels(idx);
            app.Images.Indices = app.Images.Indices(idx);
            
            % update active list
            app.MethodLists.round.active = app.MethodLists.round.active(idx);

            % update detail drop down menus
            app.DetailDropDown1.Items = app.MethodLists.round.sequential;
            app.DetailDropDown2.Items = app.MethodLists.round.sequential;
            
            % memorize that the image order has changed
            app.OverviewIsUpToDate = false;
            
        end
        
    end
    
    % UI settings
    methods (Access = private)

        % Settings refere to the state of checkboxes, radio buttons, and
        % edit fields on the Enhance Tab. They are carried over from 
        % sesssion to session and thus memorize changes by users at the 
        % time of closing the app. They are saved as a JSON structure to 
        % "hierax_settings.json" file. If the file is not readable the 
        % default values, defined below, are used instead.

        % Read settings from file at app startup
        function readSettings(app)
            try
                % try reading settings from file
                fn = fullfile(app.AppPath,'hierax_settings.json');
                fid = fopen(fn,'r');
                j = textscan(fid,'%c');
                fclose(fid);
                app.Settings = jsondecode(convertCharsToStrings(j));
            catch
                % use default settings
                setDefaultSettings(app)
            end
        end

        % Write settings to file at app shutdown
        function writeSettings(app)
            
            % update settings
            app.Settings.ImageURL.read = app.ImageURL.read;
            
            app.Settings.VividnessCheckBox.Value = ...
                app.VividnessCheckBox.Value;
            app.Settings.LSVCheckBox.Value = ...
                app.LSVCheckBox.Value;
            app.Settings.AdapthisteqCheckBox.Value = ...
                app.AdapthisteqCheckBox.Value;
            app.Settings.RetinexCheckBox.Value = ...
                app.RetinexCheckBox.Value;
            app.Settings.RetinexListBox.Enable = ...
                app.RetinexListBox.Enable;
            app.Settings.RetinexListBox.Value = ...
                app.RetinexListBox.Value;
            
            app.Settings.NegativeCheckBox.Value = ...
                app.NegativeCheckBox.Value;
            app.Settings.BlueCheckBox.Value = ...
                app.BlueCheckBox.Value;

            app.Settings.MaskBackgroundCheckBox.Value = ...
                app.MaskBackgroundCheckBox.Value;
            app.Settings.BackgroundButtonGroup.Enable = ...
                app.BackgroundButtonGroup.Enable;
            app.Settings.LightBackgroundButton.Value = ...
                app.LightBackgroundButton.Value;
            app.Settings.DarkBackgroundButton.Value = ...
                app.DarkBackgroundButton.Value;
            app.Settings.ShadowsButtonGroup.Enable = ...
                app.ShadowsButtonGroup.Enable;
            app.Settings.KeepShadowsButton.Value = ...
                app.KeepShadowsButton.Value;
            app.Settings.RemoveShadowsButton.Value = ...
                app.RemoveShadowsButton.Value;
            app.Settings.RedChannelOnlyCheckBox.Value = ...
                app.RedChannelOnlyCheckBox.Value;
            
            app.Settings.JPEGCheckBox.Value =  ...
                app.JPEGCheckBox.Value;
            app.Settings.TIFFCheckBox.Value =  ...
                app.TIFFCheckBox.Value;
            app.Settings.JPEGQualityEditField.Value = ...
                app.JPEGQualityEditField.Value;

            % write settings
            j = jsonencode(app.Settings);
            fn = fullfile(app.AppPath,'hierax_settings.json');
            fid = fopen(fn,'w');
            fprintf(fid,j);
            fclose(fid);
        end
        
        % Set default settings
        function setDefaultSettings(app)

            % default settings for UI components
            app.Settings.ImageURL.read = app.ImageURL.read;
            
            app.Settings.VividnessCheckBox.Value = true;
            app.Settings.LSVCheckBox.Value = true;
            app.Settings.AdapthisteqCheckBox.Value = true;
            app.Settings.RetinexCheckBox.Value = true;
            app.Settings.RetinexListBox.Enable = 'on';
            app.Settings.RetinexListBox.Value = {'MSRCR-RGB', 'MSR-V'};
            
            app.Settings.NegativeCheckBox.Value = true;
            app.Settings.BlueCheckBox.Value = true;
            
            app.Settings.MaskBackgroundCheckBox.Value = false;
            app.Settings.BackgroundButtonGroup.Enable = 'off';
            app.Settings.LightBackgroundButton.Value = true;
            app.Settings.DarkBackgroundButton.Value = false;
            app.Settings.ShadowsButtonGroup.Enable = 'off';
            app.Settings.KeepShadowsButton.Value = true;
            app.Settings.RemoveShadowsButton.Value = false;
            app.Settings.RedChannelOnlyCheckBox.Value = false;
            
            app.Settings.JPEGCheckBox.Value = true;
            app.Settings.TIFFCheckBox.Value = false;
            app.Settings.JPEGQualityEditField.Value = app.JpegQuality;

        end
        
    end
    
    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % set root and application folders
            if isdeployed
                app.AppRoot = fullfile(ctfroot,'Hierax',filesep);
            else
                app.AppRoot = '';
            end
            app.AppPath = ...
                fullfile(app.AppRoot,'gx','enhancement','hierax',filesep);
            
            % read settings
            readSettings(app)
                            
            % check existence of saved ImgeURL directory
            if ~isfolder(app.Settings.ImageURL.read)
                app.ImageURL.read = app.Settings.ImageURL.read;
            end

            
            % -------------------------------------------------------------
            %% Figure
            % -------------------------------------------------------------
            
            % Create Figure and hide it until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.WindowStyle = 'normal'; % R2020b
            app.UIFigure.Position = [100,100,640,480];

            % center figure
            posFigNow = app.UIFigure.Position;
            screensize = get(groot, 'Screensize');
            xfig = floor((screensize(3) - posFigNow(3))/2);
            yfig = floor((screensize(4) - posFigNow(4))/2);
            wfig = posFigNow(3);
            hfig = posFigNow(4);
            app.UIFigure.Position = [xfig,yfig,wfig,hfig];
            app.UIFigure.Name = app.AppName;
            
            % keypress listner
            % (a) this disables key event capture after toolbar clicked
            % app.UIFigure.KeyPressFcn = ...
            %     createCallbackFcn(app, @UIFigureKeyPress, true);
            % (b) this maintains key event capture after toolbar clicked
            % as per: https://ch.mathworks.com/matlabcentral/answers/
            % 320351-re-enable-keypress-capture-when-de-selecting-figure
            hManager = uigetmodemanager(app.UIFigure);
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
            app.UIFigure.WindowKeyPressFcn = ...
                createCallbackFcn(app, @UIFigureKeyPress, true);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [0 0 640 480];
            app.TabGroup.SelectionChangedFcn = ...
                createCallbackFcn(app, @TabGroupSelectionChanged, true);

            % Activate Java interaction tools
            enableLegacyExplorationModes(app.UIFigure)
            
            
            % -------------------------------------------------------------
            %% Enhance Tab
            % -------------------------------------------------------------
            
            % Create EnhanceTab
            app.EnhanceTab = uitab(app.TabGroup);
            app.EnhanceTab.Title = 'Enhance';

            % Create GridLayoutEnhance1
            app.GridLayoutEnhance1 = uigridlayout(app.EnhanceTab);
            app.GridLayoutEnhance1.ColumnWidth = {'1x'};
            app.GridLayoutEnhance1.RowHeight = {'1x', 22};
            app.GridLayoutEnhance1.ColumnSpacing = 0;
            app.GridLayoutEnhance1.RowSpacing = 0;
            app.GridLayoutEnhance1.Padding = [0 0 0 0];

            % Create GridLayoutEnhance2
            app.GridLayoutEnhance2 = uigridlayout(app.GridLayoutEnhance1);
            app.GridLayoutEnhance2.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayoutEnhance2.RowHeight = {'1x'};
            app.GridLayoutEnhance2.ColumnSpacing = 0;
            app.GridLayoutEnhance2.RowSpacing = 0;
            app.GridLayoutEnhance2.Padding = [0 0 0 0];
            app.GridLayoutEnhance2.Layout.Row = 1;
            app.GridLayoutEnhance2.Layout.Column = 1;

            % Create GridLayoutEnhance3
            app.GridLayoutEnhance3 = uigridlayout(app.GridLayoutEnhance2);
            app.GridLayoutEnhance3.ColumnWidth = {'1x'};
            app.GridLayoutEnhance3.RowHeight = {'1x', '2x'};
            app.GridLayoutEnhance3.ColumnSpacing = 0;
            app.GridLayoutEnhance3.RowSpacing = 0;
            app.GridLayoutEnhance3.Padding = [0 0 0 0];
            app.GridLayoutEnhance3.Layout.Row = 1;
            app.GridLayoutEnhance3.Layout.Column = 2;

            % Create GridLayoutEnhance4
            app.GridLayoutEnhance4 = uigridlayout(app.GridLayoutEnhance2);
            app.GridLayoutEnhance4.ColumnWidth = {'1x'};
            app.GridLayoutEnhance4.RowHeight = {'1x', '1x', '1x'};
            app.GridLayoutEnhance4.ColumnSpacing = 0;
            app.GridLayoutEnhance4.RowSpacing = 0;
            app.GridLayoutEnhance4.Padding = [0 0 0 0];
            app.GridLayoutEnhance4.Layout.Row = 1;
            app.GridLayoutEnhance4.Layout.Column = 3;

            
            % ---
            % Create ProcessingPanel
            % ---
            app.ProcessingPanel = uipanel(app.GridLayoutEnhance2);
            app.ProcessingPanel.Title = '   1. Processing Methods';
            app.ProcessingPanel.FontWeight = 'bold';
            app.ProcessingPanel.Layout.Row = 1;
            app.ProcessingPanel.Layout.Column = 1;

            % Create VividnessCheckBox
            app.VividnessCheckBox = uicheckbox(app.ProcessingPanel);
            app.VividnessCheckBox.Text = 'Vividness';
            app.VividnessCheckBox.Position = [22,362,73,22];
            app.VividnessCheckBox.Value = ...
                app.Settings.VividnessCheckBox.Value;

            % Create LSVCheckBox
            app.LSVCheckBox = uicheckbox(app.ProcessingPanel);
            app.LSVCheckBox.Text = 'LSV';
            app.LSVCheckBox.Position = [22,324,44,22];
            app.LSVCheckBox.Value = ...
                app.Settings.LSVCheckBox.Value;

            % Create AdapthisteqCheckBox
            app.AdapthisteqCheckBox = uicheckbox(app.ProcessingPanel);
            app.AdapthisteqCheckBox.Text = 'Adapthisteq';
            app.AdapthisteqCheckBox.Position = [22,286,87,22];
            app.AdapthisteqCheckBox.Value = ...
                app.Settings.AdapthisteqCheckBox.Value;

            % Create RetinexCheckBox
            app.RetinexCheckBox = uicheckbox(app.ProcessingPanel);
            app.RetinexCheckBox.Text = 'Retinex';
            app.RetinexCheckBox.Position = [22,248,62,22];
            app.RetinexCheckBox.Value = ...
                app.Settings.RetinexCheckBox.Value;
            app.RetinexCheckBox.ValueChangedFcn = createCallbackFcn(app, ...
                @RetinexCheckBoxValueChanged, true);

            % Create RetinexListBox
            app.RetinexListBox = uilistbox(app.ProcessingPanel);
            app.RetinexListBox.Items = ...
                {'MSRCR-RGB', 'MSR-VAB', 'MSR-LAB', ...
                'MSR-V', 'MSR-L', ...
                'MSRCP-I', 'MSRCP-V', 'MSRCP-L', ...
                };
            app.RetinexListBox.Multiselect = 'on';
            app.RetinexListBox.Position = [38 14 148 210];
            app.RetinexListBox.Value = ...
                app.Settings.RetinexListBox.Value;
            app.RetinexListBox.Enable = ...
                app.Settings.RetinexListBox.Enable;

            
            % ---
            % Create PostprocessingPanel
            % ---
            app.PostprocessingPanel = uipanel(app.GridLayoutEnhance3);
            app.PostprocessingPanel.Title = '   2. Postprocessing';
            app.PostprocessingPanel.FontWeight = 'bold';
            app.PostprocessingPanel.Layout.Row = 1;
            app.PostprocessingPanel.Layout.Column = 1;

            % Create NegativeCheckBox
            app.NegativeCheckBox = uicheckbox(app.PostprocessingPanel);
            app.NegativeCheckBox.Text = 'Negative';
            app.NegativeCheckBox.Position = [36,76,69,22];
            app.NegativeCheckBox.Value = ...
                app.Settings.NegativeCheckBox.Value;

            % Create BlueCheckBox
            app.BlueCheckBox = uicheckbox(app.PostprocessingPanel);
            app.BlueCheckBox.Text = 'Blue Negative';
            app.BlueCheckBox.Position = [36,38,97,22];
            app.BlueCheckBox.Value = ...
                app.Settings.BlueCheckBox.Value;
            
            
            % ---
            % Create AuxiliariesPanel
            % ---
            app.AuxiliariesPanel = uipanel(app.GridLayoutEnhance3);
            app.AuxiliariesPanel.Title = '   3. Auxiliaries';
            app.AuxiliariesPanel.FontWeight = 'bold';
            app.AuxiliariesPanel.Layout.Row = 2;
            app.AuxiliariesPanel.Layout.Column = 1;

            
            % Create RedChannelOnlyCheckBox
            app.RedChannelOnlyCheckBox = uicheckbox(app.AuxiliariesPanel);
            app.RedChannelOnlyCheckBox.Text = 'Red Channel Only';
            app.RedChannelOnlyCheckBox.Position = [34 227 119 22];
            app.RedChannelOnlyCheckBox.Value = ...
                app.Settings.RedChannelOnlyCheckBox.Value;

            
            % Create MaskBackgroundCheckBox
            app.MaskBackgroundCheckBox = ...
                uicheckbox(app.AuxiliariesPanel);
            app.MaskBackgroundCheckBox.ValueChangedFcn = ...
                createCallbackFcn(app, ...
                @MaskBackgroundCheckBoxValueChanged, true);
            app.MaskBackgroundCheckBox.Text = 'Mask Background';
            app.MaskBackgroundCheckBox.Position = [34 190 120 22];
            app.MaskBackgroundCheckBox.Value = ...
                app.Settings.MaskBackgroundCheckBox.Value;

            
            % Create BackgroundButtonGroup
            app.BackgroundButtonGroup = ...
                uibuttongroup(app.AuxiliariesPanel);
            app.BackgroundButtonGroup.BorderType = 'none';
            app.BackgroundButtonGroup.Enable = ...
                app.Settings.BackgroundButtonGroup.Enable;
            app.BackgroundButtonGroup.Title = 'Background Luminance';
            app.BackgroundButtonGroup.Position = [34 98 139 73];

            % Create LightBackgroundButton
            app.LightBackgroundButton = ...
                uiradiobutton(app.BackgroundButtonGroup);
            app.LightBackgroundButton.Text = 'Light';
            app.LightBackgroundButton.Position = [11,27,49,22];

            % Create DarkBackgroundButton
            app.DarkBackgroundButton = ...
                uiradiobutton(app.BackgroundButtonGroup);
            app.DarkBackgroundButton.Text = 'Dark';
            app.DarkBackgroundButton.Position = [11,5,47,22];

            % set the value after creating all radiobuttons in the 
            % container, because you can't set the first item to false when
            % it is the only one yet created
            app.LightBackgroundButton.Value = ...
                app.Settings.LightBackgroundButton.Value;
            app.DarkBackgroundButton.Value = ...
                app.Settings.DarkBackgroundButton.Value;

            
            % Create ShadowsButtonGroup
            app.ShadowsButtonGroup = ...
                uibuttongroup(app.AuxiliariesPanel);
            app.ShadowsButtonGroup.BorderType = 'none';
            app.ShadowsButtonGroup.Enable = ...
                app.Settings.ShadowsButtonGroup.Enable;
            app.ShadowsButtonGroup.Title = 'Shadows';
            app.ShadowsButtonGroup.Position = [34 14 139 73];

            % Create KeepShadowsButton
            app.KeepShadowsButton = ...
                uiradiobutton(app.ShadowsButtonGroup);
            app.KeepShadowsButton.Text = 'Keep';
            app.KeepShadowsButton.Position = [11,27,50,22];

            % Create RemoveShadowsButton
            app.RemoveShadowsButton = ...
                uiradiobutton(app.ShadowsButtonGroup);
            app.RemoveShadowsButton.Text = 'Remove';
            app.RemoveShadowsButton.Position = [11,5,66,22];

            % set the value after creating all radiobuttons in the 
            % container, because you can't set the first item to false when
            % it is the only one yet created
            app.KeepShadowsButton.Value = ...
                app.Settings.KeepShadowsButton.Value;
            app.RemoveShadowsButton.Value = ...
                app.Settings.RemoveShadowsButton.Value;

            
            % ---
            % Create SavePanel
            % ---
            app.SavePanel = uipanel(app.GridLayoutEnhance4);
            app.SavePanel.Title = '   4. Save As';
            app.SavePanel.FontWeight = 'bold';
            app.SavePanel.Layout.Row = 1;
            app.SavePanel.Layout.Column = 1;
            
            % Create JPEGCheckBox
            app.JPEGCheckBox = uicheckbox(app.SavePanel);
            app.JPEGCheckBox.Text = 'JPEG';
            app.JPEGCheckBox.Position = [25 76 52 22];
            app.JPEGCheckBox.Value = ...
                app.Settings.JPEGCheckBox.Value;

            % Create TIFFCheckBox
            app.TIFFCheckBox = uicheckbox(app.SavePanel);
            app.TIFFCheckBox.Text = 'TIFF';
            app.TIFFCheckBox.Position = [25 36 46 22];
            app.TIFFCheckBox.Value = ...
                app.Settings.TIFFCheckBox.Value;

            % Create QualityLabel
            app.JPEGQualityLabel = uilabel(app.SavePanel);
            app.JPEGQualityLabel.Position = [124 76 58 22];
            app.JPEGQualityLabel.Text = '% Quality';

            % Create QualityEditField
            app.JPEGQualityEditField = uieditfield(app.SavePanel, 'numeric');
            app.JPEGQualityEditField.HorizontalAlignment = 'center';
            app.JPEGQualityEditField.Position = [83 76 38 22];
            app.JPEGQualityEditField.Limits = [0 100];
            app.JPEGQualityEditField.RoundFractionalValues = 'on';
            app.JPEGQualityEditField.Value = 75;
            app.JPEGQualityEditField.Value = ...
                app.Settings.JPEGQualityEditField.Value;
            app.JPEGQualityEditField.ValueChangedFcn = ...
                createCallbackFcn(app, @JPEGQualityEditFieldValueChanged, true);
            
            
            % ---
            % Create DataPanel
            % ---
            app.DataPanel = uipanel(app.GridLayoutEnhance4);
            app.DataPanel.Title = '   5. Process Images';
            app.DataPanel.FontWeight = 'bold';
            app.DataPanel.Layout.Row = 2;
            app.DataPanel.Layout.Column = 1;

            % Create SelectImagesButton
            app.SelectImagesButton = uibutton(app.DataPanel, 'push');
            app.SelectImagesButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @EnhanceImagesButtonPushed, true);
            app.SelectImagesButton.Position = [23 53 164 22];
            app.SelectImagesButton.BackgroundColor = [1 0.8 0];
            app.SelectImagesButton.Text = 'Select, Enhance, & Save';

            
            % ---
            % Create HelpPanel
            % ---
            app.HelpPanel = uipanel(app.GridLayoutEnhance4);
            app.HelpPanel.Title = ' Help';
            app.HelpPanel.FontWeight = 'bold';
            app.HelpPanel.Layout.Row = 3;
            app.HelpPanel.Layout.Column = 1;

            % Create HelpOnlineButton
            app.HelpOnlineButton = uibutton(app.HelpPanel, 'push');
            app.HelpOnlineButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @HelpOnlineButtonPushed, true);
            app.HelpOnlineButton.BackgroundColor = [1 1 1];
            app.HelpOnlineButton.Position = [23,74,71,22];
            app.HelpOnlineButton.Text = 'Online';

            % Create HelpLocalButton
            app.HelpLocalButton = uibutton(app.HelpPanel, 'push');
            app.HelpLocalButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @HelpLocalButtonPushed, true);
            app.HelpLocalButton.BackgroundColor = [1 1 1];
            app.HelpLocalButton.Position = [116,74,71,22];
            app.HelpLocalButton.Text = 'Local';

            % Create FalconImage
            app.FalconImage = uiimage(app.HelpPanel);
            app.FalconImage.Enable = 'on';
            app.FalconImage.Position = [155 14 32 32];
            app.FalconImage.ImageSource = ...
                fullfile(app.AppPath,'gui','G5-hrw.png');
            %app.FalconImage.ImageClickedFcn = ...
            %    createCallbackFcn(app, @FalconImageClicked, true);


            % ---
            % Create StatusBarLabel
            % ---
            app.StatusBarLabel = uilabel(app.GridLayoutEnhance1);
            app.StatusBarLabel.FontWeight = 'normal';
            app.StatusBarLabel.Text = '';
            app.StatusBarLabel.Layout.Row = 2;
            app.StatusBarLabel.Layout.Column = 1;
            
            
            % -------------------------------------------------------------
            %% Overview Tab
            % -------------------------------------------------------------

            % Create OverviewTab
            app.OverviewTab = uitab(app.TabGroup);
            app.OverviewTab.Title = 'Overview';
            app.OverviewTab.BackgroundColor = [0.149 0.149 0.149];

            % Create GridLayoutOverview1
            app.GridLayoutOverview1 = uigridlayout(app.OverviewTab);
            app.GridLayoutOverview1.BackgroundColor = [0.149 0.149 0.149];
            app.GridLayoutOverview1.ColumnWidth = {'1x'};
            app.GridLayoutOverview1.RowHeight = {'1x', 45};
            app.GridLayoutOverview1.ColumnSpacing = 0;
            app.GridLayoutOverview1.RowSpacing = 0;
            app.GridLayoutOverview1.Padding = [0 0 0 0];
            
            % Create GridLayoutOverview2
            app.GridLayoutOverview2 = uigridlayout(app.GridLayoutOverview1);
            app.GridLayoutOverview2.BackgroundColor = [0.149 0.149 0.149];
            app.GridLayoutOverview2.ColumnWidth = {'1x'};
            app.GridLayoutOverview2.RowHeight = {'1x'};
            app.GridLayoutOverview2.ColumnSpacing = 0;
            app.GridLayoutOverview2.RowSpacing = 0;
            app.GridLayoutOverview2.Padding = [13 13 13 13];
            
            % Create OverviewWrapperPanel
            % a panel inside a gridlayout takes the size of the grid cell,
            % but we need to change the size of OverviewPanel to the area
            % covered by the images to be displayed in it; so we create a
            % fixed size panel OverviewWrapperPanel in which we place 
            % OverviewPanel, which now can change size
            app.OverviewWrapperPanel = uipanel(app.GridLayoutOverview2);
            app.OverviewWrapperPanel.BackgroundColor = [0.149 0.149 0.149];
            app.OverviewWrapperPanel.BorderType = 'none';
            app.OverviewWrapperPanel.Visible = 'on';
            app.OverviewWrapperPanel.Scrollable = 'on';
            app.OverviewWrapperPanel.Layout.Row = 1;
            app.OverviewWrapperPanel.Layout.Column = 1;
            
            % Create OverviewPanel
            app.OverviewPanel = uipanel(app.OverviewWrapperPanel);
            app.OverviewPanel.BackgroundColor = [0.149 0.149 0.149];
            app.OverviewPanel.BorderType = 'none';
            app.OverviewPanel.Visible = 'off';
            app.OverviewPanel.Position = [13, 13, ...
                app.OverviewWrapperPanel.Position(3) - 13 - 13,...
                app.OverviewWrapperPanel.Position(4) - 13 - 13];

            % Create OverviewToolsPanel
            app.OverviewToolsPanel = uipanel(app.GridLayoutOverview1);
            app.OverviewToolsPanel.BackgroundColor = [0.149 0.149 0.149];
            app.OverviewToolsPanel.BorderType = 'none';
            app.OverviewToolsPanel.Visible = 'on';
            app.OverviewToolsPanel.Layout.Row = 2;
            app.OverviewToolsPanel.Layout.Column = 1;

            % Create SaveOverviewButton
            app.SaveOverviewButton = ...
                uibutton(app.OverviewToolsPanel, 'push');
            app.SaveOverviewButton.BackgroundColor = ...
                [0.149 0.149 0.149];
            app.SaveOverviewButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @SaveOverview, true);
            app.SaveOverviewButton.Enable = 'off';
            app.SaveOverviewButton.FontColor = [1 1 1];
            app.SaveOverviewButton.Position = [39,12,100,22];
            app.SaveOverviewButton.Text = 'Save Overview';

            % Create LoadImagesInViewerButton
            app.LoadImagesInViewerButton = ...
                uibutton(app.OverviewToolsPanel, 'push');
            app.LoadImagesInViewerButton.BackgroundColor = ...
                [0.149 0.149 0.149];
            app.LoadImagesInViewerButton.ButtonPushedFcn = ...
                createCallbackFcn(app, ...
                @LoadImagesInViewerButtonPushed, true);
            app.LoadImagesInViewerButton.FontColor = [1 1 1];
            app.LoadImagesInViewerButton.Position = [497,12,100,22];
            app.LoadImagesInViewerButton.Text = 'View Images';
            app.LoadImagesInViewerButton.Tooltip = ...
                {'Compare two or more images without enhancing them.'};


            % -------------------------------------------------------------
            %% Detail Tab
            % -------------------------------------------------------------
            
            % Create DetailTab
            app.DetailTab = uitab(app.TabGroup);
            app.DetailTab.Title = 'Detail';
            app.DetailTab.BackgroundColor = [0.149 0.149 0.149];

            % Create DetailPanel1
            app.DetailPanel1 = uipanel(app.DetailTab);
            app.DetailPanel1.BorderType = 'none';
            app.DetailPanel1.BackgroundColor = [0.149 0.149 0.149];
            app.DetailPanel1.Position = [1,80,313,330];

            % Create DetailPanel2
            app.DetailPanel2 = uipanel(app.DetailTab);
            app.DetailPanel2.BorderType = 'none';
            app.DetailPanel2.BackgroundColor = [0.149 0.149 0.149];
            app.DetailPanel2.Position = [320,80,313,330];

            
            % Create DetailDropDown1
            app.DetailDropDown1 = uidropdown(app.DetailTab);
            app.DetailDropDown1.Items = {''};
            app.DetailDropDown1.ValueChangedFcn = ...
                createCallbackFcn(app, @DetailDropDown1ValueChanged, true);
            app.DetailDropDown1.Position = [15 12 298 22];
            app.DetailDropDown1.Value = {''};

            % Create DetailDropDown2
            app.DetailDropDown2 = uidropdown(app.DetailTab);
            app.DetailDropDown2.Items = {''};
            app.DetailDropDown2.ValueChangedFcn = ...
                createCallbackFcn(app, @DetailDropDown2ValueChanged, true);
            app.DetailDropDown2.Position = [327 12 298 22];
            app.DetailDropDown2.Value = {''};

            % ---
            % Interaction tools
            % ---
            
            % Create InteractionToolsPanel
            app.InteractionToolsPanel = uipanel(app.DetailTab);
            app.InteractionToolsPanel.ForegroundColor = [0.149 0.149 0.149];
            app.InteractionToolsPanel.BorderType = 'none';
            app.InteractionToolsPanel.BackgroundColor = [0.149 0.149 0.149];
            app.InteractionToolsPanel.Position = [1 410 638 46];

            % Create ZoomButton
            app.ZoomButton = uibutton(app.InteractionToolsPanel, 'state');
            app.ZoomButton.Position = [15 13 90 22];
            app.ZoomButton.Text = 'Zoom';
            app.ZoomButton.Tooltip = ...
                {'Click Or Shift-Click Image'};
            app.ZoomButton.ValueChangedFcn = ...
                createCallbackFcn(app, @ZoomButtonValueChanged, true);
            app.ZoomButton.FontColor = [1 1 1];
            app.ZoomButton.BackgroundColor = [0.149 0.149 0.149];

            % Create PanButton
            app.PanButton = uibutton(app.InteractionToolsPanel, 'state');
            app.PanButton.Position = [119 13 90 22];
            app.PanButton.Text = 'Pan';
            app.PanButton.Tooltip = {'Drag Image'};
            app.PanButton.ValueChangedFcn = ...
                createCallbackFcn(app, @PanButtonValueChanged, true);
            app.PanButton.FontColor = [1 1 1];
            app.PanButton.BackgroundColor = [0.149 0.149 0.149];

            % Create RotateButton
            app.RotateButton = uibutton(app.InteractionToolsPanel, 'state');
            app.RotateButton.Position = [223 13 90 22];
            app.RotateButton.Text = 'Rotate';
            app.RotateButton.Tooltip = {'Press The Arrow-Keys'};
            app.RotateButton.ValueChangedFcn = ...
                createCallbackFcn(app, @RotateButtonValueChanged, true);
            app.RotateButton.FontColor = [1 1 1];
            app.RotateButton.BackgroundColor = [0.149 0.149 0.149];
            
            % Create ResetButton
            app.ResetButton = uibutton(app.InteractionToolsPanel, 'push');
            app.ResetButton.Position = [327 13 90 22];
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Tooltip = {'Click Me'};
            app.ResetButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.FontColor = [1 1 1];
            app.ResetButton.BackgroundColor = [0.149 0.149 0.149];

            % ---
            % Displayed image change buttons
            % ---

            % Create PreviousButton
            app.PreviousButton = uibutton(app.InteractionToolsPanel, 'push');
            app.PreviousButton.BackgroundColor = [0.149 0.149 0.149];
            app.PreviousButton.FontColor = [1 1 1];
            app.PreviousButton.Position = [431 13 90 22];
            app.PreviousButton.Text = 'Previous';
            app.PreviousButton.Tooltip = {'Press The Arrow-Keys'};
            app.PreviousButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @PreviousButtonPushed, true);
            
            % Create NextButton
            app.NextButton = uibutton(app.InteractionToolsPanel, 'push');
            app.NextButton.FontColor = [1 1 1];
            app.NextButton.BackgroundColor = [0.149 0.149 0.149];
            app.NextButton.Position = [535 13 90 22];
            app.NextButton.Text = 'Next';
            app.NextButton.Tooltip = {'Press The Arrow-Keys'};
            app.NextButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @NextButtonPushed, true);

            % ---
            % Image ordering buttons
            % ---

            % Create MoveImagePanel
            app.MoveImagePanel = uipanel(app.DetailTab);
            app.MoveImagePanel.ForegroundColor = [0.149 0.149 0.149];
            app.MoveImagePanel.BorderType = 'none';
            app.MoveImagePanel.BackgroundColor = [0.149 0.149 0.149];
            app.MoveImagePanel.Position = [1 41 427 30];

            % Create MoveImageToTopButton
            app.MoveImageToTopButton = uibutton(app.MoveImagePanel, 'push');
            app.MoveImageToTopButton.BackgroundColor = [0.149 0.149 0.149];
            app.MoveImageToTopButton.FontColor = [1 1 1];
            app.MoveImageToTopButton.Tooltip = {'Press The T-Key'};
            app.MoveImageToTopButton.Position = [15 6 90 22];
            app.MoveImageToTopButton.Text = 'To Top';
            app.MoveImageToTopButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @MoveImageToTopButtonPushed, true);

            % Create MoveImageUpButton
            app.MoveImageUpButton = uibutton(app.MoveImagePanel, 'push');
            app.MoveImageUpButton.BackgroundColor = [0.149 0.149 0.149];
            app.MoveImageUpButton.FontColor = [1 1 1];
            app.MoveImageUpButton.Tooltip = {'Press The U-Key'};
            app.MoveImageUpButton.Position = [119 6 90 22];
            app.MoveImageUpButton.Text = 'Up';
            app.MoveImageUpButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @MoveImageUpButtonPushed, true);

            % Create MoveImageDownButton
            app.MoveImageDownButton = uibutton(app.MoveImagePanel, 'push');
            app.MoveImageDownButton.BackgroundColor = [0.149 0.149 0.149];
            app.MoveImageDownButton.FontColor = [1 1 1];
            app.MoveImageDownButton.Tooltip = {'Press The D-Key'};
            app.MoveImageDownButton.Position = [223 6 90 22];
            app.MoveImageDownButton.Text = 'Down';
            app.MoveImageDownButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @MoveImageDownButtonPushed, true);

            % Create MoveImageToBottomButton
            app.MoveImageToBottomButton = uibutton(app.MoveImagePanel, 'push');
            app.MoveImageToBottomButton.BackgroundColor = [0.149 0.149 0.149];
            app.MoveImageToBottomButton.FontColor = [1 1 1];
            app.MoveImageToBottomButton.Tooltip = {'Press The B-Key'};
            app.MoveImageToBottomButton.Position = [327 6 90 22];
            app.MoveImageToBottomButton.Text = 'To Bottom';
            app.MoveImageToBottomButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @MoveImageToBottomButtonPushed, true);

            
            % Create ReorderImagesPanel
            app.ReorderImagesPanel = uipanel(app.DetailTab);
            app.ReorderImagesPanel.ForegroundColor = [0.149 0.149 0.149];
            app.ReorderImagesPanel.BorderType = 'none';
            app.ReorderImagesPanel.BackgroundColor = [0.149 0.149 0.149];
            app.ReorderImagesPanel.Position = [427 41 209 30];

            % Create ListImagesSequentialButton
            app.ListImagesSequentialButton = uibutton(app.ReorderImagesPanel, 'push');
            app.ListImagesSequentialButton.BackgroundColor = [0.149 0.149 0.149];
            app.ListImagesSequentialButton.FontColor = [1 1 1];
            app.ListImagesSequentialButton.Tooltip = {'Press The S-Key'};
            app.ListImagesSequentialButton.Position = [5 6 90 22];
            app.ListImagesSequentialButton.Text = 'Sequential';
            app.ListImagesSequentialButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @ListImagesSequentialButtonPushed, true);

            % Create ListImagesInterleavedButton
            app.ListImagesInterleavedButton = uibutton(app.ReorderImagesPanel, 'push');
            app.ListImagesInterleavedButton.BackgroundColor = [0.149 0.149 0.149];
            app.ListImagesInterleavedButton.FontColor = [1 1 1];
            app.ListImagesInterleavedButton.Tooltip = {'Press The I-Key'};
            app.ListImagesInterleavedButton.Position = [109 6 90 22];
            app.ListImagesInterleavedButton.Text = 'Interleaved';
            app.ListImagesInterleavedButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @ListImagesInterleavedButtonPushed, true);

            % ---
            %% About Tab
            % -------------------------------------------------------------

            % Create AboutTab
            app.AboutTab = uitab(app.TabGroup);
            app.AboutTab.Title = 'About';

            % Create VersionLabel
            app.VersionLabel = uilabel(app.AboutTab);
            app.VersionLabel.HorizontalAlignment = 'left';
            app.VersionLabel.Position = [15 15 169 22];
            app.VersionLabel.Text = ['Version ', app.AppVersion];

            % Create AboutHTML
            app.AboutHTML = uihtml(app.AboutTab);
            app.AboutHTML.Position = [15,54,608,388];
            app.AboutHTML.HTMLSource = ...
                fullfile(app.AppPath,'gui','about.html');

            
            % ---
            %% Finish
            % -------------------------------------------------------------
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
        end
        
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = hierax

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            
            % reset patch
            noVanishingImagesReset

            % write settings to file to retrive them at next sartup
            writeSettings(app)
            
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
    
end


