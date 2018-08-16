# Component stats extraction ----------------------------------------------

# This script contains functions for extracting statistics from the raw data
# (uupu_batch, seam_batch) for interaction analyses between over project x MBI -
# groupings.

# Sourcing component definitions to use when binding stats.
source("mmn/component_definitions.R")

# Redoing batch stats function so it can deal interactively with problems with
# misaligned amplitude measurement windows. # NOTE: This new implementation now
# requires that uupu and seam component lookup table contain entries with
# identical names. Also hardcoded to work only with groupings 00 and 11.

# Another wrapper for the more advanced stats function.
wrap_stats2 <- function(groupings = c("00", "11"), max_diff = 30)
{
  stimuli_codes <- c("std","condur", "den", "fre", "int", "loc", "Nangry",
                     "Nhappy", "noise", "Nsad", "omission1", "omission2",
                     "vowcha1", "vowcha2", "vowdur1", "vowdur2")
  batch_stats2(stimuli = stimuli_codes, uupu_batch = uupu_batch,
               seam_batch = seam_batch, groupings = groupings,
               max_diff = max_diff)
}
# Main wrapper function for directing the calls to get stats per stimulus x
# component pairings.
batch_stats2 <- function(stimuli, uupu_batch, seam_batch, max_diff = 30,
                         groupings = c("11", "00"))
{
  # Making sure subjects with low trialcounts are removed.
  uupu_batch_ <- map(uupu_batch, ~.[!.$subject %in% DROP_SUBJ, ])
  seam_batch_ <- map(seam_batch, ~.[!.$subject %in% DROP_SUBJ, ])
  # Dropping subjects with missing grouping factor.
  uupu_batch_ <- map(uupu_batch_, ~.[!is.na(.$grouping),])
  seam_batch_ <- map(seam_batch_, ~.[!is.na(.$grouping),])
  # Holder of final output.
  out_final <- vector("list", 0)
  for (stim in stimuli) {
    cat("\n", stim)
    # Getting the entry in stimuli lookup-table.
    stim_lookup <- stimuli_lookup[[stim]]
    uupu_b <- uupu_batch_[[stim_lookup$erpid_name]]
    seam_b <- seam_batch_[[stim_lookup$erpid_name]]
    # Splitting into sets to be processed separately at a later stage.
    for (comp in stim_lookup$components) {
      cat("", comp, "")
      # Fetching the corresponding entries in per-project lookup-tables.
      ucl <- uupu_component_lookup[[comp]]
      scl <- seam_component_lookup[[comp]]
      u_win <- stim_lookup$onset + ucl$window
      s_win <- stim_lookup$onset + scl$window
      uupu_calc_b <- uupu_b; seam_calc_b <- seam_b
      # Differencing data should it be necessary.
      if (ucl$difference & scl$difference) {
        # Implementing waveform differencing via left_joins to make sure data
        # are aligned properly.
        uupu_calc_b <-
          left_join(uupu_calc_b, uupu_batch_$std %>%
                      rename(std_amp = amplitude) %>%
                      select(channel, time, subject, std_amp),
                    by = c("channel", "time", "subject")) %>%
          mutate(amplitude = amplitude - std_amp) %>% select(-std_amp)
        seam_calc_b <-
          left_join(seam_calc_b, seam_batch_$std %>%
                      rename(std_amp = amplitude) %>%
                      select(channel, time, subject, std_amp),
                    by = c("channel", "time", "subject")) %>%
          mutate(amplitude = amplitude - std_amp) %>% select(-std_amp)
      }
      # Iterating through the given groupings to generate first draft of the
      # dataset.
      uupu_b_split <- split(uupu_calc_b, uupu_calc_b$grouping)
      seam_b_split <- split(seam_calc_b, seam_calc_b$grouping)
      the_res <- map_dfr(groupings, function(grouping)
      {
        uupu_gb <- uupu_b_split[[grouping]]; seam_gb <- seam_b_split[[grouping]]
        left_join(mean_amp(batch = uupu_gb, window = u_win, sign = ucl$sign,
                           amp_win = ucl$amp_win),
                  peak_lat(batch = uupu_gb, window = u_win, sign = ucl$sign),
                  by = c("channel","subject")) -> u_bind
        left_join(mean_amp(batch = seam_gb, window = s_win, sign = scl$sign,
                           amp_win = scl$amp_win),
                  peak_lat(batch = seam_gb, window = s_win, sign = scl$sign),
                  by = c("channel","subject")) -> s_bind
        u_bind$grouping  <- grouping; s_bind$grouping  <- grouping
        u_bind$component <- ucl$name; s_bind$component <- ucl$name
        u_bind$project   <- "UUPU";   s_bind$project   <- "SEAM"
        rbind(u_bind, s_bind)
      })
      # Testing whether amplitude measurement windows are misaligned. If so,
      # branching to manual window alignment.
      descriptor <- str_c("Manual alignment of ", stim, " ", comp,
                          " amplitude measurement windows:")
      the_res <- manual_alignment(the_res, max_diff = max_diff,
                                  uupu_calc_b, seam_calc_b,
                                  u_win = u_win, s_win = s_win,
                                  ucl = ucl, scl = scl,
                                  descriptor = descriptor)
      the_res$stimuli <- stim; the_res$erpid <- stim_lookup$erpid_name
      out_final <- c(out_final, list(the_res))
    }
  }
  do.call("rbind", out_final)
}


