#!/usr/bin/env Rscript

# Cox model bootstrap array task for an HPC resource-estimation workshop.
#
# Each SLURM array task reads one row from params.csv, builds a teaching-sized
# dataset from the freely available survival::lung data, runs a chunk of
# bootstrap Cox proportional hazards model fits, and writes:
#   output/<array_job_id>/boot_<task>_<scenario>.csv
#   output/<array_job_id>/metrics_<task>_<scenario>.csv
#
# The goal is not a scientific lung-cancer analysis. The goal is to show how
# data size, model complexity, and number of bootstrap repetitions affect
# per-task CPU time and memory.

args <- commandArgs(trailingOnly = TRUE)
param_file <- if (length(args) >= 1) args[[1]] else "params.csv"
task_id_value <- if (length(args) >= 2) args[[2]] else Sys.getenv("SLURM_ARRAY_TASK_ID", unset = "1")
task_id <- suppressWarnings(as.integer(task_id_value))

if (is.na(task_id) || task_id < 1) {
  stop("Task id must be a positive integer. In SLURM, set SLURM_ARRAY_TASK_ID; locally, use: Rscript cox_boot_array.R params.csv 1")
}
if (!file.exists(param_file)) {
  stop("Parameter file not found: ", param_file)
}

params <- utils::read.csv(param_file, stringsAsFactors = FALSE)
required_cols <- c("scenario", "chunk", "seed", "target_n", "n_boot", "model_type")
missing_cols <- setdiff(required_cols, names(params))
if (length(missing_cols) > 0) {
  stop("Parameter file is missing columns: ", paste(missing_cols, collapse = ", "))
}
if (task_id > nrow(params)) {
  stop("SLURM_ARRAY_TASK_ID=", task_id, " but params.csv has only ", nrow(params), " rows")
}

p <- params[task_id, , drop = FALSE]
scenario <- as.character(p$scenario)
chunk <- as.integer(p$chunk)
seed <- as.integer(p$seed)
target_n <- as.integer(p$target_n)
n_boot <- as.integer(p$n_boot)
model_type <- as.character(p$model_type)

if (any(is.na(c(chunk, seed, target_n, n_boot))) || target_n < 10 || n_boot < 1) {
  stop("Invalid parameter row for task ", task_id)
}

if (!requireNamespace("survival", quietly = TRUE)) {
  stop("The R package 'survival' is required. Load an R module that includes it, or install.packages('survival').")
}

size_mb <- function(x) as.numeric(utils::object.size(x)) / 1024^2

read_proc_status_mb <- function(field) {
  # Linux-only process memory estimate. Returns NA on non-Linux systems.
  status_file <- "/proc/self/status"
  if (!file.exists(status_file)) return(NA_real_)
  status_lines <- readLines(status_file, warn = FALSE)
  field_line <- grep(paste0("^", field, ":"), status_lines, value = TRUE)
  if (length(field_line) == 0) return(NA_real_)
  kb <- suppressWarnings(as.numeric(sub(".*:\\s*([0-9]+)\\s*kB.*", "\\1", field_line[1])))
  kb / 1024
}

make_formula <- function(model_type) {
  rhs <- switch(
    model_type,
    basic = "age + sex",
    clinical = "age + sex + ph.ecog + wt.loss",
    stop("Unknown model_type: ", model_type, ". Use 'basic' or 'clinical'.")
  )
  stats::as.formula(paste("survival::Surv(time, event) ~", rhs))
}

safe_name <- function(x) gsub("[^A-Za-z0-9_.-]", "_", x)

set.seed(seed)

# Load and minimally clean the example data.
# data("lung", package = "survival")
lung <- lung
base <- lung[, c("time", "status", "age", "sex", "ph.ecog", "wt.loss")]
base <- stats::na.omit(base)
base$event <- as.integer(base$status == 2L)  # lung uses 1=censored, 2=dead.
base$status <- NULL
base$sex <- factor(base$sex, levels = c(1, 2), labels = c("Male", "Female"))

# Build a larger teaching dataset by sampling rows with replacement.
# This lets the instructor scale up data size without downloading large files.
row_index <- sample.int(nrow(base), size = target_n, replace = TRUE)
dat <- base[row_index, , drop = FALSE]
dat$teaching_id <- seq_len(nrow(dat))

