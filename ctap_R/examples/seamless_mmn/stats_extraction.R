# This script contains a yet another iteraton of the stats extracting functions.

# Workflow;
# 1. uupu_batch & seam_batch binding from raw datas from file.
#    Using functions from ctap_tools_future.R
# 2. batch_250 binding to subset and format relevant data.
#    Using get_batch-function from data_management_mmn.R
# 3. Iteration over the component lookups, defining components to be extracted.
# 3a. Amplitude from central midline channels
# 3b. Peak latency from Fz.
#    Using wrap_lookup function from stats_extraction.R
# 4. Running peak selection accuracy function to detect and manually correct for
#    peaks found to vary too much between time and between subjects groupings.
#    Especially problem with current setup; with a 3 x 2, between-within design
#    with 22 stimulus-component pairings.
#    Using align_peaks-function from stats_extraction.R
# 5. Analyses...

# require(tidyverse)
# require(stringr)

# Component definitions ---------------------------------------------------

# MMN and P3a components are defined as in Sokka et al. (2014)
# Component peak latencies are calculated from channel Fz, using a 100 ms
# window centered around measurement time and between subject grouping
# combinations.

# Define the window from which peak from grand average waveforms is to be '
# extracted from.
# onset - deviance onset
# comp_win - window type to be added over deviance onset to extract grand
# average peak from.
stim_lookup <- list(
  "condur" =    list(onset = 168, comp_win = c("MMN_oc"), stim = "condur"),
  "den" =       list(onset = 168, comp_win = c("MMN"),    stim = "den"),
  "fre" =       list(onset = 168, comp_win = c("MMN"),    stim = "fre"),
  "int" =       list(onset = 168, comp_win = c("MMN"),    stim = "int"),
  "loc" =       list(onset = 0,   comp_win = c("MMN"),    stim = "loc"),
  "noise" =     list(onset = 168, comp_win = c("MMN"),    stim = "noise"),
  "omission1" = list(onset = 168, comp_win = c("MMN_oc"), stim = "omission1"),
  "omission2" = list(onset = 168, comp_win = c("MMN"),    stim = "omission2"),
  "vowcha1" =   list(onset = 0,   comp_win = c("MMN"),    stim = "vowcha1"),
  "vowcha2" =   list(onset = 168, comp_win = c("MMN"),    stim = "vowcha2"),
  "vowdur1" =   list(onset = 0,   comp_win = c("MMN"),    stim = "vowdur1"),
  "vowdur2" =   list(onset = 168, comp_win = c("MMN"),    stim = "vowdur2"),
  "Nangry" =    list(onset = 0,   comp_win = c("MMN", "P3a_sa"), stim = "Nangry"),
  "Nhappy" =    list(onset = 0,   comp_win = c("MMN", "P3a_h"),  stim = "Nhappy"),
  "Nsad" =      list(onset = 0,   comp_win = c("MMN", "P3a_sa"), stim = "Nsad"),
  "std" =       list(onset = 0,   comp_win = c("P1", "N1", "P2", "N1-2"), stim = "std")
  )

# Lookup table defining the different windows for ERP pararmeter extraction.
# ga_win - window over deviance onset to extract component peak from Fz
# grand average waveforms.
# amp_win - window to average amplitude over around the peak found in Fz grand
# average waveforms.
# lat_win - window around component peak at Fz to extract individual peak
# latencies from.
# diff - are the statistics to be  calculated from differenced or undifferenced
# waveforms.
comp_lookup = list(
  "P1" =     list(ga_win = c(20, 80),   amp_win = c(-20, 20),
                  lat_win = c(-50, 50), diff = F, sign = "pos", clnm = "P1"),
  "N1" =     list(ga_win = c(70, 130),  amp_win = c(-20, 20),
                  lat_win = c(-50, 50), diff = F, sign = "neg", clnm = "N1"),
  "P2" =     list(ga_win = c(170, 230), amp_win = c(-20, 20),
                  lat_win = c(-50, 50), diff = F, sign = "pos", clnm = "P2"),
  "N1-2" =   list(ga_win = c(270, 330), amp_win = c(-20, 20),
                  lat_win = c(-50, 50), diff = F, sign = "neg", clnm = "N1-2"),
  "MMN" =    list(ga_win = c(100, 220), amp_win = c(-20, 20),
                  lat_win = c(-50, 50), diff = T, sign = "neg", clnm = "MMN"),
  "MMN_oc" = list(ga_win = c(0, 120),   amp_win = c(-20, 20),
                  lat_win = c(-50, 50), diff = T, sign = "neg", clnm = "MMN"),
  "P3a_sa" = list(ga_win = c(250, 350), amp_win = c(-30, 30),
                  lat_win = c(-50, 50), diff = F, sign = "pos", clnm = "P3a"),
  "P3a_h" =  list(ga_win = c(200, 300), amp_win = c(-30, 30),
                  lat_win = c(-50, 50), diff = F, sign = "pos", clnm = "P3a")
)