# Function for binding together mean amplitude with given params.
# Updated 5.10.2017 to use Fz for centering the measurement window.
mean_amp <- function(batch, window, sign, amp_win, override = NULL,
                     peak_channel = 'Fz')
{
  # 1. Calculate grand average.
  batch %>% group_by(channel, time) %>%
    summarise(amplitude = mean(amplitude)) -> ga_batch
  # 2. Subset to given window.
  win_ga <- ga_batch[ga_batch$time %in% (window[[1]]:window[[2]]),]
  # 3. Identify negative or positive peaks in the defined window.
  win_ga %>% group_by(channel) %>%
    summarise(peak_time = time[which_local_extremum(amplitude, sign)]) -> peak_t
  # Setting all edges to equal limit calculated for Fz.
  if (is.null(override)) {
    peak_t$peak_time <- peak_t[peak_t$channel == peak_channel, "peak_time"][[1]]
  } else {
    peak_t$peak_time <- override # Possibility override automatic peak detectection.
  }
  # Throwing warnings here should the peaks hit the window edges.
  check_edges(win_ga, sign)
  # 4. Define windows around found peak from which to calculate mean amplitude.
  peak_t %>% mutate(amp_win_lower = (peak_time - (amp_win / 2)),
                    amp_win_upper = (peak_time + (amp_win / 2))) -> peak_t
  peak_windows <- peak_t[ ,names(peak_t) != "peak_time"]
  # 5. Applying the defined windows over each channel to summarise group mean
  # amplitudes.
  # Join window information by channel.
  win_batch <- left_join(batch, peak_windows, by = c("channel"))
  # Subset by channel with a logical vector.
  win_batch <- win_batch[win_batch$time >= win_batch$amp_win_lower &
                           win_batch$time <= win_batch$amp_win_upper,]
  # Calculate mean values over latencies for each subject.
  win_batch %>% group_by(channel, subject) %>%
    summarise(amplitude = mean(amplitude)) -> subject_means
  # Adding used window for mean amplitude calculations as a column to the output.
  subject_means$amp_win <- str_c("[",peak_t$amp_win_lower[[1]], ", ",
                                 peak_t$amp_win_upper[[1]], "]")
  subject_means
}

# Function for binding together mean latency with given params.
peak_lat <- function(batch, window, sign)
{
  # 1. Window the batch data.
  win_batch <- batch[batch$time %in% window[[1]]:window[[2]],]
  # 2. Determine either the positive or negative peak latencies.
  win_batch %>% group_by(channel, subject) %>%
    summarise(latency = time[which_local_extremum(amplitude, sign)]) -> plat
  # Adding fetching window as a column
  plat$window <- str_c("[", window[[1]], ",", window[[2]], "]")
  plat
}

# Local peak index extraction. Index of largest/smallest value surrounded by
# smaller/larger values on both sides.
# IF no local extremes are to be found, will return the global extremum.
which_local_extremum <- function(x, sign)
{
  if (sign == "neg") {
    valleys <- c(FALSE, x[-1] - x[-length(x)] <= 0) &
      c(x[-length(x)] - x[-1] <= 0, FALSE)
    if (any(valleys)) {
      which(valleys)[which.min(x[valleys])]
    } else which.min(x)

  } else if (sign == "pos") {
    peaks <- c(FALSE, x[-1] - x[-length(x)] >= 0) &
      c(x[-length(x)] - x[-1] >= 0, FALSE)
    if (any(peaks)) {
      which(peaks)[which.max(x[peaks])]
    } else which.max(x)

  } else stop("Give sign as either neg or pos.")
}

