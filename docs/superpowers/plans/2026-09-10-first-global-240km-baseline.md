# First Global 240 km Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar o `MPAS_Compilation` em um ambiente que, além de ensinar a compilação, também reproduza automaticamente um caso MPAS-Atmosphere completo com ERA5, malha `x1.10242`, uma hora de integração e validação PASS/FAIL.

**Architecture:** A automação será dividida em scripts pequenos e idempotentes, com configuração comum em `scripts/lib/common.sh`. O caso oficial ficará versionado em `cases/first-global-240km/`, enquanto dados grandes e saídas irão para `work/` e `data/`. O pipeline final chamará as etapas de aquisição, build, WPS, static, init, atmosphere e validação sem esconder os comandos científicos usados.

**Tech Stack:** Bash, Python 3, cdsapi, Docker, MPICH, WPS 4.5, MPAS-Atmosphere 8.4.1, HDF5 paralelo, NetCDF-C/Fortran, PnetCDF, PIO, METIS.

**Spec:** `docs/superpowers/specs/2026-09-10-first-global-240km-baseline-design.md`

## Global Constraints

- MPAS-Atmosphere: `v8.4.1`.
- Malha global oficial: `x1.10242`, aproximadamente 240 km.
- ERA5 inicial: `2014-09-10 00 UTC`.
- Duração: 1 hora.
- `dt = 1200 s`.
- Execução oficial: 4 ranks MPI.
- Runtime MPI: MPICH; não substituir por OpenMPI.
- Sistema base: Ubuntu 24.04.
- Credenciais CDS nunca entram na imagem nem no Git.
- GRIB, WPS intermediate, malhas, NetCDFs, history, diagnostics e logs locais não são versionados.
- O caso valida integração e sanity básico; não mede forecast skill.

---

### Task 1: Configuração comum, layout do caso e exclusão de artefatos

**Files:**
- Create: `scripts/lib/common.sh`
- Create: `cases/first-global-240km/case.env`
- Create: `tests/smoke/test_case_config.sh`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: ambiente atual do container (`/build/WPS`, `/mpas/MPAS-Model`, `/dependencias/*`).
- Produces: `load_case_env`, `require_command`, `require_file`, `log_info`, `log_error`, `run_logged`; variáveis `CASE_ROOT`, `DATA_ROOT`, `WORK_ROOT`, `WPS_ROOT`, `MPAS_ROOT`, `MESH_FILE`, `WPS_GEOG`, `MPI_RANKS`, `START_DATE`, `END_DATE`, `RUN_DURATION`, `DT`.

- [ ] **Step 1: Write the failing smoke test**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/common.sh"
load_case_env "$ROOT/cases/first-global-240km/case.env"
[[ "$START_DATE" == "2014-09-10_00:00:00" ]]
[[ "$END_DATE" == "2014-09-10_01:00:00" ]]
[[ "$MPI_RANKS" == "4" ]]
[[ "$DT" == "1200" ]]
printf 'PASS case config\n'
```

- [ ] **Step 2: Run the test and confirm it fails before the files exist**

Run: `bash tests/smoke/test_case_config.sh`
Expected: FAIL because `scripts/lib/common.sh` is absent.

- [ ] **Step 3: Implement `case.env` and `common.sh`**

`case.env` must contain exactly the baseline defaults and allow environment overrides via shell expansion. `common.sh` must resolve repository paths from its own location and expose reusable validation/logging helpers.

- [ ] **Step 4: Expand `.gitignore`**

Add patterns for `data/`, `work/`, `*.grib`, `FILE:*`, `PFILE:*`, `*.nc`, `*.log`, `history.*`, `diag.*`, meshes downloaded locally, `.cdsapirc`, while keeping versioned JSON, namelists and documentation visible.

- [ ] **Step 5: Run the smoke test**

Run: `bash tests/smoke/test_case_config.sh`
Expected: `PASS case config`.

- [ ] **Step 6: Commit**

```bash
git add .gitignore scripts/lib/common.sh cases/first-global-240km/case.env tests/smoke/test_case_config.sh
git commit -m "feat: add baseline case configuration"
```

---

### Task 2: ERA5 oficial e download idempotente

**Files:**
- Create: `cases/first-global-240km/era5/pressure-levels.json`
- Create: `cases/first-global-240km/era5/single-levels.json`
- Create: `scripts/data/download_era5.py`
- Create: `tests/smoke/test_era5_requests.py`
- Modify: `dados-era5/baixar_era5.py`

**Interfaces:**
- Consumes: `DATA_ROOT`, credencial CDS do host e os dois JSONs versionados.
- Produces: `era5_pressure_levels.grib` e `era5_single_levels.grib` no diretório de dados.

- [ ] **Step 1: Write request tests with stdlib `unittest`**

```python
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]

