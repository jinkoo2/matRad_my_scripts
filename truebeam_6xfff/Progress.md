# TrueBeam 6XFFF Machine Commissioning for matRad

## Goal
Build a custom photon machine file (`photons_TrueBeam_6XFFF.mat`) for the matRad
Pencil-Beam SVD dose engine from Varian TrueBeam Golden Beam Data (GBD), and validate
it against those measurements in simulated water phantoms.

---

## Status: in progress

---

## Input data

All measured data comes from the **Varian TrueBeam Golden Beam Data** Excel workbook.
Sheets are extracted to CSV by `TrueBeamGBD/extract_sheets.py` into per-energy folders:

| Folder | Contents |
|--------|----------|
| `TrueBeamGBD/6FFF Beam Data/` | Output factors, PDD, profiles at 1.5/5/10/20/30 cm |
| `TrueBeamGBD/6MV Beam Data/`  | Same structure |
| `TrueBeamGBD/10FFF Beam Data/` | Same structure |
| `TrueBeamGBD/15MV Beam Data/`  | Same structure |

Key CSV files used for 6XFFF commissioning:

| File | Used by | Contents |
|------|---------|----------|
| `Open field Output Factors.csv` | s1 | Square-field OFs, diagonal extracted |
| `Open Field Depth Dose.csv` | s2 | PDD for 8 field sizes (3–40 cm), 301 depth points |
| `Open Field Profiles at 1.5cm.csv` | s3 | 40×40 cm² crossline profile at 1.5 cm depth |
| `Open Field Profiles at 1.5cm.csv` | s7/s8/s9 | GBD reference profiles for validation |
| `Open Field Profiles at 5cm.csv`   | s7/s8/s9 | GBD reference profiles for validation |
| `Open Field Profiles at 10cm.csv`  | s7/s8/s9 | GBD reference profiles for validation |
| `Open Field Profiles at 20cm.csv`  | s7/s8/s9 | GBD reference profiles for validation |
| `Open Field Profiles at 30cm.csv`  | s7/s8/s9 | GBD reference profiles for validation |

---

## Scripts

| Script | Status | Description |
|--------|--------|-------------|
| `s1_write_of_dat.m` | Done | Writes `of.dat` — square-field output factors (3–40 cm) from GBD CSV diagonal |
| `s2_write_tpr_dat.m` | Done | Writes `tpr.dat` — PDD converted to TPR via ISL correction, 8 field sizes, 301 depth points |
| `s3_write_primflu_dat.m` | Done | Writes `primflu.dat` — radial primary fluence from 40×40 cm² profile at **1.5 cm depth** |
| `s4_create_params_dat.m` | Done | Writes `params.dat` — machine scalars (SAD=1000, SCD=345, photon_energy=6, fwhm_gauss=6, etc.) |
| `s5_build_machine.m` | Done | Orchestrates s1–s4, calls `ppbkc_generateBaseData`, saves `photons_TrueBeam_6XFFF.mat` |
| `s6_load_machine.m` | Done | Smoke-test: loads machine via `matRad_loadMachine`, prints `machine.meta` |
| `s7_validate_pdd_profiles_20x20.m` | In progress | Water-phantom validation, 20×20 cm², bixelWidth=5 mm |
| `s8_validate_pdd_profiles_10x10.m` | Done | Water-phantom validation, 10×10 cm², bixelWidth=5 mm |
| `s9_validate_pdd_profiles_3x3.m`   | Done | Water-phantom validation, 3×3 cm², bixelWidth=2 mm |

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

## Validation phantom design (s7/s8/s9)

All three scripts share the same structure:
- Single AP beam, gantry 0°, SSD = 100 cm (isoCenter at phantom surface, y=0)
- `useCustomPrimaryPhotonFluence = true` (required for FFF peaked profile)
- `enableDijSampling = false`
- `addMargin = false` (prevents auto-dilation of target by bixelWidth)
- Outputs: PDD vs GBD, crossline profiles at 1.5/5/10/20/30 cm, FWHM summary

| Script | Field size | Phantom x/z | Phantom y | bixelWidth | Voxels |
|--------|-----------|-------------|-----------|------------|--------|
| s7 | 20×20 cm² | ±200 mm | 0–318 mm | 5 mm | 6.4 M |
| s8 | 10×10 cm² | ±130 mm | 0–318 mm | 5 mm | 2.7 M |
| s9 | 3×3 cm²   | ±80 mm  | 0–318 mm | 2 mm | 1.0 M |