# Function for testing if there are significant differences between groups for
# the determined amplitude measurement windows. Branches into a interactive
# window selection method to override automatic selection if significant
# misalignments are detected.
manual_alignment <- function(the_res, max_diff = 30, uupu_calc_b, seam_calc_b,
                             u_win, s_win, ucl, scl, descriptor)
{
  # Parsing amplitude windows from string.
  amp_win_num <- map(str_extract_all(string = the_res$amp_win,
                                     pattern = "[0-9]+"), as.numeric)
  the_res$amp_lo_win <- map_dbl(amp_win_num, `[`, j = 1)
  the_res$amp_hi_win <- map_dbl(amp_win_num, `[`, j = 2)
  lat_win_num <- map(str_extract_all(string = the_res$window,
                                     pattern = "[0-9]+"), as.numeric)
  the_res$lat_lo_win <- map_dbl(lat_win_num, `[`, j = 1)
  the_res$lat_hi_win <- map_dbl(lat_win_num, `[`, j = 2)
  the_res %>% mutate(gname = str_c(grouping, "_", project)) %>%
    group_by(gname, grouping, project) %>%
    summarise(amp_lo_win = mean(amp_lo_win), amp_hi_win = mean(amp_hi_win),
              lat_lo_win = mean(lat_lo_win), lat_hi_win = mean(lat_hi_win)) ->
    the_win
  the_win$original <- (the_win$amp_lo_win + the_win$amp_hi_win) / 2

  # Determining which grouping differs from the other the most.
  diff_vals <- map_dbl(seq(nrow(the_win)), function(i) {
    sum(abs(the_win$amp_lo_win[i] - the_win$amp_lo_win))}) / 3
  names(diff_vals) <- the_win$gname

  # Detection of misalignments.
  if (any(diff_vals > max_diff)) {
    cat("Misalignment of\n"); print(round(diff_vals))
    cat("detected. Determining amplitude windows manually.")
    udf <- uupu_calc_b[uupu_calc_b$grouping %in% unique(the_res$grouping),]
    sdf <- seam_calc_b[seam_calc_b$grouping %in% unique(the_res$grouping),]
    udf$project <- "UUPU"; sdf$project <- "SEAM"
    df <- rbind(udf, sdf)

    # Printing a plot visualizing the measurement windows.
    ggplot(df, aes(x = time, y = amplitude)) +
      facet_grid(channel ~ grouping + project) +
      geom_line(aes(colour = subject), alpha = 0.75) + scale_y_reverse() +
      geom_line(data = df %>% group_by(project, grouping, time, channel) %>%
                  summarise(amplitude = mean(amplitude))) +
      geom_hline(yintercept = 0, alpha = 0.5) +
      geom_vline(xintercept = 0, alpha = 0.5) +
      geom_vline(data = the_win, aes(xintercept = amp_lo_win), colour = "red",
                 alpha = 0.35) +
      geom_vline(data = the_win, aes(xintercept = amp_hi_win), colour = "red",
                 alpha = 0.35) +
      geom_vline(data = the_win, aes(xintercept = lat_lo_win), colour = "blue",
                 alpha = 0.35) +
      geom_vline(data = the_win, aes(xintercept = lat_hi_win), colour = "blue",
                 alpha = 0.35) +
      theme_minimal() + theme(legend.position = "none") +
      labs(title = descriptor) -> p; print(ggplotly(p))

    # Reading user defined order of amplitude windows from the terminal.
    cat("\nPlease give the order of amplitude windows to use in format 2 2gd 3 4\n")
    cat("Write \"gd\" after given index to use gradient descent to the local maxima.\n")
    cat("Given a value >12. that value is used to manually override amplitude measurement window center.\n")
    amp_win_order <- readline(prompt = "Give order of amplitude windows: ")
    # Parsing the read inputs.
    amp_win_order <- str_split(amp_win_order, " ")[[1]]
    # If empty, keeping the placeholder windows.
    if (length(amp_win_order) == 1 && amp_win_order == "") {
      amp_win_order <- as.character(seq(length(unique(df$grouping)) * 2))
    }
    gd_call <- grepl(x = amp_win_order, pattern = "gd")
    amp_win_order <- as.numeric(str_extract_all(amp_win_order,
                                                pattern = "[0-9]+"))
    the_win$centers <- (the_win$amp_lo_win + the_win$amp_hi_win) / 2

    # Inputting given manual values.
    if (any(amp_win_order > 12)) {
      repl_lgl <- amp_win_order > 12
      the_win[repl_lgl, "centers"] <- amp_win_order[repl_lgl]
      amp_win_order[repl_lgl] <- which(repl_lgl)
    }
    the_win$centers <- the_win$centers[amp_win_order]

    # Performing descent to local extremum if "gd"-option was specified.
    if (any(gd_call)) {
      df %>% group_by(grouping, project, time, channel) %>%
        summarise(amplitude = mean(amplitude)) %>% filter(channel == "Fz") %>%
        mutate(gname = str_c(grouping, "_", project)) -> mean_amps

      # Iterating position of old center until local extreme found.
      while (any(gd_call)) {
        gd_i <- min(which(gd_call)); starting_lat <- the_win$centers[[gd_i]]
        gdf  <- mean_amps[mean_amps$gname == unique(mean_amps$gname)[[gd_i]],]
        i <- which(gdf$time == starting_lat)
        eval_win <- gdf[i - c(1,0,-1),"amplitude"][[1]]
        if (scl$sign == "neg") {
          while (which.min(eval_win) != 2) {
            i <- (which.min(eval_win) - 2) + i
            eval_win <- gdf[i - c(1,0,-1),"amplitude"][[1]]
          }
        } else if (scl$sign == "pos") {
          while (which.max(eval_win) != 2) {
            i <- (which.max(eval_win) - 2) + i
            eval_win <- gdf[i - c(1,0,-1),"amplitude"][[1]]
          }
        }
        new_lat <- gdf[[i, "time"]]; the_win[gd_i, "centers"] <- new_lat
        gd_call[gd_i] <- FALSE
      }
    }

    # Appending the_win with information of possible manual changes.
    the_win$manual_num <- str_c(the_win$original, " -> ", the_win$centers)
    the_win$manual_lgl <- the_win$original != the_win$centers

    # Helper function for manually rebuilding the results data.frame.
    rebuild_res <- function(grouping)
    {
      # Rebuilding the_res manually, with user supplied overrides.
      uupu_g <- uupu_calc_b[uupu_calc_b$grouping == grouping,]
      seam_g <- seam_calc_b[seam_calc_b$grouping == grouping,]
      # Rebinding stats for SEAM
      left_join(mean_amp(batch = seam_g, window = s_win, sign = scl$sign,
                         amp_win = scl$amp_win,
                         override = the_win[the_win$grouping == grouping &
                                              the_win$project == "SEAM",
                                            "centers"][[1]]),
                peak_lat(batch = seam_g, window = s_win, sign = scl$sign),
                by = c("channel","subject")) -> s_g_bind
      # Rebinding stats for UUPU
      left_join(mean_amp(batch = uupu_g, window = u_win, sign = ucl$sign,
                         amp_win = ucl$amp_win,
                         override = the_win[the_win$grouping == grouping &
                                              the_win$project == "UUPU",
                                            "centers"][[1]]),
                peak_lat(batch = uupu_g, window = u_win, sign = ucl$sign),
                by = c("channel","subject")) -> u_g_bind

      u_g_bind$grouping  <- grouping; s_g_bind$grouping  <- grouping
      u_g_bind$component <- ucl$name; s_g_bind$component <- ucl$name
      u_g_bind$project   <- "UUPU";   s_g_bind$project   <- "SEAM"
      rbind(u_g_bind, s_g_bind)
    }

    out <- map_dfr(unique(the_res$grouping), rebuild_res)
  } else {
    out <- the_res[,seq(ncol(the_res) - 4)]
    the_win$centers <- the_win$original
    the_win$manual_num <- str_c(the_win$original, " -> ", the_win$original)
    the_win$manual_lgl <- FALSE
  }
  left_join(out, the_win[c("grouping", "project", "manual_num", "manual_lgl")],
            by = c("grouping", "project"))
}

