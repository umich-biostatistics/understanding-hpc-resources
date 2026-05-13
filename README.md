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
    sbatch combine_results.slurm <array_job_id>
    ```

## Teaching points

- This is a serial R script, so each array task requests `--cpus-per-task=1`.
- The job array provides throughput by running many independent one-core tasks.
- `--array=5-14` means ten tasks are submitted, starting with array id 5.
- The per-task memory request is not multiplied inside the script, but the cluster may allocate up to `MAX_RUNNING * --mem` while multiple tasks run.
- Use a pilot run to measure actual elapsed time and memory, then request a safety margin rather than guessing.

## Common pitfalls in resource estimation

### Dataset size ≠ memory request

A frequent mistake is to estimate `--mem` from the size of the input data file or the in-memory data frame. This almost always underestimates actual memory use, often by an order of magnitude or more.

The `resource_summary` table produced by `combine_results.R` includes three columns to make this concrete:

| Column | What it measures |
|------------------------------------|------------------------------------|
| `max_data_object_mb` | Size of the data frame as reported by `object.size()` |
| `max_peak_rss_mb_linux` | Peak resident set size of the R process, from `/proc` |
| `rss_to_data_ratio` | `peak_rss / data_object_mb` — the overhead multiplier |

Sources of overhead that make `rss_to_data_ratio` large:

- **R session baseline** — the interpreter and attached packages (e.g., `survival`) consume memory before any data are loaded.
- **Bootstrap resampling** — each iteration allocates a full copy of the dataset (`boot_dat`), plus the model matrix, plus the fitted object, all at the same time.
- **Intermediate objects** — `results_list`, `do.call(rbind, ...)`, and the model internals accumulate alongside the data.

The pilot scenarios in `params.csv` vary `target_n` (1 k → 10 k → 50 k rows) deliberately: comparing `rss_to_data_ratio` across scenarios shows that the ratio is not constant, so you cannot simply scale your memory request linearly from data size. Always measure, then add a safety margin.

### Walltime scales non-linearly with data size

A natural instinct after a pilot run is to scale walltime linearly: if fitting 1,000 rows took 0.01 sec/bootstrap, then 50,000 rows should take 0.5 sec/bootstrap. This is usually wrong.

Cox model computation is roughly O(n log n) or worse in the number of rows — not O(n). The same applies to many statistical models: the work per observation increases as the dataset grows because of sorting, risk-set accumulation, or matrix operations. In practice, a 50× increase in rows may produce a 100–200× increase in time per bootstrap.

`combine_results.R` makes this concrete. After a pilot run with the three `basic` scenarios (1k/10k/50k rows), it prints a scaling table showing `observed_ratio` (actual sec/boot relative to the 1k baseline) alongside `linear_predicted` (what linear scaling would predict). If `observed_ratio` substantially exceeds `linear_predicted`, runtime is superlinear.

**The practical consequence:** pilot at or very near your planned production data size. A pilot with a 1% sample is not safe to extrapolate from unless you have a theoretical model for how complexity grows.

### What happens when you get resource requests wrong

**Out-of-memory (OOM):** When a job exceeds `--mem`, the Linux kernel OOM killer terminates the process. From SLURM's perspective:

- `sacct` shows state `OUT_OF_MEMORY` (or `FAILED` with exit code 137 on some clusters)
- Output files written only at the end of a script will be absent or incomplete
- The job does not automatically retry

**Walltime exceeded:** When a job reaches its `--time` limit, SLURM sends SIGTERM followed shortly by SIGKILL. R does not have a chance to write buffered output cleanly. Any results accumulated in memory — but not yet written to disk — are lost.

This is a structural risk in scripts that write output only at the end: a job killed at 90% completion produces no output at all, which is indistinguishable from a job that failed immediately.

**Diagnostic checkpoint writing:** `cox_boot_array.R` writes a checkpoint file every ~25% of bootstraps. This checkpoint is **diagnostic, not restartable** — the script always starts from bootstrap 1 on resubmission. Its purpose is to help you understand a failure after the fact:

- How far did the job get before it was killed?
- Was it producing valid model fits, or were fits failing?
- A `checkpoint_*.csv` file left in the output directory after a run signals that the job did not complete. The file is removed automatically on successful completion.

``` r
checkpoint_every <- max(5L, as.integer(ceiling(n_boot / 4)))
```

For production scripts where restarting from scratch is expensive, a fuller approach would save RNG state and a bootstrap counter so the script can resume where it left off. That adds meaningful complexity (state validation, deciding whether to resume or start fresh) and is beyond the scope of this example.

## Simple request-sizing rule for this example

After a pilot task at or near your planned data size:

- walltime for same task size: `ceil(pilot_elapsed_minutes * 1.5)`
- walltime for more bootstraps: `ceil(pilot_sec_per_boot * planned_bootstraps * 1.5 / 60)`
- walltime when changing data size: **do not scale linearly** — run a new pilot at the target `n`
- memory: `ceil(max(MaxRSS_from_sacct, peak_rss_mb_linux_from_metrics) * 1.5)` and round up to a convenient GB value
