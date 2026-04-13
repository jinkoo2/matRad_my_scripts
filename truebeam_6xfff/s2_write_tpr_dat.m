clear; clc;

outputFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_6xfff/tpr.dat';

% Field sizes (mm)
fieldSizes = [30 40 60 80 100 200 300 400];

% Load your pasted table
data = readtable('pdd_pasted_from_excel.txt');

depth_cm = data{:,1};
depth_mm = depth_cm * 10;

pdd = data{:,2:end} / 100;  % convert percent to fraction

% Assemble matrix
tpr = [NaN fieldSizes;
       depth_mm pdd];

fid = fopen(outputFile,'w');

fprintf(fid,'0 ');
fprintf(fid,'%g ',fieldSizes);
fprintf(fid,'\n');

for i=1:length(depth_mm)
    fprintf(fid,'%g ',depth_mm(i));
    fprintf(fid,'%.6f ',pdd(i,:));
    fprintf(fid,'\n');
end

fclose(fid);

fprintf('tpr.dat written to:\n%s\n',outputFile);