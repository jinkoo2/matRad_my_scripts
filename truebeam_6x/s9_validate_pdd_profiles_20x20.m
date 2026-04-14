%% s7_validate_pdd_profiles_20x20.m  –  TrueBeam 6X (6MV flat)
% Validate TrueBeam 6X machine in a homogeneous water phantom.
% Setup  : AP beam (gantry 0), 20x20 cm² open field, SSD = 100 cm.
% Outputs: (1) calculated PDD vs GBD 20x20 cm² PDD
%          (2) calculated crossline profiles at 1.5, 5, 10, 20, 30 cm
%              vs GBD 20x20 cm² profiles
%
% Phantom sized for 20x20 cm² to minimize runtime:
%   x/z : ±200 mm (covers GBD profile range; field diverges to ±130 mm at 30 cm depth)
%   y   : 0–318 mm (covers GBD PDD range of 0–30 cm)
%   Voxel count: 200×160×200 = 6.4 M
%   Ray count  : ~1600 bixels (40x40 at 5mm spacing)
%
% addMargin=false: prevents matRad from auto-dilating the target by
%   bixelWidth (5mm), which would shift rays from ±100mm to ±105mm
%   and produce a slightly oversized field.

clear; clc; close all;

%% 1. Paths and machine
cd /gpfs/projects/KimGroup/projects/tps/matRad
matRad_rc;
matRad_cfg = MatRad_Config.instance();

pln_tmp.radiationMode = 'photons';
pln_tmp.machine       = 'TrueBeam_6X';
machine = matRad_loadMachine(pln_tmp);
fprintf('Loaded machine: %s  (SAD = %.0f mm)\n', machine.meta.name, machine.meta.SAD);

%% 2. Compact water phantom
res = 2;    % mm isotropic

Nx = 200;   % cols   x: -200 to +198 mm  (inline,     ±200 mm)
Ny = 160;   % rows   y:    0 to +318 mm  (depth, beam direction)
Nz = 200;   % slices z: -200 to +198 mm  (crossline,  ±200 mm)

ct.x = (-(Nx/2) : (Nx/2 - 1)) * res;   % -200, -198, ..., 198 mm
ct.y = (0       : Ny - 1)      * res;   %    0,    2, ..., 318 mm
ct.z = (-(Nz/2) : (Nz/2 - 1)) * res;   % -200, -198, ..., 198 mm

ct.resolution.x = res;
ct.resolution.y = res;
ct.resolution.z = res;
ct.cubeDim      = [Ny, Nx, Nz];
ct.numOfCtScen  = 1;

ct.cubeHU{1} = zeros(Ny, Nx, Nz, 'single');
ct.cube{1}   = ones( Ny, Nx, Nz, 'single');

%% 3. CST
V_all = (1 : Ny * Nx * Nz)';

% Target: exactly the 20x20 cm² field footprint (±100 mm).
ix_tgt = find(ct.x >= -100 & ct.x <= 100);
iz_tgt = find(ct.z >= -100 & ct.z <= 100);
tgt_mask = false(Ny, Nx, Nz);
tgt_mask(:, ix_tgt, iz_tgt) = true;
V_target = find(tgt_mask);

meta_oar = struct('Priority',2,'Visible',1,'visibleColor',[0 0.5 0], ...
                  'alphaX',0.1,'betaX',0.05,'TissueClass',1);
meta_ptv = struct('Priority',1,'Visible',1,'visibleColor',[1 0 0], ...
                  'alphaX',0.1,'betaX',0.05,'TissueClass',1);

cst = cell(2, 6);
cst{1,1} = 0;  cst{1,2} = 'Water';     cst{1,3} = 'OAR';
cst{1,4} = {V_all};    cst{1,5} = meta_oar;  cst{1,6} = {};
cst{2,1} = 1;  cst{2,2} = 'PTV_20x20'; cst{2,3} = 'TARGET';
cst{2,4} = {V_target}; cst{2,5} = meta_ptv;  cst{2,6} = {};

%% 4. Plan: single AP beam, 20x20 cm², gantry 0°
pln.radiationMode  = 'photons';
pln.machine        = 'TrueBeam_6X';
pln.bioModel       = 'none';
pln.multScen       = 'nomScen';
pln.numOfFractions = 1;

pln.propStf.gantryAngles = 0;
pln.propStf.couchAngles  = 0;
pln.propStf.bixelWidth   = 5;       % 5 mm pencil-beam width (even multiple of
                                    % intConvResolution=0.5mm: 10×0.5 → ok)
pln.propStf.isoCenter    = [0, 0, 0];
pln.propStf.addMargin    = false;   % keep rays at ±100mm; auto-margin would
                                    % expand to ±105mm (~21x21 cm² field)

pln.propDoseCalc.doseGrid.resolution.x = res;
pln.propDoseCalc.doseGrid.resolution.y = res;
pln.propDoseCalc.doseGrid.resolution.z = res;

pln.propDoseCalc.useCustomPrimaryPhotonFluence = true;
pln.propDoseCalc.enableDijSampling             = false;

