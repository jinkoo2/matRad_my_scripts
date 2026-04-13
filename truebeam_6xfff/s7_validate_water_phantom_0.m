%% s7_validate_water_phantom_0.m
% Validate TrueBeam 6XFFF machine in a homogeneous water phantom.
% Setup  : AP beam (gantry 0), 40x40 cm² open field, SSD = 100 cm.
% Outputs: (1) calculated PDD vs measured 40x40 PDD
%          (2) calculated inline profile at 10 cm depth vs measured
%
% Coordinate convention (matRad, gantry = 0)
%   x  : inline (columns), source at (0, -SAD, 0)
%   y  : depth along beam (+y away from source / into phantom)
%   z  : crossline (slices)
%   cubeDim = [Ny, Nx, Nz]  (MATLAB array order: rows, cols, slices)
%
% Phantom surface is placed at y = 0, isocenter at y = 0
%   → SSD = SAD = 1000 mm = 100 cm  ✓

clear; clc; close all;

%% 1. Setup paths and load machine
cd /gpfs/projects/KimGroup/projects/tps/matRad
matRad_rc;
matRad_cfg = MatRad_Config.instance();

pln_tmp.radiationMode = 'photons';
pln_tmp.machine       = 'TrueBeam_6XFFF';
machine = matRad_loadMachine(pln_tmp);
fprintf('Loaded machine: %s  (SAD = %.0f mm)\n', machine.meta.name, machine.meta.SAD);

%% 2. Build water phantom (manually, so y axis starts at 0)
res = 2;    % mm  isotropic resolution

Nx = 300;   % cols   x: -300 to +298 mm  (inline)
Ny = 160;   % rows   y:    0 to +318 mm  (depth, beam direction)
Nz = 300;   % slices z: -300 to +298 mm  (crossline)

% World-coordinate axes
ct.x = (-(Nx/2) : (Nx/2 - 1)) * res;   % -300, -298, ..., 298  mm
ct.y = (0       : Ny - 1)      * res;   %    0,    2, ..., 318  mm
ct.z = (-(Nz/2) : (Nz/2 - 1)) * res;   % -300, -298, ..., 298  mm

ct.resolution.x = res;
ct.resolution.y = res;
ct.resolution.z = res;
ct.cubeDim      = [Ny, Nx, Nz];
ct.numOfCtScen  = 1;

% HU = 0 everywhere (water).  ct.cube = 1 (rED=1) pre-set to avoid
% a crash in the STF generator's density-erase step.
ct.cubeHU{1} = zeros(Ny, Nx, Nz, 'single');
ct.cube{1}   = ones( Ny, Nx, Nz, 'single');

%% 3. Build CST
% Row 1: OAR covering the whole phantom so that voxels outside the TARGET
%        are NOT zeroed out by ignoreOutsideDensities logic.
V_all = (1 : Ny * Nx * Nz)';

% Row 2: TARGET spanning the 40x40 cm² field footprint + full depth.
%        The STF generator projects these voxels onto the iso plane to
%        place rays.  At iso (y = 0): projection = world_x directly.
%        ±200 mm covers the 40x40 field edge; add ±5 mm of margin.
ix_tgt = find(ct.x >= -200 & ct.x <= 200);
iz_tgt = find(ct.z >= -200 & ct.z <= 200);
tgt_mask = false(Ny, Nx, Nz);
tgt_mask(:, ix_tgt, iz_tgt) = true;
V_target = find(tgt_mask);

meta_oar = struct('Priority',2,'Visible',1,'visibleColor',[0 0.5 0], ...
                  'alphaX',0.1,'betaX',0.05,'TissueClass',1);
meta_ptv = struct('Priority',1,'Visible',1,'visibleColor',[1 0 0], ...
                  'alphaX',0.1,'betaX',0.05,'TissueClass',1);

cst = cell(2, 6);
cst{1,1} = 0;  cst{1,2} = 'Water';     cst{1,3} = 'OAR';
cst{1,4} = {V_all};   cst{1,5} = meta_oar;  cst{1,6} = {};

cst{2,1} = 1;  cst{2,2} = 'PTV_40x40'; cst{2,3} = 'TARGET';
cst{2,4} = {V_target}; cst{2,5} = meta_ptv; cst{2,6} = {};

%% 4. Plan: single AP beam, 40x40 cm², gantry 0°
pln.radiationMode = 'photons';
pln.machine       = 'TrueBeam_6XFFF';
pln.bioModel      = 'none';
pln.multScen      = 'nomScen';
pln.numOfFractions = 1;