class Era5RequestTest(unittest.TestCase):
    def test_pressure_request_uses_official_baseline(self):
        req = json.loads((ROOT / "cases/first-global-240km/era5/pressure-levels.json").read_text())
        self.assertEqual(req["year"], ["2014"])
        self.assertEqual(req["month"], ["09"])
        self.assertEqual(req["day"], ["10"])
        self.assertIn("00:00", req["time"])

    def test_single_request_is_global(self):
        req = json.loads((ROOT / "cases/first-global-240km/era5/single-levels.json").read_text())
        self.assertNotIn("area", req)

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run and confirm failure**

Run: `python3 tests/smoke/test_era5_requests.py -v`
Expected: FAIL because JSON files do not exist.

- [ ] **Step 3: Add versioned requests**

Pressure levels must include geopotential, temperature, relative humidity, U and V wind over the standard pressure levels needed by the MPAS initialization. Single levels must include the surface fields required by the WPS/MPAS path, including 2 m temperature/dewpoint, 10 m wind, surface pressure, mean sea-level pressure, SST/skin temperature and land/soil fields needed by initialization.

- [ ] **Step 4: Implement `download_era5.py`**

The script must: load JSON requests, refuse to run without a readable CDS credential, create the destination directory, skip non-empty existing GRIB files unless `--force` is passed, and download each dataset separately with `cdsapi.Client().retrieve(...)`.

- [ ] **Step 5: Replace the current malformed legacy downloader**

Remove the Markdown code fences currently present in `dados-era5/baixar_era5.py` and make it a thin compatibility entry point that imports/calls the new downloader instead of keeping a second hard-coded 2025 case.

- [ ] **Step 6: Run tests**

Run: `python3 tests/smoke/test_era5_requests.py -v`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add cases/first-global-240km/era5 scripts/data/download_era5.py dados-era5/baixar_era5.py tests/smoke/test_era5_requests.py
git commit -m "feat: add reproducible ERA5 acquisition"
```

---

### Task 3: Build automation and environment preflight

**Files:**
- Create: `scripts/prepare/build_tools.sh`
- Create: `scripts/validate/preflight.sh`
- Create: `tests/smoke/test_preflight.sh`
- Modify: `Dockerfile`

**Interfaces:**
- Consumes: stack `/dependencias`, WPS source, MPAS source.
- Produces: verified `ungrib.exe`, `init_atmosphere_model`, `atmosphere_model`.

- [ ] **Step 1: Write smoke test using a temporary fake environment**

Test that `preflight.sh` exits non-zero and names the missing component when `MPAS_ROOT` points to an empty directory, then succeeds in `--config-only` mode when only repository configuration is being checked.

- [ ] **Step 2: Implement `preflight.sh`**

Check `python3`, `mpiexec`, `mpicc`, `mpif90`, `nc-config`, `nf-config`, `pnetcdf-config` when available, `gpmetis`, directories, readable case config, and required input paths. Add `--config-only` so repository-level tests do not require a complete scientific runtime.

- [ ] **Step 3: Implement `build_tools.sh`**

Use existing MPICH wrappers and exported `NETCDF`, `PNETCDF`, `PIO`. Compile only missing targets. For WPS, configure GNU Linux and build `ungrib`. For MPAS run:

```bash
make -j"${BUILD_JOBS:-$(nproc)}" gnu CORE=init_atmosphere USE_PIO2=true
make -j"${BUILD_JOBS:-$(nproc)}" gnu CORE=atmosphere USE_PIO2=true
```

After each build verify executable presence and `ldd` output contains no `not found`.

- [ ] **Step 4: Modify Dockerfile only for automation prerequisites**

Ensure `python3` can run the output validator by installing `python3-netcdf4` or an isolated venv dependency; keep MPICH, parallel HDF5, existing dependency prefixes and manual-build philosophy unchanged. Copy the `cases/` directory in addition to `scripts/` so the container can run the official case.

- [ ] **Step 5: Run smoke tests**

Run: `bash tests/smoke/test_preflight.sh`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Dockerfile scripts/prepare/build_tools.sh scripts/validate/preflight.sh tests/smoke/test_preflight.sh
git commit -m "feat: automate build and environment checks"
```

---

### Task 4: WPS/ungrib preparation

**Files:**
- Create: `cases/first-global-240km/wps/namelist.wps`
- Create: `scripts/prepare/prepare_wps.sh`
- Create: `tests/smoke/test_prepare_wps.sh`
- Modify: `scripts/prepare_wps_era5.sh`

**Interfaces:**
- Consumes: two ERA5 GRIB files and WPS `Vtable.ECMWF`.
- Produces: WPS intermediate files under `${WORK_ROOT}/wps`.

