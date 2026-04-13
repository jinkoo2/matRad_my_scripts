% write_of_dat_truebeam_6xfff.m

clear; clc;

outFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_6xfff/of.dat';

% square field sizes from Golden Beam Data [cm]
field_cm = [3 4 5 7 10 15 20 30 40]';

% corresponding square-field output factors
of = [0.896 0.921 0.940 0.970 1.000 1.029 1.049 1.072 1.080]';

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