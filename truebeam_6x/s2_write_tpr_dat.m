% s2_write_tpr_dat.m  –  TrueBeam 6X (6MV flat)

clear; clc;

outputFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_6x/tpr.dat';
csvFile   = '/gpfs/projects/KimGroup/projects/tps/matRad/my_scripts/TrueBeamGBD/6MV Beam Data/Open Field Depth Dose.csv';

% Read PDD table from Golden Beam Data CSV.
% Rows 1-5 are metadata; row 6 has column headers; rows 7+ are data.
raw = readcell(csvFile);
headerRow = raw(6, :);   % {'Depth [cm]', '3x3cm2', '4x4cm2', ...}
dataRows  = raw(7:end, :);

% Extract field sizes (mm) from column headers (format: 'NxNcm2')
nCols = size(headerRow, 2) - 1;
fieldSizes = zeros(1, nCols);
for k = 1:nCols
    parts = strsplit(headerRow{1+k}, 'x');
    fieldSizes(k) = str2double(parts{1}) * 10;   % cm -> mm
end

depth_cm = cell2mat(dataRows(:, 1));
depth_mm = depth_cm * 10;

pdd = cell2mat(dataRows(:, 2:end)) / 100;   % convert % to fraction (0-1)

% -----------------------------------------------------------------------
% Convert PDD -> TPR using the ISL (inverse-square-law) correction.
%
% The ppbkc engine stores TPR (Tissue Phantom Ratio), which is the depth-
% dose measured at a FIXED source-axis distance.  TPR does NOT include the
% ISL fall-off.  PDD DOES include ISL because as depth increases, the
% distance from the source also increases.
%
% Relationship (SSD = source-to-surface distance):
%   PDD(d) = TPR(d) * [(SSD + d_ref) / (SSD + d)]^2
%   => TPR(d) = PDD(d) * [(SSD + d) / (SSD + d_ref)]^2
%
% For this machine: SSD = SAD = 1000 mm.
% d_ref is the depth of dose maximum (dmax) for each field size; find it
% as the shallowest depth where PDD first reaches its column maximum.
% -----------------------------------------------------------------------
SSD_mm = 1000;   % mm

tpr = zeros(size(pdd));
for col = 1 : size(pdd, 2)
    [~, dmax_idx]  = max(pdd(:, col));
    d_ref_mm       = depth_mm(dmax_idx);          % dmax for this field size
    ISL_factor     = ((SSD_mm + depth_mm) ./ (SSD_mm + d_ref_mm)).^2;
    tpr(:, col)    = pdd(:, col) .* ISL_factor;
    fprintf('Field %d mm: dmax = %.0f mm, TPR(300mm)/PDD(300mm) = %.3f\n', ...
        fieldSizes(col), d_ref_mm, tpr(end,col)/pdd(end,col));
end

% Assemble and write tpr.dat
fid = fopen(outputFile, 'w');

% Header row: "0" placeholder, then field sizes (mm)
fprintf(fid, '0 ');
fprintf(fid, '%g ', fieldSizes);
fprintf(fid, '\n');

% Data rows: depth (mm), then TPR values
for i = 1 : length(depth_mm)
    fprintf(fid, '%g ', depth_mm(i));
    fprintf(fid, '%.6f ', tpr(i, :));
    fprintf(fid, '\n');
end

fclose(fid);
fprintf('\ntpr.dat (PDD->TPR corrected) written to:\n%s\n', outputFile);