# Helper function for throwing warnings should peak amplitudes hit the window edges.
check_edges <- function(win_ga, sign)
{
  for (chan in unique(win_ga$channel)) {
    chan_ga <- win_ga[win_ga$channel == chan,]
    if (which_local_extremum(chan_ga$amplitude, sign) %in% c(1, nrow(chan_ga))) {
      warning(str_c(ifelse(sign == "pos", "Maximum", "Minimum"),
                    " GA amplitude hitting window edge "),
              chan_ga[which.max(chan_ga$amplitude), "time"],
              " at channel ", chan, immediate. = T)
    }
  }
}


# IA-specific wrangling functions -----------------------------------------


# Binding metadatas to the stats file.
# Set normalize = T to scale covariates by maximum value.
# Set residualize = T to residualize covariates by MBIScore.
add_covariates_ia <- function(stats, covariates = c("BDI2", "BAI"),
                              normalize = F, residualize = F)
{
  us_meta <- readRDS(str_c(SEAM_FIG_DIR, "/stats/us_metadata.rds"))
  cov_i <- which(names(us_meta) %in% covariates)
  covar <- us_meta[,cov_i]
  if (normalize) {
    # Normalizing each covariate by diving with the maximum value of the scale.
    covar <- map_dfc(names(covar), function(fname)
    {
      if (fname == "BDI2") {
        out <- data.frame(covar[fname] / 31.5)
      } else if (fname == "BAI") {
        out <- data.frame(covar[fname] / 63)
      } else if (grepl("MBI", fname)) {
        out <- data.frame(covar[fname] / 6)
      } else stop("Unknown covariate type supplied.")
      names(out) <- str_c("n", fname)
      out
    })
  }
  if (residualize) {
    covar <- map_dfc(names(covar), function(fname)
    {
      fit <- lm(covar[[fname]] ~ us_meta[["MBIScore"]])
      pred <- predict(fit, newdata = us_meta)
      out <- data.frame(covar[[fname]] - pred)
      names(out) <- str_c(fname, "_res")
      out
    })
  }
  covar <- cbind(us_meta[,"subject", drop = F], covar)
  ungroup(left_join(stats, covar, by = c("subject")))
}


# Add mean age (mage) and age at measurement (age) as to the stats df.
add_age_ia <- function(stats)
{
  us_meta <- readRDS(str_c(SEAM_FIG_DIR, "/stats/us_metadata.rds"))
  # Adding mean age.
  subj_recur <- us_meta %>% filter(project == "SEAM") %>% pull(subjnr)
  us_meta %>% filter(subjnr %in% subj_recur) %>% group_by(subjnr) %>%
    summarise(mage = mean(age)) -> mages
  left_join(us_meta %>% filter(subjnr %in% subj_recur & project == "SEAM"),
            mages, by = "subjnr") %>%
    select(one_of("subject", "mage")) %>%
    mutate(subject = substr(subject, 5, 8)) -> mages
  stats_ <- left_join(stats, mages, by = "subject") %>% ungroup()
  # Adding age at measurement time.
  left_join(stats_ %>% mutate(subjnr = parse_number(subject)),
            us_meta %>% select(subjnr, project, age),
            by = c("subjnr", "project")) %>% select(-subjnr) %>%
    mutate(project = factor(project, levels = c("UUPU", "SEAM"))) %>%
    mutate(age = age - mean(age))
}


# Deprecated --------------------------------------------------------------

# These function are the first iterations of the statistics extraction
# functions. They are not used anymore for stats extraction but still kept here
# as a reference.

# Wrapper function for calling stats generation. Fetches dataset batches uupu_batch and seam_batch as well as
# lookup-tables defining components from the global environment.
wrap_stats <- function()
{
  stimuli_codes <- c("std","condur", "den", "fre", "int", "loc", "Nangry",
                     "Nhappy", "noise", "Nsad", "omission1", "omission2",
                     "vowcha1", "vowcha2", "vowdur1", "vowdur2")
  out <- rbind(batch_stats(stimuli_codes, uupu_batch),
               batch_stats(stimuli_codes, seam_batch))
  force(out)
}


