toolboxRoot = '/gpfs/projects/KimGroup/projects/tps/matRad/photonPencilBeamKernelCalc';

inputDir = fullfile(toolboxRoot,'truebeam_6xfff');

machineName = 'TrueBeam_6XFFF';

machine = ppbkc_generateBaseData(machineName,inputDir);

save('/gpfs/projects/KimGroup/projects/tps/matRad/userdata/machines/photons_TrueBeam_6XFFF.mat','machine','-v7');