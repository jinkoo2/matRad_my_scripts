# TrueBeam 6XFFF Machine Commissioning for matRad

## Goal
Build a custom photon machine file (`photons_TrueBeam_6XFFF.mat`) for the matRad
Pencil-Beam SVD dose engine from measured water-tank data, and validate it
against those measurements in a simulated water phantom.

---

## Status: in progress

---

## Scripts

| Script | Status | Description |
|--------|--------|-------------|
| `s1_write_of_dat.m` | Done | Writes `of.dat` — square-field output factors (3–40 cm, 9 points) |
| `s2_write_tpr_dat.m` | Done | Writes `tpr.dat` — PDD converted to TPR via ISL correction, 8 field sizes (3–40 cm), 301 depth points (0–30 cm) |
| `s3_write_primflu_dat.m` | Done | Writes `primflu.dat` — radial primary fluence from measured 40×40 cm² profile at 10 cm |
| `s4_create_params_dat.m` | Done | Creates `params.dat` — machine scalars (SAD, SCD, photon_energy, fwhm_gauss, electron_range_intensity) |
| `s5_build_machine.m` | Done | Runs `ppbkc_generateBaseData` and saves `photons_TrueBeam_6XFFF.mat` to `userdata/machines/` |
| `s6_load_machine.m` | Done | Smoke-test: loads the machine via `matRad_loadMachine` and prints `machine.meta` |
| `s7_validate_water_phantom_0.m` | In progress | Water-phantom validation — see details below |
| `s8_validate_truebeam_6xfff.m` | Pending | Extended validation (spherical phantom, PhantomBuilder API) |

---

## Input data (measured, TrueBeam 6XFFF)

| File | Contents |
|------|----------|
| `pdd_pasted_from_excel.txt` | PDD (% depth dose) for 8 square field sizes (3×3 – 40×40 cm²), depths 0–30 cm in 1 mm steps |
| `profile_10cm_40x40.txt` | Inline crossplane profile at 10 cm depth, 40×40 cm² field, off-axis ±26.9 cm in 1 mm steps |

---

## Machine file

**Location:** `matRad/userdata/machines/photons_TrueBeam_6XFFF.mat`

**Required `machine.data` fields** (verified in `matRad_PhotonPencilBeamSVDEngine.isAvailable`):
`betas`, `energy`, `m`, `primaryFluence`, `kernel`, `kernelPos`

**Required `machine.meta` fields:** `SAD`, `SCD`

**Optional fields** (assumed defaults if absent):
- `penumbraFWHMatIso` — defaults to 5 mm
- `weightToMU` — defaults to 100

---

## Bugs found and fixed

### Bug 1 — `s2_write_tpr_dat.m`: PDD passed as TPR (critical)

**Root cause:** `ppbkc_generateBaseData` expects TPR (Tissue Phantom Ratio), which
is free of inverse-square-law (ISL) effects. PDD already contains the ISL fall-off.
The SVD engine then applies ISL again in `calcSingleBixel` via `(SAD/geoDists)²`,
causing a double ISL penalty. At 30 cm depth this underestimates dose by ~40%.

**Fix:** Added ISL correction in `s2_write_tpr_dat.m`:
```
TPR(d) = PDD(d) × [(SSD + d) / (SSD + d_ref)]²
```
where SSD = 1000 mm and d_ref = depth of dose maximum per field size (~13 mm).
After the fix, TPR at 30 cm is ~64% higher than the raw PDD at the same depth.

**Downstream:** Requires re-running `s5_build_machine.m` to regenerate the machine file.

### Bug 2 — `s7_validate_water_phantom_0.m`: FFF primary fluence not enabled

**Root cause:** `useCustomPrimaryPhotonFluence` defaults to `false`, so
`machine.data.primaryFluence` (the FFF cone shape from `primflu.dat`) is never
applied. Every bixel is treated as a flat-top uniform aperture, producing a
flat-topped calculated profile. The measured 6XFFF profile peaks at 100% on-axis
and drops to ~55% at the ±20 cm geometric field edge.

**Fix:** Added to `s7_validate_water_phantom_0.m` (section 4, plan settings):
```matlab
pln.propDoseCalc.useCustomPrimaryPhotonFluence = true;
```
With this enabled, the engine evaluates the primary fluence at each ray's global
off-axis position, correctly scaling outermost bixels to ~55% relative intensity.

**Side effect:** With custom fluence enabled, the kernel FFT convolution runs
per ray (~6400 FFTs for a 40×40 field at 5 mm bixel spacing) instead of once
per beam — significantly increasing computation time.

