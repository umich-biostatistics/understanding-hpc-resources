#!/bin/bash
#SBATCH --job-name=coxboot
#SBATCH --account=SLURM_ACCOUNT
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:20:00
#SBATCH --array=1-4
#SBATCH --output=logs/%A/%x-%A_%a.out
#SBATCH --error=logs/%A/%x-%A_%a.err

# Edit these module commands for your cluster.
# On some systems: module load R/4.4.0
module load R/4.5

# The R script also records timing and Linux /proc peak RSS in its metrics file.
# GNU time -v adds another useful peak RSS value in the .err log on most Linux clusters.
/usr/bin/time -v Rscript --vanilla cox_boot_array.R params.csv
