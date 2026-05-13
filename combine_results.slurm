#!/bin/bash
#SBATCH --job-name=coxcombine
#SBATCH --account=SLURM_ACCOUNT
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=combine-%j.out
#SBATCH --error=combine-%j.err

set -euo pipefail

module purge
module load R

# Option 1 (recommended): pass array job id as a positional argument:
#   sbatch combine_results.slurm <array_job_id>
# Option 2: pass a full output directory path:
#   sbatch combine_results.slurm output/<array_job_id>
# Option 3 (legacy): export ARRAY_JOB_ID and submit with no positional argument:
#   sbatch --export=ALL,ARRAY_JOB_ID=<array_job_id> combine_results.slurm
# Option 4: omit both and combine_results.R will use newest output/<job_id> directory.
outdir_arg="${1:-}"
if [[ -n "${outdir_arg}" && "${outdir_arg}" =~ ^[0-9]+$ ]]; then
  outdir_arg="output/${outdir_arg}"
fi

if [[ -n "${outdir_arg}" ]]; then
  Rscript --vanilla combine_results.R "${outdir_arg}"
else
  Rscript --vanilla combine_results.R
fi
