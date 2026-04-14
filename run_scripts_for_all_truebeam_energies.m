%% run_scripts_for_all_truebeam_energies.m
% Master script: build machine files and run water-phantom validation
% for all four TrueBeam beam energies.
%
% Calls s5–s9 in each beam folder:
%   s5  – build machine (.mat) from GBD data
%   s6  – smoke-test: load machine and print meta
%   s7  – validate 3x3 cm²   PDD + profiles vs GBD
%   s8  – validate 10x10 cm² PDD + profiles vs GBD
%   s9  – validate 20x20 cm² PDD + profiles vs GBD
%
% Beams:
%   truebeam_6xfff  –  6 MV FFF   (photons_TrueBeam_6XFFF.mat)
%   truebeam_6x     –  6 MV flat  (photons_TrueBeam_6X.mat)
%   truebeam_10xfff – 10 MV FFF   (photons_TrueBeam_10XFFF.mat)
%   truebeam_15x    – 15 MV flat  (photons_TrueBeam_15X.mat)
%
% NOTE: each subscript begins with 'clear; clc', which wipes the shared
% workspace.  All run() paths are computed inline via mfilename('fullpath')
% — a built-in function that survives clear and always returns THIS file's
% path regardless of which subscript is currently executing.

%% ── 6 MV FFF ────────────────────────────────────────────────────────────
fprintf('\n\n=========================================================\n');
fprintf(' TrueBeam 6XFFF  (6 MV FFF)\n');
fprintf('=========================================================\n\n');

fprintf('--- s5: build machine ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6xfff', 's5_build_machine.m'));

fprintf('--- s6: load machine test ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6xfff', 's6_load_machine_test.m'));

fprintf('--- s7: validate 3x3 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6xfff', 's7_validate_pdd_profiles_3x3.m'));

fprintf('--- s8: validate 10x10 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6xfff', 's8_validate_pdd_profiles_10x10.m'));

fprintf('--- s9: validate 20x20 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6xfff', 's9_validate_pdd_profiles_20x20.m'));

%% ── 6 MV flat ───────────────────────────────────────────────────────────
fprintf('\n\n=========================================================\n');
fprintf(' TrueBeam 6X  (6 MV flat)\n');
fprintf('=========================================================\n\n');

fprintf('--- s5: build machine ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6x', 's5_build_machine.m'));

fprintf('--- s6: load machine test ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6x', 's6_load_machine_test.m'));

fprintf('--- s7: validate 3x3 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6x', 's7_validate_pdd_profiles_3x3.m'));

fprintf('--- s8: validate 10x10 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6x', 's8_validate_pdd_profiles_10x10.m'));

fprintf('--- s9: validate 20x20 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_6x', 's9_validate_pdd_profiles_20x20.m'));

%% ── 10 MV FFF ───────────────────────────────────────────────────────────
fprintf('\n\n=========================================================\n');
fprintf(' TrueBeam 10XFFF  (10 MV FFF)\n');
fprintf('=========================================================\n\n');

fprintf('--- s5: build machine ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_10xfff', 's5_build_machine.m'));

fprintf('--- s6: load machine test ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_10xfff', 's6_load_machine_test.m'));

fprintf('--- s7: validate 3x3 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_10xfff', 's7_validate_pdd_profiles_3x3.m'));

fprintf('--- s8: validate 10x10 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_10xfff', 's8_validate_pdd_profiles_10x10.m'));

fprintf('--- s9: validate 20x20 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_10xfff', 's9_validate_pdd_profiles_20x20.m'));

%% ── 15 MV flat ──────────────────────────────────────────────────────────
fprintf('\n\n=========================================================\n');
fprintf(' TrueBeam 15X  (15 MV flat)\n');
fprintf('=========================================================\n\n');

fprintf('--- s5: build machine ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_15x', 's5_build_machine.m'));

fprintf('--- s6: load machine test ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_15x', 's6_load_machine_test.m'));

fprintf('--- s7: validate 3x3 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_15x', 's7_validate_pdd_profiles_3x3.m'));

fprintf('--- s8: validate 10x10 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_15x', 's8_validate_pdd_profiles_10x10.m'));

fprintf('--- s9: validate 20x20 ---\n');
run(fullfile(fileparts(mfilename('fullpath')), 'truebeam_15x', 's9_validate_pdd_profiles_20x20.m'));

%% ── Done ────────────────────────────────────────────────────────────────
fprintf('\n\n=========================================================\n');
fprintf(' All energies complete.\n');
fprintf('=========================================================\n\n');
