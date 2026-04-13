clear; clc;

inputFile = 'profile_10cm_40x40.txt';

outputFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_6xfff/primflu.dat';

% Load profile
data = readtable(inputFile);

x_cm = data{:,1};
dose = data{:,2};

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