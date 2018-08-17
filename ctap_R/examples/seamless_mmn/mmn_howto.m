
# This is a code snippet from Jonne on how to use the latest version of the MMN ERP analysis pipe.
# h5_flpth is the tibble containing all HDF5 files.

source('stats_extraction.R') #latest version of MMN feature extraction functions


data_batch <- load_h5_list(h5_flpth) %>%
	subset_fd(branch = "BLICremove", level = 2L) %>%
	preload_data(channel_arr = c("Fz", "Cz", "Pz"))