# Per grouping, stimuli and component, mean latencies and amplitudes.
batch_stats <- function(stimuli, batch)
{
  # Automagical detection of seam/uupu. Sets the proper component-lookup table to be used.
  test_subject <- batch[[1]]$subject[[1]]
  if (grepl("UUPU", test_subject)) {
    component_lookup <- uupu_component_lookup
    project <- "UUPU"
  } else if (grepl("SEAM", test_subject)) {
    component_lookup <- seam_component_lookup
    project <- "SEAM"
  }
  # Check to remove subjects with too low trialcounts in groupings 00 and 11..
  # Removing only 059 who belongs to 00 grouping as the subject would otherwise affect group mean calculations.
  batch <- map(batch, ~.[!.$subject %in% DROP_SUBJ,])
  # Brancher function for binding stats from project (2) x grouping (5) x channel (3) = 30
  bind_stim_comp <- function() {
    # Subset to appropriate condition.
    erpid_data <- batch[[erpid]]
    # Calculate differences if "difference" is flagged.
    if (difference) {
      erpid_data["amplitude"] <- (erpid_data["amplitude"] - batch[["std"]]["amplitude"])
    }
    # Leaf level function. Binds a single row.
    bind_groupings <- function(grouping) {
      # Subsetting data to group.
      if (grouping %in% c("00", "01", "10", "11")) {
        erpid_data <- erpid_data[erpid_data$grouping == grouping, ]
      }
      # Setting call window:
      comp_window <- (t_0 + window)
      # See self contained mean_amp and peak_lat function for calculation details.
      row_batch <- left_join(mean_amp(erpid_data, comp_window, sign, amp_win),
                             peak_lat(erpid_data, comp_window, sign),
                             by = c("channel", "subject"))
      row_batch$component <- comp_name; row_batch$stimuli <- stim_name
      row_batch$grouping <- grouping
      row_batch$project <- project;     row_batch$erpid <- erpid;
      force(row_batch)
    }
    out <- map(c("00", "11"), bind_groupings)
    # Bind results together.
    out <- do.call("rbind", out)
    force(out)
  }

  out_final <- vector("list", 0) # This vector holds the outputs. Is appended with c(), since length will stay small.

  for (stim_i in 1:length(stimuli)) {

    stim_params <- stimuli_lookup[[stimuli[[stim_i]]]]
    stim_name <- stimuli[[stim_i]]  # Set current stimulus name.
    t_0 <- stim_params[[1]]         # set stimulus/deviance onset in environment
    components <- stim_params[[2]]  # List of components to be iterated from t_0
    erpid <- stim_params[[3]]       # Name of the base dataset used in calculations.

    for (comp_i in 1:length(components)) {

      comp_params <- component_lookup[[components[[comp_i]]]]
      window <- comp_params[[1]]      # Initialise window from which to look for component statistics.
      comp_name <- comp_params[[2]]   # Name of the component being evaluated.
      difference <- comp_params[[3]]  # Logical flag. Is component calculated from difference signal or not?.
      amp_win <- comp_params[[4]]     # Window size around identified peak from which to calculate mean amplitudes.
      sign <- comp_params[[5]]        # Is the component positive ("pos") or negative ("neg")?

      # Temporary printout.
      cat(project, stim_name, comp_name, "\n")

      # 30-row df batch generation function is called here.
      out_final <- c(out_final, list( bind_stim_comp() ))
    }
  }

  out_final <- do.call("rbind", out_final)
  force(out_final)
}


# Plotting function for results  ------------------------------------------

# Plotting function for generating boxplots from a wrap_stats-function call batch of results.
batch_plot_results <- function(stats)
{
  components <- unique(stats$component)
  g1 <- "00"
  g2 <- "11"
  stats <- stats[stats$grouping %in% c(g1, g2, "ALL"),]
  stats <- stats[!stats$subject %in% c("UUPU", "SEAM"),]

  savedir <- str_c(SAVEDIR, "/results/")
  if (!dir.exists(savedir)) dir.create(savedir, showWarnings = F, recursive = T)

  # Iterate over each component to generate plots.
  for (comp_i in 1:length(components)) {
    component <- components[[comp_i]]
    cond_stats <- stats[stats$component == component,]

    ggplot_within <- function() {
      cond_stats_wo_all <- cond_stats[cond_stats$grouping != "ALL", ]
      p_amp <- ggplot(cond_stats_wo_all) +
        facet_grid(channel ~ project) +
        geom_hline(yintercept = 0, alpha = 0.5) +
        geom_boxplot(aes(x = stimuli, y = amplitude, fill = grouping)) +
        labs(title = str_c(component, " mean amplitude comparison within UUPU and SEAM groupings ",
                           g1, " and ", g2), y = expression(paste("Amplitude (", mu, "V)", sep = "")))

      if (component %in% c("MMN", "N1")) {
        p_amp <- p_amp + scale_y_reverse()
      }

      p_lat <- ggplot(cond_stats_wo_all) +
        facet_grid(channel ~ project) +
        # geom_hline(yintercept = 0, alpha = 0.5) +
        geom_boxplot(aes(x = stimuli, y = latency, fill = grouping)) +
        labs(title = str_c(component, " mean latency comparison within UUPU and SEAM groupings ",
                           g1, " and ", g2), y = "Latency (ms)")

      ggsave(filename = str_c(savedir, component, "_", g1, "-", g2, "_amplitude.png"),
             plot = p_amp, width = 18.1, height = 9.5)
      ggsave(filename = str_c(savedir, component, "_", g1, "-", g2, "_latency.png"),
             plot = p_lat, width = 18.1, height = 9.5)
    }

    ggplot_between <- function() {
      p_amp <- ggplot(cond_stats) +
        facet_grid(channel ~ grouping) +
        geom_boxplot(aes(x = stimuli, y = amplitude, fill = project)) +
        geom_hline(yintercept = 0) +
        labs(title = str_c(component, " mean amplitude comparison between UUPU and SEAM groupings ",
                           g1, " and ", g2), y = expression(paste("Amplitude (", mu, "V)", sep = "")))

      if (component %in% c("MMN", "N1")) {
        p_amp <- p_amp + scale_y_reverse()
      }

      p_lat <- ggplot(cond_stats) +
        facet_grid(channel ~ grouping) +
        geom_boxplot(aes(x = stimuli, y = latency, fill = project)) +
        labs(title = str_c(component, " mean latency comparison between UUPU and SEAM groupings ",
                           g1, " and ", g2), y = "Latency (ms)")

      ggsave(filename = str_c(savedir, component, "_SEAM-UUPU_amplitude.png"),
             plot = p_amp, width = 18.1, height = 9.5)
      ggsave(filename = str_c(savedir, component, "_SEAM-UUPU_latency.png"),
             plot = p_lat, width = 18.1, height = 9.5)
    }

    # Calling plot generation here.
    ggplot_within()
    ggplot_between()
  }
}

