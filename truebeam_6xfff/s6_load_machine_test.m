cd /gpfs/projects/KimGroup/projects/tps/matRad
addpath(genpath(pwd))

pln.radiationMode = 'photons';
pln.machine = 'TrueBeam_6XFFF';

machine = matRad_loadMachine(pln);
disp(machine.meta)