% Beam geometry
pln.propStf.gantryAngles = 0;      % AP: beam travels in +y direction
pln.propStf.couchAngles  = 0;
pln.propStf.bixelWidth   = 5;      % mm pencil-beam width
% Isocenter at phantom surface → SSD = SAD = 1000 mm
pln.propStf.isoCenter    = [0, 0, 0];

% Dose grid (same resolution as CT)
pln.propDoseCalc.doseGrid.resolution.x = res;
pln.propDoseCalc.doseGrid.resolution.y = res;
pln.propDoseCalc.doseGrid.resolution.z = res;

% Extend lateral cutoff so out-of-field scatter is captured
% (default 50 mm; 100 mm covers ±300 mm from outermost ray at ±200 mm)
pln.propDoseCalc.geometricLateralCutOff = 100;  % mm

%% 5. Generate STF
stf = matRad_generateStf(ct, cst, pln);
fprintf('STF: %d rays, bixelWidth = %.0f mm, isoCenter = [%.0f %.0f %.0f] mm\n', ...
    stf.numOfRays, stf.bixelWidth, stf.isoCenter(1), stf.isoCenter(2), stf.isoCenter(3));

%% 6. Dose influence calculation
dij = matRad_calcDoseInfluence(ct, cst, stf, pln);
fprintf('Dose grid: [%d %d %d]\n', dij.doseGrid.dimensions);

%% 7. Reconstruct dose with uniform bixel weights (open-field simulation)
w         = ones(dij.totalNumOfBixels, 1);
resultGUI = matRad_calcCubes(w, dij);
doseCube  = resultGUI.physicalDose;   % size: [Ny, Nx, Nz] = dose-grid dimensions

%% 8. Find isocenter indices in the dose grid
% matRad_world2cubeIndex returns [iy, ix, iz] (row, col, slice)
isoIdx = matRad_world2cubeIndex([0 0 0], dij.doseGrid);
iy0 = isoIdx(1);   % row  → y = 0 (surface)
ix0 = isoIdx(2);   % col  → x = 0 (inline center)
iz0 = isoIdx(3);   % slice→ z = 0 (crossline center)

fprintf('Isocenter voxel: iy=%d (y=%.1f mm), ix=%d (x=%.1f mm), iz=%d (z=%.1f mm)\n', ...
    iy0, dij.doseGrid.y(iy0), ...
    ix0, dij.doseGrid.x(ix0), ...
    iz0, dij.doseGrid.z(iz0));

%% 9. Extract central-axis PDD (depth = y direction for AP beam)
% doseCube(iy, ix, iz): varying iy at fixed ix0, iz0 gives depth profile
depth_calc_mm = dij.doseGrid.y;                        % 0, 2, ..., 318 mm
pdd_calc      = double(squeeze(doseCube(:, ix0, iz0))); % length = Ny

if max(pdd_calc) == 0
    error('Central-axis dose is all zero. Check phantom geometry and machine file.');
end

pdd_calc_norm = 100 * pdd_calc / max(pdd_calc);  % normalize to 100% at dmax

%% 10. Extract inline profile at 10 cm depth
depth_profile_mm = 100;   % 10 cm
[~, iy_10cm] = min(abs(depth_calc_mm - depth_profile_mm));
fprintf('Profile depth: y = %.1f mm  (iy = %d)\n', depth_calc_mm(iy_10cm), iy_10cm);

x_calc_mm    = dij.doseGrid.x;                            % mm
prof_calc    = double(squeeze(doseCube(iy_10cm, :, iz0))); % length = Nx
cax_dose     = doseCube(iy_10cm, ix0, iz0);

if cax_dose == 0
    error('CAX dose at %d mm depth is zero.', depth_profile_mm);
end

prof_calc_norm = 100 * prof_calc / double(cax_dose);  % 100% at CAX
x_calc_cm      = x_calc_mm / 10;                       % mm → cm

%% 11. Load measured PDD (40x40 cm² column)
dataDir  = '/gpfs/projects/KimGroup/projects/tps/matRad/my_scripts/truebeam_6xfff';
pdd_file = fullfile(dataDir, 'pdd_pasted_from_excel.txt');

% 'NumHeaderLines',1  skips the text header row reliably
data_pdd      = readmatrix(pdd_file, 'NumHeaderLines', 1);
depth_meas_cm = data_pdd(:, 1);          % depth [cm]
pdd_40x40     = data_pdd(:, end);        % 40x40 cm² column (last)
depth_meas_mm = depth_meas_cm * 10;      % → mm

