# A script to render Rmd files to a specific location on disk
#
# TODO:
# * rmarkdown::render() fails to Ukko because of Pandoc error
#   "hClose: hardware fault (I/O error)". Try updating Pandoc to at least
#   version 2 and use devtools::install_github("rstudio/rmarkdown") i.e.
#   the latest rmarkdown.

source("init_jkor.R")

TMP_DIR <- tempdir() #creating locally due to errors upon saving to Ukko
REPO_DIR <- "/home/jkor/work_local/projects/seamless/github/R"
PROJECT_ROOT_PATH <- '/ukko/projects/SeamlessCare_2015-16/'
CTAP_ROOT_ID_LST <- c('ctap_tswitch', 'ctap_tswitch_uupu')


# -----------------------------------------------------------------------
# Helper functions

# Extract file body
require(stringr)
filebody <- function(fname){
  stringr::str_split(basename(fname), '\\.', simplify = T)[[1]]
}

# Render report to html format
render_html <- function(report_file, out_dir, inparams){
  out_name <- sprintf('%s.html', filebody(report_file))
  rmarkdown::render(report_file,
                    output_format = 'html_document',
                    params = inparams,
                    output_file = file.path(out_dir, out_name))
}


# -----------------------------------------------------------------------
# Render documents - same document for both projects

# Separately for each project
for (ctap_root_id in CTAP_ROOT_ID_LST){

  PATHS <- create_ctap_paths(PROJECT_ROOT_PATH, ctap_root_id)

  # Create report
  inparams <- list(
    r_base_dir = REPO_DIR,
    project_root_path = PROJECT_ROOT_PATH,
    ctap_root_id = ctap_root_id
  )
  render_html(file.path(REPO_DIR, 'tswitch', 'tswitch_ERP_descriptives.Rmd'),
              TMP_DIR, inparams)


  # Copy a locally created file to server
  # debug:
  # render_html(file.path(REPO_DIR, 'tswitch', 'tswitch_ERP_descriptives.Rmd'),
  #             PATHS$ctap_results_root, inparams)

  fname <- 'tswitch_ERP_descriptives.html'
  OUTDIR <- PATHS$ctap_results_root

  file.copy(from = file.path(TMP_DIR, fname),
            to = file.path(OUTDIR),
            overwrite = TRUE,
            recursive = TRUE,
            copy.mode = FALSE,
            copy.date = TRUE)
}



# -----------------------------------------------------------------------
# Render documents - one document containing both projects
PATHS <- create_ctap_paths(PROJECT_ROOT_PATH, 'dummy')

# Create report
inparams <- list(
  r_base_dir = REPO_DIR,
  project_root_path = PROJECT_ROOT_PATH
)
 #creating locally due to errors upon saving to Ukko
render_html(file.path(REPO_DIR, 'tswitch', 'tswitch_ERP_project-comparison.Rmd'),
            TMP_DIR, inparams)


# Copy a locally created file to server
fname <- 'tswitch_ERP_project-comparison.html'
OUTDIR <- file.path(PATHS$project_root, 'analysis',
                    'uupu-seam_comparisons', 'tswitch')

file.copy(from = file.path(TMP_DIR, fname),
          to = file.path(OUTDIR),
          overwrite = TRUE,
          recursive = TRUE,
          copy.mode = FALSE,
          copy.date = TRUE)


