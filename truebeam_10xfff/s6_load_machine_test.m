% s6_load_machine_test.m  –  TrueBeam 10XFFF (10MV FFF)
% Smoke-test: load the machine file and print meta fields.

cd /gpfs/projects/KimGroup/projects/tps/matRad
addpath(genpath(pwd))

pln.radiationMode = 'photons';
pln.machine = 'TrueBeam_10XFFF';

machine = matRad_loadMachine(pln);
disp(machine.meta)
