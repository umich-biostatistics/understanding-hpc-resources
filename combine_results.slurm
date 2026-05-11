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

# Option 1: submit with ARRAY_JOB_ID set:
#   sbatch --export=ALL,ARRAY_JOB_ID=<array_job_id> combine_results.slurm
# Option 2: omit ARRAY_JOB_ID and combine_results.R will use the newest output/<job_id> directory.
Rscript --vanilla combine_results.R
