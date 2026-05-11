#!/usr/bin/env Rscript

# Combine output from cox_boot_array.R tasks and make simple summaries.
# Usage:
#   Rscript --vanilla combine_results.R output/<array_job_id>
# or, if ARRAY_JOB_ID is exported:
#   Rscript --vanilla combine_results.R

args <- commandArgs(trailingOnly = TRUE)

find_latest_output_dir <- function(root = "output") {
  if (!dir.exists(root)) stop("No output directory found")
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  if (length(dirs) == 0) stop("No output/<job_id> directories found")
  dirs[which.max(file.info(dirs)$mtime)]
}

outdir <- if (length(args) >= 1) {
  args[[1]]
} else {
  job_id <- Sys.getenv("ARRAY_JOB_ID", unset = "")
  if (nzchar(job_id)) file.path("output", job_id) else find_latest_output_dir("output")
}

if (!dir.exists(outdir)) stop("Output directory not found: ", outdir)

read_many <- function(files) {
  if (length(files) == 0) return(NULL)
  do.call(rbind, lapply(files, utils::read.csv, stringsAsFactors = FALSE))
}

safe_max <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (all(is.na(x))) return(NA_real_)
  max(x, na.rm = TRUE)
}

metric_files <- list.files(outdir, pattern = "^metrics_.*\\.csv$", full.names = TRUE)
result_files <- list.files(outdir, pattern = "^boot_.*\\.csv$", full.names = TRUE)

if (length(metric_files) == 0) stop("No metrics_*.csv files found in ", outdir)
metrics <- read_many(metric_files)
results <- read_many(result_files)

# Resource summary: use this after pilot runs to discuss right-sizing requests.
group_keys <- unique(metrics[, c("scenario", "target_n", "model_type"), drop = FALSE])
resource_summary <- do.call(rbind, lapply(seq_len(nrow(group_keys)), function(i) {
  key <- group_keys[i, , drop = FALSE]
  d <- metrics[metrics$scenario == key$scenario &
                 metrics$target_n == key$target_n &
                 metrics$model_type == key$model_type, , drop = FALSE]

  max_peak <- safe_max(d$peak_rss_mb_linux)
  suggested_mem_gb <- if (is.na(max_peak)) NA_real_ else max(2, ceiling(max_peak * 1.5 / 1024))

  data.frame(
    scenario = key$scenario,
    target_n = key$target_n,
    model_type = key$model_type,
    tasks = nrow(d),
    total_bootstraps = sum(d$n_boot),
    median_sec_per_boot = round(stats::median(d$sec_per_boot, na.rm = TRUE), 4),
    max_elapsed_min = round(max(d$elapsed_sec, na.rm = TRUE) / 60, 2),
    suggested_walltime_for_same_task_min = ceiling(max(d$elapsed_sec, na.rm = TRUE) * 1.5 / 60),
    max_data_object_mb = round(max(d$data_object_mb, na.rm = TRUE), 2),
    max_peak_rss_mb_linux = round(max_peak, 2),
    suggested_mem_gb_from_peak_rss = suggested_mem_gb,
    stringsAsFactors = FALSE
  )
}))

combined_metrics_file <- file.path(outdir, "combined_metrics.csv")
resource_summary_file <- file.path(outdir, "resource_summary.csv")
utils::write.csv(metrics, combined_metrics_file, row.names = FALSE)
utils::write.csv(resource_summary, resource_summary_file, row.names = FALSE)

cat("Wrote ", combined_metrics_file, "\n", sep = "")
cat("Wrote ", resource_summary_file, "\n", sep = "")
print(resource_summary)

# Statistical summary: only meaningful when combining tasks from the same scenario.
if (!is.null(results) && nrow(results) > 0) {
  coef_keys <- unique(results[, c("scenario", "term"), drop = FALSE])
  coef_summary <- do.call(rbind, lapply(seq_len(nrow(coef_keys)), function(i) {
    key <- coef_keys[i, , drop = FALSE]
    x <- results$estimate[results$scenario == key$scenario & results$term == key$term]
    x <- x[is.finite(x)]
    data.frame(
      scenario = key$scenario,
      term = key$term,
      n_estimates = length(x),
      mean = mean(x),
      sd = stats::sd(x),
      q025 = unname(stats::quantile(x, 0.025, names = FALSE)),
      q975 = unname(stats::quantile(x, 0.975, names = FALSE)),
      stringsAsFactors = FALSE
    )
  }))
  coef_summary_file <- file.path(outdir, "coefficient_summary.csv")
  utils::write.csv(coef_summary, coef_summary_file, row.names = FALSE)
  cat("Wrote ", coef_summary_file, "\n", sep = "")
}