# Function for plotting group differences faceted to show all relevant comparisons in one plot.
# NOTE: depends on wrangle_stats from linear_mixed_models.R
batch_plot_results2 <- function(stats, cont_mbi = F)
{
  # Automagical detection whether the stats have already been wrangled.
  if (class(stats$subject) != "factor") {
    stats <- wrangle_stats(stats, cont_mbi = cont_mbi)
  }
  stats %>% split(stats$stimuli) -> by_stim
  bind_stim <- function(stim_df) {
    stim_df %>% split(stim_df$component) -> by_comp
    ggplot_comp <- function(comp_df) {
      # IF mbi-score is handled as a continuous variable, group difference plots and "inkblot" plots need to
      # be wrangled a bit differently.
      if (!cont_mbi) {
        comp_df %>% group_by(channel, grouping, project) %>%
          summarise(mean_amp = mean(amplitude), sd_amp = sd(amplitude),
                    mean_lat = mean(latency), sd_lat = sd(latency), n = n()) %>%
          mutate(sem_amp = sd_amp / sqrt(n), sem_lat = sd_lat / sqrt(n)) -> stat_df
        # Reordering project factor so x-axis progression is chronological.
        stat_df$project <- factor(stat_df$project, levels = c("UUPU", "SEAM"))

        # Lefthand side contains plots visualizing main effects and interacions with line graphs.
        p_amp_proj <- ggplot(stat_df, aes(x = grouping, y = mean_amp, group = project, colour = project)) +
          facet_grid(channel ~ .) + geom_line() + geom_point() + scale_y_reverse() +
          geom_errorbar(aes(ymin = mean_amp + sem_amp * .5, ymax = mean_amp - sem_amp * .5), width = .2) +
          geom_errorbar(aes(ymin = mean_amp + sd_amp * .5, ymax = mean_amp - sd_amp * .5), width = .05, alpha = .5) +
          labs(title = "Amplitude")

        p_lat_proj <- ggplot(stat_df, aes(x = grouping, y = mean_lat, group = project, colour = project)) +
          facet_grid(channel ~ .) + geom_line() + geom_point() +
          geom_errorbar(aes(ymin = mean_lat + sem_lat * .5, ymax = mean_lat - sem_lat * .5), width = .2) +
          geom_errorbar(aes(ymin = mean_lat + sd_lat * .5, ymax = mean_lat - sd_lat * .5), width = .05, alpha = .5) +
          labs(title = "Latency")

        # Distributions of observations in upper right corner.
        p_inkblot <- ggplot(comp_df) +
          facet_grid(channel ~ project) +
          geom_hline(yintercept = 0, alpha = .35) +
          geom_density2d(aes(x = latency, y = amplitude), alpha = 0.15) +
          geom_point(aes(x = latency, y = amplitude, colour = grouping), alpha = .75) +
          scale_y_reverse() + labs(title = "Distribution of observations") +
          scale_colour_manual(values = c("blue", "red"))

      } else {
        comp_df <- rename(.data = comp_df,`MBI-score` = grouping)

        # Lefthand side contains plots visualizing main effects and interacions with line graphs.
        p_amp_proj <- ggplot(comp_df, aes(x = `MBI-score`, y = amplitude, group = project, colour = project)) +
          facet_grid(channel ~ .) + geom_point(shape = 1) + scale_y_reverse() +
          geom_line(stat = "smooth",  method = "lm", se = F) + labs(title = "Amplitude") +
          geom_vline(xintercept = 1.5, alpha = 0.5) + geom_hline(yintercept = mean(comp_df$amplitude), alpha = 0.35)

        p_lat_proj <- ggplot(comp_df, aes(x = `MBI-score`, y = latency, group = project, colour = project)) +
          facet_grid(channel ~ .) + geom_point(shape = 1) +
          geom_line(stat = "smooth", method = "lm", se = F) + labs(title = "Latency") +
          geom_vline(xintercept = 1.5, alpha = 0.5) + geom_hline(yintercept = mean(comp_df$latency), alpha = 0.35)

        # Distributions of observations in upper right corner.
        p_inkblot <- ggplot(comp_df) +
          facet_grid(channel ~ project) +
          # geom_hline(yintercept = 0, alpha = .5) +
          # geom_density2d(aes(x = latency, y = amplitude), alpha = 0.15) +
          geom_point(aes(x = latency, y = amplitude, colour = `MBI-score`)) +
          scale_y_reverse() + labs(title = "Distribution of observations") +
          scale_color_continuous(low = "green", high = "red") +
          labs(color = "MBI-score")
        # Trying to add per channel means as h/vline frame to allow easy comparison of distributions.
        comp_df %>% group_by(channel, project) %>% summarise(lat = mean(latency), amp = mean(amplitude)) -> per_chan
        # per_chan <- rbind(per_chan, per_chan); per_chan$project <- c("UUPU", "SEAM")
        p_inkblot <- p_inkblot + geom_hline(data = per_chan, aes(yintercept = amp), alpha = 0.35)
        p_inkblot <- p_inkblot + geom_vline(data = per_chan, aes(xintercept = lat), alpha = 0.35)


        comp_df <- rename(.data = comp_df, grouping = `MBI-score`)
      }
      # Visualizing model p-values in lower left corner
      lmm_int_amp <- lmm_to_p("amplitude", c("channel", "grouping", "project", "(1|subject)"), comp_df)
      lmm_int_ia_amp <- lmm_to_p("amplitude", c("channel", "grouping", "project", "grouping:project",
                                                "(1|subject)"), comp_df)
      lmm_int_lat <- lmm_to_p("latency", c("channel", "grouping", "project", "(1|subject)"), comp_df)
      lmm_int_ia_lat <- lmm_to_p("latency", c("channel", "grouping", "project", "grouping:project",
                                              "(1|subject)"), comp_df)
      models <- list(lmm_int_amp, lmm_int_ia_amp, lmm_int_lat, lmm_int_ia_lat)

      models <- map2(models,c("amplitude", "amplitude", "latency", "latency"),
                     function(el, name) {el$dependent <- name; force(el)})
      models <- map2(models,c("lmm", "lmm_ia", "lmm", "lmm_ia"),
                     function(el, name) {el$model <- name; force(el)})

      models <- do.call("rbind", models)
      models$p <- map_dbl(models$p, ~ifelse(. > .1, .1, .))
      p_signif <- ggplot(models) +
        facet_grid(dependent + model ~ .) +
        geom_vline(xintercept = c(.001,.01,.05,.1), colour = "red", alpha = 0.5) +
        geom_point(aes(x = p, y = independent_var), size = 2) +
        scale_x_continuous(breaks = c(0.001, 0.01, 0.05, 0.1),
                           labels = c("0.001", "0.01", "0.05", ">0.1"), limits = c(0, .1)) +
        labs(x = "p-value", y = "independent variables",
             title = "Linear mixed model significances with bonferroni-adjusted p-values.")

      # ggplot(models) +
      #   facet_grid(dependent + model ~ .) +
      #   geom_bar(aes(x = independent_var, y = rev(p), fill = p), stat = "identity")

      # p_signif <- textGrob(label = str_c(capture.output(print(models)), collapse = "\n"), just = "left")


      # p_amp_group <- ggplot(stat_df, aes(x = project, y = mean_amp, group = grouping, colour = grouping)) +
      #   facet_grid(channel ~ .) + geom_line() + geom_point() + scale_y_reverse() +
      #   geom_errorbar(aes(ymin = mean_amp + sem_amp * .5, ymax = mean_amp - sem_amp * .5), width = .2) +
      #   geom_errorbar(aes(ymin = mean_amp + sd_amp * .5, ymax = mean_amp - sd_amp * .5), width = .05, alpha = .5)
      #
      # p_lat_group <- ggplot(stat_df, aes(x = project, y = mean_lat, group = grouping, colour = grouping)) +
      #   facet_grid(channel ~ .) + geom_line() + geom_point() +
      #   geom_errorbar(aes(ymin = mean_lat + sem_lat * .5, ymax = mean_lat - sem_lat * .5), width = .2) +
      #   geom_errorbar(aes(ymin = mean_lat + sd_lat * .5, ymax = mean_lat - sd_lat * .5), width = .05, alpha = .5)

      stim <- unique(comp_df$stimuli); comp = unique(comp_df$component)
      cat(stim, comp, "- ")
      arr <- arrangeGrob(grobs = list(p_amp_proj, p_inkblot, p_lat_proj, p_signif), top = str_c(stim, " ", comp,
                                                                                                " mean amplitude and latency comparisons between groups with SEM and SD."))
      ggsave(file = str_c(SAVEDIR, "/results/",stim, "_", comp, "_gd.png"), arr, width = 15, height = 8.5)
    }
    walk(by_comp, ggplot_comp)
  }
  walk(by_stim, bind_stim)
}


