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
    sbatch --array=1-5 cox_boot_array.slurm
    ```

3.  After completion, inspect per-task resource use:

    ``` bash
    sacct -j <array_job_id> --array --format=JobID,JobName%20,State,ReqCPUS,ReqMem,MaxRSS,Elapsed,ExitCode
    Rscript --vanilla combine_results.R output/<array_job_id>
    ```

    Compare `ReqMem` to `MaxRSS`, and compare requested `--time` to `Elapsed`.

4.  Use pilot results to right-size a larger final run. For example, after editing `--mem` and `--time` if needed:

    ``` bash
    sbatch --array=6-15 cox_boot_array.slurm
    ```

5.  Combine final results:

    ``` bash
    sbatch combine_results.slurm <array_job_id>
    ```

## Teaching points

- This is a serial R script, so each array task requests `--cpus-per-task=1`.
- The job array provides throughput by running many independent one-core tasks.
- `--array=6-15` means ten tasks are submitted, starting with array id 6.
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

### Walltime does not scale predictably with data size

A natural instinct after a pilot run is to scale walltime linearly: if fitting 1,000 rows took 0.01 sec/bootstrap, then 50,000 rows should take 0.5 sec/bootstrap. That may overestimate or underestimate depending on the model and data size.

Cox model computation includes fixed overhead plus work that grows with the number of rows, sorting, risk-set accumulation, and model complexity. In these pilot results, the `basic` model grows less than linearly from 1k to 50k rows, while the `clinical` model grows worse than linearly from 100k to 200k rows. The lesson is not that one simple multiplier always works; the lesson is that you should measure near the planned production problem.

`combine_results.R` makes this concrete. It prints a scaling table showing `observed_ratio` (actual sec/boot relative to the smallest pilot for that model type) alongside `linear_predicted` (what linear scaling would predict). If `observed_ratio` is much larger than `linear_predicted`, runtime is worse than linear. If it is smaller, fixed overhead or other effects are dominating that interval.

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

### Worked estimate for the final run

The final rows in `params.csv` use the same data size and model as the largest pilot:

- pilot: `pilot_200k_clinical`, `target_n = 200000`, `n_boot = 500`
- final: `final_200k_clinical`, `target_n = 200000`, `n_boot = 2000`

Because the data size and model are the same, estimate final walltime from the measured `sec_per_boot`, not from the smaller 1k/10k/50k pilots. In the example output, `pilot_200k_clinical` has `median_sec_per_boot = 0.7547`.

``` text
estimated_minutes = 0.7547 sec/boot * 2000 bootstraps / 60
                  = 25.2 minutes

with_50_percent_margin = 25.2 * 1.5
                       = 37.8 minutes
```

So a reasonable request for each final task would be around `--time=00:40:00` or `--time=00:45:00`, depending on how conservative you want to be.

For memory, the same pilot reports `max_peak_rss_mb_linux = 332.94`. A 50% margin is about `500 MB`; in practice, round up to a convenient cluster request such as `--mem=1G` or keep `--mem=2G` for a simple, safe default. Compare this with `sacct MaxRSS` as well, because SLURM's accounting value is what many users will see first.

Remember that these are **per-task** requests. Ten final array tasks do not require `10 * 45 minutes` in `--time`; each task gets its own walltime limit. If the scheduler runs all ten at once, the job may allocate up to `10 * --mem` across the cluster while it is running.
