# A collection of functions that should be added to CTAP related collection
# of R functions
require(tidyverse)

#' Load a list of hdf5 filenames (full names!) from a file, parse it and
#' return in a tibble. The input file should contain one file name per row.
#'
#' @description
#' One way to produce the input file in linux would be:
#' find `pwd` -iname "*.h5" -exec stat -c "%n %Y" {} \; > h5_files.txt
#'
#' The listing is produced using command line tools as those seem to be much faster
#' at traversinng the directory tree thatn R is.
#'
#' The input file should look like:
#' jkor@debian-jkor .../ctap_tswitch $ head h5_files.txt
#' /ukko/projects/SeamlessCare_2015-16/analysis/ctap_tswitch/erp/prepro/ica/ERP_tswitch_CR/this/src-1_ica/figures/CTAP_plot_ERP/set2_fun2/SEAMPILOT302_VA_P1_TS03_tswitch_CR_ERPdata.h5 1523021567
#' /ukko/projects/SeamlessCare_2015-16/analysis/ctap_tswitch/erp/prepro/ica/ERP_tswitch_CR/this/src-1_ica/figures/CTAP_plot_ERP/set2_fun2/SEAM040_UU_P2_TS03_tswitch_CR_ERPdata.h5 1523020698
#'
#' @param h5_lst_file A text file with full path to a HDF5 file + unix time
#' stamp per row
#' @param select_columns A char vector of column names to return
#'
#' @return A tibble with one for per HDF5 file, columns contain file info.
#'
load_h5_list <- function(h5_lst_file,
                         select_columns =
                           c("uname","erpid","setfun","subject","modified",
                             "casename","measurement","notcasename","part","session",
                             "task","fullname","path","filename")){

  # Read file
  fd <- read.table(h5_lst_file, stringsAsFactors = F)

  # Parse rows
  make_row <- function(el){
    as.data.frame(
      c( parse.savename(el[['V1']]),
         list(modified = el[['V2']]) ),
      stringsAsFactors = F)
  }
  fd <- fd %>%
    group_by(V1) %>%
    do(make_row(.)) %>%
    ungroup()

  # Final touches
  fd <- fd %>%
    rename(fullname = V1) %>%
    mutate(modified = as.POSIXct(modified,
                                  origin='1970-01-01',
                                  tz='Europe/Helsinki'),
           uname = paste(casename, erpid, setfun, sep="_")) %>%
    select(select_columns)

  fd
}


#' CTAP savename parsing
#'
#' @description
#' Given a full file name as string returns a list of components in the name.
#'
#' @param fname A full file name of CTAP result file
#'
#' @return A list with standard CTAP file name components
parse.savename <- function(fname){

  fpath <- dirname(fname) #just path
  fname <- basename(fname) #filename only

  splits <- strsplit(fname,'_')[[1]]
  casename <- paste(splits[1:4], collapse = '_')
  notCasename <- paste(splits[5:length(splits)], collapse = '_')
  subject <- splits[1]
  part <- splits[2]
  session <- splits[3]
  measurement <- splits[4]
  task <- splits[5]
  erpid <- splits[6]

  list(path = fpath, filename = fname,
       casename = casename, notcasename = notCasename,
       subject = subject, part = part, session = session, measurement = measurement,
       task = task, erpid = erpid, setfun = basename(fpath))
}


#' The hdf5-datasets are clustered by blink handling branches and levels of
#' processing; Use this function to select the desired combination of blink
#' handling method and level of processing.
#'
#' @param branch - Select analysis branch for blink handling;
#'   asis       - No blink handling procedures.
#'   BLICremove - Remove ICs found to be associated with blinks.
#'   BLICfix    - Correction of blinks using empirical mode decomposition.
#' @param level - Integer giving the level of processing in range 1-3.
#'
#' @return A subsetted tibble containing paths to .hdf5-files with specified
#' blink handling method and level of processing.
subset_fd <- function(fd, branch = "BLICremove", level = 2L){
  PATH_PATTERNS <- c("src-1_ica", "src-1_blinkICfix", "src-1_blinkICremove")
  BRANCHES <- c('asis', 'BLICfix', 'BLICremove')
  fd %>% ungroup() %>%
    mutate(Branch = Rtools::mystr_detect_replace(path, PATH_PATTERNS, BRANCHES),
           setlev = parse_number(setfun)) %>%
    group_by(casename, erpid, Branch) %>%
    mutate(setrank = rank(setlev)) %>%
    ungroup() %>%
    filter(Branch == branch & setrank == level)
}