# Takes stats as input and join metadata from there.
# Uses package GGally
batch_metadata_correlations <- function(stats)
{
  # Making sure unnecessary information is dropped.
  stats <- stats[!stats$subject %in% DROP_SUBJ,]
  stats <- stats[stats$grouping %in% c("11", "00"),]

  uupu_stats <- stats[stats$subject %in% str_c("UUPU0",1:99),]
  seam_stats <- stats[stats$subject %in% str_c("SEAM0",1:99),]
  ufp <- str_c(UKKO_ROOT, "/projects/Uupuneet_11-12/data/ID_background/UUPU_sleep.xls")
  sfp <- str_c(UKKO_ROOT,"/projects/SeamlessCare_2015-16/data/participants/seamless_participant_data.xls")

  meta_seam <- readxl::read_xls(path = sfp, sheet = "data")
  meta_uupu <- readxl::read_xls(path = ufp)
  meta_seam <- meta_seam[c("subject", "mbi-total", "bdi2", "bai", "age")]
  meta_uupu <- meta_uupu[c("UUPU_ID", "MBI_score", "BDI2", "BAI",
                           "Subject_age")]
  names(meta_uupu) <- names(meta_seam)

  uupu_stats <- left_join(uupu_stats, meta_uupu, by = "subject")
  seam_stats <- left_join(seam_stats, meta_seam, by = "subject")

  # Imputing missing values in seam_stats$bdi2 with median (11).
  seam_stats$bdi2 <- map_dbl(seam_stats$bdi2, ~ifelse(. == "NA", 11,
                                                      as.numeric(.)))
  # Coercing some columns to numeric.
  walk(c("mbi-total", "bdi2","bai","age"),
       function(col_name) {seam_stats[col_name] <<-
         as.numeric(seam_stats[[col_name]])})
  walk(c("mbi-total", "bdi2","bai","age"),
       function(col_name) {uupu_stats[col_name] <<-
         as.numeric(uupu_stats[[col_name]])})

  # Iterating through by channel, stimuli, component and project.
  rbind(uupu_stats, seam_stats) -> stats; stats$uname <-
    str_c(stats$project, stats$stimuli, stats$component, sep = "_")
  plot_cor_meta <- function(stat_set) {
    stat_set <- stat_set[stat_set$channel == "Fz",]
    savedir <- str_c(SAVEDIR, "/results/correlations/")
    if(!dir.exists(savedir)) dir.create(savedir, showWarnings = F,
                                        recursive = T)
    savefile <- str_c(savedir, unique(stat_set$uname), ".png")
    ggsave(savefile, GGally::ggpairs(stat_set[,c("amplitude", "latency",
                                                 "mbi-total", "bdi2", "bai",
                                                 "age")]),
           width = 15, height = 8.5)
  }
  walk(stats %>% split(stats$uname), plot_cor_meta)
}