### Coordinate system

```
source at (0, −SAD, 0) = (0, −1000, 0) mm
beam travels in +y direction
isoCenter at (0, 0, 0) = phantom surface → SSD = SAD = 1000 mm
ct.y starts at 0 (depth 0 = surface = isoCenter)
cubeDim = [Ny, Nx, Nz]  (rows=y/depth, cols=x/inline, slices=z/crossline)
```

---

## Bugs found and fixed

### Bug 1 — `s2_write_tpr_dat.m`: PDD passed as TPR (critical)

**Root cause:** `ppbkc_generateBaseData` expects TPR (Tissue Phantom Ratio), which
is free of inverse-square-law (ISL) effects. PDD already contains the ISL fall-off.
The SVD engine then applies ISL again in `calcSingleBixel` via `(SAD/geoDists)²`,
causing a double ISL penalty (~40% underestimate at 30 cm depth).

**Fix:** Added ISL correction in `s2_write_tpr_dat.m`:
```
TPR(d) = PDD(d) × [(SSD + d) / (SSD + d_ref)]²
```
where SSD = 1000 mm and d_ref = depth of dose maximum per field size (~13 mm).

### Bug 2 — FFF primary fluence not enabled

**Root cause:** `useCustomPrimaryPhotonFluence` defaults to `false`, so
`machine.data.primaryFluence` (the FFF cone shape from `primflu.dat`) is never
applied. Every bixel is treated as flat-top, producing a flat calculated profile
instead of the characteristic FFF peak.

**Fix:** All validation scripts include:
```matlab
pln.propDoseCalc.useCustomPrimaryPhotonFluence = true;
```

### Bug 3 — `s5_build_machine.m`: subscript `clear` wiped `scriptDir`

**Root cause:** `run()` shares the caller's workspace. The `clear; clc` at the top
of each subscript (s1–s4) wiped the `scriptDir` variable before the next subscript ran.

**Fix:** Use `mfilename('fullpath')` inline in each `run()` call — it is a built-in
function, not a workspace variable, so it survives `clear`.

### Bug 4 — `s8/s9`: auto target margin inflates field size

**Root cause:** `matRad_StfGeneratorBase` has `addMargin=true` by default, which
expands the target bounding box by one `bixelWidth` before projecting rays. For a
10×10 field at 5 mm bixelWidth this shifts rays from ±50 mm to ±55 mm (~11×11 field).

**Fix:** `pln.propStf.addMargin = false` in all validation scripts.

### Bug 5 — SVD engine crash with odd-multiple bixelWidth (e.g., 2.5 mm)

**Root cause:** `intConvResolution = 0.5 mm`. The engine uses:
- `fieldLimit = ceil(bw / (2 * intConvRes))` → kernel grid half-size
- `Fpre = ones(floor(bw / intConvRes))` → fluence prefilter size

These agree only when `bw` is an **even multiple** of 0.5 mm. For `bw = 2.5 mm`
(odd multiple: 5×0.5), `fieldLimit` gives a 6×6 grid but `Fpre` is 5×5 → size
mismatch crash at `Fx = F .* Psi`.

**Fix:** Use bixelWidths that are even multiples of 0.5 mm (e.g., 2, 4, 5, 10 mm).
For s9 (3×3 field) use 2 mm; for s7/s8 use 5 mm.

---

## Performance notes

- `useCustomPrimaryPhotonFluence = true` forces per-ray kernel FFT convolution
  instead of once per beam — significantly increases computation time.
- MATLAB SVD engine is single-threaded; no `parfor` parallelisation.
- Approximate runtimes (single core): s9 (~5 min), s8 (~15 min), s7 (~60 min).

---

## Known limitations / next steps

- `fwhm_gauss` (6 mm) and `electron_range_intensity` (0.001) in `params.dat` are
  initial estimates; may need tuning against measured penumbra and surface dose.
- Only square field sizes are commissioned; IMRT MLC shapes are approximated by
  bixel superposition.
- s7 (20×20) PDD match needs verification after switching from bixelWidth=10 mm
  to 5 mm; large bixels underrepresent scatter build-up at depth.
