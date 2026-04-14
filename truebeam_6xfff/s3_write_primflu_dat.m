clear; clc;

csvFile    = '/gpfs/projects/KimGroup/projects/tps/matRad/my_scripts/TrueBeamGBD/6FFF Beam Data/Open Field Profiles at 1.5cm.csv';
outputFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_6xfff/primflu.dat';

% Read crossline profile CSV from Golden Beam Data.
% Rows 1-7: metadata; row 8: column headers; rows 9+: data.
raw = readcell(csvFile);
headerRow = raw(8, :);  % {'Off axis position [cm]', 'Field Size: 3x3 cm2', ..., 'Field Size: 40x40 cm2'}

% Find the 40x40 cm2 column by header name
colIdx = find(cellfun(@(h) ischar(h) && contains(h, '40x40'), headerRow));

% Extract off-axis position and 40x40 dose; empty cells come in as missing
dataRows = raw(9:end, :);
n = size(dataRows, 1);
x_cm_all   = nan(n, 1);
dose_all   = nan(n, 1);
for i = 1:n
    if isnumeric(dataRows{i, 1}),      x_cm_all(i)  = dataRows{i, 1};      end
    if isnumeric(dataRows{i, colIdx}), dose_all(i)   = dataRows{i, colIdx}; end
end
valid = ~isnan(x_cm_all) & ~isnan(dose_all);
x_cm = x_cm_all(valid);
dose = dose_all(valid);

% Convert to radius (positive only)
r_cm = abs(x_cm);

% Remove duplicate radii (average symmetric values)
[r_unique,~,idx] = unique(r_cm);
dose_avg = accumarray(idx, dose, [], @mean);

% Convert units
r_mm = r_unique * 10;
fluence = dose_avg / 100;

% Sort by radius
[r_mm, order] = sort(r_mm);
fluence = fluence(order);

% Normalize center exactly to 1
fluence = fluence / fluence(1);

% Write file
fid = fopen(outputFile,'w');

for i = 1:length(r_mm)
    fprintf(fid,'%.3f %.6f\n', r_mm(i), fluence(i));
end

fclose(fid);

fprintf('primflu.dat written:\n%s\n', outputFile);