- [ ] **Step 1: Write a dry-run smoke test**

Run `prepare_wps.sh --dry-run` against temporary fake GRIB files and assert the output contains the commands for `link_grib.csh`, Vtable linking and `ungrib.exe` without executing them.

- [ ] **Step 2: Implement `prepare_wps.sh`**

Copy the versioned namelist into the work directory, create GRIB links, link the ECMWF Vtable, execute `ungrib.exe`, save `ungrib.log`, fail on non-zero exit or missing `FILE:*`, and skip execution when valid intermediate files already exist unless `--force` is passed.

- [ ] **Step 3: Replace legacy script with wrapper**

`scripts/prepare_wps_era5.sh` must print a deprecation/compatibility message and `exec` the new `scripts/prepare/prepare_wps.sh` with the same arguments.

- [ ] **Step 4: Run the dry-run smoke test**

Run: `bash tests/smoke/test_prepare_wps.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add cases/first-global-240km/wps/namelist.wps scripts/prepare/prepare_wps.sh scripts/prepare_wps_era5.sh tests/smoke/test_prepare_wps.sh
git commit -m "feat: automate ERA5 WPS preparation"
```

---

### Task 5: Mesh, static e init

**Files:**
- Create: `scripts/data/fetch_mesh.sh`
- Create: `cases/first-global-240km/static/namelist.init_atmosphere`
- Create: `cases/first-global-240km/static/streams.init_atmosphere`
- Create: `cases/first-global-240km/init/namelist.init_atmosphere`
- Create: `cases/first-global-240km/init/streams.init_atmosphere`
- Create: `scripts/prepare/generate_static.sh`
- Create: `scripts/prepare/generate_init.sh`
- Create: `tests/smoke/test_prepare_mpas.sh`

**Interfaces:**
- Consumes: `x1.10242.grid.nc`, WPS_GEOG, WPS intermediate files, `init_atmosphere_model`.
- Produces: `${WORK_ROOT}/static/static.nc` and `${WORK_ROOT}/init/init.nc`.

- [ ] **Step 1: Add dry-run tests**

Check that each script rejects missing mesh/input files in normal mode and prints the exact `mpiexec -n 4 .../init_atmosphere_model` command in `--dry-run` mode.

- [ ] **Step 2: Implement `fetch_mesh.sh`**

Support `MESH_FILE` override. If the target already exists and is non-empty, return success. Otherwise print the documented official source location and download only when `MESH_URL` is explicitly provided; this avoids embedding an unverified URL.

- [ ] **Step 3: Add static configuration and generator**

Materialize a run directory, copy MPAS default inputs required by the case, overlay the versioned namelist/streams, link the mesh and WPS_GEOG, execute `init_atmosphere_model`, log output and require a non-empty `static.nc`.

- [ ] **Step 4: Add init configuration and generator**

Link/copy `static.nc` plus WPS intermediate data, execute the initialization mode, log output and require a non-empty `init.nc`.

- [ ] **Step 5: Run dry-run tests**

Run: `bash tests/smoke/test_prepare_mpas.sh`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/data/fetch_mesh.sh cases/first-global-240km/static cases/first-global-240km/init scripts/prepare/generate_static.sh scripts/prepare/generate_init.sh tests/smoke/test_prepare_mpas.sh
git commit -m "feat: automate MPAS static and init stages"
```

---

### Task 6: Atmosphere run and output validator

**Files:**
- Create: `cases/first-global-240km/atmosphere/namelist.atmosphere`
- Create: `cases/first-global-240km/atmosphere/streams.atmosphere`
- Create: `scripts/run/run_atmosphere.sh`
- Create: `scripts/validate/validate_outputs.py`
- Create: `tests/smoke/test_validate_outputs.py`

**Interfaces:**
- Consumes: `init.nc`, `atmosphere_model`.
- Produces: history/diagnostics NetCDFs and machine-readable validation summary.

- [ ] **Step 1: Write validator unit tests**

Use temporary NetCDF fixtures created by `netCDF4.Dataset`; assert PASS for finite dimensions/time/fields and FAIL for a fixture containing NaN.

- [ ] **Step 2: Implement `validate_outputs.py`**

Accept one or more NetCDF paths, verify they open, have non-zero dimensions, contain a time coordinate/`xtime` when expected, and scan numeric variables in chunks for NaN/Inf. Print one `PASS`/`FAIL` line per file and exit non-zero on any failure.

- [ ] **Step 3: Implement official atmosphere configuration**

Set `config_start_time='2014-09-10_00:00:00'`, `config_run_duration='01:00:00'`, `config_dt=1200.0`, and streams that produce history and diagnostics for the one-hour integration.

- [ ] **Step 4: Implement `run_atmosphere.sh`**

Prepare `${WORK_ROOT}/atmosphere`, link `init.nc` and required lookup tables, execute `mpiexec -n "${MPI_RANKS:-4}" atmosphere_model`, save the log, reject `ERROR|FATAL|abort` patterns when they represent MPAS fatal output, and require history/diagnostic products.

- [ ] **Step 5: Run validator tests**

Run: `python3 tests/smoke/test_validate_outputs.py -v`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add cases/first-global-240km/atmosphere scripts/run/run_atmosphere.sh scripts/validate/validate_outputs.py tests/smoke/test_validate_outputs.py
git commit -m "feat: run and validate one-hour MPAS baseline"
```

