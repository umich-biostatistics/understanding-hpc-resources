# HPC R resource-estimation example: Cox model bootstrap array

This example is designed for a workshop on estimating resource requests for R jobs on a SLURM cluster.

It uses the small, freely available `survival::lung` dataset, then samples rows with replacement to create teaching-sized datasets. The statistical task is a bootstrap Cox proportional hazards model. The scientific results are not the point; the point is to show how runtime and memory change with:

- data size: `target_n`
- model complexity: `model_type` (`basic` vs `clinical`)
- amount of work per task: `n_boot`
- array concurrency: `--array=START-END`

## Files

- `params.csv`: one row per array task.
- `cox_boot_array.R`: R script run by each array task.
- `cox_boot_array.slurm`: SLURM job-array submission script.
- `combine_results.R`: combines per-task outputs and produces resource summaries.
- `combine_results.slurm`: optional combine job.

## Suggested workshop flow

1.  Edit `cox_boot_array.slurm` and `combine_results.slurm`:

    - set `#SBATCH --account`
    - set `#SBATCH --partition`
    - adjust `module load R` for the local cluster

2.  Run pilot tasks only:

    ``` bash
    sbatch --array=1-4 cox_boot_array.slurm
    ```

3.  After completion, inspect per-task resource use:

    ``` bash
    sacct -j <array_job_id> --array --format=JobID,JobName%20,State,ReqCPUS,ReqMem,MaxRSS,Elapsed,ExitCode
    Rscript --vanilla combine_results.R output/<array_job_id>
    ```

    Compare `ReqMem` to `MaxRSS`, and compare requested `--time` to `Elapsed`.

4.  Use pilot results to right-size a larger final run. For example, after editing `--mem` and `--time` if needed:

    ``` bash
    sbatch --array=5-14 cox_boot_array.slurm
    ```

5.  Combine final results:

    ``` bash
    sbatch --export=ALL,ARRAY_JOB_ID=<array_job_id> combine_results.slurm
    ```

## Teaching points

- This is a serial R script, so each array task requests `--cpus-per-task=1`.
- The job array provides throughput by running many independent one-core tasks.
- `--array=5-14` means ten tasks are submitted, starting with array id 5.
- The per-task memory request is not multiplied inside the script, but the cluster may allocate up to `MAX_RUNNING * --mem` while multiple tasks run.
- Use a pilot run to measure actual elapsed time and memory, then request a safety margin rather than guessing.

## Simple request-sizing rule for this example

After a pilot task:

- walltime for same task size: `ceil(pilot_elapsed_minutes * 1.5)`
- walltime for more bootstraps: `ceil(pilot_sec_per_boot * planned_bootstraps * 1.5 / 60)`
- memory: `ceil(max(MaxRSS_from_sacct, peak_rss_mb_linux_from_metrics) * 1.5)` and round up to a convenient GB value
