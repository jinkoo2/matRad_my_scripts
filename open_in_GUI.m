pln.machine = 'Generic';
pln.radiationMode = 'photons';

for i = 1:numel(stf)
    stf(i).machine = 'Generic';
end

matRadGUI('ct', ct, 'cst', cst, 'pln', pln, 'result', result);