#!/bin/bash
#SBATCH --job-name=coxcombine
#SBATCH --account=SLURM_ACCOUNT
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=logs/%x/%j.out
#SBATCH --error=logs/%x/%j.err

module purge
module load R

# Option 1 (recommended): pass array job id as a positional argument:
#   sbatch combine_results.slurm <array_job_id>
# Option 2: omit and combine_results.R will use newest output/<job_id> directory.

outdir_arg="${1:-}"
if [[ -n "${outdir_arg}" && "${outdir_arg}" =~ ^[0-9]+$ ]]; then
  outdir_arg="output/${outdir_arg}"
fi

if [[ -n "${outdir_arg}" ]]; then
  Rscript --vanilla combine_results.R "${outdir_arg}"
else
  Rscript --vanilla combine_results.R
fi