#' Function for loading subject average ERP data and binding it into
#' a tibble, separately for each erpid.
#'
#' @param fds tibble, HDF5 file informations structure, one file per row
#' @param channel_arr char vector, names of channels to load
#'
#' @return A tibble with subject average ERP data
preload_data <- function(fd, channel_arr){

  load_condition <- function(fds, channel_arr) {

    # Load ERP data the subset defined by fds
    out <- loadNcombine_erp_data(fds, channel_arr)

    # Fetching trial counts by reading 3rd dimensions.
    trial_counts <- map_dbl(out[[1]], ~dim(.)[[3]])
    tc_df <- tibble(casename = names(trial_counts),
                    trial_count = trial_counts)

    # Combine ERP data and trial counts
    out <- as_tibble(melt.erp.lst(out$ERP, channel_arr)) %>%
      mutate(ds = as.character(ds)) %>%
      rename(casename = ds, amplitude = value)

    out <- left_join(out, tc_df, by = 'casename') %>%
      mutate(erpid = unique(fds$erpid))
    out
  }

  out <- fd %>%
    group_by(erpid) %>%
    do(load_condition(., channel_arr))
  #erpid_arr <- unique(fd$erpid)
  #bind <- map(erpid_arr, load_condition)
  #names(bind) <- erpid_arr
  out
}


#' Load different granularities of ERP data and return them in a list.
#'
#' @description
#' Loads single trial ERP data for each subject and derives subject and
#' group averages from that.
#'
#' @param fds tibble, HDF5 file informations structure, one file per row
#' @param channel_arr char vector, names of channels to load
#'
#' @return a list with single trial, average and gran average ERPs
loadNcombine_erp_data <- function(fds, channel_arr){
  # single-trial ERPs
  cerp_lst <- fds %>%
    group_by(casename) %>% # to avoid pooling of _VA_
    do(erpd = Rtools::load.h5.array(.$fullname, '/erp')) #load stERP

  # restructure:
  elem_names <- cerp_lst$casename
  cerp_lst <- cerp_lst$erpd
  names(cerp_lst) <- elem_names

  # subject average ERPs
  cerpavg_lst <- lapply(cerp_lst, function(el){apply(el, c(1,2), mean)}) #average ERPs as a list
  sterp <- melt.erp.lst(cerpavg_lst, channel_arr) #to data.frame
  # Add possible ad hoc latency fix here.

  # Group average ERPs
  gaerp <- sterp %>%
    group_by(channel, time) %>%
    summarise(n = n(),
              mean = mean(value)) #GA ERP

  list(stERP = cerp_lst, ERP = cerpavg_lst, gaERP = gaerp)
}


#' Melt a list of ERP data matrices into plottable dataset
#'
#' @param erpLst A list of ERP data matrices
#' @param channels A char vector of channel names
#'
#' @return A long format data frame with ERP data, example below.
#'
#' Output format
#' 'data.frame':
#' $ channel: Factor w/ 3 levels "Fz","Cz","Pz": 1 2 3 1 2 3 1 2 3 1 ...
#' $ time   : int  -100 -100 -100 -98 -98 -98 -96 -96 -96 -94 ...
#' $ ds     : Factor w/ 2 levels "SEAMPILOT301",..: 1 1 1 1 1 1 1 1 1 1 ...
#' $ value  : num  1.662 1.41 0.734 1.738 1.5 ...
melt.erp.lst <- function(erpLst, channels){
  erpLst <- lapply(erpLst, function(dmat){dmat[channels,]}) #select only some channels
  erpLst <- simplify2array(erpLst) #to array
  names(dimnames(erpLst)) <- c('channel','time','ds') #name dimensions
  pd <- reshape2::melt(erpLst) #to long data.frame, makes srings into factors
  pd
}


