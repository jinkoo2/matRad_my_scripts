% s4_create_params_dat.m
% Write params.dat for the TrueBeam 6XFFF photon pencil-beam kernel.

clear; clc;

outputFile = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc/truebeam_6xfff/params.dat';

fid = fopen(outputFile, 'w');
if fid == -1
    error('Cannot open output file: %s', outputFile);
end

fprintf(fid, 'SAD 1000.0\n');
fprintf(fid, 'photon_energy 6.0\n');
fprintf(fid, 'fwhm_gauss %f\n',               6.0);
fprintf(fid, 'electron_range_intensity %g\n',  0.001);
fprintf(fid, '# primary collimator\n');
fprintf(fid, 'source_collimator_distance %f\n', 345.0);
fprintf(fid, 'source_tray_distance %f\n',       565.0);
fprintf(fid, '# use this ssd to measure the output factor\n');
fprintf(fid, 'dose_reference_ssd %f\n',         950.0);
fprintf(fid, '# depth to measure output factor\n');
fprintf(fid, 'dose_reference_depth %f\n',        50.0);

fclose(fid);
fprintf('Wrote: %s\n', outputFile);
