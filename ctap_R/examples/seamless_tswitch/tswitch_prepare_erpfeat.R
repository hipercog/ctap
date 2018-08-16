# A script to load task switching ERP data from HDF5 files and extract
# features from it. Saves Subject average ERPs and features to disk
# fast access.
#
# TODO:
# * htmlwidgets::saveWidget() fails to Ukko because of Pandoc error
#   "hClose: hardware fault (I/O error)". Try updating Pandoc to at least
#   version 2 and use devtools::install_github("rstudio/rmarkdown") i.e.
#   the latest rmarkdown.
#
# * double check ERP feature extraction using MMN analysis functions,
#   move functions to a different file, higher in hierarchy.

source("init_jkor.R")
#source("mmn/stats_seam_mmn.R") #using tools from here (obsolete)
source("mmn/IA/stats_extraction_IA.R") #using tools from here, todo: correct? Jonne?
require(feather) #for storing to Python compatible format

# Minimal requirements
# require(tidyverse)
# require(Rtools)
# source("tools_setup.R")
# source("mmn/IA/stats_extraction_IA.R") #using tools from here
# source("ctap_tools_future.R") #override some stuff

# ----------------------------------------------------------------------
## Setup

PROJECT_ROOT_PATH <- '/ukko/projects/SeamlessCare_2015-16/'
CTAP_ROOT_ID <- 'ctap_tswitch_uupu'

RELOAD <- F
PATH_PATTERNS <- c("src-1_ica", "src-1_blinkICfix", "src-1_blinkICremove")
BRANCHES <- c('asis', 'BLICfix', 'BLICremove')

(PATHS <- create_ctap_paths(PROJECT_ROOT_PATH, CTAP_ROOT_ID))
PATHS_LOCAL <- create_ctap_paths('/home/jkor/Dropbox/Shared/seamless_jkor/ukonkuva',
                                  CTAP_ROOT_ID)


# ----------------------------------------------------------------------
# Gather information on available HDF5 files

fd <- load_h5_list(file.path(PATHS$ctap_root, 'h5_files.txt'))

fd <- fd %>%
  ungroup() %>%
  mutate(branch = Rtools::mystr_detect_replace(path, PATH_PATTERNS, BRANCHES),
         erpid_sf = paste0(erpid, '_', setfun))

# Find out sets of HdF5 files
result_sets <- fd %>%
  group_by(branch, erpid, setfun) %>%
  count() %>%
  ungroup() %>%
  separate(setfun, c('set','fun'), remove = F) %>%
  mutate(set = as.integer(str_replace_all(set, 'set', '')),
         fun = as.integer(str_replace_all(fun, 'fun', '')),
         erpid_sf = paste0(erpid, '_', setfun))

# Add ordering of the sets
result_sets <- result_sets %>%
  group_by(branch, erpid) %>%
  mutate(setrank = rank(set)) %>%
  ungroup()

# result_sets %>% View()


# ----------------------------------------------------------------------
# Load subject average ERP data
# Note: No individual trial data available!

savedir <- file.path(PATHS$ctap_results_root, 'rds')
dir.create(savedir, showWarnings = F, recursive = T)
savefile <- file.path(savedir, 'TS03_erp_sbjave.rds')

if (RELOAD){
  # Note: setx_funy depends on how the pipe has been run.
  # Find out correct combinations by analyzing fd.
  #
  # For SEAM project
  # CR: set6_fun3
  # CRp1: set12_fun3
  # CRp2: set6_fun3 (temporary?)
  # CRp2to9: set18_fun3
  # CRp3to9: set12_fun3 (temporary?)
  # erpid_sf_arr <- c(
  #   'CR_set6_fun3',
  #   'CRp1_set12_fun3',
  #   'CRp2_set6_fun3',
  #   'CRp2to9_set18_fun3',
  #   'CRp3to9_set12_fun3'
  # )

  # For UUPU or SEAM project (irrespective of pipe order)
  # Select a set to analyze
  (load_sets = result_sets %>%
    filter(branch == 'asis', setrank == 3))
  erpid_sf_arr <- load_sets$erpid_sf

  fd_load <- fd %>%
    mutate(erpid_sf = paste0(erpid, '_', setfun)) %>%
    filter(branch == 'asis', measurement == 'TS03',
           erpid_sf %in% erpid_sf_arr)
           #erpid_sf %in% erpid_sf_arr, subject == 'UUPU002')

  #ts3_seam_batch <- preload_data(head(fd_load,2), c('Fz','Cz','Pz'))
  ts3_seam_batch <- preload_data(fd_load, c('Fz','Cz','Pz'))
  saveRDS(ts3_seam_batch, savefile)

} else {
  ts3_seam_batch <- readRDS(savefile)
}


