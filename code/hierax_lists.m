function lists = hierax_lists(methods)
%NINOX_LISTS Variously ordered lists of enhancement method labels
%
% -------------
% INPUT
% -------------
% methods - structure with following fields, each containing a 1-by-n cell 
%         array of characters with the enhancement method labels
%             methods.input
%             methods.color.processing
%             methods.color.postprocessing
%             methods.color.auxiliaries
%             methods.grayscale.processing
%             methods.grayscale.postprocessing
%             methods.grayscale.auxiliaries
%
%           The methods and their labels correspond to those contained in 
%           the hierax_process function.
%
% -------------
% OUTPUT
% -------------
% lists   - structure with following fields, each containing a 1-by-n cell 
%         character array with variously ordered enhancement method labels
%             lists.color.sequential
%             lists.color.interleaved
%             lists.grayscale.interleaved
%             lists.grayscale.sequential
%
%           The concept is that there are three classes of methods
%           (processing, postprocessing, and auxiliary) and they combine
%           with each other to generate the total number of enhancement
%           method combinations.
%
%           The list to generate differ for color and grayscale images. The
%           specific orders are the following:
%               sequential - the basic methods are grouped together
%                   and followed by the postprocessing and auxiliary
%                   classes
%               interleaved - each basic method is followed by a
%                   postprocessing and an auxiliary method;
%
%           The generated lists are intended to allow users to display and  
%           scroll through images in Nionx in various orders.
%
% -------------
% EXAMPLE
% -------------
%
% methods.input = {...
%     'Original'};
% 
% % methods for color images
% methods.color.processing = {...
%     'Vividness', ...
%     'LSV', ...
%     'Adapthisteq', ...
%     'Retinex MSRCR-RGB', ...
%     'Retinex MSR-VAB', ...
%     'Retinex MSR-LAB', ...
%     'Retinex MSR-V', ...
%     'Retinex MSR-L', ...
%     'Retinex MSRCP-I', ...
%     'Retinex MSRCP-V', ...
%     'Retinex MSRCP-V', ...
%     };
% methods.color.postprocessing = {...
%     '', ...
%     'Negative', ...
%     'Blue Negative'};
% methods.color.auxiliaries = {...
%     '',...
%     'Masked'};
% 
% % methods for grayscale images
% methods.grayscale.processing = {...
%     'Adapthisteq', ...
%     'Retinex MSR-A', ...
%     };
% methods.grayscale.postprocessing = {...
%     '', ...
%     'Negative'};
% methods.grayscale.auxiliaries = {...
%     '',...
%     'Masked'};
%
% lists = hierax_lists(methods);
%
% -------------
% LOG
% -------------
% 2020.09.22 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/


% initialization
lists = struct;
n = struct;
n.color.processing = length(methods.color.processing);
n.color.postprocessing = length(methods.color.postprocessing);
n.color.auxiliaries = length(methods.color.auxiliaries);
n.total = 1 + n.color.processing * ...
    n.color.postprocessing * n.color.auxiliaries;

n.grayscale.processing = length(methods.grayscale.processing);
n.grayscale.postprocessing = length(methods.grayscale.postprocessing);
n.grayscale.auxiliaries = length(methods.grayscale.auxiliaries);
n.total = 1 + n.grayscale.processing * ...
    n.grayscale.postprocessing * n.grayscale.auxiliaries;

% ---
% color images
% ---
% list of interleaved classes
% ---

% multiply color.processing methods with color.postprocessing methods
A = repmat(methods.color.processing,n.color.postprocessing,1);
B = repmat((methods.color.postprocessing)',1,n.color.processing);
C = cat(3,A,B);
C = join(C,' ',3);
C = (reshape(C, n.color.processing * n.color.postprocessing, 1))';
C = strip(C);

% multiply result with auxiliary methods
A = repmat(C,n.color.auxiliaries,1);
B = repmat((methods.color.auxiliaries)',1,size(A,2));
C = cat(3,A,B);
C = join(C,' ',3);
C = (reshape(C, n.color.processing * ...
    n.color.postprocessing * n.color.auxiliaries, 1))';
C = strip(C);

% add input label
lists.color.interleaved = [methods.input,C];

% ---
% list of sequential classes
% ---

% multiply color.processing methods with color.postprocessing methods
A = repmat(methods.color.processing, 1, n.color.postprocessing);
B = repmat(methods.color.postprocessing, n.color.processing, 1);
B = B(:)';
C = cat(1,A,B);
C = join(C,' ',1);
C = strip(C);

% multiply result with auxiliary methods
A = repmat(C,1,2);
B = repmat(methods.color.auxiliaries, ...
    n.color.processing * n.color.postprocessing, 1);
B = B(:)';
C = cat(1,A,B);
C = join(C,' ',1);
C = strip(C);

% add input label
lists.color.sequential = [methods.input,C];


% ---
% grayscale images
% ---
% list of interleaved classes
% ---

% multiply color.processing methods with color.postprocessing methods
A = repmat(methods.grayscale.processing,n.grayscale.postprocessing,1);
B = repmat((methods.grayscale.postprocessing)',1,n.grayscale.processing);
C = cat(3,A,B);
C = join(C,' ',3);
C = (reshape(C, n.grayscale.processing * n.grayscale.postprocessing, 1))';
C = strip(C);

% multiply result with auxiliary methods
A = repmat(C,n.grayscale.auxiliaries,1);
B = repmat((methods.grayscale.auxiliaries)',1,size(A,2));
C = cat(3,A,B);
C = join(C,' ',3);
C = (reshape(C, n.grayscale.processing * ...
    n.grayscale.postprocessing * n.grayscale.auxiliaries, 1))';
C = strip(C);

% add input label
lists.grayscale.interleaved = [methods.input,C];

% ---
% list of sequential classes
% ---

% multiply grayscale.processing methods with grayscale.postprocessing methods
A = repmat(methods.grayscale.processing, 1, n.grayscale.postprocessing);
B = repmat(methods.grayscale.postprocessing, n.grayscale.processing, 1);
B = B(:)';
C = cat(1,A,B);
C = join(C,' ',1);
C = strip(C);

% multiply result with auxiliary methods
A = repmat(C,1,2);
B = repmat(methods.grayscale.auxiliaries, ...
    n.grayscale.processing * n.grayscale.postprocessing, 1);
B = B(:)';
C = cat(1,A,B);
C = join(C,' ',1);
C = strip(C);

% add input label
lists.grayscale.sequential = [methods.input,C];


end