%% 5. STF
stf = matRad_generateStf(ct, cst, pln);
fprintf('STF: %d rays, bixelWidth = %.0f mm, isoCenter = [%.0f %.0f %.0f] mm\n', ...
    stf.numOfRays, stf.bixelWidth, stf.isoCenter(1), stf.isoCenter(2), stf.isoCenter(3));

%% 6. Dose influence matrix
dij = matRad_calcDoseInfluence(ct, cst, stf, pln);
fprintf('Dose grid: [%d %d %d]\n', dij.doseGrid.dimensions);

%% 7. Reconstruct dose (uniform weights = open field)
w         = ones(dij.totalNumOfBixels, 1);
resultGUI = matRad_calcCubes(w, dij);
doseCube  = resultGUI.physicalDose;   % [Ny, Nx, Nz]

%% 8. Isocenter indices
isoIdx = matRad_world2cubeIndex([0 0 0], dij.doseGrid);
iy0 = isoIdx(1);
ix0 = isoIdx(2);
iz0 = isoIdx(3);
fprintf('Isocenter voxel: iy=%d (y=%.1f mm), ix=%d (x=%.1f mm), iz=%d (z=%.1f mm)\n', ...
    iy0, dij.doseGrid.y(iy0), ix0, dij.doseGrid.x(ix0), iz0, dij.doseGrid.z(iz0));

%% 9. Central-axis PDD
depth_calc_mm = dij.doseGrid.y;
pdd_calc      = double(squeeze(doseCube(:, ix0, iz0)));
if max(pdd_calc) == 0
    error('Central-axis dose is all zero. Check phantom geometry and machine file.');
end
pdd_calc_norm = 100 * pdd_calc / max(pdd_calc);

%% 10. Crossline profiles at specified depths
profile_depths_cm = [1.5, 5, 10, 20, 30];
x_calc_mm  = dij.doseGrid.x;
x_calc_cm  = x_calc_mm / 10;

prof_calc_norm = cell(length(profile_depths_cm), 1);
depth_used_mm  = zeros(length(profile_depths_cm), 1);

for k = 1:length(profile_depths_cm)
    d_mm = profile_depths_cm(k) * 10;
    [~, iy_d] = min(abs(depth_calc_mm - d_mm));
    depth_used_mm(k) = depth_calc_mm(iy_d);
    p    = double(squeeze(doseCube(iy_d, :, iz0)));
    cax  = double(doseCube(iy_d, ix0, iz0));
    prof_calc_norm{k} = 100 * p / cax;
    fprintf('Profile at %.1f cm: nearest grid depth = %.1f mm (row %d)\n', ...
        profile_depths_cm(k), depth_used_mm(k), iy_d);
end

%% 11. Load GBD reference data
gbdDir = '/gpfs/projects/KimGroup/projects/tps/matRad/my_scripts/TrueBeamGBD/6MV Beam Data';

function [pos, val] = readGBDColumn(fpath, hdr_row, dat_row, tag)
    raw  = readcell(fpath);
    hdr  = raw(hdr_row, :);
    col  = find(cellfun(@(h) ischar(h) && contains(h, tag), hdr));
    rows = raw(dat_row:end, :);
    n    = size(rows, 1);
    p    = nan(n,1);
    v    = nan(n,1);
    for i = 1:n
        if isnumeric(rows{i,1}),    p(i) = rows{i,1};    end
        if isnumeric(rows{i,col}),  v(i) = rows{i,col};  end
    end
    ok  = ~isnan(p) & ~isnan(v);
    pos = p(ok);
    val = v(ok);
end

% -- PDD (rows 1-5 metadata, row 6 header, rows 7+ data) --
[depth_meas_cm, pdd_meas_pct] = readGBDColumn( ...
    fullfile(gbdDir, 'Open Field Depth Dose.csv'), 6, 7, '20x20');
depth_meas_mm = depth_meas_cm * 10;
pdd_meas_norm = 100 * pdd_meas_pct / max(pdd_meas_pct);

% -- Profiles (rows 1-7 metadata, row 8 header, rows 9+ data) --
profile_files = { ...
    'Open Field Profiles at 1.5cm.csv', ...
    'Open Field Profiles at 5cm.csv',   ...
    'Open Field Profiles at 10cm.csv',  ...
    'Open Field Profiles at 20cm.csv',  ...
    'Open Field Profiles at 30cm.csv'   };

x_meas_cm_cell      = cell(length(profile_depths_cm), 1);
prof_meas_norm_cell = cell(length(profile_depths_cm), 1);

for k = 1:length(profile_depths_cm)
    [xm, dm] = readGBDColumn(fullfile(gbdDir, profile_files{k}), 8, 9, '20x20');
    cax_m = interp1(xm, dm, 0, 'linear');
    x_meas_cm_cell{k}      = xm;
    prof_meas_norm_cell{k} = 100 * dm / cax_m;
end

