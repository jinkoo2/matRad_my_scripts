
addpath(genpath('/gpfs/projects/KimGroup/projects/tps/matRad'));

clear

%dcm_folder = '/gpfs/projects/KimGroup/projects/tps/_sample_plans/eclipse_tps/stereophan_ap_sMLC';
%dcm_folder = '/gpfs/projects/KimGroup/projects/tps/_sample_plans/eclipse_tps/stereophan_ap_IMRT';
%dcm_folder = '/gpfs/projects/KimGroup/projects/tps/_sample_plans/eclipse_tps/stereophan_IMRT_7beams';
%dcm_folder = '/gpfs/projects/KimGroup/projects/tps/_sample_plans/eclipse_tps/stereophan_ap_VMAT';
dcm_folder = '/gpfs/projects/KimGroup/projects/tps/_sample_plans/eclipse_tps/stereophan_VMAT_1beam';

dicomImporter = matRad_DicomImporter(dcm_folder);

dicomImporter = dicomImporter.matRad_scanDicomImportFolder();

dicomImporter.matRad_importDicom();

% set machine to generic
disp('Setting machine to Generic...')
pln.machine = 'Generic';
pln.radiationMode = 'photons';

for i = 1:numel(stf)
    stf(i).machine = 'Generic';
end

% show in GUI
%matRadGUI('ct', ct, 'cst', cst, 'pln', pln, 'result', resultGUI); % TPS dose