# Funs --------------------------------------------------------------------


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

# Global peak index extraction.
which_global_extremum <- function(x, sign)
{
  if (sign == "neg") {
    which.min(x)
  } else if (sign == "pos") {
    which.max(x)
  } else stop("Give sign as either neg or pos.")
}


# Function for extracting ERP-parameters.
# Specifying the optional argument man_peak allows for overriding automatic peak
# location search with inputted values.
# Called from wrap_lookup & align_peaks functions.
extract_erppar <- function(batch, stimpar, comppar, ga_peaks = NULL)
{
  erpid <- str_replace(stimpar$stim, pattern = "[0-9]+", replacement = "")
  if (is.null(ga_peaks)) {
    # Extracting component peak latencies from measurement time x burnout
    # grand average waveforms.
    man_align <- FALSE
    if (comppar$diff) {
      b_ga <- batch$diffga[[erpid]]
    } else {
      b_ga <- batch$rawga[[erpid]]
    }
    # Latency window for ga-peak extraction;
    ga_win <- comppar$ga_win + stimpar$onset
    b_ga %>% filter(time %in% ga_win[[1]]:ga_win[[2]] & channel == "Fz") %>%
      group_by(project, grouping) %>%
      summarise(
        # # Local peak latency.
        # ga_peak = time[which_local_extremum(amplitude, comppar$sign)],
        # Global peak latency
        ga_peak = time[which_global_extremum(amplitude, comppar$sign)]
        ) %>%
      ungroup() -> ga_peaks
  } else {
    man_align <- TRUE
    ga_peaks %>% ungroup() -> ga_peaks
  }
  ## Extracting parameters.
  # Getting butterfly waveforms.
  if (comppar$diff) {
    b_bf <- batch$diffbf[[erpid]]
  } else {
    b_bf <- batch$rawbf[[erpid]]
  }
  # Adding amplitude and latency measurement windows around ga_peak values.
  ga_peaks %>%
    mutate(amp_win_lo = ga_peak + comppar$amp_win[[1]],
           amp_win_hi = ga_peak + comppar$amp_win[[2]],
           lat_win_lo = ga_peak + comppar$lat_win[[1]],
           lat_win_hi = ga_peak + comppar$lat_win[[2]]) -> par_wins
  # Iterating over group_specific amplitude windows.
  pars <- map_df(seq(nrow(par_wins)), function(i)
  {
    gpar <- par_wins[i, ]
    # Extraction of mean amplitudes.
    b_bf %>% filter(project == gpar$project &
                      grouping == gpar$grouping &
                      time %in% gpar$amp_win_lo:gpar$amp_win_hi) %>%
      group_by(channel, subject, grouping, project) %>%
      summarise(amplitude = mean(amplitude)) %>% ungroup() -> mamps
    # Extraction of peak latencies.
    b_bf %>% filter(channel == "Fz" &
                      project == gpar$project &
                      grouping == gpar$grouping &
                      time %in% gpar$lat_win_lo:gpar$lat_win_hi) %>%
      group_by(channel, subject, grouping, project) %>%
      summarise(
        # # Local peak latency
        # latency = time[which_local_extremum(amplitude, comppar$sign)],
        # Global peak latency
        latency = time[which_global_extremum(amplitude, comppar$sign)]
        ) %>%
      ungroup() -> plats
    # Joining and returning combined df.
    left_join(mamps, plats, by = c("channel", "subject", "grouping", "project"))
  })
  # Combining and strucuring the output
  left_join(pars, par_wins, by = c("project", "grouping")) %>%
    mutate(man_align = man_align, erpid = erpid, stimuli = stimpar$stim,
           component = comppar$clnm) %>%
    select(erpid, stimuli, component, project, grouping, subject, channel,
           everything()) -> out
  # Changing features to factors and ordering.
  out %>% mutate(erpid =     factor(erpid,     levels = ERPID_LEV),
                 stimuli =   factor(stimuli,   levels = STIM_LEV),
                 component = factor(component, levels = COMP_LEV),
                 subject =   factor(subject,   levels = unique(subject))) %>%
    arrange(component, erpid, stimuli, project, grouping, subject, channel) %>%
    rename(subjnr = subject) %>% mutate(subject = paste0(project, subjnr))
}

# Iterate over the given lookup tables to extract ERP parameters.
wrap_lookup <- function(batch)
{
  # Iterating over stimulus codes
  out <- list()
  for (stim in names(stim_lookup)) {
    stim_lookup[[stim]] -> stimpar
    # Iterating over component codes.
    for (comp in stimpar$comp_win) {
      comp_lookup[[comp]] -> comppar
      out <- c(out, list(extract_erppar(batch, stimpar, comppar)))
    }
  }
  data.table::rbindlist(out) %>% as.tibble
}