form <- make_formula(model_type)

array_job_id <- Sys.getenv("SLURM_ARRAY_JOB_ID", unset = Sys.getenv("SLURM_JOB_ID", unset = "interactive"))
outdir <- file.path("output", array_job_id)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

cat("Starting task\n")
cat("  scenario: ", scenario, "\n", sep = "")
cat("  task_id:  ", task_id, "\n", sep = "")
cat("  chunk:    ", chunk, "\n", sep = "")
cat("  target_n: ", target_n, "\n", sep = "")
cat("  n_boot:   ", n_boot, "\n", sep = "")
cat("  model:    ", deparse(form), "\n", sep = "")
cat("  data object size MB: ", round(size_mb(dat), 2), "\n", sep = "")

start_time <- proc.time()[["elapsed"]]
results_list <- vector("list", n_boot)

for (b in seq_len(n_boot)) {
  boot_index <- sample.int(nrow(dat), size = nrow(dat), replace = TRUE)
  boot_dat <- dat[boot_index, , drop = FALSE]

  fit <- tryCatch(
    suppressWarnings(
      survival::coxph(
        form,
        data = boot_dat,
        ties = "breslow",
        model = FALSE,
        x = FALSE,
        y = FALSE,
        control = survival::coxph.control(iter.max = 20)
      )
    ),
    error = function(e) e
  )

  if (!inherits(fit, "error")) {
    co <- stats::coef(fit)
    results_list[[b]] <- data.frame(
      scenario = scenario,
      chunk = chunk,
      task_id = task_id,
      boot = b,
      term = names(co),
      estimate = as.numeric(co),
      stringsAsFactors = FALSE
    )
  }

  rm(boot_index, boot_dat, fit)
  if (b %% 25 == 0) gc(verbose = FALSE)
}

gc(verbose = FALSE)
elapsed_sec <- proc.time()[["elapsed"]] - start_time
valid <- !vapply(results_list, is.null, logical(1))
valid_fits <- sum(valid)
failed_fits <- n_boot - valid_fits

if (valid_fits > 0) {
  results <- do.call(rbind, results_list[valid])
} else {
  results <- data.frame(
    scenario = character(), chunk = integer(), task_id = integer(),
    boot = integer(), term = character(), estimate = numeric(),
    stringsAsFactors = FALSE
  )
}

peak_rss_mb_linux <- read_proc_status_mb("VmHWM")
current_rss_mb_linux <- read_proc_status_mb("VmRSS")

metrics <- data.frame(
  array_job_id = array_job_id,
  task_id = task_id,
  scenario = scenario,
  chunk = chunk,
  seed = seed,
  target_n = target_n,
  n_boot = n_boot,
  model_type = model_type,
  source_rows_after_na_omit = nrow(base),
  data_object_mb = round(size_mb(dat), 3),
  results_object_mb = round(size_mb(results), 3),
  elapsed_sec = round(elapsed_sec, 3),
  sec_per_boot = round(elapsed_sec / n_boot, 5),
  valid_fits = valid_fits,
  failed_fits = failed_fits,
  peak_rss_mb_linux = round(peak_rss_mb_linux, 3),
  current_rss_mb_linux = round(current_rss_mb_linux, 3),
  r_version = R.version.string,
  stringsAsFactors = FALSE
)

result_file <- file.path(outdir, sprintf("boot_%03d_%s.csv", task_id, safe_name(scenario)))
metrics_file <- file.path(outdir, sprintf("metrics_%03d_%s.csv", task_id, safe_name(scenario)))
utils::write.csv(results, result_file, row.names = FALSE)
utils::write.csv(metrics, metrics_file, row.names = FALSE)

cat("Finished task\n")
cat("  elapsed seconds:       ", round(elapsed_sec, 2), "\n", sep = "")
cat("  seconds per bootstrap: ", round(elapsed_sec / n_boot, 4), "\n", sep = "")
cat("  valid fits:            ", valid_fits, "\n", sep = "")
cat("  failed fits:           ", failed_fits, "\n", sep = "")
cat("  peak RSS MB, Linux:    ", round(peak_rss_mb_linux, 2), "\n", sep = "")
cat("  wrote results:         ", result_file, "\n", sep = "")
cat("  wrote metrics:         ", metrics_file, "\n", sep = "")