### Bug 3 — `s5_build_machine.m`: missing `addpath` for ppbkc toolbox

**Fix:** Added `addpath(toolboxRoot)` so `ppbkc_generateBaseData` is found
without requiring the user to manually set the MATLAB path.

---

## s7 — Water Phantom Validation (AP beam, 40×40 cm², SSD=100 cm)

### Phantom design

| Parameter | Value |
|-----------|-------|
| Resolution | 2 mm isotropic |
| Nx (inline) | 300 voxels → x: −300 to +298 mm |
| Ny (depth) | 160 voxels → y: 0 to 318 mm |
| Nz (crossline) | 300 voxels → z: −300 to +298 mm |
| `cubeDim` | `[Ny, Nx, Nz]` = `[160, 300, 300]` |
| HU | 0 (water) everywhere |
| `ct.cube{1}` | Pre-set to 1.0 (rED) to avoid STF density-erase crash |

### Coordinate system (gantry = 0, AP beam)

```
source at (0, −SAD, 0) = (0, −1000, 0) mm
beam travels in +y direction
iso at (0, 0, 0) = phantom surface → SSD = SAD = 1000 mm = 100 cm
```

- `ct.y` starts at **0** (not centered) so that depth 0 = phantom surface = isocenter.
- `cubeDim = [Ny, Nx, Nz]` — MATLAB array order: rows=y, cols=x, slices=z.
- `doseCube(iy, ix, iz)`: depth varies with `iy`, inline with `ix`, crossline with `iz`.

### CST

| Row | Name | Type | Voxels | Purpose |
|-----|------|------|--------|---------|
| 1 | Water | OAR | all | Prevents `ignoreOutsideDensities` from zeroing water outside the PTV |
| 2 | PTV_40x40 | TARGET | x∈[−200,200] mm, z∈[−200,200] mm, all y | Drives STF ray placement for 40×40 cm² field |

### Plan settings

| Parameter | Value |
|-----------|-------|
| `gantryAngles` | 0° |
| `bixelWidth` | 5 mm |
| `isoCenter` | [0, 0, 0] mm |
| `geometricLateralCutOff` | 100 mm |
| `useCustomPrimaryPhotonFluence` | `true` (required for FFF beam) |
| Dose grid resolution | 2 mm isotropic |

### Dose extraction

```matlab
% matRad_world2cubeIndex returns [iy, ix, iz]  (row, col, slice)
isoIdx = matRad_world2cubeIndex([0 0 0], dij.doseGrid);

% PDD along depth (y = rows), AP beam, central axis
pdd_calc = doseCube(:, ix0, iz0);

% Inline profile at 10 cm depth (y = 100 mm → iy_10cm ≈ 51)
prof_calc = doseCube(iy_10cm, :, iz0);
```

### Outputs

- Figure 1: PDD comparison (measured 40×40 vs. calculated), depths 0–310 mm
- Figure 2: Inline profile at 10 cm comparison, off-axis ±30 cm
- Console: dmax, PDD at 5/10/15/20 cm, profile at ±5/10/15/18/20 cm
- `s7_water_phantom_results.mat`

---

## Performance notes

- The SVD photon dose calculation uses single-threaded MATLAB `for` loops over
  rays/bixels. MATLAB's built-in BLAS/FFTW (multi-threaded) is used only for
  internal matrix and FFT operations.
- With `useCustomPrimaryPhotonFluence = true`, the kernel FFT convolution runs
  per ray instead of once per beam. For a 40×40 field at 5 mm bixel spacing
  (~6400 rays), expect 20–60 min on a single core.
- MATLAB Parallel Computing Toolbox (`parfor`) would be needed for loop-level
  parallelization; the current matRad code does not use it.

---

## Known limitations / next steps

- The SVD pencil-beam model does not accurately reproduce scatter beyond the
  `geometricLateralCutOff` range; the calculated profile will drop to near-zero
  outside ±300 mm even if measured scatter is non-zero there.
- `fwhm_gauss` and `electron_range_intensity` in `params.dat` are starting
  estimates; they may need tuning against measured penumbra and surface dose.
- `s8` uses `matRad_PhantomBuilder` (spherical PTV) and may need updates to
  the phantom y-axis convention to match SSD=100 cm.
- Output factor small-field correction is applied internally by `ppbkc_outputFactorCorrection`;
  check if your OF data extends to fields ≤ 3×3 cm² for IMRT accuracy.