## Functions for running manual alignments should peaks found to vary too much
## between groups.

# Helper function for plotting grand average waveforms of measurement time and
# grouping combinations.
plotly_grouped <- function(s, b, stimpar, comppar)
{
  b %>% mutate(project = factor(project, levels = c("UUPU", "SEAM"))) -> b
  s %>% group_by(project, grouping, channel) %>%
    summarise(ga_peak = unique(ga_peak), amplitude = mean(amplitude)) %>%
    ungroup() -> speak
  ggplot(b, aes(x = time, y = amplitude, colour = grouping)) +
    facet_grid(channel ~ project) +
    geom_hline(yintercept = 0, alpha = 0.5) +
    geom_vline(xintercept = 0, alpha = 0.5) +
    scale_y_reverse() +
    geom_vline(xintercept = stimpar$onset + comppar$ga_win) +
    geom_point(data = speak, aes(x = ga_peak, y = amplitude), shape = 1) +
    geom_line() +
    ggtitle(label = paste(stimpar$stim, comppar$clnm)) -> p
  print(plotly::ggplotly(p))
}

# Helper function for handling user input for peak realignment and descending to
# new peak.
realign_peaks <- function(ga_peaks, b, csign)
{
  cat("Manual alignment. Please give new peak latency, or pass empty string to pass.\n")
  cat("Automatic descent to nearest peak is performed once a new latency is given.\n")
  ga_peaks$ga_peak <- map_dbl(seq(nrow(ga_peaks)), function(i)
  {
    gpr <- ga_peaks[i, ]
    nlat <- readline(prompt = paste0(
      as.character(gpr$project), " ", as.character(gpr$grouping),
      ", previously @ ", gpr$ga_peak, " : ")) %>% as.numeric
    if (is.na(nlat) || nlat == gpr$ga_peak || nlat %% 2 != 0) {
      cat("pass\n")
      gpr$ga_peak
    } else {
      # Branching to new peak selection.
      cat("New peak set to ")
      b %>% filter(project == gpr$project & grouping == gpr$grouping &
                     channel == "Fz") -> b_
      # Perform descent to nearest local peak from given latency.
      (b_ %>% pull(time) == nlat) %>% which -> lat_i
      top <- b_[lat_i - c(1, 0, -1), "amplitude"][[1]]
      whichfun <- if (csign == "neg") {
        which.min
      } else if (csign == "pos") {
        which.max
      }
      while (whichfun(top) != 2) {
        lat_i <- (whichfun(top) - 2) + lat_i
        top <- b_[lat_i - c(1, 0, -1),"amplitude"][[1]]
      }
      np <- b_[lat_i, "time"][[1]]
      cat(np, "\n")
      np
  }})
  ga_peaks
}

# Run checks for too variable peaks found in grand average waveforms.
# Align peaks manually if a deviation over the limit was found.
# lim - Maximum deviation in peaks allowed without prompt for correction.
#       Calculated as minimum peak latency - maximum peak latency.
align_peaks <- function(stats, batch, lim = 40)
{
  out <- list()
  for (stim in unique(stats$stimuli)) {
    stimpar <- stim_lookup[[stim]]
    for (comp in stimpar$comp_win) {
      comppar <- comp_lookup[[comp]]
      stats %>% filter(stimuli == stim & component == comppar$clnm) -> s
      # Checking if any of the peaks differ by more than lim.
      s %>% group_by(project, grouping) %>%
        summarise(ga_peak = unique(ga_peak)) %>% ungroup() -> ga_peaks
      ga_peaks %>% pull(ga_peak) %>% range %>% diff -> pw
      if (pw > lim) {
        # If peaks are found to vary too much, branching here and doing possible
        # adjustments.
        input <- readline(prompt = paste(stim, comppar$clnm,
          "grouped GA peaks found to vary by", pw, "ms. Adjust them, y/n? "))
        if (input == "n" || input == "") {
          o <- s
        } else {
          ## Plotting grouped waveforms.
          # Subsetting to GA dataset.
          erpid <- str_replace(stim, pattern = "[0-9]+", replacement = "")
          b <- if (comppar$diff) {
            batch[["diffga"]][[erpid]]
            } else {
            batch[["rawga"]][[erpid]]
            }
          plotly_grouped(s, b, stimpar, comppar)
          # Reading user defined order of amplitude windows from the terminal.
          ga_peaks <- realign_peaks(ga_peaks, b, comppar$sign)
          # Extracting new ERP-parameters using new realigned peaks.
          o <- extract_erppar(batch, stimpar, comppar, ga_peaks)
        }
      } else {
        o <- s
      }
      out <- c(out, list(o))
    }
  }
  data.table::rbindlist(out) %>% as.tibble
}


# CALLS -------------------------------------------------------------------







