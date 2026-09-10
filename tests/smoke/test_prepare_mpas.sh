#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

mesh_plan="$(bash "$ROOT/scripts/data/fetch_mesh.sh" --dry-run)"
grep -Fq 'x1.10242.tar.gz' <<<"$mesh_plan"
grep -Fq 'x1.10242.grid.nc' <<<"$mesh_plan"

part_plan="$(bash "$ROOT/scripts/prepare/partition_mesh.sh" --dry-run)"
grep -Fq 'gpmetis' <<<"$part_plan"
grep -Fq '.part.4' <<<"$part_plan"

static_plan="$(bash "$ROOT/scripts/prepare/generate_static.sh" --dry-run)"
grep -Fq 'mpiexec -n 1' <<<"$static_plan"
grep -Fq 'x1.10242.static.nc' <<<"$static_plan"

init_plan="$(bash "$ROOT/scripts/prepare/generate_init.sh" --dry-run)"
grep -Fq 'mpiexec -n 4' <<<"$init_plan"
grep -Fq 'x1.10242.init.nc' <<<"$init_plan"

printf 'PASS MPAS preparation dry-runs\n'