# ----------------------------------------------------------------------
# Interactive group average ERPs for GA peak finding
#
# Note:
# * These are saved to a local folder due to network issues with ukko.
# * These plots do currently work in Anaconda environment seamless-r since
#   latest ggplot2 is too difficult to install (curl certificates issue)

savedir_loc <- file.path(PATHS_LOCAL$fig_root, 'GA')
dir.create(savedir_loc, showWarnings = F, recursive = T)

my_gaerp_plot <- function(pd, savedir){

  cur_erpid <- unique(pd$erpid)

  pd <- pd %>%
    mutate(value = amplitude,
           ds = casename)

  gapd <- pd %>%
    group_by(channel, time) %>%
    summarise(n=n(), mean=mean(amplitude)) %>%
    ungroup()

  titlestr = sprintf('%s GA ERP, N_sbj = %d', cur_erpid, unique(gapd$n))
  p <- ggplot.gaerp(gapd,
                    #ylimits = c(10, -5),
                    titlestr = titlestr) #plot

  gp <- ggplotly(p)
  savefile <- file.path(savedir, sprintf('GAERP_%s.html', cur_erpid))
  htmlwidgets::saveWidget(gp, savefile)
  # note: using local save directory as saving to Ukko fails. See todo.

  tibble(success = T, plot = list(p))
}

ts3_seam_batch %>%
  group_by(erpid) %>%
  do(my_gaerp_plot(., savedir = savedir_loc))


# Copy all locally created files to server
# Note: last folder of savedir_loc is re-created at destination: hence
# copying to one level higher than with command line cp.
file.copy(from = savedir_loc,
          to = PATHS$fig_root,
          overwrite = TRUE,
          recursive = TRUE,
          copy.mode = FALSE,
          copy.date = TRUE)


# ----------------------------------------------------------------------
# Feature extraction (mean amp, peak latency)

#source("mmn/IA/stats_extraction_IA.R") #using tools from here

savedir <- file.path(PATHS$ctap_results_root, 'rds')
dir.create(savedir, showWarnings = F, recursive = T)

# ERP specifications
ts_seam_eclookup <- list(
  list(erpid = 'CR',      window = list(268 + c(-10, 10)), comp = "P3a", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp1',    window = list(274 + c(-10, 10)), comp = "P3a", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp2',    window = list(258 + c(-10, 10)), comp = "P3a", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp2to9', window = list(254 + c(-10, 10)), comp = "P3a", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp3to9', window = list(248 + c(-10, 10)), comp = "P3a", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CR',      window = list(366 + c(-10, 10)), comp = "P3b", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp1',    window = list(386 + c(-10, 10)), comp = "P3b", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp2',    window = list(366 + c(-10, 10)), comp = "P3b", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp2to9', window = list(360 + c(-10, 10)), comp = "P3b", difference = FALSE,  amp_win = 40, sign = "pos"),
  list(erpid = 'CRp3to9', window = list(354 + c(-10, 10)), comp = "P3b", difference = FALSE,  amp_win = 40, sign = "pos")
)
# to tibble
ts_seam_eclookup <- bind_rows(map(ts_seam_eclookup, as_tibble))

# A helper function to extract and row bind different features
collect_features <- function(ds, window, sign, amp_win){
  ds <- ds %>% mutate(subject = casename)

  amp <- mean_amp(ds, window, sign, amp_win, peak_channel = 'Pz') %>%
    select(-amp_win) %>%
    gather('variable','value', one_of('amplitude'))
  # lat <- mean_lat(ds, window, sign) %>%
  #   select(-window) %>%
  #   gather('variable','value', one_of('latency'))
  lat <- peak_lat(ds, window, sign) %>%
    select(-window) %>%
    gather('variable','value', one_of('latency'))

  bind_rows(amp, lat) %>% rename(casename = subject)
  #amp %>% rename(casename = subject)
}


# Compute all features for all ERP specs
erpfeat <- ts_seam_eclookup %>%
  #filter(erpid == 'CR', comp == 'P3a') %>%
  group_by(erpid, comp) %>%
  do(collect_features(filter(ts3_seam_batch, erpid == .$erpid),
                      .$window[[1]],
                      .$sign, .$amp_win)) %>%
  ungroup() %>%
  separate(casename, c('subject','part','session','measurement')) %>%
  mutate(sbjnr = as.integer(str_replace_all(subject, '[A-Z]*', '')))

savefile <- file.path(savedir, 'TS03_erpfeat.rds')
saveRDS(erpfeat, savefile)

# to Python compatible fromat
savefile <- file.path(savedir, 'TS03_erpfeat.feather')
feather::write_feather(erpfeat, savefile)

