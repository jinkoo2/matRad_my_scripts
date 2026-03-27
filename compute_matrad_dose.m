addpath(genpath('/gpfs/projects/KimGroup/projects/tps/matRad'));

% set machine to Generic
pln.machine = 'Generic';
pln.radiationMode = 'photons';

for i = 1:numel(stf)
    stf(i).machine = 'Generic';
end

% Compute matRad dose
%dij = matRad_calcDoseInfluence(ct, cst, stf, pln);
%result = matRad_calcDoseForward(ct, cst, stf, pln, ones(size(dij.w)));
% assume weights are stored in stf
result = matRad_calcDoseForward(ct, cst, stf, pln);

% Show in GUI
%matRadGUI('ct', ct, 'cst', cst, 'pln', pln, 'result', result); % matRad dose
