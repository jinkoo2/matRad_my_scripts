%% Compare dose profiles along X, Y, Z using physical dose grid center

% --- Get dose grid dimensions ---
[nX, nY, nZ] = size(resultGUI.physicalDose);

% --- X/Y center indices ---
ix = round(nX/2);
iy = round(nY/2);

% --- Z index corresponding to physical Z = 0 ---
[~, iz] = min(abs(ct.z(1:nZ)));  % nearest voxel to z = 0 mm

fprintf('Dose grid center voxel index: [%d %d %d] (Z ~ %.2f mm)\n', ix, iy, iz, ct.z(iz));

% --- Extract raw doses ---
tpsDose = resultGUI.physicalDose;  % already in Gy
mrDose  = result.physicalDose / 100;  % convert from cGy to Gy

% --- Extract dose profiles at center ---
doseX_TPS = squeeze(tpsDose(:, iy, iz));
doseX_MR  = squeeze(mrDose(:, iy, iz));
doseY_TPS = squeeze(tpsDose(ix, :, iz));
doseY_MR  = squeeze(mrDose(ix, :, iz));
doseZ_TPS = squeeze(tpsDose(ix, iy, :));
doseZ_MR  = squeeze(mrDose(ix, iy, :));

% --- Generate coordinate vectors ---
xAxis = ct.x(1:nX);   % dose grid X coordinates
yAxis = ct.y(1:nY);
zAxis = ct.z(1:nZ);

% --- Plot ---
figure('Name','Dose Profiles at Physical Center','Color','w');

subplot(3,1,1);
plot(xAxis, doseX_TPS,'r','LineWidth',1.5); hold on;
plot(xAxis, doseX_MR,'b--','LineWidth',1.5);
xlabel('X [mm]'); ylabel('Dose [Gy]'); title('Dose Profile along X'); grid on;
legend('TPS','matRad');

subplot(3,1,2);
plot(yAxis, doseY_TPS,'r','LineWidth',1.5); hold on;
plot(yAxis, doseY_MR,'b--','LineWidth',1.5);
xlabel('Y [mm]'); ylabel('Dose [Gy]'); title('Dose Profile along Y'); grid on;
legend('TPS','matRad');

subplot(3,1,3);
plot(zAxis, doseZ_TPS,'r','LineWidth',1.5); hold on;
plot(zAxis, doseZ_MR,'b--','LineWidth',1.5);
xlabel('Z [mm]'); ylabel('Dose [Gy]'); title('Dose Profile along Z'); grid on;
legend('TPS','matRad');

sgtitle('Dose Profiles Comparison at Physical Center (matRad converted to Gy)');