pdd_meas_norm = 100 * pdd_40x40 / max(pdd_40x40);   % normalize to 100%

%% 12. Load measured inline profile at 10 cm, 40x40 cm²
prof_file = fullfile(dataDir, 'profile_10cm_40x40.txt');

data_prof  = readmatrix(prof_file, 'NumHeaderLines', 1);
x_meas_cm  = data_prof(:, 1);         % off-axis position [cm]
prof_meas  = data_prof(:, 2);         % dose [%]

% Normalize measured profile to 100% at CAX (x = 0)
cax_meas       = interp1(x_meas_cm, prof_meas, 0, 'linear');
prof_meas_norm = 100 * prof_meas / cax_meas;

%% 13. Plot: PDD comparison
figure('Name', 'PDD – 40x40 cm², Gantry 0, SSD 100 cm', 'Position', [100 100 700 500]);
plot(depth_meas_mm,  pdd_meas_norm,  'b-',  'LineWidth', 1.5, 'DisplayName', 'Measured');
hold on;
plot(depth_calc_mm,  pdd_calc_norm,  'r--', 'LineWidth', 1.5, 'DisplayName', 'Calculated (matRad SVD)');
xlabel('Depth [mm]');
ylabel('Relative Dose [%]');
title('PDD – TrueBeam 6XFFF, 40×40 cm², SSD=100 cm');
legend('Location', 'northeast');
grid on;
xlim([0, 310]);
ylim([0, 108]);

%% 14. Plot: profile comparison at 10 cm
figure('Name', 'Profile at 10 cm – 40x40 cm², Gantry 0', 'Position', [830 100 700 500]);
plot(x_meas_cm,  prof_meas_norm,  'b-',  'LineWidth', 1.5, 'DisplayName', 'Measured');
hold on;
plot(x_calc_cm,  prof_calc_norm,  'r--', 'LineWidth', 1.5, 'DisplayName', 'Calculated (matRad SVD)');
xlabel('Off-axis position [cm]');
ylabel('Relative Dose [%]');
title('Inline Profile at 10 cm – TrueBeam 6XFFF, 40×40 cm², SSD=100 cm');
legend('Location', 'south');
grid on;
xlim([-30, 30]);
ylim([0, 115]);

%% 15. Quantitative summary
[~, idMax_calc] = max(pdd_calc_norm);
[~, idMax_meas] = max(pdd_meas_norm);
fprintf('\n=== PDD summary ===\n');
fprintf('  dmax  – calculated: %.1f mm  |  measured: %.1f mm\n', ...
    depth_calc_mm(idMax_calc), depth_meas_mm(idMax_meas));

for d_cm = [5, 10, 15, 20]
    d_mm = d_cm * 10;
    pdd_c = interp1(depth_calc_mm, pdd_calc_norm, d_mm, 'linear', NaN);
    pdd_m = interp1(depth_meas_mm, pdd_meas_norm, d_mm, 'linear', NaN);
    fprintf('  PDD at %2d cm – calculated: %5.1f%%  |  measured: %5.1f%%\n', d_cm, pdd_c, pdd_m);
end

fprintf('\n=== Profile summary at 10 cm ===\n');
for x_cm = [5, 10, 15, 18, 20]
    pc = interp1(x_calc_cm, prof_calc_norm, x_cm, 'linear', NaN);
    pm = interp1(x_meas_cm, prof_meas_norm, x_cm, 'linear', NaN);
    fprintf('  x = %+.0f cm – calculated: %5.1f%%  |  measured: %5.1f%%\n',  x_cm, pc, pm);
    pc = interp1(x_calc_cm, prof_calc_norm, -x_cm, 'linear', NaN);
    pm = interp1(x_meas_cm, prof_meas_norm, -x_cm, 'linear', NaN);
    fprintf('  x = %+.0f cm – calculated: %5.1f%%  |  measured: %5.1f%%\n', -x_cm, pc, pm);
end

%% 16. Save results
save('s7_water_phantom_results.mat', ...
    'ct', 'cst', 'pln', 'stf', 'dij', 'resultGUI', ...
    'doseCube', ...
    'depth_calc_mm', 'pdd_calc_norm', ...
    'x_calc_cm',     'prof_calc_norm', ...
    'depth_meas_mm', 'pdd_meas_norm', ...
    'x_meas_cm',     'prof_meas_norm');
fprintf('\nSaved: s7_water_phantom_results.mat\n');
