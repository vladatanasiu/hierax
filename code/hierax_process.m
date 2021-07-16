function [ImagesOut, firstImage, imurl, uistatus, firstImageGrayscale, ...
    abort] = hierax_process(do, jpegFormat, tiffFormat, firstImage, ...
    appRoot, dirwrite, imurl, jpegQuality, hFigure)
%HIERAX_ENHANCE Enhance the legibility of papyri images
%
% This is a subfunction of the Hierax app (main file hierax.m), containing
% the image processing functions of the software. The purpose of the
% software is to enhance the legibility of papyri images using color 
% processing and optical illusions. Please refer to the Hierax HTML help 
% file for more information.
%
% -------------
% INPUT
% -------------
%
% do        - structure specifying processing parameters
%
%           - do.mask: {false} | true
%           logical true if the papyrus is to be segmented from background 
%           before enhancement, which may improve the enhancement
%           - do.maskBackground = {'lightBackground'} | 'darkBackground'
%           specifies the lightness of the papyrus background; it affects
%           the quality of the mask
%           - do.deshadow: {false} | true
%           logical true if shadows in the image are to be removed, which 
%           may improve papyrus/background segmentation
%
%           - do.[·], where [·] are fields specifying the enhancement 
%           methods to use; each field takes logical true or false as 
%           value; the fields are: vivdness, lsv, adapthisteq, retinex, 
%           negative, blue
% 
% jpegFormat - logical, specifying if to save images in JPEG format
%
% tiffFormat - logical, specifying if to save images in TIFF format
%
% firstImage - structure specifying data about the first image to process
%           - firstImage.is: {false} | true
%           specifies whether an image in a list of images to be processed
%           is not the first in the list; only the first image in the list
%           is memorized
%           - firstImage.filename: string
%           file name of the first image
%
% appRoot   - root path of the application
%
% dirwrite   - name of directory where the images are saved; 
%            default: "enhanced"
%
% imurl     - structure specifying the URL of the last processed image
%           imurl.read: from where the image was read
%           imurl.write: where the image was written
%
% jpegQuality - JPEG quality of saved images; scalar; default: 75
%
% hFigure   - handle of Hierax figure; used for UI dialog figures
%
% ASSUMPTIONS:
% Images are assumed to have bit depth of 8 bits and of class uint8.
%
% -------------
% OUTPUT
% -------------
%
% ImagesOut.Bitmaps  - cell array holding the enhanced images
%
% ImagesOut.Labels  - labels of the enhanced images
%
% ImagesOut.Indices - indices of the enhanced images (1 ... n);
%                     used for reordering overview images
%
% firstImage - updated structure containing the file name of the first
%           processed image
%
% imurl     - structure specifying the URL of the first processed image
%           imurl.read: from where the image was read
%           imurl.write: where the image was written
%
% uistatus  - character array containing a message to the user; to be
%           displayed on the GUI status bar
%
% firstImageGrayscale - structure; defining is the first image is grayscale
%           and if it was processed
%
%           firstImageGrayscale.is: logical; true if the image is
%                grayscale, false if it is a color image
%           firstImageGrayscale.processed: logical; true if the image
%                was enhanced, false otherwise
%
% abort     - logical; true if the user aborted the enhancement process by
%           pressing the cancel button on the waitbar
%
% -------------
% METHODS
% -------------
% The technical aspects of the image processing methods used in Hierax and 
% their evaluation through a user experiment are described in the following 
% paper: Vlad Atanasiu, Isabelle Marthot-Santaniello, “Legibility 
% Enhancement of Papyri Using Color Processing and Visual Illusions: A 
% Case Study in Critical Vision”, submitted for publication.
%
% -------------
% ALGORITHM
% -------------
% A papyri legibility enhancement algorithm is presented here. As an 
% example is taken the vividness method, with gamut expansion, dynamic 
% range stretching, negative polarity, and blue shift. This contains most 
% proposed methods, with the exception of lsv and retinex. Note that the 
% elements of the retinex method and their sequence are critical to the
% outcome (particularly striking for the normalization of the dynamic 
% range of images). The references below refer to sections in the paper by 
% Atanasiu & Marthot-Santaniello.
% 
% — input
% read RGB image values
%
% — color gamut expansion (Section 4.2)
% convert color profile using ICC profiles
% · source color space: sRGB IEC 61966-2.1
% · target color space: Adobe RGB (1998)
% · source render intent: perceptual
% · target render intent: perceptual
%
% — use a perceptual color space for enhancement (§ 4.3)
% convert color space to CIELAB
% · source color space: sRGB IEC 61966-2.1
% · whitepoint: D65
%
% — vividness enhancement (§ 4.5)
% replace lightness by vividness (Eq. 3)
% L*′ = (L*^2 + a*^2 + b*^2)^(−1/2)
%
% — dynamic range increase (§ 4.3)
% stretch dynamic range of lightness to bounds (Eq. 1)
% L*′ = [L* − min(L*)] / {max[L* − min(L*)]}
%
% — negative polarity (§ 4.4)
% reverse lightness polarity (Eq. 2)
% L*′ = 100 − L*
%
% — blue shift (§ 4.7)
% change sign of values in chromatic channels (Eq. 8)
% a*′ = −a* and b*′ = −b*
%
% — back-conversion to primary colors space
% convert color space to RGB
% · source color space: sRGB IEC 61966-2.1
% · whitepoint: D65
%
% – manage out-of-gamut values
% clip values to the [0, 1] range
%
% — output
% save image in TIFF or JPEG format
%
% — make color profile explicit
% embed ICC color profile in image file
% · color space: sRGB IEC 61966-2.1
%
% -------------
% LOG
% -------------
% 2020.12.29 - [fix] multichannel images are checked for identical channels
% 2020.12.21 - [fix] on Windows, writes correctly unreadable files
% 2020.12.18 - [new] handles multi-channel images
%            - [new] outputs names of unreadable images to a text file
% 2020.12.09 - [new] implements retinex MSR-A method for color images
% 2020.11.05 - [new] detection of pseudo-color images (identical channels)
%            - [new] output directory renamed to 'enhanced'
% 2020.10.26 - latest update
% 2019.12.02 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/
%
% Includes open source code by:
%
% Harvey, Phil (2020). ExifTool, Version 12.01, retrieved June 24, 2020, 
% https://exiftool.org.
%
% Schivre, Geoffrey (2020). "Multiscale Retinex", MATLAB Central File 
% Exchange, retrieved July 8, 2020, https://www.mathworks.com/
% matlabcentral/fileexchange/71386-multiscale-retinex.
%
% Tordoff, Ben (2020). "multiWaitbar", MATLAB Central File 
% Exchange, retrieved September 18, 2020, https://www.mathworks.com/
% matlabcentral/fileexchange/26589-multiwaitbar.



    % ---------------------------------------------------------------------
    %%   PARAMETERS
    % ---------------------------------------------------------------------

    if nargin < 1 || isempty(do)
        % image processing methods

        % background masking
        do.mask = false;
        do.maskBackground = 'lightBackground';
        do.deshadow = false;

        % enhancement methods to apply
        do.vividness = true;
        do.vividnessNegative = true;
        do.vividnessNegativeBlue = true;

        do.lsv = true;
        do.lsvNegative = true;
        do.lsvNegativeBlue = true;

        do.adapthisteq = false;
        do.adapthisteqNegative = false;
        do.adapthisteqNegativeBlue = false;
        
        do.retinex = false;            
        do.retinexMethods = {};            

    end

    if nargin < 2 || isempty(jpegFormat)

        % output file format
        fileFormat.jpeg = true;
    else
        fileFormat.jpeg = jpegFormat;        
    end

    if nargin < 3 || isempty(tiffFormat)

        % output file format
        fileFormat.tiff = false;
    else
        fileFormat.tiff = tiffFormat;        
    end

    if nargin < 4 || isempty(firstImage)

        % information about first processed file
        firstImage.is = true;
        firstImage.filename = '';
    end

    if nargin < 5 || isempty(appRoot)

        % path of application root
        appRoot = '';
    end

    if nargin < 6 || isempty(dirwrite)

        % directory where the output images will be written
        dirwrite = 'enhanced';
    end
    
    if nargin < 7 || isempty(imurl)

        % directory selected by user
        imurl.read = ['.',filesep];
        imurl.write = ['.',filesep,dirwrite,filesep];
    end

    if nargin < 8 || isempty(jpegQuality)

        % JPEG quality of saved images
        jpegQuality = 75;
    end

    if nargin < 9 || isempty(hFigure)

        % handle of Hierax figure
        hFigure = gcf;
    end
    
    % ---------------------------------------------------------------------
    % define outputs to avoid Matlab throwing an error
    uistatus = '';
    firstImageGrayscale.is = false;
    firstImageGrayscale.processed = false;
    abort = false;

    % ---------------------------------------------------------------------
    % static and dynamic parameters
    
    % image precision
    precision = 2^8 - 1;

    % enhanced images and their names are memorized for visualization
    ImagesOut.Bitmaps = {};
    ImagesOut.Labels = {};
    ImagesOut.Indices = {};

    % file names
    do.deshadowlabel = '';
    do.masklabel = '';

    % number of enhacement processes
    nRetinex = 1;
    if iscell(do.retinexMethods)
        nRetinex = numel(do.retinexMethods);
    end
    nRetinex = nRetinex*do.retinex;
    nMethods = (do.mask + 1) * ...
        (do.vividness + do.lsv + do.adapthisteq + nRetinex) * ...
        (do.negative + do.blue + 1);
    kMethods = 1;
    dMethods = kMethods/nMethods;


    % ---------------------------------------------------------------------
    %%   BATCH
    % ---------------------------------------------------------------------

    % select images for enhancement from the directory last used
    [image_path,~,~] = fileparts(imurl.read);
    [image_file,image_path] = uigetfile(...
       [image_path,filesep,'*.*'],...
       'Select One or More Files', 'MultiSelect', 'on');
    
    % catch if user pressed the Cancel button
    if isa(image_file,'double')
        return
    end

    % create folder for enhanced images
    [mkdir_status,mkdir_msg] = mkdir([image_path,dirwrite]);
    if mkdir_status == 0
        uialert(hFigure,mkdir_msg,'Error','Icon','error');
        return
    end
    
    % write urls of unreadble images to a file
    fn = 'log unreadable images.txt';
    imageReadError.counter = 0;
    imageReadError.fileUrl = [image_path,dirwrite,filesep,fn];

    % loop through image list
    multiWaitbar('Reading Images',0);
    if iscell(image_file)
        nImages = length(image_file); % multiple images
    else
        nImages = 1; % single image
    end
    dImages = 1/nImages; % waitbar increment

    for kImages = 1:nImages

        % read image
        if nImages == 1
            imurl.read = [image_path,image_file];
            imurl.write = [image_path,dirwrite,filesep,image_file];
            firstImage.filename = image_file;
        else
            imurl.read = [image_path,image_file{kImages}];
            imurl.write = [image_path,dirwrite,filesep,...
                image_file{kImages}];
            
            % memorize the name of the first file
            if kImages == 1
                firstImage.filename = image_file{kImages};
            end
        end

        try
            I = imread(imurl.read);
        catch
            
            % increment counter of unreadble images
            imageReadError.counter = imageReadError.counter + 1;

            % delete any preexisting error log file
            status = exist(imageReadError.fileUrl,'file');
            if status == 2
                delete(imageReadError.fileUrl)
            end

            % log name of unreadable image to an error file
            s = [replace(imurl.read,'\','\\'),'\n'];
            fid = fopen(imageReadError.fileUrl,'at');
            fprintf(fid, s);
            fclose(fid);

            % skip this image
            continue
        end

        % memorize if we deal with grayscale images
        % -
        % flag if a grayscale image was processed with any method so that 
        % we can display it
        grayscale.is = false;
        grayscale.processed = false;
        grayscale.red = false;
        
        % multi-channel images > retain only the first three ones;
        % such images may also be due to a transparency (alpha) channel
        if size(I,3) > 3
            I = I(:,:,1:3);
        end
        
        % determine if image is grayscale or color
        switch size(I,3)
            case 1
                % image has a single channels > grayscale
                grayscale.is = true;
                
            case 2
                % two-channel images > add a null valued third channel
                J = zeros(size(I,1),size(I,2));
                I = cat(3,I,J);
                
            case 3
                if isequal(I(:,:,1), I(:,:,2)) && ...
                        isequal(I(:,:,1), I(:,:,3))
                    
                    % all channels have identical values > grayscale image
                    I = I(:,:,1);
                    grayscale.is = true;
                    
                else
                    % channels are different > color image
                end
        end
        
        % retain only the red channel (assumed to be the first channel)
        if grayscale.is == false && do.red == true
            I = I(:,:,1);
            grayscale.is = true;
            grayscale.red = true;
        end

        % memorize the first image if requested
        if kImages ~= 1
            firstImage.is = false;
        end

        
        % - process image
        multiWaitbar('Enhancing Images',0,'CanCancel','on');

        [ImagesOut, uistatus, kMethods, grayscale, abort] = improc(...
            I, imurl, do, dMethods, kMethods, ...
            fileFormat, firstImage, ImagesOut, grayscale, ...
            precision, appRoot, jpegQuality, hFigure);

        % memorize if first image is grayscale and if it was processed
        if kImages == 1
            firstImageGrayscale.is = grayscale.is;
            firstImageGrayscale.processed = grayscale.processed;
        end
        
        % stop processing if user pressed the waitbar cancel button
        if abort == true
            multiWaitbar('Enhancing Images','Close');
            break
        end

        
        % - process image without masking
        if do.mask == true

            do.mask = false;
            [ImagesOut, uistatus, kMethods, grayscale, abort] = improc(...
                I, imurl, do, dMethods, kMethods, ...
                fileFormat, firstImage, ImagesOut, grayscale, ...
                precision, appRoot, jpegQuality, hFigure);
            
            % reset masking status for next image enhancement
            do.mask = true;

            if abort == true
                multiWaitbar('Enhancing Images','Close');
                break
            end
        end

        
        % end enhancing process
        multiWaitbar('Enhancing Images','Close');
        multiWaitbar('Reading Images','Increment',dImages);
    end
                        
    % notify user that some images could not be read
    if imageReadError.counter ~= 0
        
        del = '';
        if ~isempty(uistatus)
            del = ' – ';
        end
        
        plural = 's';
        if imageReadError.counter == 1
            plural = '';
        end

        uistatus = [uistatus,del,num2str(imageReadError.counter),...
            '/',num2str(nImages),' unreadable image',plural];
    else
        % remove image read error file if all images have been read
        status = exist(imageReadError.fileUrl,'file');
        if status == 2
            delete(imageReadError.fileUrl)
        end
    end

    multiWaitbar('Reading Images','Close');

end



% =========================================================================
%%   ENHANCEMENT
% =========================================================================
function [ImagesOut, uistatus, kMethods, grayscale, abort] = improc(...
    I, imurl, do, dMethods, kMethods, fileFormat, firstImage, ...
    ImagesOut, grayscale, precision, appRoot, jpegQuality, hFigure)

    % preparations
    uistatus = '';
    abort = false;

    
    % ---------------------------------------------------------------------
    %% gamut expansion
    % ---------------------------------------------------------------------

    if grayscale.is == false && do.processing == true
    % grayscale images have no gamut to expand; additionally, if you apply
    % icc color profile conversion on an achromatic RGB image you produce
    % chromatic values, which should not be the case
    
        gamutexpansion = true;
        
        % color profiles
        icc_url_sRGB = fullfile(appRoot,...
            '3p','images','color','color profiles','sRGB Profile.icc');
        icc_url_AdobeRGB = fullfile(appRoot,...
            '3p','images','color','color profiles','AdobeRGB1998.icc');
        try
            src_profile = iccread(icc_url_sRGB);
        catch
            uialert(hFigure,['Chromatic contrast using color gamut ',...
                'expansion not applied, because could not read color '...
                'profile from file <sRGB Profile.icc> or file not found.'],...
                'Error','Icon','error');
            gamutexpansion = false;
        end
        try
            dest_profile = iccread(icc_url_AdobeRGB);
        catch
            uialert(hFigure,['Chromatic contrast using color gamut ',...
                'expansion not applied, because could not read color '...
                'profile from file <AdobeRGB1998.icc> or file not found.'],...
                'Error','Icon','error');
            gamutexpansion = false;
        end

        % intent
        % Perceptual, AbsoluteColorimetric, RelativeColorimetric, Saturation
        src_intent = 'Perceptual';
        dest_intent = 'Perceptual';

        % convert profile
        if gamutexpansion == true
            C = makecform('icc', dest_profile, src_profile,...
                'SourceRenderingIntent', src_intent, ...
                'DestRenderingIntent', dest_intent);
            I = applycform(I,C);
        end
        
    end

    % ---------------------------------------------------------------------
    %% convert to CIELAB and get lightness
    % ---------------------------------------------------------------------
    if grayscale.is == false
        
        LAB = rgb2lab(I,'ColorSpace','srgb','WhitePoint','d65');
        L = LAB(:,:,1);
        L = rescale(L); % range [0 1]
    end

    % ---------------------------------------------------------------------
    %% mask background
    % ---------------------------------------------------------------------
    if do.mask == true

        if grayscale.is == false
            % remove shadows
            L2 = L;
            if do.deshadow == true

                % make color-invariant image by normalizing pixel values
                % Theo Gevers et al. (2012), Color in Computer Vision, 
                % Hoboken, NJ: John Wiley & Sons, p. 49–52.
                I2 = double(I);
                S = sum(I,3) + eps; % add eps to avoid division by zero
                R = I2(:,:,1)./S;
                G = I2(:,:,2)./S;
                B = I2(:,:,3)./S;
                I2 = cat(3,R,G,B);

                % get lightness
                LAB2 = ...
                    rgb2lab(I2,'ColorSpace','srgb','WhitePoint','d65');
                L2 = LAB2(:,:,1);
                L2 = rescale(L2); % range [0 1]

                % file names
                do.deshadowlabel = 'deshadowed';
            end

            % mask background
            BW = maskbkgd(L2,do,imurl);
            BW3 = cat(3,BW,BW,BW);

            % memorize background for etching back into image
            LAB_background = LAB;
            LAB_background(BW3 == 1) = -Inf;
            L_background = L;
            L_background(BW == 1) = -Inf;

            % fuse mask and image
            LAB(BW3 == 0) = NaN;
            L(BW == 0) = NaN;
            
        else
            if do.adapthisteq == true || do.retinex == true
                % grayscale images
                BW = maskbkgd(I,do,imurl);
                I_background = double(I)/precision;
                I_background(BW == 1) = -Inf;
                I(BW == 0) = NaN;
            end
        end

        % file names
        do.masklabel = 'masked';
    end

    
    % ---------------------------------------------------------------------
    % CIELAB vivdness
    % .....................................................................
    %% vividness
    % ---------------------------------------------------------------------
    if do.vividness == true && grayscale.is == false
        % some parts of this method are used by other methods, so we need to
        % run it for those methods: negvividness and blue

        L2 = sqrt(sum(LAB.^2,3)); % CIELAB vividness = L2-norm
        L2 = rescale(L2);

        % reinsert background mask
        LAB3 = LAB;
        L3 = L2;
        if do.mask == true
            LAB3 = max(LAB3,LAB_background);
            L3 = max(L3,L_background);
        end

        % switch new and old L in LAB image and convert to RGB
        I2 = l2ab2rgb(L3,LAB3);

        % save image
        label = 'vividness';
        icc_status = imwritewrap(I2,imurl,label,do,...
            fileFormat, grayscale, appRoot, jpegQuality);
        
        % output a message if the color profile could not be embedded
        if ~isempty(icc_status)
            uistatus = icc_status;
        end

        % memorize image
        if firstImage.is == true
            ImagesOut.Bitmaps{kMethods} = I2;
            label = 'Vividness';
            if do.mask == true
                label = [label,' Masked'];
            end
            ImagesOut.Labels{kMethods} = label;
            ImagesOut.Indices{kMethods} = kMethods;
        end

        abort = multiWaitbar('Enhancing Images','Increment',dMethods);
        if abort == true
            abortCheck = uiconfirm(hFigure,...
                'Stop processing?','Confirm Stop',...
                'Options',{'Yes','No'},...
                'DefaultOption',1,'CancelOption',2,...
                 'Icon','question');
            if strcmp(abortCheck,'Yes')
                return
            else
                multiWaitbar('Enhancing Images','ResetCancel');
            end
        end
        kMethods = kMethods+1;

    end

    % ---------------------------------------------------------------------
    %% vividness negative lightness
    % ---------------------------------------------------------------------
    if (do.vividness == true && (do.negative == true || ...
            do.blue == true)) && grayscale.is == false

        % negative
        L2 = 1 - L2;

        if do.negative == true
            
            % reinsert background mask
            LAB3 = LAB;
            L3 = L2;
            if do.mask == true
                LAB3 = max(LAB3,LAB_background);
                L3 = max(L3,L_background);
            end

            I2 = l2ab2rgb(L3,LAB3);
            label = 'vividness-neg';
            icc_status = imwritewrap(I2,imurl,label,do,...
                fileFormat, grayscale, appRoot, jpegQuality);
            if ~isempty(icc_status)
                uistatus = icc_status;
            end
            if firstImage.is == true
                ImagesOut.Bitmaps{kMethods} = I2;
                label = 'Vividness Negative';
                if do.mask == true
                    label = [label,' Masked'];
                end
                ImagesOut.Labels{kMethods} = label;
                ImagesOut.Indices{kMethods} = kMethods;
            end

            abort = multiWaitbar('Enhancing Images','Increment',dMethods);
            if abort == true
                abortCheck = uiconfirm(hFigure,...
                    'Stop processing?','Confirm Stop',...
                    'Options',{'Yes','No'},...
                    'DefaultOption',1,'CancelOption',2,...
                     'Icon','question');
                if strcmp(abortCheck,'Yes')
                    return
                else
                    multiWaitbar('Enhancing Images','ResetCancel');
                end
            end
            kMethods = kMethods+1;
        end
    end

    % ---------------------------------------------------------------------
    %% vividness negative blue
    % ---------------------------------------------------------------------
    if (do.vividness == true && do.blue == true) && grayscale.is == false

        % change of sign
        A2 = -LAB(:,:,2);
        B2 = -LAB(:,:,3);

        % reinsert background mask
        L3 = L2;
        if do.mask == true
            A2 = max(A2,LAB_background(:,:,2));
            B2 = max(B2,LAB_background(:,:,3));
            L3 = max(L3,L_background);
        end

        % back to RGB
        LAB2 = cat(3,100*L3,A2,B2);
        I2 = l2ab2rgb(L3,LAB2);

        % write image
        label = 'vividness-neg-blue';
        icc_status = imwritewrap(I2,imurl,label,do,...
            fileFormat, grayscale, appRoot, jpegQuality);
        if ~isempty(icc_status)
            uistatus = icc_status;
        end
        if firstImage.is == true
            ImagesOut.Bitmaps{kMethods} = I2;
            label = 'Vividness Blue Negative';
            if do.mask == true
                label = [label,' Masked'];
            end
            ImagesOut.Labels{kMethods} = label;
            ImagesOut.Indices{kMethods} = kMethods;
        end

        abort = multiWaitbar('Enhancing Images','Increment',dMethods);
        if abort == true
            abortCheck = uiconfirm(hFigure,...
                'Stop processing?','Confirm Stop',...
                'Options',{'Yes','No'},...
                'DefaultOption',1,'CancelOption',2,...
                 'Icon','question');
            if strcmp(abortCheck,'Yes')
                return
            else
                multiWaitbar('Enhancing Images','ResetCancel');
            end
        end
        kMethods = kMethods+1;
    end


    % ---------------------------------------------------------------------
    % lightness and difference of saturation and value
    % .....................................................................
    %% LSV
    % ---------------------------------------------------------------------
    if do.lsv == true && grayscale.is == false

        HSV = rgb2hsv(I); % range [0 1]
        S = HSV(:,:,2);
        V = HSV(:,:,3);
        S = 1 - S; % negative
        SV = abs(V - S); % difference of saturation and value (DSV)
        if do.mask == true
            SV(BW == 0) = NaN; % mask background to improve rescaling
        end
        SV = rescale(SV);
        L2 = 100 - L; % negative; range [0 100]
        L2 = rescale(L2);
        LSV = (L2 + SV)/2; % average lightness and DSV
        LSV = 1 - LSV; % negative; range [0 1]

        % reinsert background mask
        LAB3 = LAB;
        LSV3 = LSV;
        if do.mask == true
            LAB3 = max(LAB3,LAB_background);
            LSV3 = max(LSV3,L_background);
        end

        I2 = l2ab2rgb(LSV3,LAB3);
        label = 'lsv';
        icc_status = imwritewrap(I2,imurl,label,do,...
            fileFormat, grayscale, appRoot, jpegQuality);
        if ~isempty(icc_status)
            uistatus = icc_status;
        end
        if firstImage.is == true
            ImagesOut.Bitmaps{kMethods} = I2;
            label = 'LSV';
            if do.mask == true
                label = [label,' Masked'];
            end
            ImagesOut.Labels{kMethods} = label;
            ImagesOut.Indices{kMethods} = kMethods;
        end

        abort = multiWaitbar('Enhancing Images','Increment',dMethods);
        if abort == true
            abortCheck = uiconfirm(hFigure,...
                'Stop processing?','Confirm Stop',...
                'Options',{'Yes','No'},...
                'DefaultOption',1,'CancelOption',2,...
                 'Icon','question');
            if strcmp(abortCheck,'Yes')
                return
            else
                multiWaitbar('Enhancing Images','ResetCancel');
            end
        end
        kMethods = kMethods+1;

    end

    % ---------------------------------------------------------------------
    %% LSV negative
    % ---------------------------------------------------------------------
    if (do.lsv == true && (do.negative == true || do.blue == true)) ...
            && grayscale.is == false

        LSV3 = 1 - LSV3; % range [0 1]

        if do.negative == true
            
            I2 = l2ab2rgb(LSV3,LAB3);
            label = 'lsv-neg';
            icc_status = imwritewrap(I2,imurl,label,do,...
                fileFormat, grayscale, appRoot, jpegQuality);
            if ~isempty(icc_status)
                uistatus = icc_status;
            end
            if firstImage.is == true
                ImagesOut.Bitmaps{kMethods} = I2;
                label = 'LSV Negative';
                if do.mask == true
                    label = [label,' Masked'];
                end
                ImagesOut.Labels{kMethods} = label;
                ImagesOut.Indices{kMethods} = kMethods;
            end

            abort = multiWaitbar('Enhancing Images','Increment',dMethods);
            if abort == true
                abortCheck = uiconfirm(hFigure,...
                    'Stop processing?','Confirm Stop',...
                    'Options',{'Yes','No'},...
                    'DefaultOption',1,'CancelOption',2,...
                     'Icon','question');
                if strcmp(abortCheck,'Yes')
                    return
                else
                    multiWaitbar('Enhancing Images','ResetCancel');
                end
            end
            kMethods = kMethods+1;
        end
    end

    % ---------------------------------------------------------------------
    %% LSV negative blue
    % ---------------------------------------------------------------------
    if (do.lsv == true && do.blue == true) && grayscale.is == false

        % change of sign
        A2 = -LAB3(:,:,2);
        B2 = -LAB3(:,:,3);

        % back to RGB
        LAB2 = cat(3,100*LSV3,A2,B2);
        I2 = l2ab2rgb(LSV3,LAB2);
        label = 'lsv-neg-blue';
        icc_status = imwritewrap(I2,imurl,label,do,...
            fileFormat, grayscale, appRoot, jpegQuality);
        if ~isempty(icc_status)
            uistatus = icc_status;
        end
        if firstImage.is == true
            ImagesOut.Bitmaps{kMethods} = I2;
            label = 'LSV Blue Negative';
            if do.mask == true
                label = [label,' Masked'];
            end
            ImagesOut.Labels{kMethods} = label;
            ImagesOut.Indices{kMethods} = kMethods;
        end

        abort = multiWaitbar('Enhancing Images','Increment',dMethods);
        if abort == true
            abortCheck = uiconfirm(hFigure,...
                'Stop processing?','Confirm Stop',...
                'Options',{'Yes','No'},...
                'DefaultOption',1,'CancelOption',2,...
                 'Icon','question');
            if strcmp(abortCheck,'Yes')
                return
            else
                multiWaitbar('Enhancing Images','ResetCancel');
            end
        end
        kMethods = kMethods+1;
    end


    % ---------------------------------------------------------------------
    % Contrast-limited adaptive histogram equalization (CLAHE)
    % .....................................................................
    %% adapthisteq
    % ---------------------------------------------------------------------
    if do.adapthisteq == true

        if grayscale.is == false
            L2 = L;
            L2(isnan(L2)) = 0;
            L2 = rescale(L2);
            L2 = adapthisteq(L2,'Distribution','rayleigh');
            L2 = rescale(L2);
            % reinsert background mask
            LAB3 = LAB;
            L3 = L2;
            if do.mask == true
                LAB3 = max(LAB3,LAB_background);
                L3 = max(L3,L_background);
            end

            I2 = l2ab2rgb(L3,LAB3);
        else
            % grayscale images
            I2 = rescale(I);
            I2 = adapthisteq(I2,'Distribution','rayleigh');
            I2 = rescale(I2);
            if do.mask == true
                I2 = max(I2,I_background);
            end 
        end
        
        label = 'adapthisteq';
        icc_status = imwritewrap(I2,imurl,label,do,...
            fileFormat, grayscale, appRoot, jpegQuality);
        if ~isempty(icc_status)
            uistatus = icc_status;
        end
        if firstImage.is == true
            ImagesOut.Bitmaps{kMethods} = I2;
            label = 'Adapthisteq';
            if do.mask == true
                label = [label,' Masked'];
            end
            ImagesOut.Labels{kMethods} = label;
            ImagesOut.Indices{kMethods} = kMethods;
        end

        if grayscale.is == true
            grayscale.processed = true;
        end

        abort = multiWaitbar('Enhancing Images','Increment',dMethods);
        if abort == true
            abortCheck = uiconfirm(hFigure,...
                'Stop processing?','Confirm Stop',...
                'Options',{'Yes','No'},...
                'DefaultOption',1,'CancelOption',2,...
                 'Icon','question');
            if strcmp(abortCheck,'Yes')
                return
            else
                multiWaitbar('Enhancing Images','ResetCancel');
            end
        end
        kMethods = kMethods+1;

    end

    % ---------------------------------------------------------------------
    %% adapthisteq negative
    % ---------------------------------------------------------------------
    if (do.adapthisteq == true && (do.negative == true || do.blue == true))

        if grayscale.is == false
            L3 = 1 - L3; % range [0 1]
        else
            I2 = 1 - I2;
        end

        if do.negative == true
            
            if grayscale.is == false
                I2 = l2ab2rgb(L3,LAB3);
            end
            label = 'adapthisteq-neg';
            icc_status = imwritewrap(I2,imurl,label,do,...
                fileFormat, grayscale, appRoot, jpegQuality);
            if ~isempty(icc_status)
                uistatus = icc_status;
            end
            if firstImage.is == true
                ImagesOut.Bitmaps{kMethods} = I2;
                label = 'Adapthisteq Negative';
                if do.mask == true
                    label = [label,' Masked'];
                end
                ImagesOut.Labels{kMethods} = label;
                ImagesOut.Indices{kMethods} = kMethods;
            end
            if grayscale.is == true
                grayscale.processed = true;
            end

            abort = multiWaitbar('Enhancing Images','Increment',dMethods);
            if abort == true
                abortCheck = uiconfirm(hFigure,...
                    'Stop processing?','Confirm Stop',...
                    'Options',{'Yes','No'},...
                    'DefaultOption',1,'CancelOption',2,...
                     'Icon','question');
                if strcmp(abortCheck,'Yes')
                    return
                else
                    multiWaitbar('Enhancing Images','ResetCancel');
                end
            end
            kMethods = kMethods+1;
        end
    end

    % ---------------------------------------------------------------------
    %% adapthisteq negative blue
    % ---------------------------------------------------------------------
    if do.adapthisteq == true && do.blue == true && grayscale.is == false

        % change of sign
        A2 = -LAB3(:,:,2);
        B2 = -LAB3(:,:,3);

        % back to RGB
        LAB2 = cat(3,100*L3,A2,B2);
        I2 = l2ab2rgb(L3,LAB2);
        label = 'adapthisteq-neg-blue';
        icc_status = imwritewrap(I2,imurl,label,do,...
            fileFormat, grayscale, appRoot, jpegQuality);
        if ~isempty(icc_status)
            uistatus = icc_status;
        end
        if firstImage.is == true
            ImagesOut.Bitmaps{kMethods} = I2;
            label = 'Adapthisteq Blue Negative';
            if do.mask == true
                label = [label,' Masked'];
            end
            ImagesOut.Labels{kMethods} = label;
            ImagesOut.Indices{kMethods} = kMethods;
        end

        if grayscale.is == true
            grayscale.processed = true;
        end

        abort = multiWaitbar('Enhancing Images','Increment',dMethods);
        if abort == true
            abortCheck = uiconfirm(hFigure,...
                'Stop processing?','Confirm Stop',...
                'Options',{'Yes','No'},...
                'DefaultOption',1,'CancelOption',2,...
                 'Icon','question');
            if strcmp(abortCheck,'Yes')
                return
            else
                multiWaitbar('Enhancing Images','ResetCancel');
            end
        end
        kMethods = kMethods+1;
    end


    % ---------------------------------------------------------------------
    % RETINEX color constancy enhancement methods
    % .....................................................................
    %% retinex
    % ---------------------------------------------------------------------
    if do.retinex == true
        
        n = 1; % single method
        if iscell(do.retinexMethods) % multiple methods
            n = length(do.retinexMethods);
        end
        for k = 1:n
            
            % -------------------------------------------------------------
            %% positive
            if grayscale.is == false
                method = do.retinexMethods{k};                
            else
                % retinex on single channel for achromatic images
                method = 'MSR-A';
            end
            
            % do retinex
            postprocessing.negative = false;
            postprocessing.complementhue = false;
            I2 = retinex(I, method, [], [], [], postprocessing);

            % write image and embedd color profile
            label = ['retinex-',method];
            icc_status = imwritewrap(I2, imurl, label, do,...
                fileFormat, grayscale, appRoot, jpegQuality);
            if ~isempty(icc_status)
                uistatus = icc_status;
            end
            
            % remember image and image label
            if firstImage.is == true
                ImagesOut.Bitmaps{kMethods} = I2;
                label = ['Retinex ',method];
                if do.mask == true
                    label = [label,' Masked'];
                end
                ImagesOut.Labels{kMethods} = label;
                ImagesOut.Indices{kMethods} = kMethods;
            end

            % next
            abort = multiWaitbar('Enhancing Images','Increment',dMethods);
            if abort == true
                abortCheck = uiconfirm(hFigure,...
                    'Stop processing?','Confirm Stop',...
                    'Options',{'Yes','No'},...
                    'DefaultOption',1,'CancelOption',2,...
                     'Icon','question');
                if strcmp(abortCheck,'Yes')
                    return
                else
                    multiWaitbar('Enhancing Images','ResetCancel');
                end
            end
            kMethods = kMethods+1;

            % -------------------------------------------------------------
            %% negative
            if do.negative == true
            
                % do retinex
                postprocessing.negative = true;
                postprocessing.complementhue = false;
                I2 = retinex(I, method, [], [], [], postprocessing);
                                
                label = ['retinex-',method,'-neg'];
                icc_status = imwritewrap(I2,imurl,label,do,...
                    fileFormat, grayscale, appRoot, jpegQuality);
                if ~isempty(icc_status)
                    uistatus = icc_status;
                end
                
                if firstImage.is == true
                    ImagesOut.Bitmaps{kMethods} = I2;
                    label = ['Retinex ',method,' Negative'];
                    if do.mask == true
                        label = [label,' Masked'];
                    end
                    ImagesOut.Labels{kMethods} = label;
                    ImagesOut.Indices{kMethods} = kMethods;
                end

                abort = multiWaitbar('Enhancing Images',...
                    'Increment',dMethods);
                if abort == true
                    abortCheck = uiconfirm(hFigure,...
                        'Stop processing?','Confirm Stop',...
                        'Options',{'Yes','No'},...
                        'DefaultOption',1,'CancelOption',2,...
                         'Icon','question');
                    if strcmp(abortCheck,'Yes')
                        return
                    else
                        multiWaitbar('Enhancing Images','ResetCancel');
                    end
                end
                kMethods = kMethods+1;
                
            end
            
            if grayscale.is == true
                grayscale.processed = true;
                break
            end

            % -------------------------------------------------------------
            %% blue negative
            if do.blue == true && grayscale.is == false
            % skip grayscale images since they have no chromatic dimension
                
                % do retinex
                postprocessing.negative = true;
                postprocessing.complementhue = true;
                I2 = retinex(I, method, [], [], [], postprocessing);
                                
                label = ['retinex-',method,'-neg-blue'];
                icc_status = imwritewrap(I2,imurl,label,do,...
                    fileFormat, grayscale, appRoot, jpegQuality);
                if ~isempty(icc_status)
                    uistatus = icc_status;
                end
                
                if firstImage.is == true
                    ImagesOut.Bitmaps{kMethods} = I2;
                    label = ['Retinex ',method,' Blue Negative'];
                    if do.mask == true
                        label = [label,' Masked'];
                    end
                    ImagesOut.Labels{kMethods} = label;
                    ImagesOut.Indices{kMethods} = kMethods;
                end

                abort = multiWaitbar('Enhancing Images',...
                    'Increment',dMethods);
                if abort == true
                    abortCheck = uiconfirm(hFigure,...
                        'Stop processing?','Confirm Stop',...
                        'Options',{'Yes','No'},...
                        'DefaultOption',1,'CancelOption',2,...
                         'Icon','question');
                    if strcmp(abortCheck,'Yes')
                        return
                    else
                        multiWaitbar('Enhancing Images','ResetCancel');
                    end
                end
                kMethods = kMethods+1;
                
            end
            
        end

    end

    
    % ---------------------------------------------------------------------
    %% memorize input image for display on GUI
    % ---------------------------------------------------------------------
    if firstImage.is == true
       if grayscale.is == false || ...
               (grayscale.is == true && grayscale.processed == true)
           
            % original is already in list, don't add it anymore
            if do.mask == false
                
                ImagesOut.Bitmaps{kMethods} = I;
                ImagesOut.Labels{kMethods} = 'Original';
                ImagesOut.Indices{kMethods} = kMethods;
                ImagesOut.Bitmaps = circshift(ImagesOut.Bitmaps,1);
                ImagesOut.Labels = circshift(ImagesOut.Labels,1);
                
            end
       end
       
       % if enhancement methods were chosen that don't support grayscale
       % processing (vividness, lsv, some retinex), then thorw an error
       if grayscale.is == true && grayscale.processed == false
           
            uialert(hFigure,...
                ['The selected methods do not support grayscale ',...
               'images. Please select Adapthisteq and/or Retinex.'],...
               'Request','Icon','warning');
           
       end
    end
    
end


% =========================================================================
%% 	WRITE IMAGE
% =========================================================================
function icc_status = imwritewrap(I, imurl, methodlabel, do,...
    fileFormat, grayscale, appRoot, jpegQuality)
    
    % generate file name
    if grayscale.red == true
        redChannel = '-red';
    else
        redChannel = '';
    end
    idx = strfind(imurl.write,'.');
    % we maintain the file extension of the input file in the output file
    % name, so that files with the same name but different extensions are
    % not overwritten if the extension would be disregarded
    fn = [imurl.write(1:idx(end)-1),'_',imurl.write(idx(end)+1:end),...
        redChannel,'-',methodlabel];
    if ~isempty(do.masklabel)
        fn = [fn,'-',do.masklabel,'-',do.maskBackground];
    end
    if ~isempty(do.deshadowlabel)
        fn = [fn,'-',do.deshadowlabel];
    end

    % select file format
    if fileFormat.tiff == true
        imwrite(I,[fn,'.tif'])
    end
    if fileFormat.jpeg == true
        imwrite(I,[fn,'.jpg'],'Quality',jpegQuality)
    end

    % don't embed color profile in grayscale images
    if grayscale.is == true
        icc_status = '';
        return
    end
    
    % embed color profile in image file
    icc_status = embedColorProfile(fn,fileFormat,appRoot);

end


% =========================================================================
%%  EMBED COLOR PROFILE
% =========================================================================
function icc_status = embedColorProfile(im_url,fileFormat,appRoot)

    icc_status = '';
    
    % color profile choices: {'sRGB Profile'} | 'AdobeRGB1998'
    icc_url = fullfile(appRoot,...
        '3p','images','color','color profiles','sRGB Profile.icc');

    % embed color profile in TIFF file
    if fileFormat.tiff == true

        % Reference: https://blogs.mathworks.com/steve/2009/10/20/...
        %   embedding-an-icc-profile-into-a-tiff-file/

        % Step 1. Read in the raw bytes of the profile file.
        fid = fopen(icc_url);
        raw_profile_bytes = fread(fid, Inf, 'uint8=>uint8');
        fclose(fid);

        % Step 2. Initialize a Tiff object using 'r+' mode (read and 
        % modify).
        tif = Tiff([im_url,'.tif'], 'r+');

        % Step 3. Embed the profile bytes as a TIFF tag.
        tif.setTag('ICCProfile', raw_profile_bytes);

        % Step 4. Tell the Tiff object to update the image metadata in 
        % the file.
        tif.rewriteDirectory();

        % Step 5. Close the Tiff object.
        tif.close();
    end

    % embed color profile in JPEG file
    if fileFormat.jpeg == true

        exiftoolpath = ...
            fullfile(appRoot,'gx','enhancement','hierax','exiftool');
        if ispc
            exiftool_url = [exiftoolpath,filesep,'exiftool.exe'];
        else
            exiftool_url = [exiftoolpath,filesep,'exiftool.pl'];
        end

        % copy ICC color profile from ICC definition file into image file
        % TODO: and supress any shell output (' > NUL')
        icc_embed_status = system([ '"', exiftool_url, ...
            '" -q -tagsFromFile "', ... 
            icc_url, '" -ICC_Profile "', [im_url,'.jpg'],'"']);

        % delete backup files produced by exiftool
        if icc_embed_status == 0
            delete([im_url,'.jpg_original'])
        else
            icc_status = 'No ICC color profiles embeded in JPEG files.';
        end
        
    end
    
end


% =========================================================================
%% 	MASK BACKGROUND
% =========================================================================
function BW = maskbkgd(L,do,imurl)

    multiWaitbar('Masking Background',0);
    multiWaitbar('Masking Background','Increment',0/1);

    % reverse polarity pre-binarization
    if strcmp(do.maskBackground,'darkBackground')
        L = 1 - L;
    end

    % parameters
    wavelength = 2; % 2: very small, Nyqiust limit
    deltaTheta = 45/1; % 45/1 ... 4
    orientation = 0:deltaTheta:(180-deltaTheta);
    fb = 15; % 15: very long
    ar = 0.05; % 0.05: very narrow, filiform

    % Gabors filter bank
    G = gabor(wavelength,orientation, ...
        'SpatialFrequencyBandwidth',fb,'SpatialAspectRatio',ar);
    F = imgaborfilt(L,G); % filtering w/ even Gabors

    % integration of filtered images across orientations & wavelengths
    F2 = max(F,[],3);
    F2 = rescale(F2);

    % Otsu binarization
    BW = imbinarize(F2,'global');
    BW = double(BW);

    % reverse polarity post-binarization
    if do.deshadow == false
        BW = 1 - BW;
    end

    % save mask for visual control
    fn = [imurl.write(1:end-4),'-mask','-',do.maskBackground];
    if ~isempty(do.deshadowlabel)
        fn = [fn,'-',do.deshadowlabel];
    end
    fn = [fn,'.png'];
    imwrite(BW,fn)

    multiWaitbar('Masking Background','Close');

end


% =========================================================================
%%  INSERT NEW LIGHTNESS CHANNEL IN LAB AND CONVERT TO RGB
% =========================================================================
function I2 = l2ab2rgb(L2,LAB)
% input L2: double, range [0 1]
% output I2: uint8, range [0 255]

    L2 = 100*L2;
    LAB2 = cat(3,L2,LAB(:,:,2),LAB(:,:,3));
    I2 = lab2rgb(LAB2,'ColorSpace','srgb','WhitePoint','d65');

    % algorithm to manage out-of-gamut values:
    % clip values to [0, 1] range to bring them into the RGB range
    I2 = max(0,min(1,I2));
    I2 = uint8(255*I2);

end