# Binding generalized eta squared values for each stimuli / component / channel
batch_ges <- function(stats)
{
  # Setting contrasts options for type 3 sum of squares.
  options(contrasts = c("contr.sum","contr.poly"))
  if (class(stats$grouping) != "factor") { stats <- wrangle_stats(stats) }
  bind_stimuli <- function(stim) {
    stim_df <- stats[stats$stimuli == stim,]
    bind_component <- function(comp) {
      comp_df <- stim_df[stim_df$component == comp,]
      # bind_channel <- function(chan) {
      # chan_df <- comp_df[comp_df$channel == chan,]
      amp <- ezANOVA(data = comp_df, wid = subject, dv = amplitude,
                     within = .(project, channel),
                     between = grouping, type = 3)[[1]]
      lat <- ezANOVA(data = comp_df, wid = subject, dv = latency,
                     within = .(project, channel),
                     between = grouping, type = 3)[[1]]
      amp$dependent <- "amplitude"; lat$dependent <- "latency"
      rbind(amp, lat) -> out
      # out$channel <- chan;
      out$component <- comp; out$stimuli <- stim; force(out)
      # }
      # map_df(unique(comp_df$channel), bind_channel)
    }
    map_df(unique(stim_df$component), bind_component)
  }
  map_df(unique(stats$stimuli), bind_stimuli)
}

# Binding correlations for peak amplitudes and latencies for
bind_correlations <- function(stats, by)
{
  # Defining a inflix operator to do a spread() that actually works
  `%spread%` <- function(df, var)
  {
    df %>% split(f = df[[var]]) %>% map(`[`, -which(names(df) == var)) %>%
      do.call(cbind, .)
  }
  stats[,c("project", "latency", "amplitude")] %spread% by %>%
    summarize(cor_lat = cor(UUPU.latency, SEAM.latency),
              cor_amp = cor(UUPU.amplitude, SEAM.amplitude))
}


# Notes and misc ---------------------------------------------------------

# Component definitions as in Sokka et al. (2014)
# N1: Largest negative deflection 50-150ms after stimulus onset.
# MMN: Most negative peaks 100-220ms after deviance onset.
# P3a: 200-300ms for Happy and 250-300ms for Angry and sad after deviance onset.

# Stimuli features:
# Deviants:
# Density
# Frequency
# Intensity
# Location                  # Deviance from start
# Noise
# Consonant duration        # Added 100ms silence in between
# Omission                  # 2 MMN responses
# Vowel change              # Natural utterance, 2 MMN responses
# Vowel duration            # Natural utterance, 2 MMN responses

# Deviants:                 1st     2nd Syllable    d-onset1    d-onset2    erpid
# Density                   168     168             168                     den
# Frequency                 168     168             168                     fre
# Intensity                 168     168             168                     int
# Location                  168     168             0                       loc
# Noise                     168     168             168                     noise
# Consonant duration        144     176             144                     condur
# Omission                  168     0               0?          168         omission
# Vowel change              168     168             0           168         vowcha
# Vowel duration            168     168             0           168         vowdur


# Data management ---------------------------------------------------------

#################### CALL BATCH_STATS HERE #####################

# stats <- wrap_stats()
# saveRDS(stats, str_c(SEAM_FIG_DIR, "/results/stats.rds"))
#
# # batch_plot_results(stats)
# batch_plot_results2(stats)
# batch_metadata_correlations(stats)
# effect_sizes <- batch_ges(stats)

################################################################


# Saving the generated dataset
# saveRDS(stats, file = str_c(SAVEDIR, "/stats/stats_", Sys.Date(), ".rds"))
# saveRDS(stats, file = str_c("/home/jloh/Documents/data/stats_", Sys.Date(), ".rds"))
























