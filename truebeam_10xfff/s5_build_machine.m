% s5_build_machine.m  –  TrueBeam 10XFFF (10MV FFF)
% Generate the TrueBeam 10XFFF matRad machine file by:
%   1. Running s1–s4 to produce the four input .dat files
%   2. Calling ppbkc_generateBaseData to build the machine struct
%   3. Saving to the matRad userdata/machines directory

% mfilename('fullpath') is a built-in, not a workspace variable, so it
% survives the 'clear; clc' that each subscript runs at startup.
% All run() paths are computed inline to avoid the cleared-variable trap.

%% Step 1: Generate input .dat files
fprintf('=== s1: output factors ===\n');
run(fullfile(fileparts(mfilename('fullpath')), 's1_write_of_dat.m'));

fprintf('=== s2: TPR table ===\n');
run(fullfile(fileparts(mfilename('fullpath')), 's2_write_tpr_dat.m'));

fprintf('=== s3: primary fluence ===\n');
run(fullfile(fileparts(mfilename('fullpath')), 's3_write_primflu_dat.m'));

fprintf('=== s4: params ===\n');
run(fullfile(fileparts(mfilename('fullpath')), 's4_create_params_dat.m'));

%% Step 2: Build machine
toolboxRoot = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc';
addpath(toolboxRoot);

inputDir  = fullfile(toolboxRoot, 'truebeam_10xfff');
machineName = 'TrueBeam_10XFFF';

fprintf('\n=== s5: building machine ===\n');
machine = ppbkc_generateBaseData(machineName, inputDir);

%% Step 3: Save
outFile = '/gpfs/projects/KimGroup/projects/tps/matRad/userdata/machines/photons_TrueBeam_10XFFF.mat';
save(outFile, 'machine', '-v7');
fprintf('Saved: %s\n', outFile);