---

### Task 7: Final case runner and PASS/FAIL report

**Files:**
- Create: `scripts/validate/final_case.sh`
- Create: `scripts/run/full_pipeline.sh`
- Create: `tests/smoke/run_all.sh`

**Interfaces:**
- Consumes: all earlier scripts.
- Produces: end-to-end orchestration and `work/logs/summary.txt`.

- [ ] **Step 1: Implement `tests/smoke/run_all.sh`**

Execute all repository-only smoke tests in deterministic order and stop at first failure.

- [ ] **Step 2: Implement `final_case.sh`**

Check expected WPS, static, init, atmosphere and diagnostic outputs, call the Python NetCDF validator and print a compact table with `WPS`, `STATIC`, `INIT`, `ATMOSPHERE`, `NETCDF_SANITY` marked PASS/FAIL.

- [ ] **Step 3: Implement `full_pipeline.sh`**

Execute:

```text
preflight -> download ERA5 -> build tools -> prepare WPS -> fetch/verify mesh -> static -> init -> atmosphere -> final validation
```

Support `SKIP_DOWNLOAD=1`, `SKIP_BUILD=1` and `FORCE=1`; preserve stage logs under `${WORK_ROOT}/logs`.

- [ ] **Step 4: Run repository smoke suite**

Run: `bash tests/smoke/run_all.sh`
Expected: all repository-level tests PASS without requiring ERA5 download.

- [ ] **Step 5: Commit**

```bash
git add scripts/validate/final_case.sh scripts/run/full_pipeline.sh tests/smoke/run_all.sh
git commit -m "feat: add end-to-end MPAS ERA5 pipeline"
```

---

### Task 8: Documentation and final verification

**Files:**
- Create: `docs/cases/first-global-240km.md`
- Create: `docs/reproducibility/end-to-end.md`
- Create: `docs/testing/validation-matrix.md`
- Modify: `docs/wps/README.md`
- Modify: `docs/wps/INSTALACAO.md`
- Modify: `docs/wps/ungrib.md`
- Modify: `docs/mpas/COMPILACAO.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: final command names and case layout.
- Produces: a user path from clone to PASS/FAIL.

- [ ] **Step 1: Document the baseline**

State the fixed date, mesh, duration, dt, 4 MPI ranks, required external data, outputs and scientific limitations.

- [ ] **Step 2: Write the end-to-end guide**

Include concrete commands:

```bash
docker build -t mpas .
docker run --rm -it \
  -v "$HOME/.cdsapirc:/root/.cdsapirc:ro" \
  -v "$PWD/data:/dados" \
  -v "$PWD/work:/workspace/work" \
  mpas bash
./scripts/validate/preflight.sh
./scripts/run/full_pipeline.sh
```

Explain the environment overrides and how to resume stages.

- [ ] **Step 3: Complete the WPS docs and update MPAS compilation docs**

Explain WPS/ungrib specifically for ERA5 and distinguish manual compilation from automated preparation.

- [ ] **Step 4: Update root README**

Present both learning paths: manual build and reproducible baseline. Include `bash tests/smoke/run_all.sh` and `./scripts/run/full_pipeline.sh` as the principal verification commands.

- [ ] **Step 5: Run static repository verification**

Run:

```bash
bash -n scripts/lib/common.sh scripts/data/fetch_mesh.sh scripts/prepare/*.sh scripts/run/*.sh scripts/validate/*.sh
python3 -m py_compile scripts/data/download_era5.py scripts/validate/validate_outputs.py tests/smoke/test_era5_requests.py
bash tests/smoke/run_all.sh
```

Expected: no syntax errors and repository-level smoke suite PASS.

- [ ] **Step 6: Run the scientific pipeline where Docker/network/data are available**

Run: `./scripts/run/full_pipeline.sh`
Expected final report: `WPS PASS`, `STATIC PASS`, `INIT PASS`, `ATMOSPHERE PASS`, `NETCDF_SANITY PASS`.

- [ ] **Step 7: Commit**

```bash
git add README.md docs
git commit -m "docs: document reproducible MPAS ERA5 baseline"
```