%% 12. Plot: PDD comparison
figure('Name','PDD – 20x20 cm², TrueBeam 6X','Position',[50 100 700 500]);
plot(depth_meas_mm, pdd_meas_norm,  'b-',  'LineWidth',1.5,'DisplayName','GBD Measured');
hold on;
plot(depth_calc_mm, pdd_calc_norm,  'r--', 'LineWidth',1.5,'DisplayName','Calculated (matRad)');
xlabel('Depth [mm]');
ylabel('Relative Dose [%]');
title('PDD – TrueBeam 6X, 20×20 cm², SSD=100 cm');
legend('Location','northeast');
grid on;
xlim([0, 320]);
ylim([0, 108]);

%% 13. Plot: profiles at each depth
for k = 1:length(profile_depths_cm)
    figure('Name', sprintf('Profile %.0fcm – 20x20 cm²', profile_depths_cm(k)), ...
           'Position', [50 + (k-1)*55, 650, 680, 430]);
    plot(x_meas_cm_cell{k}, prof_meas_norm_cell{k}, 'b-',  'LineWidth',1.5,'DisplayName','GBD Measured');
    hold on;
    plot(x_calc_cm, prof_calc_norm{k}, 'r--', 'LineWidth',1.5,'DisplayName','Calculated (matRad)');
    xline([-10 10], 'k:', 'LineWidth',0.8);    % field edge markers
    xlabel('Off-axis position [cm]');
    ylabel('Relative Dose [%]');
    title(sprintf('Profile at %.1f cm (grid: %.1f mm) – TrueBeam 6X, 20×20 cm²', ...
          profile_depths_cm(k), depth_used_mm(k)));
    legend('Location','south');
    grid on;
    xlim([-25, 25]);
    ylim([0, 115]);
end

%% 14. Quantitative summary
[~, idMax_calc] = max(pdd_calc_norm);
[~, idMax_meas] = max(pdd_meas_norm);
fprintf('\n=== PDD summary – 20×20 cm² ===\n');
fprintf('  dmax – calc: %.1f mm  |  meas: %.1f mm\n', ...
    depth_calc_mm(idMax_calc), depth_meas_mm(idMax_meas));
for d_cm = [5, 10, 20, 30]
    pdd_c = interp1(depth_calc_mm, pdd_calc_norm, d_cm*10, 'linear', NaN);
    pdd_m = interp1(depth_meas_mm, pdd_meas_norm, d_cm*10, 'linear', NaN);
    fprintf('  PDD at %2d cm  – calc: %5.1f%%  |  meas: %5.1f%%  |  diff: %+.1f%%\n', ...
        d_cm, pdd_c, pdd_m, pdd_c - pdd_m);
end

fprintf('\n=== Profile summary – 20×20 cm² ===\n');
x_check = [2, 5, 8, 10, 12];
for k = 1:length(profile_depths_cm)
    fprintf('  Depth = %.1f cm (grid %.1f mm)\n', ...
        profile_depths_cm(k), depth_used_mm(k));
    for x_off = x_check
        for sgn = [1, -1]
            xq = sgn * x_off;
            pc = interp1(x_calc_cm,            prof_calc_norm{k},      xq, 'linear', NaN);
            pm = interp1(x_meas_cm_cell{k}, prof_meas_norm_cell{k}, xq, 'linear', NaN);
            fprintf('    x = %+.0f cm: calc=%5.1f%%  meas=%5.1f%%  diff=%+.1f%%\n', ...
                xq, pc, pm, pc-pm);
        end
    end
    fwhm_c = calcFWHM(x_calc_cm,            prof_calc_norm{k});
    fwhm_m = calcFWHM(x_meas_cm_cell{k}, prof_meas_norm_cell{k});
    fprintf('    FWHM       – calc: %.3f cm  |  meas: %.3f cm  |  diff: %+.3f cm\n', ...
        fwhm_c, fwhm_m, fwhm_c - fwhm_m);
end

%% 15. Save
save('s9_water_phantom_20x20_6x_results.mat', ...
    'ct','cst','pln','stf','dij','resultGUI','doseCube', ...
    'depth_calc_mm','pdd_calc_norm', ...
    'x_calc_cm','prof_calc_norm','depth_used_mm', ...
    'depth_meas_mm','pdd_meas_norm', ...
    'x_meas_cm_cell','prof_meas_norm_cell', ...
    'profile_depths_cm');
fprintf('\nSaved: s9_water_phantom_20x20_6x_results.mat\n');

%% Local functions
function fwhm = calcFWHM(x, y)
% Return the full width at half maximum (50% level) of a dose profile.
% x must be monotonically increasing; y is normalised so that CAX = 100%.
% Linear interpolation is used to locate each 50% crossing precisely.
    x = x(:);  y = y(:);
    above = y >= 50;
    tr    = diff(above);                      % +1 = rising, -1 = falling
    rise  = find(tr ==  1, 1, 'first');       % leftmost  50% crossing
    fall  = find(tr == -1, 1, 'last');        % rightmost 50% crossing
    if isempty(rise) || isempty(fall)
        fwhm = NaN;  return;
    end
    x_l  = interp1(y(rise:rise+1), x(rise:rise+1), 50);
    x_r  = interp1(y(fall:fall+1), x(fall:fall+1), 50);
    fwhm = x_r - x_l;
end
