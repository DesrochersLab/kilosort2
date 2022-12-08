%% you need to change most of the paths in this block
% dateUsed = { 
% 		    '02182019',
% 		    '02272019',
% 		    '02282019', 
% 		    '03012019', 
% 		    '03022019', 
% 		    '03062019',
% 		    '03082019', 
% 		    '03102019', 
% 		    '03112019', 
% 		    '03152019', 
% 		    '03182019',
% 		    '03312019', 
% 		    '04012019', 
% 		    '04052019',
% 		    '04222019',
% 		    '04252019',
% 		    '05012019',
% 		    '05072019',
% 		    '05082019',
% 		    '05092019'
% 		    };

% dateUsed = {
%         '02082019',
%         '02132019',
%         '02142019',
%         '02152019',
%         '02162019',
%         '02172019',
%         '02262019',
% 	    '03042019',
% 	    '03052019', 
% 	    '03072019', 
% 	    '03092019', 
% 	    '03122019',
% 	    '03132019', 
% 	    '03142019', 
% 	    '03162019', 
% 	    '03272019',
% %		'03282019', 
% 	    '04032019', 
% 	    '04062019',
% 	    '04232019',
% 	    '04242019',
% 	    '04262019',
% 	    '04292019',
% 	    '05022019',
% 	    '05052019',
%         '05102019'
%     };

% FOR LIP
%RERUN ORIGINAL LIST 11, 16
%RERUN MISSING LIST 17 19 20 24
% FOR Pul
%RERUN ORIGINAL LIST 5, 13
%RERUN MISSING LIST 4, 6, 24
for session=25:size(dateUsed,1)
    area = 3;
    
    
    
    addpath(genpath('/home/rboshra/Kilosort2')) % path to kilosort folder
    addpath(genpath('/home/rboshra/Kilosort/npy-matlab')) % for converting to Phy
    rootZ = '/mnt/sink/scratch/rboshra/spike_sorting/Pul/'; % the raw data binary file is in this folder
    rootH = '/home/rboshra/Kilosort/tmp'; % path to temporary binary file (same size as data, should be on fast SSD)
    pathToYourConfigFile = '/home/rboshra/kilo/'; % take from Github folder and put it somewhere else (together with the master_file)
    chanMapFile = 'chanMap.mat';
    
    
    
    rootY = ['/mnt/sink/scratch/rboshra/spike_sorting/Results/' dateUsed{session} '/' num2str(area)]; % the results folder
    
    
    ops.trange    = [0 Inf]; % time range to sort
    ops.NchanTOT  = 32; % total number of channels in your recording
    
    run(fullfile(pathToYourConfigFile, 'configFile.m'))
    ops.fproc   = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
    ops.chanMap = fullfile(pathToYourConfigFile, chanMapFile);
    %% this block runs all the steps of the algorithm
    fprintf('Looking for data inside %s \n', rootZ)
    
    % main parameter changes from Kilosort2 to v2.5
    %ops.sig        = 20;  % spatial smoothness constant for registration
    ops.fshigh     = 100; % high-pass more aggresively
    %ops.nblocks    = 1; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 
    
    % main parameter changes from Kilosort2.5 to v3.0
    ops.Th       = [8 6];
    
    % is there a channel map file in this folder?
    fs = dir(fullfile(rootZ, 'chan*.mat'));
    if ~isempty(fs)
        ops.chanMap = fullfile(rootZ, fs(1).name);
    end
    
    % find the binary file
    ops.fbinary = [rootZ, 'Remy_', dateUsed{session} '_' num2str(area) '.dat'];
	% preprocess data to create temp_wh.dat
	rez = preprocessDataSub(ops);

	% time-reordering as a function of drift
	rez = clusterSingleBatches(rez);

	% main tracking and template matching algorithm
	rez = learnAndSolve8b(rez);

	% final merges
	rez = find_merges(rez, 1);

	% final splits by SVD
	rez = splitAllClusters(rez, 1);

	% final splits by amplitudes
	rez = splitAllClusters(rez, 0);

	% decide on cutoff
	rez = set_cutoff(rez);

	fprintf('found %d good units \n', sum(rez.good>0))

	% write to Phy
    mkdir(rootY)
	fprintf('Saving results to Phy  \n')
	rezToPhy(rez, rootY );
end
