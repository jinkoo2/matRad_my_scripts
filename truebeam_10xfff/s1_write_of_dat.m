% s1_write_of_dat.m  –  TrueBeam 10XFFF (10MV FFF)

clear; clc;

outFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_10xfff/of.dat';
csvFile = '/gpfs/projects/KimGroup/projects/tps/matRad/my_scripts/TrueBeamGBD/10FFF Beam Data/Open field Output Factors.csv';

% Read square-field output factors from Golden Beam Data CSV.
% The CSV is a 2D matrix (field Y x field X); square fields are on the diagonal.
% Header rows: rows 1-6 are metadata; row 7 has X field sizes starting at col 3.
% Data rows start at row 8; col 1 is empty, col 2 is Y field size, cols 3+ are OF values.
raw = readcell(csvFile);

% Extract X field sizes from row 7 (cols 3 onward)
x_sizes = cell2mat(raw(7, 3:end));

% Extract Y field sizes and OF matrix from data rows (row 8 onward)
n_rows = size(raw, 1) - 7;
y_sizes = zeros(n_rows, 1);
of_matrix = zeros(n_rows, numel(x_sizes));
for i = 1:n_rows
    y_sizes(i) = raw{7 + i, 2};
    of_matrix(i, :) = cell2mat(raw(7 + i, 3:end));
end

% Extract diagonal (square fields where X == Y)
[~, ix] = ismember(y_sizes, x_sizes);
valid = ix > 0;
field_cm = y_sizes(valid);
of = of_matrix(sub2ind(size(of_matrix), find(valid), ix(valid)));

% convert to mm
field_mm = field_cm * 10;

data = [field_mm, of];

fid = fopen(outFile, 'w');
if fid == -1
    error('Cannot open output file: %s', outFile);
end

for i = 1:size(data,1)
    fprintf(fid, '%g %.6f\n', data(i,1), data(i,2));
end

fclose(fid);

fprintf('Wrote: %s\n', outFile);
disp(data);
