% --- Choose middle slice ---
sliceIdx = round(ct.cubeDim(3)/2);

% --- Extract slices ---
ctSlice      = ct.cubeHU{1}(:,:,sliceIdx);
tpsDoseSlice = resultGUI.physicalDose(:,:,sliceIdx);  % TPS dose
mrDoseSlice  = result.physicalDose(:,:,sliceIdx);     % matRad dose

% --- Display ---
figure('Name','TPS vs matRad Dose Comparison','Color','w');

% Show CT background
imshow(ctSlice, [], 'InitialMagnification', 'fit'); 
colormap gray; hold on;

% TPS dose overlay in red
h1 = imshow(tpsDoseSlice); colormap(gca, 'hot'); alpha(h1, 0.4);

% matRad dose overlay in blue
h2 = imshow(mrDoseSlice); colormap(gca, 'cool'); alpha(h2, 0.4);

title(['Axial slice ', num2str(sliceIdx)]);
colorbar;